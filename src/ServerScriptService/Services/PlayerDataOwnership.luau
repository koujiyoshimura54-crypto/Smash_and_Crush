-- Per-session fencing for every normal PlayerData write, on the same key.
local ReturnPersistence = require(script.Parent.RunReturnPersistence)
local M = {}

function M.Acquire(store, key, attempt, defaults, validate, current)
	if attempt.Lost then error("SessionOwnershipLost", 0) end
	if not attempt.Read then
		local options = Instance.new("DataStoreGetOptions")
		options.UseCache = false
		local raw = store:GetAsync(key, options)
		assert(raw == nil or typeof(raw) == "table", "Invalid saved PlayerData")
		attempt.ExpectedOwner = raw and raw.SessionOwnerToken
		attempt.Read = true
	end
	local rejected = false
	local saved = store:UpdateAsync(key, function(old, info)
		rejected = false
		assert(old == nil or typeof(old) == "table", "Invalid saved PlayerData")
		local owner = old and old.SessionOwnerToken
		if not current() or owner ~= attempt.ExpectedOwner and owner ~= attempt.Token then
			rejected = true
			return nil
		end
		local normalized, reason = validate(old)
		assert(normalized, reason)
		local data = old and table.clone(old) or defaults()
		-- Normalize legacy item quantities before any durable delta operation.
		data.OwnedItems = table.clone(normalized.OwnedItems)
		ReturnPersistence.Recover(data)
		data.SessionOwnerToken = attempt.Token
		local meta = info and info:GetMetadata() or {}
		local j = data.RunReturnJournal
		if j and j.State == "Cancelled" and old.RunReturnJournal.State == "Pending" then
			meta.RunReturnId, meta.RunReturnState = j.TransactionId, "Cancelled"
		end
		return data, info and info:GetUserIds() or {}, meta
	end)
	if rejected then attempt.Lost = true; error("SessionOwnershipLost", 0) end
	assert(saved and saved.SessionOwnerToken == attempt.Token, "OwnershipSaveUnconfirmed")
	return saved
end

function M.Update(store, key, session, transform, current)
	if session.OwnershipLost or not session.OwnerToken or not current() then error("SessionOwnershipLost", 0) end
	local rejected = false
	local saved, info = store:UpdateAsync(key, function(old, keyInfo)
		rejected = false
		if not current() or typeof(old) ~= "table" or old.SessionOwnerToken ~= session.OwnerToken then
			rejected = true
			return nil
		end
		local value, users, meta = transform(old, keyInfo)
		if value then assert(value.SessionOwnerToken == session.OwnerToken, "Owner token must be preserved") end
		return value, users, meta
	end)
	if rejected then session.OwnershipLost = true; error("SessionOwnershipLost", 0) end
	return saved, info
end

return M
