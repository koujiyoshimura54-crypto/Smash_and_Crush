-- Pure arithmetic shared by live gains and prospective equipment/reference rates.
-- Item inputs are already effective values; there is no final Element multiplier.
local M={}
function M.Gain(amount,ticks,c,sourceMultiplier)
 local base=amount>0 and (amount+((c.Dumbbell or 0)+c.Aura+c.Protein)*ticks) or amount
 return base*c.Rebirth*sourceMultiplier*(c.StrengthPotion or 1)*c.VIP*c.Pet
end
return table.freeze(M)
