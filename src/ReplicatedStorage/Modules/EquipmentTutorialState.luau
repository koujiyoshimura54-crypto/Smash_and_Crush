-- Lifetime equipment onboarding; only the established fresh/reset cohort opts in.
local Items=require(script.Parent.Parent.Config.ItemMaster)
local Dumbbells=require(script.Parent.DumbbellEquipment)
local M={}
function M.Normalize(raw,eligible)
 if raw==nil then return {Version=1,Eligible=eligible==true,ItemCompleted=false,DumbbellCompleted=false,HigherDumbbellCompleted=false} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Eligible)~="boolean"
  or type(raw.ItemCompleted)~="boolean" or type(raw.DumbbellCompleted)~="boolean"
  or raw.HigherDumbbellCompleted~=nil and type(raw.HigherDumbbellCompleted)~="boolean" then return nil,"InvalidEquipmentTutorial" end
 return {Version=1,Eligible=raw.Eligible,ItemCompleted=raw.ItemCompleted,DumbbellCompleted=raw.DumbbellCompleted,HigherDumbbellCompleted=raw.HigherDumbbellCompleted==true}
end
function M.Merge(old,incoming)
 local b=assert(M.Normalize(incoming,false))
 if old==nil then return b end
 local a=assert(M.Normalize(old,false))
 a.ItemCompleted=a.ItemCompleted or b.ItemCompleted
 a.DumbbellCompleted=a.DumbbellCompleted or b.DumbbellCompleted
 a.HigherDumbbellCompleted=a.HigherDumbbellCompleted or b.HigherDumbbellCompleted
 return a
end
function M.ItemAvailable(data)
 for id,n in pairs(data.OwnedItems or {}) do
  local item=Items.Get(id)
  if type(n)=="number" and n>0 and item and ((item.WorldId or 1)==1 or data.World1Cleared) then return true end
 end
 return false
end
function M.Refresh(data)
 local eligible=data.EggPetTutorial and data.EggPetTutorial.Eligible
 local state=assert(M.Normalize(data.EquipmentTutorial,eligible))
 local oldItem,oldBell,oldHigher=state.ItemCompleted,state.DumbbellCompleted,state.HigherDumbbellCompleted
 if state.Eligible then
  for kind,id in pairs(data.EquippedItems or {}) do
   local item=Items.Get(id)
   if item and item.ItemType==kind and (data.OwnedItems[id] or 0)>0 then state.ItemCompleted=true;break end
  end
  if data.OreMergeTutorial and data.OreMergeTutorial.Completed then
   local best=Dumbbells.Best(data.OwnedDumbbells,data.EquippedDumbbell)
   if best and best==data.EquippedDumbbell then
    state.DumbbellCompleted=true
    if data.HigherOreMergeTutorial and data.HigherOreMergeTutorial.Completed then state.HigherDumbbellCompleted=true end
   end
  end
 end
 data.EquipmentTutorial=state
 return oldItem~=state.ItemCompleted or oldBell~=state.DumbbellCompleted or oldHigher~=state.HigherDumbbellCompleted
end
function M.Publish(player,data)
 local changed=M.Refresh(data);local state=data.EquipmentTutorial
 player:SetAttribute("ItemEquipTutorialEligible",state.Eligible)
 player:SetAttribute("ItemEquipTutorialReady",M.ItemAvailable(data))
 player:SetAttribute("ItemEquipTutorialCompleted",state.ItemCompleted)
 player:SetAttribute("DumbbellEquipTutorialEligible",state.Eligible)
 player:SetAttribute("DumbbellEquipTutorialInitialCompleted",state.DumbbellCompleted)
 player:SetAttribute("DumbbellEquipTutorialReady",data.OreMergeTutorial and data.OreMergeTutorial.Completed==true
  and Dumbbells.Best(data.OwnedDumbbells,data.EquippedDumbbell)~=nil)
 local higher=data.HigherOreMergeTutorial and data.HigherOreMergeTutorial.Completed
 player:SetAttribute("DumbbellEquipTutorialCompleted",higher and state.HigherDumbbellCompleted or not higher and state.DumbbellCompleted)
 return changed
end
return table.freeze(M)
