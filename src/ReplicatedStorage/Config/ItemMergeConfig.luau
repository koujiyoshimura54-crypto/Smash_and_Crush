-- Shared regular-Item merge authority: UI projection and server sampling.
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local M={}
M.MinimumCount=2
M.Version="ItemPoints_v1"
M.MaxInteger=9007199254740991
M.RarityPoints=table.freeze({Common=1,Uncommon=3,Rare=9,Epic=27,Legendary=81})
local function integer(n)
 return typeof(n)=="number" and n==n and n>0 and n<=M.MaxInteger and n%1==0
end
function M.GetPoints(item)
 return item and Master.TypePrefixes[item.ItemType] and M.RarityPoints[item.Rarity] or nil
end
function M.GetRank(item)
 local rank=item and Master.RarityRank[item.Rarity]
 return rank and rank+((item.WorldId or 1)==2 and 5 or 0) or nil
end
function M.IsUnlocked(item,world2Unlocked)
 return item~=nil and ((item.WorldId or 1)==1 or world2Unlocked==true)
end
function M.Groups(owned,world2Unlocked)
 local groups={}
 local kinds={Glove=1,Protein=2,TrainingBelt=3}
 local elements={};for i,name in ipairs(Master.Elements) do elements[name]=i end
 for id,count in pairs(owned or {}) do
  local item=Master.Get(id)
  if integer(count) and M.GetPoints(item) and M.IsUnlocked(item,world2Unlocked) then
   -- Element variants remain distinct: they participate in different set bonuses.
   table.insert(groups,{Key=id,ItemId=id,Count=count,Rank=M.GetRank(item),KindOrder=kinds[item.ItemType],ElementOrder=elements[item.Element]})
  end
 end
 table.sort(groups,function(a,b)
  if a.Rank~=b.Rank then return a.Rank<b.Rank end
  if a.ElementOrder~=b.ElementOrder then return a.ElementOrder<b.ElementOrder end
  if a.KindOrder~=b.KindOrder then return a.KindOrder<b.KindOrder end
  return a.ItemId<b.ItemId
 end)
 return groups
end
function M.Ladder()
 local rows={}
 for _,name in ipairs(Master.Rarities) do
  local p=M.RarityPoints[name]
  if integer(p) then table.insert(rows,{Rarity=name,Points=p,Rank=Master.RarityRank[name]}) end
 end
 table.sort(rows,function(a,b)return a.Points<b.Points end)
 for i=2,#rows do assert(rows[i].Points>rows[i-1].Points,"Invalid Item merge ladder") end
 return rows
end
function M.RarityOdds(points)
 local ladder=M.Ladder();assert(#ladder>0,"Missing Item merge ladder")
 for i=1,#ladder-1 do
  local a,b=ladder[i],ladder[i+1]
  if points<b.Points then
   local upper=math.clamp((points-a.Points)/(b.Points-a.Points),0,1)
   local rows={}
   if upper<1 then table.insert(rows,{Rarity=a.Rarity,Probability=1-upper}) end
   if upper>0 then table.insert(rows,{Rarity=b.Rarity,Probability=upper}) end
   return rows
  end
 end
 return {{Rarity=ladder[#ladder].Rarity,Probability=1}}
end
function M.Evaluate(materials,owned,world2Unlocked)
 if typeof(materials)~="table" then return nil,"InvalidMaterials" end
 local total,count,types,elements,ids=0,0,{},{},{}
 local worldId
 for id,n in pairs(materials) do
  local item=Master.Get(id)
  local p=M.GetPoints(item)
  if not item or not p or not Master.ElementSet[item.Element] then return nil,"InvalidItemId" end
  local world=item.WorldId or 1
  if world==2 and world2Unlocked==false then return nil,"WorldNotReached" end
  if worldId and worldId~=world then return nil,"MixedWorldMaterials" end
  worldId=world
  if not integer(n) then return nil,"InvalidAmount" end
  if owned and (not integer(owned[id]) or owned[id]<n) then return nil,"NotEnoughItems" end
  if n>math.floor((M.MaxInteger-total)/p) or n>M.MaxInteger-count then return nil,"CountOverflow" end
  local points=n*p;total+=points;count+=n
  types[item.ItemType]=(types[item.ItemType] or 0)+points
  elements[item.Element]=(elements[item.Element] or 0)+points
  table.insert(ids,id)
 end
 if count<M.MinimumCount then return nil,"NotEnoughItems" end
 table.sort(ids)
 local signature={}
 for _,id in ids do table.insert(signature,id..":"..string.format("%.0f",materials[id])) end
 local outcomes={}
 local rarities=M.RarityOdds(total)
 for _,rarity in rarities do
  for _,kind in ipairs(Master.Kinds) do
   for _,element in ipairs(Master.Elements) do
    local a,b=types[kind] or 0,elements[element] or 0
    if a>0 and b>0 then
     local id=Master.Id(kind,rarity.Rarity,element,worldId)
     if not Master.Get(id) then return nil,"InvalidMergeResult" end
     local probability=rarity.Probability*(a/total)*(b/total)
     table.insert(outcomes,{ItemId=id,Probability=probability,Percent=probability*100})
    end
   end
  end
 end
 return {WorldId=worldId,Count=count,Points=total,Types=types,Elements=elements,Rarities=rarities,Outcomes=outcomes,Signature=table.concat(signature,"|")}
end
local function choose(rows,random)
 local p=random();local acc=0
 for _,row in ipairs(rows) do acc+=row.Probability;if p<acc then return row end end
 return rows[#rows]
end
function M.Sample(preview,random)
 local rarity=choose(preview.Rarities,random).Rarity
 local types,elements={},{}
 for _,kind in ipairs(Master.Kinds) do
  if preview.Types[kind] then table.insert(types,{Value=kind,Probability=preview.Types[kind]/preview.Points}) end
 end
 for _,element in ipairs(Master.Elements) do
  if preview.Elements[element] then table.insert(elements,{Value=element,Probability=preview.Elements[element]/preview.Points}) end
 end
 -- Separate draws, including cross-combinations absent from the input IDs.
 local kind=choose(types,random).Value;local element=choose(elements,random).Value
 return Master.Id(kind,rarity,element,preview.WorldId)
end
return table.freeze(M)
