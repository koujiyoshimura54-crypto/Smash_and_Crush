local Config = {}

-- Item effect source of truth. The existing module path is retained.
-- Element does not change effects. Edit only these rarity tables to rebalance.
Config.ProteinBonus = {
 Common = 1, Uncommon = 15, Rare = 30, Epic = 50, Legendary = 150,
}
Config.GloveBossDamageBonus = {
 Common = 0.05, Uncommon = 0.10, Rare = 0.20, Epic = 0.35, Legendary = 0.50,
}
Config.BeltTreadmillBonus = {
 Common = 0.25, Uncommon = 0.5, Rare = 1, Epic = 1.5, Legendary = 2,
}

function Config.GetProteinBonus(rarity)
 return Config.ProteinBonus[rarity] or 0
end
function Config.GetGloveBossDamageBonus(rarity)
 return Config.GloveBossDamageBonus[rarity] or 0
end
function Config.GetBeltTreadmillBonus(rarity)
 return Config.BeltTreadmillBonus[rarity] or 0
end
function Config.GetEffectText(itemType, rarity)
 if itemType == "Protein" then
  return "+" .. tostring(Config.GetProteinBonus(rarity)) .. " Strength"
 elseif itemType == "Glove" then
  return string.format("Boss Damage +%g%%", Config.GetGloveBossDamageBonus(rarity) * 100)
 elseif itemType == "TrainingBelt" then
  return "Treadmill +" .. tostring(Config.GetBeltTreadmillBonus(rarity)) .. "x"
 end
 return ""
end

return Config
