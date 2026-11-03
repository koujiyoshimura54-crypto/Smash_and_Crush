local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local Run=require(S.RunInventoryService)
local Return=require(S.RunReturnService)
local Drop=require(S.EnemyDropGachaService)
local Mem=require(RS.__OBQAMemory)
local bf=Instance.new("BindableFunction");bf.Name="__OBQAServer";bf.Parent=game.ServerStorage
local function waitFor(fn,t)local untilTime=os.clock()+(t or 15)repeat local v=fn();if v then return v end task.wait(.05)until os.clock()>untilTime error("QA timeout")end
local function player()local p=game.Players:GetPlayers()[1];assert(p and D.Get(p) and D.Get(p).Loaded);return p end
local function snapshot(p)return {First=D.Get(p).Data.FirstStage1Reward,Ores=D.Get(p).Data.OwnedOres,Items=D.Get(p).Data.OwnedItems,Bag=Run.GetSnapshot(p)}end
bf.OnInvoke=function(action,arg)
 local p=player()
 if action=="status" then return snapshot(p)
 elseif action=="time" then
  D.Get(p).Data.TimeRewards.ElapsedSeconds=math.max(60,D.Get(p).Data.TimeRewards.ElapsedSeconds)
  local ok,why=require(S.TimeRewardService).Claim(p,"StoneIntro01");assert(ok,why);return snapshot(p)
 elseif action=="combat" then
  D.SetAutoTapEnabled(p,false);D.SetCurrentStrength(p,1000000000);p:SetAttribute("CurrentWorld",1);p:SetAttribute("__OBQADraw",arg)
  E.StartRun(p,1);W.ApplyDamageForStage(p,1,1000000000)
  local enemy=waitFor(function()return E.GetEnemy(1,p)end)
  local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=enemy.CombatZone.CFrame
  task.wait(.35);local ok,why=E.TryManualAttack(p);assert(ok,why)
  waitFor(function()return E.GetPlayerState(p).Defeated[1]end,8)
  local row=waitFor(function()local id=p:GetAttribute("__OBQALastDrop");return id and game.ServerStorage.__OBQAEvents:FindFirstChild(id)end,10)
  task.wait(.4)
  local result=snapshot(p);result.Drop=game.HttpService:JSONDecode(row.Value)
  local again,reason=Drop.OnEnemyDefeated(p,1,E.GetPlayerState(p),1)
  assert(not again and reason=="AlreadyProcessed");result.Replay=reason
  return result
 elseif action=="return" then
  local before=Run.GetSnapshot(p);local ok,reason=Return.Request(p,before.RunId)
  local result=snapshot(p);result.OK=ok;result.Reason=reason;result.Before=before
  if ok then local repeated,why=Return.Request(p,before.RunId);assert(not repeated);result.Replay=why end
  task.wait(.3);return result
 elseif action=="fill" then
  local id=Run.GetSnapshot(p).RunId
  local dropId=game.HttpService:GenerateGUID(false)
  assert(Run.TryAddOreDrop(p,id,dropId,"ORE_001"))
  local duplicate,why=Run.TryAddDrop(p,id,dropId,"PROTEIN_COMMON_FIRE");assert(not duplicate and why=="AlreadyProcessed")
  assert(Run.TryAddDrop(p,id,game.HttpService:GenerateGUID(false),"PROTEIN_COMMON_FIRE"))
  assert(Run.TryAddOreDrop(p,id,game.HttpService:GenerateGUID(false),"ORE_002"))
  assert(Run.TryAddDrop(p,id,game.HttpService:GenerateGUID(false),"PROTEIN_COMMON_FIRE"))
  assert(Run.GetSnapshot(p).Count==5)
  local ore,oreReason=Run.TryAddOreDrop(p,id,game.HttpService:GenerateGUID(false),"ORE_001")
  local item,itemReason=Run.TryAddDrop(p,id,game.HttpService:GenerateGUID(false),"PROTEIN_COMMON_FIRE")
  assert(not ore and not item and oreReason=="InventoryFull" and itemReason=="InventoryFull")
  return snapshot(p)
 elseif action=="lostAck" then
  local store=Mem.DataStoreService:GetDataStore("PlayerData_v1_Studio")
  local original=store.UpdateAsync;local armed=true
  store.UpdateAsync=function(self,key,fn)
   return original(self,key,function(old,info)
    local value,users,meta=fn(old,info)
    if armed and key=="Player_"..p.UserId and value and value.RunOreReturnJournal and value.RunOreReturnJournal.State=="Granted" and old.RunOreReturnJournal.State=="Pending" then armed=false;Mem.FailAfter=1 end
    return value,users,meta
   end)
  end
  local run=Run.GetSnapshot(p)
  local ok,why=Return.Request(p,run.RunId)
  store.UpdateAsync=original
  assert(not ok and why=="InventorySavePending",tostring(why))
  local durable=store:GetAsync("Player_"..p.UserId)
  return {Pending=why,Live=snapshot(p),DurableOres=durable.OwnedOres,Journal=durable.RunOreReturnJournal}
 elseif action=="death" then
  local old=p.Character;old.Humanoid.Health=0
  waitFor(function()return p.Character and p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end,15)
  task.wait(.2);return snapshot(p)
 elseif action=="reload" then
  D.Get(p).Dirty=true;assert(D.Save(p));Run.Invalidate(p);D.Release(p);assert(D.Load(p));return snapshot(p)
 elseif action=="reset" then
  local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,"/resetdata");assert(ok,why)
  D.Release(p);assert(D.Load(p));D.SetAutoTapEnabled(p,false);return snapshot(p)
 end
end
