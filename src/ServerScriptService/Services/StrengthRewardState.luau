-- Pure durable state transitions. Caller supplies server clock and unique IDs.
local Config = require(game.ReplicatedStorage.Config.StrengthRewardConfig)
local M = {}
local function number(v) return type(v) == "number" and v == v and v >= 0 and v < math.huge end
local function copy(v)
	if type(v) ~= "table" then return v end
	local out = {} for k, x in pairs(v) do out[k] = copy(x) end return out
end
M.Copy = copy
-- Only newly quoted packs use this final rounding; saved intents remain exact.
function M.PackAmount(rate, seconds)
 assert(number(rate) and number(seconds), "InvalidStrengthQuote")
 local amount=rate*seconds
 assert(number(amount), "InvalidStrengthQuote")
 return math.floor(amount)
end
function M.Normalize(raw)
	if raw == nil then return {Version = 1, Rewards = {}, Pending = {}, Receipts = {}, GrantedTotal = 0} end
	if type(raw) ~= "table" or raw.Version ~= 1 or not number(raw.GrantedTotal)
		or type(raw.Rewards) ~= "table" or type(raw.Pending) ~= "table" or type(raw.Receipts) ~= "table" then return nil, "InvalidStrengthRewards" end
	for id, r in pairs(raw.Rewards) do
		if type(id) ~= "string" or type(r) ~= "table" or not number(r.Amount) or not number(r.Paid)
			or r.Paid > r.Amount * 2 or not number(r.CreatedAt) then return nil, "InvalidOfflineReward" end
	end
	for id, p in pairs(raw.Pending) do
		if type(id) ~= "string" or type(p) ~= "table" or not Config.ForProduct(p.ProductId)
			or type(p.Id) ~= "string" or not number(p.Amount) or p.Amount <= 0
			or (p.Kind ~= "Pack" and p.Kind ~= "DoubleOffline") then return nil, "InvalidStrengthIntent" end
		if p.Kind == "DoubleOffline" and (not raw.Rewards[p.RewardId] or raw.Rewards[p.RewardId].Amount ~= p.Amount) then return nil, "InvalidRewardBinding" end
	end
	for id, r in pairs(raw.Receipts) do
		if type(id) ~= "string" or type(r) ~= "table" or not Config.ForProduct(r.ProductId)
			or type(r.IntentId) ~= "string" or not number(r.Gain) then return nil, "InvalidStrengthReceipt" end
	end
	if raw.Presence then
		local p = raw.Presence
		if type(p) ~= "table" or not number(p.At) or not number(p.Rate)
			or (p.State ~= "Online" and p.State ~= "Offline") then return nil, "InvalidStrengthPresence" end
	end
	return copy(raw)
end
function M.Acquire(raw, token, now)
	local state = assert(M.Normalize(raw))
	if state.Owner == token then return state end -- ambiguous acquisition retry
	-- A login replaces the free reward. Keep old records only while an immutable
	-- paid intent still needs them; receipts and their deduplication journal survive.
	local retained = {}
	for _, intent in pairs(state.Pending) do
		if intent.Kind == "DoubleOffline" then retained[intent.RewardId] = true end
	end
	for id in pairs(state.Rewards) do if not retained[id] then state.Rewards[id] = nil end end
	local p = state.Presence
	if p and p.State == "Offline" then
		-- Only a confirmed departure proves this interval was offline. An expired
		-- heartbeat cannot prove a prior server stopped; never infer that interval.
		local start = p.At
		local amount = Config.OfflineAmount(p.Rate, math.max(0, now - start))
		if amount > 0 then state.Rewards[token] = {Amount = amount, Paid = 0, CreatedAt = now} end
	end
	state.Owner = token
	state.Presence = {State = "Online", At = now, Rate = 0}
	return state
end
function M.Checkpoint(raw, token, now, rate, closing)
	local state = assert(M.Normalize(raw))
	assert(state.Owner == token, "StrengthOwnerMismatch")
	assert(number(rate), "InvalidStrengthRate")
	state.Presence = {State = closing and "Offline" or "Online", At = now, Rate = rate}
	return state
