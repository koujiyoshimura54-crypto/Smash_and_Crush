-- Server-only drop distribution. Item identity always comes from ItemMaster.
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local M={}
local kinds=Master.Kinds
local elements=Master.Elements
local rarities=Master.Rarities
local weights=Master.DropWeights
local function validateStage(stage)
 assert(typeof(stage)=="number" and stage%1==0 and stage>=1 and stage<=10,"Invalid drop source Stage")
end
local function unlocked(rarity,stage)
 local stageRequired=Master.DropUnlockStage[rarity] or 1
 return stage>=stageRequired
end
function M.RollRarity(rng,stage,rarityWeights)
 validateStage(stage)
 local weights=rarityWeights or weights
 if rarityWeights then
  assert(#weights==#rarities,"Invalid rarity weights")
  for _,w in ipairs(weights) do assert(typeof(w)=="number" and w>=0 and w<math.huge and w%1==0,"Invalid rarity weight") end
 end
 local total=0
 for i,weight in weights do
  if unlocked(rarities[i],stage) then total+=weight end
 end
 local roll=rng:NextInteger(1,total)
 local cumulative=0
 for i,weight in weights do
  if unlocked(rarities[i],stage) then
   cumulative+=weight
   if roll<=cumulative then return rarities[i] end
  end
 end
 error("No eligible rarity")
end
local lookup={}
for id,item in pairs(Master.GetAll()) do
 lookup[item.ItemType.."/"..item.Element.."/"..item.Rarity]=id
end
for _,kind in kinds do for _,element in elements do for _,rarity in rarities do
 assert(lookup[kind.."/"..element.."/"..rarity],"Missing drop item definition")
end end end
-- Shared item selection. This path has no ITEM/MISS roll.
function M.RollItem(rng,stage,rarityWeights)
 validateStage(stage)
 local kind=kinds[rng:NextInteger(1,#kinds)]
 local element=elements[rng:NextInteger(1,#elements)]
 local rarity=M.RollRarity(rng,stage,rarityWeights)
 return assert(lookup[kind.."/"..element.."/"..rarity])
end
function M.Roll(rng,stage)
 validateStage(stage)
 local hit=rng:NextNumber()<Master.DropHitChance
 local segments=hit and {2,4} or {1,3,5}
 local result={Outcome=hit and "ITEM" or "MISS",Segment=segments[rng:NextInteger(1,#segments)]}
 if hit then
  result.ItemId=M.RollItem(rng,stage)
 end
 return result
end
return table.freeze(M)
