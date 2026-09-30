-- Adapter for PlayerDataService's existing serialized item-mutation pipeline.
-- Uses the SAME PlayerData key/store and metadata, never an inventory snapshot save.
local M = {}
local MAX_COUNT = 9007199254740991

function M.Resolve(player, session, op, adapter)
	local context = op.RunReturn
	if op.Resolving then return false, "InventorySavePending" end
	local function valid()
		if context.Cancelled then return false end
		if not adapter.Current() or not context.Validate() then context.Cancelled = true end
		return not context.Cancelled
	end
	-- Autosave/leave/shutdown must never initiate/retry a provisional grant.
	-- They may only reconcile a cancelled in-flight return, removing its own delta.
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
	-- A death while UpdateAsync yields may race an already-applied write. In that
	-- case atomically reverse ONLY this transaction before declaring it cancelled.
	for _ = 1, 2 do
		local rejection
		local ok, saved, info = pcall(adapter.Update, function(old, keyInfo)
			rejection = nil
			if old ~= nil and typeof(old) ~= "table" then error("Invalid saved PlayerData") end
			local merged = old and table.clone(old) or adapter.Defaults()
			local users, meta = adapter.Metadata(keyInfo)
			if adapter.ResetToken(merged) ~= op.ResetToken then
				rejection = "SaveSupersededByReset"
				return nil
			end
			local owned = assert(adapter.Items(merged.OwnedItems))
			local same = meta.RunReturnId == op.Id
			if not valid() then
				if same and meta.RunReturnState == "Granted" then
					for id, amount in pairs(op.Deltas) do
						local count = (owned[id] or 0) - amount
						assert(count >= 0, "Return cancellation quantity conflict")
						owned[id] = count > 0 and count or nil
					end
				end
				meta.RunReturnState = "Cancelled"
			elseif not same then
				for id, amount in pairs(op.Deltas) do
					local count = (owned[id] or 0) + amount
					if count > MAX_COUNT then rejection = "CountOverflow"; return nil end
					owned[id] = count
				end
				meta.RunReturnState = "Granted"
			end
			meta.RunReturnId = op.Id
			meta.ItemMutationId = op.Id
			merged.OwnedItems = owned
			return merged, users, meta
		end)
		if ok and rejection then return finish(rejection) end
		local metadataOK, meta = pcall(function() return info:GetMetadata() end)
		if not ok or not metadataOK or typeof(meta) ~= "table" or meta.RunReturnId ~= op.Id then break end
		if meta.RunReturnState == "Cancelled" then return finish("ReturnCancelled", saved) end
		if meta.RunReturnState == "Granted" and valid() then
			-- No yield from confirmed persistence through the local commit decision.
			context.Committed = true
			return finish("Changed", saved)
		end
	end
	unlock()
	-- Cancellation retries never grant, including after PlayerData releases the
	-- disconnected session. A manual retry remains the only grant retry path.
	if not valid() and not op.CancelRetryScheduled then
		op.CancelRetryScheduled = true
		task.delay(2, function()
			op.CancelRetryScheduled = false
			if not op.Result then M.Resolve(player, session, op, adapter) end
		end)
	end
	return false, "InventorySavePending"
end

return M
