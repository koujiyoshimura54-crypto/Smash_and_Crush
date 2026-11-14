-- Preserve player camera choices; retain death presentation and new-subject recovery.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Death presentation is owned here; both death signals share one character latch.
local TweenService = game:GetService("TweenService")
local frozenFrame, frozenFocus, frozenFov, frozenCharacter, resumeFov
local encounters = {}
local boundCharacter, diedConnection
local lastView, pendingView
local restoreRevision = 0
local stopped = false
local cameraConnections = {}
local restoringCamera = false
local deathGui, overlay, fade
local lossConnection
local function updateLoss()
 if not overlay then return end
 local detail=overlay:FindFirstChild("LootLoss")
 if detail then detail.Visible=frozenCharacter~=nil and (frozenCharacter:GetAttribute("BattleBagLostCount") or 0)>0 end
end
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
  table.insert(cameraConnections, camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
   if frozenFrame and not restoringCamera and camera.FieldOfView ~= frozenFov then resumeFov = camera.FieldOfView end
   lockCamera()
  end))
 end
 lockCamera()
end
local function showDeath()
 if not deathGui then return end
 deathGui.Enabled = true
 updateLoss()
 if fade then fade:Cancel() end
 overlay.BackgroundTransparency = 1
 fade = TweenService:Create(overlay, TweenInfo.new(.15), {BackgroundTransparency = .5})
 fade:Play()
end
-- Read nominal user zoom, not the distance shortened by normal occlusion.
local function getCameraController()
 local module=player.PlayerScripts:FindFirstChild("PlayerModule")
  or game:GetService("StarterPlayer"):FindFirstChild("PlayerModule")
 local cameras=module and module:FindFirstChild("CameraModule")
 if not cameras then return nil end
 local ok,result=pcall(require,cameras)
 return ok and result.activeCameraController or nil
end
-- FollowCamera interprets a teleport from its old position as walking sideways.
-- Clear only that movement history during an acknowledged server placement;
-- input, zoom, follow and occlusion still run in the standard controller.
local placementCharacter, placementRevision
local function prepareCameraForPlacement()
 if stopped or frozenCharacter then return end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local camera=workspace.CurrentCamera
 if not root or not humanoid or humanoid.Health<=0 or not camera
  or camera.CameraType~=Enum.CameraType.Custom or camera.CameraSubject~=humanoid then return end
 if placementCharacter~=character then placementCharacter=character;placementRevision=nil end
 local revision=character:GetAttribute("SpawnPlacementRevision")
 local target=character:GetAttribute("SpawnPlacementTarget")
 local arrived=revision~=placementRevision and typeof(target)=="Vector3" and (root.Position-target).Magnitude<=.5
 if root.Anchored or arrived then
  local controller=getCameraController()
  if controller then controller.lastCameraTransform=nil;controller.lastCameraFocus=nil end
 end
 if arrived then placementRevision=revision end
end
local function rememberView()
 if stopped or frozenCharacter or pendingView then return end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local camera=workspace.CurrentCamera
 if character~=boundCharacter or not humanoid or humanoid.Health<=0 or not camera
  or camera.CameraType~=Enum.CameraType.Custom or camera.CameraSubject~=humanoid then return end
 local controller=getCameraController()
 if not controller or not controller.GetCameraToSubjectDistance then return end
 lastView={Distance=controller:GetCameraToSubjectDistance(),Rotation=camera.CFrame.Rotation}
end
local function resumeView(character,humanoid)
 if not lastView then return end
 local view=lastView
 pendingView=view;restoreRevision+=1
 local revision=restoreRevision
 task.spawn(function()
  -- The standard controller must first accept the new Humanoid and spawn position.
  RunService.RenderStepped:Wait()
  RunService.RenderStepped:Wait()
  local deadline=os.clock()+10
  repeat
   if stopped or revision~=restoreRevision or character~=player.Character
    or character~=boundCharacter or humanoid.Health<=0 or frozenCharacter then return end
   local camera=workspace.CurrentCamera
   local controller=getCameraController()
   if character:GetAttribute("LobbySpawnPlaced") and camera
    and camera.CameraSubject==humanoid and camera.CameraType==Enum.CameraType.Custom
    and controller and controller.GetSubjectPosition and controller.SetCameraToSubjectDistance then
    local subject=controller:GetSubjectPosition()
    if subject then
     controller:SetCameraToSubjectDistance(view.Distance)
     -- Rebase the chosen orbit at the NEW subject; never restore an old world position.
     camera.Focus=CFrame.new(subject)
     camera.CFrame=CFrame.new(subject)*view.Rotation*CFrame.new(0,0,view.Distance)
     controller.lastCameraTransform=nil;controller.lastCameraFocus=nil
     pendingView=nil
     return
    end
   end
   RunService.RenderStepped:Wait()
  until os.clock()>=deadline
  if revision==restoreRevision then pendingView=nil end
 end)
end
local function freezeDeath(character)
 if character ~= boundCharacter or character ~= player.Character or frozenCharacter then return end
 local camera = workspace.CurrentCamera
 if not camera then return end
 restoreRevision+=1;pendingView=nil
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
 resumeView(character,humanoid)
 return true
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
-- Enforce the snapshot after the standard camera and presentation shakes.
RunService:BindToRenderStep("SmashDeathCamera", Enum.RenderPriority.Last.Value + 1, lockCamera)
RunService:BindToRenderStep("SmashPlacementCamera", Enum.RenderPriority.Camera.Value - 1, prepareCameraForPlacement)
RunService:BindToRenderStep("SmashRememberCamera", Enum.RenderPriority.Camera.Value + 2, rememberView)
task.spawn(function()
 deathGui = player:WaitForChild("PlayerGui"):WaitForChild("DeathGui")
 overlay = deathGui:WaitForChild("Overlay")
 if frozenCharacter then showDeath() else deathGui.Enabled = false end
end)

-- Body growth, SIZE/AUTO and SpawnFacingDirection do not own the camera.
-- Character placement/facing and server acknowledgement remain in their own scripts.
local function bindCharacter(character)
 boundCharacter=character
 restoreRevision+=1
 if lossConnection then lossConnection:Disconnect() end
 lossConnection=character:GetAttributeChangedSignal("BattleBagLostCount"):Connect(updateLoss)
 for _,encounter in encounters do table.clear(encounter) end
 if diedConnection then diedConnection:Disconnect();diedConnection=nil end
 local humanoid=character:WaitForChild("Humanoid",10)
 if not humanoid or character~=boundCharacter then return end
 diedConnection=humanoid.Died:Connect(function()freezeDeath(character)end)
 if humanoid.Health<=0 then freezeDeath(character);return end
 local root=character:WaitForChild("HumanoidRootPart",10)
 if not root or character~=boundCharacter then return end
 while character==player.Character and not character:IsDescendantOf(workspace) do RunService.Heartbeat:Wait() end
 restoreFollow(character,humanoid)
end
player.CharacterAdded:Connect(function(character)task.spawn(bindCharacter,character)end)
if player.Character then task.spawn(bindCharacter,player.Character) end

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
 stopped=true;restoreRevision+=1
 if lossConnection then lossConnection:Disconnect() end
 RunService:UnbindFromRenderStep("SmashDeathCamera")
 RunService:UnbindFromRenderStep("SmashRememberCamera")
 RunService:UnbindFromRenderStep("SmashPlacementCamera")
 if diedConnection then diedConnection:Disconnect() end
 for _,connection in cameraConnections do connection:Disconnect() end
end)
