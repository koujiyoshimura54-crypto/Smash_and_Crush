local Players = game:GetService("Players")
local Marketplace = game:GetService("MarketplaceService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Config.StrengthRewardConfig)
local Data = require(script.Parent.PlayerDataService)
local State = require(script.Parent.StrengthRewardState)
local Reference = require(script.Parent.StrengthReference)
local Passes = require(script.Parent.GamePassService)
local M = {}
local locks, prompts, ready, nextRequest = {}, {}, {}, {}
local initialized = false
local function sessionFor(player)
	local s = Data.Get(player)
	if not s or not s.Loaded or s.OwnershipLost or s.StrengthClosing then return nil end
	return s
end
function M.View(player)
	local s = sessionFor(player)
	if not s then return {Ready = false} end
	local id, reward = State.NextReward(s.Data.StrengthRewards)
	local rate = ready[player] and Reference.Get(player) or nil
	local blocked = false
	for _, intent in pairs(s.Data.StrengthRewards.Pending) do if intent.State == "Prompting" then blocked = true end end
	local result = {Ready = rate ~= nil, Offers = {}, Reward = reward and {Id = id, Amount = reward.Amount}, Pending = blocked}
	for _, product in ipairs(Config.Packs) do
		local pending = s.Data.StrengthRewards.Pending[tostring(product.ProductId)]
		result.Offers[tostring(product.ProductId)] = pending and pending.Amount or rate and rate * product.Seconds or 0
	end
	return result
end
function M.Request(player, action, value)
	if locks[player] or os.clock() < (nextRequest[player] or 0) then return {Ok = false, Code = "Busy"} end
	nextRequest[player] = os.clock() + .25
	local s = sessionFor(player)
	if not s then return {Ok = false, Code = "DataNotLoaded"} end
	if action == "View" then return M.View(player) end
	locks[player] = true
	local ok, result = pcall(function()
		local op = {Id = Http:GenerateGUID(false)}
		if action == "Claim" then
			if type(value) ~= "string" then return {Ok = false, Code = "InvalidReward"} end
			op.Action, op.RewardId = "Claim", value
		elseif action == "Prepare" then
			-- Test sessions may display offers but never open a real Robux checkout.
			if RunService:IsStudio() then return {Ok = false, Code = "StudioCheckoutDisabled"} end
			local product, kind = Config.ForProduct(value)
			if not product or not ready[player] then return {Ok = false, Code = "Unavailable"} end
			for _, intent in pairs(s.Data.StrengthRewards.Pending) do
				if intent.State == "Prompting" then return {Ok = false, Code = "PurchasePending"} end
			end
			op.Action, op.ProductId = "Prepare", value
			if kind == "DoubleOffline" then op.RewardId = State.NextReward(s.Data.StrengthRewards)
			else op.Amount = assert(Reference.Get(player)) * product.Seconds end
		elseif action == "Open" then
			if RunService:IsStudio() or type(value) ~= "table" or type(value.IntentId) ~= "string" then return {Ok=false,Code="Unavailable"} end
			op.Action,op.ProductId,op.IntentId="Open",value.ProductId,value.IntentId
		else return {Ok = false, Code = "InvalidRequest"} end
		local success, reason = Data.CommitStrengthOperation(player, op)
		if not success then return {Ok = false, Code = reason} end
		if action == "Open" then
			prompts[player]={Id=op.IntentId,ProductId=op.ProductId}
			local opened=pcall(Marketplace.PromptProductPurchase,Marketplace,player,op.ProductId)
			if not opened then
				Data.CommitStrengthOperation(player,{Id="Cancel:"..op.Id,Action="Cancel",ProductId=op.ProductId,IntentId=op.IntentId})
				prompts[player]=nil
			end
			return {Ok=opened,Code=opened and "Prompted" or "PromptUnavailable"}
		end
		local current = sessionFor(player)
		local pending = current and current.Data.StrengthRewards.Pending[tostring(value)]
		if pending and action == "Prepare" then
			return {Ok = true, ProductId = pending.ProductId, Amount = pending.Amount, RewardId = pending.RewardId, IntentId = pending.Id}
		end
		return {Ok = true, View = M.View(player)}
	end)
	locks[player] = nil
	if not ok then warn("[StrengthRewards] Request deferred: " .. tostring(result)); return {Ok = false, Code = "Retry"} end
	return result
end
function M.ProcessReceipt(receipt)
	local pending = Enum.ProductPurchaseDecision.NotProcessedYet
	if RunService:IsStudio() then return pending end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local s = player and sessionFor(player)
	if not s then return pending end
	local seen = s.Data.StrengthRewards.Receipts[receipt.PurchaseId]
	if seen then return seen.ProductId == receipt.ProductId and Enum.ProductPurchaseDecision.PurchaseGranted or pending end
	local intent = s.Data.StrengthRewards.Pending[tostring(receipt.ProductId)]
	-- External/unmatched purchases are held for reconciliation, never acknowledged
	-- as a zero grant. No amount is reconstructed from a later equipment state.
	if not intent or receipt.PlaceIdWherePurchased ~= game.PlaceId then
		warn("[StrengthRewards] Unmatched receipt requires reconciliation: " .. tostring(receipt.PurchaseId))
		return pending
	end
	local success = Data.CommitStrengthOperation(player, {Id = "Receipt:" .. receipt.PurchaseId, Action = "Receipt",
		PurchaseId = receipt.PurchaseId, ProductId = receipt.ProductId, IntentId = intent.Id})
	if success then
		if prompts[player] and prompts[player].Id == intent.Id then prompts[player] = nil end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return pending
end
function M.Init()
	if initialized then return end
	initialized = true
	local remote = RS.Remotes:FindFirstChild("StrengthRewards") or Instance.new("RemoteFunction")
	remote.Name = "StrengthRewards"; remote.Parent = RS.Remotes
	remote.OnServerInvoke = M.Request
	local function joined(player)
		task.spawn(function()
			for attempt = 1, 6 do
				if player.Parent ~= Players then return end
				if Data.IsLoaded(player) then
					local _, a = Passes.RefreshPremiumTreadmill(player, 1)
					local _, b = Passes.RefreshPremiumTreadmill(player, 2)
					local _, c = Passes.RefreshShopPass(player, "VIP")
                    local auraStatus="Verified"
                    local session=Data.Get(player)
                    local auraId=session and session.Data and session.Data.EquippedAura
                    local aura=require(RS.Config.AuraConfig).Get(auraId)
                    if aura and aura.PurchaseType=="GamePass" then
                        local _, status=require(script.Parent.AuraService).RefreshPassOwnership(player,auraId)
                        auraStatus=status
                    end
					if a == "Verified" and b == "Verified" and c == "Verified" and auraStatus=="Verified" then ready[player] = true; return end
				end
				task.wait(math.min(attempt * 2, 10))
			end
		end)
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in ipairs(Players:GetPlayers()) do joined(player) end
	Players.PlayerRemoving:Connect(function(player) locks[player] = nil; prompts[player] = nil; ready[player] = nil; nextRequest[player] = nil end)
	Marketplace.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
		if purchased then return end -- only a receipt grants anything
		local player = Players:GetPlayerByUserId(userId)
		local prompt = player and prompts[player]
		if not prompt or prompt.ProductId ~= productId then return end
		local id = prompt.Id
		Data.CommitStrengthOperation(player, {Id = "Cancel:" .. id, Action = "Cancel", ProductId = productId, IntentId = id})
		prompts[player] = nil
	end)
end
return M
