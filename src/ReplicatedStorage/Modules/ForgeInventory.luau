-- Pure quantity transaction. Random outcomes are chosen once by the server before saving.
local Counts=require(script.Parent.InventoryCounts)
local Ore=require(script.Parent.Parent.Config.OreConfig)
local Master=require(script.Parent.Parent.Config.DumbbellItemMaster)
local Merge=require(script.Parent.OreMerge)
local M={}
function M.Journal(raw)
 if raw==nil then return {Sequence=0} end
 if typeof(raw)~="table" or typeof(raw.Sequence)~="number" or not Counts.Count(raw.Sequence) then return nil,"InvalidForgeJournal" end
 if raw.Sequence==0 then return {Sequence=0} end
 for _,key in ipairs({"Id","Signature","ResultId"}) do if typeof(raw[key])~="string" then return nil,"InvalidForgeJournal" end end
 return {Sequence=raw.Sequence,Id=raw.Id,Signature=raw.Signature,ResultId=raw.ResultId}
end
function M.Apply(data,op)
 local journal,err=M.Journal(data.ForgeJournal);if not journal then return nil,err end
 if journal.Sequence>=op.Sequence then
  if journal.Sequence==op.Sequence and journal.Id==op.Id and journal.Signature==op.Signature then return data,"AlreadyApplied" end
  return nil,"InventoryChanged"
 end
 if journal.Sequence+1~=op.Sequence then return nil,"InventoryChanged" end
 local ores=Counts.Normalize(data.OwnedOres);local bells=Counts.Normalize(data.OwnedDumbbells)
 if not ores or not bells then return nil,"InvalidInventory" end
 local delta=0
 if op.Action=="MergeOre" then
  local preview,reason=Merge.Evaluate(op.Materials,ores);if not preview then return nil,reason end
  local valid=false for _,row in ipairs(preview.Outcomes) do if row.Id==op.ResultId and row.Probability>0 then valid=true end end
  if not valid then return nil,"InvalidResult" end
  for id,count in pairs(preview.Materials) do ores[id]-=count;if ores[id]==0 then ores[id]=nil end end
  bells[op.ResultId]=(bells[op.ResultId] or 0)+1
 elseif op.Action=="SellOre" then
  local preview,reason=Merge.Selection(op.Materials,ores,true);if not preview then return nil,reason end
  for id,count in pairs(preview.Materials) do ores[id]-=count;if ores[id]==0 then ores[id]=nil end end
  delta=preview.Total
 elseif op.Action=="SellDumbbell" then
  local item=Master.Get(op.ItemId);local count=Counts.Count(op.Count)
  if not item or item.WorldId==2 or not item.SellWin or typeof(op.Count)~="number" or not count or count<1 then return nil,"InvalidSale" end
  local owned=bells[op.ItemId] or 0
  if count>owned then return nil,"NotEnoughDumbbells" end
  if op.ItemId==data.EquippedDumbbell and count>=owned then return nil,"EquippedLastCopy" end
  bells[op.ItemId]=owned-count;if bells[op.ItemId]==0 then bells[op.ItemId]=nil end
  delta=count*item.SellWin
 elseif op.Action=="BuyDumbbell" then
  local item=Master.Get(op.ItemId)
  if not item or item.WorldId==2 then return nil,"InvalidItemId" end
  if (bells[op.ItemId] or 0)>0 then return nil,"AlreadyOwned" end
  delta=-item.PriceWin;bells[op.ItemId]=1
 elseif op.Action=="DropOre" then
  local ore=Ore.Get(op.ResultId);if not ore or not ore.Available then return nil,"InvalidOre" end
  ores[op.ResultId]=(ores[op.ResultId] or 0)+1
 else return nil,"InvalidAction" end
 local win=data.Win+delta
 if not Counts.Count(win) then return nil,win<0 and "NotEnoughWin" or "WinOverflow" end
 for _,inventory in ipairs({ores,bells}) do for _,n in pairs(inventory) do if not Counts.Count(n) then return nil,"CountOverflow" end end end
 local out=table.clone(data)
 out.OwnedOres=ores;out.OwnedDumbbells=bells;out.Win=win
 out.ForgeJournal={Sequence=op.Sequence,Id=op.Id,Signature=op.Signature,ResultId=op.ResultId or ""}
 return out,"Applied",delta
end
return table.freeze(M)
