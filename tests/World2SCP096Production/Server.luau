local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local ST=game:GetService('StudioTestService')
local report={Cases={},Errors={},Mode='Native two-client Play; isolated stores; server-driven positions and real combat API'}
local request=Instance.new('RemoteEvent');request.Name='__SCP096TestRequest';request.Parent=RS
local reply=Instance.new('RemoteEvent');reply.Name='__SCP096TestReply';reply.Parent=RS
local replies={};reply.OnServerEvent:Connect(function(p,key,value)replies[key]={Player=p,Value=value}end)
local function waitFor(fn,seconds,label)
 local finish=os.clock()+seconds
 repeat local result=fn();if result then return result end;task.wait(.025) until os.clock()>=finish
 error('Timeout: '..label)
end
local function check(value,message)assert(value,message)end
local done=false
task.delay(240,function()if not done then done=true;ST:EndTest({Timeout=true,Report=report})end end)
local ok,err=xpcall(function()
 waitFor(function()return #Players:GetPlayers()==2 end,45,'two players')
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 for _,p in players do check(p.UserId<=0,'Expected isolated Studio test clients') end
 local A,B=players[1],players[2]
 local PD=require(game.ServerScriptService.Services.PlayerDataService)
 local EM=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
 local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
 local Attack=require(game.ServerScriptService.World.BossAttackService).ForWorld(2)
 local Chase=require(game.ServerScriptService.World.BossChaseService).ForWorld(2)
 waitFor(function()return EM.IsReady()end,45,'World2 ready')
 local map=workspace.World2Map.BattleCorridor.Stage01
 local keepAlive,targets={},{}
 local function actor(p)
  local owner=workspace.World2Enemies:FindFirstChild('Owner_'..p.UserId)
  return owner and owner:FindFirstChild('Stage01_Enemy')
 end
 local function place(p,pos,e)
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  if root then
   root.Anchored=true
   local target=e and e:GetPivot().Position or pos+Vector3.zAxis
   root.CFrame=CFrame.lookAt(pos,Vector3.new(target.X,pos.Y,target.Z))
  end
 end
 local function near(p,e)
  targets[p]=nil
  local pos=e:GetPivot().Position+e:GetPivot().LookVector*3
  place(p,Vector3.new(pos.X,map.Floor.Position.Y+map.Floor.Size.Y/2+3,pos.Z),e)
 end
 local function far(p,e)
  targets[p]=e
 end
 Run.Heartbeat:Connect(function()
  for p in keepAlive do
   local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if hum and hum.Health>0 then hum.Health=hum.MaxHealth end
  end
  for p,e in targets do if e.Parent and p.Character then
   local root=p.Character:FindFirstChild('HumanoidRootPart');local hum=p.Character:FindFirstChildOfClass('Humanoid')
   if root and hum and hum.Health>0 then
    -- Choose an existing arena point outside the unchanged attack volume.
    local origin=e:GetPivot().Position
    local chosen
    for _,offset in {Vector3.new(0,0,-18),Vector3.new(18,0,0),Vector3.new(-18,0,0),Vector3.new(0,0,18)} do
     local pos=Vector3.new(origin.X+offset.X,map.Floor.Position.Y+map.Floor.Size.Y/2+3,origin.Z+offset.Z)
     if Chase.ContainsPlayer(e,pos) then chosen=pos;break end
    end
    if chosen then place(p,chosen,e) end
   end
  end end
 end)
 local function ready(p)
  waitFor(function()return PD.Get(p) and p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   and p.Character:FindFirstChildOfClass('Humanoid').Health>0 end,30,'character/profile')
  PD.SetAutoTapEnabled(p,false);p:SetAttribute('CurrentWorld',2);keepAlive[p]=true
 end
 for _,p in players do ready(p) end
 task.wait(2)
 local function prepare(p,battleStrength)
  targets[p]=nil;ready(p);PD.SetCurrentStrength(p,1e16);EM.InitializePlayer(p,1)
  local e=waitFor(function()return actor(p)end,10,'new actor')
  local wall=map['Stage1.1'].Wall
  place(p,Vector3.new(wall.Position.X,map.Floor.Position.Y+map.Floor.Size.Y/2+3,wall.Position.Z-4))
  local mounted='Mounted_'..p.UserId..'_'..e:GetAttribute('SpawnGeneration')
  request:FireClient(p,mounted,'Mounted',e:GetAttribute('SpawnGeneration'))
  check(waitFor(function()return replies[mounted]end,14,'client body mount').Value.Mounted,'Body mount failed')
  task.wait(.2)
  local accepted,reason=EM.TryManualAttack(p)
  check(accepted and Wall.IsBossUnlockedForStage(p,1),'Actual wall4 break: '..tostring(reason))
  check(e:GetAttribute('SCP096Phase')=='GetUp_Panic','Intro must start at actual wall4 break')
  PD.SetCurrentStrength(p,battleStrength or 1)
  return e
 end
 local function phase(e,name,seconds)
  return waitFor(function()return e.Parent and e:GetAttribute('SCP096Phase')==name end,seconds or 5,name)
 end
 local a,b=prepare(A),prepare(B)
 local aStart=a:GetAttribute('BossIntroStartedAt');local bStart=b:GetAttribute('BossIntroStartedAt')
 near(A,a);near(B,b)
 local aPivot,bPivot=a:GetPivot(),b:GetPivot()
 task.wait(.3)
 check((a:GetPivot().Position-aPivot.Position).Magnitude<.001 and (b:GetPivot().Position-bPivot.Position).Magnitude<.001,'Intro moved')
 local attackA=Attack.GetState(A)
 check(not attackA or not attackA.LastAttack,'Intro dealt Boss damage')
 waitFor(function()return a:GetAttribute('SCP096Phase')~='GetUp_Panic' end,3,'GetUp completes')
 report.Cases.Intro={AStart=aStart,BStart=bStart,AFirstBoundary=a:GetAttribute('SCP096PhaseStartedAt'),Duration=a:GetAttribute('BossIntroDuration')}
 check(math.abs(report.Cases.Intro.AFirstBoundary-aStart-1.5)<.03,'GetUp2x duration')
 far(A,a);far(B,b)
 phase(a,'Running',4);phase(b,'Running',4)
 check(math.abs(a:GetAttribute('SCP096PhaseStartedAt')-aStart-2.5)<.03,'Combined2x intro')
 task.wait(1.2)
 check((a:GetPivot().Position-aPivot.Position).Magnitude>.3 and (b:GetPivot().Position-bPivot.Position).Magnitude>.3,'Both actors pursue')
 report.Cases.BothMoved=true
 near(A,a);phase(a,'AttackRunStart');task.wait(.15);far(A,a);phase(a,'Running')
 report.Cases.InterruptedStart=true
 -- Enter just before an existing damage deadline. Start animation must not delay it.
 local active=waitFor(function()return Attack.GetState(A)end,4,'formal Boss attack session')
 local targetTime=active.StartedAt+math.floor(workspace:GetServerTimeNow()-active.StartedAt)+.85
 if targetTime<=workspace:GetServerTimeNow() then targetTime+=1 end
 waitFor(function()return workspace:GetServerTimeNow()>=targetTime end,2,'scheduled re-entry')
 near(A,a);phase(a,'AttackRunStart')
 local start=a:GetAttribute('SCP096PhaseStartedAt')
 local hit=waitFor(function()local r=Attack.GetState(A);local h=r and r.LastAttack
  return h and h.Hit and h.ActualAt>=start and h end,2,'unchanged damage cadence')
 check(hit.HealthBefore-hit.HealthAfter==25,'Damage25')
 check(hit.ActualAt-start<.6,'Damage wrongly waits for AttackRunStart')
 phase(a,'AttackRun',2)
 report.Cases.Damage={Amount=hit.HealthBefore-hit.HealthAfter,SecondsAfterStart=hit.ActualAt-start,Interval=1}
 near(B,b);phase(b,'AttackRunStart');phase(b,'AttackRun',2)
 task.wait(.8)
 far(A,a);phase(a,'Running');near(A,a);phase(a,'AttackRunStart');phase(a,'AttackRun',2)
 report.Cases.AttackLoopAndReentry=true
 -- Leave both actual actors active for read-only captures; no camera/UI changes.
 workspace:SetAttribute('__SCP096TestPhase','Visual')
 task.wait(30)
 workspace:SetAttribute('__SCP096TestPhase','Lifecycle')
 far(B,b);local peerGeneration=b:GetAttribute('SpawnGeneration')
 local function peer()
  check(actor(B)==b and b:GetAttribute('SpawnGeneration')==peerGeneration and b.Parent,'Peer actor reset')
  check(b:GetAttribute('SCP096Phase')~='Cancelled','Peer animation cancelled')
 end
 local old=a;a=prepare(A);task.wait(.15);keepAlive[A]=nil;targets[A]=nil
 A.Character:FindFirstChildOfClass('Humanoid').Health=0
 waitFor(function()return not a.Parent end,6,'intro death retires actor');peer()
 ready(A);a=prepare(A);check(a~=old,'Retry uses fresh actor');peer()
 local cancelled=a;EM.InitializePlayer(A,1);task.wait(.15)
 check(not cancelled.Parent,'Return reset retires intro');peer()
 a=prepare(A);phase(a,'Running',4);near(A,a);phase(a,'AttackRunStart')
 keepAlive[A]=nil;A.Character:FindFirstChildOfClass('Humanoid').Health=0
 waitFor(function()return not a.Parent end,6,'attack death retires actor');peer()
 ready(A);a=prepare(A);phase(a,'Running',4);near(A,a);phase(a,'AttackRunStart');phase(a,'AttackRun',2)
 EM.Deactivate(A);A:SetAttribute('CurrentWorld',1);targets[A]=nil
 check(not a.Parent,'World return retires attack');peer()
 -- Existing BossCombatService snapshots Strength at encounter start.
 -- Prepare lethal strength before entering, never overwrite that production rule.
 ready(A);a=prepare(A,1e16);phase(a,'Running',4);near(A,a);phase(a,'AttackRunStart')
 task.wait(.3)
 local accepted,reason=EM.TryManualAttack(A)
 check(accepted,'Accepted defeat input '..tostring(reason))
 waitFor(function()return EM.GetPlayerState(A).Defeated[1]==true end,5,'real Boss defeat');peer()
 report.Cases.LifecycleAndPeerIsolation=true
 for _,p in players do local key='Final_'..p.UserId;request:FireClient(p,key,'Report')
  local data=waitFor(function()return replies[key]end,8,'client report').Value
  report.Cases[key]=data
  check(data.ForeignVisible==0,'Foreign Boss became visible')
  check(data.Tracks==0,'Unexpected animation tracks')
  local found={}
  for _,capture in data.Actors do for name,count in capture.Changes do if count>0 and capture.Visible then found[name]=true end end end
  for _,name in {'GetUp_Panic','Panic','Running','AttackRunStart','AttackRun'} do check(found[name],'No client Bone movement for '..name) end
 end
 targets[A]=nil;keepAlive[A]=nil;request:FireClient(A,'Exit','Leave')
 waitFor(function()return A.Parent~=Players end,10,'real test client departure');peer()
 report.Cases.DepartureIsolation=true
end,debug.traceback)
if not ok then table.insert(report.Errors,err) end
report.Success=ok
if not done then done=true;ST:EndTest(report) end
