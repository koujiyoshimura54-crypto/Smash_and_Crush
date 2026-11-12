-- Prepared native combat, outside all normal-route timing samples.
-- Keeps live attack, contact, Auto clock, incoming damage and respawn services.
return function(player)
 local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
 assert(RS:FindFirstChild("__W1BalanceMemory"),"Isolation required")
 local D=require(S.PlayerDataService);local Q=require(RS.Config.LevelRequirements)
 local E=require(game.ServerScriptService.World.EnemyManager)
 local B=require(game.ServerScriptService.World.BossCombatService)
 local W=require(game.ServerScriptService.World.Stage1WallManager)
 local Placement=require(S.LobbySpawnService);local q=RS.__W1BalanceBoundary
 local report={Cases={},Kind="Prepared native combat: injected starting data and position, ordinary Auto/Tap/MoveTo thereafter"}
 local function waitFor(fn,seconds)
  local limit=os.clock()+(seconds or 20)
  repeat local v=fn();if v then return v end;task.wait(.025)until os.clock()>limit
  error("Combat probe timeout")
 end
 local function ready()
  return waitFor(function()local c=player.Character;return c and c:FindFirstChildOfClass("Humanoid")and c.Humanoid.Health>0 and c:FindFirstChild("HumanoidRootPart")and c:GetAttribute("LobbySpawnPlaced")and c end,30)
 end
 local function prep(stage)
  local c=ready();local s=D.Get(player);waitFor(function()return not s.Saving and not s.PendingItemMutation end)
  D.SetAutoTapEnabled(player,false);c.HumanoidRootPart.Anchored=false
  E.ForWorld(player:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(player)
  player:SetAttribute("CurrentWorld",1)
  local level=RS.Config.World1BossConfig and require(RS.Config.World1BossConfig).GetRecommendedLevel(stage)
  local strength=Q.GetCumulativeStrength(level,2)
  s.Data.Level=level;s.Data.LevelProgress=0;s.Data.LevelCurveVersion=2;s.Data.Strength=strength;s.Data.RebirthCount=0
  s.Data.EquippedItems={Glove="",Protein="",TrainingBelt=""}
  for name,value in {Level=level,LevelProgress=0,Strength=strength,LevelCurveVersion=2,RebirthCount=0}do player:SetAttribute(name,value)end
  s.Dirty=true
  E.StartRun(player,stage)
  W.ApplyDamageForStage(player,stage,1e20);E.SendState(player)
  local actor=waitFor(function()return E.GetEnemy(stage,player)end)
  task.wait(.3)
  local h=c.Humanoid;local root=c.HumanoidRootPart
  local floor=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)].Floor
  local y=floor.Position.Y+floor.Size.Y/2+h.HipHeight+root.Size.Y/2
  local zone=actor.CombatZone;local pos=Vector3.new(zone.Position.X,y,zone.Position.Z)+zone.CFrame.LookVector*2
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  c:PivotTo(CFrame.lookAt(pos,Vector3.new(zone.Position.X,y,zone.Position.Z)))
  h.Health=h.MaxHealth
  return c,actor,strength
 end
 for _,mode in {"Manual","Auto"}do for stage=1,5 do
  local original=B.Attack;local healthConnection
  local case={Mode=mode,Stage=stage,Hits={},Incoming={}}
  local ok,err=xpcall(function()
   local c,actor,expected=prep(stage);local h=c.Humanoid;local start=os.clock();case.ExpectedStrength=expected
   B.Attack=function(p)
    local result,state=original(p)
    if p==player and state then table.insert(case.Hits,{Time=os.clock()-start,HP=state.HP,Damage=state.BattleDamage,Strength=state.BattleStartStrength,Health=h.Health,Count=state.Attacks})end
    return result,state
   end
   healthConnection=h.HealthChanged:Connect(function(hp)table.insert(case.Incoming,{Time=os.clock()-start,Health=hp})end)
   -- Exact-Strength benchmark starts inputs after real contact recognition;
   -- pre-contact taps/walking would legitimately train and change the benchmark.
   waitFor(function()return player:GetAttribute("IsFighting")==true or h.Health<=0 end,5)
   case.ContactSeconds=os.clock()-start;case.HealthAtContact=h.Health
   if mode=="Auto"then q.Call:InvokeClient(player,"Auto",true)end
   case.Client=q.Call:InvokeClient(player,"Fight",{World=1,Stage=stage,Mode=mode})
   D.SetAutoTapEnabled(player,false)
   case.Defeated=E.GetPlayerState(player).Defeated[stage]==true
   case.Died=h.Health<=0;case.Seconds=os.clock()-start
   case.ExactBenchmark=#case.Hits>0 and case.Hits[1].Strength==expected
   case.FiveHits=#case.Hits==5 and case.Defeated
  end,debug.traceback)
  B.Attack=original;if healthConnection then healthConnection:Disconnect()end
  case.FixtureOK=ok;case.Error=not ok and err or nil;table.insert(report.Cases,case)
  D.SetAutoTapEnabled(player,false)
  local c=ready();E.InitializePlayer(player);Placement.MoveToLobby(player,c,1)
  waitFor(function()return not c.HumanoidRootPart.Anchored end)
 end end
 local back={};report.Back=back
 local ok,err=xpcall(function()
  local c=prep(2)
  task.wait(.3);q.Call:InvokeClient(player,"Tap")
  waitFor(function()return E.GetGauge(player,2)<1800 end,3)
  back.BeforeHP=E.GetGauge(player,2);back.Curve=D.Get(player).Data.LevelCurveVersion
  local prior=player:GetAttribute("RunInventoryId")
  q.Call:InvokeClient(player,"Back",8)
  waitFor(function()return player:GetAttribute("RunInventoryId")~=prior and not player:GetAttribute("RunReturnBusy")end)
  back.AfterHP=E.GetGauge(player,2);back.CurveAfter=D.Get(player).Data.LevelCurveVersion
  back.CharacterSame=player.Character==c;back.Health=c.Humanoid.Health
  assert(back.AfterHP==1800 and back.CurveAfter==back.Curve and back.CharacterSame and back.Health>0)
 end,debug.traceback)
 back.FixtureOK=ok;back.Error=not ok and err or nil
 return report
end
