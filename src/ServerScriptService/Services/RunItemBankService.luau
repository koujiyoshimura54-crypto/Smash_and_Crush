-- Shared World1 run banking for Back and Trophy. No travel, UI or Win rewards.
local Players = game:GetService("Players")
local Services = script.Parent
local Run = require(Services.RunInventoryService)
local Items = require(Services.ItemService)
local Data = require(Services.PlayerDataService)
local M = {}
local busy = {}
local contexts = {}
local pendingNotifications = {}
local RS = game:GetService("ReplicatedStorage")
local notification = Instance.new("RemoteEvent")
notification.Name = "RunLootBanked"
notification.Parent = RS.Remotes
local snapshot = Instance.new("RemoteFunction")
snapshot.Name = "BankedItemNotificationState"
snapshot.Parent = RS.Remotes
local function notificationState(player)
 local session = Data.Get(player)
 if not session or not session.Loaded then return {Loaded=false} end
 local owned = table.clone(session.Data.OwnedItems or {})
 -- Confirmed ownership can precede arrival. Hide only that return's additions.
 for _,token in pairs(pendingNotifications[player] or {}) do
  if token.Committed and not token.Arrived and token.ResetToken==session.Data.ResetToken then
   for id,count in pairs(token.Items) do owned[id]=math.max(0,(owned[id] or 0)-count) end
  end
 end
 return {Loaded=true,OwnedItems=owned}
end
snapshot.OnServerInvoke = notificationState
require(Services.LobbySpawnService).Arrived:Connect(function(player)
 local pending=pendingNotifications[player]
 if not pending then return end
 local changed=false
 for id,entry in pairs(pending) do
  entry.Arrived=true
  if entry.Committed then pending[id]=nil;changed=true end
 end
 if changed then notification:FireClient(player,notificationState(player)) end
 if not next(pending) then pendingNotifications[player]=nil end
end)
local function forget(player)
 local context = contexts[player]
 if context and context.Connection then context.Connection:Disconnect() end
 contexts[player] = nil
end

function M.Commit(player, runId)
 if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then return false, "InvalidPlayer" end
 if typeof(runId) ~= "string" or #runId > 64 then return false, "InvalidRunId" end
 if busy[player] then return false, "ReturnBusy" end
 busy[player] = true
 local ok, success, reason, token = xpcall(function()
		local token, code = Run.BeginReturn(player, runId)
		if not token then return false, code end
		local context = contexts[player]
		if context and context.Id ~= token.Id then
			if context.Operation and not context.Operation.Result then return false, "InventorySavePending" end
			forget(player)
			context = nil
		end
		if not context then
			context = {Id = token.Id, RunId = token.RunId, Ores = table.clone(token.Ores), Validate = function() return Run.CanReturn(player, token) end}
			contexts[player] = context
   if token.Count>0 then
    local session=Data.Get(player)
    local entry={Items=table.clone(token.Items),ResetToken=session.Data.ResetToken}
    pendingNotifications[player]=pendingNotifications[player] or {}
    pendingNotifications[player][token.Id]=entry
    -- Called by the existing journal's terminal resolution, including death/retry.
    context.OnResolved=function(result)
     local pending=pendingNotifications[player]
     if not pending or pending[token.Id]~=entry then return end
     entry.Committed=result=="Changed"
     if not entry.Committed or entry.Arrived then pending[token.Id]=nil end
     if entry.Committed and entry.Arrived then notification:FireClient(player,notificationState(player)) end
     if not next(pending) then pendingNotifications[player]=nil end
    end
   end
			context.Connection = player:GetAttributeChangedSignal("RunInventoryId"):Connect(function()
				if not context.Committed and not context.Validate() then
					context.Cancelled = true
					if context.Operation and not context.Operation.Result then
						task.spawn(function() Data.ResolveItemMutation(player) end)
					end
				end
			end)
		end
		if not context.Validate() then return false, "StaleRun" end
		local changed, result = true, "EmptyRun"
		context.Permit = true
		if token.Count > 0 then
			if context.Operation and context.Operation.Result then
				changed, result = context.Operation.Result == "Changed", context.Operation.Result
			elseif context.Operation then
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
    if context.OnResolved then context.OnResolved(result) end
				Run.ReleaseReturn(player, token)
				forget(player)
			end
			return false, result
		end
		-- No yield between confirmed ownership and retiring this snapshot.
		-- Callers own their UI, rewards and lobby/reset behavior.
		if not Run.CompleteReturn(player, token) then return false, "StaleRun" end

  forget(player)
  return true, "Banked", token
 end, debug.traceback)
 local context = contexts[player]
 if context then context.Permit = false end
 busy[player] = nil
 if not ok then warn("[RunItemBank] " .. tostring(success)); return false, "ReturnFailed" end
 return success, reason, token
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
 pendingNotifications[player] = nil
end)

return M
