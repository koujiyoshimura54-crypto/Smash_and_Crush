-- HP-only projection; never mutates the World1 table or copies its unlock rules.
local Base=require(script.Parent.World1BossConfig)
local World=require(script.Parent.World2Config)
local C={StageCount=Base.StageCount,RequiredStrengthStatus="Pending"}
local hp={}
for stage=1,C.StageCount do
 hp[stage]=assert(Base.GetMaxHP(stage))*World.World2HPScale
end
C.MaxHP=table.freeze(hp)
function C.GetMaxHP(stage) return C.MaxHP[stage] end
-- Intentionally unavailable until World2 balancing is approved.
function C.GetRequiredStrength(stage) return nil end
return table.freeze(C)

