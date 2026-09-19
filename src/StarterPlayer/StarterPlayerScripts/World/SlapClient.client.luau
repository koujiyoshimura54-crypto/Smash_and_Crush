local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Config:WaitForChild("SlapPassConfig"))
local request = ReplicatedStorage.Remotes:WaitForChild("GameRemotes"):WaitForChild("SlapRequest")
local connections = setmetatable({}, { __mode = "k" })

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
		local target = findTarget()
		if target then request:FireServer(target) end
	end)
	tool.Destroying:Connect(function()
		local connection = connections[tool]
		if connection then connection:Disconnect() end
		connections[tool] = nil
	end)
end

local function watch(container)
	for _, child in ipairs(container:GetChildren()) do connectTool(child) end
	container.ChildAdded:Connect(connectTool)
end

watch(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end
