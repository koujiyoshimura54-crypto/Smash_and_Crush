-- World1 Stage1-5 approved balance: 2026-11-12. Stage6-10 are unchanged.
-- World2 uses its independent World2Config. Shared V5 lottery retained.
local C={}
-- Preserve the old first-wall guidance floor even though Lv2 now costs only 5.
-- This is a tutorial arrow condition, not a combat/Stage entry restriction.
C.IntroTrainingStrength=10
function C.NeedsIntroTraining(level,strength,hasBattleProgress)
 return (level or 1)<2 or (not hasBattleProgress and (strength or 0)<C.IntroTrainingStrength)
end
C.RequiredStrength={
 [1]=40,[2]=360,[3]=2000,[4]=5000,[5]=14000,
 [6]=38000,[7]=82000,[8]=198000,[9]=360000,[10]=1000000,
}
C.RecommendedLevels={4,8,15,20,25,30,35,40,45,50}
C.StageCount=#C.RecommendedLevels
C.HPPerRequiredStrength=5
C.Lottery={
 {UpperExclusive=0.60,Chance=0},
 {UpperExclusive=0.70,Chance=0.25},
 {UpperExclusive=0.80,Chance=0.50},
 {UpperExclusive=0.85,Chance=0.80},
 {UpperExclusive=0.90,Chance=0.85},
 {UpperExclusive=0.95,Chance=0.90},
 {UpperExclusive=1.00,Chance=0.95},
}
function C.GetRequiredStrength(stage) return C.RequiredStrength[stage] end
function C.GetMaxHP(stage)
 local strength=C.GetRequiredStrength(stage)
 return strength and strength*C.HPPerRequiredStrength
end
function C.GetRecommendedLevel(stage) return C.RecommendedLevels[stage] end
function C.GetLotteryWinChance(ratio)
 if ratio>=1 then return 0 end
 for _,band in ipairs(C.Lottery) do
  if ratio<band.UpperExclusive then return band.Chance end
 end
 return 0
end
-- Stage1-5 walls are fixed independently of RequiredStrength.
-- Stage6-10 retain derived walls at 40/50/60/80 percent of Boss HP.
local walls={
 [1]={50,75,100,135},
 [2]={275,300,320,390},
 [3]={565,705,845,1130},
 [4]={2880,3600,4320,5760},
 [5]={6860,8575,10290,13720},
}
local wallConfigs={}
for stage=1,C.StageCount do
 local strength=C.GetRequiredStrength(stage)
 local hp=walls[stage] or {strength*2,strength*2.5,strength*3,strength*4}
 wallConfigs[stage]=table.freeze({Walls=table.freeze(hp),BossMaxHP=C.GetMaxHP(stage)})
end
-- Compatible wall lookup API, available for all World1 stages.
function C.GetWallConfig(stage) return wallConfigs[stage] end
table.freeze(C.RequiredStrength)
table.freeze(C.RecommendedLevels)
return table.freeze(C)
