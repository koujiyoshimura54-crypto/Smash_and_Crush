local Players = game:GetService("Players")
local Services = script.Parent
local Bank = require(Services.RunItemBankService)
local Enemy = require(game.ServerScriptService.World.EnemyManager)
local Trophy = require(Services.TrophyRewardService)
local Training = require(Services.TrainingManager)
local Speed = require(Services.SpeedService)
local Placement = require(Services.LobbySpawnService)
local M = {}
local busy = {}
local function returnToLobby(player, character, spawn, worldEnemy)
	-- Reuse the normal World1 reset, never Trophy.collect or its reward path.
	(worldEnemy or Enemy).InitializePlayer(player)
	-- Keep the fresh active bag and combat Run ID aligned for walking re-entry.
	-- Bank.Begin already retained the previous bag as a separate return receipt.
	Training.StopTraining(player)
	local hum = character:FindFirstChildOfClass("Humanoid")
	hum.Health = hum.MaxHealth
	hum.Sit = false
	-- Persistence/streaming may yield while the selected Speed changes.
	-- Apply the current server-owned value only after the return reset.
	Speed.Apply(player)
	return Placement.MoveToLobby(player, character, Placement.WorldFor(player))
end

function M.Request(player, runId)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return false, "InvalidPlayer" end
	if typeof(runId) ~= "string" or #runId > 64 then return false, "InvalidRunId" end
	if busy[player] then return false, "ReturnBusy" end
	busy[player] = true
	player:SetAttribute("RunReturnBusy", true)
	local ok, success, reason = xpcall(function()
  local worldId=Placement.WorldFor(player)
  local worldEnemy=Enemy.ForWorld(worldId)
  local worldTrophy=Trophy.ForWorld(worldId)
  if worldId==2 then
   local ps=worldEnemy.GetPlayerState(player)
   local stage=player:GetAttribute("World2CurrentStage") or 1
   local wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
   if not ps or ps.RunReturnId~=runId then return false,"StaleRun" end
   if ps.Defeated[stage] or not wall.IsBossUnlockedForStage(player,stage) then return false,"NotReturnable" end
  end
  local spawn = worldTrophy.GetLobbySpawn()
		if not spawn or not worldEnemy.IsReady() then return false, "LobbyUnavailable" end
		local placement = Placement.StreamLobby(player, player.Character, worldId)
		if not placement then return false, "CharacterNotReady" end
		local token, code = Bank.Begin(player, runId)
		local committed=token~=nil
		if not committed then return false, code end
		if not Placement.IsCurrent(player, placement) then return false, "StaleRun" end
		local placed, why = returnToLobby(player, token.Character, spawn, worldEnemy)
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
