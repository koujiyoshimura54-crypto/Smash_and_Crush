-- Native, memory-only balance driver. Never install without service isolation.
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
local Memory=require(RS.__PhaseTaskMemory);local D=require(S.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local Boss=require(game.ServerScriptService.World.BossCombatService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn)
 local deadline=os.clock()+40 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>deadline;error('Balance QA timeout')
end
local function ready()return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
ready();if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end
D.SetAutoTapEnabled(p,false)
local function root()return waitFor(function()return p.Character and p.Character:FindFirstChild('HumanoidRootPart')end)end
local function lobby(world)p:SetAttribute('CurrentWorld',world);root();assert(require(S.LobbySpawnService).MoveToLobby(p,p.Character,world));root().Anchored=true end
local function profile()
 local s=ready();return {Strength=s.Data.Strength,Level=s.Data.Level,Progress=s.Data.LevelProgress,Rebirth=s.Data.RebirthCount,AttributeLevel=p:GetAttribute('Level'),AttributeStrength=p:GetAttribute('Strength')}
end
local function saveReload()
 ready().Dirty=true;assert(D.Save(p));D.Release(p);assert(D.Load(p));if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end;D.SetAutoTapEnabled(p,false)
end
local probe=Instance.new('BindableFunction');probe.Name='__PhaseBalance';probe.Parent=game.ServerStorage
probe.OnInvoke=function(action,v)
 if action=='Pure' then return require(RS.__PhaseLevelsPure)
 elseif action=='Profile' then return profile()
 elseif action=='SeedLevel' then
  ready().Dirty=true;assert(D.Save(p));local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName('PlayerData_v1'))
  store:UpdateAsync('Player_'..p.UserId,function(raw)raw.Strength=v.Strength;raw.Level=v.Level;raw.LevelProgress=v.Progress;raw.LevelProgressVersion=1;return raw end)
  D.Release(p);assert(D.Load(p));if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end;D.SetAutoTapEnabled(p,false);lobby(1);return profile()
 elseif action=='Gain' then assert(require(S.StrengthManager).AddRewardStrength(p,v));return profile()
 elseif action=='Reload' then saveReload();return profile()
 elseif action=='Stage' then
  local world=v.World or 2;local n=v.Stage;local E=Enemy.ForWorld(world);local W=Wall.ForWorld(world);local B=Boss.ForWorld(world)
  waitFor(E.IsReady);lobby(world);E.InitializePlayer(p,n)
  local e=waitFor(function()return E.GetEnemy(n,p)end)
  local snapshot=W.GetSnapshotForStage(p,n)
  local actual=B.Begin(p,e,n)
  local result={World=world,Stage=n,BossHP=e:GetAttribute('BossMaxHP'),BossGauge=E.GetGauge(p,n),EncounterHP=actual.HP,
   RecommendedLevel=e:GetAttribute('RecommendedLevel'),RequiredStrength=actual.RequiredStrength,Walls=snapshot.Gauges,Maxes=snapshot.Maxes}
  B.Cancel(p);return result
 elseif action=='WallHit' then
  local W=Wall.ForWorld(2);W.ApplyDamageForStage(p,v.Stage,v.Amount);Enemy.ForWorld(2).SendState(p);return W.GetSnapshotForStage(p,v.Stage)
 elseif action=='Death' then local old=p.Character;root().Anchored=false;old.Humanoid.Health=0;waitFor(function()return p.Character and p.Character~=old and p.Character:FindFirstChild('HumanoidRootPart')end);lobby(2);return Wall.ForWorld(2).GetSnapshotForStage(p,v or 1)
 elseif action=='Travel' then lobby(v);Enemy.ForWorld(v).InitializePlayer(p,1);return {World=p:GetAttribute('CurrentWorld'),Walls=Wall.ForWorld(v).GetSnapshotForStage(p,1)}
 else error(action)end
end
lobby(1)
print('[PhaseBalance] native memory driver ready')