end
function M.NextReward(state)
	-- Rewards are keyed by the acquisition token. Archived paid intents must never
	-- become the current free reward, including when this login earned zero.
	local id = state.Owner
	local reward = id and state.Rewards[id]
	if reward and reward.Paid < reward.Amount then return id, reward end
end
function M.Apply(raw, op)
	local state = assert(M.Normalize(raw))
	if state.LastOperation and state.LastOperation.Id == op.Id then return state, 0, "AlreadyApplied" end
	local gain = 0
	if op.Action == "Claim" then
		local r = state.Rewards[op.RewardId]
		if op.RewardId ~= state.Owner or not r then return nil, 0, "RewardUnavailable" end
		gain = math.max(0, r.Amount - r.Paid)
		r.Paid += gain
	elseif op.Action == "Prepare" then
		local product, kind = Config.ForProduct(op.ProductId)
		if not product then return nil, 0, "ProductUnavailable" end
		if kind == "DoubleOffline" and (op.RewardId ~= state.Owner or not state.Rewards[op.RewardId]) then return nil, 0, "RewardUnavailable" end
		local key = tostring(op.ProductId)
		local previous = state.Pending[key]
		if previous then
			-- Never resume an older reward's checkout from this login's popup.
			if previous.Kind == "DoubleOffline" and previous.RewardId ~= op.RewardId then return nil, 0, "PurchasePending" end
			-- A cancelled dialog cannot prove the absence of a delayed receipt.
			-- Retain and resume the same quote; never bind that receipt to a newer one.
			if previous.State ~= "Cancelled" and previous.State ~= "Prepared" then return nil, 0, "PurchasePending" end
			if previous.Kind == "DoubleOffline" and state.Rewards[previous.RewardId].Paid >= previous.Amount then return nil, 0, "RewardUnavailable" end
			previous.State = "Prepared"
			state.LastOperation = {Id = op.Id, Gain = 0}
			return state, 0, "Committed"
		end
		local amount = op.Amount
		if kind == "DoubleOffline" then
			local r = state.Rewards[op.RewardId]
			if not r or r.Paid >= r.Amount then return nil, 0, "RewardUnavailable" end
			amount = r.Amount
		end
		if not number(amount) then return nil, 0, "InvalidAmount" end
		if kind == "Pack" then amount = M.PackAmount(amount, 1) end
		if amount <= 0 then return nil, 0, "InvalidAmount" end
		state.Pending[key] = {Id = op.Id, ProductId = op.ProductId, Kind = kind, Amount = amount, RewardId = op.RewardId, State = "Prepared"}
	elseif op.Action == "Open" then
		local p = state.Pending[tostring(op.ProductId)]
		if not p or p.Id ~= op.IntentId or p.State ~= "Prepared" then return nil, 0, "PurchasePending" end
		if p.Kind == "DoubleOffline" and p.RewardId ~= state.Owner then return nil, 0, "RewardUnavailable" end
		p.State = "Prompting"
	elseif op.Action == "Cancel" then
		local key = tostring(op.ProductId)
		local p = state.Pending[key]
		if p and p.Id == op.IntentId then p.State = "Cancelled" end
	elseif op.Action == "Receipt" then
		local seen = state.Receipts[op.PurchaseId]
		if seen then
			if seen.ProductId ~= op.ProductId then return nil, 0, "ReceiptMismatch" end
			return state, 0, "AlreadyGranted"
		end
		local key = tostring(op.ProductId)
		local p = state.Pending[key]
		if not p or p.Id ~= op.IntentId then return nil, 0, "UnmatchedReceipt" end
		if p.Kind == "Pack" then gain = p.Amount
		else
			local r = state.Rewards[p.RewardId]
			if not r or r.Amount ~= p.Amount then return nil, 0, "RewardMismatch" end
			gain = math.max(0, p.Amount * 2 - r.Paid)
			r.Paid += gain
		end
		state.Receipts[op.PurchaseId] = {ProductId = op.ProductId, IntentId = p.Id, RewardId = p.RewardId, Gain = gain}
		state.Pending[key] = nil
	else return nil, 0, "InvalidOperation" end
	state.GrantedTotal += gain
	state.LastOperation = {Id = op.Id, Gain = gain}
	return state, gain, "Committed"
end
return M
