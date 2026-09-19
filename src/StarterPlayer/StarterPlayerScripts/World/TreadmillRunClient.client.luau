local Players = game:GetService("Players")

local player = Players.LocalPlayer

local treadmillTrack
local currentCharacter
local diedConnection
local preparing = false

local function stopTrack()
	if treadmillTrack and treadmillTrack.IsPlaying then
		treadmillTrack:Stop(0.15)
	end
end

local function destroyTrack()
	stopTrack()
	if treadmillTrack then
		treadmillTrack:Destroy()
		treadmillTrack = nil
	end
end

local function findWalkAnimation(character)
	local animate = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 5)
	local walkContainer = animate and animate:FindFirstChild("walk")
	local walkAnimation = walkContainer and walkContainer:FindFirstChild("WalkAnim")
	if walkAnimation and walkAnimation:IsA("Animation") and walkAnimation.AnimationId ~= "" then
		return walkAnimation
	end
	return nil
end

local function prepareTrack()
	if treadmillTrack then
		return treadmillTrack
	end
	if preparing then
		return nil
	end

	local character = currentCharacter
	if not character or character ~= player.Character then
		return nil
	end

	preparing = true
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
	local walkAnimation = findWalkAnimation(character)
	if character == currentCharacter and character == player.Character and humanoid and humanoid.Health > 0 and animator and walkAnimation then
		local track = animator:LoadAnimation(walkAnimation)
		track.Name = "TreadmillWalkTrack"
		track.Priority = Enum.AnimationPriority.Movement
		track.Looped = true
		treadmillTrack = track
	end
	preparing = false
	return treadmillTrack
end

local function isTraining()
	local treadmill = player:GetAttribute("TrainingTreadmill")
	return player:GetAttribute("IsTraining") == true and typeof(treadmill) == "string" and treadmill ~= ""
end

local function updateTrack()
	if not isTraining() then
		stopTrack()
		return
	end

	local track = prepareTrack()
	if track and isTraining() and not track.IsPlaying then
		track:Play(0.15, 1, 1)
	end
end

local function disconnectCharacter()
	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end
	destroyTrack()
end

local function onCharacterAdded(character)
	disconnectCharacter()
	currentCharacter = character
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if humanoid then
		diedConnection = humanoid.Died:Connect(destroyTrack)
	end
	task.defer(updateTrack)
end

player:GetAttributeChangedSignal("IsTraining"):Connect(updateTrack)
player:GetAttributeChangedSignal("TrainingTreadmill"):Connect(updateTrack)
player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(function(character)
	if character == currentCharacter then
		disconnectCharacter()
		currentCharacter = nil
	end
end)
script.Destroying:Connect(disconnectCharacter)

if player.Character then
	task.defer(onCharacterAdded, player.Character)
end
