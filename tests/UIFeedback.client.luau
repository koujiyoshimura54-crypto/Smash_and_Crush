local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local SS=game:GetService("SoundService")
local CP=game:GetService("ContentProvider")
local F=require(RS.Modules.UIFeedback)
F.Start()
local counts,events={},{}
local watched=setmetatable({},{__mode="k"})
local function watch(s)
 if not s:IsA("Sound") or watched[s] then return end;watched[s]=true
 s.Played:Connect(function()
  counts[s.Name]=(counts[s.Name] or 0)+1
  events[#events+1]={Name=s.Name,Id=s.SoundId,Volume=s.Volume,Speed=s.PlaybackSpeed}
 end)
end
for _,s in SS:GetDescendants() do watch(s) end
SS.DescendantAdded:Connect(watch)
local latest={}
for _,name in {"RebirthRequest","ItemPurchaseRequest","DumbbellPurchaseRequest","AuraPurchaseRequest","SpeedPurchaseRequest","TimeRewardClaim","DailyRewardClaim"} do
 RS.Remotes:WaitForChild(name).OnClientEvent:Connect(function(r) if r.Success~=nil or r.Type then latest[name]=r end end)
end
local function count(name)return counts["AddedUIFeedback_"..name] or 0 end
local function waitCount(name,before,n,label)
 task.wait(.4);assert(count(name)-before==n,label..": "..(count(name)-before).." expected "..n)
end
local q=Instance.new("BindableFunction");q.Name="__SEQA";q.Parent=p.PlayerScripts
q.OnInvoke=function(action,value)
 if action=="Warm" then
  local loaded={}
  for _,s in SS.UI:GetChildren() do
   if s:IsA("Sound") then CP:PreloadAsync({s},function(_,status)loaded[s.Name]=status.Name end) end
  end
  for _,role in {"Hover","Click","Rebirth","Offline","Merge","Sale","Purchase","WinReward","Reward","Denied","Level"} do F.Play(role);task.wait(.16) end
  task.wait(.4);table.clear(counts);table.clear(events)
  return loaded
 elseif action=="Cases" then
  local checks={}
  local function check(name,fn,sound,n)
   local before=count(sound);fn();waitCount(sound,before,n,name);checks[#checks+1]=name
  end
  check("Rebirth success then repeated result",function()F.Rebirth({Type="Success",RebirthCount=88});F.Rebirth({Type="Success",RebirthCount=88})end,"Winner",1)
  check("Rejected Rebirth",function()F.Rebirth({Type="Denied"})end,"Error",1)
  check("Confirmed offline and double grant totals",function()
   F.ObserveStrength({SessionToken=p:GetAttribute("ForgeSessionToken"),GrantedTotal=100,Level=p:GetAttribute("Level")})
   F.ObserveStrength({SessionToken=p:GetAttribute("ForgeSessionToken"),GrantedTotal=200})
   F.ObserveStrength({SessionToken=p:GetAttribute("ForgeSessionToken"),GrantedTotal=200})
  end,"Success",1)
  check("Second committed double remainder",function()F.ObserveStrength({SessionToken=p:GetAttribute("ForgeSessionToken"),GrantedTotal=300})end,"Success",1)
  check("Repeated view no reward",function()F.ObserveStrength({SessionToken=p:GetAttribute("ForgeSessionToken"),GrantedTotal=300})end,"Success",0)
  check("Item merge identity",function()F.ItemMerge({Success=true,RequestId="mock-item",ResultItemId="PROTEIN_UNCOMMON_FIRE"});F.ItemMerge({Success=true,RequestId="mock-item",ResultItemId="PROTEIN_UNCOMMON_FIRE"})end,"Success",1)
  check("Ore merge identity",function()F.Forge({Action="MergeOre",Id="mock-ore"},{Success=true});F.Forge({Action="MergeOre",Id="mock-ore"},{Success=true})end,"Success",1)
  check("Bulk ore sale once",function()F.Forge({Action="SellOre",Id="mock-sale"},{Success=true});F.Forge({Action="SellOre",Id="mock-sale"},{Success=true})end,"Cash",1)
  check("Dumbbell sale once",function()F.Forge({Action="SellDumbbell",Id="mock-bell"},{Success=true})end,"Cash",1)
  check("Material denial repeated",function()F.Forge({Action="MergeOre",Id="mock-denied"},{Success=false,Code="SelectAtLeastTwoOres"});F.Forge({Action="MergeOre",Id="mock-denied"},{Success=false,Code="SelectAtLeastTwoOres"})end,"Error",1)
  check("Win purchase then duplicate",function()F.Purchase("Item",{Success=true,Code="Purchased",FeedbackId="mock-buy"});F.Purchase("Item",{Success=true,Code="Purchased",FeedbackId="mock-buy"})end,"Success",1)
  check("Checkout cancellation/prompt/already owned silent",function()
   for _,code in {"Cancelled","Prompted","AlreadyOwned","AwaitingReceipt"} do F.Purchase("Item",{Success=true,Code=code,FeedbackId=code})end
  end,"Success",0)
  check("Insufficient Win",function()F.Purchase("Item",{Success=false,Code="NotEnoughWin",FeedbackId="mock-short"})end,"Error",1)
  check("Unequipped stand isn't purchase",function()F.Purchase("Dumbbell",{Success=true,Code="Equipped",FeedbackId="mock-equip",PurchaseConfirmed=false})end,"Success",0)
  check("Pet merge leaves hatch to existing path",function()F.Forge({Action="MergePet",Id="mock-pet"},{Success=true})end,"Success",0)
  check("Multiple levels once",function()F.Level((p:GetAttribute("Level") or 1)+4);F.Level((p:GetAttribute("Level") or 1)+4)end,"Notification",1)
  local gui=Instance.new("ScreenGui");gui.Name="__SEQAButtons";gui.ResetOnSpawn=false;gui.Parent=p.PlayerGui
  local b=Instance.new("TextButton");b.Name="NewButton";b.Active=true;b.Parent=gui
  F.BindButton(b);F.BindButton(b)
  check("New button click",function()F.Button(b,false)end,"Click",1)
  b:SetAttribute("ExistingClickSE",true)
  check("Existing click owner excluded",function()F.Button(b,false)end,"Click",0)
  b:SetAttribute("ExistingHoverSE",true)
  check("Existing hover owner excluded",function()F.Button(b,true)end,"Hover",0)
  b:SetAttribute("ExistingClickSE",nil);b.Interactable=false
  check("Disabled button silent",function()F.Button(b,false)end,"Click",0)
  b:Destroy();b=Instance.new("TextButton");b.Active=true;b.Parent=gui;F.BindButton(b)
  check("Replacement GUI button one callback",function()F.Button(b,false)end,"Click",1)
  gui:Destroy()
  check("Hover burst rate limited",function()for _=1,10 do F.Play("Hover")end end,"Hover",1)
  return {Checks=checks,Counts=table.clone(counts)}
 elseif action=="Send" then
  local r=RS.Remotes[value.Name]
  if value.Name=="StrengthRewards" then return r:InvokeServer(value.Action,value.Value) end
  r:FireServer(table.unpack(value.Args or {}));task.wait(.6);return {Result=latest[value.Name],Counts=table.clone(counts)}
 elseif action=="Forge" then
  local Forge=require(RS.Modules.ForgeClient);Forge.Refresh()
  local response
  local c=Forge.Completed:Connect(function(op,result)response={Operation=op,Result=result}end)
  Forge.Request(value.Action,value.Fields)
  local limit=os.clock()+8;repeat task.wait(.1) until response or os.clock()>limit
  c:Disconnect();return {Response=response,Counts=table.clone(counts)}
 elseif action=="Inspect" then
  local sounds={} for _,s in SS:GetChildren() do if s:GetAttribute("AddedUIFeedback") then
   sounds[s.Name]={Loaded=s.IsLoaded,Length=s.TimeLength,Position=s.TimePosition,Playing=s.Playing,Volume=s.Volume}
  end end return {Counts=table.clone(counts),Sounds=sounds,Events=events}
 elseif action=="Replay" then
  local r=latest[value];local before=table.clone(counts)
  F.Purchase(({ItemPurchaseRequest="Item",DumbbellPurchaseRequest="Dumbbell",AuraPurchaseRequest="Aura",SpeedPurchaseRequest="Speed"})[value],r)
  task.wait(.4);return {Before=before,After=table.clone(counts)}
 end
end

