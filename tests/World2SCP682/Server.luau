local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local ST=game:GetService("StudioTestService")
local H=game:GetService("HttpService")
local report={Cases={},Errors={},Fixture="Two native clients; in-memory stores and payment mocks; server-driven test inputs"}
local request=Instance.new("RemoteEvent",RS);request.Name="FourRequest"
local reply=Instance.new("RemoteEvent",RS);reply.Name="FourReply"
local replies={};reply.OnServerEvent:Connect(function(p,key,data)replies[key]={Player=p,Data=data}end)
local function check(ok,msg)if not ok then error(msg,2)end end
local function waitFor(fn,seconds)
 local deadline=os.clock()+seconds;repeat local v=fn();if v then return v end;task.wait(.1) until os.clock()>deadline
end
task.delay(220,function()ST:EndTest({Timeout=true,Report=report})end)
local ok,err=xpcall(function()
 check(waitFor(function()return #Players:GetPlayers()==2 end,60),"Two clients missing")
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.Name<b.Name end)
 local PD=require(game.ServerScriptService.Services.PlayerDataService)
 local EM=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
 local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
 check(waitFor(function()return EM.IsReady()end,45),"EnemyManager startup")
 local targets={};local alive={}
 local function place(p,pos)
  local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  if root then root.Anchored=true;root.CFrame=CFrame.lookAt(pos,pos+Vector3.zAxis) end
 end
 Run.Heartbeat:Connect(function()
  for p in alive do local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h and h.Health>0 then h.Health=h.MaxHealth end end
  for p,t in targets do
   local f=t.Floor;local time=os.clock()-t.Start
   place(p,f.CFrame:PointToWorldSpace(Vector3.new(math.sin(time*.9)*f.Size.X*.30,f.Size.Y/2+3,math.cos(time*.7)*f.Size.Z*.30)))
  end
 end)
 for _,p in players do
  check(waitFor(function()return PD.Get(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,45),"Player load")
  task.wait(2);PD.SetAutoTapEnabled(p,false);p:SetAttribute("CurrentWorld",2);alive[p]=true
 end
 local function actor(p,stage)
  return waitFor(function()local f=workspace.World2Enemies:FindFirstChild("Owner_"..p.UserId);return f and f:FindFirstChild(("Stage%02d_Enemy"):format(stage))end,10)
 end
 local function prepare(p,stage,power)
  targets[p]=nil;p:SetAttribute("CurrentWorld",2);PD.SetCurrentStrength(p,power or 1);EM.InitializePlayer(p,stage)
  local map=workspace.World2Map.BattleCorridor[("Stage%02d"):format(stage)];local f=map.Floor
  if stage==5 then
   local w=map["Stage5.1"].Wall;place(p,Vector3.new(w.Position.X,f.Position.Y+f.Size.Y/2+3,w.Position.Z-4))
   PD.SetCurrentStrength(p,1e16);task.wait(.35)
   local accepted=EM.TryManualAttack(p);check(accepted and Wall.IsBossUnlockedForStage(p,stage),"049 real Wall4 attack failed")
   PD.SetCurrentStrength(p,1)
  else Wall.ApplyDamageForStage(p,stage,1e16) end
  local e=actor(p,stage);check(e,"Missing actor")
  targets[p]={Floor=f,Start=os.clock()};return e,map
 end
 local function sample(p,key,stage,seconds,view)
  replies[key]=nil;request:FireClient(p,key,"Sample",stage,seconds,view)
 end
 local function result(key,seconds)
  local r=waitFor(function()return replies[key]end,seconds or 20);check(r,"Client sample timeout "..key)
  report.Cases[key]=r.Data;check(not r.Data.Error,r.Data.Error);return r.Data
 end
 local options=ST:GetTestArgs()
 for _,stage in options.Stages do
  table.clear(targets)
  local actors={};local map
  for _,p in players do actors[p],map=prepare(p,stage) end
  if stage==5 then
   local e=actors[players[2]];local before=e:GetPivot()
   check(e:GetAttribute("BossIntroState")=="Playing","049 intro did not start after real Wall4")
   task.wait(.3);check((e:GetPivot().Position-before.Position).Magnitude<.01,"049 moved during intro")
   task.wait(3);report.Cases.IntroSeconds=e:GetAttribute("BossIntroElapsed")
   check(e:GetAttribute("BossIntroState")=="Completed","049 intro completion")
   report.Cases.BlackThighs={}
   for _,side in {"Left","Right"} do
    local leg=e["SCP-049"][side.."UpperLeg"];local appearance=leg:FindFirstChildOfClass("SurfaceAppearance")
    check(leg.Color.R<.2 and appearance and appearance.Color.R<.2,"049 thigh color")
    report.Cases.BlackThighs[side]={Color=leg.Color.R,SurfaceAppearanceColor=appearance.Color.R}
   end
  end
  if options.Capture~=false then
  for _,view in {"Front","Side","Normal"} do
   for _,p in players do sample(p,"S"..stage.."_"..p.Name.."_"..view,stage,12,view) end
   for _,p in players do
    local value=result("S"..stage.."_"..p.Name.."_"..view)
    check(value.VisibleLimbRadians>.15,"Visible limbs did not move stage "..stage.." "..p.Name)
    check(value.ForeignVisibleParts==0,"Peer visual visible")
   end
  end
  end
  report.Cases["Balance"..stage]={Speed=actors[players[1]]:GetAttribute("ChaseSpeed"),Turn=actors[players[1]]:GetAttribute("ChaseTurnResponse")}
  if options.Mode=="Full" then
   local a,b=players[1],players[2];local walking=actors[a];local floor=map.Floor
   local peer={Actor=actors[b],Run=b:GetAttribute("World2RunId"),Generation=actors[b]:GetAttribute("SpawnGeneration"),HP=EM.GetPlayerState(b).Gauges[stage]}
   local function unchanged()
    check(actor(b,stage)==peer.Actor and b:GetAttribute("World2RunId")==peer.Run and peer.Actor:GetAttribute("SpawnGeneration")==peer.Generation and EM.GetPlayerState(b).Gauges[stage]==peer.HP,"Peer encounter changed")
   end
   local function one(p,name,duration)
    if p==b then
     targets[b]=nil
     local relative=floor.CFrame:PointToObjectSpace(peer.Actor.HumanoidRootPart.Position)
     place(b,floor.CFrame:PointToWorldSpace(Vector3.new(relative.X>0 and -35 or 35,floor.Size.Y/2+3,relative.Z>20 and -20 or 60)))
     task.wait(.2)
    end
    local key="S"..stage.."_"..name;sample(p,key,stage,duration or 1,"Side");local r=result(key);check(not r.Error,r.Error);return r
   end
   targets[a]=nil
   local collider=walking.MiniBossCollider;local c=collider.Position
   place(a,Vector3.new(c.X,floor.Position.Y+floor.Size.Y/2+3,c.Z-collider.Size.Z/2-a.Character.HumanoidRootPart.Size.Z/2-.8))
   task.wait(1)
   local stop=one(a,"ContactStop",.8)
   check(stop.Animation=="Stopped" and stop.VisibleLimbRadians<.03,"Contact did not settle")
   unchanged();check(one(b,"PeerDuringStop",1).VisibleLimbRadians>.15,"Peer stopped with A")
   targets[a]={Floor=floor,Start=os.clock()}
   check(one(a,"Restart",1.5).VisibleLimbRadians>.15,"Restart failed")
   targets[a]=nil
   place(a,Vector3.new(floor.Position.X,floor.Position.Y+floor.Size.Y/2+3,floor.Position.Z-floor.Size.Z))
   local returning=one(a,"Return",.8)
   check(returning.Animation=="Walk" or returning.VisibleLimbRadians>.15 or returning.Moved<1,"Return walk missing")
   task.wait(5);unchanged()
   local settled=one(a,"HomeSettled",.5);check(settled.VisibleLimbRadians<.03,"Home kept walking")
   -- Real death and the existing respawn path, using only the in-memory profile.
   local old=prepare(a,stage);alive[a]=nil;targets[a]=nil
   a.Character:FindFirstChildOfClass("Humanoid").Health=0
   check(waitFor(function()return not old.Parent end,5),"Death retained old actor")
   unchanged();check(one(b,"PeerDuringDeath",1).VisibleLimbRadians>.15,"Peer stopped on death")
   check(waitFor(function()local h=a.Character and a.Character:FindFirstChildOfClass("Humanoid");return h and h.Health>0 end,20),"Respawn timeout")
   task.wait(1);alive[a]=true
   for cycle=1,2 do
    local fresh=prepare(a,stage);check(fresh~=old,"Actor reused")
    local retry=one(a,"Retry"..cycle,1)
    check(retry.VisibleLimbRadians>.15 and retry.Bones==32 and retry.Motors==0 and retry.Tracks==0,"Retry animation/rig accumulation")
    targets[a]=nil;EM.ResetPlayer(a);check(not fresh.Parent,"Reset retained actor");unchanged();old=fresh
   end
   local exiting=prepare(a,stage);targets[a]=nil;a:SetAttribute("CurrentWorld",1);task.wait(.5)
   local outside=one(a,"WorldExit",.5)
   check(outside.VisibleLimbRadians<.03 and outside.Tracks==0 and outside.Records.Active==0,"World exit retained animation");unchanged()
   -- A real accepted combat attack, not direct actor deletion.
   local victim=prepare(a,stage,1e16);targets[a]=nil
   local hit=victim.MiniBossCollider;local hitPos=hit.Position
   place(a,Vector3.new(hitPos.X,floor.Position.Y+floor.Size.Y/2+3,hitPos.Z-hit.Size.Z/2-1));task.wait(.4)
   local accepted,reason=EM.TryManualAttack(a)
   check(accepted and reason=="Combat","Defeat rejected "..tostring(reason))
   check(waitFor(function()return not victim.Parent end,4),"Defeat retained actor");unchanged()
   check(one(b,"PeerAfterDefeat",1).VisibleLimbRadians>.15,"Peer stopped on defeat")
   local previewKey="Preview9";request:FireClient(a,previewKey,"Preview",9,0);local pv=result(previewKey,20);check(pv.VisibleJointsChanged>=4,"Skin Preview failed")
   local representative=prepare(a,4);local key="SharedStage4";sample(a,key,4,3,"Side");check(result(key).VisibleLimbRadians>.15,"Existing shared Stage4 gait failed");unchanged()
   request:FireClient(a,"Leave","Leave",stage,0)
   check(waitFor(function()return a.Parent~=Players end,12),"Client departure timeout");unchanged()
   check(one(b,"PeerAfterDeparture",1.5).VisibleLimbRadians>.15,"Peer stopped on departure")
   report.Cases["Lifecycle"..stage]={Contact=true,Restart=true,Return=true,Death=true,Retries=2,WorldExit=true,RealDefeat=true,RealDeparture=true,PeerUnchanged=true}
  end
 end
 table.clear(targets)
 if options.Mode=="Regression" then
  local a,b=players[1],players[2]
  for _,stage in {2,4,6,7} do
   local key="Preview"..stage;request:FireClient(a,key,"Preview",stage,0)
   local value=result(key,25);check(value.VisibleJointsChanged>=4,"Preview did not move visible limbs")
  end
  local old=prepare(a,5);local peer=prepare(b,5);targets[a]=nil;targets[b]=nil
  a.Character:FindFirstChildOfClass("Humanoid").Health=0
  check(waitFor(function()return not old.Parent end,5),"049 interrupted actor retained")
  check(waitFor(function()local h=a.Character and a.Character:FindFirstChildOfClass("Humanoid");return h and h.Health>0 end,20),"049 respawn")
  task.wait(1);local fresh=prepare(a,5);check(fresh:GetAttribute("BossIntroState")=="Playing","049 retry intro")
  task.wait(3.3);check(fresh:GetAttribute("BossIntroState")=="Completed" and peer.Parent,"049 retry/peer")
  report.Cases.IntroInterruptionRetry=true;targets[a]=nil
  a:SetAttribute("CurrentWorld",1)
  local w1=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
  w1.InitializePlayer(a,1);task.wait(.4)
  local e=workspace.Enemies["Owner_"..a.UserId].Stage01_Enemy
  check(e:GetAttribute("ChaseSpeed")==16 and e:GetAttribute("ChaseTurnResponse")==4,"World1 tuning")
  local before=e:GetPivot().Position
  require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1).ApplyDamageForStage(a,1,1e16)
  local f=workspace.GeneratedMap.BattleCorridor.Stage01.Floor
  place(a,f.Position+Vector3.new(0,f.Size.Y/2+3,0));task.wait(1.5)
  local moved=(e:GetPivot().Position-before).Magnitude;check(moved>1,"World1 representative movement")
  report.Cases.World1={Moved=moved,Speed=16,Turn=4}
 end
end,debug.traceback)
if not ok then table.insert(report.Errors,err);warn("FOUR_ERROR",err)end
ST:EndTest(report)
