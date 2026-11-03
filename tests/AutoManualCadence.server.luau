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
local report={Cases={},Timings={},Trace={},Inputs={},Checks={},Mode="Two native clients; instrumented original input LocalScript; memory only"}
local events,inputs,lastDelta={},{},{}
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
local originalRecord=Clock.RecordSuccess
Clock.RecordSuccess=function(p,manual)
 originalRecord(p,manual)
 local row=lastDelta[p] or {};row=table.clone(row)
 row.Time=os.clock();row.Manual=manual;row.World=p:GetAttribute("CurrentWorld");row.Clock=Clock.__QASnapshot(p)
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
 check(v>=target-.002 and v<=target+.14,label.." "..string.format("%.4f",v))
end
local function flow(p,w,kind)
 prepare(p,w,kind)
 local first=count(p)
 untilTime((last(p) and last(p).Time or 0)+.22)
 tap(p,kind);task.wait(.215);tap(p,kind)
 D.SetAutoTapEnabled(p,true)
 local mark=count(p);local a=autoAfter(p,mark,kind);local ai=count(p);local b=autoAfter(p,ai,kind)
 approx(b.Time-a.Time,.5,kind.." auto only")
 untilTime(b.Time+.22)
 local m=tap(p,kind)
 approx(m.Clock.NextAuto-m.Clock.Last,.3,"manual next due")
 local markAfter=count(p);ask(p,"RawSpam");ask(p,"Invalid")
 local c=autoAfter(p,markAfter,kind);local ci=count(p);local d=autoAfter(p,ci,kind)
 approx(c.Time-m.Time,.3,kind.." resume after manual")
 approx(d.Time-c.Time,.5,kind.." subsequent auto")
 untilTime(d.Time+.22)
 local burstStart=count(p);ask(p,"Burst")
 local burstManual=0;for i=burstStart+1,count(p) do if events[p][i].Manual then burstManual+=1 end end
 check(burstManual==4,"all four native burst inputs accepted")
 local burstLast=last(p);check(burstLast.Manual,"burst keeps auto deferred")
 local k=count(p);local resumed=autoAfter(p,k,kind)
 approx(resumed.Time-burstLast.Time,.3,kind.." burst resume")
 D.SetAutoTapEnabled(p,false);local stopped=count(p);task.wait(.65);check(count(p)==stopped,"Auto OFF cancels reservation")
 tap(p,kind)
 local rows={};for i=first+1,count(p) do rows[#rows+1]=events[p][i] end
 for i=2,#rows do check(rows[i].Time-rows[i-1].Time>=.199,"common .2 floor") end
 for _,r in inputs[p] or {} do if not r.Accepted then check(r.Before.Last==r.After.Last and r.Before.NextAuto==r.After.NextAuto,"rejected input leaves clock") end end
 report.Timings[#report.Timings+1]={World=w,Kind=kind,Auto=b.Time-a.Time,AfterManual=c.Time-m.Time,AfterAuto=d.Time-c.Time,AfterBurst=resumed.Time-burstLast.Time,Actions=#rows,ManualBurst=burstManual}
 for i=1,math.min(8,#rows) do report.Trace[#report.Trace+1]=rows[i] end
end
local ended=false
local function finish()
 if ended then return end;ended=true
 report.Passed=true
 for _,v in report.Cases do if not v.Passed then report.Passed=false end end
 for _,v in report.Checks do if not v.Passed then report.Passed=false end end
 game:GetService("StudioTestService"):EndTest(report)
end
task.delay(225,function()report.Cases[#report.Cases+1]={Label="watchdog",Passed=false};finish()end)
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==2 end,40)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local p,peer=players[1],players[2]
 for _,x in players do
  waitFor(function()return D.Get(x) and D.Get(x).Loaded and x.Character and x.Character:GetAttribute("SpawnEngineReady") and x.Character:GetAttribute("MuscleScaleReady")end,40)
  D.SetAutoTapEnabled(x,false);ask(x,"Ready")
  local d=D.Get(x).Data;d.SelectedSizeTier=1;x:SetAttribute("SelectedSizeTier",1)
  D.UnlockWorld(x,2);D.MarkWorld2Reached(x)
 end
 for _,w in {1,2} do
  for _,kind in {"Training","Wall","Boss"} do run("World"..w.." "..kind.." shared cadence",function()flow(p,w,kind)end) end
  run("World"..w.." contact / rejected / stale hit",function()
   prepare(p,w,"Boss");D.SetAutoTapEnabled(p,true)
   local E,B=services(w);local e=E.GetEnemy(1,p)
   waitFor(function()return Clock.__QASnapshot(p).Pending end)
   local hp=B.Get(p).HP
   local f=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor.Stage01.Floor
   local chase=require(game.ServerScriptService.World.BossChaseService).ForWorld(w)
   local best,dist=nil,-1
   for _,x in {-.75,0,.75} do for _,z in {-.75,0,.75} do
    local pos=f.CFrame:PointToWorldSpace(Vector3.new(f.Size.X*x/2,0,f.Size.Z*z/2))
    pos=Vector3.new(pos.X,root(p).Position.Y,pos.Z)
    if chase.ContainsPlayer(e,pos) and (pos-e.CombatZone.Position).Magnitude>dist then best=pos;dist=(pos-e.CombatZone.Position).Magnitude end
   end end
   assert(best,"inside arena sample");put(p,best)
   check(not E.__QAContact(p.Character,e),"contact separated")
   local snap=Clock.__QASnapshot(p);local n=count(p);ask(p,"RawSpam");task.wait(.55)
   check(count(p)==n and B.Get(p) and B.Get(p).HP==hp,"windup miss does not hit/heal/train: "..tostring(count(p)-n).."/"..tostring(B.Get(p) and B.Get(p).HP).."/"..tostring(hp))
   check(Clock.__QASnapshot(p).Last==snap.Last,"invalid contact does not consume action time")
   local z=e.CombatZone.Position;put(p,Vector3.new(z.X,root(p).Position.Y,z.Z))
   autoAfter(p,n,"Boss")
   D.SetAutoTapEnabled(p,false)
   -- A new automatic windup cannot survive death.
   D.SetAutoTapEnabled(p,true);waitFor(function()return Clock.__QASnapshot(p).Pending end)
   local old=p.Character;local actions=count(p);hum(p).Health=0
   task.wait(.6);check(count(p)==actions,"no post-death hit")
   waitFor(function()return p.Character and p.Character~=old and p.Character:GetAttribute("SpawnEngineReady") and p.Character:GetAttribute("MuscleScaleReady")end,20)
   D.SetAutoTapEnabled(p,false);root(p).Anchored=true;task.wait(.25);tap(p,"Training")
   prepare(p,w,"Boss");tap(p,"Boss")
  end)
 end
 run("defeat and new battle generation",function()
  for _,w in {1,2} do
   prepare(p,w,"Boss")
   local E,B=services(w);local bs=B.Get(p)
   -- Isolated fixture setup: leave one normal hit of HP, then use the original input route.
   bs.HP=bs.BattleDamage
   D.SetAutoTapEnabled(p,true);waitFor(function()return Clock.__QASnapshot(p).Pending end)
   untilTime((last(p) and last(p).Time or 0)+.22)
   -- Separate internal-handler test: no client round-trip race against the lethal auto deadline.
   local actions=count(p);local accepted,reason=Tap.HandleTap(p);assert(accepted,reason)
   local hit=events[p][actions+1];check(hit and hit.Manual and hit.Kind=="Boss" and hit.Delta>0,"internal lethal manual commits")
   waitFor(function()return E.GetPlayerState(p).Defeated[1]end)
   local n=count(p);task.wait(.65)
   for i=n+1,count(p) do check(events[p][i].Kind~="Boss","defeated Boss receives no old hit") end
   prepare(p,w,"Boss");tap(p,"Boss")
  end
 end)
 run("two independent real players and UI exclusion",function()
  lobby(p,1);lobby(peer,2);D.SetAutoTapEnabled(peer,true)
  local peerStart=count(peer);local pStart=count(p);local before=#(inputs[p] or {})
  ask(p,"Tap","Processed");ask(p,"Tap","Button");task.wait(.1)
  check(#(inputs[p] or {})==before and count(p)==pStart,"processed/UI button never becomes tap")
  D.SetAutoTapEnabled(p,true);local start=count(p);ask(p,"Burst")
  check(count(p)>=start+4,"first player burst")
  autoAfter(peer,peerStart,"Training");D.SetAutoTapEnabled(peer,false);D.SetAutoTapEnabled(p,false)
  local rows=events[peer];local previous
  for i=peerStart+1,#rows do if previous then approx(rows[i].Time-previous.Time,.5,"peer timer independent")end previous=rows[i]end
 end)
 run("World travel and Treadmill independent timers",function()
  lobby(p,1);D.SetAutoTapEnabled(p,true);local gate=workspace[require(RS.Config.WorldGateConfig).GateName]
  put(p,gate.WorldGateTrigger.Position);ask(p,"Travel",2)
  waitFor(function()return p:GetAttribute("CurrentWorld")==2 end,15);D.SetAutoTapEnabled(p,false);task.wait(.3)
  root(p).Anchored=true;tap(p,"Training")
  for _,w in {1,2} do
   lobby(p,w)
   local area=workspace[w==1 and "GeneratedMap" or "World2Map"].TrainingArea
   local model=w==1 and workspace.Treadmills.Normal01 or area.TreadmillDisplays["01"]
   -- Let the real belt support the avatar; an anchored animated foot is not a stable occupancy fixture.
   put(p,model.Area.Position+Vector3.new(0,hum(p).HipHeight+root(p).Size.Y/2+.1,0))
   root(p).Anchored=false;root(p):SetNetworkOwner(nil)
   task.wait(.7)
   waitFor(function()return p:GetAttribute("IsTraining") and Training.IsPlayerInsideZone(p,model.Area)end)
   D.SetAutoTapEnabled(p,true);local snap=Clock.__QASnapshot(p);local before=p:GetAttribute("Strength");local n=count(p)
   ask(p,"RawSpam");task.wait(1.1)
   check(p:GetAttribute("Strength")>before and count(p)==n,"W"..w.." native treadmill grants outside action clock: gain="..(p:GetAttribute("Strength")-before)..", actions="..(count(p)-n)..", occupied="..tostring(p:GetAttribute("IsTraining")))
   check(Clock.__QASnapshot(p).Last==snap.Last and Clock.__QASnapshot(p).NextAuto==snap.NextAuto,"treadmill/rejection leaves tap clock")
   D.SetAutoTapEnabled(p,false)
  end
 end)
 for _,x in players do
  for _,v in inputs[x] or {} do if #report.Inputs<20 or not v.Accepted then report.Inputs[#report.Inputs+1]=v end end
 end
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="setup",Passed=false,Error=err}end
finish()
