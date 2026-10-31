-- World2 balance authority, approved 2026-09-15.
-- World2 workbook authority; existing battle rules and placements are retained.
-- World2HPScale was removed after auditing its two callers. No World1 HP dependency.
local Workbook=require(script.Parent.World2GameplayConfig)
local C={
 WorldId=2,
 SourceWorldId=1, -- Graybox provenance only; never a balance source.
 StageCount=10,
 RequiredStrengthStatus="Configured",
 BalanceVersion=Workbook.Version,
 WallHitMultipliers=table.freeze({2,2.5,3,3.5,4,4.5}), -- Stage rows determine the actual count.
 BossHitMultiplier=5,
}
local stages={
 [1]={RecommendedLevel=60},
 [2]={RecommendedLevel=75},
 [3]={RecommendedLevel=90},
 [4]={RecommendedLevel=105},
 [5]={RecommendedLevel=120},
 [6]={RecommendedLevel=140},
 [7]={RecommendedLevel=155},
 [8]={RecommendedLevel=170},
 [9]={RecommendedLevel=185},
 [10]={RecommendedLevel=200},
}
for stage,entry in ipairs(stages) do
 local approved=Workbook.Stages[stage]
 entry.RequiredStrength=approved.BossMaxHP/C.BossHitMultiplier -- Existing combat benchmark, never an entry gate.
 entry.Walls=approved.Walls
 entry.WallCount=#approved.Walls
 local multipliers={}
 for i,hp in ipairs(approved.Walls) do multipliers[i]=hp/entry.RequiredStrength end
 entry.WallHitMultipliers=table.freeze(multipliers)
 entry.BossMaxHP=approved.BossMaxHP
 entry.WinReward=approved.WinReward
 table.freeze(entry)
end
C.Stages=table.freeze(stages)
function C.GetStageConfig(stage) return C.Stages[stage] end
function C.GetWallCount(stage) return #C.Stages[stage].Walls end
function C.GetWallHitMultipliers(stage) return C.Stages[stage].WallHitMultipliers end
return table.freeze(C)
