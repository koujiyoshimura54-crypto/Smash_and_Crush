-- Temporary QA: prepared Strength/positions; real server combat, remotes and native clients.
local Players=game.Players
local RS=game.ReplicatedStorage
local ST=game:GetService("StudioTestService")
local Http=game.HttpService
local report={Mode="Prepared isolated native two-client tests; no natural progression timing",Stages={},Lifecycle={},Errors={}}
local request=Instance.new("RemoteEvent",RS);request.Name="__HPWallsRequest"
local reply=Instance.new("RemoteEvent",RS);reply.Name="__HPWallsReply"
local replies,ready={},{}
reply.OnServerEvent:Connect(function(p,key,value) if key=="Ready" then ready[p]=true else replies[key]={Player=p,Value=value} end end)
local function waitFor(fn,seconds,label)
 local deadline=os.clock()+seconds
 repeat local value=fn();if value then return value end;task.wait(.05) until os.clock()>deadline
 error("Timeout: "..label)
end
local serial=0
local function rpc(p,action,args)
 serial+=1;local key=tostring(serial);request:FireClient(p,key,action,args)
 local value=waitFor(function()return replies[key]end,18,"client "..action).Value
 assert(value.Success,value.Result);replies[key]=nil;return value.Result
end
local function post(name,value)
 local r=Http:RequestAsync({Url="http://127.0.0.1:18766/"..name,Method="POST",Headers={["Content-Type"]="application/json"},Body=Http:JSONEncode(value)})
 assert(r.Success)
