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
local watched=setmetatable({}, {__mode="k"})
local function overlap(character,pad,margin)
 local params=OverlapParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={character}
 return workspace:GetPartBoundsInBox(pad.CFrame*CFrame.new(0,0.3,0),pad.Size+Vector3.new(margin or 0,0.6,margin or 0),params)
end
local function eligible(player,record)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 return player.Parent==Players and records[player] and records[player][record.Stage]==record
  and record.Character==character and humanoid and humanoid.Health>0
  and (player:GetAttribute("CurrentWorld") or 1)==worldId and isDefeated(player,record.Stage)
end

function M.InitializePlayer(player)
 if not watched[player] then
  watched[player]=true
  player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() M.Clear(player) end)
  player.CharacterRemoving:Connect(function() M.Clear(player) end)
 end
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
		for _,connection in record.Connections do connection:Disconnect() end

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
				WinReward = GamePass.GetTrophyWinReward(player, RewardConfig.GetBaseReward(r.Stage,worldId),worldId,false),
				StaticButtons = true,
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

local function collectAttempt(player, record, part, double, purchased)
	if (player:GetAttribute("CurrentWorld") or 1)~=worldId or not records[player]
		or records[player][record.Stage] ~= record
		or record.Claiming
		or (activeClaims[player] and activeClaims[player] ~= record) then
		return
	end

	if record.Owner ~= player or not eligible(player,record) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not character
		or (not purchased and (not part or not part:IsDescendantOf(character)))
		or not humanoid
		or humanoid.Health <= 0 then
		return
	end

 local pad=double and record.DoublePad or record.Hitbox
 if not purchased and #overlap(character,pad)==0 then return end

	if not PlayerData.IsLoaded(player) then return end

	-- Serialize this player's receipt before any possible ownership lookup yield.
	activeClaims[player] = record
	record.Claiming = true
	if not record.Collected then
	 local baseReward = RewardConfig.GetBaseReward(record.Stage, worldId)
	 if typeof(baseReward) ~= "number" then diagnose(player, record, "MissingReward"); return end
	 local winReward = GamePass.GetTrophyWinReward(player, baseReward, worldId, double)
	 -- A cold pass lookup can yield; never use pre-yield balance or eligibility.
	 if not records[player] or records[player][record.Stage] ~= record
	  or player.Character ~= character or humanoid.Health <= 0
	  or (player:GetAttribute("CurrentWorld") or 1) ~= worldId
	  or not isDefeated(player, record.Stage) or not PlayerData.IsLoaded(player) then return end
	 if not purchased and #overlap(character,pad)==0 then return end
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
    OwnsNormal01=(require(game.ReplicatedStorage.Modules.InventoryCounts).Count(owned.NORMAL_01) or 0)>0,
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

local collect
collect=function(player,record,part,double,purchased)
 if not eligible(player,record) then return end
 if not purchased and #overlap(record.Character,double and record.DoublePad or record.Hitbox)==0 then return end
 if double and not record.Collected and not purchased then
  if record.Prompting or record.InsideDouble then return end
  record.InsideDouble=true
  record.Prompting=true
  task.spawn(function()
   local ok,err=xpcall(function()
    local owned,status=GamePass.GetTrophyDoubleOwnership(player)
    if not eligible(player,record) or record.Collected then return end
    if owned then
     if #overlap(record.Character,record.DoublePad)>0 then collect(player,record,part,true,true) end
     return
    end
    if status~="Verified" then return end
    local token=record.Purchase or {}
    record.Purchase=token
    local function current()
     return eligible(player,record) and not record.Collected and record.Purchase==token
    end
    local prompted,reason=GamePass.Prompt(player,{
     IsCurrent=function() return current() and #overlap(record.Character,record.DoublePad)>0 end,
     OnOwned=function()
      if current() then collect(player,record,nil,true,true) end
     end,
    })
    if not prompted and reason=="AlreadyOwned" and current() then collect(player,record,nil,true,true) end
   end,debug.traceback)
   record.Prompting=false
   if not ok then diagnose(player,record,"Purchase:"..tostring(err)) end
  end)
  return
 end
 if record.Processing or (record.RetryAt and os.clock()<record.RetryAt) then return end
 record.Processing=true
 task.spawn(function()
  local ok,err=xpcall(function() collectAttempt(player,record,part,double,purchased) end,debug.traceback)
  record.Claiming=false
  record.Processing=false
  if not record.Collected and activeClaims[player]==record then activeClaims[player]=nil end
  if record.Collected then record.RetryAt=os.clock()+1 end
  if not ok then diagnose(player,record,"Exception:"..tostring(err)) end
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
			(worldId==2 and "Stage%d.Boss" or "Stage%d.5"):format(major)
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

 -- Authored equipment is saved in the place; never regenerate buttons per run.
 local normal=stage:FindFirstChild("TrophyNormalButton")
 local double=stage:FindFirstChild("TrophyDoubleButton")
 local box=normal and normal:FindFirstChild("Handle")
 local doublePad=double and double:FindFirstChild("Handle")
 assert(box and doublePad,"Saved Trophy buttons missing")
 local cf=box.CFrame

	sequence += 1

	local r = {
		Owner = player,
		Character = player.Character,
		DoublePad = doublePad,
		Stage = major,
		Id = sequence,
		Hitbox = box,
		CFrame = cf,
		Claiming = false,
		Collected = false
	}

	records[player] = records[player] or {}
	records[player][major] = r

 r.Connections={
  box.Touched:Connect(function(part)
   if player.Character and part:IsDescendantOf(player.Character) then collect(player,r,part,false,false) end
  end),
  doublePad.Touched:Connect(function(part)
   if player.Character and part:IsDescendantOf(player.Character) then collect(player,r,part,true,false) end
  end),
 }

	remote:FireClient(player, {
		Type = "TrophySpawn",
		Id = r.Id,
		Stage = r.Stage,
		WinReward = GamePass.GetTrophyWinReward(player, baseReward,worldId,false),
		StaticButtons = true,
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
			for _, record in stages do
				if records[player] ~= stages then
					break
				end

    if not eligible(player,record) then continue end
    if #overlap(character,record.DoublePad,1.5)==0 then record.InsideDouble=false end
    local doubleParts=overlap(character,record.DoublePad)
    if doubleParts[1] then collect(player,record,doubleParts[1],true,false) end
				for _, part in overlap(character,record.Hitbox) do
					collect(player, record, part, false, false)

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
