-- World1 Stage1-10 balance authority. Runtime values preserved on 2026-09-16.
-- World2 uses its independent World2Config. Shared V5 lottery retained.
local C={}
C.RequiredStrength={
 [1]=75,[2]=450,[3]=2500,[4]=6000,[5]=15000,
 [6]=37315,[7]=81865,[8]=196915,[9]=462965,[10]=1018015,
}
C.RecommendedLevels={8,10,15,20,25,30,35,40,45,50}
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
-- Preserve the existing early-stage walls independently of Boss strength.
-- In particular Stage2 retains its special 3 / 3.25 / 3.5 / 4.25 multipliers.
local walls={
 [1]={100,125,150,200},
 [2]={300,325,350,425},
 [3]={600,750,900,1200},
 [4]={3000,3750,4500,6000},
 [5]={7000,8750,10500,14000},
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
