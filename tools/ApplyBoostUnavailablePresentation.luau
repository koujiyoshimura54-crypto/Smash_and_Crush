-- Edit-only initial appearance, using the same production style constants.
-- Runtime Open / Close / availability remain owned by RewardedStrengthBoostClient.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857)
assert(not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage
local loadStyle=assert(loadstring(RS.Config.RewardedStrengthBoostStyle.Source))
setfenv(loadStyle,setmetatable({script=RS.Config.RewardedStrengthBoostStyle,require=function(m)
 assert(m==RS.Config.StrengthHUDStyle);return assert(loadstring(m.Source))()
end},{__index=getfenv()}))
local S=loadStyle()
local gui=assert(game.StarterGui:FindFirstChild("RewardedStrengthBoostGui"))
gui.Entry.Visible=true
local watch=gui.Overlay.Panel.Watch
watch.BackgroundColor3=S.UnavailableColor;watch.Active=false;watch.AutoButtonColor=false
watch.Title.Text="Unavailable";watch.Title.TextSize=S.Modal.StatusTextSize
return "Entry shown; initial watch state is Unavailable; geometry and artwork preserved"
