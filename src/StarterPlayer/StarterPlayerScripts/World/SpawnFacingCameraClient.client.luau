-- One-shot standard-camera heading alignment after each server spawn correction.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
-- Adjust this coefficient to tune automatic framing; manual zoom remains standard.
local CAMERA_DISTANCE_MULTIPLIER = 0.65
local baseMinZoom = player.CameraMinZoomDistance
local baseMaxZoom = player.CameraMaxZoomDistance
local handled = setmetatable({}, {__mode="k"})
local appliedScale = setmetatable({}, {__mode="k"})
local cameraModule
local function getCameraController()
 if not cameraModule then
  -- Support both Roblox's current StarterPlayer module and the legacy location.
  local module = player.PlayerScripts:FindFirstChild("PlayerModule")
   or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
  local cameras = module and module:FindFirstChild("CameraModule")
  if not cameras then return nil end
  local ok,result = pcall(require,cameras)
  if not ok then return nil end
  cameraModule = result
 end
 return cameraModule.activeCameraController
end
local function syncScale(character,humanoid)
 local camera=workspace.CurrentCamera
 local root=character:FindFirstChild("HumanoidRootPart")
 local scale=character:GetAttribute("MuscleHeightScale")
 if player.Character~=character or not camera or camera.CameraSubject~=humanoid or not root or typeof(scale)~="number" then return end
 if camera.CameraType~=Enum.CameraType.Custom or appliedScale[character]==scale then return end
 local controller=getCameraController()
 if not controller or not controller.SetCameraToSubjectDistance then return end
 local distance=baseMinZoom*scale*CAMERA_DISTANCE_MULTIPLIER
 -- The old scaled minimum forced the camera out. Keep room to zoom inward,
 -- and retain the previous maximum so the user can still zoom all the way out.
 local newMin=math.min(baseMinZoom,distance/2)
 local newMax=math.max(newMin,baseMaxZoom*scale)
 if newMin<player.CameraMinZoomDistance then player.CameraMinZoomDistance=newMin;player.CameraMaxZoomDistance=newMax
 else player.CameraMaxZoomDistance=newMax;player.CameraMinZoomDistance=newMin end
 controller:SetCameraToSubjectDistance(distance)
 appliedScale[character]=scale
 if scale<=1 then humanoid.CameraOffset=Vector3.zero return end
 local box=character:GetBoundingBox()
 local worldDelta=box.Position-camera.Focus.Position
 humanoid.CameraOffset=humanoid.CameraOffset+root.CFrame:VectorToObjectSpace(worldDelta)
end
local function align(character)
 if handled[character] then return end
 handled[character] = true
 local humanoid = character:WaitForChild("Humanoid", 10)
 if not humanoid then return end
 local revision=0
 local scaleConnection=character:GetAttributeChangedSignal("MuscleHeightScale"):Connect(function()
  revision+=1
  local requested=revision
  -- Coalesce a size update and allow its parts/joints to replicate before framing.
  task.delay(.1,function()
   if requested==revision then syncScale(character,humanoid) end
  end)
 end)
 character.AncestryChanged:Once(function() scaleConnection:Disconnect() end)
 local deadline = os.clock()+10
 local camera
 repeat
  RunService.RenderStepped:Wait()
  camera = workspace.CurrentCamera
  if player.Character ~= character then return end
 until (character:GetAttribute("SpawnFacingDirection") and camera and camera.CameraSubject==humanoid) or os.clock()>=deadline
 if not camera or camera.CameraSubject~=humanoid then return end
 -- Let the standard CameraModule finish its new-subject initialization.
 RunService.RenderStepped:Wait()
 RunService.RenderStepped:Wait()
 if player.Character~=character or camera~=workspace.CurrentCamera
  or camera.CameraSubject~=humanoid or camera.CameraType~=Enum.CameraType.Custom then return end
 syncScale(character,humanoid)
 local direction = character:GetAttribute("SpawnFacingDirection")
 if typeof(direction)~="Vector3" then return end
 local focus = camera.Focus.Position
 local offset = camera.CFrame.Position-focus
 local horizontal = Vector3.new(offset.X,0,offset.Z).Magnitude
 if horizontal<0.01 then return end
 local look = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
 if look.Magnitude>0 and look.Unit:Dot(direction)>0.999 then return end
 -- Retain standard zoom distance and elevation; change only the heading.
 local position = focus-direction*horizontal+Vector3.new(0,offset.Y,0)
 camera.CFrame = CFrame.lookAt(position,focus,Vector3.yAxis)
end
player.CharacterAdded:Connect(function(character) task.spawn(align,character) end)
if player.Character then task.spawn(align,player.Character) end
