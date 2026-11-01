-- Temporary native solo-Play probe. Requires every DataStore/Badge dependency to use __UI2Memory.
local RS=game.ReplicatedStorage
local Memory=require(assert(RS:FindFirstChild("__UI2Memory")))
local Services=game.ServerScriptService.Services
local Data=require(Services.PlayerDataService)
local Forge=require(Services.ForgeService)
local Time=require(Services.TimeRewardService)
local Debug=require(game.ServerScriptService.Systems.Debug.StudioDebugService)
local Placement=require(Services.LobbySpawnService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn,seconds)
 local limit=os.clock()+seconds
 repeat local value=fn();if value then return value end;task.wait(.1) until os.clock()>limit
 error("Fixture condition timed out")
end
waitFor(function()local s=Data.Get(p);return s and s.Loaded and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,20)
Data.SetAutoTapEnabled(p,false)
local function idle()waitFor(function()local s=Data.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation end,10)end
local function data()return Data.Get(p).Data end
local function request(amount)
 local state=Forge.State(p)
 return {Action="MergeOre",Materials={ORE_001=amount},Id=game.HttpService:GenerateGUID(false),
  Sequence=state.Sequence+1,Token=state.Token,Generation=state.Generation}
end
local function status()
 local d=data();local bells=0;for _,n in d.OwnedDumbbells do bells+=n end
 return {Tutorial=d.OreMergeTutorial,Floor=d.TutorialCompleted,Ores=table.clone(d.OwnedOres),Bells=bells,
  Token=Forge.State(p).Token,Journal=table.clone(d.ForgeJournal),First=d.FirstStage1Reward,
  Time=d.TimeRewards.Claimed,Pending=Data.Get(p).PendingItemMutation~=nil}
end
local last
local probe=Instance.new("BindableFunction");probe.Name="__OreQA"
probe.OnInvoke=function(action,value)
 if action=="Status" then return status() end
 if action=="FailWrites" then Memory.FailBefore=value;return true end
 if action=="Resolve" then Memory.FailBefore=0;assert(Data.ResolveItemMutation(p));return status() end
 idle()
 if action=="Reset" then
  local ok,why=Debug.Execute(p,"/resetdata");assert(ok,why);Data.SetAutoTapEnabled(p,false)
  assert(data().OreMergeTutorial.Eligible and not data().OreMergeTutorial.Completed)
  assert(not data().FirstStage1Reward.Consumed and not next(data().TimeRewards.Claimed))
  return {Command=why,State=status()}
 elseif action=="TimeStone" then
  data().TimeRewards.ElapsedSeconds=60;Data.Get(p).TimeRewardClock=os.clock()
  local ok,why=Time.Claim(p,"StoneIntro01");assert(ok,why)
 elseif action=="Ore" then
  for _=1,value.Count do idle();local ok,why=Forge.GrantOre(p,value.Id,game.HttpService:GenerateGUID(false));assert(ok,why) end
 elseif action=="FloorComplete" then assert(Data.CompleteTutorial(p))
 elseif action=="BossAndTrophy" then
  local Enemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
  local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
  waitFor(Enemy.IsReady,15);Data.SetCurrentStrength(p,1000000000);Enemy.StartRun(p,1)
  Wall.ApplyDamageForStage(p,1,1000000000)
  local actor=waitFor(function()return Enemy.GetEnemy(1,p)end,10)
  local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=actor.CombatZone.CFrame;task.wait(.35)
  local ok,why=Enemy.TryManualAttack(p);assert(ok,why)
  waitFor(function()return data().FirstStage1Reward.Consumed end,10)
  root.Anchored=false
  local pad=workspace.GeneratedMap.BattleCorridor.Stage01.TrophyNormalButton.Handle
  p.Character:PivotTo(pad.CFrame+CFrame.new(0,3,0).Position)
  waitFor(function()return data().TutorialCompleted end,12)
  waitFor(function()return not p:GetAttribute("RunReturnBusy")end,10)
  Placement.MoveToLobby(p,p.Character,1);Data.SetCurrentStrength(p,0)
 elseif action=="Lobby" then Placement.MoveToLobby(p,p.Character,1)
 elseif action=="LeaveLobby" then p.Character:PivotTo(workspace.GeneratedMap.BattleCorridor.Stage01.Floor.CFrame+Vector3.new(0,6,0))
 elseif action=="Death" then
  local old=p.Character;old.Humanoid.Health=0;waitFor(function()return p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end,12)
 elseif action=="Merge" then last=request(value);return Forge.Request(p,last)
 elseif action=="Remember" then last=request(2);return last
 elseif action=="Replay" then return Forge.Request(p,assert(last))
 elseif action=="ReplayJournal" then
  local state=Forge.State(p);local r=request(2);r.Id=state.Journal.Id;r.Sequence=state.Journal.Sequence;return Forge.Request(p,r)
 elseif action=="Reload" then
  Data.Get(p).Dirty=true;assert(Data.Save(p));Data.Release(p);assert(Data.Load(p))
 elseif action=="Legacy" then
  local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
  Data.Get(p).Dirty=true;assert(Data.Save(p));store:UpdateAsync("Player_"..p.UserId,function(raw)raw.OreMergeTutorial=nil;return raw end)
  Data.Release(p);assert(Data.Load(p))
 elseif action=="SellOne" then
  local r=request(1);r.Action="SellOre";return Forge.Request(p,r)
 else error("Unknown fixture action") end
 return status()
end
probe.Parent=RS
print("[OreTutorial QA] memory fixture ready")
