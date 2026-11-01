local Ore=require(script.Parent.OreConfig)
local C={}
-- IDs identify reward contents, not their visual slots. Existing claims stay intact.
C.Rewards={
 {Id="StoneIntro01",RequiredSeconds=60,RewardType="Ore",OreId="ORE_001",Amount=1,ClaimOrder=1,Label=Ore.Get("ORE_001").Name.." ×1"},
 {Id="Reward01",RequiredSeconds=120,RewardType="Win",Amount=1,ClaimOrder=2,Label="Win"},
 {Id="Reward02",RequiredSeconds=300,RewardType="Potion",Amount=1,PotionId="Training",PotionDurationSeconds=60,ClaimOrder=3,Label="Training Potion"},
 {Id="Reward03",RequiredSeconds=420,RewardType="Win",Amount=3,ClaimOrder=4,Label="Win"},
 {Id="Reward04",RequiredSeconds=600,RewardType="Potion",Amount=1,PotionId="Strength",ClaimOrder=5,Label="Strength Potion"},
 {Id="Reward05",RequiredSeconds=900,RewardType="Win",Amount=10,ClaimOrder=6,Label="Win"},
 {Id="Reward07",RequiredSeconds=1200,RewardType="Potion",Amount=1,PotionId="Training",ClaimOrder=7,Label="Training Potion"},
 {Id="Reward08",RequiredSeconds=1800,RewardType="Win",Amount=25,ClaimOrder=8,Label="Win"},
 {Id="Reward09",RequiredSeconds=2700,RewardType="ItemRoll",Amount=10,ClaimOrder=9,Label="Items (no MISS)"},
}
C.Potions={
 Strength={Name="Strength Potion",DurationSeconds=180,Multiplier=1.5},
 Training={Name="Training Potion",DurationSeconds=180,TreadmillBonus=1},
}
-- Existing purchased TimeReward icon assets; ore art comes from the ore catalogue.
C.Images={Win="rbxassetid://106494459783367",Potion="rbxassetid://88132060004695",ItemRoll="rbxassetid://73989013612789"}
function C.Get(id)
 if typeof(id)~="string" then return nil end
 for _,r in ipairs(C.Rewards) do if r.Id==id then return r end end
 return nil
end
function C.GetCardName(reward) return string.format("Reward%02d",reward.ClaimOrder) end
function C.GetImage(reward)
 if reward.RewardType=="Ore" then return Ore.Get(reward.OreId).Image end
 return C.Images[reward.RewardType]
end
function C.GetPotionDuration(id,reward)
 local potion=C.Potions[id]
 return potion and ((reward and reward.PotionDurationSeconds) or potion.DurationSeconds)
end
return C
