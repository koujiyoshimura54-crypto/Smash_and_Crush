local C={}
-- Claim state and elapsed time are persisted. Strength Amount means normal-training seconds.
C.Rewards={
 {Id="Reward01",RequiredSeconds=60,RewardType="Win",Amount=1,ClaimOrder=1,Label="Win"},
 {Id="Reward02",RequiredSeconds=120,RewardType="Potion",Amount=1,PotionId="Training",PotionDurationSeconds=60,ClaimOrder=2,Label="Training Potion"},
 {Id="Reward03",RequiredSeconds=300,RewardType="Win",Amount=3,ClaimOrder=3,Label="Win"},
 {Id="Reward04",RequiredSeconds=420,RewardType="Potion",Amount=1,PotionId="Strength",ClaimOrder=4,Label="Strength Potion"},
 {Id="Reward05",RequiredSeconds=600,RewardType="Win",Amount=10,ClaimOrder=5,Label="Win"},
 {Id="Reward06",RequiredSeconds=900,RewardType="Strength",Amount=15,ClaimOrder=6,Label="Training"},
 {Id="Reward07",RequiredSeconds=1200,RewardType="Potion",Amount=1,PotionId="Training",ClaimOrder=7,Label="Training Potion"},
 {Id="Reward08",RequiredSeconds=1800,RewardType="Win",Amount=25,ClaimOrder=8,Label="Win"},
 {Id="Reward09",RequiredSeconds=2700,RewardType="ItemRoll",Amount=10,ClaimOrder=9,Label="Items (no MISS)"},
}
C.Potions={
 Strength={Name="Strength Potion",DurationSeconds=180,Multiplier=1.5},
 Training={Name="Training Potion",DurationSeconds=180,TreadmillBonus=1},
}
function C.Get(id)
 if typeof(id)~="string" then return nil end
 for _,r in ipairs(C.Rewards) do if r.Id==id then return r end end
 return nil
end
function C.GetPotionDuration(id,reward)
 local potion=C.Potions[id]
 return potion and ((reward and reward.PotionDurationSeconds) or potion.DurationSeconds)
end
return C