end
local done=false
task.delay(540,function()if not done then done=true;ST:EndTest({Timeout=true,Report=report})end end)
local ok,err=xpcall(function()
 waitFor(function()return #Players:GetPlayers()==2 end,50,"two clients")
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local A,B=players[1],players[2]
 local PD=require(game.ServerScriptService.Services.PlayerDataService)
 local WallModule=require(game.ServerScriptService.World.Stage1WallManager)
 local EnemyModule=require(game.ServerScriptService.World.EnemyManager)
 local BossModule=require(game.ServerScriptService.World.BossCombatService)
 local ChaseModule=require(game.ServerScriptService.World.BossChaseService)
 local StageModule=require(game.ServerScriptService.World.StageManager)
 local TrophyModule=require(game.ServerScriptService.Services.TrophyRewardService)
 local format=require(RS.Modules.NumberFormat)
 local cfg=require(RS.Config.World2Config)
 local bossHP={15000000,30000000,75000000,150000000,500000000,1000000000,5000000000,15000000000,45000000000,150000000000}
 local keepAlive={}
 game:GetService("RunService").Heartbeat:Connect(function()
  for p in keepAlive do local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h and h.Health>0 then h.Health=h.MaxHealth end end
 end)
 local function living(p)
  return waitFor(function()return PD.IsLoaded(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
   and p.Character:FindFirstChildOfClass("Humanoid").Health>0 and p.Character:GetAttribute("MuscleScaleReady") and p.Character end,35,"living ready character")
 end
 for _,p in players do assert(p.UserId<=0);living(p);waitFor(function()return ready[p]end,30,"QA client ready");PD.SetAutoTapEnabled(p,false);keepAlive[p]=true end
 local function service(world) return EnemyModule.ForWorld(world),WallModule.ForWorld(world) end
 local function model(world,n) return workspace[world==2 and "World2Map" or "GeneratedMap"].BattleCorridor[("Stage%02d"):format(n)] end
 local function actor(p,world,n) return EnemyModule.ForWorld(world).GetEnemy(n,p) end
 local function place(p,world,n,pos)
  local ch=living(p);local root=ch.HumanoidRootPart;local hum=ch:FindFirstChildOfClass("Humanoid")
  local floor=model(world,n).Floor;local y=floor.Position.Y+floor.Size.Y/2+hum.HipHeight+root.Size.Y/2+.05
  root.Anchored=true;root.CFrame=CFrame.lookAt(Vector3.new(pos.X,y,pos.Z),Vector3.new(pos.X,y,pos.Z+1))
  root.AssemblyLinearVelocity=Vector3.zero
 end
 local function prepare(p,world,n)
  living(p);PD.SetAutoTapEnabled(p,false);p:SetAttribute("CurrentWorld",world)
  local EM,Wall=service(world);waitFor(function()return EM.IsReady()end,40,"combat ready")
  EM.InitializePlayer(p,n);task.wait(.2)
  local e=waitFor(function()return actor(p,world,n)end,10,"fresh Boss")
  place(p,world,n,model(world,n)[("Stage%d.1"):format(n)].Wall.Position-Vector3.zAxis*12)
  local snap=rpc(p,"Resync",{World=world,Stage=n,Count=Wall.GetWallCount(n)})
  assert(snap.State and snap.State.Current==1 and #snap.State.Gauges==Wall.GetWallCount(n),"initial snapshot count")
  return e
 end
 local function hit(p,world,n,index,damage)
  local EM,Wall=service(world);local wall=model(world,n)[("Stage%d.%d"):format(n,index)].Wall
  assert(PD.SetCurrentStrength(p,damage));task.wait(.12)
  place(p,world,n,wall.Position-Vector3.zAxis*4)
  task.wait(.55)
  local accepted,reason=EM.TryManualAttack(p)
  assert(accepted,"Attack rejected: "..tostring(reason))
  task.wait(.12)
  return rpc(p,"Snapshot",{World=world,Stage=n,Count=Wall.GetWallCount(n)})
 end
 -- All 55 walls: exact HP, partial damage, HP text, personal collision and final unlock.
 for n=1,10 do
  local e=prepare(A,2,n);local EM,Wall=service(2);local count=n<=5 and 5 or 6
  assert(Wall.GetWallCount(n)==count and cfg.Stages[n].BossMaxHP==bossHP[n])
  assert(e:GetAttribute("BossMaxHP")==bossHP[n] and cfg.Stages[n].RequiredStrength==bossHP[n]/5)
  local row={Count=count,BossHP=e:GetAttribute("BossMaxHP"),Walls={}}
  for i=1,count do
   local hp=bossHP[n]*(.3+.1*i);assert(math.abs(Wall.GetStageConfig(n).Walls[i]-hp)<.01)
   hp=Wall.GetStageConfig(n).Walls[i]
   local half=hit(A,2,n,i,hp/2)
   assert(Wall.GetGaugeForStage(A,n,i)==hp/2 and Wall.GetCurrentIndexForStage(A,n)==i)
   assert(not Wall.IsBossUnlockedForStage(A,n),"premature unlock")
   local expectedText=string.format(require(RS.Modules.Config).Stages.Health.format,format.Format(hp/2),format.Format(hp))
   assert(half.Walls[i].Text==expectedText,"half HP text: "..tostring(half.Walls[i].Text).." expected "..expectedText)
   assert(half.Walls[i].Enabled and half.Walls[i].Collide and not half.Walls[i].Hidden,"active wall rendering")
   if i>=4 then assert(not e:GetAttribute("BossIntroStartedAt"),"early intro") end
   local cleared=hit(A,2,n,i,hp/2)
   assert(Wall.GetCurrentIndexForStage(A,n)==i+1 and cleared.State.Current==i+1)
   assert(cleared.Walls[i].Hidden and not cleared.Walls[i].Collide and not cleared.Walls[i].Enabled,"clear render/collision")
   assert(Wall.IsBossUnlockedForStage(A,n)==(i==count),"unlock boundary")
   if i<count then assert(not e:GetAttribute("BossIntroStartedAt"),"intro before last wall") end
   row.Walls[i]={HP=hp,HalfText=half.Walls[i].Text,Cleared=true,Unlocked=i==count}
  end
  assert(EM.GetGauge(A,n)==bossHP[n],"wall overflow damaged Boss")
  if n==1 or n==5 then
   assert(e:GetAttribute("BossIntroStartedAt"),"missing final-wall intro")
   row.IntroStartedAt=e:GetAttribute("BossIntroStartedAt")
  end
  local finalWall=model(2,n)[("Stage%d.%d"):format(n,count)].Wall
  place(A,2,n,finalWall.Position+Vector3.new(15,0,16))
  waitFor(function()return e:GetAttribute("ChaseTargetUserId")==A.UserId end,9,"final-wall owner recognition")
  row.Chase=e:GetAttribute("ChaseState")
  local resync=rpc(A,"Resync",{World=2,Stage=n,Count=count})
  assert(resync.State.Current==count+1 and resync.State.Cleared[count],"final resync")
  report.Stages[n]=row;post("progress.json",report)
 end
 -- Carry reaches new walls and discards final surplus; it never starts the Boss damaged.
 for _,n in {5,6,10} do
  local e=prepare(A,2,n);local EM,Wall=service(2);local sum=0
  for _,hp in Wall.GetStageConfig(n).Walls do sum+=hp end
  local snap=hit(A,2,n,1,sum+12345)
  assert(Wall.IsBossUnlockedForStage(A,n) and snap.State.Current==Wall.GetWallCount(n)+1)
  assert(EM.GetGauge(A,n)==bossHP[n],"final surplus reached Boss")
  report.Lifecycle["Carry"..n]=true
 end
 -- Same-Stage two-client isolation, partial death, combat death, actual Trophy pickup/return.
 for _,n in {5,6} do
  local ea,eb=prepare(A,2,n),prepare(B,2,n);local EM,Wall=service(2);local count=Wall.GetWallCount(n)
  hit(B,2,n,1,Wall.GetStageConfig(n).Walls[1]/2)
  local peerHP=Wall.GetGaugeForStage(B,n,1);local peerGeneration=eb:GetAttribute("SpawnGeneration")
  local function peer()
   assert(actor(B,2,n)==eb and eb:GetAttribute("SpawnGeneration")==peerGeneration)
   assert(Wall.GetCurrentIndexForStage(B,n)==1 and Wall.GetGaugeForStage(B,n,1)==peerHP)
   local snap=rpc(B,"Snapshot",{World=2,Stage=n,Count=count})
   assert(snap.Walls[count].Collide and not snap.Walls[count].Hidden and snap.State.Current==1,"peer wall affected")
  end
  local sum=0;for i=1,count-1 do sum+=Wall.GetStageConfig(n).Walls[i] end
  hit(A,2,n,1,sum+Wall.GetStageConfig(n).Walls[count]/2)
  assert(Wall.GetCurrentIndexForStage(A,n)==count and not Wall.IsBossUnlockedForStage(A,n));peer()
  local old=A.Character;keepAlive[A]=nil;old:FindFirstChildOfClass("Humanoid").Health=0
  waitFor(function()return A.Character~=old and A.Character and A.Character:FindFirstChildOfClass("Humanoid") and A.Character:FindFirstChildOfClass("Humanoid").Health>0 end,25,"wall death respawn")
  living(A);keepAlive[A]=true
  for k=1,10 do assert(Wall.GetCurrentIndexForStage(A,k)==1 and Wall.GetGaugeForStage(A,k,Wall.GetWallCount(k))==Wall.GetStageConfig(k).Walls[Wall.GetWallCount(k)]) end
  local reset=rpc(A,"Resync",{World=2,Stage=n,Count=count});assert(reset.Walls[count].Collide and not reset.Walls[count].Hidden);peer()
  ea=prepare(A,2,n);sum=0;for _,hp in Wall.GetStageConfig(n).Walls do sum+=hp end
  hit(A,2,n,1,sum+1)
  PD.SetCurrentStrength(A,1);task.wait(.2)
  local pos=ea:GetPivot().Position;place(A,2,n,pos)
  waitFor(function()return BossModule.ForWorld(2).Get(A)end,10,"Boss encounter")
  assert(BossModule.ForWorld(2).Get(A).HP==bossHP[n],"Boss initial HP")
  old=A.Character;keepAlive[A]=nil;old:FindFirstChildOfClass("Humanoid").Health=0
  waitFor(function()return A.Character~=old and A.Character and A.Character:FindFirstChildOfClass("Humanoid") and A.Character:FindFirstChildOfClass("Humanoid").Health>0 end,25,"Boss death respawn")
  living(A);keepAlive[A]=true;assert(Wall.GetCurrentIndexForStage(A,n)==1);peer()
  ea=prepare(A,2,n);hit(A,2,n,1,sum+1)
  PD.SetCurrentStrength(A,bossHP[n]*2);task.wait(.2);place(A,2,n,ea:GetPivot().Position)
  waitFor(function()return BossModule.ForWorld(2).Get(A)end,10,"winning Boss encounter")
  task.wait(.6);assert(EM.TryManualAttack(A))
  waitFor(function()return EM.GetPlayerState(A).Defeated[n]end,6,"accepted Boss defeat")
  task.wait(.5)
  local Trophy=TrophyModule.ForWorld(2);local previous=Trophy.GetStudioCollectionCounts(A).Total
  local button=model(2,n).TrophyNormalButton.Handle
  A.Character.HumanoidRootPart.CFrame=button.CFrame
  waitFor(function()return Trophy.GetStudioCollectionCounts(A).Total>previous end,12,"actual Trophy overlap")
  waitFor(function()return StageModule.ForWorld(2).GetCurrentStageNumber(A)==1 and Wall.GetCurrentIndexForStage(A,n)==1 end,15,"Trophy return reset")
  peer();ea=prepare(A,2,n)
  local again=rpc(A,"Resync",{World=2,Stage=n,Count=count})
  assert(again.Walls[count].Collide and not again.Walls[count].Hidden);peer()
  report.Lifecycle["TwoClientStage"..n]={PartialDeath=true,BossDeath=true,TrophyReturn=true,Retry=true,PeerUnaffected=true}
  post("progress.json",report)
 end
 -- World1's authority and four-wall unlock stay unchanged.
 local e=prepare(A,1,1);local EM,Wall=service(1)
 assert(Wall.GetWallCount(1)==4)
 for i=1,4 do
  hit(A,1,1,i,Wall.GetStageConfig(1).Walls[i])
  assert(Wall.IsBossUnlockedForStage(A,1)==(i==4))
 end
 report.World1={Count=4,BossHP=e:GetAttribute("BossMaxHP") or EM.GetGauge(A,1),FinalUnlock=true}
 report.IsolatedWrites=require(RS.__HPWallsMemory).Writes
end,debug.traceback)
if not ok then table.insert(report.Errors,err) end
report.Success=ok
post("native-result.json",report)
if not done then done=true;ST:EndTest(report) end
