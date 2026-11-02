-- Temporary native two-client fixture; all persistence/badges redirected to memory.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local Data=require(S.PlayerDataService)
local World=game.ServerScriptService.World
local Enemies=require(World.EnemyManager)
local Placement=require(S.LobbySpawnService)
local Tap=require(S.AutoTapService)
local report={Checks={},Cases={},Kind="Two real clients; prepared combat; memory-only persistence"}
local request=Instance.new("RemoteEvent");request.Name="__BossQARequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__BossQAReply";reply.Parent=RS
local answers={}
reply.OnServerEvent:Connect(function(p,id,result)answers[id]={Player=p,Result=result}end)
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 10)
 repeat local v=fn();if v then return v end;task.wait(.025) until os.clock()>deadline
 error("Fixture timeout")
end
local function check(ok,label,detail)
 report.Checks[#report.Checks+1]={Passed=not not ok,Label=label,Detail=detail}
 assert(ok,label)
end
local function ask(p,action,value)
 local id=game.HttpService:GenerateGUID(false);request:FireClient(p,id,action,value)
 local r=waitFor(function()return answers[id]end,15)
 assert(r.Player==p and r.Result.OK,tostring(r.Result.Value));return r.Result.Value
end
local function runCase(label,fn)
 if script:GetAttribute("Only")=="Remaining" and not label:find("windup",1,true) and not label:find("stop distance",1,true) then return end
 if script:GetAttribute("Only")=="World2Stop" and label~="World2 chase stop distance" then return end
 local ok,err=xpcall(fn,debug.traceback)
 report.Cases[#report.Cases+1]={Label=label,Passed=ok,Error=not ok and err or nil}
 print("__BossQA",label,ok,not ok and err or "")
end
local function services(w)
 return Enemies.ForWorld(w),require(World.BossCombatService).ForWorld(w),require(World.BossAttackService).ForWorld(w),require(World.BossChaseService).ForWorld(w),require(World.Stage1WallManager).ForWorld(w)
end
local function root(p)return p.Character.HumanoidRootPart end
local function health(p)return p.Character.Humanoid end
local function put(p,pos,face)
 local r=root(p);r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 r.CFrame=face and CFrame.lookAt(pos,Vector3.new(face.X,pos.Y,face.Z)) or CFrame.new(pos)
end
local function prepare(p,w,n,scale)
 waitFor(function()return Data.Get(p) and Data.Get(p).Loaded and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and health(p).Health>0 end,30)
 Data.SetAutoTapEnabled(p,false)
 local old=p:GetAttribute("CurrentWorld") or 1
 Enemies.ForWorld(old).Deactivate(p)
 p:SetAttribute("CurrentWorld",w)
 local E,B,A,C,W=services(w)
 waitFor(function()return E.IsReady()end,30)
 Data.SetCurrentStrength(p,B.GetStageConfig(n).MaxHP/100)
 E.StartRun(p,n)
 local e=waitFor(function()return E.GetEnemy(n,p)end)
 W.ApplyDamageForStage(p,n,1e30)
 if w==2 then C.BeginIntro(e) end -- same callback as the prepared final-wall clear
 p:SetAttribute("SelectedSizeTier",scale or 1)
 task.wait(.15)
 local floor=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor[("Stage%02d"):format(n)].Floor
 local y=floor.Position.Y+floor.Size.Y/2+health(p).HipHeight+root(p).Size.Y/2
 put(p,Vector3.new(e.CombatZone.Position.X,y+50,e.CombatZone.Position.Z))
 health(p).Health=100
 local context={P=p,W=w,N=n,E=E,B=B,A=A,C=C,Actor=e,Floor=floor,Y=y,Hits={}}
 local original=B.Attack
 B.Attack=function(player)
  local status,state=original(player)
  if player==p and state then context.Hits[#context.Hits+1]={Time=os.clock(),HP=state.HP,Contact=E.__QAContact(p.Character,e)} end
  return status,state
 end
 context.Restore=function()B.Attack=original end
 return context
end
local function contact(c)
 local z=c.Actor.CombatZone
 put(c.P,Vector3.new(z.Position.X,c.Y,z.Position.Z)+z.CFrame.LookVector*math.min(2,z.Size.Z/4),z.Position)
 waitFor(function()return c.E.__QAContact(c.P.Character,c.Actor)end,2)
end
local function high(c)
 local v=c.Actor.CombatZone.Position
 put(c.P,Vector3.new(v.X,c.Y+60,v.Z));task.wait(.05)
end
local function far(c)
 local best,dist
 for _,x in {-.75,0,.75} do for _,z in {-.75,0,.75} do
  local pos=c.Floor.CFrame:PointToWorldSpace(Vector3.new(c.Floor.Size.X*x/2,0,c.Floor.Size.Z*z/2))
  pos=Vector3.new(pos.X,c.Y,pos.Z)
  if c.C.ContainsPlayer(c.Actor,pos) then
   local d=(pos-c.Actor.CombatZone.Position).Magnitude
   if not dist or d>dist then best,dist=pos,d end
  end
 end end
 assert(best,"No arena sample");put(c.P,best,c.Actor.CombatZone.Position);task.wait(.05)
 return best
end
local function leave(c)
 put(c.P,c.Floor.CFrame:PointToWorldSpace(Vector3.new(c.Floor.Size.X+20,60,0)));task.wait(.15)
end
local ended=false
local function finish()
 if ended then return end;ended=true
 report.Passed=true
 for _,v in report.Cases do if not v.Passed then report.Passed=false end end
 game:GetService("StudioTestService"):EndTest(report)
end
task.delay(230,function()report.Cases[#report.Cases+1]={Label="Timeout",Passed=false};finish()end)
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==2 end,40)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local p,peer=players[1],players[2]
 for _,player in players do
  waitFor(function()return Data.Get(player) and Data.Get(player).Loaded and player.Character and player.Character:FindFirstChild("HumanoidRootPart")end,40)
  Data.SetAutoTapEnabled(player,false)
  ask(player,"Ready")
 end
 for _,w in {1,2} do
  runCase("World"..w.." contact / pursuit / resume / exit",function()
   local c=prepare(p,w,w==1 and 1 or 2)
   contact(c);task.wait(.15)
   local bs=waitFor(function()return c.B.Get(p)end)
   local before=bs.HP
   ask(p,"Tap");waitFor(function()return bs.HP<before end,2)
   check(bs.HP==before-bs.BattleDamage,"W"..w.." manual contact actual HP")
   health(p).Health=75
   local beforeHP,beforePlayer=bs.HP,health(p).Health
   local actorBefore=c.Actor:GetPivot().Position
   far(c)
   check(not c.E.__QAContact(p.Character,c.Actor),"W"..w.." separated inside arena")
   ask(p,"Tap");task.wait(.2)
   check(bs.HP==beforeHP and c.B.Get(p)==bs and p:GetAttribute("IsFighting"),"W"..w.." separation retains encounter; manual misses")
   check(health(p).Health<=beforePlayer and health(p).Health>0,"W"..w.." separation does not heal player")
   check(c.Actor:GetAttribute("ChaseState")=="Chasing" and (c.Actor:GetPivot().Position-actorBefore).Magnitude>.1,"W"..w.." pursuit continues")
   high(c);Data.SetAutoTapEnabled(p,true);task.wait(.65)
   check(bs.HP==beforeHP and c.B.Get(p)==bs and Data.IsAutoTapEnabled(p),"W"..w.." vertical separation / Auto retained")
   health(p).Health=100;contact(c)
   waitFor(function()return bs.HP<beforeHP end,2)
   local hitCount=#c.Hits
   task.wait(.12)
   check(#c.Hits==hitCount,"W"..w.." recontact no queued burst")
   waitFor(function()return #c.Hits>hitCount end,2)
   local a,b=c.Hits[#c.Hits-1],c.Hits[#c.Hits]
   check(b.Time-a.Time>=c.B.AttackInterval-.06,"W"..w.." Auto cadence",b.Time-a.Time)
   Data.SetAutoTapEnabled(p,false);high(c);task.wait(.6)
   local damaged=bs.HP;health(p).Health=50
   leave(c)
   check(health(p).Health==100 and c.E.GetGauge(p,c.N)==bs.MaxHP and c.B.Get(p)==nil and not p:GetAttribute("IsFighting"),"W"..w.." arena exit heals both")
   contact(c);task.wait(.2)
   local again=waitFor(function()return c.B.Get(p)end)
   check(again~=bs and again.HP==again.MaxHP and health(p).Health==100 and damaged<again.HP,"W"..w.." reentry starts fully healed")
   local ui=ask(p,"Gauge",{World=w,Stage=c.N})
   check(ui.Packet and ui.Packet.Current==again.HP and ui.Packet.Max==again.MaxHP,"W"..w.." replicated HP matches",ui)
   check(ui.Fill==1,"W"..w.." rendered gauge fill is full",ui)
   c.Restore();leave(c)
  end)
  runCase("World"..w.." windup / generations / death",function()
   local c=prepare(p,w,2)
   contact(c);Data.SetAutoTapEnabled(p,true)
   waitFor(function()local s=c.E.__QASession(p);return s and s.Pending>0 end,2)
   local bs=c.B.Get(p);local hp=bs.HP
   high(c);task.wait(.6)
   check(bs.HP==hp and bs.Attacks==0 and c.B.Get(p)==bs,"W"..w.." leaves before Auto impact: miss")
   Data.SetAutoTapEnabled(p,false);contact(c);task.wait(.2);ask(p,"Tap")
   waitFor(function()return bs.HP<hp end,2)
   health(p).Health=50;Data.SetAutoTapEnabled(p,true)
   waitFor(function()local s=c.E.__QASession(p);return s and s.Pending>0 end,2)
   leave(c);task.wait(.55)
   check(c.E.GetGauge(p,2)==bs.MaxHP and health(p).Health==100,"W"..w.." pending attack cannot undo exit heal")
   contact(c);waitFor(function()local s=c.E.__QASession(p);return s and s.Pending>0 end,2)
   Data.SetAutoTapEnabled(p,false);c.E.StartRun(p,2);c.Actor=waitFor(function()return c.E.GetEnemy(2,p)end);high(c);task.wait(.65)
   check(c.E.GetGauge(p,2)==c.B.GetStageConfig(2).MaxHP,"W"..w.." replaced combat generation rejects pending hit")
   c.Restore()
   c=prepare(p,w,2);contact(c);Data.SetAutoTapEnabled(p,true)
   waitFor(function()local s=c.E.__QASession(p);return s and s.Pending>0 end,2)
   local old=c.B.Get(p);local oldHP=old.HP;local character=p.Character
   health(p).Health=0;task.wait(.6)
   check(old.HP==oldHP,"W"..w.." death rejects pending impact")
   Data.SetAutoTapEnabled(p,false)
   waitFor(function()return p.Character~=character and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and health(p).Health>0 end,15)
   check(c.E.GetGauge(p,2)==c.B.GetStageConfig(2).MaxHP,"W"..w.." respawn has no stale damage")
   c.Restore()
  end)
  runCase("World"..w.." two-client isolation",function()
   local a=prepare(p,w,2);local b=prepare(peer,w,2)
   contact(a);contact(b);task.wait(.55)
   ask(p,"Tap");ask(peer,"Tap")
   local sa,sb=a.B.Get(p),b.B.Get(peer)
   waitFor(function()return sa.HP<sa.MaxHP and sb.HP<sb.MaxHP end,2)
   health(p).Health=50;health(peer).Health=75;high(b)
   local peerHP=sb.HP
   leave(a);task.wait(.2)
   check(a.E.GetGauge(p,2)==sa.MaxHP and health(p).Health==100,"W"..w.." owner exit heals owner")
   check(b.B.Get(peer)==sb and sb.HP==peerHP and health(peer).Health==75 and peer:GetAttribute("IsFighting"),"W"..w.." owner exit leaves peer HP/session unchanged")
   b.Restore();a.Restore();leave(b)
  end)
  runCase("World"..w.." chase stop distance",function()
   for _,spec in {{1,1},{8,13}} do
    local c=prepare(p,w,spec[1],spec[2])
    local shell=c.Actor.MiniBossCollider
    local pos=shell.Position+shell.CFrame.LookVector*(shell.Size.Z/2+13)
    pos=Vector3.new(pos.X,c.Y,pos.Z)
    if c.C.ContainsPlayer(c.Actor,pos) then put(p,pos,shell.Position) else far(c) end
    waitFor(function()return c.E.__QAContact(p.Character,c.Actor)end,12)
    health(p).Health=100
    task.wait(.8)
    local before=c.Actor:GetPivot().Position
    task.wait(.2)
    local drift=(c.Actor:GetPivot().Position-before).Magnitude
    check(drift<.15 and c.E.__QAContact(p.Character,c.Actor),"W"..w.." chase stops in real contact tier"..spec[2].." Stage"..spec[1],{Drift=drift})
    c.Restore();leave(c)
   end
  end)
  runCase("World"..w.." player sizes and Boss bodies",function()
   for _,spec in {{1,1},{8,13}} do
    local c=prepare(p,w,spec[1],spec[2])
    contact(c);task.wait(.55)
    local bs=waitFor(function()return c.B.Get(p)end,4);local hp=bs.HP
    ask(p,"Tap");waitFor(function()return bs.HP<hp end,2)
    check(c.E.__QAContact(p.Character,c.Actor),"W"..w.." tier"..spec[2].." Stage"..spec[1].." contact",{
     Height=p.Character:GetAttribute("MuscleHeightScale"),Trigger=tostring(p.Character.WallCombatTriggerRef.Value.Size),Zone=tostring(c.Actor.CombatZone.Size)})
    c.Restore();leave(c)
   end
  end)
 end
 runCase("World travel rejects pending attack",function()
  local c=prepare(p,1,2);contact(c);Data.SetAutoTapEnabled(p,true)
  waitFor(function()local s=c.E.__QASession(p);return s and s.Pending>0 end,2)
  local bs=c.B.Get(p);local hp=bs.HP
  Data.UnlockWorld(p,2)
  local cfg=require(RS.Config.WorldGateConfig)
  put(p,workspace[cfg.GateName].WorldGateTrigger.Position)
  ask(p,"Travel",2)
  waitFor(function()return p:GetAttribute("CurrentWorld")==2 end,10)
  task.wait(.6);check(bs.HP==hp and c.B.Get(p)==nil,"Old World pending hit rejected after native gate travel")
  Data.SetAutoTapEnabled(p,false);c.Restore()
 end)
 runCase("Defeated Boss never revived by arena exit",function()
  local c=prepare(p,1,1)
  Data.SetCurrentStrength(p,c.B.GetStageConfig(1).MaxHP*2)
  contact(c);task.wait(.55);ask(p,"Tap")
  waitFor(function()return c.E.GetPlayerState(p).Defeated[1]end,3)
  leave(c);task.wait(.65)
  check(c.E.GetPlayerState(p).Defeated[1] and c.E.GetGauge(p,1)==0 and c.E.GetEnemy(1,p)==nil,"Defeat followed by exit remains defeated")
  c.Restore()
 end)
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="Suite",Passed=false,Error=err} end
finish()
