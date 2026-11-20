return function(s)
 local checks=0;local cases={};local fixtures={}
 local function eq(a,b,label)checks+=1;assert(a==b,(label or "check")..": "..tostring(a).." ~= "..tostring(b))end
 local function settle()task.wait(.02)end
 local function fixture(source,ignoreCancel,studio)
  local f={Mono=0,Now=1000,Queries={},Sent={},Events={},Threads={}}
  local values={};local rs={Config={RewardedStrengthBoostConfig="Config",RewardedStrengthBoostStyle="Style"}}
  local parent={StrengthHUDStyle="HUDStyle",RewardedStrengthBoostPresentation="Visual",NumberFormat="NumberFormat"}
  local function load(key,code)
   local fn=assert(loadstring(code or s[key]));setfenv(fn,setmetatable({game={GetService=function(_,n)assert(n=="ReplicatedStorage");return rs end},script={Parent=parent},require=function(k)return assert(values[k],k)end},{__index=getfenv()}))
   values[key]=fn();return values[key]
  end
  load("Config");load("HUDStyle");load("Style");load("Visual");values.NumberFormat={Price=tostring}
  local client=load("Client",source)
  local folder=Instance.new("Folder");folder.Name="UnparentedRecoveryFixture";f.Root=folder
  local main=Instance.new("ScreenGui");main.Name="StrengthGui";main.Parent=folder;main:SetAttribute("StrengthBoostDiagnostics",true);f.Main=main
  for _,name in {"OfflineRewards","ShopPanel","InventoryPanel","MergePanel","RebirthPanel","DailyRewardsPanel","TimeRewardsPanel","CommunityRewardsPanel"}do
   local p=Instance.new("Frame");p.Name=name;p.Visible=false;p.Parent=main
  end
  local scroll=Instance.new("ScrollingFrame");scroll.Name="MainScrollingFrame";scroll.Parent=main.ShopPanel
  local holder=Instance.new("Frame");holder.Name="Holder";holder.Parent=scroll
  local player=Instance.new("Folder");player.Name="MockPlayer";player.Parent=folder;f.Player=player
  local function event()local e=Instance.new("BindableEvent");table.insert(f.Events,e);return e end
  local opened,closed,reply=event(),event(),event()
  local character=event();f.CharacterAdded=character
  local menu={MenuIsOpen=false,MenuOpened=opened.Event,MenuClosed=closed.Event}
  function f.Toggle(name,on)
   if name=="Menu" then menu.MenuIsOpen=on;(on and opened or closed):Fire()
   else main[name].Visible=on end
   settle()
  end
  local playerProxy={CharacterAdded=character.Event,IsA=function(_,class)return class=="Player" end,
   GetAttribute=function(_,key)return player:GetAttribute(key)end,
   GetAttributeChangedSignal=function(_,key)return player:GetAttributeChangedSignal(key)end}
  local d={Player=playerProxy,Menu=menu,Now=function()return f.Now end,Monotonic=function()return f.Mono end,Reply=reply.Event,
   Send=function(action,id)table.insert(f.Sent,{Action=action,Id=id})end,ManualTick=true,StudioRestricted=studio==true,Price=function()return 1,"Fixture"end,
   Available=function()
    local q={Gate=event(),Thread=coroutine.running(),Started=f.Mono};table.insert(f.Queries,q);table.insert(f.Threads,q.Thread)
    q.Gate.Event:Wait();if q.Result=="Error" then error("synthetic availability failure")end;return q.Result
   end}
  if ignoreCancel then d.Cancel=function()end end
  f.Api=client.Mount(main,d);f.Client=client;f.Dependencies=d;settle();f.Gui=f.Api.Gui
  function f.Reply(index,result)local q=assert(f.Queries[index],"missing query "..index);q.Result=result;q.Gate:Fire();settle()end
  function f.Advance(delta)f.Mono+=delta;f.Now+=delta;f.Api.Tick();settle()end
  function f.Cleanup()
   f.Api.Destroy();folder:Destroy()
   for _,t in f.Threads do if coroutine.status(t)~="dead" then pcall(task.cancel,t)end end
   for _,e in f.Events do e:Destroy()end
  end
  table.insert(fixtures,f);return f
 end

 local ok,result=pcall(function()
  local function available(f,n)f.Reply(n,{AdAvailabilityResult=Enum.AdAvailabilityResult.IsAvailable})end
  local function unavailable(f,n)f.Reply(n,{AdAvailabilityResult=Enum.AdAvailabilityResult.NoFill})end
  local function state(f,title,enabled)
   eq(f.Gui.Entry.Visible,true,"entry stays visible")
   eq(f.Gui.Overlay.Panel.Watch.Title.Text,title,"watch label")
   eq(f.Gui.Overlay.Panel.Watch.Active,enabled,"watch enabled")
   eq(f.Gui.Overlay.Panel.Watch.AutoButtonColor,enabled,"button feedback")
  end
  -- Reproduce both original defects with the actual preserved client.
  local before=fixture(s.BeforeClient);before.Reply(1,false)
  eq(before.Gui.Entry.Visible,false);eq(before.Api.Open(),false);before.Cleanup()
  before=fixture(s.BeforeClient);before.Reply(1,true);eq(before.Api.Open(),true)
  before.Advance(60);eq(before.Gui.Entry.Visible,false);eq(before.Gui.Overlay.Panel.Watch.Active,false)
  eq(before.Gui.Overlay.Panel.Watch.Title.Text,"WATCH AD");eq(#before.Queries,1);before.Cleanup()
  cases.Before={Unavailable="entry/open blocked",Expiry="entry hidden and stale WATCH AD disabled without refresh"}

  local f=fixture(s.Client,false,true)
  state(f,"Unavailable",false);eq(#f.Queries,0,"Studio does not fake API eligibility")
  eq(f.Api.Open(),true);eq(f.Gui.Overlay.Visible,true);state(f,"Unavailable",false)
  eq(f.Api.Watch(),false);eq(#f.Sent,0)
  local row=f.Api.GetAvailabilityDiagnostics()[1]
  eq(row.Result,"StudioRestricted");eq(row.APIInvoked,false);eq(row.APIResult,nil);eq(row.RawResult,nil)
  eq(row.StudioRestricted,true);eq(row.UIState,"Unavailable")
  f.Advance(600);eq(#f.Queries,0);state(f,"Unavailable",false)
  f.Api.Close();eq(f.Gui.Overlay.Visible,false);eq(f.Gui.Entry.Visible,true);f.Cleanup()
  cases.Studio=true

  f=fixture(s.Client);state(f,"Checking…",false);eq(f.Api.Open(),true);eq(#f.Queries,1)
  available(f,1);state(f,"WATCH AD",true)
  local button=f.Gui.Overlay.Panel.Watch;local size,pos=button.Size,button.Position
  local arm=f.Gui.Overlay.Panel.Arm.ImageColor3
  f.Advance(59.99);eq(#f.Queries,1);state(f,"WATCH AD",true)
  f.Advance(.02);eq(#f.Queries,2,"one visible expiry refresh");state(f,"Checking…",false)
  for _=1,10 do f.Api.Tick();f.Api.Open();f.Api.Watch()end
  eq(#f.Queries,2);eq(#f.Sent,0);unavailable(f,2);state(f,"Unavailable",false)
  eq(button.Size,size);eq(button.Position,pos);eq(f.Gui.Overlay.Panel.Arm.ImageColor3,arm)
  eq(button.BackgroundColor3,Color3.fromRGB(117,120,125));eq(button.Outline.Color,Color3.new())
  eq(button.Title.TextColor3,Color3.new(1,1,1));eq(f.Gui.Overlay.Panel.Close.BackgroundColor3,Color3.fromRGB(230,45,37))
  local diagnostic=f.Api.GetAvailabilityDiagnostics()[2]
  eq(diagnostic.RawResult.AdAvailabilityResult,Enum.AdAvailabilityResult.NoFill)
  eq(diagnostic.APIResult,tostring(Enum.AdAvailabilityResult.NoFill));eq(diagnostic.CallSucceeded,true)
  eq(diagnostic.Reason,"VisibleCacheExpired");eq(diagnostic.UIState,"Unavailable")
  diagnostic.RawResult.AdAvailabilityResult="changed copy"
  eq(f.Api.GetAvailabilityDiagnostics()[2].RawResult.AdAvailabilityResult,Enum.AdAvailabilityResult.NoFill)
  f.Advance(4.9);eq(#f.Queries,2);f.Advance(.2);eq(#f.Queries,3);state(f,"Checking…",false)
  available(f,3);state(f,"WATCH AD",true);eq(#f.Sent,0)
  f.Api.Close();f.Advance(600);eq(#f.Queries,3,"closed modal never periodically queries")
  eq(f.Gui.Entry.Visible,true);eq(f.Api.Open(),true);eq(#f.Queries,4);available(f,4)
  f.Api.Close();eq(f.Api.Open(),true);eq(#f.Queries,4,"fresh cache reused");f.Cleanup();cases.CacheAndVisibleRecovery=true

  for _,failure in {false,"Error"}do
   f=fixture(s.Client);f.Api.Open();f.Reply(1,failure);state(f,"Unavailable",false)
   for _=1,5 do f.Api.Close();f.Api.Open()end;eq(#f.Queries,1,"negative/error result retry spacing")
   if failure=="Error" then local d=f.Api.GetAvailabilityDiagnostics()[1];eq(d.Result,"Error");eq(d.CallSucceeded,false);eq(d.APIResult,nil);eq(type(d.Error),"string")end
   f.Advance(5);eq(#f.Queries,2);available(f,2);state(f,"WATCH AD",true);eq(#f.Sent,0);f.Cleanup()
  end;cases.FailureRetry=true

  f=fixture(s.Client,true);f.Api.Open();f.Advance(15);state(f,"Unavailable",false)
  row=f.Api.GetAvailabilityDiagnostics()[1];eq(row.Result,"Timeout");eq(row.TimedOut,true);eq(row.CallSucceeded,nil);eq(row.APIResult,nil);eq(row.Seconds,15)
  f.Advance(5);eq(#f.Queries,2);unavailable(f,2);available(f,1)
  state(f,"Unavailable",false);eq(#f.Sent,0)
  row=f.Api.GetAvailabilityDiagnostics()[3];eq(row.Result,"StaleResponse");eq(row.Ignored,true);eq(row.TimedOut,true)
  f.Advance(5);available(f,3);state(f,"WATCH AD",true);f.Cleanup();cases.TimeoutAndLate=true

  for _,name in {"OfflineRewards","Menu","ShopPanel","InventoryPanel","MergePanel"}do
   for _,late in {false,true}do
    f=fixture(s.Client);f.Api.Open();f.Toggle(name,true);eq(f.Gui.Overlay.Visible,false);eq(f.Gui.Entry.Visible,false)
    if late then f.Toggle(name,false);available(f,1)else available(f,1);f.Toggle(name,false)end
    eq(f.Gui.Entry.Visible,true);eq(f.Gui.Overlay.Visible,false);eq(#f.Sent,0);eq(#f.Queries,1)
    eq(f.Api.Open(),true);state(f,"WATCH AD",true);f.Cleanup()
   end
  end;cases.NaturalOverlayRecovery=true

  f=fixture(s.Client);available(f,1);f.Api.Open()
  eq(f.Api.Watch(),true);eq(f.Api.Watch(),false);eq(#f.Queries,2)
  f.Api.Close();f.Api.Open();available(f,2);eq(#f.Sent,0,"closed intent is not revived by reopen")
  f.Advance(3);eq(f.Api.Watch(),true);available(f,3);eq(#f.Sent,1);eq(f.Sent[1].Action,"Ad")
  eq(f.Api.Watch(),false);eq(#f.Sent,1);f.Cleanup();cases.ExplicitStartAndClose=true

  f=fixture(s.Client,true);available(f,1);f.Api.Open();f.Api.Watch();f.Api.Close()
  f.Advance(16);available(f,2);eq(#f.Sent,0,"timeout/late response cannot start closed intent");eq(f.Gui.Overlay.Visible,false);f.Cleanup()

  f=fixture(s.Client);unavailable(f,1);f.Player:SetAttribute("StrengthBoostExpiresAt",f.Now+300);settle();f.Api.Tick()
  eq(f.Gui.Entry.Footer.Text,"05:00");eq(f.Api.Open(),true);state(f,"05:00",false)
  f.CharacterAdded:Fire();settle();eq(f.Gui.Entry.Footer.Text,"05:00")
  f.Player:SetAttribute("CurrentWorld",2);settle();eq(#f.Queries,1)
  f.Advance(299);eq(f.Gui.Entry.Footer.Text,"00:01");f.Advance(1)
  eq(f.Gui.Entry.Visible,true);eq(f.Gui.Entry.Footer.Text,"FREE");eq(#f.Queries,2)
  unavailable(f,2);eq(f.Gui.Entry.Visible,true);eq(f.Api.Open(),true);state(f,"Unavailable",false)
  f.Cleanup();cases.ActiveTimerAndExpiry=true

  f=fixture(s.Client,true);local first=f.Api;eq(f.Client.Mount(f.Main,f.Dependencies),first)
  f.Api.Destroy();f.Api=f.Client.Mount(f.Main,f.Dependencies);settle();f.Gui=f.Api.Gui
  eq(#f.Queries,2);unavailable(f,2);available(f,1);state(f,"Unavailable",false)
  f.Gui:Destroy();settle();f.Toggle("Menu",true);f.Toggle("Menu",false);eq(#f.Queries,2)
  f.Cleanup();cases.DestroyRemount=true
  f=fixture(s.Client);f.Api.Open();f.Advance(15);eq(coroutine.status(f.Queries[1].Thread),"dead")
  f.Main.Enabled=false;settle();eq(f.Gui.Entry.Visible,false);f.Main.Enabled=true;settle();eq(f.Gui.Entry.Visible,true)
  f.Advance(5);f.Toggle("Menu",true);f.Toggle("Menu",false);eq(#f.Queries,2);available(f,2);f.Cleanup()
  for _,reason in {Enum.AdAvailabilityResult.DeviceIneligible,Enum.AdAvailabilityResult.ExperienceIneligible,
   Enum.AdAvailabilityResult.InternalError,Enum.AdAvailabilityResult.NoFill,Enum.AdAvailabilityResult.PlayerIneligible,
   Enum.AdAvailabilityResult.PublisherIneligible}do
   f=fixture(s.Client);f.Api.Open();f.Mono=2.5;f.Reply(1,{AdAvailabilityResult=reason})
   state(f,"Unavailable",false);local d=f.Api.GetAvailabilityDiagnostics()[1]
   eq(d.RawResult.AdAvailabilityResult,reason);eq(d.APIResult,tostring(reason));eq(d.Seconds,2.5);eq(d.CallSucceeded,true)
   eq(#f.Sent,0);f.Cleanup()
  end
  f=fixture(s.Client);f.Api.Open();f.Reply(1,{})
  state(f,"Unavailable",false);eq(f.Api.GetAvailabilityDiagnostics()[1].APIResult,nil,"unknown reason is not invented")
  for i=2,10 do f.Advance(5);eq(#f.Queries,i);unavailable(f,i)end
  eq(#f.Api.GetAvailabilityDiagnostics(),8,"bounded memory diagnostics")
  f.Main:SetAttribute("StrengthBoostDiagnostics",false);f.Advance(5);unavailable(f,11)
  eq(#f.Api.GetAvailabilityDiagnostics(),8);f.Cleanup();cases.RawAPIResultsAndDiagnostics=true
  return {Assertions=checks,Cases=cases,Mode="Edit native unparented GUI + actual production controller; mocked API/menu/time; no real ads or purchases",RealAPITiming="Unmeasured"}
 end)
 for _,f in fixtures do pcall(f.Cleanup)end
 assert(ok,result);return result
end
