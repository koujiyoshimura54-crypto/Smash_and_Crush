-- Pure profile transformation. No instances, store, HTTP, clocks or UI side effects.
local M = {}
local function integer(n)
	return type(n)=="number" and n==n and n>=0 and n%1==0 and n<=9007199254740991
end
function M.Normalize(raw)
	if raw==nil then return {ExpiresAt=0, Receipts={}} end
	if type(raw)~="table" or not integer(raw.ExpiresAt) or type(raw.Receipts)~="table" then return nil,"InvalidStrengthBoost" end
	local receipts={}
	for id,r in pairs(raw.Receipts) do
		if type(id)~="string" or id=="" or type(r)~="table" or not integer(r.ProductId) or not integer(r.PlayerId)
			or not integer(r.GrantedAt) or not integer(r.ExpiresAt) or type(r.Channel)~="string" then return nil,"InvalidBoostReceipt" end
		receipts[id]=table.clone(r)
	end
	-- Never prune fulfilled receipt IDs when the timed effect expires.
	return {ExpiresAt=raw.ExpiresAt, Receipts=receipts}
end
function M.Apply(raw, receipt, now, duration)
	if type(receipt)~="table" or type(receipt.PurchaseId)~="string" or receipt.PurchaseId==""
		or not integer(receipt.ProductId) or receipt.ProductId==0 or not integer(receipt.PlayerId) or receipt.PlayerId==0
		or type(receipt.Channel)~="string" or not integer(now) or not integer(duration) or duration==0 then return nil,"InvalidReceipt" end
	local state,reason=M.Normalize(raw)
	if not state then return nil,reason end
	local previous=state.Receipts[receipt.PurchaseId]
	if previous then
		if previous.PlayerId~=receipt.PlayerId or previous.ProductId~=receipt.ProductId then return nil,"ReceiptConflict" end
		return state,"AlreadyGranted"
	end
	local expires=math.max(now,state.ExpiresAt)+duration
	if not integer(expires) then return nil,"ExpiryOverflow" end
	state.ExpiresAt=expires
	state.Receipts[receipt.PurchaseId]={PlayerId=receipt.PlayerId,ProductId=receipt.ProductId,
		GrantedAt=now,ExpiresAt=expires,Channel=receipt.Channel}
	return state,"Granted"
end
function M.Bonus(state, now, bonus)
	return state and type(state.ExpiresAt)=="number" and now<state.ExpiresAt and bonus or 0
end
return M
