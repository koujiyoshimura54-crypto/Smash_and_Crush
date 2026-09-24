-- Explicit World2 boss allowlist. SourceModels are archival, never auto-enumerated.
local stages = {
 [1] = {SCP="SCP-096", Template="SCP096_Display"},
 [2] = {SCP="SCP-023", Template="SCP023_Display"},
 [3] = {SCP="SCP-035", Template="SCP035_Display"},
 [4] = {SCP="SCP-058", Template="SCP058_Display"},
 [5] = {SCP="SCP-049", Template="SCP049_Display"},
 [6] = {SCP="SCP-173", Template="SCP173_Display"},
 [7] = {SCP="SCP-939", Template="SCP939_Display"},
 [8] = {SCP="SCP-106", Template="SCP106_Display"},
 [9] = {SCP="SCP-682", Template="SCP682_Display"},
 [10] = {SCP="SCP-323", Template="SCP323_Display"},
}
for _,entry in stages do table.freeze(entry) end
return table.freeze({
 Stages=table.freeze(stages),
 -- No World2 Win table has been approved. Do not borrow World1 rewards.
 RewardStatus="Unconfigured",
})
