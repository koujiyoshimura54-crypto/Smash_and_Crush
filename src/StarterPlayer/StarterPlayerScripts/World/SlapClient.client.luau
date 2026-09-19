local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Config:WaitForChild("SlapPassConfig"))
local request = ReplicatedStorage.Remotes:WaitForChild("GameRemotes"):WaitForChild("SlapRequest")
local connections = setmetatable({}, { __mode = "k" })
local tracks = setmetatable({}, { __mode = "k" })
local swingLocked = false

local function aliveRoot(other)
	local character = other.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then return root end
end

local function findTarget()
	local ownRoot = aliveRoot(player)
	if not ownRoot then return nil end
	local look = Vector3.new(ownRoot.CFrame.LookVector.X, 0, ownRoot.CFrame.LookVector.Z)
	local best, bestDistance
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local root = aliveRoot(other)
			if root then
				local offset = root.Position - ownRoot.Position
				local horizontal = Vector3.new(offset.X, 0, offset.Z)
				local distance = offset.Magnitude
				local facing = horizontal.Magnitude < 0.05 or look.Magnitude < 0.05
					or look.Unit:Dot(horizontal.Unit) >= Config.MinimumFacingDot
				if distance <= Config.SlapDistance and facing and (not bestDistance or distance < bestDistance) then
					best, bestDistance = other, distance
				end
			end
		end
	end
	return best
end

local function connectTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= Config.ToolName or connections[tool] then return end
	connections[tool] = tool.Activated:Connect(function()
		if swingLocked then return end
		swingLocked = true
		task.delay(Config.SwingLockout, function() swingLocked = false end)
		if Config.AnimationPlaybackEnabled then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
			local animation = humanoid and tool:FindFirstChild(humanoid.RigType == Enum.HumanoidRigType.R15 and "SwingR15" or "SwingR6")
			if animator and animation and animation:IsA("Animation") then
				local track = tracks[tool]
				if not track then
					track = animator:LoadAnimation(animation)
					track.Priority = Enum.AnimationPriority.Action
					track.Looped = false
					tracks[tool] = track
				end
				track:Play(0.05)
			end
		end
		task.delay(Config.HitDelay, function()
			if tool.Parent ~= player.Character then return end
			local target = findTarget()
			if target then request:FireServer(target) end
		end)
	end)
	tool.Destroying:Connect(function()
		local connection = connections[tool]
		if connection then connection:Disconnect() end
		connections[tool] = nil
		local track = tracks[tool]
		if track then track:Stop(0); track:Destroy() end
		tracks[tool] = nil
	end)
end

local function watch(container)
	for _, child in ipairs(container:GetChildren()) do connectTool(child) end
	container.ChildAdded:Connect(connectTool)
end

watch(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end
