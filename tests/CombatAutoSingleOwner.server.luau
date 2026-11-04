-- Temporary solo Play regression; install only after isolating persistence/payment dependencies.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local Tap=require(S.AutoTapService)
local Clock=require(S.PlayerActionTiming)
local Strength=require(S.StrengthManager)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Training=require(S.TrainingManager)
local Place=require(S.LobbySpawnService)
local report={Cases={},Timings={},Trace={},Inputs={},Checks={},Mode=script:GetAttribute("Native") and "Two native clients; original input LocalScript; memory only" or "One native solo client; original input LocalScript; memory only"}
local events,inputs,lastDelta={},{},{}
report.AttackNotifications={}
local suspended=false
local originalAuto=Tap.TryAutomatic
Tap.TryAutomatic=function(p)if suspended then return false,"QASuspended" end return originalAuto(p) end
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
 if script:GetAttribute("Only")=="Toggle" then
  if not label:find("toggle boundary",1,true) then return end
 elseif script:GetAttribute("Only")=="Corrected" then
  if not label:find("Wall",1,true) and not label:find("walking",1,true) then return end
 elseif script:GetAttribute("Only")=="Remaining" then
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
Clock.RecordSuccess=function(p,manual,combat)
 originalRecord(p,manual,combat)
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
 check(v>=target-.002 and v<=target+.15,label.." "..string.format("%.4f",v))
end

local function toggle(p,on)
 if p:GetAttribute("AutoTapEnabled")==on then return end
 ask(p,"Toggle");waitFor(function()return p:GetAttribute("AutoTapEnabled")==on end)
 task.wait(.17)
end

local function trace(p)return ask(p,"Trace")end
local function lengths(t,w)
 local a,b,c=0,0,0
 for _,x in t.Visuals do if x.World==w then
  if x.Type=="Animation" then a+=1 elseif x.Type=="Sound" then b+=1 end
 end end
 for _,x in t.Events do if x.World==w and x.Type=="CombatAttack" then c+=1 end end
 return a,b,c
