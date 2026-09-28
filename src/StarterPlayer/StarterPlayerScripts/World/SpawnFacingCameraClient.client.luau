-- One-shot standard-camera heading and character-scale synchronization.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local baseMinZoom = player.CameraMinZoomDistance
local baseMaxZoom = player.CameraMaxZoomDistance
local handled = setmetatable({}, {__mode="k"})

local function syncScale(character,humanoid)
 local camera=workspace.CurrentCamera
 local root=character:FindFirstChild("HumanoidRootPart")
 local scale=character:GetAttribute("MuscleHeightScale")
 if player.Character~=character or not camera or camera.CameraSubject~=humanoid or not root or typeof(scale)~="number" then return end
 local newMin=baseMinZoom*scale
 local newMax=math.max(newMin,baseMaxZoom*scale)
 if newMin<player.CameraMinZoomDistance then player.CameraMinZoomDistance=newMin;player.CameraMaxZoomDistance=newMax
 else player.CameraMaxZoomDistance=newMax;player.CameraMinZoomDistance=newMin end
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
 local scaleConnection=character:GetAttributeChangedSignal("MuscleHeightScale"):Connect(function()
 RunService.RenderStepped:Wait()
  RunService.RenderStepped:Wait()
  syncScale(character,humanoid)
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
 RunService.RenderStepped:Wait()
 RunService.RenderStepped:Wait()
 if player.Character~=character or camera~=workspace.CurrentCamera or camera.CameraSubject~=humanoid or camera.CameraType~=Enum.CameraType.Custom then return end
 local direction = character:GetAttribute("SpawnFacingDirection")
 if typeof(direction)=="Vector3" then
  local focus = camera.Focus.Position
  local offset = camera.CFrame.Position-focus
  local horizontal = Vector3.new(offset.X,0,offset.Z).Magnitude
  local look = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
  if horizontal>=0.01 and not (look.Magnitude>0 and look.Unit:Dot(direction)>0.999) then
   local position = focus-direction*horizontal+Vector3.new(0,offset.Y,0)
   camera.CFrame = CFrame.lookAt(position,focus,Vector3.yAxis)
  end
 end
 syncScale(character,humanoid)
end
player.CharacterAdded:Connect(function(character) task.spawn(align,character) end)
if player.Character then task.spawn(align,player.Character) end
