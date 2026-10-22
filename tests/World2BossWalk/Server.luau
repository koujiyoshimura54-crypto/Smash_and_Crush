local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local ST=game:GetService("StudioTestService")
local Http=game:GetService("HttpService")
local report={Cases={},Errors={},Fixture="In-memory stores; server-positioned anchored player targets; real combat services and native client animation"}
local request=Instance.new("RemoteEvent",RS);request.Name="WalkTestRequest"
local reply=Instance.new("RemoteEvent",RS);reply.Name="WalkTestReply"
local replies={}
reply.OnServerEvent:Connect(function(p,key,data) replies[key]={Player=p.UserId,Data=data} end)
local function check(ok,message) if not ok then error(message,2) end end
local function waitUntil(fn,seconds)
 local start=os.clock();repeat local value=fn();if value then return value end;task.wait(.1) until os.clock()-start>seconds
end
local function client(p,name,stage,seconds)
 request:FireClient(p,name,"Sample",stage,seconds)
 local value=waitUntil(function()return replies[name]end,(seconds or 2)+12)
 check(value~=nil,"Client reply timeout "..name)
 report.Cases[name]=value.Data;print("WALK_CASE",name,Http:JSONEncode(value.Data))
 return value.Data
end
task.delay(480,function() ST:EndTest({Timeout=true,Report=report}) end)
local ok,err=xpcall(function()
 waitUntil(function()return #Players:GetPlayers()>=2 end,60)
 local list=Players:GetPlayers();check(#list==2,"Two real clients required")
 table.sort(list,function(a,b)return a.Name<b.Name end)
 local PD=require(game.ServerScriptService.Services.PlayerDataService)
 local keepAlive={}
 Run.Heartbeat:Connect(function()
  for p in keepAlive do
   local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if h and h.Health>0 then h.Health=h.MaxHealth end
  end
 end)
 local EM=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
 local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
 check(waitUntil(function()return EM.IsReady()end,45),"EnemyManager startup")
 for _,p in list do
  check(waitUntil(function()return PD.Get(p)end,30),"Data load")
  check(waitUntil(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,30),"Character")
  task.wait(2)
  PD.SetAutoTapEnabled(p,false);p:SetAttribute("CurrentWorld",2)
  keepAlive[p]=true
 end
 local function actor(p,stage)
  return waitUntil(function()
   local f=workspace.World2Enemies:FindFirstChild("Owner_"..p.UserId)
   return f and f:FindFirstChild(("Stage%02d_Enemy"):format(stage))
  end,10)
 end
 local function place(p,position,look)
  local root=p.Character.HumanoidRootPart
  root.Anchored=true;root.CFrame=CFrame.lookAt(position,position+(look or Vector3.zAxis))
  local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
  humanoid.Health=humanoid.MaxHealth
 end
 local function prepare(p,stage,realWalls,afterPower)
  p:SetAttribute("CurrentWorld",2);PD.SetAutoTapEnabled(p,false)
  PD.SetCurrentStrength(p,afterPower or 1)
  EM.InitializePlayer(p,stage)
  local stageModel=workspace.World2Map.BattleCorridor[("Stage%02d"):format(stage)]
  if realWalls then
   local wall=stageModel[("Stage%d.1"):format(stage)].Wall
   place(p,Vector3.new(wall.Position.X,stageModel.Floor.Position.Y+stageModel.Floor.Size.Y/2+3,wall.Position.Z-4))
   PD.SetCurrentStrength(p,1e16)
   task.wait(.3)
   local accepted,reason=EM.TryManualAttack(p)
   check(accepted,"Actual wall attack rejected: "..tostring(reason))
   check(Wall.IsBossUnlockedForStage(p,stage),"Real wall1-4 damage/carry did not clear")
   PD.SetCurrentStrength(p,afterPower or 1)
  else Wall.ApplyDamageForStage(p,stage,1e16) end
  local e=actor(p,stage);check(e,"Actor missing")
  local home=e:GetPivot()
  local floor=stageModel.Floor
  local target=Vector3.new(floor.Position.X+20,floor.Position.Y+floor.Size.Y/2+3,floor.Position.Z)
  place(p,target)
  task.wait(.5)
  return e,home,stageModel
 end
 local movingTargets={}
 if type(ST:GetTestArgs())=="table" and ST:GetTestArgs().OnlyKill then
  local p=list[1]
  local e,_,stageModel=prepare(p,5,true,1e16)
  task.wait(3.2)
  local BC=require(game.ServerScriptService.World.BossCombatService).ForWorld(2)
  local function snapshot()
   local s=BC.Get(p)
   return {Strength=p:GetAttribute("Strength"),HP=s and s.HP,Damage=s and s.BattleDamage,Route=s and s.Route,
    Attacks=s and s.Attacks,WallIndex=Wall.GetCurrentIndexForStage(p,5),Fighting=p:GetAttribute("IsFighting"),
    Type=p:GetAttribute("CombatType"),ActorAlive=e.Parent~=nil,Stage=p:GetAttribute("World2CurrentStage")}
  end
  report.Cases.KillBefore=snapshot()
  local c=e.MiniBossCollider.Position
  place(p,Vector3.new(c.X,stageModel.Floor.Position.Y+stageModel.Floor.Size.Y/2+3,c.Z-e.MiniBossCollider.Size.Z/2-1))
  task.wait(.3)
  report.Cases.KillAtContact=snapshot()
  local accepted,reason=EM.TryManualAttack(p)
  report.Cases.KillRequest={Accepted=accepted,Reason=reason}
  task.wait(.8);report.Cases.KillAfter=snapshot()
  return
 end
 Run.Heartbeat:Connect(function()
  for p,data in movingTargets do
   if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
    local floor=data.Floor
    local t=os.clock()-data.Start
    local pos=floor.CFrame:PointToWorldSpace(Vector3.new(math.sin(t*.9)*floor.Size.X*.3,
     floor.Size.Y/2+3,math.cos(t*.7)*floor.Size.Z*.3))
    place(p,pos)
   end
  end
 end)
 local stageList=type(ST:GetTestArgs())=="table" and ST:GetTestArgs().LifecycleOnly and {} or {1,3,5,8,10}
 if type(ST:GetTestArgs())=="table" and ST:GetTestArgs().Stage5Only then stageList={5} end
 for _,stage in stageList do
  table.clear(movingTargets)
  for _,p in list do prepare(p,stage,stage==5) end
  for _,p in list do movingTargets[p]={Floor=workspace.World2Map.BattleCorridor[("Stage%02d"):format(stage)].Floor,Start=os.clock()} end
  local p=list[1];local e=actor(p,stage)
  if stage==5 then
   report.Cases.IntroDuration=e:GetAttribute("BossIntroDuration")
   local duplicateStart=e:GetAttribute("BossIntroStartedAt")
   require(game.ServerScriptService.World.BossChaseService).ForWorld(2).BeginIntro(e)
   check(e:GetAttribute("BossIntroStartedAt")==duplicateStart,"Duplicate intro restarted")
   client(p,"049Intro",stage,1.5)
   task.wait(2)
   report.Cases.IntroElapsed=e:GetAttribute("BossIntroElapsed")
   check(e:GetAttribute("BossIntroState")=="Completed","Intro not completed")
  end
  print("WALK_VISUAL_STAGE",stage)
  RS:SetAttribute("__WalkCameraStartedAt",workspace:GetServerTimeNow())
  local a=client(p,"Stage"..stage.."Moving",stage,12)
  check(a.JointRadians>.02 and a.LimbRadians>.02,"No real joint/limb movement Stage"..stage)
  local peer=client(list[2],"Stage"..stage.."Peer",stage,.7)
  check(peer.JointRadians>.01,"Peer animation missing")
  report.Cases["Speed"..stage]={Speed=e:GetAttribute("ChaseSpeed"),Turn=e:GetAttribute("ChaseTurnResponse")}
 end
 if type(ST:GetTestArgs())=="table" and ST:GetTestArgs().Stage5Only then
  local e=actor(list[1],5);local visual=e:FindFirstChild("SCP-049")
  report.Cases.Thighs={}
  for _,side in {"Left","Right"} do
   local leg=visual[side.."UpperLeg"]
   report.Cases.Thighs[side]={Texture=leg.TextureID,Color={leg.Color.R,leg.Color.G,leg.Color.B},Transparency=leg.Transparency}
   check(leg.TextureID=="" and leg.Color.R<.2,"Pale thigh texture/color retained")
  end
  return
 end
 print("WALK_MATRIX_DONE")
 table.clear(movingTargets)
 local a,b=list[1],list[2]
 local function identity(p)
  local e=actor(p,5)
  return {Actor=e,Run=p:GetAttribute("World2RunId"),Generation=e:GetAttribute("SpawnGeneration"),HP=EM.GetPlayerState(p).Gauges[5]}
 end
 local function peerUnchanged(before)
  local after=identity(b)
  check(after.Actor==before.Actor and after.Run==before.Run and after.Generation==before.Generation and after.HP==before.HP,"Other player's encounter changed")
 end
 -- Same-stage intro interruption by real death, with another player's clip active.
 prepare(a,5,true);prepare(b,5,true)
 local peer=identity(b)
 local old=actor(a,5)
 a.Character:FindFirstChildOfClass("Humanoid").Health=0
 check(waitUntil(function()return not old.Parent end,5),"Dead owner's actor retained")
 task.wait(3.3);peerUnchanged(peer)
 report.Cases.DeathDuringIntro={OldActorRemoved=true,PeerUnchanged=true,PeerIntro=peer.Actor:GetAttribute("BossIntroState")}
 check(waitUntil(function()local c=a.Character;local h=c and c:FindFirstChildOfClass("Humanoid");return h and h.Health>0 end,15),"Respawn timeout")
 task.wait(1)
 -- New challenge may play once again. No old completion can unlock it early.
 local fresh=prepare(a,5,true)
 check(fresh~=old and fresh:GetAttribute("BossIntroState")=="Playing","Fresh intro not created")
 local started=fresh:GetAttribute("BossIntroStartedAt")
 local home=fresh:GetPivot()
 task.wait(.3)
 check(fresh:GetAttribute("BossIntroState")=="Playing","Fresh intro completed too early")
 check((fresh:GetPivot().Position-home.Position).Magnitude<.01,"Intro chase moved")
 peerUnchanged(peer)
 -- Reset/Back path cancels only A; then prove five fresh clones do not accumulate.
 EM.ResetPlayer(a);check(not fresh.Parent,"Reset did not retire intro actor")
 for cycle=1,5 do
  local e=prepare(a,5,true)
  check(e:GetAttribute("BossIntroState")=="Playing","Intro reuse in cycle"..cycle)
  check(e:GetAttribute("BossIntroStartedAt")~=started,"Old intro timestamp reused")
  local visual=e:FindFirstChild("SCP-049")
  local count=0;for _,x in visual:GetDescendants() do if x:IsA("Motor6D") then count+=1 end end
  check(count==15,"Rig correction accumulated motors")
  report.Cases["FreshRig"..cycle]={Motors=count,Scale=visual:GetScale()}
  EM.ResetPlayer(a);peerUnchanged(peer)
 end
 -- World exit cancels the current intro without altering the peer.
 local exiting=prepare(a,5,true)
 a:SetAttribute("CurrentWorld",1)
 task.wait(.4)
 check(not exiting.Parent or exiting:GetAttribute("BossIntroState")~="Playing","World exit kept playing")
 peerUnchanged(peer)
 report.Cases.WorldExitDuringIntro={Cancelled=true,PeerUnchanged=true}
 -- Stop in contact, move again, then let the same owner actor walk home.
 a:SetAttribute("CurrentWorld",2)
 local walking,originalHome,stageModel=prepare(a,5,true)
 task.wait(3.2)
 local floor=stageModel.Floor
 local collider=walking.MiniBossCollider
 local center=collider.Position
 local root=a.Character.HumanoidRootPart
 local distance=collider.Size.Z/2+root.Size.Z/2+.8
 place(a,Vector3.new(center.X,floor.Position.Y+floor.Size.Y/2+3,center.Z-distance))
 task.wait(1)
 local stopped=client(a,"ContactStop",5,.8)
 report.Cases.ContactServer={Mode=walking:GetAttribute("ChaseState"),Target=walking:GetAttribute("ChaseTargetUserId"),Motion=walking:GetAttribute("BossMotionSpeed")}
 check(stopped.Animation=="Stopped" and stopped.Tracks==0,"Contact kept walking")
 movingTargets[a]={Floor=floor,Start=os.clock()}
 local again=client(a,"MoveAgain",5,2)
 movingTargets[a]=nil
 check(again.JointRadians>.02,"Walk did not resume")
 place(a,Vector3.new(floor.Position.X,floor.Position.Y+floor.Size.Y/2+3,floor.Position.Z-floor.Size.Z))
 local returning=client(a,"ReturnHome",5,.8)
 check(returning.Animation=="Walk" or returning.Moved<1,"Return animation missing")
 task.wait(4)
 report.Cases.ReturnSettled={Mode=walking:GetAttribute("ChaseState"),Motion=walking:GetAttribute("BossMotionSpeed"),Intro=walking:GetAttribute("BossIntroState")}
 check(walking:GetAttribute("BossIntroStartedAt")~=nil,"Intro identity lost")
 peerUnchanged(peer)
 -- Real accepted Boss kill while the peer keeps its own actor/HP/run.
 local victim=prepare(a,5,true,1e16);task.wait(3.2)
 PD.SetCurrentStrength(a,1e16)
 local c=victim.MiniBossCollider.Position
 place(a,Vector3.new(c.X,floor.Position.Y+floor.Size.Y/2+3,c.Z-victim.MiniBossCollider.Size.Z/2-1))
 task.wait(.3)
 local accepted,reason=EM.TryManualAttack(a)
 check(accepted and reason=="Combat","Boss defeat attack rejected: "..tostring(reason))
 check(waitUntil(function()return not victim.Parent end,3),"Defeated actor retained")
 peerUnchanged(peer);report.Cases.DefeatPeerIsolation=true
 -- Representative actual World1 actor retains its existing 16/4 locomotion.
 a:SetAttribute("CurrentWorld",1)
 local W1=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
 W1.InitializePlayer(a,1)
 task.wait(.5)
 local owner=workspace.Enemies:FindFirstChild("Owner_"..a.UserId)
 local w1=owner and owner:FindFirstChild("Stage01_Enemy")
 check(w1 and w1:GetAttribute("ChaseSpeed")==16 and w1:GetAttribute("ChaseTurnResponse")==4,"World1 movement changed")
 report.Cases.World1={Speed=16,Turn=4,World2RigAttribute=w1:GetAttribute("World2RigVersion")}
 local first=w1:GetPivot().Position
 require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1).ApplyDamageForStage(a,1,1e16)
 local originalFloor=workspace.GeneratedMap.BattleCorridor.Stage01.Floor
 place(a,originalFloor.Position+Vector3.new(0,originalFloor.Size.Y/2+3,0))
 task.wait(1.5)
 report.Cases.World1.Moved=(w1:GetPivot().Position-first).Magnitude
 check(report.Cases.World1.Moved>1,"World1 representative movement missing")
 -- A actual client departure leaves B's living challenge unchanged.
 movingTargets[b]={Floor=workspace.World2Map.BattleCorridor.Stage05.Floor,Start=os.clock()}
 request:FireClient(a,"Leave","Leave",5,0)
 check(waitUntil(function()return a.Parent~=Players end,10),"Client departure timeout")
 peerUnchanged(peer)
 report.Cases.DeparturePeerIsolation=true
 local final=client(b,"PeerAfterDeparture",5,1)
 check(not final.Error and final.JointRadians>.02,"Peer lost its ongoing animation")
end,debug.traceback)
if not ok then table.insert(report.Errors,err);warn("WALK_TEST_ERROR",err) end
print("WALK_REPORT_JSON "..Http:JSONEncode(report))
ST:EndTest(report)
