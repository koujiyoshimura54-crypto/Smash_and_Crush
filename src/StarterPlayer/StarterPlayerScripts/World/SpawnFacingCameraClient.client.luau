-- One-shot standard-camera heading alignment after each server spawn correction.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Death presentation is owned here; both death signals share one character latch.
local TweenService = game:GetService("TweenService")
local frozenFrame, frozenFocus, frozenFov, frozenCharacter, resumeFov
local encounters = {}
local boundCharacter, diedConnection, scaleConnection, facingConnection
local headingRequest = 0
local cameraConnections = {}
local restoringCamera = false
local requestFraming
local deathGui, overlay, fade
local function lockCamera()
 local camera = workspace.CurrentCamera
 if not frozenFrame or not camera or restoringCamera then return end
 restoringCamera = true
 if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end
 if camera.CFrame ~= frozenFrame then camera.CFrame = frozenFrame end
 if camera.Focus ~= frozenFocus then camera.Focus = frozenFocus end
 if camera.FieldOfView ~= frozenFov then camera.FieldOfView = frozenFov end
 restoringCamera = false
end
local function watchCamera()
 for _,connection in cameraConnections do connection:Disconnect() end
 table.clear(cameraConnections)
 local camera = workspace.CurrentCamera
 if camera then
  for _,property in {"CFrame", "Focus", "CameraType"} do
   table.insert(cameraConnections, camera:GetPropertyChangedSignal(property):Connect(lockCamera))
  end
  for _,property in {"CameraType", "CameraSubject"} do
   table.insert(cameraConnections, camera:GetPropertyChangedSignal(property):Connect(function()
    if requestFraming then requestFraming() end
   end))
  end
  table.insert(cameraConnections, camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
   if frozenFrame and not restoringCamera and camera.FieldOfView ~= frozenFov then resumeFov = camera.FieldOfView end
   lockCamera()
  end))
 end
 lockCamera()
 if requestFraming then requestFraming() end
end
local function showDeath()
 if not deathGui then return end
 deathGui.Enabled = true
 if fade then fade:Cancel() end
 overlay.BackgroundTransparency = 1
 fade = TweenService:Create(overlay, TweenInfo.new(.15), {BackgroundTransparency = .5})
 fade:Play()
end
local function freezeDeath(character)
 if character ~= boundCharacter or character ~= player.Character or frozenCharacter then return end
 local camera = workspace.CurrentCamera
 if not camera then return end
 frozenCharacter = character
 frozenFrame, frozenFocus, frozenFov = camera.CFrame, camera.Focus, camera.FieldOfView
 resumeFov = frozenFov
 lockCamera()
 showDeath()
end
local function restoreFollow(character, humanoid)
 if character ~= player.Character or character ~= boundCharacter or humanoid.Health <= 0 then return false end
 -- The old character must never unlock its own death presentation.
 if frozenCharacter == character then return false end
 local fieldOfView = resumeFov
 frozenCharacter, frozenFrame, frozenFocus, frozenFov, resumeFov = nil, nil, nil, nil, nil
 if fade then fade:Cancel(); fade = nil end
 if deathGui then deathGui.Enabled = false; overlay.BackgroundTransparency = 1 end
 local camera = workspace.CurrentCamera
 if camera then
  if fieldOfView then camera.FieldOfView = fieldOfView end
  camera.CameraSubject = humanoid
  camera.CameraType = Enum.CameraType.Custom
 end
 return true
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
-- Enforce the snapshot after the standard camera and presentation shakes.
RunService:BindToRenderStep("SmashDeathCamera", Enum.RenderPriority.Last.Value + 1, lockCamera)
task.spawn(function()
 deathGui = player:WaitForChild("PlayerGui"):WaitForChild("DeathGui")
 overlay = deathGui:WaitForChild("Overlay")
 if frozenCharacter then showDeath() else deathGui.Enabled = false end
end)

