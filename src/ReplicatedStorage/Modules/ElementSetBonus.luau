local ItemMaster = require(game:GetService("ReplicatedStorage").Config:WaitForChild("ItemMaster"))

local Effects = require(game:GetService("ReplicatedStorage").Config.ItemMultiplierConfig)
local ElementSetBonus = {}

ElementSetBonus.Multiplier = 1.5

local REQUIRED_TYPES = {"Protein", "Glove", "TrainingBelt"}

function ElementSetBonus.GetMatchingElement(ownedItems, equippedItems)
 if typeof(ownedItems) ~= "table" or typeof(equippedItems) ~= "table" then return nil end
 local matchingElement
 for _, itemType in ipairs(REQUIRED_TYPES) do
  local itemId = equippedItems[itemType]
  local item = typeof(itemId) == "string" and ItemMaster.Get(itemId)
  local count = typeof(itemId) == "string" and tonumber(ownedItems[itemId]) or 0
  if not item or item.ItemType ~= itemType or not count or count <= 0
   or ItemMaster.ElementSet[item.Element] ~= true then return nil end
  if matchingElement and matchingElement ~= item.Element then return nil end
  matchingElement = item.Element
 end
 return matchingElement
end

function ElementSetBonus.GetMultiplier(ownedItems, equippedItems)
 return ElementSetBonus.GetMatchingElement(ownedItems, equippedItems) and ElementSetBonus.Multiplier or 1
end

-- Shared by server calculations and equipped-item presentation. Never mutate base tables.
function ElementSetBonus.GetBaseEffect(item)
 if not item then return 0 end
 local getter = ({Protein=Effects.GetProteinBonus, Glove=Effects.GetGloveBossDamageBonus,
  TrainingBelt=Effects.GetBeltTreadmillBonus})[item.ItemType]
 return getter and getter(item.Rarity,item.WorldId) or 0
end
function ElementSetBonus.GetEffects(ownedItems,equippedItems)
 local result={Protein=0,Glove=0,TrainingBelt=0}
 local multiplier=ElementSetBonus.GetMultiplier(ownedItems,equippedItems)
 for _,kind in ipairs(REQUIRED_TYPES) do
  local id=typeof(equippedItems)=="table" and equippedItems[kind]
  local item=typeof(id)=="string" and ItemMaster.Get(id)
  if item and item.ItemType==kind and typeof(ownedItems)=="table" and (tonumber(ownedItems[id]) or 0)>0 then
   result[kind]=ElementSetBonus.GetBaseEffect(item)*multiplier
  end
 end
 return result
end

return table.freeze(ElementSetBonus)
