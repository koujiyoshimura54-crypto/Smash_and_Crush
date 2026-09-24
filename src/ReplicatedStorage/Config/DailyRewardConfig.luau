local C={}
C.Rewards={
 {Day=1,RewardType="Win",Amount=1,Label="Win"},
 {Day=2,RewardType="Potion",Amount=1,PotionId="Strength",Label="Strength Potion"},
 {Day=3,RewardType="Win",Amount=3,Label="Win"},
 {Day=4,RewardType="ItemRoll",Amount=10,Label="Items"},
 {Day=5,RewardType="Potion",Amount=1,PotionId="Training",Label="Training Potion"},
 {Day=6,RewardType="Win",Amount=5,Label="Win"},
 {Day=7,RewardType="ItemRoll",Amount=10,Label="Items"},
}
-- Only Day7 supplies this override. Normal roller weights remain untouched.
C.Day7RarityWeights={50,25,15,8,2}
function C.GetDayCount() return #C.Rewards end
function C.GetRarityWeights(day)
 return day==7 and C.Day7RarityWeights or nil
end
function C.Get(day)
 if typeof(day)~="number" or day%1~=0 then return nil end
 return C.Rewards[day]
end
return C
