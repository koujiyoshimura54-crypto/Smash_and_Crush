-- Temporary early-World1 Play balance: Stage1–5 only. Shared V5 lottery retained.
local C={}
C.RequiredStrength={
 [1]=50,[2]=100,[3]=450,[4]=2000,[5]=5000,
 [6]=20000,[7]=70000,[8]=200000,[9]=600000,[10]=2000000,
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
return C
