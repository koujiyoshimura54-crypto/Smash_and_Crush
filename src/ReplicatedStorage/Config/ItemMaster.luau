-- Phase 7.4.3: deterministic regular item definitions and element-specific images.
local itemTypes = {
 {Name="Protein", Id="PROTEIN"},
 {Name="Glove", Id="GLOVE"},
 {Name="TrainingBelt", Id="TRAININGBELT"},
}
local rarities = {"Common","Uncommon","Rare","Epic","Legendary"}
local elements = {"Fire","Ice","Electric"}
local winPrices = {Common=75,Uncommon=200,Rare=600}
local Products=require(game.ReplicatedStorage.Config:WaitForChild("DeveloperProductConfig"))
local images = {
 Protein = {
  Fire="rbxassetid://88813844869136",
  Ice="rbxassetid://71899140469848",
  Electric="rbxassetid://99486749835983",
 },
 Glove = {
  Fire="rbxassetid://112294938722512",
  Ice="rbxassetid://116331874339139",
  Electric="rbxassetid://87861483932138",
 },
 TrainingBelt = {
  Fire="rbxassetid://123189885722060",
  Ice="rbxassetid://94400762055390",
  Electric="rbxassetid://102495913054361",
 },
}
local items = {}

for _, itemType in ipairs(itemTypes) do
 for _, rarity in ipairs(rarities) do
  for _, element in ipairs(elements) do
   local itemId = itemType.Id.."_"..string.upper(rarity).."_"..string.upper(element)
   items[itemId] = table.freeze({
    ItemId = itemId,
    ItemType = itemType.Name,
    Rarity = rarity,
    Element = element,
    Image = images[itemType.Name][element],
    WinPrice = winPrices[rarity] or 0,
    RobuxPrice = Products.GetItemProduct(rarity) and Products.GetItemProduct(rarity).FallbackPrice or 0,
    ShopPurchasable = winPrices[rarity] ~= nil,
    Mergeable = rarity ~= "Legendary",
   })
  end
 end
end
table.freeze(items)

local ItemMaster = {}
local prefixes,elementSet,rarityRank,nextRarity={},{},{},{}
for _,entry in ipairs(itemTypes) do prefixes[entry.Name]=entry.Id end
for _,element in ipairs(elements) do elementSet[element]=true end
for rank,rarity in ipairs(rarities) do rarityRank[rarity]=rank;nextRarity[rarity]=rarities[rank+1] end
ItemMaster.TypePrefixes=table.freeze(prefixes)
ItemMaster.ElementSet=table.freeze(elementSet)
ItemMaster.RarityRank=table.freeze(rarityRank)
ItemMaster.NextRarity=table.freeze(nextRarity)

ItemMaster.Rarities=table.freeze(rarities)
ItemMaster.Elements=table.freeze(elements)
local kinds={}
for _,entry in ipairs(itemTypes) do table.insert(kinds,entry.Name) end
ItemMaster.Kinds=table.freeze(kinds)
-- Existing drop odds retained; Rare balance is not yet finalized in V5.
ItemMaster.DropWeights=table.freeze({80,13,4,2,1})
ItemMaster.DropUnlockStage=table.freeze({Epic=5,Legendary=8})
ItemMaster.DropHitChance=0.20
function ItemMaster.Get(itemId)
 if typeof(itemId) ~= "string" then return nil end
 return items[itemId]
end
function ItemMaster.GetAll()
 return items
end
return table.freeze(ItemMaster)