-- Automatic camera framing.
-- BASE_DISTANCE controls the normal camera distance.
-- SCALE_INFLUENCE controls how much character growth affects camera distance.
local CAMERA_BASE_DISTANCE = 18
local CAMERA_SCALE_INFLUENCE = 0.15
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
-- A frame can be unavailable while the standard camera initializes or another
-- presentation temporarily owns it. Retain that request until normal follow returns.
local framingRequest = 0
local stopped = false
local function syncScale(character,humanoid)
 local camera=workspace.CurrentCamera
 local root=character:FindFirstChild("HumanoidRootPart")
 local scale=character:GetAttribute("MuscleHeightScale")
 if frozenCharacter or humanoid.Health<=0 or player.Character~=character or not camera
  or camera.CameraSubject~=humanoid or not root or typeof(scale)~="number" then return false end
 if camera.CameraType~=Enum.CameraType.Custom then return false end
 local controller=getCameraController()
 if not controller or not controller.SetCameraToSubjectDistance then return false end
 local previous=appliedScale[character]
 local resized=not previous or previous.Scale~=scale or previous.Humanoid~=humanoid
 if not resized and previous.Camera==camera and previous.Controller==controller then return true end
 local distance=CAMERA_BASE_DISTANCE*(1+(scale-1)*CAMERA_SCALE_INFLUENCE)
 if not resized then
  -- Read the nominal zoom from the previous controller, never an occlusion-
  -- shortened CFrame/Focus distance. A camera replacement keeps manual zoom.
  local old=previous.Controller
  distance=old and old.GetCameraToSubjectDistance and old:GetCameraToSubjectDistance() or previous.Distance
 end
 local newMin=math.min(baseMinZoom,distance/2)
 local newMax=math.max(newMin,baseMaxZoom*scale)
 if newMin<player.CameraMinZoomDistance then player.CameraMinZoomDistance=newMin;player.CameraMaxZoomDistance=newMax
 else player.CameraMaxZoomDistance=newMax;player.CameraMinZoomDistance=newMin end
 controller:SetCameraToSubjectDistance(distance)
 appliedScale[character]={Scale=scale,Humanoid=humanoid,Camera=camera,Controller=controller,Distance=distance}
 if resized then
 if scale<=1 then humanoid.CameraOffset=Vector3.zero
 elseif controller.GetSubjectPosition then
  -- Ask the standard camera for its uncorrected subject point. Camera.Focus
  -- can still belong to the pre-growth/pre-teleport frame, so adding its delta
  -- repeatedly accumulates an unrelated offset.
  local oldOffset=humanoid.CameraOffset
  humanoid.CameraOffset=Vector3.zero
  local subject=controller:GetSubjectPosition()
  if subject then
   local box=character:GetBoundingBox()
   humanoid.CameraOffset=root.CFrame:VectorToObjectSpace(box.Position-subject)
  else humanoid.CameraOffset=oldOffset end
 end
 end
 return true
end
requestFraming=function()
 framingRequest+=1
 local requested=framingRequest
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not character or character~=boundCharacter or not humanoid or frozenCharacter or humanoid.Health<=0 then return end
 task.spawn(function()
  local deadline=os.clock()+10
  repeat
   RunService.RenderStepped:Wait()
   if stopped or requested~=framingRequest or character~=player.Character or humanoid.Parent~=character
    or frozenCharacter or humanoid.Health<=0 then return end
   if syncScale(character,humanoid) then return end
  until os.clock()>=deadline
 end)
end
-- Late PlayerModule/CameraModule insertion must also retry an earlier request.
local function moduleArrived(instance)
 if instance.Name=="PlayerModule" or instance.Name=="CameraModule" then requestFraming() end
