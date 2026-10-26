-- Installed temporarily for isolated native Play QA, then removed in Edit.
local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Forge=require(game.ServerScriptService.Services.ForgeService)
local Http=game:GetService("HttpService")
local memory=require(game.ReplicatedStorage.__OreQAMemory)
local bridge=Instance.new("BindableFunction");bridge.Name="__OreQABridge";bridge.Parent=game.ServerScriptService
bridge.OnInvoke=function(action,args)
 local p=Players:GetPlayers()[1];assert(p)
 local s=Data.Get(p)
 if action=="State" then return {Forge=Forge.State(p),Pets=Data.GetPetState(p),Override=s.StudioStartOverride~=nil,Pending=s.PendingItemMutation~=nil,Writes=memory.Writes} end
 if action=="Override" then return Data.ApplyStudioStartLevel(p,100,10) end
 if action=="Restore" then return Data.RestoreStudioStartOverride(p) end
 if action=="FailAfter" then memory.FailAfter=args or 1;return true end
 if action=="FailBefore" then memory.FailBefore=args or 1;return true end
 if action=="GrantOre" then return Forge.GrantOre(p,args.Id,args.DropId or Http:GenerateGUID(false)) end
 if action=="Save" then return Data.Save(p) end
 if action=="Win" then return Data.SetWin(p,args) end
 if action=="Equip" then return require(game.ServerScriptService.Services.DumbbellService).EquipDumbbell(p,args) end
 if action=="PrepareStage" then
  local E=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
  local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
  p:SetAttribute("CurrentWorld",1);Data.SetAutoTapEnabled(p,false);Data.SetCurrentStrength(p,10000000000)
  E.StartRun(p,args);W.ApplyDamageForStage(p,args,10000000000)
  local actor
  for _=1,50 do actor=E.GetEnemy(args,p);if actor then break end;task.wait(.1) end
  assert(actor,"Actor missing")
  local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=actor.CombatZone.CFrame
  return true
 end
 if action=="Attack" then return require(game.ServerScriptService.World.EnemyManager).ForWorld(1).TryManualAttack(p) end
 if action=="FillBag" then
  local R=require(game.ServerScriptService.Services.RunInventoryService)
  local snapshot=R.GetSnapshot(p)
  local first for id,row in pairs(require(game.ReplicatedStorage.Config.ItemMaster).GetAll()) do if (row.WorldId or 1)==1 then first=id;break end end
  while snapshot.Count<snapshot.Capacity do
   assert(R.TryAddDrop(p,snapshot.RunId,Http:GenerateGUID(false),first))
   snapshot=R.GetSnapshot(p)
  end
  return snapshot
 end
 if action=="WorldRoundTrip" then
  local before=Forge.State(p);p:SetAttribute("CurrentWorld",2);task.wait(.2);p:SetAttribute("CurrentWorld",1);task.wait(.2)
  return {Before=before,After=Forge.State(p)}
 end
 if action=="Saved" then
  local config=require(game.ServerScriptService.Config.DataStoreConfig)
  return memory.DataStoreService:GetDataStore(config.GetName("PlayerData_v1")):GetAsync("Player_"..p.UserId)
 end
 error("Unknown QA action")
end
local function prepare(p)
 while not Data.IsLoaded(p) or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") do task.wait(.1) end
 Data.RestoreStudioStartOverride(p)
 Data.SetWin(p,100000)
 local state,_,generation=Data.GetPetState(p)
 local results={}
 for _,name in {"Dog","Grey Cat","Pink Bunny","Sheep","Bear","Camel","Slime","Dog"} do
  table.insert(results,{id=Http:GenerateGUID(false),pet=name,percent=require(game.ReplicatedStorage.Modules.Egg).pets("Basic")[name],duplicate=false,bonus=0})
 end
 local ok,why=Data.MutatePets(p,Http:GenerateGUID(false),state.Revision,"Hatch",{EggName="Basic",Count=8,PriceWin=120,Results=results},generation)
 assert(ok,why)
 for _,ore in ipairs(require(game.ReplicatedStorage.Config.OreConfig).GetAvailable()) do
  for _=1,8 do local granted,reason=Forge.GrantOre(p,ore.Id,Http:GenerateGUID(false));assert(granted,reason) end
  task.wait()
 end
 Data.SetAutoTapEnabled(p,false)
 local item=require(game.ReplicatedStorage.Config.ItemMaster).GetAll()
 local first for id,row in pairs(item) do if (row.WorldId or 1)==1 and row.Rarity=="Common" then first=id;break end end
 if first then local added,reason=require(game.ServerScriptService.Services.ItemService).AddItem(p,first,4);assert(added,reason) end
 task.wait(2)
 p.Character.HumanoidRootPart.CFrame=workspace.RestockShop.Area.CFrame+Vector3.new(0,3,0)
 bridge:SetAttribute("Ready",true)
end
Players.PlayerAdded:Connect(function(p) task.spawn(prepare,p) end)
for _,p in Players:GetPlayers() do task.spawn(prepare,p) end
