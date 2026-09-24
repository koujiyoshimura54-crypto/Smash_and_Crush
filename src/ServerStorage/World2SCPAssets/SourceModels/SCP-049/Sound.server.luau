--[[
	Author: @spotco
	This script creates sounds which are placed under the character head.
	These sounds are used by the "LocalSound" script.
	
	To modify this script, copy it to your "StarterPlayer/StarterCharacterScripts" folder keeping the same script name ("Sound").
	The default Sound script loaded for every character will then be replaced with your copy of the script.
	]]--
	
			---local path = game:GetService("PathfindingService"):FindPathAsync(script.Parent.HumanoidRootPart.Position, GetTarget.Head.Position) --find the path from scp's torso to victims head
			--					local waypoints = path:GetWaypoints() --get the every point of the path
				--				if path.Status == Enum.PathStatus.Success then
	--for q,w in pairs(waypoints) do
	--	if not GetTarget then
	--		break
	--	end
							--			if PlayerHumanoid.Health > 0 then
					--						local allow = 0
						--					script.Parent.Humanoid:MoveTo(w.Position)
										
					--						
							--				while (script.Parent.HumanoidRootPart.Position - w.Position).magnitude > 4 and allow < 30--[[ and victimhumanoid.Health > 0--]] do
					--							allow = allow + 1
							--					heartbeat:wait()
								--			end
							--				
									--	end
--	end
	
								--	script.Parent.Humanoid:MoveTo(GetTarget.Head.Position)
									
			
				--	end
				

function CreateNewSound(name, id, looped, pitch, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Name = name
	sound.archivable = false
	sound.Parent = parent
	sound.Pitch = pitch
	sound.Looped = looped
	
	sound.MinDistance = 5
	sound.MaxDistance = 150
	sound.Volume = 0.65
	
	return sound
end

local head = script.Parent:FindFirstChild("Head")
if head == nil then
	error("Sound script parent has no child Head.")
	return
end


CreateNewSound("GettingUp", 	"rbxasset://sounds/action_get_up.mp3",					false, 	1,		head)
CreateNewSound("Died", 		"rbxasset://sounds/uuhhh.mp3",							false, 	1,		head) 
CreateNewSound("FreeFalling", 	"rbxasset://sounds/action_falling.mp3",				true,	1,		head)
CreateNewSound("Jumping", 		"rbxasset://sounds/action_jump.mp3",					false,	1,		head)
CreateNewSound("Landing", 		"rbxasset://sounds/action_jump_land.mp3",				false,	1,		head)
CreateNewSound("Splash", 		"rbxasset://sounds/impact_water.mp3",					false, 	1,		head)
CreateNewSound("Running", 		"rbxasset://sounds/action_footsteps_plastic.mp3",		true, 	1.85,	head)
CreateNewSound("Swimming", 	"rbxasset://sounds/action_swim.mp3",					true,	1.6,	head)
CreateNewSound("Climbing", 	"rbxasset://sounds/action_footsteps_plastic.mp3",		true,	1,		head)