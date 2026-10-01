-- Hand-authored item balance; independent of SpeedConfig.WalkSpeed.
local C = {
 NONE = {BossAttackReachMultiplier = 1.00},
 Speed1 = {BossAttackReachMultiplier = 1.30},
 Premium = {BossAttackReachMultiplier = 1.50},
}
for _, entry in pairs(C) do table.freeze(entry) end
return table.freeze(C)
