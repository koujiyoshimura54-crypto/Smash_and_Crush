-- INJECTED native checks. Do not include these data/position probes in route timings.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
local Memory=require(RS.__W1BalanceMemory);local q=RS.__W1BalanceBoundary
local D=require(S.PlayerDataService);local P=require(RS.Modules.LevelProgression)
local Q=require(RS.Config.LevelRequirements);local R=require(RS.Config.RebirthConfig)
local E=require(game.ServerScriptService.World.EnemyManager)
local B=require(game.ServerScriptService.World.BossCombatService)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local Placement=require(S.LobbySpawnService)
local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local report={Cases={},Checks=0,Kind="Native three-client Play; injected profiles/positions; memory stores only"}
local function eq(a,b,label)report.Checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
local function waitFor(fn,seconds)
 local untilTime=os.clock()+(seconds or 20)
 repeat local result=fn();if result then return result end;task.wait(.05)until os.clock()>untilTime
 error("Boundary timeout")
end
local function run(name,fn)
 local ok,value=xpcall(fn,debug.traceback)
 table.insert(report.Cases,{Name=name,Passed=ok,Value=ok and value or nil,Error=not ok and value or nil})
 Memory.HoldWrites=false;Memory.FailBefore=0;Memory.FailAfter=0;Memory.Delay=0;Memory.TargetKey=nil
 print("[W1Balance boundary]",name,ok)
end
local function key(p)return "Player_"..p.UserId end
local function settled(p)
 waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation end)
end
local function state(p)
 local d=D.Get(p).Data
 return {Strength=d.Strength,Level=d.Level,Progress=d.LevelProgress,Curve=d.LevelCurveVersion,Rebirth=d.RebirthCount,Win=d.Win,Equipped=d.EquippedDumbbell}
end
local function inject(p,level,progress,strength,curve,count)
 settled(p);local s=D.Get(p);local d=s.Data
 d.Level,d.LevelProgress,d.Strength,d.LevelCurveVersion,d.RebirthCount=level,progress,strength,curve,count or 0
 s.Dirty=true
 for name,value in {Level=level,LevelProgress=progress,Strength=strength,LevelCurveVersion=curve,RebirthCount=count or 0}do p:SetAttribute(name,value)end
end
local function save(p)
 settled(p);D.Get(p).Dirty=true;assert(D.Save(p));return store:GetAsync(key(p))
end
local function reload(p,raw)
 settled(p);D.Release(p)
 if raw then store:SetAsync(key(p),raw)end
 assert(D.Load(p));D.SetAutoTapEnabled(p,false);return state(p)
end
local function ui(p)return q.Call:InvokeClient(p,"State")end
local function still(p)
 D.SetAutoTapEnabled(p,false)
 local c=waitFor(function()local ch=p.Character;return ch and ch:FindFirstChild("HumanoidRootPart")and ch:FindFirstChildOfClass("Humanoid")and ch.Humanoid.Health>0 and ch end,30)
 Placement.MoveToLobby(p,c,p:GetAttribute("CurrentWorld")==2 and 2 or 1)
 c.Humanoid:MoveTo(c.HumanoidRootPart.Position)
 waitFor(function()return not c.HumanoidRootPart.Anchored end)
 -- Prevent incidental walking gains during data assertions only.
 c.HumanoidRootPart.Anchored=true
