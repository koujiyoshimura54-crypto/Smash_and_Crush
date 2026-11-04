-- Temporary native multiplayer test; install only after redirecting every persistence/payment dependency.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Tap=require(S.AutoTapService)
local Clock=require(S.PlayerActionTiming)
local Strength=require(S.StrengthManager)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Training=require(S.TrainingManager)
local Place=require(S.LobbySpawnService)
local report={Belt={},Cases={},Timings={},Trace={},Inputs={},Checks={},Mode=script:GetAttribute("Native") and "Two native clients; original input LocalScript; memory only" or "One native solo client; original input LocalScript; memory only"}
local events,inputs,lastDelta={},{},{}
report.Reservations={}
report.ServerTimeOffset=workspace:GetServerTimeNow()-os.clock()
local request=Instance.new("RemoteEvent");request.Name="__TapQARequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__TapQAReply";reply.Parent=RS
local answers={}
reply.OnServerEvent:Connect(function(p,id,v)answers[id]={P=p,V=v}end)
local function waitFor(fn,t)
 local deadline=os.clock()+(t or 8)
 repeat local v=fn();if v then return v end task.wait(.005) until os.clock()>deadline
 error("QA timeout")
end
local function ask(p,action,value)
 local id=game.HttpService:GenerateGUID(false);request:FireClient(p,id,action,value)
 local a=waitFor(function()return answers[id]end,20);assert(a.P==p and a.V.OK,tostring(a.V.Value));return a.V.Value
