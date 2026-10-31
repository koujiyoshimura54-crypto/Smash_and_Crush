-- Prepared follow-up: maximum-body native walking, real travel requests, Stage10 completion.
local Players=game.Players;local RS=game.ReplicatedStorage;local ST=game:GetService("StudioTestService")
local report={Mode="Isolated prepared follow-up; native physics and normal travel/Trophy paths",Cases={},Errors={}}
local request=Instance.new("RemoteEvent",RS);request.Name="__HPWallsRequest"
local reply=Instance.new("RemoteEvent",RS);reply.Name="__HPWallsReply"
local replies,ready={},{};local serial=0
reply.OnServerEvent:Connect(function(p,k,v)if k=="Ready" then ready[p]=true else replies[k]=v end end)
local function waitFor(fn,seconds,label)
 local deadline=os.clock()+seconds;repeat local v=fn();if v then return v end;task.wait(.05) until os.clock()>deadline;error("Timeout: "..label)
end
local function rpc(p,action,args)
 serial+=1;local key=tostring(serial);request:FireClient(p,key,action,args)
 local v=waitFor(function()return replies[key]end,20,action);assert(v.Success,v.Result);return v.Result
end
local done=false;task.delay(240,function()if not done then done=true;ST:EndTest({Timeout=true,Report=report})end end)
local ok,err=xpcall(function()
 waitFor(function()return #Players:GetPlayers()==2 end,50,"two players")
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end);local A,B=players[1],players[2]
 local PD=require(game.ServerScriptService.Services.PlayerDataService)
 local EM=require(game.ServerScriptService.World.EnemyManager).ForWorld(2)
 local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(2)
 local Stage=require(game.ServerScriptService.World.StageManager).ForWorld(2)
 local Boss=require(game.ServerScriptService.World.BossCombatService).ForWorld(2)
 local Trophy=require(game.ServerScriptService.Services.TrophyRewardService).ForWorld(2)
 local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
 local keepAlive={}
 game:GetService("RunService").Heartbeat:Connect(function()for p in keepAlive do local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid");if h and h.Health>0 then h.Health=h.MaxHealth end end end)
 for _,p in players do
  waitFor(function()return ready[p] and PD.IsLoaded(p) and p.Character and p.Character:GetAttribute("MuscleScaleReady")end,45,"ready")
  assert(p.UserId<=0);keepAlive[p]=true;PD.SetAutoTapEnabled(p,false);p:SetAttribute("CurrentWorld",2)
 end
 waitFor(EM.IsReady,30,"World2 ready")
 local function model(n)return workspace.World2Map.BattleCorridor[("Stage%02d"):format(n)]end
 local function place(p,n,pos)
  local ch=p.Character;local root=ch.HumanoidRootPart;local hum=ch:FindFirstChildOfClass("Humanoid");local floor=model(n).Floor
  root.Anchored=true;local y=floor.Position.Y+floor.Size.Y/2+hum.HipHeight+root.Size.Y/2+.1
  root.CFrame=CFrame.lookAt(Vector3.new(pos.X,y,pos.Z),Vector3.new(pos.X,y,pos.Z+1));root.AssemblyLinearVelocity=Vector3.zero
 end
 local function prep(p,n)
  EM.InitializePlayer(p,n);task.wait(.3)
  place(p,n,model(n)[("Stage%d.1"):format(n)].Wall.Position-Vector3.zAxis*12)
  rpc(p,"Resync",{World=2,Stage=n});return waitFor(function()return EM.GetEnemy(n,p)end,8,"actor")
 end
 local function strike(p,n,amount)
  PD.SetCurrentStrength(p,amount);task.wait(.2)
  local i=Wall.GetCurrentIndexForStage(p,n);local w=model(n)[("Stage%d.%d"):format(n,i)].Wall
  place(p,n,w.Position-Vector3.zAxis*4);task.wait(.6);assert(EM.TryManualAttack(p));task.wait(.2)
 end
 local function sumWalls(n,last)local sum=0;for i,hp in Wall.GetStageConfig(n).Walls do if not last or i<=last then sum+=hp end end;return sum end
 -- Maximum authored size; ordinary Humanoid MoveTo walks through cleared physical walls.
 for _,n in {5,6} do
  local e=prep(A,n);A:SetAttribute("SelectedSizeTier",13);task.wait(.3)
  strike(A,n,sumWalls(n)+1);assert(Wall.IsBossUnlockedForStage(A,n))
  local first=model(n)[("Stage%d.1"):format(n)].Wall;local last=model(n)[("Stage%d.%d"):format(n,Wall.GetWallCount(n))].Wall
  place(A,n,first.Position-Vector3.zAxis*9);rpc(A,"Resync",{World=2,Stage=n})
  local root=A.Character.HumanoidRootPart;local _,size=A.Character:GetBoundingBox();local start=root.Position
  root.Anchored=false;pcall(function()root:SetNetworkOwner(A)end)
  local result=rpc(A,"Walk",{World=2,Stage=n,Target=Vector3.new(first.Position.X,start.Y,last.Position.Z+4)})
  assert(result.Position[3]>last.Position.Z+1,"maximum body failed passage")
  report.Cases["MaxSizePassStage"..n]={SelectedTier=13,BodyBounds={size.X,size.Y,size.Z},StartZ=start.Z,EndZ=result.Position[3],LastWallZ=last.Position.Z}
 end
 -- Same avatar World2 -> World1 -> World2 preserves the incomplete sixth wall.
 A:SetAttribute("SelectedSizeTier",0);local e=prep(A,6);local peer=prep(B,6)
 strike(B,6,Wall.GetStageConfig(6).Walls[1]/2);local peerHP=Wall.GetGaugeForStage(B,6,1)
 strike(A,6,sumWalls(6,5)+Wall.GetStageConfig(6).Walls[6]/2)
 assert(Wall.GetCurrentIndexForStage(A,6)==6 and not Wall.IsBossUnlockedForStage(A,6))
 PD.UnlockWorld(A,2)
 local returnTrigger=workspace.World2Map.TrainingArea.World1ReturnGate.WorldGateTrigger
 A.Character.HumanoidRootPart.CFrame=returnTrigger.CFrame
 rpc(A,"Travel",{Action="ReturnWorld1"})
 waitFor(function()return A:GetAttribute("CurrentWorld")==1 end,20,"return World1")
 assert(EM.GetEnemy(6,B)==peer and Wall.GetGaugeForStage(B,6,1)==peerHP)
 task.wait(1.3);local trigger=workspace.World2Gate.WorldGateTrigger
 A.Character.HumanoidRootPart.CFrame=trigger.CFrame
 rpc(A,"Travel",{Action="ToWorld2"})
 waitFor(function()return A:GetAttribute("CurrentWorld")==2 end,20,"return World2")
 -- Travel returns to the Lobby; the distant Stage can legitimately stream out.
 A:RequestStreamAroundAsync(model(6)["Stage6.6"].Wall.Position)
 place(A,6,model(6)["Stage6.6"].Wall.Position-Vector3.zAxis*4)
 local restored=waitFor(function()
  local s=rpc(A,"Snapshot",{World=2,Stage=6})
  report.Cases.RoundTripObservation={State=s.State,Walls=s.Walls}
  return s.Walls[5] and s.Walls[6] and s.Walls[5].Hidden and not s.Walls[5].Collide and s.Walls[6].Collide and s
 end,12,"Stage6 streamed visibility/collision restoration")
 assert(restored.State.Current==6 and restored.State.Gauges[6]==Wall.GetStageConfig(6).Walls[6]/2)
 assert(restored.Walls[5].Hidden and not restored.Walls[5].Collide and restored.Walls[6].Collide)
 assert(EM.GetEnemy(6,B)==peer and Wall.GetGaugeForStage(B,6,1)==peerHP)
 report.Cases.WorldRoundTrip={RestoredIndex=6,SixthWallHalfHP=true,PeerUnaffected=true}
 -- Last Stage's real Boss defeat, completion and original Trophy return.
 e=prep(A,10);strike(A,10,sumWalls(10)+12345)
 assert(EM.GetGauge(A,10)==150000000000)
 PD.SetCurrentStrength(A,300000000000);task.wait(.3);place(A,10,e:GetPivot().Position)
 waitFor(function()return Boss.Get(A)end,10,"Stage10 Boss")
 task.wait(.6);assert(EM.TryManualAttack(A))
 waitFor(function()return Stage.GetState(A).WorldComplete end,8,"World2 complete")
 assert(EM.GetPlayerState(A).Defeated[10] and EM.GetGauge(A,10)==0)
 task.wait(.5);local old=Trophy.GetStudioCollectionCounts(A).Total;local win=A:GetAttribute("Win")
 A.Character.HumanoidRootPart.CFrame=model(10).TrophyNormalButton.Handle.CFrame
 waitFor(function()return Trophy.GetStudioCollectionCounts(A).Total>old end,12,"Stage10 Trophy")
 waitFor(function()return Stage.GetCurrentStageNumber(A)==1 and not Stage.GetState(A).WorldComplete end,20,"Stage10 return reset")
 assert(A:GetAttribute("Win")-win==3500000 and Wall.GetCurrentIndexForStage(A,10)==1)
 report.Cases.Stage10={BossHP=150000000000,Defeated=true,WorldComplete=true,TrophyWin=3500000,Reset=true}
end,debug.traceback)
if not ok then table.insert(report.Errors,err)end;report.Success=ok
game.HttpService:PostAsync("http://127.0.0.1:18766/mobility-result.json",game.HttpService:JSONEncode(report),Enum.HttpContentType.ApplicationJson)
if not done then done=true;ST:EndTest(report)end
