local Players = game:GetService("Players")
local Services = script.Parent
local Run = require(Services.RunInventoryService)
local Bank = require(Services.RunItemBankService)
local Enemy = require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Trophy = require(Services.TrophyRewardService).ForWorld(1)
local Training = require(Services.TrainingManager)
local Speed = require(Services.SpeedService)
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
	local _, size = character:GetBoundingBox()
	character:PivotTo(spawn.CFrame * CFrame.new(0,
		spawn.Size.Y / 2 + math.max(size.Y / 2, hum.HipHeight + 2) + 2, 0))
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
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
   returnToLobby(player,character,spawn,Speed.GetState(player).WalkSpeed,worldEnemy)
   return true,"Returned"
  end
  local spawn = Trophy.GetLobbySpawn()
		if not spawn or not Enemy.IsReady() then return false, "LobbyUnavailable" end
		-- Read the normal speed before the shared durable commit.
		local speed = Speed.GetState(player).WalkSpeed
		local committed, code, token = Bank.Commit(player, runId)
		if not committed then return false, code end
		returnToLobby(player, token.Character, spawn, speed)
		return true, "Returned"
	end, debug.traceback)
	busy[player] = nil
	if player.Parent == Players then player:SetAttribute("RunReturnBusy", false) end
	if not ok then warn("[RunReturn] " .. tostring(success)); return false, "ReturnFailed" end
	return success, reason
end

Players.PlayerRemoving:Connect(function(player) busy[player] = nil end)

return M
