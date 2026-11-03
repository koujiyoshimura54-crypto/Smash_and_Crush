-- Pure selection using the same owned/category rules as the existing equip setter.
local Master=require(script.Parent.Parent.Config.DumbbellItemMaster)
local Counts=require(script.Parent.InventoryCounts)
local M={}
function M.Best(owned,current)
 local selected,best=nil,-math.huge
 local ids={} for id in pairs(owned or {}) do table.insert(ids,id) end;table.sort(ids)
 for _,id in ids do
  local item=Master.Get(id);local value=item and item.StrengthBonus
  if item and item.Category=="Dumbbell" and (Counts.Count(owned[id]) or 0)>0
   and type(value)=="number" and value==value and value>=0 and value<math.huge then
   if value>best or value==best and id==current then selected,best=id,value end
  end
 end
 return selected,best
end
return table.freeze(M)
