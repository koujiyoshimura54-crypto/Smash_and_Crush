-- Temporary native fixture; all service handles must be isolated before Play.
assert(game.ReplicatedStorage:FindFirstChild("__EquipQAMemory"))
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService);local F=require(S.ForgeService);local Item=require(S.ItemService);local Bell=require(S.DumbbellService)
local E=require(RS.Modules.EquipmentTutorialState);local Memory=require(RS.__EquipQAMemory);local H=game.HttpService
local Store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn,seconds)
 local untilAt=os.clock()+(seconds or 25)
 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>untilAt;error("Equipment QA timed out")
end
local function ready()return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function root()return waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)end
local function lobby()
 root();p:SetAttribute("CurrentWorld",1);assert(require(S.LobbySpawnService).MoveToLobby(p,p.Character,1));root().Anchored=true
end
local function reload()
 local generation=(D.Get(p).PetViewGeneration or 0)+10
 D.Release(p);assert(D.Load(p));D.Get(p).PetViewGeneration=generation;p:SetAttribute("PetViewGeneration",generation)
 D.SetAutoTapEnabled(p,false);lobby()
end
local function setup(v)
 v=v or {};local s=ready();if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
 ready();assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));D.SetWin(p,0);assert(D.Save(p))
 Store:UpdateAsync("Player_"..p.UserId,function(raw)
  raw.OwnedItems=v.Items or {};raw.EquippedItems=v.EquippedItems or {Protein="",Glove="",TrainingBelt=""}
  raw.OwnedDumbbells=v.Bells or {};raw.EquippedDumbbell=v.Equipped or ""
  raw.OwnedOres=v.Ores or {}
  raw.OreMergeTutorial.Completed=v.OreDone==true
  raw.EggPetTutorial.Completed=v.EggDone~=false
  if v.Legacy then raw.EggPetTutorial.Eligible=false;raw.OreMergeTutorial.Eligible=false;raw.EquipmentTutorial=nil end
  return raw
 end)
 reload()
end
local function status()
 local s=ready()
 return {Tutorial=s.Data.EquipmentTutorial,Ore=s.Data.OreMergeTutorial,Items=s.Data.OwnedItems,EquippedItems=s.Data.EquippedItems,
 Bells=s.Data.OwnedDumbbells,Equipped=s.Data.EquippedDumbbell,Bonus=Bell.GetStrengthBonus(p),Ores=s.Data.OwnedOres,
 ItemReady=p:GetAttribute("ItemEquipTutorialReady"),BellReady=p:GetAttribute("DumbbellEquipTutorialReady"),
 Win=s.Data.Win,Token=s.ForgeToken,Run=require(S.RunInventoryService).GetSnapshot(p)}
end
local lastRequest,bagId
local probe=Instance.new("BindableFunction");probe.Name="__EquipQAServer";probe.Parent=RS
probe.OnInvoke=function(action,v)
 if action=="Setup" then setup(v)
 elseif action=="Status" then return status()
 elseif action=="Bag" then local run=require(S.RunInventoryService);bagId=run.Reset(p,true);assert(run.TryAddDrop(p,bagId,H:GenerateGUID(false),v or "PROTEIN_COMMON_FIRE"));D.RefreshEquipmentTutorial(p)
 elseif action=="Return" then local ok,why=require(S.RunReturnService).Request(p,bagId);assert(ok,why);root().Anchored=true
 elseif action=="Item" then return {Item.EquipItem(p,v)}
 elseif action=="ItemBest" then return {Item.EquipBestItems(p)}
 elseif action=="Bell" then return {Bell.EquipDumbbell(p,v)}
 elseif action=="BellBest" then return {Bell.EquipBestDumbbell(p)}
 elseif action=="Ore" then assert(F.GrantOre(p,"ORE_001",H:GenerateGUID(false)))
 elseif action=="Merge" then local s=F.State(p);lastRequest={Action="MergeOre",Materials=v or {ORE_001=2},Id=H:GenerateGUID(false),Sequence=s.Sequence+1,Token=s.Token,Generation=s.Generation};return F.Request(p,lastRequest)
 elseif action=="Replay" then return F.Request(p,lastRequest)
 elseif action=="Sell" then local s=F.State(p);return F.Request(p,{Action="SellDumbbell",ItemId=v.Id,Count=v.Count,Id=H:GenerateGUID(false),Sequence=s.Sequence+1,Token=s.Token,Generation=s.Generation})
 elseif action=="Reload" then ready();assert(D.Save(p));reload()
 elseif action=="Disk" then ready();assert(D.Save(p));local d=Store:GetAsync("Player_"..p.UserId);return {Tutorial=d.EquipmentTutorial,Item=d.EquippedItems,Bell=d.EquippedDumbbell,Ore=d.OreMergeTutorial}
 elseif action=="Reset" then ready();local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,"/resetdata");assert(ok,why);D.SetAutoTapEnabled(p,false);lobby()
 elseif action=="Floor" then assert(D.CompleteTutorial(p))
 elseif action=="Busy" then p:SetAttribute("RunReturnBusy",v)
 elseif action=="Death" then local old=p.Character;root().Anchored=false;old.Humanoid.Health=0;waitFor(function()return p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end);lobby()
 elseif action=="FailSave" then Memory.FailBefore=1;return {D.Save(p)}
 elseif action=="Grant" then assert(Item.AddItem(p,v,1))
 elseif action=="Win" then D.SetWin(p,v)
 elseif action=="PetSeed" then
  assert(D.Save(p));Store:UpdateAsync("Player_"..p.UserId,function(raw)
   local pets=require(RS.Modules.Pet).NormalizeState(nil)
   pets.Owned["00000000-0000-0000-0000-000000000001"]="Grey Cat";pets.Owned["00000000-0000-0000-0000-000000000002"]="Dog"
   raw.Pets=pets;raw.PetMergeTutorial={Version=1,Eligible=true,Completed=false};return raw end)
  reload()
 elseif action=="Gain" then local before=D.Get(p).Data.Strength;require(S.StrengthManager).AddStrength(p,1,1,1);return {Before=before,After=D.Get(p).Data.Strength,Bonus=Bell.GetStrengthBonus(p)}
 else error(action)end
 return status()
end
setup()
print("[Equipment QA] native isolated server ready")
