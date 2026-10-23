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
 local a=prepare(A);far(A,a)
 local aStart=a:GetAttribute('BossIntroStartedAt')
 phase(a,'AttackRunStart',4)
 check(math.abs(a:GetAttribute('SCP096PhaseStartedAt')-aStart-2.5)<.03,'Combined2x intro')
 phase(a,'AttackRun',2)
 local b=prepare(B);far(B,b);phase(b,'AttackRun',4)
 local aRevision,bRevision=a:GetAttribute('SCP096PhaseRevision'),b:GetAttribute('SCP096PhaseRevision')
 local aPivot,bPivot=a:GetPivot(),b:GetPivot()
 task.wait(1.2)
 check((a:GetPivot().Position-aPivot.Position).Magnitude>.3 and (b:GetPivot().Position-bPivot.Position).Magnitude>.3,'Both actors pursue')
 check(not a:GetAttribute('SCP096AttackEligible') and not b:GetAttribute('SCP096AttackEligible'),'Distant pursuit outside hit condition')
 report.Cases.DistantForwardPursuit=true
 near(A,a);near(B,b)
 waitFor(function()return a:GetAttribute('SCP096AttackEligible') and b:GetAttribute('SCP096AttackEligible')end,4,'contact eligibility')
 local contact=workspace:GetServerTimeNow()
 local hit=waitFor(function()local state=Attack.GetState(A);local h=state and state.LastAttack
  return h and h.Hit and h.ActualAt>=contact and h end,3,'existing damage deadline')
 check(hit.HealthBefore-hit.HealthAfter==25,'Damage25')
 report.Cases.Damage={Amount=hit.HealthBefore-hit.HealthAfter,SecondsAfterContact=hit.ActualAt-contact,Interval=1}
 task.wait(.8)
 far(A,a);far(B,b);task.wait(1.2)
 check(a:GetAttribute('SCP096Phase')=='AttackRun' and b:GetAttribute('SCP096Phase')=='AttackRun','Range exit preserves loop')
 check(a:GetAttribute('SCP096PhaseRevision')==aRevision and b:GetAttribute('SCP096PhaseRevision')==bRevision,'Contact cannot restart Start/loop')
 report.Cases.RangeChangesPreserveLoop=true
 for _,p in players do local key='Forward_'..p.UserId;request:FireClient(p,key,'Report')
  local data=waitFor(function()return replies[key]end,8,'client report').Value
  report.Cases[key]=data
  check(data.ForeignVisible==0 and data.Tracks==0,'Visibility/tracks regression')
  local currentGeneration=(p==A and a or b):GetAttribute('SpawnGeneration')
  local first;for _,capture in data.Actors do if capture.Generation==currentGeneration then first=capture;break end end
  check(first and first.Visible,'Body mesh visible flag')
  for _,name in {'GetUp_Panic','Panic','AttackRunStart','AttackRun'} do check((first.Changes[name] or 0)>0,'No client Bone movement for '..name) end
  for _,row in first.Phases do check(row.Phase~='Running','Arms-down Running appeared') end
  for _,keyName in {'Pursuit','Contact'} do
   local arms=first.ArmSamples[keyName]
   check(arms and arms.Count>20 and arms.MinForward>.9 and arms.MaxVertical<.15,'Forward horizontal arms during '..keyName)
  end
 end
 local peerGeneration=b:GetAttribute('SpawnGeneration')
 local old=a;a=prepare(A);far(A,a);phase(a,'AttackRun',4)
 check(a~=old and not old.Parent,'Fresh retry actor')
 check(actor(B)==b and b:GetAttribute('SpawnGeneration')==peerGeneration and b:GetAttribute('SCP096PhaseRevision')==bRevision,'Retry cannot reset peer')
 EM.Deactivate(A);targets[A]=nil;A:SetAttribute('CurrentWorld',1)
 check(not a.Parent and b.Parent and b:GetAttribute('SCP096Phase')=='AttackRun','Return cancels only owner')
 report.Cases.RetryAndPeerIsolation=true
end,debug.traceback)
if not ok then table.insert(report.Errors,err) end
report.Success=ok
if not done then done=true;ST:EndTest(report) end
