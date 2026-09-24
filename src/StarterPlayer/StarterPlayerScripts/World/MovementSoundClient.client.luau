local MOVEMENT_SOUND_ID = "rbxassetid://91656373864470"
local MOVEMENT_SOUND_VOLUME = 1
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
local character
local humanoid
local playing=false
local function setPlaying(value)
 if value==playing then return end
 playing=value
 if value then sound:Play() else sound:Stop() end
end
local function bind(newCharacter)
 setPlaying(false)
 character=newCharacter
 humanoid=newCharacter:FindFirstChildOfClass("Humanoid")
end
local added=player.CharacterAdded:Connect(bind)
local removing=player.CharacterRemoving:Connect(function(oldCharacter)
 if character==oldCharacter then
  setPlaying(false)
  character=nil
  humanoid=nil
 end
end)
if player.Character then bind(player.Character) end
local heartbeat=RunService.Heartbeat:Connect(function()
 if not character or not character.Parent then setPlaying(false);return end
 if not humanoid or humanoid.Parent~=character then
  humanoid=character:FindFirstChildOfClass("Humanoid")
 end
 local root=character:FindFirstChild("HumanoidRootPart")
 if not humanoid or not root or not root:IsA("BasePart") then setPlaying(false);return end
 local state=humanoid:GetState()
 local grounded=state==Enum.HumanoidStateType.Running or state==Enum.HumanoidStateType.RunningNoPhysics
 local velocity=root.AssemblyLinearVelocity
 setPlaying(humanoid.Health>0 and grounded
  and humanoid.FloorMaterial~=Enum.Material.Air
  and humanoid.MoveDirection.Magnitude>0.01
  and humanoid.WalkSpeed>0 and not humanoid.Sit and not humanoid.PlatformStand
  and not root.Anchored and Vector3.new(velocity.X,0,velocity.Z).Magnitude>0.1)
end)
script.Destroying:Once(function()
 added:Disconnect();removing:Disconnect();heartbeat:Disconnect()
 sound:Stop();sound:Destroy()
end)