end
local control=Instance.new("BindableFunction");control.Name="Control";control.Parent=q
control.OnInvoke=function(action,p,value)
 if action=="State"then return state(p)end
 if action=="Profile"then inject(p,value.Level,value.Progress,value.Strength,value.Curve,value.Rebirth);return state(p)end
 if action=="UI"then return ui(p)end
 if action=="Roundtrip"then save(p);return reload(p)end
 if action=="PrepareMobile"then
  -- Prepared UI/input setup on the last-wall floor, outside Boss attack contact.
  D.SetAutoTapEnabled(p,false)
  local c=p.Character;c.HumanoidRootPart.Anchored=false
  E.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1).Deactivate(p)
  p:SetAttribute("CurrentWorld",1);inject(p,8,0,360,2,0)
  E.StartRun(p,2);W.ApplyDamageForStage(p,2,1e20);E.SendState(p)
  local stage=workspace.GeneratedMap.BattleCorridor.Stage02;local f=stage.Floor
  local wall=stage["Stage2.4"].Wall
  local behind=wall.Position+(stage["Stage2.3"].Wall.Position-wall.Position).Unit*8
  local y=f.Position.Y+f.Size.Y/2+c.Humanoid.HipHeight+c.HumanoidRootPart.Size.Y/2
  local pos=Vector3.new(behind.X,y,behind.Z)
  c:PivotTo(CFrame.lookAt(pos,Vector3.new(wall.Position.X,y,wall.Position.Z)));c.Humanoid:MoveTo(pos)
  return {State=state(p),Position=tostring(pos),BossHP=E.GetGauge(p,2)}
 end
 if action=="Combat"then
  task.spawn(function()
   local ok,result=xpcall(function()return require(q.CombatProbe)(p)end,debug.traceback)
   local out=Instance.new("StringValue");out.Name="CombatResult";out.Value=game.HttpService:JSONEncode({OK=ok,Result=result});out.Parent=q
   q:SetAttribute("CombatDone",true)
  end)
  return "Started native prepared combat"
 end
 error("Unknown native boundary control")
