-- Separate durable second-tier onboarding, sharing ordinary Ore eligibility.
local Base=require(script.Parent.OreMergeTutorialState)
local Merge=require(script.Parent.OreMerge)
local Ore=require(script.Parent.Parent.Config.OreConfig)
local Counts=require(script.Parent.InventoryCounts)
local Master=require(script.Parent.Parent.Config.DumbbellItemMaster)
local M={MinimumPoints=20,Normalize=Base.Normalize,Merge=Base.Merge,Complete=Base.Complete}
function M.IsResult(id)
 local item=Master.Get(id)
 return item~=nil and type(item.MergePoints)=="number" and item.MergePoints>=M.MinimumPoints
end
function M.Selection(ores,world2Unlocked)
 local units={}
 for id,n in pairs(ores or {})do
  local ore=Ore.Get(id);local count=Counts.Count(n)
  if ore and ore.Available and count and count>0 then
   for _=1,math.min(count,Merge.Maximum)do table.insert(units,{Id=id,Points=ore.Points})end
  end
 end
 table.sort(units,function(a,b)if a.Points~=b.Points then return a.Points>b.Points end return a.Id<b.Id end)
 local selection={}
 for i=1,math.min(#units,Merge.Maximum)do
  local id=units[i].Id;selection[id]=(selection[id] or 0)+1
  if i>=Merge.Minimum then
   local preview=Merge.Evaluate(selection,ores,world2Unlocked)
   if preview and preview.Total>=M.MinimumPoints then return selection,preview end
  end
 end
 return nil
end
function M.Publish(player,state)
 player:SetAttribute("HigherOreTutorialEligible",state.Eligible)
 player:SetAttribute("HigherOreTutorialCompleted",state.Completed)
end
return table.freeze(M)
