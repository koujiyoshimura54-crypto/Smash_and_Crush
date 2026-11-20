-- Explicit temporary Edit preview. Actual client/layout code, Studio start gate,
-- local clock/player/events; no real API, network, purchases or persistent data.
return function()
 assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
 assert(not shared.BoostUnavailablePreview)
 local s={Originals={},Clones={},Events={},Cache={},Calls=0,Sent=0}
 shared.BoostUnavailablePreview=s
 function s.Require(m)
  assert(m:IsA("ModuleScript")and m:IsDescendantOf(game.ReplicatedStorage))
  if s.Cache[m]~=nil then return s.Cache[m]end
  local f=assert(loadstring(m.Source,"="..m:GetFullName()))
  setfenv(f,setmetatable({script=m,require=s.Require},{__index=getfenv()}))
  local v=f();s.Cache[m]=v;return v
 end
 function s.Destroy()
  if s.Api then s.Api.Destroy()end
  for _,x in s.Clones do x:Destroy()end
  for _,e in s.Events do e:Destroy()end
  if s.Player then s.Player:Destroy()end
  for x,row in s.Originals do x.Name=row.Name;x.Enabled=row.Enabled end
  shared.BoostUnavailablePreview=nil
 end
 for _,name in {"StrengthGui","World1DoubleWinGui","RewardedStrengthBoostGui"}do
  local original=game.StarterGui:FindFirstChild(name)
  if original then
   s.Originals[original]={Name=original.Name,Enabled=original.Enabled}
   if name~="RewardedStrengthBoostGui" then
    local clone=original:Clone()
    for _,x in clone:GetDescendants()do if x:IsA("LuaSourceContainer")then x:Destroy()end end
    table.insert(s.Clones,clone)
   end
   original.Name="_BoostUnavailableOriginal_"..name;original.Enabled=false
  end
 end
 for _,clone in s.Clones do clone.Parent=game.StarterGui;clone.Enabled=true end
 s.Main=s.Clones[1];s.Require(game.ReplicatedStorage.Modules.HUDLayout).Mount(s.Main)
 local function event()local e=Instance.new("BindableEvent");table.insert(s.Events,e);return e end
 local opened,closed,reply=event(),event(),event()
 s.Player=Instance.new("Folder");s.Player:SetAttribute("StrengthBoostExpiresAt",0)
 s.Main:SetAttribute("StrengthBoostDiagnostics",true)
 local d={Player=s.Player,Menu={MenuIsOpen=false,MenuOpened=opened.Event,MenuClosed=closed.Event},
  Now=function()return 1000 end,Monotonic=os.clock,Reply=reply.Event,
  StudioRestricted=game:GetService("RunService"):IsStudio(),ManualTick=true,
  Available=function()s.Calls+=1;error("Studio restriction must prevent real availability checks")end,
  Send=function()s.Sent+=1;error("No sends allowed")end,Price=function()return nil,"Preview"end}
 s.Api=s.Require(game.ReplicatedStorage.Modules.RewardedStrengthBoostClient).Mount(s.Main,d)
 s.Gui=s.Api.Gui
 local function rect(x)local p,z=x.AbsolutePosition,x.AbsoluteSize;return {X=p.X,Y=p.Y,W=z.X,H=z.Y}end
 function s.Snapshot()
  local p=s.Gui.Overlay.Panel;local texts={}
  for _,x in {s.Gui.Entry.Title,s.Gui.Entry.Footer,p.Title,p.Subtitle,p.Watch.Title,p.Close.Title}do
   table.insert(texts,{Name=x:GetFullName(),Text=x.Text,Rect=rect(x),Bounds=tostring(x.TextBounds),Fits=x.TextFits})
  end
  return {Viewport=rect(s.Gui),Entry=rect(s.Gui.Entry),Panel=rect(p),Watch=rect(p.Watch),Close=rect(p.Close),
   EntryVisible=s.Gui.Entry.Visible,OverlayVisible=s.Gui.Overlay.Visible,WatchActive=p.Watch.Active,
   WatchColor=tostring(p.Watch.BackgroundColor3),ArmImage=p.Arm.Image,ArmColor=tostring(p.Arm.ImageColor3),
   Texts=texts,Queries=s.Calls,Sends=s.Sent,State=s.Api.GetAvailabilityState(),Diagnostics=s.Api.GetAvailabilityDiagnostics()}
 end
 return s
end
