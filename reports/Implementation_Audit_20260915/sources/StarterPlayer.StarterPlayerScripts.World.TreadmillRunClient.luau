local Players = game:GetService("Players")

local player = Players.LocalPlayer

local runTrack
local currentCharacter
local diedConnection

local function stopRun()
	if runTrack then
		runTrack:Stop(0.15)
		runTrack:Destroy()
		runTrack = nil
	end
end

local function findRunAnimation(character)
	local animate = character:FindFirstChild("Animate") or character:WaitForChild("Animate", 5)
	if not animate then
		return nil
	end

	local runContainer = animate:FindFirstChild("run")
	if not runContainer then
		return nil
	end

	return runContainer:FindFirstChildWhichIsA("Animation", true)
end

local function startRun()
	local character = currentCharacter
	if runTrack or not character or character ~= player.Character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or humanoid.Health <= 0 or not animator then
		return
	end

	local runAnimation = findRunAnimation(character)
	if not runAnimation or runAnimation.AnimationId == "" then
		return
	end

	local track = animator:LoadAnimation(runAnimation)
	track.Priority = Enum.AnimationPriority.Movement
	track.Looped = true
	track:Play(0.15, 1, 1)
	runTrack = track
end

local function updateRun()
	if player:GetAttribute("IsTraining") == true then
		startRun()
	else
		stopRun()
	end
end

local function onCharacterAdded(character)
	stopRun()
	currentCharacter = character

	if diedConnection then
		diedConnection:Disconnect()
	end

	local humanoid = character:WaitForChild("Humanoid")
	diedConnection = humanoid.Died:Connect(stopRun)
	task.defer(updateRun)
end

player:GetAttributeChangedSignal("IsTraining"):Connect(updateRun)
player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
	task.defer(onCharacterAdded, player.Character)
end