end
local fatal,errorText=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==3 end,60)
 local players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 for _,p in players do waitFor(function()return D.IsLoaded(p)and p.Character and p.Character:GetAttribute("LobbySpawnPlaced")end,45);still(p)end
 local fresh,legacy,reborn=players[1],players[2],players[3]
 run("New default, missing marker LV1 zero, existing reborn cycle",function()
  eq(state(fresh).Curve,2);eq(state(fresh).Level,1);eq(state(fresh).Strength,0)
  local raw=save(legacy);raw.LevelCurveVersion=nil;raw.Strength=0;raw.Level=1;raw.LevelProgress=0
  local old=reload(legacy,raw);eq(old.Curve,1);eq(old.Level,1);eq(old.Strength,0)
  eq(legacy:GetAttribute("MTFNewFirstSession"),false)
  raw=save(reborn);raw.LevelCurveVersion=nil;raw.Strength=17.75;raw.Level=30;raw.LevelProgress=.125;raw.RebirthCount=3
  raw.Win=37;raw.OwnedDumbbells.NORMAL_02=1;raw.EquippedDumbbell="NORMAL_02"
  raw.OwnedItems.PROTEIN_COMMON_FIRE=2
  local oldReborn=reload(reborn,raw);eq(oldReborn.Curve,1);eq(oldReborn.Level,30);eq(oldReborn.Strength,17.75);eq(oldReborn.Progress,.125)
  eq(oldReborn.Rebirth,3);eq(oldReborn.Win,37);eq(oldReborn.Equipped,"NORMAL_02")
  eq(D.Get(reborn).Data.OwnedItems.PROTEIN_COMMON_FIRE,2)
  return {New=state(fresh),Missing=old,Reborn=oldReborn}
 end)
 run("Native intro guide stays at training on low-Strength LVUP",function()
  inject(fresh,2,0,5,2);local low=ui(fresh);eq(low.TutorialTarget,"Treadmill")
  inject(fresh,2,4,9,2);local before=ui(fresh);eq(before.TutorialTarget,"Treadmill")
  inject(fresh,2,5,10,2);task.wait(.4);local reached=ui(fresh);eq(reached.TutorialTarget,"Wall1.1")
  return {Low=low,Before=before,Reached=reached}
 end)
 run("Actual grants at changed boundaries, fractions, zero carry, peer isolation",function()
  local peer=state(reborn)
  for curve=1,2 do local p=curve==1 and legacy or fresh
   for level=1,29 do for _,offset in {-.25,0,.25}do
    local gain=Q.GetRequiredStrength(level,curve)+offset
    inject(p,level,0,37.125,curve)
    assert(D.AddStrengthGain(p,gain))
    local l,pr=P.Advance(level,0,gain,curve);local d=state(p)
    eq(d.Strength,37.125+gain);eq(d.Level,l);eq(d.Progress,pr);eq(d.Curve,curve)
   end end
   inject(p,2,Q.GetRequiredStrength(2,curve)+.125,9.75,curve)
   eq(D.AddStrengthGain(p,0),9.75);eq(state(p).Level,3);eq(state(p).Progress,.125)
   inject(p,1,0,37.125,curve)
   local large=Q.GetCumulativeStrength(50,curve)+.125
   eq(D.AddStrengthGain(p,large),37.125+large);eq(state(p).Level,50);eq(state(p).Progress,.125)
  end
  eq(state(reborn).Strength,peer.Strength);eq(state(reborn).Level,peer.Level);eq(state(reborn).Curve,peer.Curve)
  return {New=state(fresh),Old=state(legacy),Peer=state(reborn)}
 end)
 run("Different curves coexist with actual LV and Rebirth UI",function()
  inject(fresh,10,.5,675.5,2);inject(legacy,10,.5,955.5,1)
  local a,b=ui(fresh),ui(legacy)
  eq(a.Curve,2);eq(b.Curve,1);eq(a.RequiredText,"Required Level: 12");eq(b.RequiredText,"Required Level: 10")
  eq(a.RebirthEnabled,false);eq(b.RebirthEnabled,true)
  -- Existing HUD rounds sub-1000 values; the stored fractional progress stays .5.
  eq(a.ProgressText,"1 / 195");eq(b.ProgressText,"1 / 290")
  return {New=a,Legacy=b}
 end)
 run("Rebirth below/at/above gates, spam, old cycle switch and multiplier",function()
  for curve=1,2 do for count=0,5 do
   local target=R.GetRequiredLevel(count,curve)
   inject(fresh,target-1,.25,123.75,curve,count)
   eq(D.TryRebirth(fresh),false);eq(state(fresh).Strength,123.75)
   for _,extra in {0,1}do
    inject(fresh,target+extra,.25,123.75,curve,count)
    local ok,n=D.TryRebirth(fresh);eq(ok,true);eq(n,count+1)
    eq(state(fresh).Curve,2);eq(state(fresh).Strength,0);eq(state(fresh).Level,1);eq(state(fresh).Progress,0)
    eq(D.TryRebirth(fresh),false);eq(state(fresh).Rebirth,count+1)
   end
  end end
  inject(legacy,10,.125,955.125,1,0)
  local response=q.Call:InvokeClient(legacy,"Rebirth",12)
  eq(state(legacy).Rebirth,1);eq(state(legacy).Curve,2);eq(response.RequiredText,"Required Level: 17")
  eq(R.GetMultiplier(1),1.5)
  inject(fresh,12,0,1095,2,0)
  local session=D.Get(fresh);session.OwnershipLost=true
  local accepted=D.TryRebirth(fresh);session.OwnershipLost=nil
  eq(accepted,false);eq(state(fresh).Strength,1095);eq(state(fresh).Rebirth,0)
  return {After=state(legacy),UI=response}
 end)
 run("Save failure, acknowledgement loss, reload keep one coherent cycle",function()
  inject(fresh,8,.375,360.375,2,0);local expected=state(fresh)
  Memory.TargetKey=key(fresh);Memory.FailBefore=1
  eq(D.Save(fresh),false);eq(state(fresh).Strength,expected.Strength)
  Memory.FailBefore=0;assert(D.Save(fresh));local raw=store:GetAsync(key(fresh))
  eq(raw.LevelCurveVersion,2);eq(raw.LevelProgress,.375)
  local loaded=reload(fresh);eq(loaded.Strength,expected.Strength);eq(loaded.Progress,.375);eq(loaded.Curve,2)
  inject(legacy,10,.125,955.125,1,0);eq(D.TryRebirth(legacy),true)
  Memory.TargetKey=key(legacy);Memory.FailAfter=1
  eq(D.Save(legacy),false);eq(D.TryRebirth(legacy),false)
  Memory.FailAfter=0;assert(D.Save(legacy));raw=store:GetAsync(key(legacy))
  eq(raw.RebirthCount,1);eq(raw.LevelCurveVersion,2);eq(raw.Level,1);eq(raw.LevelProgress,0)
  loaded=reload(legacy);eq(loaded.Rebirth,1);eq(loaded.Curve,2);eq(loaded.Strength,0)
  return {New=state(fresh),Switched=loaded}
 end)
 run("Saving barrier rejects Rebirth without consuming old eligibility",function()
  inject(legacy,10,.25,955.25,1,0);Memory.TargetKey=key(legacy);Memory.HoldWrites=true
  local completed=false;task.spawn(function()D.Save(legacy);completed=true end)
  waitFor(function()return D.IsSaving(legacy)end)
  eq(D.TryRebirth(legacy),false);eq(state(legacy).Curve,1);eq(state(legacy).Level,10)
  Memory.HoldWrites=false;waitFor(function()return completed end)
  eq(D.TryRebirth(legacy),true);eq(state(legacy).Curve,2)
  return state(legacy)
 end)
 run("Unacknowledged reward blocks switch; retry grants once and keeps training",function()
  inject(legacy,10,.25,955.25,1,0);save(legacy)
  local session=D.Get(legacy);local id=session.Data.StrengthRewards.Owner
  local function award(raw)raw.StrengthRewards.Rewards[id]={Amount=12.5,Paid=0,CreatedAt=os.time()};return raw end
  session.Data.StrengthRewards.Rewards[id]={Amount=12.5,Paid=0,CreatedAt=os.time()}
  store:UpdateAsync(key(legacy),award)
  local op={Action="Claim",Id="W1BalanceBoundaryReward",RewardId=id}
  Memory.TargetKey=key(legacy);Memory.FailAfter=1
  local success=D.CommitStrengthOperation(legacy,op);eq(success,false)
  eq(D.TryRebirth(legacy),false);eq(state(legacy).Curve,1)
  assert(D.AddStrengthGain(legacy,3.125))
  Memory.FailAfter=0;waitFor(function()D.ResolveItemMutation(legacy);return not D.Get(legacy).PendingItemMutation end)
  eq(state(legacy).Strength,970.875);eq(state(legacy).Curve,1)
  assert(D.CommitStrengthOperation(legacy,op));eq(state(legacy).Strength,970.875)
  eq(D.TryRebirth(legacy),true);eq(state(legacy).Curve,2)
  assert(D.AddStrengthGain(legacy,5.125));local raw=save(legacy);reload(legacy)
  eq(state(legacy).Strength,5.125);eq(state(legacy).Level,2);eq(state(legacy).Progress,.125);eq(raw.LevelCurveVersion,2)
  return state(legacy)
 end)
 run("Real Boss/Wall services: five hits, gear, carry, per-owner reset",function()
  local evidence={}
  for stage,level in {4,8,15,20,25}do
   inject(fresh,level,0,Q.GetCumulativeStrength(level,2),2)
   B.Reset(fresh);local s=B.Begin(fresh,Instance.new("Model"),stage)
   eq(s.GloveBonus,0);eq(s.MaxHP,s.Strength*5)
   for hit=1,5 do local result=B.Attack(fresh);eq(result,hit==5 and"Win"or"Active")end
   eq(s.Attacks,5);eq(s.HP,0)
   W.InitializePlayer(fresh);local cfg=W.GetStageConfig(stage)
   local total=0;for _,v in cfg.Walls do total+=v end
   local wallHits=0
   repeat W.ApplyDamageForStage(fresh,stage,s.Strength);wallHits+=1 until W.IsBossUnlockedForStage(fresh,stage)
   eq(wallHits,math.ceil(total/s.Strength))
   if stage==4 then eq(wallHits,4)end
   W.InitializePlayer(fresh)
   local _,nextIndex,carry=W.ApplyDamageForStage(fresh,stage,total+7.5)
   eq(nextIndex,5);eq(carry,7.5)
   B.Reset(fresh);local nextBoss=B.Begin(fresh,Instance.new("Model"),stage)
   eq(nextBoss.HP,cfg.BossMaxHP) -- actual EnemyManager discards wall surplus.
   evidence[stage]={BossHP=s.MaxHP,Strength=s.Strength,Hits=s.Attacks,WallTotal=total,WallHits=wallHits}
   B.Reset(fresh);W.InitializePlayer(fresh)
  end
  local d=D.Get(fresh).Data;local glove="GLOVE_LEGENDARY_FIRE"
  d.OwnedItems[glove]=1;d.EquippedItems.Glove=glove
  inject(fresh,8,0,360,2);B.Reset(fresh)
  local equipped=B.Begin(fresh,Instance.new("Model"),2)
  eq(equipped.GloveBonus,.5);eq(equipped.BattleDamage,540)
  for hit=1,4 do local result=B.Attack(fresh);eq(result,hit==4 and"Win"or"Active")end
  evidence.Gear={Hits=equipped.Attacks,Damage=equipped.BattleDamage}
  d.EquippedItems.Glove="";d.OwnedItems[glove]=nil
  inject(legacy,8,0,360,1);B.Reset(legacy)
  local peer=B.Begin(legacy,Instance.new("Model"),2)
  W.InitializePlayer(legacy);W.ApplyDamageForStage(legacy,2,100)
  B.Reset(fresh);W.InitializePlayer(fresh)
  eq(B.Get(legacy),peer);eq(peer.HP,1800);eq(W.GetGaugeForStage(legacy,2,1),175)
  B.Reset(legacy);W.InitializePlayer(legacy)
  return evidence
 end)
 run("World2 shared curve and Rebirth, independent combat configuration",function()
  -- Prepared World2 arrival, outside ordinary-route measurements.
  local c=fresh.Character;c.HumanoidRootPart.Anchored=false
  E.ForWorld(1).Deactivate(fresh);fresh:SetAttribute("CurrentWorld",2)
  E.ForWorld(2).Activate(fresh);assert(Placement.MoveToLobby(fresh,c,2))
  waitFor(function()return not c.HumanoidRootPart.Anchored end)
  c.HumanoidRootPart.Anchored=true
  inject(fresh,16,0,2400,2,1)
  eq(D.TryRebirth(fresh),false);assert(D.AddStrengthGain(fresh,Q.GetRequiredStrength(16,2)))
  eq(state(fresh).Level,17);eq(D.TryRebirth(fresh),true);eq(state(fresh).Curve,2)
  eq(B.ForWorld(2).GetStageConfig(1).MaxHP,10000000)
  local view=ui(fresh);eq(view.Curve,2);eq(view.RequiredText,"Required Level: 24")
  local result={State=state(fresh),UI=view,Position=tostring(c:GetPivot().Position)}
  c.HumanoidRootPart.Anchored=false;E.ForWorld(2).Deactivate(fresh);fresh:SetAttribute("CurrentWorld",1)
  E.ForWorld(1).Activate(fresh);assert(Placement.MoveToLobby(fresh,c,1))
  waitFor(function()return not c.HumanoidRootPart.Anchored end)
  return result
 end)
 for _,p in players do local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart");if root then root.Anchored=false end end
end,debug.traceback)
Memory.HoldWrites=false;Memory.FailBefore=0;Memory.FailAfter=0;Memory.TargetKey=nil
if not fatal then table.insert(report.Cases,{Name="Suite",Passed=false,Error=errorText})end
report.Passed=true;for _,v in report.Cases do if not v.Passed then report.Passed=false end end
local output=Instance.new("StringValue");output.Name="Result";output.Value=game.HttpService:JSONEncode(report);output.Parent=q
q:SetAttribute("Done",true)
-- Keep this owned test open for combat cadence and device-emulator probes.
