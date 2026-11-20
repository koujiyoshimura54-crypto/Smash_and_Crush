-- Edit-only visual fixture: real layout/renderer, simulated animation time.
-- Does not execute reward clients, purchases, ads, analytics or data services.
return function(before)
 assert(game.PlaceId==126576845524886 and game.GameId==10765181857)
 assert(not game:GetService("RunService"):IsRunning())
 local backup=assert(shared.RewardBadgeHalf20261120)
 assert(not shared.RewardBadgePreview)
 local s={Originals={},Clones={},Cache={},Before=before}
 shared.RewardBadgePreview=s
 local old={};for _,row in backup.Targets do old[row.Path]=row.Source end
 local clock={Heartbeat={Connect=function(_,fn)
  s.Tick=fn;return {Disconnect=function()s.Tick=nil end}
 end}}
 function s.Require(m)
  assert(m:IsA("ModuleScript") and m:IsDescendantOf(game.ReplicatedStorage))
  if s.Cache[m]~=nil then return s.Cache[m]end
  local source=before and old[m:GetFullName()] or m.Source
  local f=assert(loadstring(source,"="..m:GetFullName()))
  local env={script=m,require=s.Require}
  if m.Name=="BadgeRenderer" then
   env.game={GetService=function(_,name)assert(name=="RunService");return clock end}
  end
  setfenv(f,setmetatable(env,{__index=getfenv()}))
  local v=f();s.Cache[m]=v;return v
 end
 function s.Destroy()
  for _,copy in s.Clones do copy:Destroy()end
  for original,row in s.Originals do original.Name=row.Name;original.Enabled=row.Enabled end
  shared.RewardBadgePreview=nil
 end
 for _,name in {"StrengthGui","World1DoubleWinGui"}do
  local original=game.StarterGui[name]
  s.Originals[original]={Name=original.Name,Enabled=original.Enabled}
  local copy=original:Clone()
  for _,x in copy:GetDescendants()do if x:IsA("LuaSourceContainer")then x:Destroy()end end
  original.Name="_RewardBadgeReview_"..name;original.Enabled=false
  copy.Parent=game.StarterGui;copy.Enabled=true;s.Clones[name]=copy
 end
 s.Require(game.ReplicatedStorage.Modules.HUDLayout).Mount(s.Clones.StrengthGui)
 local renderer=s.Require(game.ReplicatedStorage.Modules.BadgeRenderer)
 for _,name in {"TimeRewardsButton","DailyRewardsButton"}do
  local badge=s.Clones.StrengthGui.LeftMenu[name].NotificationBadge
  renderer.Attach(badge);badge.Visible=true
 end
 local function rect(x)
  local p,z=x.AbsolutePosition,x.AbsoluteSize
  return {X=p.X,Y=p.Y,W=z.X,H=z.Y}
 end
 function s.Snapshot()
  local rows={}
  for _,name in {"TimeRewardsButton","DailyRewardsButton"}do
   local button=s.Clones.StrengthGui.LeftMenu[name]
   local badge=button.NotificationBadge;local image=badge.NotificationImage
   local r=math.rad(image.Rotation);local z=image.AbsoluteSize
   local extent=Vector2.new(math.abs(math.cos(r))*z.X+math.abs(math.sin(r))*z.Y,
    math.abs(math.sin(r))*z.X+math.abs(math.cos(r))*z.Y)
   local center=image.AbsolutePosition+z/2
   table.insert(rows,{Name=name,Button=rect(button),Icon=rect(button.Icon),Image=rect(image),
    Rotated={X=center.X-extent.X/2,Y=center.Y-extent.Y/2,W=extent.X,H=extent.Y},
    Rotation=image.Rotation,ImageId=image.Image,Color=tostring(image.ImageColor3),
    UIScale=badge.RewardBadgeScale.Scale,ButtonScale=button.HUDScale.Scale,
    BadgePosition=tostring(badge.Position),Badge=rect(badge),
    Active=image.Active,Interactable=image.Interactable,Visible=badge.Visible})
  end
  return {Before=before,Viewport=rect(s.Clones.StrengthGui),Rows=rows}
 end
 return s
end
