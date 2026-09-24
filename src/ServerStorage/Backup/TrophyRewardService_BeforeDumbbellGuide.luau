-- Phase 6.6: server-owned reward records; only the owner receives the visual.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GamePass = require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local PlayerData = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))

local M = {}

-- ★ StageごとのTrophy基本Win報酬
-- 今後はここだけ手動変更してください
local TROPHY_WIN_REWARDS = {
	[1] = 1,
	[2] = 3,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 6,
	[7] = 7,
	[8] = 8,
	[9] = 9,
	[10] = 10,
}

local records = {}
local map, remote, resetRun, isDefeated
local sequence = 0
local template = RS.UI.Templates:WaitForChild("TrophyRewardTemplate")

local hitboxes = Instance.new("Folder")
hitboxes.Name = "PersonalTrophyHitboxes"
hitboxes.Parent = workspace

function M.InitializePlayer(player)
	if player:GetAttribute("Win") == nil then
		player:SetAttribute("Win", 0)
	end
end

function M.GetLobbySpawn()
	local area = map and map:FindFirstChild("TrainingArea")
	return area and area:FindFirstChildWhichIsA("SpawnLocation", true)
end

function M.Clear(player)
	local stages = records[player]
	records[player] = nil

	for _, record in stages or {} do
		record.Connection:Disconnect()
		record.Hitbox:Destroy()

		if player.Parent == Players then
			remote:FireClient(player, {
				Type = "TrophyRemoved",
				Id = record.Id
			})
		end
	end
end

function M.SendState(player)
	for _, r in records[player] or {} do
		if not r.Claiming then
			remote:FireClient(player, {
				Type = "TrophySpawn",
				Id = r.Id,
				Stage = r.Stage,
				CFrame = r.CFrame
			})
		end
	end
end

local function collect(player, record, part)
	if not records[player]
		or records[player][record.Stage] ~= record
		or record.Claiming
		or record.Collected then
		return
	end

	if record.Owner ~= player or not isDefeated(player, record.Stage) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not character
		or not part:IsDescendantOf(character)
		or not humanoid
		or humanoid.Health <= 0 then
		return
	end

	local spawn = M.GetLobbySpawn()
	if not spawn then
		return
	end

	-- Verify physical overlap on the server, including when Touched was raised.
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {character}

	if #workspace:GetPartsInPart(record.Hitbox, params) == 0 then
		return
	end

	local win = player:GetAttribute("Win")

	if typeof(win) ~= "number"
		or win ~= win
		or win < 0
		or win == math.huge then
		return
	end

	local baseReward = TROPHY_WIN_REWARDS[record.Stage]

	if typeof(baseReward) ~= "number" then
		warn("Trophy Win reward missing for Stage " .. tostring(record.Stage))
		return
	end

	-- No yield between locking, crediting, consuming, moving and resetting.
	record.Claiming = true

	player:SetAttribute(
		"Win",
		win + GamePass.GetWinReward(player, baseReward)
	)

	record.Collected = true

	if record.Stage == 1 then
		PlayerData.CompleteTutorial(player)
	end

	M.Clear(player)

	humanoid.Health = humanoid.MaxHealth
	humanoid.Sit = false

	local _, size = character:GetBoundingBox()

	character:PivotTo(
		spawn.CFrame
			* CFrame.new(
				0,
				spawn.Size.Y / 2
				+ math.max(size.Y / 2, humanoid.HipHeight + 2)
				+ 2,
				0
			)
	)

	for _, item in character:GetDescendants() do
		if item:IsA("BasePart") then
			item.AssemblyLinearVelocity = Vector3.zero
			item.AssemblyAngularVelocity = Vector3.zero
		end
	end

	resetRun(player)
end

function M.Spawn(player, major)
	if (records[player] and records[player][major])
		or not isDefeated(player, major) then
		return false
	end

	assert(major >= 1 and major <= 10 and major % 1 == 0)

	local stage = map.BattleCorridor:FindFirstChild(
		("Stage%02d"):format(major)
	)

	local bossStage = stage
		and stage:FindFirstChild(
			("Stage%d.5"):format(major)
		)

	local marker = bossStage
		and (
			bossStage:FindFirstChild("EnemySpawn")
			or bossStage:FindFirstChild("MiniBossSpawn")
		)

	local floor = bossStage
		and bossStage:FindFirstChild("Floor")

	assert(marker and floor, "Trophy boss spawn/floor missing")

	local baseReward = TROPHY_WIN_REWARDS[major]

	if typeof(baseReward) ~= "number" then
		warn("Trophy Win reward missing for Stage " .. tostring(major))
		return false
	end

	local handle = template.Handle

	-- Move sideways from the combat zone so victory itself does not collect the trophy.
	local position = marker.Position + marker.CFrame.RightVector * 7

	position = Vector3.new(
		position.X,
		floor.Position.Y + floor.Size.Y / 2 + handle.Size.Y / 2 + 0.6,
		position.Z
	)

	local cf = CFrame.new(position) * handle.CFrame.Rotation

	local box = Instance.new("Part")
	box.Name = "Trophy_" .. player.UserId .. "_Stage" .. major

	box.Size = handle.Size + Vector3.new(0.5, 0.5, 0.5)
	box.CFrame = cf
	box.Anchored = true
	box.CanCollide = false
	box.CanTouch = true
	box.CanQuery = true
	box.Transparency = 1

	box:SetAttribute("OwnerUserId", player.UserId)
	box:SetAttribute("MajorStage", major)
	box:SetAttribute("WinReward", baseReward)

	sequence += 1

	local r = {
		Owner = player,
		Stage = major,
		Id = sequence,
		Hitbox = box,
		CFrame = cf,
		Claiming = false,
		Collected = false
	}

	records[player] = records[player] or {}
	records[player][major] = r

	r.Connection = box.Touched:Connect(function(part)
		collect(player, r, part)
	end)

	box.Parent = hitboxes

	remote:FireClient(player, {
		Type = "TrophySpawn",
		Id = r.Id,
		Stage = r.Stage,
		CFrame = r.CFrame
	})

	return true
end

function M.Initialize(newMap, combatRemote, reset, defeated)
	map = newMap
	remote = combatRemote
	resetRun = reset
	isDefeated = defeated
end

local elapsed = 0

RunService.Heartbeat:Connect(function(dt)
	elapsed += dt

	if elapsed < 0.1 then
		return
	end

	elapsed = 0

	for player, stages in records do
		local character = player.Character

		if character then
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {character}

			for _, record in stages do
				if records[player] ~= stages then
					break
				end

				for _, part in workspace:GetPartsInPart(record.Hitbox, params) do
					collect(player, record, part)

					if records[player] ~= stages then
						break
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(M.Clear)

return M