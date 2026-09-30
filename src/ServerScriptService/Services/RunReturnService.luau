local Players = game:GetService("Players")
local Services = script.Parent
local Run = require(Services.RunInventoryService)
local Items = require(Services.ItemService)
local Data = require(Services.PlayerDataService)
local Enemy = require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Trophy = require(Services.TrophyRewardService).ForWorld(1)
local Training = require(Services.TrainingManager)
local Speed = require(Services.SpeedService)
local M = {}
local busy = {}
local contexts = {}
local function forget(player)
	local context = contexts[player]
	if context and context.Connection then context.Connection:Disconnect() end
	contexts[player] = nil
end

local function returnToLobby(player, character, spawn, speed)
	-- Reuse the normal World1 reset, never Trophy.collect or its reward path.
	Enemy.InitializePlayer(player)
	-- InitializePlayer prepares an active run for ordinary respawns. A voluntary
	-- return ends this run; the next World1 StartRun activates a fresh generation.
	Run.Invalidate(player)
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
		local spawn = Trophy.GetLobbySpawn()
		if not spawn or not Enemy.IsReady() then return false, "LobbyUnavailable" end
		local token, code = Run.BeginReturn(player, runId)
		if not token then return false, code end
		local context = contexts[player]
		if context and context.Id ~= token.Id then
			if context.Operation and not context.Operation.Result then return false, "InventorySavePending" end
			forget(player)
			context = nil
		end
		if not context then
			context = {Id = token.Id, RunId = token.RunId, Validate = function() return Run.CanReturn(player, token) end}
			contexts[player] = context
			context.Connection = player:GetAttributeChangedSignal("RunInventoryId"):Connect(function()
				if not context.Committed and not context.Validate() then
					context.Cancelled = true
					if context.Operation and not context.Operation.Result then
						task.spawn(function() Data.ResolveItemMutation(player) end)
					end
				end
			end)
		end
		-- Resolve any potentially yielding entitlement read BEFORE the commit.
		local speed = Speed.GetState(player).WalkSpeed
		if not context.Validate() then return false, "StaleRun" end
		local changed, result = true, "EmptyRun"
		context.Permit = true
		if token.Count > 0 then
			if context.Operation then
				changed, result = Data.ResolveItemMutation(player)
			else
				changed, result = Items.RunItemTransaction(player, function(transaction)
					for id, amount in pairs(token.Items) do
						local added, failure = Items.AddItem(player, id, amount, transaction)
						if not added then return false, failure end
					end
					return true
				end, {RunReturn = context})
			end
		end
		context.Permit = false
		if not changed then
			if not context.Operation or context.Operation.Result then
				Run.ReleaseReturn(player, token)
				forget(player)
			end
			return false, result
		end
		-- No yield after the confirmed save: invalidate old ID, clear run, reset,
		-- heal and teleport the same living Character as one server completion.
		if not Run.CompleteReturn(player, token) then return false, "StaleRun" end
		returnToLobby(player, token.Character, spawn, speed)
		forget(player)
		return true, "Returned"
	end, debug.traceback)
	local context = contexts[player]
	if context then context.Permit = false end
	busy[player] = nil
	if player.Parent == Players then player:SetAttribute("RunReturnBusy", false) end
	if not ok then warn("[RunReturn] " .. tostring(success)); return false, "ReturnFailed" end
	return success, reason
end

Players.PlayerRemoving:Connect(function(player)
	local context = contexts[player]
	if context and not context.Committed then
		context.Cancelled = true
		if context.Operation and not context.Operation.Result then
			task.spawn(function() Data.ResolveItemMutation(player) end)
		end
	end
	forget(player)
	busy[player] = nil
end)

return M
