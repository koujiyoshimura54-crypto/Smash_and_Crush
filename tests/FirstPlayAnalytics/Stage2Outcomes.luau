-- Copied production modules, deterministic service/clock/character/placement adapters.
-- Native Luau Edit simulation only. No Instances, Play, DataStore or Analytics API writes.
return function(sources,deps)
 local result={Checks={},Kind="Native Luau isolated simulation; not gameplay Play or Hub receipt"}
 local function check(name,ok)assert(ok,name);table.insert(result.Checks,{Name=name,Passed=true})end
 local deathName="MTF_FirstStage2BossDeath_v1"
 local backName="MTF_FirstStage2BossBack_v1"
 local function signal()
  local s={Listeners={}}
  function s:Connect(fn)local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end;table.insert(self.Listeners,c);return c end
  function s:Once(fn)local c;c=self:Connect(function(...)c:Disconnect();fn(...)end);return c end
  function s:Fire(...)for _,c in table.clone(self.Listeners)do if c.Connected then c.Fn(...)end end end
  return s
 end
 local function factory(serviceSource,attackSource,returnSource)
  local F={Clock=0,Pending={},Serial=0,Trace={},Warnings={}}
  local function event()local s=signal();return {Event=s,Fire=function(_,...)s:Fire(...)end,Destroy=function()end}end
  local remote={OnServerEvent=signal(),FireClient=function()end}
  local Players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {}end}
  F.Players=Players
  function Players:GetPlayerFromCharacter(c)return c.Player end
  local config={Enabled=true,QueuePerSession=64,StudioRecordLimit=2048}
  local bindings={Config=config,Ore=deps.Ore,Merge=deps.Merge,Counts=deps.Counts,Master={Get=function()return {}end},Items={}}
  local servicesFolder={FirstPlayAnalyticsConfig="Config",FirstPlayAnalyticsTransport="Transport",PlayerDataService="Data",
   FirstPlayAnalyticsService="Analytics",RunInventoryService="Run",RunItemBankService="Bank",SpeedService="Speed",
   TrophyRewardService="Trophy",TrainingManager="Training",LobbySpawnService="Placement",ItemService="Items"}
  function servicesFolder:WaitForChild(k)return assert(self[k],k)end
  local configFolder={OreConfig="Ore",ItemMaster="Master",BossBehaviorConfig="Behavior"}
  function configFolder:WaitForChild(k)return assert(self[k],k)end
  local RS={Remotes={FindFirstChild=function()return remote end},Config=configFolder,Modules={OreMerge="Merge",InventoryCounts="Counts"}}
  local heartbeat=signal()
  local ws={GetServerTimeNow=function()return F.Clock end}
  local services={Players=Players,ReplicatedStorage=RS,HttpService={GenerateGUID=function()F.Serial+=1;return "fixture-"..F.Serial end},
   RunService={IsStudio=function()return true end,Heartbeat=heartbeat},Workspace=ws,
   AnalyticsService=setmetatable({},{__index=function()return function()error("Production API forbidden")end end})}
  local fakeGame={PlaceVersion=559,ServerScriptService={Services=servicesFolder,World={EnemyManager="Enemy",StageManager="Stage",Stage1WallManager="Wall"}},ReplicatedStorage=RS,
   GetService=function(_,name)return assert(services[name],name)end}
  local fakeTask={spawn=function(fn,...)fn(...)end,defer=function(fn,...)table.insert(F.Pending,{Fn=fn,Args=table.pack(...)})end,
   wait=function()error("Unexpected wait in game/analytics call")end}
  local env=setmetatable({game=fakeGame,workspace=ws,task=fakeTask,os={clock=function()return F.Clock end},
   typeof=function(v)if type(v)=="table"and v.IsPlayer then return "Instance"end;return typeof(v)end,
   Instance={new=function(class)if class=="BindableEvent"then return event()end;return {OnServerEvent=signal(),FireClient=function()end}end},
   warn=function(msg)table.insert(F.Warnings,msg)end,require=function(k)return assert(bindings[k],tostring(k))end},{__index=getfenv()})
  function F.Compile(text,parent)local e=setmetatable({script={Parent=parent or servicesFolder}},{__index=env});local f=assert(loadstring(text));setfenv(f,e);return f()end
  servicesFolder.Parent={Config={FirstPlayAnalyticsConfig="Config"}}
  bindings.Data={Get=function(p)return p.State end,HasReachedWorld2=function()return false end,GetInventoryCapacity=function()return 100 end,
   ChangeItemCounts=function(p,items,options)
    table.insert(F.Trace,"Save")
    local context=options.RunReturn;context.Operation={Result="Changed"}
    for id,n in items do p.State.Data.OwnedItems[id]=(p.State.Data.OwnedItems[id]or 0)+n end
    if context.OnResolved then context.OnResolved("Changed")end
    return true,"Changed"
   end}
  F.Config=config
  F.T=F.Compile(sources.Transport);bindings.Transport=F.T
  -- Only the old Ore physical-location dependency uses a logical fixture.
  local first=assert(serviceSource:find("local function atMerge(p)",1,true))
  local last=assert(serviceSource:find("function M.OreView",first,true))
  F.A=F.Compile(serviceSource:sub(1,first-1).."local function atMerge(p)return p.AtMerge end\n"..serviceSource:sub(last));bindings.Analytics=F.A
  F.Run=F.Compile(sources.Run);bindings.Run=F.Run
  local Placement={Arrived=signal(),WorldFor=function(p)return p:GetAttribute("CurrentWorld")==2 and 2 or 1 end}
  function Placement.StreamLobby(p,c,world)
   table.insert(F.Trace,"Stream")
   if F.OnStream then F.OnStream(p)end
   if F.StreamFails then return nil end
   return {Character=c,World=world}
  end
  function Placement.IsCurrent(p,r)return not F.StalePlacement and p.Character==r.Character and Placement.WorldFor(p)==r.World end
  function Placement.MoveToLobby(p,c,world)
   table.insert(F.Trace,"Move")
   if F.MoveThrows then error("fixture placement exception")end
   if F.MoveFails or p.Character~=c or p.Humanoid.Health<=0 then return false,"LobbyFloorUnavailable"end
   c.HumanoidRootPart.Anchored=true;c:SetAttribute("LobbySpawnPlaced",true)
   c:SetAttribute("SpawnPlacementRevision",c:GetAttribute("SpawnPlacementRevision")+1)
   return true
  end
  F.Placement=Placement;bindings.Placement=Placement
  local Enemy={}
  function Enemy.ForWorld()return Enemy end
  function Enemy.IsReady()return not F.EnemyNotReady end
  function Enemy.GetPlayerState(p)return p.CombatState end
  function Enemy.InitializePlayer(p)
   table.insert(F.Trace,"ResetRun")
   p:SetAttribute("CurrentStage",1)
   p.CombatState={RunInventoryId=F.Run.Reset(p,true),Defeated={}}
  end
  F.Enemy=Enemy;bindings.Enemy=Enemy
  bindings.Stage={GetCurrentStageNumber=function(p)return p:GetAttribute("CurrentStage")end}
  local Wall={IsBossUnlockedForStage=function()return not F.BossLocked end};function Wall.ForWorld()return Wall end;bindings.Wall=Wall
  local Trophy={GetLobbySpawn=function()return not F.LobbyMissing and {}or nil end};function Trophy.ForWorld()return Trophy end
  bindings.Trophy=Trophy;bindings.Training={StopTraining=function()table.insert(F.Trace,"StopTraining")end}
  bindings.Speed={Apply=function()table.insert(F.Trace,"ApplySpeed")end,GetEquippedSpeedItemId=function()return "NONE"end}
  bindings.Behavior={Get=function()return {AttackInterval=1,Damage=25}end}
  bindings.Animation={Ready=function()return true end,SetAttackEligible=function()end}
  F.Bank=F.Compile(sources.Bank);bindings.Bank=F.Bank
  F.Return=F.Compile(returnSource)
  F.Attack=F.Compile(attackSource,{World2BossAnimationService="Animation"})
  F.Attack.SetSessionValidator(function(p,enemy,stage,c)return not F.InvalidAttack and p.Character==c and p:GetAttribute("CurrentStage")==stage end)
  F.Attack.IsInRange=function()return F.InRange~=false,1,5 end
  function F.Flush()local count=0;while #F.Pending>0 do count+=1;assert(count<10000,"queue bounded");local job=table.remove(F.Pending,1);job.Fn(table.unpack(job.Args,1,job.Args.n))end end
  function F.Character(p)
   local attrs={SpawnPlacementRevision=1,SpawnEngineReady=true,MuscleScaleReady=true,LobbySpawnPlaced=true}
   local c={Player=p,ChildAdded=signal(),HumanoidRootPart={Anchored=false}}
   local hp=100
   local h;h=setmetatable({Parent=c,MaxHealth=100,Died=signal(),Sit=false},{__index=function(_,k)if k=="Health"then return hp end end,
    __newindex=function(t,k,v)
     if k~="Health"then rawset(t,k,v);return end
     local before=hp;hp=v
     if F.KillOnNonlethal and v>0 and v<100 then hp=0 end
     if before>0 and hp==0 then
      if F.ResetOnDeath then p:SetAttribute("CurrentStage",1);F.Run.DiscardOnDeath(p,c);p.CombatState={RunInventoryId=F.Run.Reset(p,true),Defeated={}}end
      h.Died:Fire()
     end
    end})
   c.Humanoid=h
   function c:GetChildren()return {}end
   function c:FindFirstChild(k)return self[k]end
   function c:FindFirstChildOfClass()return self.Humanoid end
   function c:WaitForChild()return self.Humanoid end
   function c:GetAttribute(k)return attrs[k]end
   function c:SetAttribute(k,v)attrs[k]=v end
   return c,h
  end
  function F.Player(kind)
   F.Serial+=1
   local attrs={CurrentWorld=1,CurrentStage=2};local signals={}
   local p={IsPlayer=true,UserId=-F.Serial,Parent=Players,CharacterAdded=signal(),AtMerge=true}
   function p:IsA(k)return k=="Player"end
   function p:GetAttribute(k)return attrs[k]end
   function p:SetAttribute(k,v)attrs[k]=v;if signals[k]then signals[k]:Fire()end end
   function p:GetAttributeChangedSignal(k)signals[k]=signals[k]or signal();return signals[k]end
   p.State={Loaded=true,ForgeToken="token",PetViewGeneration=0,Data={OwnedOres={},OwnedItems={},ResetToken="reset"}}
   p.Character,p.Humanoid=F.Character(p)
   p.CombatState={RunInventoryId=F.Run.Reset(p,true),Defeated={}}
   F.A.Join(p);if kind then F.A.Loaded(p,p.State.Data,kind)end
   F.A.Placed(p,p.Character,1);F.A.Playable(p,p.Character,1)
   return p
  end
  function F.Damage(p)for i=2,5 do F.A.Combat(p,1,2,i)end end
  function F.Retry(p)
   F.Attack.Stop(p,false);p.Character,p.Humanoid=F.Character(p);p.CharacterAdded:Fire(p.Character)
   p:SetAttribute("CurrentStage",2);p.CombatState={RunInventoryId=F.Run.Reset(p,true),Defeated={}}
  end
  function F.Kill(p,world,stage)
   local attack=F.Attack.ForWorld(world or 1)
   attack.SetSessionValidator(function()return not F.InvalidAttack end)
   attack.IsInRange=function()return F.InRange~=false,1,5 end
   attack.Start(p,{Parent=true},stage or 2,F.Clock);p.Humanoid.Health=25
   F.Clock+=1;heartbeat:Fire()
  end
  function F.Pulse()F.Clock+=1;heartbeat:Fire()end
  function F.Ack(p)
   p.Character.HumanoidRootPart.Anchored=false
   F.A.Placed(p,p.Character,p.Character:GetAttribute("SpawnPlacementRevision"))
   Placement.Arrived:Fire(p,p.Character,p.Character:GetAttribute("SpawnPlacementRevision"))
  end
  function F.Back(p)local id=p:GetAttribute("RunInventoryId");return F.Return.Request(p,id)end
  function F.Rows(p,name)
   F.Flush();local out={}
   for _,row in F.T.StudioRecords()do if row.UserId==p.UserId and(not name or row.Name==name)then table.insert(out,row)end end
   return out
  end
  function F.Count(p,name)return #F.Rows(p,name)end
  return F
 end
 local function fixture()return factory(sources.Service,sources.Attack,sources.Return)end
 local F=fixture();local p=F.Player("New");F.Damage(p);F.Damage(p)
 check("Effective damage starts both funnels exactly once",F.Count(p,deathName)==1 and F.Count(p,backName)==1)
 local id=p:GetAttribute("MTFSession")
 for _,name in {deathName,backName}do local e=F.Rows(p,name)[1];check(name.." schema",e.Step==1 and e.StepName=="DamagedStage2Boss"and e.Session==id and e.Fields.CustomField01=="PlaceVersion:559"and e.Fields.CustomField02=="NewFirstSession"and e.Fields.CustomField03=="Normal")end
 F.ResetOnDeath=true;F.Kill(p)
 check("Lethal Boss write survives synchronous Died/run reset",p.Humanoid.Health==0 and p:GetAttribute("CurrentStage")==1 and F.Count(p,deathName)==2)
 check("Death terminal exact name",F.Rows(p,deathName)[2].StepName=="KilledByStage2Boss")
 F.Retry(p);F.Damage(p);check("Death then retry Back accepted",F.Back(p))
 check("Back placement submission alone not completed",F.Count(p,backName)==1)
 F.Ack(p);F.Ack(p)
 check("Death then Back completes each once with same GUID",F.Count(p,deathName)==2 and F.Count(p,backName)==2 and p:GetAttribute("MTFSession")==id)
 check("Back terminal exact name",F.Rows(p,backName)[2].StepName=="BackBeforeStage2BossDefeat")
 F.A.Combat(p,1,2,6);check("Defeat after both outcomes still completes existing funnel",F.Count(p,"MTF_FirstStage2Combat_v1")==5)
 F.Retry(p);F.Kill(p);check("Repeated death never duplicates",F.Count(p,deathName)==2)
 do
  local G=fixture();local q=G.Player("New");G.Damage(q);check("Back then retry death Back accepted",G.Back(q));G.Ack(q);G.Retry(q);G.Kill(q)
  check("Back then death completes both",G.Count(q,backName)==2 and G.Count(q,deathName)==2)
  G.A.Combat(q,1,2,6);check("Defeat after Back/death progresses",G.Count(q,"MTF_FirstStage2Combat_v1")==5)
 end
 for _,kind in {"Existing","Unknown","Unloaded","Reset","DataReplaced","SkipBefore","SkipAfter","DebugOverride"}do
  local G=fixture();local q=G.Player(kind=="Unloaded"and nil or (kind=="Existing"or kind=="Unknown")and kind or "New")
  if kind=="Unloaded"then G.A.Leaving(q);G.A.Join(q)end
  if kind=="Reset"or kind=="DebugOverride"then G.A.Reset(q)end
  if kind=="DataReplaced"then G.A.Loaded(q,{},"New")end
  if kind=="SkipBefore"then G.A.Skipped(q)end
  G.Damage(q);if kind=="SkipAfter"then G.A.Skipped(q)end
  G.Kill(q);G.Retry(q);G.Back(q);G.Ack(q)
  local expected=kind=="SkipAfter"and 1 or 0
  check(kind.." excludes outcomes",G.Count(q,deathName)==expected and G.Count(q,backName)==expected)
 end
 for _,cause in {"ResetCharacter","Fall","OtherStage","World2","NoDamage","Miss","InvalidSession","OldCharacter","Nonlethal","OtherCauseDuringNonlethal"}do
  local G=fixture();local q=G.Player("New");if cause~="NoDamage"then G.Damage(q)end
  if cause=="ResetCharacter"or cause=="Fall"then q.Humanoid.Health=0
  elseif cause=="Nonlethal"or cause=="OtherCauseDuringNonlethal"then
   G.Attack.Start(q,{Parent=true},2,0);G.KillOnNonlethal=cause=="OtherCauseDuringNonlethal";G.Pulse()
  elseif cause=="OldCharacter"then
   local old=q.Character;local h=q.Humanoid;G.Retry(q);h.Health=0
   G.A.Stage2BossHit(q,1,{Stage=2,Character=old,Humanoid=h,Enemy={},Behavior={Damage=25}},25,0)
  else
   G.InRange=cause~="Miss";G.InvalidAttack=cause=="InvalidSession"
   G.Kill(q,cause=="World2"and 2 or 1,cause=="OtherStage"and 1 or 2)
  end
  check(cause.." never completes Boss death",G.Count(q,deathName)==(cause=="NoDamage"and 0 or 1))
 end
 for missing=2,5 do
  local G=fixture();local q=G.Player("New");for i=2,5 do if i~=missing then G.A.Combat(q,1,2,i)end end
  G.Kill(q);G.Retry(q);G.Back(q);G.Ack(q)
  check("Missing Stage2 observation "..missing.." never synthesized",G.Count(q,deathName)==0 and G.Count(q,backName)==0)
 end
 for _,scenario in {"Stage1","World2","BossLocked","NoDamage","Busy","StaleRun","StreamFail","StalePlacement","PlacementFail","PlacementThrow","DeathDuringStream","CharacterDuringStream","RunDuringStream","StageDuringStream","WorldDuringStream","DefeatDuringStream","DataDuringStream","DeathBeforeAck","RunBeforeAck","CharacterBeforeAck","WorldBeforeAck","RevisionBeforeAck","SkipBeforeAck","DefeatBeforeAck","Trophy","Walk","AutomaticRespawn","NoAck"}do
  local G=fixture();local q=G.Player("New");if scenario~="NoDamage"then G.Damage(q)end
  if scenario=="Stage1"then q:SetAttribute("CurrentStage",1)end
  if scenario=="World2"then q:SetAttribute("CurrentWorld",2);q:SetAttribute("World2CurrentStage",2);q.CombatState.RunInventoryId=G.Run.Reset(q,true);q.CombatState.RunReturnId=q.CombatState.RunInventoryId end
  G.BossLocked=scenario=="BossLocked"
  G.StreamFails=scenario=="StreamFail";G.StalePlacement=scenario=="StalePlacement";G.MoveFails=scenario=="PlacementFail";G.MoveThrows=scenario=="PlacementThrow"
  if scenario=="Busy"then G.OnStream=function()local ok,why=G.Back(q);check("Concurrent Back returns ReturnBusy",not ok and why=="ReturnBusy");G.StreamFails=true end end
  local changes={Death=function()q.Humanoid.Health=0 end,Character=function()G.Retry(q)end,Run=function()G.Enemy.InitializePlayer(q);q:SetAttribute("CurrentStage",2)end,
   Stage=function()q:SetAttribute("CurrentStage",1)end,World=function()q:SetAttribute("CurrentWorld",2)end,Defeat=function()G.A.Combat(q,1,2,6);q.CombatState.Defeated[2]=true end,
   Data=function()G.A.Loaded(q,{},"New")end,Revision=function()q.Character:SetAttribute("SpawnPlacementRevision",100)end,Skip=function()G.A.Skipped(q)end}
  local during=scenario:match("^(%a+)DuringStream$");if during then G.OnStream=changes[during]end
  if scenario=="Trophy"then local token=G.Bank.Begin(q,q:GetAttribute("RunInventoryId"));check("Trophy shared banking succeeds",token~=nil);G.Enemy.InitializePlayer(q);G.Placement.MoveToLobby(q,q.Character,1)
  elseif scenario=="Walk"or scenario=="AutomaticRespawn"then G.Enemy.InitializePlayer(q);G.Placement.MoveToLobby(q,q.Character,1)
  elseif scenario=="StaleRun"then local ok,why=G.Return.Request(q,"old-run");check("StaleRun rejected",not ok and why=="StaleRun")
  else local ok=G.Back(q);if scenario=="World2"or scenario=="BossLocked"then check(scenario.." return behavior remains successful",ok)end end
  local before=scenario:match("^(%a+)BeforeAck$");if before then changes[before]()end
  if scenario~="NoAck"then G.Ack(q)end
  check(scenario.." never completes Back",G.Count(q,backName)==(scenario=="NoDamage"and 0 or 1))
 end
 do
  local G=fixture();local q=G.Player("New");q:SetAttribute("CurrentStage",1);check("Stage1 Back succeeds",G.Back(q));G.Ack(q)
  q:SetAttribute("CurrentStage",2);G.Damage(q);check("Later Stage2 Back succeeds",G.Back(q));G.Ack(q)
  check("Earlier first ReturnAccepted does not suppress Stage2 Back",G.Count(q,backName)==2)
 end
 for _,after in {"DefeatBeforeOutcomes","DefeatAfterDeath","DefeatAfterBack","OutOfOrderDefeat"}do
  local G=fixture();local q=G.Player("New")
  if after~="OutOfOrderDefeat"then G.Damage(q)end
  if after=="DefeatAfterDeath"then G.Kill(q);G.Retry(q)end
  if after=="DefeatAfterBack"then G.Back(q);G.Ack(q);G.Retry(q)end
  G.A.Combat(q,1,2,6);G.Retry(q);G.Damage(q);G.Kill(q);G.Retry(q);G.Back(q);G.Ack(q)
  check(after.." permanently excludes later-run completion",G.Count(q,deathName)==(after=="OutOfOrderDefeat"and 0 or after=="DefeatAfterDeath"and 2 or 1)and G.Count(q,backName)==(after=="OutOfOrderDefeat"and 0 or after=="DefeatAfterBack"and 2 or 1))
 end
 do
  local G=fixture();local q=G.Player("New");G.Damage(q);local oldId=q:GetAttribute("MTFSession");G.A.Leaving(q);G.A.Join(q);G.A.Loaded(q,q.State.Data,"Existing");G.Kill(q);G.Retry(q);G.Back(q);G.Ack(q)
  check("Rejoin GUID changes and Existing cannot resume",q:GetAttribute("MTFSession")~=oldId and G.Count(q,deathName)==1 and G.Count(q,backName)==1)
 end
 -- Exact old four-funnel/custom stream parity, plus return/HP traces with disabled/failed analytics.
 local function fullRoute(G)
  local q=G.Player("New");for i=2,6 do G.A.Combat(q,1,1,i)end;G.Damage(q)
  q.State.Data.OwnedOres={ORE_001=2};G.A.CheckOre(q)
  local context={Session=q:GetAttribute("MTFSession"),Character=q.Character,Sequence=1,Open=true,Token="token",Generation=0,Materials={ORE_001=2}}
  local op={Action="MergeOre",Id="merge",Materials={ORE_001=2},AnalyticsContext=context};G.A.OreView(q,context);G.A.OreRequested(q,op);G.A.OreCommitted(q,op)
  G.A.Strength(q,"Manual");G.A.AutoOn(q);G.A.Equipped(q,"NORMAL_02")
  G.Kill(q);G.Retry(q);G.Back(q);G.Ack(q);G.A.Combat(q,1,2,6)
  return q
 end
 local old=factory(sources.Baseline,sources.AttackBaseline,sources.ReturnBaseline);local new=fixture()
 local a=fullRoute(old);local b=fullRoute(new)
 local function normalize(rows)
  local out={};for _,e in rows do if e.Name~=deathName and e.Name~=backName then table.insert(out,{Kind=e.Kind,Name=e.Name,Session=e.Session,Step=e.Step,StepName=e.StepName,Value=e.Value,Fields=e.Fields})end end
  return game:GetService("HttpService"):JSONEncode(out)
 end
 check("Existing four funnels and every custom row unchanged",normalize(old.Rows(a))==normalize(new.Rows(b)))
 check("Gameplay reset/training/speed/move trace unchanged",table.concat(old.Trace,",")==table.concat(new.Trace,","))
 check("Exactly four additional Funnel events and no new Custom events",#new.Rows(b)-#old.Rows(a)==4)
 result.EventBudget={Baseline=#old.Rows(a),WithBothOutcomes=#new.Rows(b),Added=4,QueueCapacity=64}
 for _,mode in {"Disabled","SendFailure"}do
  local G=fixture();local q=G.Player("New");G.Flush();G.Damage(q);G.Flush()
  if mode=="Disabled"then G.Config.Enabled=false else G.T.StudioFailNext(3)end
  G.Kill(q);G.Retry(q)
  local run=q:GetAttribute("RunInventoryId");check(mode.." ordinary loot added",G.Run.TryAddDrop(q,run,"drop","ITEM_TEST"))
  local ok=G.Back(q);G.Ack(q);G.Flush()
  check(mode.." leaves damage and return functional",ok and q.Humanoid.Health==100 and not q:GetAttribute("RunReturnBusy")and q:GetAttribute("CurrentStage")==1)
  check(mode.." deferred bank still saves exactly once",q.State.Data.OwnedItems.ITEM_TEST==1 and G.Run.GetAccepted(q,run)==nil)
 end
 do
  local G=fixture();local q=G.Player("New");G.Damage(q);local run=q:GetAttribute("RunInventoryId")
  check("Initial spam-route return succeeds",G.Back(q));G.Ack(q);G.Flush()
  for _=1,10 do local ok,why=G.Return.Request(q,run);check("Repeated old run rejected ".._,not ok and why=="StaleRun")end
  G.Ack(q);check("Back spam does not duplicate completion",G.Count(q,backName)==2)
 end
 do
  local G=fixture();local q=G.Player("New");G.Damage(q)
  local run=q:GetAttribute("RunInventoryId");G.Run.TryAddDrop(q,run,"held-save","ITEM_TEST")
  check("Return succeeds before deferred bank runs",G.Back(q));G.Ack(q)
  check("Placement does not wait for deferred save",q.State.Data.OwnedItems.ITEM_TEST==nil)
  G.Flush();check("Deferred bank settles after placement",q.State.Data.OwnedItems.ITEM_TEST==1 and G.Count(q,backName)==2)
 end
 result.Passed=true;return result
end
