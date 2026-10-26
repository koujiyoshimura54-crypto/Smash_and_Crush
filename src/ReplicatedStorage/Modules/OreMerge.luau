local Ore=require(script.Parent.Parent.Config.OreConfig)
local Dumbbells=require(script.Parent.Parent.Config.DumbbellItemMaster)
local Counts=require(script.Parent.InventoryCounts)
local M={Minimum=1,Maximum=5}
function M.Selection(raw,owned,selling)
 if typeof(raw)~="table" then return nil,"InvalidMaterials" end
 local selected,total,quantity,entries={},0,0,0
 for id,n in pairs(raw) do
  local ore=Ore.Get(id);local count=Counts.Count(n)
  entries+=1
  if entries>16 or not ore or not ore.Available or typeof(n)~="number" or not count or count<1 then return nil,"InvalidMaterials" end
  if owned and count>(Counts.Count(owned[id]) or 0) then return nil,"NotEnoughOres" end
  selected[id]=count;quantity+=count;total+=count*(selling and ore.SellWin or ore.Points)
  if total>Counts.Max or quantity>Counts.Max then return nil,"CountOverflow" end
 end
 if quantity<1 then return nil,"SelectMaterials" end
 if not selling and quantity>M.Maximum then return nil,"TooManyMaterials" end
 return {Materials=selected,Count=quantity,Total=total}
end
function M.Evaluate(raw,owned)
 local result,reason=M.Selection(raw,owned,false);if not result then return nil,reason end
 local rows=Dumbbells.GetSorted(1)
 local lower=rows[1]
 for _,item in ipairs(rows) do
  if result.Total==item.MergePoints then result.Outcomes={{Id=item.ItemId,Probability=1}};return result end
  if result.Total<item.MergePoints then
   local upper=(result.Total-lower.MergePoints)/(item.MergePoints-lower.MergePoints)
   result.Outcomes={{Id=lower.ItemId,Probability=1-upper},{Id=item.ItemId,Probability=upper}}
   return result
  end
  lower=item
 end
 return nil,"InvalidPoints"
end
function M.Pick(preview,unit)
 local sum=0
 for _,row in ipairs(preview.Outcomes) do sum+=row.Probability;if unit<sum then return row.Id end end
 return preview.Outcomes[#preview.Outcomes].Id
end
function M.Signature(action,selection,itemId)
 local entries={action,itemId or ""}
 local ids={} for id in pairs(selection or {}) do table.insert(ids,id) end;table.sort(ids)
 for _,id in ipairs(ids) do table.insert(entries,id..":"..selection[id]) end
 return table.concat(entries,"|")
end
return table.freeze(M)
