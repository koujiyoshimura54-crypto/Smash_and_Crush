local contexts={}
local function forWorld(worldId)
 assert(worldId==1 or worldId==2,"Unsupported world")
 if contexts[worldId] then return contexts[worldId] end
-- Phase 6.6: server-owned reward records; only the owner receives the visual.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Placement = require(game.ServerScriptService.Services.LobbySpawnService)
local GamePass = require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local PlayerData = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))

local Bank = worldId==1 and require(game.ServerScriptService.Services.RunItemBankService)
local Run = worldId==1 and require(game.ServerScriptService.Services.RunInventoryService)

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
local activeClaims = {}
local map, remote, resetRun, isDefeated
local sequence = 0
local template = RS.UI.Templates:WaitForChild("TrophyRewardTemplate")

local hitboxes = Instance.new("Folder")
hitboxes.Name = worldId==2 and "World2PersonalTrophyHitboxes" or "PersonalTrophyHitboxes"
hitboxes.Parent = workspace

function M.InitializePlayer(player)
	if player:GetAttribute("Win") == nil then
		player:SetAttribute("Win", 0)
	end
end

function M.GetLobbySpawn()
	local area = map and map:FindFirstChild("TrainingArea")
	local spawn = area and area:FindFirstChild(worldId==2 and "World2LobbySpawn" or "SpawnLocation")
	return spawn and spawn:IsA("BasePart") and spawn or nil
end

function M.Clear(player)
	local stages = records[player]
	records[player] = nil
	activeClaims[player] = nil

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
				WinReward = GamePass.GetWinReward(player, RewardConfig.GetBaseReward(r.Stage,worldId),worldId),
				CFrame = r.CFrame
			})
		end
	end
end

local function diagnose(player, record, reason)
 record.Diagnostics = record.Diagnostics or {}
 if record.Diagnostics[reason] then return end
 record.Diagnostics[reason] = true
 warn(("[TrophyReward] user=%d world=%d stage=%d id=%d credited=%s %s"):format(
  player.UserId, worldId, record.Stage, record.Id, tostring(record.Collected), reason))
end

local function collectAttempt(player, record, part)
	if (player:GetAttribute("CurrentWorld") or 1)~=worldId or not records[player]
		or records[player][record.Stage] ~= record
		or record.Claiming
		or (activeClaims[player] and activeClaims[player] ~= record) then
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

	-- Verify physical overlap on the server, including when Touched was raised.
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {character}

	if #workspace:GetPartsInPart(record.Hitbox, params) == 0 then
		return
	end

	if not PlayerData.IsLoaded(player) then return end

	-- Serialize this player's receipt before any possible ownership lookup yield.
	activeClaims[player] = record
	record.Claiming = true
	if not record.Collected then
	 local baseReward = RewardConfig.GetBaseReward(record.Stage, worldId)
	 if typeof(baseReward) ~= "number" then diagnose(player, record, "MissingReward"); return end
	 local winReward = GamePass.GetWinReward(player, baseReward, worldId)
	 -- A cold pass lookup can yield; never use pre-yield balance or eligibility.
	 if not records[player] or records[player][record.Stage] ~= record
	  or player.Character ~= character or humanoid.Health <= 0
	  or (player:GetAttribute("CurrentWorld") or 1) ~= worldId
	  or not isDefeated(player, record.Stage) or not PlayerData.IsLoaded(player) then return end
	 if #workspace:GetPartsInPart(record.Hitbox, params) == 0 then return end
	 local win = player:GetAttribute("Win")
	 if typeof(win) ~= "number" or win ~= win or win < 0 or win == math.huge then
	  diagnose(player, record, "InvalidWin"); return
	 end
	 local updatedWin = win + winReward
	 -- SetWin updates the loaded session/attribute and marks the existing save path dirty.
	 -- No yield between credit success and consuming this receipt.
	 if not PlayerData.SetWin(player, updatedWin) then diagnose(player, record, "CreditRejected"); return end
	 record.Collected = true
	 record.WinReward, record.Win = winReward, updatedWin
	end
	local winReward, updatedWin = record.WinReward, record.Win
	if not record.Notified then
	 record.Notified = true
	if worldId==1 and record.Stage == WorldGateConfig.CompletionStage then
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
 if worldId==1 and record.Stage == 1 then
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
	if worldId==1 and record.Stage == 1 then
		PlayerData.CompleteTutorial(player)
	end

	end -- Notify once; retries below never credit again.

	local function current()
	 return player.Parent == Players and records[player] and records[player][record.Stage] == record
	  and player.Character == character and humanoid.Health > 0
	  and (player:GetAttribute("CurrentWorld") or 1) == worldId
	end
	-- Durable item banking remains mandatory before reset, but cannot delay Win credit.
	if Bank and not record.Banked then
	 local snapshot = Run.GetSnapshot(player)
	 local committed, reason = false, "MissingRun"
	 if snapshot then committed, reason = Bank.Commit(player, snapshot.RunId) end
	 if not committed then diagnose(player, record, "Bank:" .. tostring(reason)); return end
	 record.Banked = true
	end
	if not current() then return end
	local placement, reason = Placement.StreamLobby(player, character, worldId)
	if not placement then diagnose(player, record, "Stream:" .. tostring(reason)); return end
	if not current() or not Placement.IsCurrent(player, placement) then return end
	humanoid.Health = humanoid.MaxHealth
	humanoid.Sit = false
	local placed, why = Placement.MoveToLobby(player, character, worldId)
	if not placed then diagnose(player, record, "Return:" .. tostring(why)); return end
	-- Keep receipt/Banked until travel succeeds; failures can retry without another credit.
	M.Clear(player)
	resetRun(player)
end

local function collect(player, record, part)
 if record.Processing or (record.RetryAt and os.clock() < record.RetryAt) then return end
 record.Processing = true
 -- Never make one player's streaming/save suspend the shared overlap scan.
 task.spawn(function()
  local ok, err = xpcall(function() collectAttempt(player, record, part) end, debug.traceback)
  record.Claiming = false
  record.Processing = false
  if not record.Collected and activeClaims[player] == record then activeClaims[player] = nil end
  -- Backoff is only for an already credited return retry, never initial reward acceptance.
  if record.Collected then record.RetryAt = os.clock() + 1 end
  if not ok then diagnose(player, record, "Exception:" .. tostring(err)) end
 end)
end

function M.Spawn(player, major)
 if (player:GetAttribute("CurrentWorld") or 1)~=worldId then return false,"WrongWorld" end
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

	local baseReward = RewardConfig.GetBaseReward(major,worldId)

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
		WinReward = GamePass.GetWinReward(player, baseReward,worldId),
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


 contexts[worldId]=M
 M.ForWorld=forWorld
 return M
end
return forWorld(1)
