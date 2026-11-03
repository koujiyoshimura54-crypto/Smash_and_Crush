local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local Run=require(S.RunInventoryService)
local Return=require(S.RunReturnService)
local Mem=require(RS.__WBQAMemory)
local Debug=require(game.ServerScriptService.Systems.Debug.StudioDebugService)
local bf=Instance.new("BindableFunction");bf.Name="__WBQAServer";bf.Parent=game.ServerStorage
local function waitFor(fn,seconds)
 local untilTime=os.clock()+(seconds or 15)
 repeat local v=fn();if v then return v end;task.wait(.05) until os.clock()>untilTime
 error("QA timeout")
end
local function p()
 local p=game.Players:GetPlayers()[1]
 assert(p and D.Get(p) and D.Get(p).Loaded,"Data not ready");return p
end
bf.OnInvoke=function(action,arg)
 local player=p();local d=D.Get(player).Data
 if action=="status" then return {UserId=player.UserId,First=d.FirstStage1Reward,Ore=d.OwnedOres,Bag=Run.GetSnapshot(player),AdminSaving=D.Get(player).Saving} end
 if action=="combat" then
  D.SetAutoTapEnabled(player,false);D.SetCurrentStrength(player,1000000000)
  player:SetAttribute("CurrentWorld",1);player:SetAttribute("__WBQADraw",arg)
  E.StartRun(player,1);W.ApplyDamageForStage(player,1,1000000000)
  local enemy=waitFor(function()return E.GetEnemy(1,player)end)
  local root=player.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=enemy.CombatZone.CFrame
  task.wait(.35)
  local ok,reason=E.TryManualAttack(player);assert(ok,reason)
  waitFor(function()return E.GetPlayerState(player).Defeated[1]end,8)
  local entry=waitFor(function()
   local id=player:GetAttribute("__WBQALastDrop")
   local row=id and game.ServerStorage.__WBQAEvents:FindFirstChild(id)
   return row and row.Value~="" and row
  end,10)
  task.wait(.4)
  return {Drop=game.HttpService:JSONDecode(entry.Value),Bag=Run.GetSnapshot(player),First=d.FirstStage1Reward,Ores=d.OwnedOres}
 elseif action=="return" then
  local before=Run.GetSnapshot(player)
  local ok,reason=Return.Request(player,before.RunId);assert(ok,reason)
  task.wait(.3)
  return {Reason=reason,Before=before,After=Run.GetSnapshot(player),OwnedItems=d.OwnedItems,First=d.FirstStage1Reward}
 elseif action=="reload" then
  D.Get(player).Dirty=true;assert(D.Save(player));D.Release(player);assert(D.Load(player))
  return {First=D.Get(player).Data.FirstStage1Reward,Ores=D.Get(player).Data.OwnedOres,Items=D.Get(player).Data.OwnedItems}
 elseif action=="death" then
  local old=player.Character;old.Humanoid.Health=0
  waitFor(function()return player.Character and player.Character~=old and player.Character:FindFirstChild("HumanoidRootPart")end,15)
  return {First=D.Get(player).Data.FirstStage1Reward}
 elseif action=="admin" then
  local Prod=require(S.__WBQAProdData)
  local prodStore=Mem.DataStoreService:GetDataStore("PlayerData_v1")
  local base=Mem.DataStoreService:GetDataStore("PlayerData_v1_Studio"):GetAsync("Player_"..player.UserId)
  local checks={}
  for _,id in {10591394123,10653503502} do
   prodStore:SetAsync("Player_"..id,base)
   local before=prodStore:GetAsync("Player_"..id)
   local ok,result=Debug.Execute(player,"/setwin 1000 "..id)
   assert(not ok and result:find("PendingOnlineSessionOrNextLogin",1,true),result)
   local saved=prodStore:GetAsync("Player_"..id)
   assert(saved.Win==before.Win and saved.OwnedOres.ORE_001==before.OwnedOres.ORE_001)
   local attrs={};local fake={UserId=id,Name="QA"..id,Parent=nil,SetAttribute=function(_,k,v)attrs[k]=v end,GetAttribute=function(_,k)return attrs[k] end,Destroy=function()end}
   assert(Prod.Load(fake));assert(Prod.Get(fake).Data.Win==1000)
   assert(Prod.Get(fake).Data.OwnedOres.ORE_001==before.OwnedOres.ORE_001)
   Prod.Release(fake);fake:Destroy()
   table.insert(checks,{Case="Offline "..id,Status=result,NextLoginWin=1000})
  end
  -- A separate native production-session module owns this in-memory key.
  assert(Prod.Load(player));local ps=Prod.Get(player)
  Prod.SetWin(player,37);ps.Dirty=true;assert(Prod.Save(player))
  local original=ps.Data.OwnedOres.ORE_001
  Mem.SubscribeHook=function(topic,data) if data.UserId==player.UserId then task.defer(function()Prod.SyncProductionWin(player)end) end end
  local ok,result=Debug.Execute(player,"/setwin 1000 "..player.UserId)
  assert(ok and result:find("Applied",1,true),result)
  assert(ps.Data.Win==1000 and player:GetAttribute("Win")==1000)
  assert(ps.Data.OwnedOres.ORE_001==original)
  ps.Dirty=true;assert(Prod.Save(player));assert(prodStore:GetAsync("Player_"..player.UserId).Win==1000)
  table.insert(checks,{Case="Online",Status=result,Live=ps.Data.Win,Autosave=1000})
  -- Uncertain commit: retain the session barrier and recover exactly once.
  Mem.SubscribeHook=nil
  local queued,why=Debug.Execute(player,"/setwin 0 "..player.UserId);assert(not queued,why)
  Mem.FailAfter=1
  local applied,reason=Prod.SyncProductionWin(player)
  assert(not applied and ps.PendingAdminWin and ps.Saving,reason)
  local blocked=Prod.Save(player);assert(not blocked)
  assert(Prod.SyncProductionWin(player));assert(ps.Data.Win==0 and not ps.PendingAdminWin and not ps.Saving)
  Prod.SetWin(player,7);ps.Dirty=true;assert(Prod.Save(player))
  assert(Prod.SyncProductionWin(player));assert(ps.Data.Win==7)
  table.insert(checks,{Case="LostAckRetry",First=reason,AfterRetry=0,LaterEarnedWin=7})
  local bad={}
  for _,command in {"/setwin -1 "..player.UserId,"/setwin 1.5 "..player.UserId,"/setwin 1 0","/setwin 1 nan","/setwin 1 "..player.UserId.." extra"} do
   local accepted=Debug.Execute(player,command);assert(not accepted);table.insert(bad,command)
  end
  return {Checks=checks,Rejected=bad,OwnStudioWin=D.Get(player).Data.Win,ProductionLive=ps.Data.Win}
 elseif action=="adminStatus" then
  local Prod=require(S.__WBQAProdData)
  return {Win=Prod.Get(player) and Prod.Get(player).Data.Win,Attr=player:GetAttribute("Win"),MemoryWrites=Mem.Writes}
 end
end