end
local function check(ok,label)report.Checks[#report.Checks+1]={Passed=not not ok,Label=label};assert(ok,label)end
local function run(label,fn)
 if script:GetAttribute("Only")=="Remaining" then
  if label~="defeat and new battle generation" and label~="World travel and Treadmill independent timers" then return end
 elseif script:GetAttribute("Only") and not label:find(script:GetAttribute("Only"),1,true) then return end
 local ok,e=xpcall(fn,debug.traceback);report.Cases[#report.Cases+1]={Label=label,Passed=ok,Error=not ok and e or nil}
 print("__TapQA",label,ok,not ok and e or "")
end
local originalGain=Strength.AddStrength
Strength.AddStrength=function(p,...)
 local before=p:GetAttribute("Strength");local a,b=originalGain(p,...)
 lastDelta[p]={Kind="Training",Delta=p:GetAttribute("Strength")-before,Value=p:GetAttribute("Strength")}
 return a,b
end
for _,w in {1,2} do
 local B=require(game.ServerScriptService.World.BossCombatService).ForWorld(w)
 local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(w)
 local attack=B.Attack;B.Attack=function(p)
  local s=B.Get(p);local before=s and s.HP;local a,b=attack(p)
  if before and b then lastDelta[p]={Kind="Boss",Delta=before-b.HP,Value=b.HP} end
  return a,b
 end
 local apply=W.ApplyDamageForStage;W.ApplyDamageForStage=function(p,n,amount)
  local i=W.GetCurrentIndexForStage(p,n);local before=W.GetGaugeForStage(p,n,i)
  local a,b=apply(p,n,amount)
  lastDelta[p]={Kind="Wall",Delta=b>i and before or before-W.GetGaugeForStage(p,n,i),Value=b>i and 0 or W.GetGaugeForStage(p,n,i)}
  return a,b
 end
end
local schedule=Clock.ScheduleAutomatic
Clock.ScheduleAutomatic=function(p,lead,perform,finish)
 local before=Clock.__QASnapshot(p)
 local accepted,delay=schedule(p,lead,function()
  report.Reservations[#report.Reservations+1]={Type="Perform",Player=p.UserId,Time=os.clock(),Clock=Clock.__QASnapshot(p)}
  return perform()
 end,function()
  report.Reservations[#report.Reservations+1]={Type="FinishOrCancel",Player=p.UserId,Time=os.clock(),Clock=Clock.__QASnapshot(p)}
  if finish then finish() end
 end)
 if accepted then report.Reservations[#report.Reservations+1]={Type="Schedule",Player=p.UserId,Time=os.clock(),Delay=delay,Before=before,Clock=Clock.__QASnapshot(p)} end
 return accepted,delay
end
local originalRecord=Clock.RecordSuccess
Clock.RecordSuccess=function(p,manual)
 originalRecord(p,manual)
 local row=lastDelta[p] or {};row=table.clone(row)
 row.Time=os.clock();row.ServerTime=workspace:GetServerTimeNow();row.Manual=manual;row.World=p:GetAttribute("CurrentWorld");row.Clock=Clock.__QASnapshot(p)
 events[p]=events[p] or {};table.insert(events[p],row)
end
local originalTap=Tap.HandleTap
Tap.HandleTap=function(p)
 local now=os.clock();local before=Clock.__QASnapshot(p);local a,b=originalTap(p)
 local row={Time=now,Auto=p:GetAttribute("AutoTapEnabled"),Accepted=a,Reason=b,Before=before,After=Clock.__QASnapshot(p)}
 inputs[p]=inputs[p] or {};table.insert(inputs[p],row)
 return a,b
end
local function root(p)return p.Character.HumanoidRootPart end
local function hum(p)return p.Character.Humanoid end
local function put(p,pos)
 local r=root(p);r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.CFrame=CFrame.new(pos);task.wait(.12)
end
local function services(w)return Enemy.ForWorld(w),require(game.ServerScriptService.World.BossCombatService).ForWorld(w),require(game.ServerScriptService.World.Stage1WallManager).ForWorld(w)end
local function lobby(p,w)
 D.SetAutoTapEnabled(p,false);Enemy.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
 p:SetAttribute("CurrentWorld",w);Enemy.ForWorld(w).Activate(p)
 local f=workspace[w==1 and "GeneratedMap" or "World2Map"].TrainingArea.Floor
 put(p,f.Position+Vector3.new(0,f.Size.Y/2+hum(p).HipHeight+root(p).Size.Y/2,0))
 waitFor(function()return not p:GetAttribute("IsTraining")end)
end
local function prepare(p,w,kind)
 lobby(p,w)
 local E,B,W=services(w)
 if kind=="Training" then return end
 D.SetCurrentStrength(p,kind=="Boss" and B.GetStageConfig(1).MaxHP/1000 or 1)
 E.StartRun(p,1)
 if kind=="Wall" then
  local wall=waitFor(function()return W.GetCurrentWallForStage(p,1)end)
  put(p,wall.Wall.Position+Vector3.new(0,0,3))
  waitFor(function()return E.__QAWallContact(p,wall)end)
 else
  W.ApplyDamageForStage(p,1,1e30)
  local e=waitFor(function()return E.GetEnemy(1,p)end)
  if w==2 then require(game.ServerScriptService.World.BossChaseService).ForWorld(w).BeginIntro(e) end
  local f=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor.Stage01.Floor
  local y=f.Position.Y+f.Size.Y/2+hum(p).HipHeight+root(p).Size.Y/2
  put(p,Vector3.new(e.CombatZone.Position.X,y,e.CombatZone.Position.Z))
  waitFor(function()return E.__QAContact(p.Character,e) and B.Get(p)end)
 end
 hum(p).MaxHealth=1e12;hum(p).Health=1e12
 task.wait(.25)
end
local function count(p)return #(events[p] or {})end
local function last(p)return (events[p] or {})[count(p)]end
local function untilTime(t)if t>os.clock() then task.wait(t-os.clock())end end
local function tap(p,kind)
 local n=count(p);local result=ask(p,"Tap")
 local r=waitFor(function()return count(p)>n and events[p][n+1]end,3)
 check(r.Manual and r.Kind==kind and r.Delta>0,"native manual "..kind.." "..game.HttpService:JSONEncode(r))
 return r,result
end
local function autoAfter(p,n,kind)
 return waitFor(function()
  for i=n+1,count(p) do local r=events[p][i];if not r.Manual and r.Kind==kind then return r end end
 end,3)
end
local function approx(v,target,label)
 check(v>=target-.002 and v<=target+.2,label.." "..string.format("%.4f",v))
end

local function toggle(p,on)
 if p:GetAttribute("AutoTapEnabled")==on then return end
 ask(p,"Toggle");waitFor(function()return p:GetAttribute("AutoTapEnabled")==on end)
 task.wait(.17)
end
local function flow(p,w,kind,peer)
 prepare(p,w,kind)
 local begin=count(p)
 toggle(p,true)
 local a=autoAfter(p,count(p),kind)
 local b=autoAfter(p,count(p),kind)
 approx(b.Time-a.Time,.5,"fresh auto "..kind)
 for _=1,4 do toggle(p,false);toggle(p,true) end
 local c=autoAfter(p,count(p),kind)
 untilTime(c.Time+.215)
 ask(p,"Burst")
 ask(p,"RawSpam")
 local lastManual=last(p)
 check(lastManual.Manual,"last burst input succeeded")
 local mark=count(p)
 local r=autoAfter(p,mark,kind)
 task.wait(2.15)
 local rows={}
 for i=begin+1,count(p) do
  local row=table.clone(events[p][i]);row.Player=p.UserId;rows[#rows+1]=row
 end
 local post={}
 for i=2,#rows do
  check(rows[i].Time-rows[i-1].Time>=.1985,"common floor")
  if rows[i-1].Time>=r.Time and not rows[i].Manual then
   local gap=rows[i].Time-rows[i-1].Time
   approx(gap,.5,"post-burst auto")
   post[#post+1]=gap
  end
 end
 approx(r.Time-lastManual.Time,.3,"first auto after manual")
 toggle(p,false);local n=count(p);task.wait(.55);check(count(p)==n,"OFF no old hit")
 report.Timings[#report.Timings+1]={World=w,Kind=kind,Fresh=b.Time-a.Time,Resume=r.Time-lastManual.Time,Post=post}
 for _,row in rows do report.Trace[#report.Trace+1]=row end
 for _,input in inputs[p] or {} do if not input.Accepted then check(input.Before.Last==input.After.Last and input.Before.NextAuto==input.After.NextAuto,"rejection preserves clock") end end
 report.Inputs[#report.Inputs+1]={World=w,Kind=kind,Rows=inputs[p]}
 inputs[p]={}
end
local Item=require(S.ItemService)
local function beltState(p)
 local d=D.Get(p)
 return {Loaded=d and d.Loaded==true,EquipmentGeneration=p:GetAttribute("ForgeSessionToken"),
 OwnedItems=Item.GetOwnedItems(p) or {},EquippedItems=Item.GetEquippedItems(p) or {}}
end
local function beltSample(p,label)
 local state=beltState(p)
 local hud=ask(p,"HUD")
 local r={Label=label,Player=p.UserId,State=state,HUD=hud,Effective=Item.GetBeltTreadmillBonus(p)}
 report.Belt[#report.Belt+1]=r
 return r
end
local function equip(p,id,action)
 ask(p,"Equip",{Id=id,Action=action or "Equip"})
 task.wait(.3)
end
local ended=false
local function finish()
 if ended then return end;ended=true
 report.Passed=true
 for _,v in report.Cases do if not v.Passed then report.Passed=false end end
 for _,v in report.Checks do if not v.Passed then report.Passed=false end end
 _G.AutoBeltResult=report
 local output=Instance.new("StringValue");output.Name="__AutoBeltResult";output.Value=game.HttpService:JSONEncode(report);output.Parent=RS
 if not script:GetAttribute("Native") then
  local visual=Instance.new("BindableFunction");visual.Name="__AutoBeltVisual";visual.Parent=game.ServerStorage
  visual.OnInvoke=function(action)
   local p=game.Players:GetPlayers()[1]
   if action=="Equip" then
    assert(Item.AddItem(p,"TRAININGBELT_COMMON_FIRE",1));equip(p,"TRAININGBELT_COMMON_FIRE")
   elseif action=="Reset" then assert(D.Reset(p));D.SetAutoTapEnabled(p,false);task.wait(.4)
   end
   return beltSample(p,action)
  end
 end
 if game:GetService("RunService"):IsStudio() and script:GetAttribute("Native") then
  game:GetService("StudioTestService"):EndTest(report)
 end
end
task.delay(170,function()report.Cases[#report.Cases+1]={Label="watchdog",Passed=false};finish()end)
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()>=(script:GetAttribute("Native") and 2 or 1)end,40)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local p,peer=players[1],players[2]
 for _,x in players do
  waitFor(function()return D.Get(x) and D.Get(x).Loaded and x.Character and x.Character:GetAttribute("SpawnEngineReady") and x.Character:GetAttribute("MuscleScaleReady")end,40)
  if D.Get(x).StudioStartOverride then D.RestoreStudioStartOverride(x) end
  D.SetAutoTapEnabled(x,false);ask(x,"Ready")
  local d=D.Get(x).Data;d.SelectedSizeTier=1;x:SetAttribute("SelectedSizeTier",1)
  D.UnlockWorld(x,2);D.MarkWorld2Reached(x)
 end
 if script:GetAttribute("Only")~="Belt" then
  local peerMark=0
  if peer then prepare(peer,2,"Wall");peerMark=count(peer);toggle(peer,true) end
  for _,w in {1,2} do for _,kind in {"Wall","Boss"} do
   run("World"..w.." "..kind,function()flow(p,w,kind,peer)end)
  end end
  if peer then
   toggle(peer,false)
   local rows={}
   for i=peerMark+1,count(peer) do rows[#rows+1]=events[peer][i] end
   for i=2,#rows do approx(rows[i].Time-rows[i-1].Time,.5,"other player's independent auto") end
   report.PeerTimers=rows
   lobby(peer,1)
  end
 end
 run("Belt ownership/reset/generation",function()
  lobby(p,1)
  local id="TRAININGBELT_COMMON_FIRE"
  local other="TRAININGBELT_RARE_ICE"
  check(not beltSample(p,"fresh").HUD.Visible,"fresh hidden")
  assert(Item.AddItem(p,id,1))
  -- Existing state Remote, no direct HUD mutation.
  RS.Remotes.ItemEquipRequest:FireClient(p,{State=beltState(p)})
  task.wait(.2)
  check(not beltSample(p,"owned only").HUD.Visible,"owned unequipped hidden")
  equip(p,id);local old=beltSample(p,"equipped")
  check(old.HUD.Visible and old.Effective>0,"valid owned equipped Belt")
  assert(Item.AddItem(p,other,1));equip(p,other)
  local changed=beltSample(p,"equipment changed");check(changed.Effective>old.Effective,"normal equip updates effect")
  if peer then check(not beltSample(peer,"peer before reset").HUD.Visible,"peer unaffected") end
  local oldState=changed.State
  assert(D.Reset(p));D.SetAutoTapEnabled(p,false);task.wait(.4)
  local reset=beltSample(p,"reset before BestEquip")
  check(reset.Effective==0 and next(reset.State.OwnedItems)==nil,"reset server has no Belt effect")
  -- Simulated delayed old-session reply through the same production Remote.
  RS.Remotes.ItemEquipRequest:FireClient(p,{State=oldState});task.wait(.2)
  local stale=beltSample(p,"delayed old-generation reply")
  equip(p,nil,"BestEquip")
  local best=beltSample(p,"BestEquip after reset")
  check(best.Effective==0 and not best.HUD.Visible,"BestEquip reflects empty server state")
  if script:GetAttribute("Fixed") then
   check(not reset.HUD.Visible and reset.HUD.Image=="" and reset.HUD.Text=="","reset clears immediately")
   check(not stale.HUD.Visible and stale.HUD.Image=="","old generation rejected")
  else
   check(reset.HUD.Visible and stale.HUD.Visible,"baseline stale HUD reproduced")
  end
  if script:GetAttribute("Fixed") then
   -- Deliberately hold a real state response across a normal isolated reset.
   assert(Item.AddItem(p,id,1));equip(p,id)
   local rf=RS.Remotes.ItemInventoryState
   local held=false
   _G.AutoBeltStateResponseObserver=function(who,state)
    if who==p and not held then held=true;task.wait(.55) end
   end
   RS.Remotes.ItemMergeRequest:FireClient(p,{State={}})
   waitFor(function()return held end)
   assert(D.Reset(p));D.SetAutoTapEnabled(p,false)
   task.wait(1.3);_G.AutoBeltStateResponseObserver=nil
   local delayed=beltSample(p,"in-flight snapshot crossed reset")
   check(not delayed.HUD.Visible and delayed.HUD.Text=="" and delayed.Effective==0,"in-flight snapshot fenced")
   assert(Item.AddItem(p,id,1));equip(p,id)
   D.Get(p).Loaded=false
   RS.Remotes.ItemEquipRequest:FireClient(p,{State=beltState(p)})
   task.wait(.2)
   local loading=beltSample(p,"data temporarily unavailable")
   check(not loading.HUD.Visible and loading.Effective==0,"loading clears display and has no effect")
   D.Get(p).Loaded=true;task.wait(1.25)
   local reloaded=beltSample(p,"loaded again")
   check(reloaded.HUD.Visible and reloaded.Effective>0,"loaded state automatically returns")
   equip(p,"TrainingBelt","Unequip")
   -- Generation-less legacy merge reply must request current server state.
   RS.Remotes.ItemMergeRequest:FireClient(p,{State={Loaded=true,OwnedItems=oldState.OwnedItems,EquippedItems=oldState.EquippedItems}})
   task.wait(.4)
   check(not beltSample(p,"legacy merge snapshot").HUD.Visible,"legacy snapshot cannot resurrect equipment")
  end
  assert(Item.AddItem(p,id,1));equip(p,id)
  local preDeath=beltSample(p,"equipped before death")
  local oldChar=p.Character;hum(p).Health=0
  waitFor(function()return p.Character and p.Character~=oldChar and p.Character:GetAttribute("SpawnEngineReady") and p.Character:GetAttribute("MuscleScaleReady")end,20)
  task.wait(.5);D.SetAutoTapEnabled(p,false)
  local afterDeath=beltSample(p,"equipped after respawn")
  check(afterDeath.HUD.Visible and afterDeath.Effective==preDeath.Effective,"respawn retains valid equipment")
  equip(p,"TrainingBelt","Unequip")
  local unequipped=beltSample(p,"unequipped")
  check(not unequipped.HUD.Visible and unequipped.Effective==0,"normal unequip hides effect")
  if peer then check(not beltSample(peer,"peer final").HUD.Visible,"peer HUD remains independent") end
 end)
 for _,x in players do
  report.Inputs[#report.Inputs+1]={Player=x.UserId,Client=ask(x,"Trace")}
 end
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="setup",Passed=false,Error=err} end
finish()