end
local function flow(p,w,kind)
 prepare(p,w,kind)
 local E,B,W=services(w)
 local start=count(p)
 local before=trace(p)
 toggle(p,true)
 local a=autoAfter(p,count(p),kind);local b=autoAfter(p,count(p),kind)
 approx(b.Time-a.Time,.8,"fresh Auto")
 for _=1,4 do toggle(p,false);toggle(p,true) end
 local c=autoAfter(p,count(p),kind)
 untilTime(c.Time+.215)
 ask(p,"Burst");ask(p,"RawSpam")
 local manual=last(p);check(manual.Manual,"manual accepted while Auto ON")
 local first=autoAfter(p,count(p),kind)
 local second=autoAfter(p,count(p),kind)
 approx(first.Time-manual.Time,.5,"after manual")
 approx(second.Time-first.Time,.8,"after Auto")
 local third=autoAfter(p,count(p),kind)
 approx(third.Time-second.Time,.8,"continued Auto")
 -- The contact monitor must not execute attacks when the sole router is paused.
 suspended=true
 local n=count(p);local snap=Clock.__QASnapshot(p);task.wait(1.85)
 check(count(p)==n,"monitor alone cannot attack")
 check(Clock.__QASnapshot(p).Last==snap.Last and Clock.__QASnapshot(p).NextAuto==snap.NextAuto,"missed time leaves clock")
 suspended=false
 local resumed=autoAfter(p,n,kind)
 local nr=count(p);task.wait(.14);check(count(p)==nr,"no catch-up burst")
 local following=autoAfter(p,nr,kind)
 approx(following.Time-resumed.Time,.8,"resume no catch-up")
 toggle(p,false);n=count(p);task.wait(.9);check(count(p)==n,"OFF no old attack")
 -- Losing contact also prohibits a tap and produces no attack presentation.
 local saved=root(p).Position
 if kind=="Boss" then
  local e=E.GetEnemy(1,p);local f=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor.Stage01.Floor
  local chase=require(game.ServerScriptService.World.BossChaseService).ForWorld(w)
  local best,dist=nil,-1
  for _,x in {-.75,0,.75}do for _,z in {-.75,0,.75}do
   local pos=f.CFrame:PointToWorldSpace(Vector3.new(f.Size.X*x/2,0,f.Size.Z*z/2))
   pos=Vector3.new(pos.X,root(p).Position.Y,pos.Z)
   if chase.ContainsPlayer(e,pos) and (pos-e.CombatZone.Position).Magnitude>dist then best=pos;dist=(pos-e.CombatZone.Position).Magnitude end
  end end
  assert(best);put(p,best);check(not E.__QAContact(p.Character,e),"Boss contact removed")
 else
  local wall=W.GetCurrentWallForStage(p,1)
  put(p,wall.Wall.Position+Vector3.new(0,0,-18))
  check(not E.__QAWallContact(p,wall),"wall contact removed")
 end
 toggle(p,true)
 n=count(p);snap=Clock.__QASnapshot(p);if kind=="Boss"then ask(p,"Tap")end;task.wait(.95)
 check(count(p)==n,"no damage or training after contact loss")
 check(Clock.__QASnapshot(p).Last==snap.Last and Clock.__QASnapshot(p).NextAuto==snap.NextAuto,"contact rejection leaves clock")
 toggle(p,false);put(p,saved)
 local rows={}
 for i=start+1,count(p)do rows[#rows+1]=events[p][i]end
 for i=2,#rows do check(rows[i].Time-rows[i-1].Time>=.1985,"shared minimum")end
 for _,r in inputs[p]or{}do if not r.Accepted then check(r.Before.Last==r.After.Last and r.Before.NextAuto==r.After.NextAuto,"refusal leaves clocks")end end
 task.wait(.25)
 local after=trace(p);local a0,b0,c0=lengths(before,w);local a1,b1,c1=lengths(after,w)
 check(c1-c0==#rows,"one notification per real HP success")
 check(a1-a0==#rows,"one actual Track.Play per success")
 check(b1-b0==#rows,"one punch Sound.Play per success")
 report.Timings[#report.Timings+1]={World=w,Kind=kind,Fresh=b.Time-a.Time,AfterManual=first.Time-manual.Time,
 AfterAuto=second.Time-first.Time,Continued=third.Time-second.Time,Resume=following.Time-resumed.Time,
 Successes=#rows,Notifications=c1-c0,Animations=a1-a0,Sounds=b1-b0}
 for _,row in rows do report.Trace[#report.Trace+1]=row end
 report.Inputs[#report.Inputs+1]={World=w,Kind=kind,Rows=inputs[p]};inputs[p]={}
end
local function deathRetry(p,w)
 prepare(p,w,"Boss");toggle(p,true)
 autoAfter(p,count(p),"Boss")
 local n=count(p);local old=p.Character;hum(p).Health=0
 task.wait(.9);check(count(p)==n,"death cancels future automatic actions")
 waitFor(function()return p.Character and p.Character~=old and p.Character:GetAttribute("SpawnEngineReady") and p.Character:GetAttribute("MuscleScaleReady")end,20)
 D.SetAutoTapEnabled(p,false)
 root(p).Anchored=true;local h=Clock.__QASnapshot(p);task.wait(.6)
 check(count(p)==n,"old encounter cannot hit respawn")
 prepare(p,w,"Boss")
 local E,B=services(w)
 toggle(p,true)
 local fresh=autoAfter(p,count(p),"Boss")
 check(fresh.Delta>0,"new encounter attacks")
 toggle(p,false)
 -- Leave one hit of HP to exercise the ordinary lethal-hit result and re-fight path.
 local bs=B.Get(p);bs.HP=bs.BattleDamage
 task.wait(.22);tap(p,"Boss")
 waitFor(function()return E.GetPlayerState(p).Defeated[1]end)
 n=count(p);task.wait(.9);check(count(p)==n,"no old hit after defeat")
 prepare(p,w,"Boss")
 toggle(p,true);autoAfter(p,count(p),"Boss");toggle(p,false)
end
local function walking(p,w)
 lobby(p,w)
 toggle(p,true)
 local n=count(p);local strength=p:GetAttribute("Strength");task.wait(.8)
 check(count(p)==n and p:GetAttribute("Strength")==strength,"stationary Auto no gain")
 local m=tap(p,"Training")
 check(m.Clock.NextAuto-m.Clock.Last==.5,"manual Strength next automatic .5")
 task.wait(.75);check(count(p)==n+1,"stationary after manual no gain")
 local pos=root(p).Position
 root(p).Anchored=false;root(p):SetNetworkOwner(nil)
 local function walk()
  local h=hum(p)
  local cx=game.RunService.PreSimulation:Connect(function()h:Move(Vector3.new(1,0,0),false)end)
  task.wait(2.7);cx:Disconnect();h:Move(Vector3.zero,false);task.wait(.25)
 end
 local start=count(p);walk()
 check((root(p).Position-pos).Magnitude>2,"real walking displacement")
 task.wait(.25)
 local rows={}
 for i=start+1,count(p)do if events[p][i].Kind=="Training" and not events[p][i].Manual then rows[#rows+1]=events[p][i]end end
 check(#rows>=4,"walking real Strength gains")
 for i=2,#rows do approx(rows[i].Time-rows[i-1].Time,.5,"walking Auto .5")end
 n=count(p);task.wait(.75);check(count(p)==n,"stopped no gain")
 toggle(p,false)
 start=count(p);walk();check(count(p)==start,"Auto OFF walking no automatic gain")
 local first=tap(p,"Training");task.wait(.215);local second=tap(p,"Training")
 check(second.Time-first.Time>=.2 and second.Time-first.Time<.45,"manual Strength .2 remains available")
 report.Training=report.Training or {};report.Training[#report.Training+1]={World=w,Rows=rows}
end
local ended=false
local function finish()
 if ended then return end;ended=true
 report.Passed=true
 for _,v in report.Cases do if not v.Passed then report.Passed=false end end
 for _,v in report.Checks do if not v.Passed then report.Passed=false end end
 local p=game.Players:GetPlayers()[1]
 if p then report.Client=trace(p) end
 local output=Instance.new("StringValue");output.Name="__CadenceResult";output.Value=game.HttpService:JSONEncode(report);output.Parent=RS
 print("__CadenceComplete",report.Passed)
end
task.delay(210,function()report.Cases[#report.Cases+1]={Label="watchdog",Passed=false};finish()end)
local ok,err=xpcall(function()
 local p=waitFor(function()return game.Players:GetPlayers()[1]end,30)
 waitFor(function()return D.Get(p) and D.Get(p).Loaded and p.Character and p.Character:GetAttribute("SpawnEngineReady") and p.Character:GetAttribute("MuscleScaleReady")end,35)
 if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p) end
 D.SetAutoTapEnabled(p,false);ask(p,"Ready")
 local d=D.Get(p).Data;d.SelectedSizeTier=1;p:SetAttribute("SelectedSizeTier",1)
 D.UnlockWorld(p,2);D.MarkWorld2Reached(p)
 for _,w in {1,2}do
  run("World"..w.." toggle boundary",function()
   for _,kind in {"Wall","Boss"}do
    prepare(p,w,kind);toggle(p,true)
    local first=autoAfter(p,count(p),kind)
    local mark=count(p);local due=Clock.__QASnapshot(p).NextAuto
    task.wait(.03);toggle(p,false);toggle(p,true)
    check(Clock.__QASnapshot(p).NextAuto==due or count(p)>mark,"toggle preserves successful deadline")
    local second=autoAfter(p,mark,kind)
    check(second.Time-first.Time>=.798,"toggle cannot shorten successful Auto interval")
    report.Timings[#report.Timings+1]={World=w,Kind=kind,ToggleGap=second.Time-first.Time,First=first,Second=second}
    toggle(p,false)
   end
  end)
  for _,kind in {"Wall","Boss"}do run("World"..w.." "..kind,function()flow(p,w,kind)end)end
  run("World"..w.." death/defeat/retry",function()deathRetry(p,w)end)
  run("World"..w.." walking",function()walking(p,w)end)
 end
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="setup",Passed=false,Error=err}end
finish()
