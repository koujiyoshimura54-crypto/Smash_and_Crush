local Players = game:GetService("Players")
local Services = script.Parent
local Run = require(Services.RunInventoryService)
local Bank = require(Services.RunItemBankService)
local Enemy = require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Trophy = require(Services.TrophyRewardService).ForWorld(1)
local Training = require(Services.TrainingManager)
local Speed = require(Services.SpeedService)
local Placement = require(Services.LobbySpawnService)
local M = {}
local busy = {}
local function returnToLobby(player, character, spawn, speed, worldEnemy)
	-- Reuse the normal World1 reset, never Trophy.collect or its reward path.
	(worldEnemy or Enemy).InitializePlayer(player)
	-- InitializePlayer prepares an active run for ordinary respawns. A voluntary
	-- return ends this run; the next World1 StartRun activates a fresh generation.
	if not worldEnemy then Run.Invalidate(player) end
	Training.StopTraining(player)
	local hum = character:FindFirstChildOfClass("Humanoid")
	hum.Health = hum.MaxHealth
	hum.Sit = false
	hum.WalkSpeed = speed
	return Placement.MoveToLobby(player, character, Placement.WorldFor(player))
end

function M.Request(player, runId)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return false, "InvalidPlayer" end
	if typeof(runId) ~= "string" or #runId > 64 then return false, "InvalidRunId" end
	if busy[player] then return false, "ReturnBusy" end
	busy[player] = true
	player:SetAttribute("RunReturnBusy", true)
	local ok, success, reason = xpcall(function()
  if player:GetAttribute("CurrentWorld")==2 then
   local Data=require(Services.PlayerDataService)
   local session=Data.Get(player)
   if not session or not session.Loaded or session.Saving or session.PendingItemMutation or session.OwnershipLost then return false,"DataSaving" end
   local worldEnemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
   local worldTrophy=require(Services.TrophyRewardService).ForWorld(2)
   local wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
   local currentStage=player:GetAttribute("World2CurrentStage") or 1
   local ps=worldEnemy.GetPlayerState(player)
   if not worldEnemy.IsReady() or not ps or ps.RunReturnId~=runId then return false,"StaleRun" end
   if ps.Defeated[currentStage] or not wall.IsBossUnlockedForStage(player,currentStage) then return false,"NotReturnable" end
   local character=player.Character;local hum=character and character:FindFirstChildOfClass("Humanoid")
   local root=character and character:FindFirstChild("HumanoidRootPart")
   local spawn=worldTrophy.GetLobbySpawn()
   if not root or not hum or hum.Health<=0 or not spawn then return false,"CharacterNotReady" end
   local placement=Placement.StreamLobby(player,character,2)
   if not placement or not Placement.IsCurrent(player,placement) or ps~=worldEnemy.GetPlayerState(player)
    or ps.RunReturnId~=runId or hum.Health<=0 then return false,"StaleRun" end
   local placed,why=returnToLobby(player,character,spawn,Speed.GetState(player).WalkSpeed,worldEnemy)
   if not placed then return false,why end
   return true,"Returned"
  end
  local spawn = Trophy.GetLobbySpawn()
		if not spawn or not Enemy.IsReady() then return false, "LobbyUnavailable" end
		-- Read the normal speed before the shared durable commit.
		local speed = Speed.GetState(player).WalkSpeed
		local placement = Placement.StreamLobby(player, player.Character, 1)
		if not placement then return false, "CharacterNotReady" end
		local committed, code, token = Bank.Commit(player, runId)
		if not committed then return false, code end
		if not Placement.IsCurrent(player, placement) then return false, "StaleRun" end
		local placed, why = returnToLobby(player, token.Character, spawn, speed)
		if not placed then return false, why end
		return true, "Returned"
	end, debug.traceback)
	busy[player] = nil
	if player.Parent == Players then player:SetAttribute("RunReturnBusy", false) end
	if not ok then warn("[RunReturn] " .. tostring(success)); return false, "ReturnFailed" end
	return success, reason
end

Players.PlayerRemoving:Connect(function(player) busy[player] = nil end)

return M
