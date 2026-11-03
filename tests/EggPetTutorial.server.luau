-- Temporary native Play fixture; memory services only.
local RS=game.ReplicatedStorage
local Memory=require(RS.__EggQAMemory)
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local E=require(S.EggServer)
local H=game.HttpService
local Store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn,seconds)
 local limit=os.clock()+(seconds or 15)
 repeat local x=fn();if x then return x end;task.wait(.1)until os.clock()>limit
 error("Egg QA timed out")
end
local function ready()
 return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)
end
local function root()return waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)end
local function status()
 local s=D.Get(p)
 return {Tutorial=s.Data.EggPetTutorial,Pets=D.GetPetState(p),Win=s.Data.Win,Generation=s.PetViewGeneration or 0,Pending=s.PendingItemMutation~=nil,
  World=p:GetAttribute("CurrentWorld"),Health=p.Character and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health}
end
local function setup(win)
 local s=ready();if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end
 ready();assert(D.Reset(p));D.SetAutoTapEnabled(p,false);assert(D.CompleteTutorial(p));D.SetWin(p,win or 2)
 p:SetAttribute("CurrentWorld",1)
 require(S.LobbySpawnService).MoveToLobby(p,p.Character,1)
 root().Anchored=true
end
local last
local probe=Instance.new("BindableFunction");probe.Name="__EggQA"
probe.OnInvoke=function(action,v)
 if action=="Status" then return status() end
 if action=="Setup" then setup(v)
 elseif action=="Win" then ready();D.SetWin(p,v)
 elseif action=="Basic" then root().CFrame=workspace.Eggs.Basic.CFrame+Vector3.new(0,0,5)
 elseif action=="Lobby" then root().Anchored=false;require(S.LobbySpawnService).MoveToLobby(p,p.Character,1);root().Anchored=true
 elseif action=="Outside" then root().CFrame=workspace.GeneratedMap.BattleCorridor.Stage01.Floor.CFrame+Vector3.new(0,6,0)
 elseif action=="World2" then p:SetAttribute("CurrentWorld",2);require(S.LobbySpawnService).MoveToLobby(p,p.Character,2);root().Anchored=true
 elseif action=="World1" then p:SetAttribute("CurrentWorld",1);require(S.LobbySpawnService).MoveToLobby(p,p.Character,1);root().Anchored=true
 elseif action=="Request" then
  local pets,_,generation=D.GetPetState(p)
  last={v.Action,H:GenerateGUID(false),pets.Revision,v.A,v.B,generation}
  return E.request(p,table.unpack(last,1,6))
 elseif action=="Replay" then return E.request(p,table.unpack(assert(last),1,6))
 elseif action=="Remember" then local pets,_,generation=D.GetPetState(p);last={"OpenEgg",H:GenerateGUID(false),pets.Revision,"Basic","Open1",generation};return last
 elseif action=="FailBefore" then Memory.FailBefore=v;return true
 elseif action=="FailAfter" then Memory.FailAfter=v;return true
 elseif action=="Resolve" then Memory.FailBefore=0;Memory.FailAfter=0;return {D.ResolveItemMutation(p)}
 elseif action=="Reset" then
  ready();local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,"/resetdata");assert(ok,why);D.SetAutoTapEnabled(p,false)
 elseif action=="FloorComplete" then ready();assert(D.CompleteTutorial(p))
 elseif action=="Ore" then
  ready();assert(require(S.ForgeService).GrantOre(p,"ORE_001",H:GenerateGUID(false)))
 elseif action=="OreMerge" then
  local F=require(S.ForgeService);local state=F.State(p)
  return F.Request(p,{Action="MergeOre",Materials={ORE_001=2},Id=H:GenerateGUID(false),Sequence=state.Sequence+1,Token=state.Token,Generation=state.Generation})
 elseif action=="Death" then root().Anchored=false;local old=p.Character;old.Humanoid.Health=0;waitFor(function()return p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end,20);root().Anchored=true
 elseif action=="Reload" then
  ready();local old=D.Get(p).PetViewGeneration or 0
  assert(D.Save(p));D.Release(p);assert(D.Load(p))
  -- A real rejoin has a fresh client; keep this test client's generation monotonic.
  D.Get(p).PetViewGeneration=old+1;p:SetAttribute("PetViewGeneration",old+1)
 elseif action=="Disk" then ready();assert(D.Save(p));return Store:GetAsync("Player_"..p.UserId)
 elseif action=="Legacy" then
  ready();assert(D.Save(p));Store:UpdateAsync("Player_"..p.UserId,function(raw)raw.EggPetTutorial=nil;return raw end)
  local old=D.Get(p).PetViewGeneration or 0;D.Release(p);assert(D.Load(p));D.Get(p).PetViewGeneration=old+1;p:SetAttribute("PetViewGeneration",old+1)
 elseif action=="Busy" then p:SetAttribute("RunReturnBusy",v)
 else error(action)end
 return status()
end
probe.Parent=game.ServerStorage
setup(2)
print("[Egg QA] isolated fixture ready")
