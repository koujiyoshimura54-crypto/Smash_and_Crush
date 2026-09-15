-- Server-only activation API; no client-supplied duration, multiplier, or timer.
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.TimeRewardConfig)
local M={}
local timers=setmetatable({}, {__mode="k"})
function M.Activate(player,id,timeRewardId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 local c=Config.Potions[id]
 if not c or typeof(c.DurationSeconds)~="number" or c.DurationSeconds<=0 or c.DurationSeconds>=math.huge then return false,"InvalidPotion" end
 local duration=Config.GetPotionDuration(id)
 if timeRewardId~=nil then
  local reward=Config.Get(timeRewardId)
  if not reward or reward.RewardType~="Potion" or reward.PotionId~=id then return false,"InvalidRewardPotion" end
  duration=Config.GetPotionDuration(id,reward)
 end
 if typeof(duration)~="number" or duration~=duration or duration<=0 or duration>=math.huge then return false,"InvalidDuration" end
 local t=timers[player] or {} timers[player]=t
 t[id]=math.max(os.clock(),t[id] or 0)+duration
 return true,"Activated"
end
function M.GetRemaining(player,id)
 local t=timers[player]
 return math.max(0,(t and t[id] or 0)-os.clock())
end
function M.GetStrengthMultiplier(player)
 return M.GetRemaining(player,"Strength")>0 and Config.Potions.Strength.Multiplier or 1
end
function M.GetTrainingBonus(player)
 return M.GetRemaining(player,"Training")>0 and Config.Potions.Training.TreadmillBonus or 0
end
function M.GetState(player)
 return {ServerTime=workspace:GetServerTimeNow(),StrengthSeconds=M.GetRemaining(player,"Strength"),TrainingSeconds=M.GetRemaining(player,"Training")}
end
Players.PlayerRemoving:Connect(function(p) timers[p]=nil end)
-- A durable bundle stores an absolute deadline; retries never add duration twice.
function M.EnsureExpiresAt(player,id,expiresAt)
 if not Config.Potions[id] or typeof(expiresAt)~="number" then return false end
 local remaining=math.max(0,expiresAt-os.time())
 if remaining<=0 then return true end
 local t=timers[player] or {};timers[player]=t
 t[id]=math.max(t[id] or 0,os.clock()+remaining)
 return true
end
return M

