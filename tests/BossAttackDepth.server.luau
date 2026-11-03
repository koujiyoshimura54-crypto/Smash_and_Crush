-- Temporary native Play fixture. All persistence and purchase APIs are redirected to memory.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local W=game.ServerScriptService.World
local D=require(S.PlayerDataService)
local EAll=require(W.EnemyManager)
local Old=require(RS.__DepthQAOld)
local report={Checks={},Cases={},Samples={},Kind="Native server combat; two real clients; memory stores; scripted fixture positions"}
local request=Instance.new("RemoteEvent");request.Name="__DepthQARequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__DepthQAReply";reply.Parent=RS
local replies={}
reply.OnServerEvent:Connect(function(p,id,r)replies[id]={Player=p,Result=r}end)
local function waitFor(f,seconds)
 local deadline=os.clock()+(seconds or 10)
 repeat local value=f();if value then return value end;task.wait(.025) until os.clock()>deadline
 error("Fixture timeout",2)
end
local function check(ok,label,detail)
 report.Checks[#report.Checks+1]={Passed=not not ok,Label=label,Detail=detail}
 assert(ok,label)
end
local function case(label,fn)
 local ok,err=xpcall(fn,debug.traceback)
 report.Cases[#report.Cases+1]={Label=label,Passed=ok,Error=not ok and err or nil}
 print("__DepthQA",label,ok,not ok and err or "")
end
local function ask(p,action)
 local id=game.HttpService:GenerateGUID(false);request:FireClient(p,id,action)
 local r=waitFor(function()return replies[id]end,10)
 assert(r.Player==p and r.Result.OK,tostring(r.Result.Value))
 return r.Result.Value
end
local function hum(p)return p.Character:FindFirstChildOfClass("Humanoid")end
local function root(p)return p.Character.HumanoidRootPart end
local function put(p,pos)
 local r=root(p);r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.CFrame=CFrame.new(pos)
end
local function ready(p)
 waitFor(function()return D.Get(p) and D.Get(p).Loaded and p.Character and hum(p) and hum(p).Health>0 and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:GetAttribute("SpawnEngineReady")~=false end,30)
 D.SetAutoTapEnabled(p,false)
 D.Get(p).Data.SelectedSizeTier=1;p:SetAttribute("SelectedSizeTier",1)
end
local function prepare(p,w,n)
 ready(p)
 EAll.ForWorld(p:GetAttribute("CurrentWorld") or 1).Deactivate(p)
 p:SetAttribute("CurrentWorld",w)
 local E=EAll.ForWorld(w);waitFor(function()return E.IsReady()end,30)
 local B=require(W.BossCombatService).ForWorld(w)
 local A=require(W.BossAttackService).ForWorld(w)
 local C=require(W.BossChaseService).ForWorld(w)
 local walls=require(W.Stage1WallManager).ForWorld(w)
 D.SetCurrentStrength(p,B.GetStageConfig(n).MaxHP/1000)
 E.StartRun(p,n)
 local e=waitFor(function()return E.GetEnemy(n,p)end)
 e:SetAttribute("__DepthQAPaused",true)
 walls.ApplyDamageForStage(p,n,1e30)
 if w==2 then C.BeginIntro(e) end
 task.wait(.2)
 local floor=workspace[w==1 and "GeneratedMap" or "World2Map"].BattleCorridor[("Stage%02d"):format(n)].Floor
 local pivot=e:GetPivot()
 -- Move only the isolated actor to the arena center for reproducible boundary samples.
 e:PivotTo(CFrame.new(floor.Position.X,pivot.Position.Y,floor.Position.Z)*pivot.Rotation)
 local y=floor.Position.Y+floor.Size.Y/2+hum(p).HipHeight+root(p).Size.Y/2
 local c={P=p,W=w,N=n,E=E,B=B,A=A,C=C,O=Old.ForWorld(w),Actor=e,Floor=floor,Y=y}
 put(p,Vector3.new(e.CombatZone.Position.X,y,e.CombatZone.Position.Z))
 waitFor(function()return E.__DepthQAContact(p.Character,e) and A.GetState(p) and B.Get(p)end,5)
 c.ColliderSize=e.MiniBossCollider.Size;c.ZoneSize=e.CombatZone.Size
 return c
end
local function bounds(c)return c.A.GetAttackBounds(c.Actor,c.N,c.P)end
local function localPut(c,x,z,y)
 local b=bounds(c)
 local pos=b.Pivot:PointToWorldSpace(Vector3.new(x,0,z))
 put(c.P,Vector3.new(pos.X,y or c.Y,pos.Z))
 assert(c.C.ContainsPlayer(c.Actor,root(c.P).Position),"Sample outside arena")
end
local function depthPoint(c,fraction)
 local b=bounds(c);local r=math.max(root(c.P).Size.X,root(c.P).Size.Z)/2
 local cx,cz=(b.Low.X+b.High.X)/2,(b.Low.Z+b.High.Z)/2
 local half=(b.High.Z-b.Low.Z)/2+b.Reach+r
 return cx,cz-half*fraction,half
end
local function range(c)
 local h,r=hum(c.P),root(c.P)
 local hit,distance,reach=c.A.IsInRange(c.Actor,c.N,h,r)
 local old,oldDistance,oldReach=c.O.IsInRange(c.Actor,c.N,h,r)
 return hit,old,distance,oldDistance,reach,oldReach
end
local function actual(c,label,expectHit,count)
 local rows={}
 for i=1,(count or 1) do
  local state=assert(c.A.GetState(c.P),"No native attack session")
  local prior=state.LastAttack and state.LastAttack.Index or 0
  hum(c.P).Health=100 -- fixture setup only; damage below comes from native Heartbeat
  waitFor(function()return state.LastAttack and state.LastAttack.Index>prior end,2.5)
  local a=table.clone(state.LastAttack)
  rows[#rows+1]=a
  check(a.Hit==expectHit and a.HealthBefore-a.HealthAfter==(expectHit and 25 or 0)
   and hum(c.P).Health==a.HealthAfter,label.." actual HP "..i,a)
 end
 return rows
end
local function checkGeometry(c,label)
 local b,old=bounds(c),c.O.GetAttackBounds(c.Actor,c.N,c.P)
 check((b.Low-old.Low).Magnitude<.001 and (b.High-old.High).Magnitude<.001 and b.Pivot==old.Pivot
  and b.AttackTop==old.AttackTop and b.Reach==old.Reach and b.Settings==old.Settings,label.." original bounds/center/height/angle/reach unchanged")
 local x,z,half=depthPoint(c,.95);localPut(c,x,z)
 local hit,was=range(c);check(was and not hit,label.." old-only front shell")
 local out=actual(c,label.." old-only shell",false)
 x,z=depthPoint(c,.85);localPut(c,x,z)
 hit,was=range(c);check(was and hit,label.." inside reduced depth")
 local inside=actual(c,label.." inside",true,2)
 check(math.abs(inside[2].ScheduledAt-inside[1].ScheduledAt-1)<.001
  and math.abs(inside[2].ActualAt-inside[1].ActualAt-1)<.12,label.." original one-second native cadence",inside[2].ActualAt-inside[1].ActualAt)
 -- Exact front boundary probes, independently of visual boxes.
 for _,f in {.899,.901} do x,z=depthPoint(c,f);localPut(c,x,z);hit,was=range(c)
  check(was and hit==(f<.9),label.." front boundary "..f)
 end
 b=bounds(c)
 local cx,cz=(b.Low.X+b.High.X)/2,(b.Low.Z+b.High.Z)/2
 local radius=math.max(root(c.P).Size.X,root(c.P).Size.Z)/2
 for _,edge in {-1,1} do
  local edgeX=(edge<0 and b.Low.X or b.High.X)+edge*(b.Reach+radius-.01)
  localPut(c,edgeX,cz)
  local _,_,nd,od,nr,orr=range(c)
  check(math.abs(nd-od)<.001 and nr==orr,label.." lateral distance envelope unchanged "..edge,{Distance=nd,Old=od,Reach=nr})
 end
 x,z=depthPoint(c,.5)
 local verticalTop=b.Pivot.Position.Y+b.AttackTop+b.Settings.VerticalPadding+hum(c.P).HipHeight+root(c.P).Size.Y/2
 localPut(c,x,z,verticalTop-.02);hit,was=range(c);check(was and hit,label.." original upper-height edge inside")
 localPut(c,x,z,verticalTop+.02);hit,was=range(c);check(not was and not hit,label.." original upper-height edge outside")
 local pivot=c.Actor:GetPivot();c.Actor:PivotTo(CFrame.new(pivot.Position)*CFrame.Angles(0,math.pi/2,0))
 x,z=depthPoint(c,.95);localPut(c,x,z);hit,was=range(c)
 check(was and not hit,label.." yaw90 shrinks Boss-local front")
 actual(c,label.." yaw90 old-only shell",false)
 x,z=depthPoint(c,.85);localPut(c,x,z);actual(c,label.." yaw90 inner",true)
 check(c.Actor.MiniBossCollider.Size==c.ColliderSize and c.Actor.CombatZone.Size==c.ZoneSize,label.." physical/contact Parts untouched")
 report.Samples[#report.Samples+1]={World=c.W,Stage=c.N,OldDepth=half*2,NewDepth=half*2*.9,
  Width=(b.High.X-b.Low.X)+2*(b.Reach+radius),Collider=tostring(c.ColliderSize),OldShell=out,Inner=inside}
 return half
end
local function playerAttackAndChase(c)
 local zone=c.Actor.CombatZone
 put(c.P,Vector3.new(zone.Position.X,c.Y,zone.Position.Z))
 waitFor(function()return c.E.__DepthQAContact(c.P.Character,c.Actor)end,2)
 local state=c.B.Get(c.P);local hp=state.HP
 ask(c.P,"Tap");waitFor(function()return state.HP<hp end,2)
 check(state.HP==hp-state.BattleDamage,"W"..c.W.." native client Player-to-Boss hit unchanged",{Before=hp,After=state.HP,Damage=state.BattleDamage})
 local x,z=depthPoint(c,.85);localPut(c,x,z)
 local before=c.Actor:GetPivot()
 hum(c.P).Health=100;c.Actor:SetAttribute("__DepthQAPaused",nil)
 task.wait(.3)
 check((c.Actor:GetPivot().Position-before.Position).Magnitude>.1 and c.Actor:GetAttribute("ChaseState")=="Chasing","W"..c.W.." native pursuit still moves",{Movement=(c.Actor:GetPivot().Position-before.Position).Magnitude})
 c.Actor:SetAttribute("__DepthQAPaused",true)
end
local function finish()
 if report.Ended then return end;report.Ended=true;report.Passed=true
 for _,r in report.Cases do if not r.Passed then report.Passed=false end end
 game:GetService("StudioTestService"):EndTest(report)
end
task.delay(210,function()report.Cases[#report.Cases+1]={Label="Timeout",Passed=false};finish()end)
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==2 end,40)
 local ps=game.Players:GetPlayers();table.sort(ps,function(a,b)return a.UserId<b.UserId end)
 local p,peer=ps[1],ps[2]
 ready(p);ready(peer);ask(p,"Ready");ask(peer,"Ready")
 local last
 for _,spec in {{1,1},{1,10},{2,2},{2,9}} do
  case("W"..spec[1].." Stage"..spec[2].." geometry and native damage",function()
   local c=prepare(p,spec[1],spec[2]);last=c
   checkGeometry(c,"W"..spec[1].."S"..spec[2])
   if spec[2]==1 or spec[2]==2 then playerAttackAndChase(c) end
   c.E.Deactivate(p)
  end)
 end
 case("Death, re-fight and World transition: no accumulated shrink",function()
  local c=prepare(p,1,1)
  local b=bounds(c);local _,_,half=depthPoint(c,.95)
  for i=1,5 do check(bounds(c).DepthScale==.9,"Repeated bounds factor "..i) end
  local oldChar=p.Character;hum(p).Health=0
  waitFor(function()return p.Character~=oldChar and p.Character and hum(p) and hum(p).Health>0 and p.Character:FindFirstChild("HumanoidRootPart")end,18)
  c=prepare(p,1,1);local _,_,newHalf=depthPoint(c,.95)
  check(math.abs(newHalf-half)<.02 and bounds(c).DepthScale==.9,"Respawn/re-fight unchanged depth",{Old=half*2,New=newHalf*2*.9})
  local x,z=depthPoint(c,.95);localPut(c,x,z);actual(c,"Respawn old-only shell",false)
  c.E.Deactivate(p)
  c=prepare(p,2,2);check(bounds(c).DepthScale==.9,"World2 transition factor")
  c.E.Deactivate(p)
  c=prepare(p,1,1);local _,_,again=depthPoint(c,.95)
  check(math.abs(again-half)<.02 and bounds(c).DepthScale==.9,"World1 return/recreated actor no accumulation")
  c.E.Deactivate(p)
 end)
 case("Independent native PlayerHP sessions",function()
  local a=prepare(p,1,1);local b=prepare(peer,1,1)
  local x,z=depthPoint(a,.95);localPut(a,x,z)
  x,z=depthPoint(b,.85);localPut(b,x,z)
  hum(peer).Health=100
  actual(a,"Peer test owner outside",false)
  waitFor(function()return hum(peer).Health<100 end,2)
  check(hum(p).Health==100 and hum(peer).Health<=75 and a.Actor~=b.Actor,"Peer damage remains independent")
  a.E.Deactivate(p);b.E.Deactivate(peer)
 end)
end,debug.traceback)
if not ok then report.Cases[#report.Cases+1]={Label="Fixture startup",Passed=false,Error=err} end
finish()
