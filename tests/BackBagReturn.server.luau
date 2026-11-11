-- Temporary native Studio regression harness. Requires __BackBagQAMemory isolation.
-- Prepared strength/walls and programmatic movement; never install in production.
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local R=require(S.RunInventoryService)
local B=require(S.RunItemBankService)
local Return=require(S.RunReturnService)
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local Stage=require(game.ServerScriptService.World.StageManager)
local T=require(S.TrophyRewardService)
local Area=require(S.TrainingLobbyAreaService)
local Placement=require(S.LobbySpawnService)
local Memory=require(RS.__BackBagQAMemory)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 10)
 repeat local value=fn();if value then return value end task.wait(.03) until os.clock()>deadline
 error("QA timeout")
end
waitFor(function()return D.IsLoaded(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:GetAttribute("MuscleScaleReady")end,30)
D.SetAutoTapEnabled(p,false);D.RestoreStudioStartOverride(p)
local function world()return p:GetAttribute("CurrentWorld")==2 and 2 or 1 end
local function root()return p.Character.HumanoidRootPart end
local function hum()return p.Character.Humanoid end
local function map()return workspace[world()==1 and "GeneratedMap" or "World2Map"]end
local function guid()return game.HttpService:GenerateGUID(false)end
local function copy(t)local c={} for k,v in t or {} do c[k]=v end return c end
local function snapshot()
 local s=R.GetSnapshot(p);local ps=E.ForWorld(world()).GetPlayerState(p);local d=D.Get(p).Data
 return {World=world(),Bag=s,CombatId=ps.RunInventoryId,ReturnId=ps.RunReturnId,
  IDsMatch=s and s.RunId==ps.RunInventoryId,Lobby=Area.IsInTrainingLobby(p),Position=tostring(root().Position),
  Win=p:GetAttribute("Win"),Items=copy(d.OwnedItems),Ores=copy(d.OwnedOres),
  Pending=D.Get(p).PendingItemMutation~=nil,BlockedWrites=Memory.BlockedWrites}
end
local function put(cf)
 root().Anchored=true;root().AssemblyLinearVelocity=Vector3.zero;root().AssemblyAngularVelocity=Vector3.zero;root().CFrame=cf
end
local api=Instance.new("BindableFunction");api.Name="__BackBagQACommand";api.Parent=RS
local itemId,oreId="PROTEIN_COMMON_FIRE","ORE_003"
local lastRun,lastTrophy,oldCharacter
local function act(action,arg)
 if action=="State" then return snapshot()
 elseif action=="Prepare" then
  E.ForWorld(world()).Deactivate(p);p:SetAttribute("CurrentWorld",arg.World)
  D.UnlockWorld(p,2);D.MarkWorld2Reached(p)
  D.SetCurrentStrength(p,10000000000000)
  local d=D.Get(p).Data;d.SelectedSizeTier=1;p:SetAttribute("SelectedSizeTier",1)
  E.ForWorld(world()).InitializePlayer(p,arg.Stage or 1)
  task.wait(.7) -- Allow prepared size/world placement callbacks to settle.
  assert(Placement.StreamLobby(p,p.Character,world()));assert(Placement.MoveToLobby(p,p.Character,world()))
  root().Anchored=false;task.wait(.5)
  return snapshot()
 elseif action=="Back" then
  local stage=Stage.ForWorld(world()).GetCurrentStageNumber(p)
  if world()==2 then W.ForWorld(2).ApplyDamageForStage(p,stage,1e15) end
  lastRun=R.GetSnapshot(p).RunId
  local start=os.clock();local ok,why=Return.Request(p,lastRun)
  local s=snapshot();s.OK=ok;s.Reason=why;s.Seconds=os.clock()-start
  return s
 elseif action=="Walk" then
  local floor=map().TrainingArea.Floor
  local start=root().Position
  local target=Vector3.new(map().TrainingArea[world()==1 and "SpawnLocation" or "World2LobbySpawn"].Position.X,start.Y,floor.Position.Z+floor.Size.Z/2+10)
  root().Anchored=false;root():SetNetworkOwner(nil);hum():MoveTo(target)
  local deadline=os.clock()+18
  repeat task.wait(.05) until not Area.IsInTrainingLobby(p) or os.clock()>deadline
  hum():MoveTo(root().Position);task.wait(.15)
  local s=snapshot();s.Distance=(root().Position-start).Magnitude;s.Crossed=not Area.IsInTrainingLobby(p)
  return s
 elseif action=="Add" then
  local run=E.ForWorld(world()).GetPlayerState(p).RunInventoryId
  if world()==2 then
   for id,row in require(RS.Config.ItemMaster).GetAll() do if row.WorldId==2 then itemId=id;break end end
   oreId="ORE_021"
  else itemId="PROTEIN_COMMON_FIRE";oreId="ORE_003" end
  local a,b=R.TryAddDrop(p,run,guid(),itemId)
  local c,d=R.TryAddOreDrop(p,run,guid(),oreId)
  local s=snapshot();s.ItemOK=a;s.ItemReason=b;s.OreOK=c;s.OreReason=d;return s
 elseif action=="Stale" then
  local a,b=R.TryAddDrop(p,lastRun,guid(),itemId);local c,d=R.TryAddOreDrop(p,lastRun,guid(),oreId)
  return {ItemOK=a,ItemReason=b,OreOK=c,OreReason=d,State=snapshot()}
 elseif action=="Fight" or action=="FightEmpty" then
  local n=arg or 2;local enemy=E.ForWorld(world());local ps=enemy.GetPlayerState(p)
  -- Prepare earlier-stage progression without resetting the current run.
  while Stage.ForWorld(world()).GetCurrentStageNumber(p)<n do
   local k=Stage.ForWorld(world()).GetCurrentStageNumber(p);ps.Defeated[k]=true;assert(Stage.ForWorld(world()).ClearStage(p,k))
  end
  W.ForWorld(world()).ApplyDamageForStage(p,n,1e15)
  local actor=waitFor(function()return enemy.GetEnemy(n,p)end,10)
  put(actor.CombatZone.CFrame);task.wait(.35)
local originals,dropId={},nil
  if action=="FightEmpty" then
   for _,key in {"TryAddDrop","TryAddOreDrop"} do
    local original=R[key];originals[key]=original
    R[key]=function(owner,run,id,...)
     local ok,why=original(owner,run,id,...);if owner==p and ok then dropId=id end;return ok,why
    end
   end
  end
  local accepted,reason=enemy.TryManualAttack(p)
  local ok,why=pcall(function()waitFor(function()return ps.Defeated[n]end,12);task.wait(.4)end)
  for key,original in originals do R[key]=original end
  assert(ok,why)
  if action=="FightEmpty" and dropId then
   R.DropRequest(p,"Shown",ps.RunInventoryId,dropId)
   assert(R.DropRequest(p,"Drop",ps.RunInventoryId,dropId))
  end
  local s=snapshot();s.AttackAccepted=accepted;s.AttackReason=reason;s.Defeated=ps.Defeated[n];s.Stage=n
  return s
 elseif action=="Trophy" then
  local n=arg or 2;local before=snapshot();lastRun=before.Bag.RunId
  local pad=map().BattleCorridor[("Stage%02d"):format(n)].TrophyNormalButton.Handle
  lastTrophy={Pad=pad,Win=before.Win,World=world()}
  root().Anchored=false;root().CFrame=pad.CFrame*CFrame.new(0,1.5,0)
  local deadline=os.clock()+12
  repeat task.wait(.03) until Area.IsInTrainingLobby(p) or os.clock()>deadline
  local s=snapshot();s.WinDelta=s.Win-before.Win;s.Returned=s.Lobby;return s
 elseif action=="ReplayTrophy" then
  local win=p:GetAttribute("Win")
  put(lastTrophy.Pad.CFrame*CFrame.new(0,1.5,0));task.wait(1.3)
  local delta=p:GetAttribute("Win")-win
  assert(Placement.MoveToLobby(p,p.Character,world()));root().Anchored=false
  return {WinDelta=delta,State=snapshot()}
 elseif action=="Death" then
  oldCharacter=p.Character;lastRun=R.GetSnapshot(p).RunId;hum().Health=0
  waitFor(function()return p.Character and p.Character~=oldCharacter and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:GetAttribute("MuscleScaleReady")end,18)
  task.wait(.8);local s=snapshot();s.Lost=oldCharacter:GetAttribute("BattleBagLostCount");s.Resolved=oldCharacter:GetAttribute("BattleBagDeathResolved");return s
 elseif action=="Hold" then Memory.HoldWrites=true;return snapshot()
 elseif action=="Release" then Memory.FailBefore=arg and arg.Before or 0;Memory.FailAfter=arg and arg.After or 0;Memory.HoldWrites=false;return snapshot()
 elseif action=="Flush" then local ok=B.Flush(p,15);local s=snapshot();s.Flushed=ok;return s
 elseif action=="FaultGranted" then
  local injected=false
  for _,store in Memory.Stores do
   local original=store.UpdateAsync
   store.UpdateAsync=function(self,key,fn)
    local granted=false
    local a,b=original(self,key,function(...)
     local value,users,metadata=fn(...)
     if value and (value.RunReturnJournal or value.RunOreReturnJournal) and (value.RunReturnJournal or value.RunOreReturnJournal).State=="Granted" then granted=true end
     return value,users,metadata
    end)
    if granted and not injected then injected=true;Memory.GrantedAckLost=(Memory.GrantedAckLost or 0)+1;error("isolated Granted acknowledgement loss") end
    return a,b
   end
  end
  return true
 elseif action=="FaultState" then
  return {GrantedAckLost=Memory.GrantedAckLost or 0,BeforeRemaining=Memory.FailBefore,AfterRemaining=Memory.FailAfter,BlockedWrites=Memory.BlockedWrites}
 elseif action=="Save" then
  assert(D.Save(p));local cfg=require(game.ServerScriptService.Config.DataStoreConfig)
  local raw=Memory.DataStoreService:GetDataStore(cfg.GetName("PlayerData_v1")):GetAsync("Player_"..p.UserId)
  return {Items=raw.OwnedItems,Ores=raw.OwnedOres,Win=raw.Win,Journal=raw.RunReturnJournal,OreJournal=raw.RunOreReturnJournal}
 end
 error("Unknown action "..tostring(action))
end
api.OnInvoke=function(action,arg)
 local ok,result=xpcall(function()return act(action,arg)end,debug.traceback)
 return {OK=ok,Result=ok and result or nil,Error=not ok and result or nil}
end
script:SetAttribute("Ready",true)
