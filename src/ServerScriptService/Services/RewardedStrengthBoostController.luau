-- Dependency boundary for send-free tests. Runtime dependencies live in the service adapter.
local M={}
function M.New(d)
	local active,nextRequest={},{}
	local receipts={}
	local stopping=false
	local wait=d.Wait or task.wait
	local api={}
	function api.Request(player,action)
		if action~="Ad" and action~="Buy" then return "InvalidRequest" end
		if not d.Config.Enabled then return "Unavailable" end
		if d.IsStudio() then return "StudioPreviewOnly" end
		if active[player] or d.Monotonic()<(nextRequest[player] or 0) then return "Busy" end
		nextRequest[player]=d.Monotonic()+d.Config.RequestCooldownSeconds
		local session=d.Session(player)
		if not session or not session.Loaded or session.OwnershipLost or session.StrengthClosing then return "DataNotLoaded" end
		if action=="Ad" then
			if (session.Data.StrengthBoost.ExpiresAt or 0)>d.Now() then return "BoostActive" end
			if not d.Safe(player) then return "ReturnToLobby" end
		end
		local token={};active[player]=token
		local ok,result=pcall(function()
			if action=="Buy" then d.Purchase(player,d.Config.ProductId);return "Prompted" end
			local reward=d.CreateReward(d.Config.ProductId)
			-- Revalidate after any yield; never start for a departed/replaced profile or outside Lobby.
			if active[player]~=token or d.Session(player)~=session or not d.Safe(player) then return "ReturnToLobby" end
			if session.StrengthClosing or session.OwnershipLost then return "DataNotLoaded" end
			if session.Data.StrengthBoost.ExpiresAt>d.Now() then return "BoostActive" end
			local outcome=d.Show(player,reward,d.Config.PlacementId)
			-- Even ShowCompleted does NOT grant anything. Only ProcessReceipt can do so.
			return outcome==Enum.ShowAdResult.ShowCompleted and "AwaitingReceipt" or "AdUnavailable"
		end)
		if active[player]==token then active[player]=nil end
		return ok and result or "Unavailable"
	end
	function api.Receipt(receipt)
		local pending=Enum.ProductPurchaseDecision.NotProcessedYet
		if type(receipt)~="table" or receipt.ProductId~=d.Config.ProductId or type(receipt.PurchaseId)~="string"
			or receipt.PurchaseId=="" or type(receipt.PlayerId)~="number" or receipt.PlayerId<=0 or receipt.PlayerId%1~=0 then return pending end
		if d.IsStudio() then return pending end -- No Studio success simulation in production code.
		local player=d.Player(receipt.PlayerId)
		if not player or stopping then return pending end
		local session=d.Session(player)
		if not session or not session.Loaded or session.OwnershipLost or session.StrengthClosing then return pending end
		local channel=receipt.ProductPurchaseChannel
		local channelName="Unknown" -- Legacy receipts may omit the channel; never discard a paid receipt.
		if typeof(channel)=="EnumItem" and channel.EnumType==Enum.ProductPurchaseChannel then channelName=channel.Name end
		local bucket=receipts[player]
		if not bucket or bucket.Session~=session then bucket={Session=session,Jobs={}};receipts[player]=bucket end
		local function current()
			return not stopping and receipts[player]==bucket and d.Player(receipt.PlayerId)==player
				and d.Session(player)==session and session.Loaded and not session.OwnershipLost and not session.StrengthClosing
		end
		local job=bucket.Jobs[receipt.PurchaseId]
		if job then
			-- Parallel callbacks share the original receipt's result, never a second writer.
			while not job.Done and current() do wait(d.Config.ReceiptWaitSeconds or 1) end
			return job.Done and job.Decision or pending
		end
		job={Done=false};bucket.Jobs[receipt.PurchaseId]=job
		local request={PurchaseId=receipt.PurchaseId,PlayerId=receipt.PlayerId,ProductId=receipt.ProductId,Channel=channelName}
		local retryAt=0
		local decision=pending
		-- Keep THIS ProcessReceipt invocation alive through transient contention.
		-- Memory-only waits; no polling DataStore and no dependence on Roblox redelivery.
		while current() do
			local op=session.PendingItemMutation
			local own=op and op.StrengthBoost and op.PurchaseId==request.PurchaseId and op.ProductId==request.ProductId
			local ready=not session.Saving and (not op or own and not op.Resolving and not op.RetryScheduled)
			if ready and d.Monotonic()>=retryAt then
				local ok,confirmed,reason=pcall(d.Commit,player,request)
				if ok and confirmed then
					if current() then decision=Enum.ProductPurchaseDecision.PurchaseGranted end
					break
				end
				if ok and reason~="DataSaving" and reason~="InventorySavePending" then break end
				-- Existing 1/2/4/8-second mutation retries retain priority. Once exhausted,
				-- only a pending legitimate receipt can retry at this slower cadence.
				retryAt=d.Monotonic()+(d.Config.ReceiptRecoverySeconds or 30)
			end
			wait(d.Config.ReceiptWaitSeconds or 1)
		end
		job.Decision=decision;job.Done=true;bucket.Jobs[receipt.PurchaseId]=nil
		if receipts[player]==bucket and next(bucket.Jobs)==nil then receipts[player]=nil end
		return decision
	end
	function api.Forget(player) active[player]=nil;nextRequest[player]=nil;receipts[player]=nil end
	function api.Shutdown() stopping=true;table.clear(receipts);table.clear(active);table.clear(nextRequest) end
	return api
end
return M
