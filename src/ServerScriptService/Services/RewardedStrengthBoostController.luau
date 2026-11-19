-- Dependency boundary for send-free tests. Runtime dependencies live in the service adapter.
local M={}
function M.New(d)
	local active,nextRequest={},{}
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
		if not player then return pending end
		local channel=receipt.ProductPurchaseChannel
		local channelName="Unknown" -- Legacy receipts may omit the channel; never discard a paid receipt.
		if typeof(channel)=="EnumItem" and channel.EnumType==Enum.ProductPurchaseChannel then channelName=channel.Name end
		local ok,confirmed=pcall(d.Commit,player,{PurchaseId=receipt.PurchaseId,PlayerId=receipt.PlayerId,
			ProductId=receipt.ProductId,Channel=channelName})
		-- Enabled, ad outcome, active UI, safe area and current expiry never gate a legitimate receipt.
		return ok and confirmed and Enum.ProductPurchaseDecision.PurchaseGranted or pending
	end
	function api.Forget(player) active[player]=nil;nextRequest[player]=nil end
	return api
end
return M
