-- Legacy World1 Stage1 view; author Stage values and SpeedModifiers in BossBehaviorConfig.
local Behavior=require(script.Parent.BossBehaviorConfig)
local C={}
for id in pairs(Behavior.SpeedModifiers) do C[id]=table.freeze(Behavior.GetAttackSettings(1,1,id)) end
return table.freeze(C)
