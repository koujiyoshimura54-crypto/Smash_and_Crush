local State = require(script.Parent.StrengthRewardState)
local Progress = require(game.ReplicatedStorage.Modules.LevelProgression)
local M = {}
function M.Resolve(player, session, op, ctx)
	if op.Resolving then return false, "InventorySavePending" end
	op.Resolving = true; session.Saving = true
	local rejection
	local ok, saved = pcall(function()
		return ctx.Update(function(old, info)
			rejection = nil
			if ctx.ResetToken(old) ~= op.ResetToken then rejection = "SaveSupersededByReset"; return nil end
			local nextState, gain, reason = State.Apply(old.StrengthRewards, op)
			if not nextState then rejection = reason; return nil end
			local merged = table.clone(old)
			if reason ~= "AlreadyApplied" and reason ~= "AlreadyGranted" then
				-- Persist current progression and this grant atomically with its marker.
				local strength, level, progress = Progress.ApplyGain(op.Before, gain)
				assert(strength, level)
				merged.Strength, merged.Level, merged.LevelProgress = strength, level, progress
				merged.LevelProgressVersion = Progress.Version
				merged.TotalStrengthEarned = op.Before.TotalStrengthEarned + gain
				merged.DailyDate = op.Before.DailyDate
				merged.DailyStrengthEarned = op.Before.DailyStrengthEarned + gain
			end
			merged.StrengthRewards = nextState
			local users, meta = ctx.Metadata(info)
			return merged, users, meta
		end)
	end)
	op.Resolving = false; session.Saving = false
	if not ctx.Current() then return false, "SaveSuperseded" end
	if ok and rejection then session.PendingItemMutation = nil; return false, rejection end
	local state = ok and saved and State.Normalize(saved.StrengthRewards)
	local confirmed = state and (state.LastOperation and state.LastOperation.Id == op.Id
		or op.Action == "Receipt" and state.Receipts[op.PurchaseId] and state.Receipts[op.PurchaseId].ProductId == op.ProductId)
	if not confirmed then ctx.Retry(); return false, "InventorySavePending" end
	local gain = math.max(0, state.GrantedTotal - session.Data.StrengthRewards.GrantedTotal)
	-- Live training may continue during the write; apply only the durable delta.
	if gain > 0 then assert(ctx.Grant(gain)) end
	session.Data.StrengthRewards = state
	session.PendingItemMutation = nil; session.Dirty = true
	player:SetAttribute("StrengthRewardRevision", (player:GetAttribute("StrengthRewardRevision") or 0) + 1)
	return true, "Committed"
end
return M
