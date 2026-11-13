local Ore=require(script.Parent.OreConfig)
local C={}
-- IDs identify reward contents, not their visual slots. Existing claims stay intact.
C.Rewards={
 {Id="IntroWin02",RequiredSeconds=60,RewardType="Win",Amount=1,ClaimOrder=1,Label="Win"},
 {Id="IronIntro01",RequiredSeconds=120,RewardType="Ore",OreId="ORE_003",Amount=2,ClaimOrder=2,Label=Ore.Get("ORE_003").Name.." ×2"},
 {Id="Reward03",RequiredSeconds=180,RewardType="Win",Amount=3,ClaimOrder=3,Label="Win"},
 {Id="Reward02",RequiredSeconds=300,RewardType="Potion",Amount=1,PotionId="Training",PotionDurationSeconds=60,ClaimOrder=4,Label="Treadmill Potion"},
 {Id="Reward04",RequiredSeconds=420,RewardType="Potion",Amount=1,PotionId="Strength",ClaimOrder=5,Label="Strength Potion"},
 {Id="Reward05",RequiredSeconds=600,RewardType="Win",Amount=10,ClaimOrder=6,Label="Win"},
 {Id="Reward07",RequiredSeconds=900,RewardType="Potion",Amount=1,PotionId="Training",ClaimOrder=7,Label="Treadmill Potion"},
 {Id="Reward08",RequiredSeconds=1800,RewardType="Win",Amount=25,ClaimOrder=8,Label="Win"},
 {Id="Reward09",RequiredSeconds=2700,RewardType="ItemRoll",Amount=10,ClaimOrder=9,Label="Items (no MISS)"},
}
C.Potions={
 Strength={Name="Strength Potion",DurationSeconds=180,Multiplier=1.5},
 Training={Name="Treadmill Potion",DurationSeconds=180,TreadmillBonus=1},
}
-- Existing purchased TimeReward icon assets; ore art comes from the ore catalogue.
C.Images={Win="rbxassetid://106494459783367",Potion="rbxassetid://88132060004695",ItemRoll="rbxassetid://73989013612789"}
function C.Get(id)
 if typeof(id)~="string" then return nil end
 for _,r in ipairs(C.Rewards) do if r.Id==id then return r end end
 return nil
end
-- Verified history: 0188223 Reward01 (first Win), 912d51c StoneIntro01.
-- These are one lifetime first slot, despite their former contents/positions.
local firstSlot={IntroWin02=true,StoneIntro01=true,Reward01=true}
function C.IsClaimed(claimed,id)
 if firstSlot[id] then
  for previous in pairs(firstSlot) do if claimed[previous]==true then return true end end
  return false
 end
 return claimed[id]==true
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
