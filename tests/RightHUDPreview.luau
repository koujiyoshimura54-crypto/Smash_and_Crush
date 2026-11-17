-- Explicit Edit-only rendering fixture. No player, reward, purchase or data services.
return function()
 assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
 assert(not shared.RightHudPreview,"Remove the previous preview first")
 local s={originals={},clones={},cache={}};shared.RightHudPreview=s
 function s.require(m)
  assert(m:IsA("ModuleScript") and m:IsDescendantOf(game.ReplicatedStorage),"Preview module boundary")
  if s.cache[m]~=nil then return s.cache[m]end
  local f=assert(loadstring(m.Source,"="..m:GetFullName()))
  setfenv(f,setmetatable({script=m,require=s.require},{__index=getfenv()}))
  local v=f();s.cache[m]=v;return v
 end
 function s.Destroy()
  for _,x in s.clones do x:Destroy()end
  for original,enabled in s.originals do original.Name=original.Name:gsub("^_ReviewOriginal_","");original.Enabled=enabled end
  shared.RightHudPreview=nil
 end
 for _,name in {"StrengthGui","World1DoubleWinGui"}do
  local original=game.StarterGui[name];s.originals[original]=original.Enabled
  local copy=original:Clone()
  for _,x in copy:GetDescendants()do if x:IsA("LuaSourceContainer")then x:Destroy()end end
  original.Name="_ReviewOriginal_"..name;original.Enabled=false
  copy.Parent=game.StarterGui;copy.Enabled=true;s.clones[name]=copy
 end
 s.layout=s.require(game.ReplicatedStorage.Modules.HUDLayout).Mount(s.clones.StrengthGui)
 s.require(game.ReplicatedStorage.Modules.BadgeRenderer).Mount(s.clones.StrengthGui)
 for _,name in {"TimeRewardsButton","DailyRewardsButton"}do s.clones.StrengthGui.LeftMenu[name].NotificationBadge.Visible=true end
 return s
end
