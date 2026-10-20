-- Acknowledge one server placement after its pose and floor reach this client.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LobbySpawnReady")
local connections = {}
local function bind(character)
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or player.Character ~= character then return end
	local sentRevision, queued
	local function check()
		queued = false
		if player.Character ~= character then return end
		local revision = character:GetAttribute("SpawnPlacementRevision")
		local target = character:GetAttribute("SpawnPlacementTarget")
		if not revision or sentRevision == revision or typeof(target) ~= "Vector3"
			or (root.Position - target).Magnitude > 0.5 then return end
		local excluded = {}
		for _, other in Players:GetPlayers() do if other.Character then table.insert(excluded, other.Character) end end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = excluded
		params.RespectCanCollide = true
		params.CollisionGroup = root.CollisionGroup
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -character:GetExtentsSize().Y - 16, 0), params)
		if not hit or hit.Normal.Y < 0.9 then return end
		sentRevision = revision
		remote:FireServer(character, revision, target)
	end
	local function schedule()
		if sentRevision == character:GetAttribute("SpawnPlacementRevision") then return end
		if queued then return end
		queued = true
		task.defer(check)
	end
	table.insert(connections, character:GetAttributeChangedSignal("SpawnPlacementRevision"):Connect(schedule))
	table.insert(connections, character:GetAttributeChangedSignal("SpawnPlacementTarget"):Connect(schedule))
	table.insert(connections, root:GetPropertyChangedSignal("CFrame"):Connect(schedule))
	table.insert(connections, workspace.DescendantAdded:Connect(function()
		if sentRevision ~= character:GetAttribute("SpawnPlacementRevision") then schedule() end
	end))
	schedule()
end
player.CharacterAdded:Connect(bind)
if player.Character then task.spawn(bind, player.Character) end
