-- World2 balance authority, approved 2026-09-15.
-- Data only: does not activate travel, combat, progression, rewards or inventory.
-- World2HPScale was removed after auditing its two callers. No World1 HP dependency.
local C={
 WorldId=2,
 SourceWorldId=1, -- Graybox provenance only; never a balance source.
 StageCount=10,
 RequiredStrengthStatus="Configured",
 BalanceVersion="20260915",
 WallHitMultipliers=table.freeze({2,2.5,3,4}),
 BossHitMultiplier=5,
}
local stages={
 [1]={RecommendedLevel=60,RequiredStrength=3000000},
 [2]={RecommendedLevel=75,RequiredStrength=10000000},
 [3]={RecommendedLevel=90,RequiredStrength=20000000},
 [4]={RecommendedLevel=105,RequiredStrength=50000000},
 [5]={RecommendedLevel=120,RequiredStrength=100000000},
 [6]={RecommendedLevel=140,RequiredStrength=200000000},
 [7]={RecommendedLevel=155,RequiredStrength=500000000},
 [8]={RecommendedLevel=170,RequiredStrength=1000000000},
 [9]={RecommendedLevel=185,RequiredStrength=2000000000},
 [10]={RecommendedLevel=200,RequiredStrength=5000000000},
}
for _,entry in ipairs(stages) do
 local walls={}
 for index,multiplier in ipairs(C.WallHitMultipliers) do
  walls[index]=entry.RequiredStrength*multiplier
 end
 entry.Walls=table.freeze(walls)
 entry.BossMaxHP=entry.RequiredStrength*C.BossHitMultiplier
 table.freeze(entry)
end
C.Stages=table.freeze(stages)
function C.GetStageConfig(stage) return C.Stages[stage] end
return table.freeze(C)
