local PotionConfig=require(game.ReplicatedStorage.Config:WaitForChild("TimeRewardConfig"))
local Numbers=require(game.ReplicatedStorage.Modules:WaitForChild("NumberFormat"))
local M={}
function M.GetText(reward)
 if reward.RewardType=="Win" then return "Win +"..Numbers.Plain(reward.Amount) end
 if reward.RewardType=="Strength" then return "Training: "..Numbers.Plain(reward.Amount).." seconds" end
 if reward.RewardType=="ItemRoll" then return "Item ×"..Numbers.Plain(reward.Amount) end
 if reward.RewardType=="Potion" then
  local potion=PotionConfig.Potions[reward.PotionId]
  if not potion then return "Unavailable" end
  return potion.Name.." ("..tostring(PotionConfig.GetPotionDuration(reward.PotionId,reward)).." sec)"
 end
 return reward.Label or ""
end
function M.GetCommunityText(config)
 return "Win +"..Numbers.Plain(config.WinAmount).." and Item ×"..Numbers.Plain(config.ItemAmount)
end
return table.freeze(M)
