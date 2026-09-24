-- Compatibility view; AuraConfig is the sole specification.
local config=require(game.ReplicatedStorage.Config:WaitForChild("AuraConfig"))
local list={}
for _,id in ipairs(config.Order) do
 local aura=table.clone(config.Get(id))
 aura.Bonus="+"..aura.StrengthBonus.." Strength"
 aura.Currency=aura.PurchaseType=="Win" and tostring(aura.Price).." WIN" or "ROBUX"
 list[#list+1]=aura
end
return list
