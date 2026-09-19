local Players = game:GetService("Players")

local player = Players.LocalPlayer
local TREADMILL_RUN_ID = "rbxassetid://913376220"

local treadmillTrack
local currentCharacter
local currentAnimator
local diedConnection
local animationPlayedConnection
local runningConnection
local preparing = false
local suppressedTracks = setmetatable({}, {__mode = "k"})
local locomotionIds = {}

local function normalizedAnimationId(animationId)
	return tostring(animationId):match("(%d+)$")
end

local function isTraining()
	local treadmill = player:GetAttribute("TrainingTreadmill")
	return player:GetAttribute("IsTraining") == true and typeof(treadmill) == "string" and treadmill ~= ""
end

local function stopTrack()
	if treadmillTrack and treadmillTrack.IsPlaying then
		treadmillTrack:Stop(0.15)
	end
end

local function restoreStandardLocomotion()
	for track, weight in pairs(suppressedTracks) do
		if track.IsPlaying then track:AdjustWeight(weight, 0.1) end
	end
	table.clear(suppressedTracks)
end

local function destroyTrack()
	stopTrack()
	if treadmillTrack then
		treadmillTrack:Destroy()
		treadmillTrack = nil
	end
end

local function collectLocomotionIds(character)
	table.clear(locomotionIds)
	local animate = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 5)
	if not animate then return end
	for _, containerName in ipairs({"walk", "run"}) do
		local container = animate:FindFirstChild(containerName)
		if container then
			for _, descendant in ipairs(container:GetDescendants()) do
				if descendant:IsA("Animation") then
					local id = normalizedAnimationId(descendant.AnimationId)
					if id then locomotionIds[id] = true end
				end
			end
		end
	end
end

local function suppressStandardTrack(track)
	if not isTraining() or track == treadmillTrack then return end
	local animation = track.Animation
	local id = animation and normalizedAnimationId(animation.AnimationId)
	if not id or not locomotionIds[id] then return end
	local targetWeight = math.max(track.WeightTarget, track.WeightCurrent)
	if targetWeight > 0 then suppressedTracks[track] = targetWeight end
	track:AdjustWeight(0, 0)
end

local function suppressPlayingLocomotion()
	if not isTraining() or not currentAnimator then return end
	for _, track in ipairs(currentAnimator:GetPlayingAnimationTracks()) do
		suppressStandardTrack(track)
	end
end

local function prepareTrack()
	if treadmillTrack then return treadmillTrack end
	if preparing then return nil end
	local character = currentCharacter
	if not character or character ~= player.Character then return nil end

	preparing = true
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
	if character == currentCharacter and character == player.Character and humanoid and humanoid.Health > 0 and animator then
		local animation = Instance.new("Animation")
		animation.Name = "TreadmillRunAnimation"
		animation.AnimationId = TREADMILL_RUN_ID
		local track = animator:LoadAnimation(animation)
		animation:Destroy()
		track.Name = "TreadmillRunTrack"
		track.Priority = Enum.AnimationPriority.Movement
		track.Looped = true
		treadmillTrack = track
	end
	preparing = false
	return treadmillTrack
end

local function updateTrack()
	if not isTraining() then
		stopTrack()
		restoreStandardLocomotion()
		return
	end
	local track = prepareTrack()
	if track and isTraining() and not track.IsPlaying then track:Play(0.15, 1, 1) end
	task.defer(suppressPlayingLocomotion)
end

local function disconnectCharacter()
	if diedConnection then diedConnection:Disconnect(); diedConnection = nil end
	if animationPlayedConnection then animationPlayedConnection:Disconnect(); animationPlayedConnection = nil end
	if runningConnection then runningConnection:Disconnect(); runningConnection = nil end
	restoreStandardLocomotion()
	destroyTrack()
	currentAnimator = nil
	table.clear(locomotionIds)
end

local function onCharacterAdded(character)
	disconnectCharacter()
	currentCharacter = character
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local animator = humanoid and (humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5))
	if humanoid and animator then
		currentAnimator = animator
		collectLocomotionIds(character)
		diedConnection = humanoid.Died:Connect(disconnectCharacter)
		animationPlayedConnection = animator.AnimationPlayed:Connect(function(track)
			task.defer(suppressStandardTrack, track)
		end)
		runningConnection = humanoid.Running:Connect(function()
			task.defer(suppressPlayingLocomotion)
		end)
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

if player.Character then task.defer(onCharacterAdded, player.Character) end
