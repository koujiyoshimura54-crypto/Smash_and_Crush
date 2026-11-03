-- Temporary native Play fixture. Every persistence/service handle is isolated first.
local RS=game.ReplicatedStorage
local Memory=require(RS.__PMQAMemory)
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local E=require(S.EggServer)
local H=game.HttpService
local Pet=require(RS.Modules.Pet)
local Store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn,seconds)
 local limit=os.clock()+(seconds or 20)
 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>limit
 error("PM QA timed out")
end
local function ready()return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function root()return waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)end
local function reload()
 local old=ready().PetViewGeneration or 0;D.Release(p);assert(D.Load(p))
 D.Get(p).PetViewGeneration=old+1;p:SetAttribute("PetViewGeneration",old+1)
end
local function setup(v)
 v=v or {};local s=ready();if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
 ready();assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));D.SetWin(p,0);assert(D.Save(p))
 Store:UpdateAsync("Player_"..p.UserId,function(raw)
  local pets=assert(Pet.NormalizeState(nil))
  for i,name in v.Names or {"Grey Cat"} do local id=string.format("00000000-0000-0000-0000-%012d",i);pets.Owned[id]=name
   if i<=(v.Equipped or 0)then pets.Equipped[i]=id end
   if v.Protected and table.find(v.Protected,i)then pets.Protected=pets.Protected or {};pets.Protected[id]=true end
  end
  raw.Pets=pets;raw.PetMergeTutorial={Version=1,Eligible=true,Completed=false}
  if v.Legacy then raw.PetMergeTutorial=nil end
  raw.EggPetTutorial={Version=1,Eligible=v.Legacy~=true,Completed=v.EggComplete==true,Acquired={}}
  return raw
 end)
 reload();p:SetAttribute("CurrentWorld",v.World or 1);require(S.LobbySpawnService).MoveToLobby(p,p.Character,v.World or 1);root().Anchored=true
end
local function status()
 local s=D.Get(p);return {Tutorial=s.Data.PetMergeTutorial,Egg=s.Data.EggPetTutorial,Pets=D.GetPetState(p),Win=s.Data.Win,Generation=s.PetViewGeneration or 0,Pending=s.PendingItemMutation~=nil,World=p:GetAttribute("CurrentWorld")}
end
local last
local probe=Instance.new("BindableFunction");probe.Name="__PMQA"
probe.OnInvoke=function(action,v)
 if action=="Status"then return status()
 elseif action=="Setup"then setup(v)
 elseif action=="MergeArea"then
  local model=workspace.RestockShop
  if p:GetAttribute("CurrentWorld")==2 then model=workspace.World2Map.TrainingArea.FacilityDisplays.MergeDisplay end
  root().CFrame=model.Area.CFrame+Vector3.new(0,2,0)
 elseif action=="Lobby"then require(S.LobbySpawnService).MoveToLobby(p,p.Character,p:GetAttribute("CurrentWorld"));root().Anchored=true
 elseif action=="Outside"then root().CFrame=workspace.GeneratedMap.BattleCorridor.Stage01.Floor.CFrame+Vector3.new(0,6,0)
 elseif action=="World"then p:SetAttribute("CurrentWorld",v);require(S.LobbySpawnService).MoveToLobby(p,p.Character,v);root().Anchored=true
 elseif action=="Mutate"then
  ready();assert(D.Save(p));Store:UpdateAsync("Player_"..p.UserId,function(raw)
   if v.Equipped then raw.Pets.Equipped=v.Equipped end
   if v.Protected then raw.Pets.Protected=v.Protected end
   if v.Names then for i,name in v.Names do raw.Pets.Owned[string.format("00000000-0000-0000-0000-%012d",i)]=name end end
   if v.EggEligible~=nil then raw.EggPetTutorial.Eligible=v.EggEligible end
   return raw end)
  reload()
 elseif action=="Request"then local pets,_,g=D.GetPetState(p);last={v.Action,H:GenerateGUID(false),pets.Revision,v.A,v.B,g};return E.request(p,table.unpack(last,1,6))
 elseif action=="Replay"then return E.request(p,table.unpack(assert(last),1,6))
 elseif action=="Remember"then local pets,_,g=D.GetPetState(p);last={"Merge",H:GenerateGUID(false),pets.Revision,v,nil,g};return last
 elseif action=="FailBefore"then Memory.FailBefore=v
 elseif action=="FailAfter"then Memory.FailAfter=v
 elseif action=="Resolve"then Memory.FailBefore=0;Memory.FailAfter=0;return {D.ResolveItemMutation(p)}
 elseif action=="InvalidResult"then
  local pets,_,g=D.GetPetState(p);return {D.MutatePets(p,H:GenerateGUID(false),pets.Revision,"Merge",{Materials=v,EggName="Basic",Results={{id=H:GenerateGUID(false),pet="not a Pet",percent=25}}},g)}
 elseif action=="Reset"then ready();local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,"/resetdata");assert(ok,why);D.SetAutoTapEnabled(p,false)
 elseif action=="FloorComplete"then ready();assert(D.CompleteTutorial(p))
 elseif action=="FloorWaiting"then p:SetAttribute("TutorialCompleted",false)
 elseif action=="FloorResume"then p:SetAttribute("TutorialCompleted",true)
 elseif action=="Win"then D.SetWin(p,v)
 elseif action=="Ore"then ready();assert(require(S.ForgeService).GrantOre(p,"ORE_001",H:GenerateGUID(false)))
 elseif action=="OreMerge"then local F=require(S.ForgeService);local s=F.State(p);return F.Request(p,{Action="MergeOre",Materials={ORE_001=2},Id=H:GenerateGUID(false),Sequence=s.Sequence+1,Token=s.Token,Generation=s.Generation})
 elseif action=="Death"then root().Anchored=false;local old=p.Character;old.Humanoid.Health=0;waitFor(function()return p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end,25);root().Anchored=true
 elseif action=="Reload"then ready();assert(D.Save(p));reload()
 elseif action=="Disk"then ready();assert(D.Save(p));return Store:GetAsync("Player_"..p.UserId)
 elseif action=="Busy"then p:SetAttribute("RunReturnBusy",v)
 else error(action)end
 return status()
end
probe.Parent=game.ServerStorage
setup()
print("[PM QA] isolated fixture ready")
