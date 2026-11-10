-- Native isolated QA only. External services MUST be redirected to __PhaseTaskMemory.
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
assert(RS:FindFirstChild("__PhaseTaskMemory"))
local D=require(S.PlayerDataService);local Stand=require(RS.Config.DumbbellStandConfig)
local Master=require(RS.Config.DumbbellItemMaster);local Service=require(S.DumbbellService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn)
 local deadline=os.clock()+30 repeat local v=fn();if v then return v end;task.wait(.1)until os.clock()>deadline;error("Stand QA timeout")
end
local function ready()return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function root()return waitFor(function()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)end
ready();if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p) end
D.SetAutoTapEnabled(p,false);D.CompleteTutorial(p)
local data=ready().Data;data.OwnedOres={ORE_003=2};data.OwnedDumbbells={NORMAL_01=1};data.EquippedDumbbell="NORMAL_01"
data.OreMergeTutorial.Completed=true;data.EquipmentTutorial.DumbbellCompleted=true;data.EquipmentTutorial.ItemCompleted=true
data.EggPetTutorial.Completed=true;data.PetMergeTutorial.Completed=true;data.Win=10000000;ready().Dirty=true
assert(D.Save(p))
local memory=require(RS.__PhaseTaskMemory)
local store=memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
store:UpdateAsync("Player_"..p.UserId,function(raw)
 raw.OwnedOres={ORE_003=2};raw.OwnedDumbbells={NORMAL_01=1};raw.EquippedDumbbell="NORMAL_01";raw.Win=10000000
 raw.OreMergeTutorial.Completed=true;raw.EquipmentTutorial.DumbbellCompleted=true;raw.EquipmentTutorial.ItemCompleted=true
 raw.EggPetTutorial.Completed=true;raw.PetMergeTutorial.Completed=true;return raw
end)
D.Release(p);assert(D.Load(p));if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p) end
D.SetAutoTapEnabled(p,false);p:SetAttribute("CurrentWorld",1);root();require(S.LobbySpawnService).MoveToLobby(p,p.Character,1);root().Anchored=true
local b=Instance.new("BindableFunction");b.Name="__PhaseStandServer";b.Parent=game.ServerStorage
b.OnInvoke=function(action,arg)
 if action=="Gate" then
  assert(D.UnlockWorld(p,2));local trigger=arg==2 and workspace.World2Gate.WorldGateTrigger or workspace.World2Map.TrainingArea.World1ReturnGate.WorldGateTrigger
  root().Anchored=true;root().CFrame=trigger.CFrame;return true
 elseif action=="Purchase" then
  local world=arg.World;local i=arg.Index;assert((p:GetAttribute("CurrentWorld") or 1)==world)
  local id=Stand.GetItemId(i,world);local item=Master.Get(id);local before=p:GetAttribute("Win")
  assert(not Service.HasDumbbell(p,id));local m=Stand.GetFolder(world)[tostring(i)]
  root().Anchored=true;root().CFrame=m.Press.CFrame+Vector3.new(0,3,0)
  waitFor(function()return Service.HasDumbbell(p,id) and Service.GetEquippedDumbbell(p)==id end)
  task.wait(.35);assert(p:GetAttribute("Win")==before-item.PriceWin,"Wrong World price")
  local result={Id=id,Name=item.Name,Price=item.PriceWin,Debited=before-p:GetAttribute("Win"),Count=ready().Data.OwnedDumbbells[id],Equipped=Service.GetEquippedDumbbell(p)}
  require(S.LobbySpawnService).MoveToLobby(p,p.Character,world);task.wait(.25);return result
 elseif action=="Reenter" then
  local world=arg.World;local id=Stand.GetItemId(arg.Index,world);local before=p:GetAttribute("Win")
  local m=Stand.GetFolder(world)[tostring(arg.Index)];root().CFrame=m.Press.CFrame+Vector3.new(0,3,0);task.wait(.6)
  assert(p:GetAttribute("Win")==before and Service.GetEquippedDumbbell(p)==id)
  require(S.LobbySpawnService).MoveToLobby(p,p.Character,world);return {NoDebit=true,Equipped=id}
 elseif action=="Death" then
  local old=p.Character;root().Anchored=false;old.Humanoid.Health=0
  waitFor(function()return p.Character and p.Character~=old and p.Character:FindFirstChild("HumanoidRootPart")end);task.wait(1)
  return {World=p:GetAttribute("CurrentWorld"),Equipped=Service.GetEquippedDumbbell(p)}
 elseif action=="Position" then root().Anchored=true;root().CFrame=CFrame.new(arg[1],arg[2],arg[3]);return true
 elseif action=="Status" then return {World=p:GetAttribute("CurrentWorld"),Win=p:GetAttribute("Win"),Equipped=Service.GetEquippedDumbbell(p),Counts=ready().Data.OwnedDumbbells}
 else error(action)end
end
