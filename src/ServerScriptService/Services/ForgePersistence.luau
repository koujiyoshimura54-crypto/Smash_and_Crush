local RS=game:GetService("ReplicatedStorage")
local Inventory=require(RS.Modules.ForgeInventory)
local Counts=require(RS.Modules.InventoryCounts)
local M={}
function M.Resolve(player,s,op,ctx)
 if op.Resolving then return false,"InventorySavePending" end
 op.Resolving=true;s.Saving=true
 local rejection
 local ok,saved=pcall(function()
  return ctx.Update(function(old,info)
   rejection=nil
   local merged=old and table.clone(old) or ctx.Defaults()
   if ctx.ResetToken(merged)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
   local journal=assert(Inventory.Journal(merged.ForgeJournal))
   if journal.Sequence<op.Sequence then
    -- Include legitimate unsaved World2 purchases/equipment. The session lock and
    -- pending-mutation barrier protect this exact snapshot throughout retries.
    merged.OwnedDumbbells=op.DumbbellsBefore
    merged.EquippedDumbbell=op.EquippedBefore
    local paid=tonumber(merged.ShopRewards and merged.ShopRewards.WinGrantedTotal) or 0
    merged.Win=op.WinBefore+math.max(0,paid-op.PaidBefore)
   end
   local result,reason=Inventory.Apply(merged,op)
   if not result then rejection=reason;return nil end
   local users,meta=ctx.Metadata(info)
   return result,users,meta
  end)
 end)
 if not ctx.Current() then op.Resolving=false;s.Saving=false;return false,"SaveSuperseded" end
 if ok and rejection then
  s.PendingItemMutation=nil;s.Saving=false;op.Resolving=false
  player:SetAttribute("ForgeSavePending",false)
  return false,rejection
 end
 local journal=ok and typeof(saved)=="table" and Inventory.Journal(saved.ForgeJournal)
 if not journal or journal.Id~=op.Id or journal.Sequence~=op.Sequence or journal.Signature~=op.Signature then
  op.Resolving=false;s.Saving=false
  ctx.Retry()
  warn("[Forge] Save unconfirmed; retaining operation "..op.Id..": "..tostring(ok and "missing confirmation" or saved))
  return false,"InventorySavePending"
 end
 s.Data.OwnedOres=assert(Counts.Normalize(saved.OwnedOres))
 s.Data.OwnedDumbbells=assert(Counts.Normalize(saved.OwnedDumbbells))
 s.Data.ForgeJournal=journal
 local paid=tonumber(saved.ShopRewards and saved.ShopRewards.WinGrantedTotal) or 0
 local unseen=math.max(0,paid-(s.Data.ShopRewards.WinGrantedTotal or 0))
 s.Data.ShopRewards.WinGrantedTotal=math.max(paid,s.Data.ShopRewards.WinGrantedTotal or 0)
 s.Data.Win=(player:GetAttribute("Win") or s.Data.Win)+op.WinDelta+unseen
 player:SetAttribute("Win",s.Data.Win)
 s.PendingItemMutation=nil;s.Saving=false;s.Dirty=true;op.Resolving=false
 player:SetAttribute("ForgeSavePending",false)
 player:SetAttribute("ForgeInventoryRevision",journal.Sequence)
 return true,"Applied"
end
return M
