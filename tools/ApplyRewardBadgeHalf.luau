-- Reapply the two Edit-time property changes; does not save or start Play.
-- Existing authored compensation is recorded so re-running never halves twice.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857)
assert(not game:GetService("RunService"):IsRunning())
local style=assert(loadstring(game.ReplicatedStorage.Config.RightHUDStyle.Source))()
local originalCompensation=2.7288167476654053
local rows={}
for _,name in {"TimeRewardsButton","DailyRewardsButton"}do
 local button=game.StarterGui.StrengthGui.LeftMenu[name]
 local badge=button.NotificationBadge
 local compensation=badge.RewardBadgeScale
 local target=originalCompensation*style.RewardBadgeSizeRatio
 assert(math.abs(compensation.Scale-originalCompensation)<1e-6
  or math.abs(compensation.Scale-target)<1e-6,"Unexpected edited scale: "..badge:GetFullName())
 local scale=button.HUDScale.Scale
 local half=style.BadgeDesignSize*style.BadgeImageScale*target*scale/2
 local angle=math.rad(style.BadgeMaxRotation)
 local radius=half*(math.cos(angle)+math.sin(angle))
 local previous={Scale=compensation.Scale,Position=tostring(badge.Position)}
 compensation.Scale=target
 badge.AnchorPoint=Vector2.new(.5,.5)
 badge.Position=UDim2.new(1,0,0,math.ceil(radius/scale))
 table.insert(rows,{Path=badge:GetFullName(),Before=previous,
  After={Scale=compensation.Scale,Position=tostring(badge.Position)}})
end
return rows
