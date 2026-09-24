local ItemMaster = require(game:GetService("ReplicatedStorage").Config:WaitForChild("ItemMaster"))

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

return table.freeze(ElementSetBonus)

