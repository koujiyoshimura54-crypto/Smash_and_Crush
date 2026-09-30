-- Durable World1 Return journal in the existing PlayerData key.
-- Pending never owns items. Granted is terminal: death/leave never subtracts it.
local M = {}
local MAX_COUNT = 9007199254740991

local function integer(n)
	return typeof(n) == "number" and n == n and n >= 1 and n <= MAX_COUNT and n % 1 == 0
end
local function deltasEqual(a, b)
	for id, n in pairs(a) do if b[id] ~= n then return false end end
	for id, n in pairs(b) do if a[id] ~= n then return false end end
	return true
end
function M.ValidateJournal(j)
	if j == nil then return true end
	if typeof(j) ~= "table" or typeof(j.TransactionId) ~= "string"
		or typeof(j.OwnerToken) ~= "string" or not integer(j.Sequence)
		or typeof(j.RunId) ~= "string" or not integer(j.CreatedAt)
		or (j.State ~= "Pending" and j.State ~= "Granted" and j.State ~= "Cancelled")
		or typeof(j.ItemDelta) ~= "table" or next(j.ItemDelta) == nil then
		return false
	end
	for id, n in pairs(j.ItemDelta) do
		if typeof(id) ~= "string" or not integer(n) then return false end
	end
	return true
end

-- Called atomically with ownership acquisition, before Loaded=true.
-- A Pending journal has not modified OwnedItems; never replay an abandoned run.
function M.Recover(data)
	local j = data.RunReturnJournal
	assert(M.ValidateJournal(j), "Invalid RunReturnJournal")
	if j and j.State == "Pending" then
		local copy = table.clone(j)
		copy.ItemDelta = table.clone(j.ItemDelta)
		copy.State = "Cancelled"
		copy.ResolvedAt = os.time()
		copy.Reason = "SessionRecovery"
		data.RunReturnJournal = copy
	end
end

-- Pure, non-yielding transition. nil means NO write (including no metadata write).
-- Sequence is a per-owner high-water mark, so replaced/old IDs cannot be prepared again.
function M.Transition(old, op, action)
	if old.SessionOwnerToken ~= op.OwnerToken then return nil, "SessionOwnershipLost" end
	local j = old.RunReturnJournal
	assert(M.ValidateJournal(j), "Invalid RunReturnJournal")
	local same = j and j.TransactionId == op.Id and j.OwnerToken == op.OwnerToken
		and j.Sequence == op.Sequence
	if j and j.TransactionId == op.Id and not same then return nil, "TransactionMismatch" end
	if same and (j.RunId ~= op.RunId or not deltasEqual(j.ItemDelta, op.Deltas)) then
		return nil, "TransactionMismatch"
	end
	if action == "Prepare" then
		if same then return old, j.State end
		if j and (j.State == "Pending" or j.OwnerToken == op.OwnerToken and op.Sequence <= j.Sequence) then
			return nil, "StaleTransaction"
		end
		local data = table.clone(old)
		local nextJournal = {TransactionId = op.Id, OwnerToken = op.OwnerToken,
			Sequence = op.Sequence, RunId = op.RunId, ItemDelta = table.clone(op.Deltas),
			CreatedAt = op.CreatedAt, State = "Pending"}
		assert(M.ValidateJournal(nextJournal), "Invalid return operation")
		data.RunReturnJournal = nextJournal
		return data, "Pending"
	end
	if not same then return nil, "StaleTransaction" end
	-- Terminal states can be read again, but never reversed or applied twice.
	if j.State ~= "Pending" then return old, j.State end
	local data = table.clone(old)
	local nextJournal = table.clone(j)
	nextJournal.ItemDelta = table.clone(j.ItemDelta)
	nextJournal.ResolvedAt = os.time()
	if action == "Cancel" then
		nextJournal.State = "Cancelled"
	elseif action == "Grant" then
		local owned = table.clone(assert(old.OwnedItems))
		for id, amount in pairs(j.ItemDelta) do
			local count = (owned[id] or 0) + amount
			if count > MAX_COUNT then return nil, "CountOverflow" end
			owned[id] = count
		end
		data.OwnedItems = owned
		nextJournal.State = "Granted"
	else
		error("Invalid return transition")
	end
	data.RunReturnJournal = nextJournal
	return data, nextJournal.State
end

function M.Resolve(player, session, op, adapter)
	local context = op.RunReturn
	if op.Resolving then return false, "InventorySavePending" end
	if op.Result then return op.Result == "Changed", op.Result end
	local function valid()
		if not adapter.Current() or not context.Validate() then context.Cancelled = true end
		return not context.Cancelled
	end
	-- Ordinary saves cannot initiate a grant. They may settle a cancellation,
	-- which is a no-op if the durable transaction has already become Granted.
	if valid() and not context.Permit then return false, "InventorySavePending" end
	op.Resolving = true
	session.Saving = true
	local function unlock()
		op.Resolving = false
		session.Saving = false
	end
	local function finish(result, saved)
		if saved and adapter.Current() then session.Data.OwnedItems = adapter.Items(saved.OwnedItems) end
		op.Result = result
		if session.PendingItemMutation == op then session.PendingItemMutation = nil end
		session.Dirty = true
		unlock()
		return result == "Changed", result
	end
	-- Separate durable writes: confirmation of Pending MUST precede Grant.
	for _ = 1, 2 do
		local rejection
		local ok, saved = pcall(adapter.Update, function(old, info)
			rejection = nil
			if adapter.ResetToken(old) ~= op.ResetToken then rejection = "SaveSupersededByReset"; return nil end
			local action = not valid() and "Cancel" or (op.PendingConfirmed and "Grant" or "Prepare")
			local data, state = M.Transition(old, op, action)
			if not data then rejection = state; return nil end
			local users, meta = adapter.Metadata(info)
			-- These compatibility markers are not the dedupe authority.
			-- Only a transition of THIS matching journal may update them.
			if data ~= old then
				meta.RunReturnId = op.Id
				meta.RunReturnState = state
				if state == "Granted" then meta.ItemMutationId = op.Id end
			end
			return data, users, meta
		end)
		if not ok then
			if tostring(saved) == "SessionOwnershipLost" then return finish("SessionOwnershipLost") end
			break -- uncertain write; retry retains ID/sequence/snapshot
		end
		if rejection then return finish(rejection) end
		local j = saved and saved.RunReturnJournal
		if not j or j.TransactionId ~= op.Id or j.OwnerToken ~= op.OwnerToken or j.Sequence ~= op.Sequence then break end
		if j.State == "Granted" then
			context.Committed = true
			return finish("Changed", saved) -- even if death/leave happened during the response
		end
		if j.State == "Cancelled" then return finish("ReturnCancelled", saved) end
		op.PendingConfirmed = true
	end
	unlock()
	-- No detached background writes after Release. An unresolved Pending record
	-- is cancelled by next Join's atomic ownership acquisition/recovery.
	return false, "InventorySavePending"
end

return M
