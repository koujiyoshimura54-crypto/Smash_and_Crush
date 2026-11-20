-- Edit-only reapplication of the two reward entry colors; no Save / Publish.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857)
assert(not game:GetService("RunService"):IsRunning())
local cache={}
local allowed={RightHUDPresentation=true,RightHUDStyle=true,StrengthHUDStyle=true}
local function loadModule(m)
 assert(m:IsDescendantOf(game.ReplicatedStorage) and allowed[m.Name],"Presentation boundary")
 if cache[m]then return cache[m]end
 local f=assert(loadstring(m.Source,"="..m:GetFullName()))
 setfenv(f,setmetatable({script=m,require=loadModule},{__index=getfenv()}))
 local v=f();cache[m]=v;return v
end
local presentation=loadModule(game.ReplicatedStorage.Modules.RightHUDPresentation)
for _,name in {"TimeRewardsButton","DailyRewardsButton"}do
 presentation.ApplyRewardColors(game.StarterGui.StrengthGui.LeftMenu[name])
end
return "Applied reward entry colors only"
