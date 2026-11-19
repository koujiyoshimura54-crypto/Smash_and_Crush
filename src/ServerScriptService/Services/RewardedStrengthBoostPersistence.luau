local State=require(script.Parent.RewardedStrengthBoostState)
local M={}
function M.Resolve(player,session,op,ctx)
	if op.Resolving then return false,"InventorySavePending" end
	op.Resolving=true;session.Saving=true
	local rejection
	local ok,saved=pcall(function()
		return ctx.Update(function(old,info)
			rejection=nil
			if ctx.ResetToken(old)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
			local state,reason=State.Apply(old.StrengthBoost,op,ctx.Now(),op.DurationSeconds)
			if not state then rejection=reason;return nil end
			local merged=table.clone(old)
			merged.StrengthBoost=state -- Expiry AND receipt marker in the SAME owned-profile write.
			local users,meta=ctx.Metadata(info)
			return merged,users,meta
		end)
	end)
	op.Resolving=false;session.Saving=false
	if not ctx.Current() then return false,"SaveSuperseded" end
	if ok and rejection then session.PendingItemMutation=nil;return false,rejection end
	local state=ok and saved and State.Normalize(saved.StrengthBoost)
	local marker=state and state.Receipts[op.PurchaseId]
	if not marker or marker.ProductId~=op.ProductId or marker.PlayerId~=op.PlayerId then
		-- An ambiguous write keeps the SAME operation behind the existing save barrier.
		ctx.Retry();return false,"InventorySavePending"
	end
	session.Data.StrengthBoost=state
	session.PendingItemMutation=nil
	player:SetAttribute("StrengthBoostExpiresAt",state.ExpiresAt)
	return true,"Committed"
end
return M