end
local playerModuleConnection=player:WaitForChild("PlayerScripts").DescendantAdded:Connect(moduleArrived)
local starterModuleConnection=game:GetService("StarterPlayer").DescendantAdded:Connect(moduleArrived)
local function alignHeading(character, humanoid)
 if character ~= player.Character or character ~= boundCharacter or frozenCharacter or humanoid.Health <= 0 then return end
 headingRequest += 1
 local requested = headingRequest
 local deadline = os.clock()+10
 local camera
 repeat
  RunService.RenderStepped:Wait()
  camera = workspace.CurrentCamera
  if requested ~= headingRequest or frozenCharacter or humanoid.Health<=0 or player.Character ~= character then return end
 until (character:GetAttribute("SpawnFacingDirection") and camera and camera.CameraSubject==humanoid) or os.clock()>=deadline
 if not camera or camera.CameraSubject~=humanoid then return end
 -- Let the standard CameraModule finish its new-subject initialization.
 RunService.RenderStepped:Wait()
 RunService.RenderStepped:Wait()
 if requested ~= headingRequest or frozenCharacter or humanoid.Health<=0 or player.Character~=character or camera~=workspace.CurrentCamera
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
local function align(character)
 if handled[character] then return end
 handled[character] = true
 local humanoid = character:WaitForChild("Humanoid", 10)
 if not humanoid then return end
 local revision=0
 scaleConnection=character:GetAttributeChangedSignal("MuscleHeightScale"):Connect(function()
  revision+=1
  local requested=revision
  -- Coalesce a size update and allow its parts/joints to replicate before framing.
  task.delay(.1,function()
   if requested==revision and character==boundCharacter then requestFraming() end
  end)
 end)


 facingConnection=character:GetAttributeChangedSignal("SpawnFacingRevision"):Connect(function()
  task.spawn(alignHeading, character, humanoid)
 end)
 requestFraming()
 alignHeading(character, humanoid)
end
local function bindCharacter(character)
 boundCharacter = character
 framingRequest += 1
 headingRequest += 1
 if facingConnection then facingConnection:Disconnect(); facingConnection = nil end
 for _,encounter in encounters do table.clear(encounter) end
 if diedConnection then diedConnection:Disconnect(); diedConnection = nil end
 if scaleConnection then scaleConnection:Disconnect(); scaleConnection = nil end
 local humanoid = character:WaitForChild("Humanoid", 10)
 if not humanoid or character ~= boundCharacter then return end
 diedConnection = humanoid.Died:Connect(function() freezeDeath(character) end)
 if humanoid.Health <= 0 then freezeDeath(character); return end
 local root = character:WaitForChild("HumanoidRootPart", 10)
 if not root or character ~= boundCharacter then return end
 while character == player.Character and not character:IsDescendantOf(workspace) do
  RunService.Heartbeat:Wait()
 end
 if restoreFollow(character, humanoid) then align(character) end
end
player.CharacterAdded:Connect(function(character) task.spawn(bindCharacter, character) end)
if player.Character then task.spawn(bindCharacter, player.Character) end

-- Listen to the existing presentation streams without waiting on an absent World2.
task.spawn(function()
 local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GameRemotes")
 local hooked = {}
 local function hook(remote)
  if not remote:IsA("RemoteEvent") or hooked[remote]
   or (remote.Name ~= "CombatState" and remote.Name ~= "World2CombatState") then return end
  hooked[remote] = true
  local encounter = {}
  table.insert(encounters, encounter)
  remote.OnClientEvent:Connect(function(data)
   if typeof(data) ~= "table" then return end
   if data.Type == "BossInitialize" then
    encounter.Character, encounter.Stage, encounter.Generation = player.Character, data.Stage, data.SpawnGeneration
   elseif data.Type == "Initialize" then
    table.clear(encounter)
   elseif data.Type == "BossResult" then
    if data.Result == "LOSE" and encounter.Character == player.Character
     and encounter.Stage == data.Stage and encounter.Generation == data.SpawnGeneration then
     freezeDeath(encounter.Character)
    end
    table.clear(encounter)
   end
  end)
 end
 remotes.ChildAdded:Connect(hook)
 for _,remote in remotes:GetChildren() do hook(remote) end
end)
script.Destroying:Connect(function()
 stopped=true
 framingRequest+=1
 playerModuleConnection:Disconnect()
 starterModuleConnection:Disconnect()
 RunService:UnbindFromRenderStep("SmashDeathCamera")
 if diedConnection then diedConnection:Disconnect() end
 if scaleConnection then scaleConnection:Disconnect() end
 if facingConnection then facingConnection:Disconnect() end
 headingRequest += 1
 for _,connection in cameraConnections do connection:Disconnect() end
end)
