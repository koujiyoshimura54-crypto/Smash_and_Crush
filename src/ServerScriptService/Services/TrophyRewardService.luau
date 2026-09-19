-- Phase 6.6: server-owned reward records; only the owner receives the visual.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GamePass = require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local PlayerData = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))

local M = {}

local RewardConfig=require(RS.Config:WaitForChild("TrophyRewardConfig"))
local WorldGateConfig=require(RS.Config:WaitForChild("WorldGateConfig"))

-- Studio session metrics only: never written to PlayerData or DataStore.
local studioCollections=setmetatable({}, {__mode="k"})
function M.GetStudioCollectionCounts(player)
 if not RunService:IsStudio() then return nil end
 local counts=studioCollections[player]
 return counts and {Total=counts.Total,ByStage=table.clone(counts.ByStage)} or {Total=0,ByStage={}}
end

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
	local spawn = area and area:FindFirstChild("SpawnLocation")
	return spawn and spawn:IsA("SpawnLocation") and spawn or nil
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
				WinReward = GamePass.GetWinReward(player, RewardConfig.GetBaseReward(r.Stage)),
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

	if not PlayerData.IsLoaded(player) then return end

	local win = player:GetAttribute("Win")

	if typeof(win) ~= "number"
		or win ~= win
		or win < 0
		or win == math.huge then
		return
	end

	local baseReward = RewardConfig.GetBaseReward(record.Stage)

	if typeof(baseReward) ~= "number" then
		warn("Trophy Win reward missing for Stage " .. tostring(record.Stage))
		return
	end

	-- No yield between locking, crediting, consuming, moving and resetting.
	record.Claiming = true

	local winReward = GamePass.GetWinReward(player, baseReward)
	local updatedWin = win + winReward
	player:SetAttribute("Win", updatedWin)

	record.Collected = true
	if record.Stage == WorldGateConfig.CompletionStage then
		PlayerData.UnlockWorld(player, WorldGateConfig.RequiredWorld)
	end
 if RunService:IsStudio() then
  local counts=studioCollections[player]
  if not counts then counts={Total=0,ByStage={}};studioCollections[player]=counts end
  counts.Total+=1
  counts.ByStage[record.Stage]=(counts.ByStage[record.Stage] or 0)+1
 end
	-- Presentation only: emitted after the authoritative Win value has changed.
	remote:FireClient(player, {
		Type = "TrophyCollected",
		Id = record.Id,
		Stage = record.Stage,
		WinReward = winReward,
		Win = updatedWin,
	})
 -- Presentation notification only, after Win credit and confirmed collection.
 if record.Stage == 1 then
  local session=PlayerData.Get(player)
  local owned=session and session.Loaded and session.Data and session.Data.OwnedDumbbells
  if typeof(owned)=="table" then
   remote:FireClient(player,{
    Type="Dumbbell1GuideUnlocked",
    Stage=record.Stage,
    TrophyId=record.Id,
    OwnsNormal01=owned.NORMAL_01==true,
   })
  end
 end


	-- Normal completion: validated Stage1 pickup. Stage2 Boss attack is the fallback.
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

	assert(major >= 1 and major <= #RewardConfig.Rewards and major % 1 == 0)

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

	local baseReward = RewardConfig.GetBaseReward(major)

	if typeof(baseReward) ~= "number" then
		warn("Trophy Win reward missing for Stage " .. tostring(major))
		return false
	end

	local handle = template.Handle

	-- Floor-relative placement on the left of the boss area, clear of the enlarged visual.
	local inset = math.max(handle.Size.X / 2 + 4, floor.Size.X * 0.12)
	local padLocal = CFrame.new(
		-floor.Size.X / 2 + inset,
		floor.Size.Y / 2 + handle.Size.Y / 2 + 0.03,
		0
	)
	local cf = floor.CFrame * padLocal * handle.CFrame.Rotation

	local box = Instance.new("Part")
	box.Name = "Trophy_" .. player.UserId .. "_Stage" .. major

	-- A shallow volume above the pad catches feet, without a surrounding pickup radius.
	box.Size = handle.Size + Vector3.new(0, 0.6, 0)
	box.CFrame = cf * CFrame.new(0, 0.3, 0)
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
		WinReward = GamePass.GetWinReward(player, baseReward),
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
