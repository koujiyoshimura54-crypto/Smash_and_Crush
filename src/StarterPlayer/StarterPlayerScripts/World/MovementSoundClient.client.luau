local MOVEMENT_SOUND_ID = "rbxassetid://91656373864470"
local MOVEMENT_SOUND_VOLUME = 0.1
local MOVEMENT_SOUND_PLAYBACK_SPEED = 1.2

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local sound=Instance.new("Sound")
sound.Name="Creamy Keyboard Typing Free"
sound.SoundId=MOVEMENT_SOUND_ID
sound.Volume=MOVEMENT_SOUND_VOLUME
sound.PlaybackSpeed=MOVEMENT_SOUND_PLAYBACK_SPEED
sound.Looped=true
sound.Parent=SoundService

-- Measure world-space travel, not the velocity reported while pressing a wall.
-- Net displacement over a short window rejects alternating physics jitter.
local WINDOW=0.12
local START_SPEED=0.8
local STOP_SPEED=0.35
local TELEPORT_SETTLE=0.2
local character,humanoid,root
local standard,standardConnection,diedConnection
local stateConnection,floorConnection,inputConnection
local playing=false
local samples={}
local elapsed=0
local previousPosition
local placementRevision
local worldId
local settleUntil=0

local function setPlaying(value)
 playing=value
 if value then
  if not sound.IsPlaying then sound:Play() end
 else
  if sound.IsPlaying then sound:Stop() end
  -- The engine's Running updater also uses velocity. Gate just that sound;
  -- keep its asset, volume, speed, and all other character sounds unchanged.
  if standard and standard.Parent and standard.IsPlaying then standard:Stop() end
 end
end
local function reset(settle)
 table.clear(samples)
 previousPosition=nil
 settleUntil=elapsed+(settle or 0)
 setPlaying(false)
end
local function bindStandard(nextSound)
 if standard==nextSound then return end
 if standardConnection then standardConnection:Disconnect();standardConnection=nil end
 standard=nextSound
 if standard and (standard:IsA("Sound")or standard:IsA("AudioPlayer"))then
  local property=standard:IsA("Sound")and "Playing"or "IsPlaying"
  standardConnection=standard:GetPropertyChangedSignal(property):Connect(function()
   if not playing and standard and standard.IsPlaying then standard:Stop() end
  end)
  if not playing and standard.IsPlaying then standard:Stop() end
 else standard=nil end
end
local function disconnectHumanoid()
 for _,connection in {diedConnection,stateConnection,floorConnection,inputConnection}do if connection then connection:Disconnect()end end
 diedConnection=nil;stateConnection=nil;floorConnection=nil;inputConnection=nil
end
local function bind(newCharacter)
 reset()
 bindStandard(nil)
 disconnectHumanoid()
 character=newCharacter;humanoid=nil;root=nil
 placementRevision=nil;worldId=nil
end
local added=player.CharacterAdded:Connect(bind)
local removing=player.CharacterRemoving:Connect(function(oldCharacter)
 if character==oldCharacter then bind(nil)end
end)
if player.Character then bind(player.Character)end

local heartbeat=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if not character or character~=player.Character or not character.Parent then reset();return end
 local nextHumanoid=character:FindFirstChildOfClass("Humanoid")
 if humanoid~=nextHumanoid then
  disconnectHumanoid()
  humanoid=nextHumanoid
  if humanoid then
   diedConnection=humanoid.Died:Connect(function()reset()end)
   stateConnection=humanoid.StateChanged:Connect(function(_,state)
    if state~=Enum.HumanoidStateType.Running and state~=Enum.HumanoidStateType.RunningNoPhysics then reset()end
   end)
   floorConnection=humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
    if humanoid.FloorMaterial==Enum.Material.Air then reset()end
   end)
   inputConnection=humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if humanoid.MoveDirection.Magnitude<=0.05 then reset()end
   end)
  end
  reset()
 end
 local nextRoot=character:FindFirstChild("HumanoidRootPart")
 if root~=nextRoot then root=nextRoot;bindStandard(nil);reset()end
 if not humanoid or not root or not root:IsA("BasePart")then reset();return end
 bindStandard(root:FindFirstChild("Running"))
 local revision=character:GetAttribute("SpawnPlacementRevision")
 local currentWorld=player:GetAttribute("CurrentWorld")
 if revision~=placementRevision or currentWorld~=worldId then
  placementRevision=revision;worldId=currentWorld;reset(TELEPORT_SETTLE)
 end
 local state=humanoid:GetState()
 local grounded=state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.RunningNoPhysics
 if dt<=0 or dt>0.25 or humanoid.Health<=0 or not grounded
  or humanoid.FloorMaterial==Enum.Material.Air or humanoid.MoveDirection.Magnitude<=0.05
  or humanoid.WalkSpeed<=0 or humanoid.Sit or humanoid.PlatformStand or root.Anchored then
  reset();return
 end
 local position=root.Position
 if previousPosition and (position-previousPosition).Magnitude>math.max(1.5,humanoid.WalkSpeed*dt*2)then
  reset(TELEPORT_SETTLE)
 end
 previousPosition=position
 if elapsed<settleUntil then setPlaying(false);return end
 table.insert(samples,{Time=elapsed,Position=position})
 while #samples>2 and elapsed-samples[2].Time>=WINDOW do table.remove(samples,1)end
 local first=samples[1]
 local span=elapsed-first.Time
 if span<WINDOW*0.85 then setPlaying(false);return end
 local delta=position-first.Position
 local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
 local speed=distance/span
 setPlaying(speed>=(playing and STOP_SPEED or START_SPEED))
end)
script.Destroying:Once(function()
 added:Disconnect();removing:Disconnect();heartbeat:Disconnect()
 reset();bindStandard(nil)
 disconnectHumanoid()
 sound:Destroy()
end)
