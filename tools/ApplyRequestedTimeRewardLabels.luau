-- Idempotent Edit-only authored text/image update; reward ownership is never touched.
assert(game.PlaceId==126576845524886)
assert(not game:GetService("RunService"):IsRunning())
local C=require(game.ReplicatedStorage.Config.TimeRewardConfig)
local gui=game.StarterGui.StrengthGui
local changed={}
for _,reward in ipairs(C.Rewards) do
 local card=gui.TimeRewardsPanel.Holder[C.GetCardName(reward)]
 local text=reward.Label
 if reward.RewardType=="Win" then text="Win +"..reward.Amount
 elseif reward.RewardType=="Potion" then text=reward.Label.." ("..C.GetPotionDuration(reward.PotionId,reward).." sec)"
 elseif reward.RewardType=="ItemRoll" then text="Item ×"..reward.Amount end
 card.RewardName.Text=text;card.Decor.Icon.Image=C.GetImage(reward)
 table.insert(changed,card:GetFullName())
end
gui.DailyRewardsPanel.Holder.Day5.RewardText.Text=require(game.ReplicatedStorage.Config.DailyRewardConfig).Rewards[5].Label
local benefits=gui.ShopPanel.MainScrollingFrame.Holder.Card02_StarterPack.Benefits
benefits.Text=benefits.Text:gsub("Training Potion","Treadmill Potion")
return changed
