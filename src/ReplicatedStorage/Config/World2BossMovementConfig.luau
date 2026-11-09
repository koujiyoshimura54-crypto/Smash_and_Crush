-- Compatibility view; edit BossBehaviorConfig.Worlds[2][stage] instead.
local Behavior=require(script.Parent.BossBehaviorConfig)
local C={Stages=Behavior.Worlds[2]}
function C.Get(stage) return Behavior.Get(2,stage) end
return table.freeze(C)
