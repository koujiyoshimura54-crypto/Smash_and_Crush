return function(s)
 local checks=0;local cases={};local fixtures={}
 local function eq(a,b,label)checks+=1;assert(a==b,(label or "check")..": "..tostring(a).." ~= "..tostring(b))end
 local function settle()task.wait(.02)end
 local function fixture(source,ignoreCancel)
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
   Send=function(action,id)table.insert(f.Sent,{Action=action,Id=id})end,ManualTick=true,Price=function()return 1,"Fixture"end,
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
  for _,name in {"OfflineRewards","Menu","ShopPanel","InventoryPanel","MergePanel"}do
   local before=fixture(s.BeforeClient);before.Toggle(name,true);before.Reply(1,true);before.Toggle(name,false)
   eq(before.Gui.Entry.Visible,false,"before reproduces dropped result: "..name);before.Cleanup()
   for _,late in {false,true}do
    local f=fixture(s.Client);f.Toggle(name,true)
    if late then f.Toggle(name,false);f.Reply(1,true)else f.Reply(1,true);f.Toggle(name,false)end
    eq(f.Gui.Entry.Visible,true,name.." natural recovery; responseAfterClose="..tostring(late))
    eq(f.Gui.Entry.Footer.Text,"FREE");eq(f.Gui.Overlay.Visible,false);eq(#f.Sent,0);eq(#f.Queries,1,"single shared availability request")
    f.Cleanup()
   end
   cases[name]={Before="FREE remains hidden",After="FREE restored by actual Visible/MenuClosed events in both response orders"}
  end
  for _,failure in {false,"Error"}do
   local f=fixture(s.Client);f.Reply(1,failure);eq(f.Gui.Entry.Visible,true,"unavailable still offers explanation")
   f.Advance(1);f.Toggle("Menu",true);f.Toggle("Menu",false);eq(#f.Queries,1,"retry cooldown")
   f.Advance(5);eq(#f.Queries,2,"deferred natural retry");f.Reply(2,true);eq(f.Gui.Entry.Visible,true)
   local diagnostic=f.Api.GetAvailabilityDiagnostics();eq(diagnostic[2].Reason,"MenuClosed");eq(diagnostic[2].Result,"Available")
   f.Cleanup()
  end
  local f=fixture(s.Client,true);f.Advance(16);eq(f.Gui.Entry.Visible,true)
  eq(f.Api.GetAvailabilityDiagnostics()[1].Result,"Timeout")
  f.Toggle("OfflineRewards",true);f.Toggle("OfflineRewards",false);f.Advance(5);eq(#f.Queries,2)
  f.Reply(2,false);f.Reply(1,true);eq(f.Gui.Entry.Visible,true);eq(f.Gui.Overlay.Panel.Watch.Active,false,"old success cannot overwrite newer no-fill")
  f.Advance(6);f.Toggle("InventoryPanel",true);f.Toggle("InventoryPanel",false);eq(#f.Queries,3)
  f.Reply(3,true);eq(f.Gui.Entry.Visible,true,"recovers after response exceeded 15-second simulated deadline")
  f.Cleanup();cases.TimeoutAndStaleReply=true
  f=fixture(s.Client)
  for _=1,8 do f.Toggle("Menu",true);f.Toggle("Menu",false)end
  eq(#f.Queries,1);f.Reply(1,true);eq(f.Gui.Entry.Visible,true)
  eq(f.Api.Open(),true);settle();eq(#f.Queries,1,"fresh cache reused on open")
  eq(f.Api.Watch(),true);eq(f.Api.Watch(),false);settle();eq(#f.Queries,2,"watch always revalidates")
  f.Toggle("ShopPanel",true);f.Reply(2,true);f.Toggle("ShopPanel",false)
  eq(#f.Sent,0,"closed watch intent cannot start an ad");eq(f.Gui.Overlay.Visible,false);eq(f.Gui.Entry.Visible,true)
  f.Advance(4);eq(f.Api.Open(),true);eq(f.Api.Watch(),true);settle();f.Reply(3,true)
  eq(#f.Sent,1);eq(f.Sent[1].Action,"Ad");f.Cleanup();cases.WatchIntentAndRapidUI=true
  f=fixture(s.Client);f.Reply(1,false)
  f.Advance(500);for _=1,20 do f.Api.Tick()end;eq(#f.Queries,1,"no unconditional availability polling")
  f.Player:SetAttribute("StrengthBoostExpiresAt",f.Now+300);settle();f.Api.Tick()
  eq(f.Gui.Entry.Visible,true);eq(f.Gui.Entry.Footer.Text,"05:00","active timer independent of no-fill")
  f.CharacterAdded:Fire();settle();eq(f.Gui.Entry.Footer.Text,"05:00","death/respawn callback preserves active timer")
  f.Player:SetAttribute("CurrentWorld",2);settle();eq(#f.Queries,1,"no redundant check during boost")
  f.Advance(299);eq(f.Gui.Entry.Footer.Text,"00:01");f.Advance(1);eq(#f.Queries,2,"expiry natural recheck")
  f.Reply(2,true);eq(f.Gui.Entry.Footer.Text,"FREE")
  f.Advance(61);eq(f.Gui.Entry.Visible,true,"eligibility cache expiry does not hide entry")
  f.Toggle("MergePanel",true);f.Toggle("MergePanel",false);eq(#f.Queries,3);f.Reply(3,true);eq(f.Gui.Entry.Visible,true)
  f.Cleanup();cases.TimerAndCache=true
  f=fixture(s.Client,true);local old=f.Api;eq(f.Client.Mount(f.Main,f.Dependencies),old)
  old.Destroy();eq(f.Root:FindFirstChild("RewardedStrengthBoostGui"),nil)
  f.Api=f.Client.Mount(f.Main,f.Dependencies);settle();f.Gui=f.Api.Gui;eq(#f.Queries,2);f.Reply(2,true)
  f.Reply(1,false);eq(f.Gui.Entry.Visible,true,"destroyed generation reply cannot modify replacement GUI")
  f.Toggle("Menu",true);f.Toggle("Menu",false);eq(#f.Queries,2,"no old event handler")
  f.Gui:Destroy();settle();eq(f.Root:FindFirstChild("RewardedStrengthBoostGui"),nil)
  f.Toggle("Menu",true);f.Toggle("Menu",false);eq(#f.Queries,2,"external GUI destruction cleans callbacks")
  f.Cleanup();cases.DestructionAndRemount=true
  f=fixture(s.Client);f.Advance(16);eq(coroutine.status(f.Queries[1].Thread),"dead","timed-out worker cancelled")
  f.Toggle("Menu",true);f.Toggle("Menu",false);f.Advance(5);f.Reply(2,true)
  f.Main.Enabled=false;settle();eq(f.Gui.Entry.Visible,false);f.Main.Enabled=true;settle();eq(f.Gui.Entry.Visible,true)
  f.Player:SetAttribute("CurrentWorld",2);settle();eq(#f.Queries,2,"World travel reuses fresh result")
  f.Advance(61);f.Player:SetAttribute("CurrentWorld",1);settle();eq(#f.Queries,3);f.Reply(3,true)
  f.Cleanup();cases.WorldAndTimeoutCancellation=true
  return {Assertions=checks,Cases=cases,Mode="Edit / actual unparented GUI property events, mocked menu signals and delayed availability; no real AdService",RealAPIAverageSeconds="Unmeasured"}
 end)
 for _,f in fixtures do pcall(f.Cleanup)end
 assert(ok,result);return result
end
