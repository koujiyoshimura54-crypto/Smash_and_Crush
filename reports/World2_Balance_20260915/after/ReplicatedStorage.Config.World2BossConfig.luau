-- World2-only balance view. No World1 dependency or combat activation.
local World=require(script.Parent.World2Config)
local C={StageCount=World.StageCount,RequiredStrengthStatus=World.RequiredStrengthStatus}
local hp={}
for stage=1,C.StageCount do hp[stage]=World.GetStageConfig(stage).BossMaxHP end
C.MaxHP=table.freeze(hp)
function C.GetMaxHP(stage) return C.MaxHP[stage] end
function C.GetRequiredStrength(stage)
 local entry=World.GetStageConfig(stage)
 return entry and entry.RequiredStrength
end
function C.GetRecommendedLevel(stage)
 local entry=World.GetStageConfig(stage)
 return entry and entry.RecommendedLevel
end
return table.freeze(C)
