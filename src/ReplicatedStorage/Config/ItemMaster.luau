-- Phase 7.4.3: deterministic regular item definitions and element-specific images.
local itemTypes = {
 {Name="Protein", Id="PROTEIN"},
 {Name="Glove", Id="GLOVE"},
 {Name="TrainingBelt", Id="TRAININGBELT"},
}
local rarities = {"Common","Uncommon","Rare","Epic","Legendary"}
local elements = {"Fire","Ice","Electric"}
local winPrices = {Common=75,Uncommon=200,Rare=600,Epic=4500}
local Products=require(game.ReplicatedStorage.Config:WaitForChild("DeveloperProductConfig"))
-- Upload 01..05 = Common..Legendary. Grove/Belt upload names do not change item IDs.
local images = {
 Protein = {
  Fire={"rbxassetid://119239917570949","rbxassetid://108422218042975","rbxassetid://79765453122830","rbxassetid://82077986207411","rbxassetid://91739900505998"},
  Ice={"rbxassetid://109626867118785","rbxassetid://91362170512211","rbxassetid://82858655370111","rbxassetid://82889919252005","rbxassetid://124374248196874"},
  Electric={"rbxassetid://88641679595352","rbxassetid://85795080513978","rbxassetid://107739440992464","rbxassetid://103146146252897","rbxassetid://97578658858016"},
 },
 Glove = {
  Fire={"rbxassetid://131063706477806","rbxassetid://98887322321581","rbxassetid://77605756931267","rbxassetid://109538064430664","rbxassetid://73308020209583"},
  Ice={"rbxassetid://77728202879648","rbxassetid://139999591744437","rbxassetid://110123985270101","rbxassetid://110315224232470","rbxassetid://93781714149316"},
  Electric={"rbxassetid://111718628408896","rbxassetid://102792375678043","rbxassetid://119911873482523","rbxassetid://134926043547076","rbxassetid://131591548966635"},
 },
 TrainingBelt = {
  Fire={"rbxassetid://135152518487596","rbxassetid://139567332510562","rbxassetid://93608276021361","rbxassetid://74118581220310","rbxassetid://104564972440529"},
  Ice={"rbxassetid://110481788029040","rbxassetid://123049417284290","rbxassetid://117141510259080","rbxassetid://132759157132674","rbxassetid://96064369103679"},
  Electric={"rbxassetid://96496752053787","rbxassetid://85833750596611","rbxassetid://119294353394586","rbxassetid://105659825652489","rbxassetid://99054363236474"},
 },
}
local items = {}

for _, itemType in ipairs(itemTypes) do
 for rank, rarity in ipairs(rarities) do
  for _, element in ipairs(elements) do
   local itemId = itemType.Id.."_"..string.upper(rarity).."_"..string.upper(element)
   items[itemId] = table.freeze({
    ItemId = itemId,
    ItemType = itemType.Name,
    Rarity = rarity,
    Element = element,
    Image = images[itemType.Name][element][rank],
    WinPrice = winPrices[rarity] or 0,
    RobuxPrice = Products.GetItemProduct(rarity) and Products.GetItemProduct(rarity).FallbackPrice or 0,
    ShopPurchasable = winPrices[rarity] ~= nil,
    -- New individual Robux offers only; product definitions remain for paid receipts.
    RobuxPurchasable = rarity ~= "Epic" and Products.GetItemProduct(rarity) ~= nil,
    Mergeable = true,
   })
  end
 end
end
local World2=require(script.Parent.World2GameplayConfig)
local originals=table.clone(items)
for id,item in pairs(originals) do
 local row=assert(World2.Items[item.Rarity])
 local worldItem=table.clone(item)
 worldItem.ItemId="W2_"..id;worldItem.WorldId=2
 worldItem.WinPrice=row.PriceWin;worldItem.ShopPurchasable=row.PriceWin~=nil
 worldItem.RobuxPurchasable=false;worldItem.RobuxPrice=nil
 items[worldItem.ItemId]=table.freeze(worldItem)
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
ItemMaster.DropHitChance=require(script.Parent.EnemyDropConfig).Worlds[1][1].ItemChance -- Legacy read-only view
function ItemMaster.Get(itemId)
 if typeof(itemId) ~= "string" then return nil end
 return items[itemId]
end
function ItemMaster.GetAll()
 return items
end
function ItemMaster.Id(kind,rarity,element,worldId)
 local prefix=worldId==2 and "W2_" or ""
 return prefix..ItemMaster.TypePrefixes[kind].."_"..rarity:upper().."_"..element:upper()
end
function ItemMaster.DisplayName(item)
 return "World "..tostring(item.WorldId or 1).." "..item.Rarity.." "..item.Element.." "..item.ItemType
end
return table.freeze(ItemMaster)
