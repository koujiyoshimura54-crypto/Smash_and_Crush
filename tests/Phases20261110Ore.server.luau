-- Native test driver; install ONLY with __PhaseTaskMemory service isolation.
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
local Memory=require(RS.__PhaseTaskMemory);local D=require(S.PlayerDataService);local F=require(S.ForgeService)
local H=require(RS.Modules.HigherOreMergeTutorialState)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName('PlayerData_v1'))
local function waitFor(fn)
 local deadline=os.clock()+40 repeat local v=fn();if v then return v end;task.wait(.1)until os.clock()>deadline;error('Ore phase QA timeout')
end
local function ready()return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function lobby()
 waitFor(function()return p.Character and p.Character:FindFirstChild('HumanoidRootPart')end)
 p:SetAttribute('CurrentWorld',1);assert(require(S.LobbySpawnService).MoveToLobby(p,p.Character,1));p.Character.HumanoidRootPart.Anchored=true
end
local function reload()
 D.Release(p);assert(D.Load(p));if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end
 D.SetAutoTapEnabled(p,false);lobby()
end
local function setup(v)
 v=v or {};ready();if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end
 assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));assert(D.Save(p))
 store:UpdateAsync('Player_'..p.UserId,function(raw)
  raw.OwnedOres=v.Ores or {};raw.OwnedDumbbells={NORMAL_01=1};raw.EquippedDumbbell='NORMAL_01'
  raw.OreMergeTutorial.Completed=v.InitialDone~=false
  raw.EquipmentTutorial.DumbbellCompleted=true;raw.EquipmentTutorial.ItemCompleted=true
  raw.EggPetTutorial.Completed=true;raw.PetMergeTutorial.Completed=true
  if v.Legacy then raw.OreMergeTutorial.Eligible=false;raw.HigherOreMergeTutorial=nil end
  return raw
 end);reload()
end
local function status()
 local s=ready();return {Higher=s.Data.HigherOreMergeTutorial,Initial=s.Data.OreMergeTutorial,Equipment=s.Data.EquipmentTutorial,
 Ores=s.Data.OwnedOres,Bells=s.Data.OwnedDumbbells,Equipped=s.Data.EquippedDumbbell,EligibleSelection=H.Selection(s.Data.OwnedOres,D.HasReachedWorld2(p))~=nil,
 EquipCompleted=p:GetAttribute('DumbbellEquipTutorialCompleted'),Token=s.ForgeToken}
end
local last
local function merge(materials)
 local state=F.State(p);last={Action='MergeOre',Materials=materials,Id=game.HttpService:GenerateGUID(false),Token=state.Token,Generation=state.Generation,Sequence=state.Sequence+1}
 return F.Request(p,last)
end
local probe=Instance.new('BindableFunction');probe.Name='__PhaseOreServer';probe.Parent=game.ServerStorage
probe.OnInvoke=function(action,v)
 if action=='Setup' then setup(v)
 elseif action=='Status' then return status()
 elseif action=='Merge' then return merge(v)
 elseif action=='Replay' then return F.Request(p,last)
 elseif action=='SaveReload' then ready().Dirty=true;assert(D.Save(p));reload()
 elseif action=='Fail' then Memory.FailAfter=1;return merge(v)
 elseif action=='Resolve' then return {D.ResolveItemMutation(p)}
 elseif action=='Reset' then local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,'/resetdata');assert(ok,why);D.SetAutoTapEnabled(p,false);lobby()
 elseif action=='Equip' then return {require(S.DumbbellService).EquipBestDumbbell(p)}
 elseif action=='Death' then local c=p.Character;c.HumanoidRootPart.Anchored=false;c.Humanoid.Health=0;waitFor(function()return p.Character~=c and p.Character and p.Character:FindFirstChild('HumanoidRootPart')end);lobby()
 elseif action=='Bag' then local run=require(S.RunInventoryService);local id=run.Reset(p,true);assert(run.TryAddOreDrop(p,id,'qa-ore1','ORE_003'));assert(run.TryAddOreDrop(p,id,'qa-ore2','ORE_003'))
 elseif action=='Busy' then p:SetAttribute('RunReturnBusy',v)
 else error(action)end
 return status()
end
setup({Ores={ORE_003=2}})
print('[PhaseOre] isolated native driver ready')
