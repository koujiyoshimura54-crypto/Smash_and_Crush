-- Phase 7.3.3 deterministic regression tests, including Dumbbell regressions.
-- Run in Studio Edit Command Bar: require(game.ServerStorage.Tests.Phase741MovementTests).Run()
-- Production sources are cloned. DataStore, players, Heartbeat and task scheduling
-- are isolated in memory. No real player data, world objects or stores are changed.
local Tests={}
function Tests.Run()
 local folder=Instance.new("Folder")
 folder.Name="Phase741MovementTestSandbox"
 folder.Parent=game.ServerStorage
 local results={}
 local function module(name,source)
  local m=Instance.new("ModuleScript")
  m.Name=name m.Source=source m.Parent=folder
  return m
 end
 local function replace(source,before,after)
  local a,b=source:find(before,1,true)
  assert(a,"Test dependency seam missing: "..before)
  return source:sub(1,a-1)..after..source:sub(b+1)
 end
 local ok,err=pcall(function()
  local runtimeModule=module("Runtime",[==[
local R={Records={},Ordered={},Tasks={}}
function R.Signal()
 local signal={Listeners={}}
 function signal:Connect(fn)
  local connection={Connected=true}
  function connection:Disconnect() self.Connected=false end
  table.insert(self.Listeners,{Connection=connection,Fn=fn})
  return connection
 end
 function signal:Fire(...)
  for _,entry in ipairs(self.Listeners) do
   if entry.Connection.Connected then entry.Fn(...) end
  end
 end
 return signal
end
R.Players={List={},PlayerAdded=R.Signal(),PlayerRemoving=R.Signal()}
function R.Players:GetPlayers() return self.List end
R.Workspace={ChildAdded=R.Signal()}
function R.Workspace:FindFirstChild() return nil end
R.RunService={Heartbeat=R.Signal()}
R.Task={}
function R.Task.wait(interval) return coroutine.yield(interval) end
function R.Task.spawn(fn)
 local co=coroutine.create(fn)
 local success,message=coroutine.resume(co)
 assert(success,message)
 table.insert(R.Tasks,co)
 return co
end
function R.Tick(dt)
 R.RunService.Heartbeat:Fire(dt)
 for _,co in ipairs(table.clone(R.Tasks)) do
  if coroutine.status(co)=="suspended" then
   local success,message=coroutine.resume(co)
   assert(success,message)
  end
 end
end
R.RebirthRemote={OnServerEvent=R.Signal(),Replies={}}
function R.RebirthRemote:FireClient(p,reply) self.Replies[p]=reply end
local H=game:GetService("HttpService")
local function copy(v)
 if v==nil then return nil end
 return H:JSONDecode(H:JSONEncode(v))
end
R.DSS={}
R.Metadata={}
function R.DSS:GetDataStore(name)
 assert(name=="PlayerData_v1")
 local function info(key)
  return {GetMetadata=function() return copy(R.Metadata[key] or {}) end,GetUserIds=function() return {} end}
 end
 return {
  GetAsync=function(_,key)
   if R.FailLoad then error("simulated load failure") end
   return copy(R.Records[key]),info(key)
  end,
  UpdateAsync=function(_,key,callback)
   if R.BeforeUpdate then R.BeforeUpdate() end
   if R.FailSave then error("simulated save failure") end
   callback(copy(R.Records[key]),info(key))
   local value,_,meta=callback(copy(R.Records[key]),info(key))
   if value==nil then return nil end
   R.Records[key]=copy(value)
   R.Metadata[key]=copy(meta or {})
   return copy(R.Records[key]),info(key)
  end,
 }
end
function R.DSS:GetOrderedDataStore(name)
 return {SetAsync=function(_,key,value)
  R.Ordered[name]=R.Ordered[name] or {}
  R.Ordered[name][key]=value
 end}
end
return R
]==])
  local R=require(runtimeModule)
  local masterSource=game.ReplicatedStorage.Config.DumbbellItemMaster.Source
  local masterModule=module("DumbbellItemMaster",masterSource)
  local source=game.ServerScriptService.Services.PlayerDataService.Source
  source=replace(source,'local DSS=game:GetService("DataStoreService")','local DSS=require(script.Parent.Runtime).DSS')
  source=replace(source,'require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))','require(script.Parent.DumbbellItemMaster)')
  local dataModule=module("PlayerDataService",source)
  local typeShim='local engineTypeof=typeof\nlocal function typeof(v) if type(v)=="table" and v.IsTestPlayer then return "Instance" end return engineTypeof(v) end\n'
  local function fakePlayers(text)
   return replace(text,'game:GetService("Players")','require(script.Parent.Runtime).Players')
  end
  local serviceSource=fakePlayers(game.ServerScriptService.Services.DumbbellService.Source)
  serviceSource=replace(serviceSource,'require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))','require(script.Parent.DumbbellItemMaster)')
  local serviceModule=module("DumbbellService",typeShim..serviceSource)
  module("TrainingLobbyAreaService",'return {IsInTrainingLobby=function(p) return p.InLobby~=false end}')
  module("ItemService",typeShim..fakePlayers(game.ServerScriptService.Services.ItemService.Source))
  local Items=require(folder.ItemService)
  local ItemMaster=require(game.ReplicatedStorage.Config.ItemMaster)
  local strengthModule=module("StrengthManager",typeShim..fakePlayers(game.ServerScriptService.Services.StrengthManager.Source))
  local trainingSource=fakePlayers(game.ServerScriptService.Services.TrainingManager.Source)
  trainingSource=replace(trainingSource,'game:GetService("Workspace")','require(script.Parent.Runtime).Workspace')
  local trainingModule=module("TrainingManager",'local task=require(script.Parent.Runtime).Task\n'..trainingSource)
  local controllerSource=fakePlayers(game.ServerScriptService.Systems.Controllers.TrainingController.Source)
  controllerSource=replace(controllerSource,'game:GetService("RunService")','require(script.Parent.Runtime).RunService')
  controllerSource=replace(controllerSource,'game:GetService("Workspace")','require(script.Parent.Runtime).Workspace')
  require(module("TrainingController",controllerSource..'\nreturn true'))
  local rebirthSource=fakePlayers(game.ServerScriptService.Systems.Controllers.RebirthService.Source)
  rebirthSource=replace(rebirthSource,'local request=RS.Remotes:WaitForChild("RebirthRequest")','local request=require(script.Parent.Runtime).RebirthRemote')
  require(module("RebirthService",rebirthSource..'\nreturn true'))
  local Data,Service,Strength,Training,Master=require(dataModule),require(serviceModule),require(strengthModule),require(trainingModule),require(masterModule)
  local sequence=722000
  local function character()
   local h={Health=100,State=Enum.HumanoidStateType.Running,MoveDirection=Vector3.zero,HipHeight=2,Died=R.Signal()}
   function h:GetState() return self.State end
   local root={AssemblyLinearVelocity=Vector3.zero,Position=Vector3.zero,Size=Vector3.new(2,2,1)}
   local c={Humanoid=h,Root=root}
   function c:FindFirstChildOfClass(name) return name=="Humanoid" and h or nil end
   function c:FindFirstChild(name) return name=="HumanoidRootPart" and root or nil end
   return c
  end
  local function player(raw)
   sequence+=1
   local p={IsTestPlayer=true,UserId=sequence,Name="Isolated722",Parent=R.Players,Attributes={},CharacterAdded=R.Signal(),Character=character()}
   function p:IsA(name) return name=="Player" end
   function p:GetAttribute(name) return self.Attributes[name] end
   function p:SetAttribute(name,value) self.Attributes[name]=value end
   if raw then R.Records["Player_"..p.UserId]=raw end
   R.Players.List={p}
   R.Players.PlayerAdded:Fire(p)
   assert(Data.Load(p))
   return p
  end
  local function equipped(id,rebirth)
   return player({Strength=0,RebirthCount=rebirth or 0,TotalStrengthEarned=0,DailyStrengthEarned=0,DailyDate=Data.Today(),Win=20,OwnedDumbbells=id and {[id]=true} or {},EquippedDumbbell=id or ""})
  end
  local function check(name,fn)
   fn() table.insert(results,"PASS "..name)
  end
  local function walk(p,n)
   p.Character.Humanoid.MoveDirection=Vector3.new(1,0,0)
   for _=1,n do R.Tick(0.5) end
   p.Character.Humanoid.MoveDirection=Vector3.zero
  end

  local function itemPlayer(rebirth)
   local owned={}
   for id in pairs(ItemMaster.GetAll()) do owned[id]=true end
   return player({RebirthCount=rebirth or 0,Win=100,OwnedItems=owned,OwnedDumbbells={NORMAL_01=true}})
  end
  local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b)) end
  check("1-4/12: three independent slots and additive 1.60 multiplier",function()
   local p=itemPlayer()
   assert(Items.EquipItem(p,"PROTEIN_RARE_FIRE"))
   near(Items.GetItemStrengthMultiplier(p),1.2)
   assert(Items.EquipItem(p,"GLOVE_EPIC_ICE"))
   near(Items.GetItemStrengthMultiplier(p),1.55)
   assert(Items.EquipItem(p,"TRAININGBELT_COMMON_ELECTRIC"))
   near(Items.GetItemStrengthMultiplier(p),1.6)
   local eq=Items.GetEquippedItems(p)
   assert(eq.Protein=="PROTEIN_RARE_FIRE" and eq.Glove=="GLOVE_EPIC_ICE" and eq.TrainingBelt=="TRAININGBELT_COMMON_ELECTRIC")
   eq.Protein=""
   assert(Items.GetEquippedItems(p).Protein=="PROTEIN_RARE_FIRE")
  end)
  check("5-11: all 45 definitions equip; same-type replacement; rarity only",function()
   local p=itemPlayer()
   local bonuses={Common=.05,Uncommon=.10,Rare=.20,Epic=.35,Legendary=.50}
   for id,item in pairs(ItemMaster.GetAll()) do
    for _,slot in ipairs({"Protein","Glove","TrainingBelt"}) do assert(Items.UnequipItem(p,slot)) end
    assert(Items.EquipItem(p,id))
    near(Items.GetItemStrengthMultiplier(p),1+bonuses[item.Rarity])
   end
   Items.EquipItem(p,"GLOVE_EPIC_ICE")
   Items.EquipItem(p,"TRAININGBELT_COMMON_ELECTRIC")
   Items.EquipItem(p,"PROTEIN_RARE_FIRE")
   Items.EquipItem(p,"PROTEIN_EPIC_ICE")
   local eq=Items.GetEquippedItems(p)
   assert(eq.Protein=="PROTEIN_EPIC_ICE" and eq.Glove=="GLOVE_EPIC_ICE" and eq.TrainingBelt=="TRAININGBELT_COMMON_ELECTRIC")
   assert(Items.HasItem(p,"PROTEIN_RARE_FIRE"))
  end)
  check("13-15: walking x Rebirth x Dumbbell x Item with integer totals",function()
   local p=itemPlayer(1)
   Items.EquipItem(p,"PROTEIN_RARE_FIRE")
   Items.EquipItem(p,"GLOVE_EPIC_ICE")
   Items.EquipItem(p,"TRAININGBELT_COMMON_ELECTRIC")
   assert(Service.EquipDumbbell(p,"NORMAL_01"))
   near(Strength.GetTotalStrengthGainMultiplier(p),3.84)
   walk(p,25)
   local d=Data.Get(p).Data
   assert(d.Strength==96 and d.TotalStrengthEarned==96 and d.DailyStrengthEarned==96)
   near(Strength.GetGainRemainder(p),0)
   p.InLobby=false
   near(Strength.GetTotalStrengthGainMultiplier(p),1.92)
  end)
  check("16: actual treadmill loop uses Item multiplier without double walking gain",function()
   local p=itemPlayer()
   Items.EquipItem(p,"PROTEIN_COMMON_FIRE")
   local treadmill={AncestryChanged=R.Signal()}
   function treadmill:IsA(name) return name=="Model" end
   function treadmill:IsDescendantOf(parent) return parent==R.Workspace end
   function treadmill:GetAttribute(name) return name=="VirtualStepReward" and 1 or 0.5 end
   assert(Training.StartTraining(p,treadmill))
   walk(p,20)
   assert(p:GetAttribute("Strength")==21)
   assert(Data.Get(p).Data.TotalStrengthEarned==21 and Data.Get(p).Data.DailyStrengthEarned==21)
   Training.StopTraining(p)
  end)
  check("17/18: character respawn and actual Rebirth callback preserve all slots",function()
   local p=itemPlayer()
   for _,id in ipairs({"PROTEIN_RARE_FIRE","GLOVE_EPIC_ICE","TRAININGBELT_COMMON_ELECTRIC"}) do Items.EquipItem(p,id) end
   p.Character=character()
   p.CharacterAdded:Fire(p.Character)
   near(Items.GetItemStrengthMultiplier(p),1.6)
   Strength.SetStrength(p,100000)
   R.RebirthRemote.OnServerEvent:Fire(p,"Request")
   assert(R.RebirthRemote.Replies[p].Type=="Success")
   assert(p:GetAttribute("Strength")==0)
   near(Items.GetItemStrengthMultiplier(p),1.6)
  end)
  check("19: save/release/reload preserves slots and all existing fields",function()
   local p=itemPlayer(3)
   Items.EquipItem(p,"PROTEIN_RARE_FIRE")
   Items.EquipItem(p,"GLOVE_EPIC_ICE")
   Items.EquipItem(p,"TRAININGBELT_COMMON_ELECTRIC")
   Service.EquipDumbbell(p,"NORMAL_01")
   Strength.AddStrength(p,10)
   local old=table.clone(Data.Get(p).Data)
   assert(Data.Save(p))
   Data.Release(p)
   assert(Data.Load(p))
   local d=Data.Get(p).Data
   for _,field in ipairs({"Strength","RebirthCount","TotalStrengthEarned","DailyStrengthEarned","DailyDate","Win","EquippedDumbbell"}) do assert(d[field]==old[field],field) end
   for _,field in ipairs({"OwnedItems","EquippedItems","OwnedDumbbells"}) do
    for k,v in pairs(old[field]) do assert(d[field][k]==v,field) end
   end
   near(Items.GetItemStrengthMultiplier(p),1.6)
  end)
  check("20/21: unowned, invalid ID, type and spoofed attributes rejected",function()
   local p=player()
   local yes,code=Items.EquipItem(p,"PROTEIN_RARE_FIRE")
   assert(not yes and code=="NotOwned")
   for _,id in ipairs({"NO_ITEM","NORMAL_01",false,{},123}) do assert(not Items.EquipItem(p,id)) end
   assert(not Items.EquipItem(p,nil))
   assert(not Items.UnequipItem(p,"Dumbbell"))
   assert(not Items.UnequipItem(p,{}))
   p:SetAttribute("EquippedItems","PROTEIN_LEGENDARY_FIRE")
   near(Items.GetItemStrengthMultiplier(p),1)
   local d=Data.Get(p).Data
   d.EquippedItems.Protein="GLOVE_EPIC_FIRE"
   d.OwnedItems.GLOVE_EPIC_FIRE=1
   near(Items.GetItemStrengthMultiplier(p),1)
  end)
  check("Legacy migration only fills missing fields; malformed equipment fails load",function()
   local p=player({Strength=123,Win=99,OwnedItems={PROTEIN_RARE_FIRE=true}})
   assert(Items.GetEquippedItems(p).Protein=="")
   assert(p:GetAttribute("Strength")==123 and p:GetAttribute("Win")==99)
   assert(Data.Save(p))
   Data.Release(p)
   R.Records["Player_"..p.UserId].EquippedItems=false
   assert(not Data.Load(p))
   assert(not Data.Save(p))
   assert(R.Records["Player_"..p.UserId].EquippedItems==false)
  end)
  check("Item purchase => owned => equip; save lock; unequip; unloaded APIs",function()
   local p=player({Win=100})
   assert(Items.PurchaseItemWithWin(p,"PROTEIN_COMMON_FIRE"))
   assert(Items.GetEquippedItems(p).Protein=="")
   assert(p:GetAttribute("Win")==97)
   assert(Items.EquipItem(p,"PROTEIN_COMMON_FIRE"))
   Strength.AddStrength(p,1)
   near(Strength.GetGainRemainder(p),.05)
   R.BeforeUpdate=function()
    local yes,code=Items.UnequipItem(p,"Protein")
    assert(not yes and code=="DataSaving")
    assert(not Items.EquipItem(p,"PROTEIN_COMMON_FIRE"))
   end
   assert(Data.Save(p))
   R.BeforeUpdate=nil
   assert(Items.UnequipItem(p,"Protein"))
   near(Strength.GetGainRemainder(p),.05)
   near(Items.GetItemStrengthMultiplier(p),1)
   Data.Release(p)
   assert(not Items.EquipItem(p,"PROTEIN_COMMON_FIRE"))
   assert(Items.GetEquippedItems(p)==nil)
   near(Items.GetItemStrengthMultiplier(p),1)
  end)

  check("Remote equip/unequip: authoritative state, rejection and rate limit",function()
   R.ItemEquipRemote={OnServerEvent=R.Signal(),Replies={}}
   R.ItemPurchaseRemote={OnServerEvent=R.Signal(),Replies={}}
   function R.ItemEquipRemote:FireClient(p,reply) self.Replies[p]=reply end
   function R.ItemPurchaseRemote:FireClient(p,reply) self.Replies[p]=reply end
   R.ItemStateRemote={}
   R.ItemRobuxRemote={OnServerEvent=R.Signal()}
   function R.ItemRobuxRemote:FireClient() end
   module("ItemPurchaseService",'return {SetNotifier=function() end,Prompt=function() return false,"TestIsolated" end}')
   local controller=fakePlayers(game.ServerScriptService.Systems.Controllers.ItemController.Source)
   controller=replace(controller,'RS.Remotes:WaitForChild("ItemPurchaseRequest")','require(script.Parent.Runtime).ItemPurchaseRemote')
   controller=replace(controller,'RS.Remotes:WaitForChild("ItemInventoryState")','require(script.Parent.Runtime).ItemStateRemote')
   controller=replace(controller,'RS.Remotes:WaitForChild("ItemEquipRequest")','require(script.Parent.Runtime).ItemEquipRemote')
   controller=replace(controller,'RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")','require(script.Parent.Runtime).ItemRobuxRemote')
   require(module("ItemController",controller..'\nreturn true'))
   local p=itemPlayer()
   R.ItemEquipRemote.OnServerEvent:Fire(p,"PROTEIN_RARE_FIRE")
   local reply=R.ItemEquipRemote.Replies[p]
   assert(reply.Success and reply.State.EquippedItems.Protein=="PROTEIN_RARE_FIRE")
   assert(reply.State.OwnedItems.PROTEIN_RARE_FIRE and reply.State.Win==100)
   R.ItemEquipRemote.OnServerEvent:Fire(p,"GLOVE_EPIC_ICE")
   assert(R.ItemEquipRemote.Replies[p].Code=="RateLimited")
   assert(Items.GetEquippedItems(p).Glove=="")
   R.Players.PlayerRemoving:Fire(p) -- clear cooldown deterministically
   R.ItemEquipRemote.OnServerEvent:Fire(p,"Protein","Unequip")
   assert(R.ItemEquipRemote.Replies[p].Success and Items.GetEquippedItems(p).Protein=="")
   local q=player()
   R.ItemEquipRemote.OnServerEvent:Fire(q,"PROTEIN_RARE_FIRE")
   assert(R.ItemEquipRemote.Replies[q].Code=="NotOwned")
   local x=player()
   R.ItemEquipRemote.OnServerEvent:Fire(x,{ItemId="PROTEIN_RARE_FIRE"})
   assert(R.ItemEquipRemote.Replies[x].Code=="InvalidItemId")
   assert(R.ItemStateRemote.OnServerInvoke(p).EquippedItems.Protein=="")
  end)
  check("A: unchanged walking controller, 10 simulated seconds unarmed = +20",function()
   local p=equipped()
   assert(Service.GetEquippedDumbbell(p)==nil and p:GetAttribute("EquippedDumbbell")=="")
   walk(p,20)
   assert(p:GetAttribute("Strength")==20)
  end)
  check("B: owned NORMAL_01 equip, walking 10 simulated seconds = +40",function()
   local p=player({Win=10,OwnedDumbbells={NORMAL_01=true}})
   assert(Service.EquipDumbbell(p,"NORMAL_01"))
   assert(p:GetAttribute("EquippedDumbbell")=="NORMAL_01")
   walk(p,20)
   assert(p:GetAttribute("Strength")==40 and p:GetAttribute("Win")==10)
   assert(Data.Get(p).Data.TotalStrengthEarned==40 and Data.Get(p).Data.DailyStrengthEarned==40)
  end)
  check("C: NORMAL_03 walking 10 simulated seconds = +200",function()
   local p=equipped("NORMAL_03")
   walk(p,20)
   assert(p:GetAttribute("Strength")==200)
  end)
  check("Stopped / Jumping / Freefall do not accrue walking Strength",function()
   local p=equipped("NORMAL_03")
   for _=1,20 do R.Tick(0.5) end
   assert(p:GetAttribute("Strength")==0)
   p.Character.Humanoid.MoveDirection=Vector3.new(1,0,0)
   for _,state in ipairs({Enum.HumanoidStateType.Jumping,Enum.HumanoidStateType.Freefall}) do
    p.Character.Humanoid.State=state
    for _=1,20 do R.Tick(0.5) end
   end
   assert(p:GetAttribute("Strength")==0)
  end)
  check("D: unchanged treadmill loop = +200 / 10 simulated seconds, no walking double count",function()
   local p=equipped("NORMAL_03")
   local treadmill={AncestryChanged=R.Signal()}
   function treadmill:IsA(name) return name=="Model" end
   function treadmill:IsDescendantOf(parent) return parent==R.Workspace end
   function treadmill:GetAttribute(name) return name=="VirtualStepReward" and 1 or 0.5 end
   assert(Training.StartTraining(p,treadmill))
   assert(p:GetAttribute("IsTraining")==true)
   p.Character.Humanoid.MoveDirection=Vector3.new(1,0,0)
   for _=1,20 do R.Tick(0.5) end
   assert(p:GetAttribute("Strength")==200)
   Training.StopTraining(p)
  end)
  check("E: R5 x2 and NORMAL_03 x10 => +20 for base 1",function()
   local p=equipped("NORMAL_03",5)
   assert(Strength.GetStrengthGainMultiplier(p)==2)
   assert(Strength.GetTotalStrengthGainMultiplier(p)==20)
   Strength.AddStrength(p,1)
   assert(p:GetAttribute("Strength")==20)
  end)
  check("F: R1 x1.2 remainder retained (unarmed +6, NORMAL_01 +12 over 5 gains)",function()
   for _,id in ipairs({"","NORMAL_01"}) do
    local p=equipped(id~="" and id or nil,1)
    for _=1,5 do Strength.AddStrength(p,1) end
    assert(p:GetAttribute("Strength")==(id=="" and 6 or 12))
    assert(math.abs(Strength.GetGainRemainder(p))<1e-9)
   end
  end)
  check("Fraction is retained across equip / unequip changes",function()
   local p=player({RebirthCount=1,OwnedDumbbells={NORMAL_01=true}})
   Strength.AddStrength(p,1) -- +1, remainder .2
   assert(Service.EquipDumbbell(p,"NORMAL_01"))
   Strength.AddStrength(p,1) -- +2, remainder .6
   assert(Service.UnequipDumbbell(p))
   Strength.AddStrength(p,1) -- +1, remainder .8
   Strength.AddStrength(p,1) -- +2, remainder 0
   assert(p:GetAttribute("Strength")==6 and math.abs(Strength.GetGainRemainder(p))<1e-9)
  end)
  check("G/H: unowned and invalid equip rejected; repeat equip is idempotent; one slot",function()
   local p=player({OwnedDumbbells={NORMAL_01=true,NORMAL_03=true}})
   assert(Service.EquipDumbbell(p,"NORMAL_01"))
   local success,code=Service.EquipDumbbell(p,"NORMAL_05")
   assert(not success and code=="NotOwned")
   for _,id in ipairs({"INVALID_ITEM",false,{},123}) do assert(not Service.EquipDumbbell(p,id)) end
   assert(not Service.EquipDumbbell(p,nil))
   for _=1,100 do
    local yes,why=Service.EquipDumbbell(p,"NORMAL_01")
    assert(yes and why=="AlreadyEquipped")
   end
   assert(Service.EquipDumbbell(p,"NORMAL_03"))
   assert(Service.GetEquippedDumbbell(p)=="NORMAL_03")
   assert(Service.HasDumbbell(p,"NORMAL_01"))
  end)
  check("I: actual Rebirth callback resets Strength/remainder, preserves inventory/equipment",function()
   local p=equipped("NORMAL_01",1)
   Strength.AddStrength(p,1)
   assert(Strength.GetGainRemainder(p)>0)
   Strength.SetStrength(p,100000)
   local total=Data.Get(p).Data.TotalStrengthEarned
   R.RebirthRemote.OnServerEvent:Fire(p,"Request")
   assert(R.RebirthRemote.Replies[p].Type=="Success")
   assert(p:GetAttribute("Strength")==0 and p:GetAttribute("RebirthCount")==2)
   assert(Strength.GetGainRemainder(p)==0)
   assert(Service.HasDumbbell(p,"NORMAL_01") and Service.GetEquippedDumbbell(p)=="NORMAL_01")
   assert(Data.Get(p).Data.TotalStrengthEarned==total)
   Strength.AddStrength(p,1)
   assert(p:GetAttribute("Strength")==2)
  end)
  check("J: CharacterAdded does not clear Player equipment",function()
   local p=equipped("NORMAL_03")
   p.Character=character()
   p.CharacterAdded:Fire(p.Character)
   assert(Service.GetEquippedDumbbell(p)=="NORMAL_03" and p:GetAttribute("EquippedDumbbell")=="NORMAL_03")
   Strength.AddStrength(p,1)
   assert(p:GetAttribute("Strength")==10)
  end)
  check("K: purchase does not auto-equip; explicit equip persists through save/reload",function()
   local p=player({Strength=278,RebirthCount=5,TotalStrengthEarned=999,DailyStrengthEarned=77,DailyDate=Data.Today(),Win=10,ExistingExtra="keep"})
   assert(Service.PurchaseDumbbell(p,"NORMAL_03"))
   assert(Service.GetEquippedDumbbell(p)==nil)
   assert(Service.EquipDumbbell(p,"NORMAL_03"))
   assert(Data.Save(p))
   Data.Release(p)
   assert(Data.Load(p))
   local d=Data.Get(p).Data
   assert(d.OwnedDumbbells.NORMAL_03 and d.EquippedDumbbell=="NORMAL_03")
   assert(p:GetAttribute("EquippedDumbbell")=="NORMAL_03" and p:GetAttribute("Win")==5)
   assert(d.Strength==278 and d.RebirthCount==5 and d.TotalStrengthEarned==999 and d.DailyStrengthEarned==77)
   assert(R.Records["Player_"..p.UserId].ExistingExtra=="keep")
   assert(Service.UnequipDumbbell(p) and Data.Save(p))
   Data.Release(p)
   assert(Data.Load(p) and Service.GetEquippedDumbbell(p)==nil and p:GetAttribute("EquippedDumbbell")=="")
  end)
  check("L: missing/unowned/deleted/malformed equipped IDs normalize to empty",function()
   for _,value in ipairs({"NORMAL_03","DELETED_ITEM",{},42,false,""}) do
    local p=player({Strength=123,Win=10,OwnedDumbbells={NORMAL_01=true,DELETED_ITEM=true},EquippedDumbbell=value})
    assert(Service.GetEquippedDumbbell(p)==nil and p:GetAttribute("EquippedDumbbell")=="")
    assert(p:GetAttribute("Strength")==123 and p:GetAttribute("Win")==10)
    assert(Data.Save(p))
    assert(R.Records["Player_"..p.UserId].EquippedDumbbell=="")
    assert(Service.HasDumbbell(p,"DELETED_ITEM"))
   end
   local legacy=player({Win=3,OwnedDumbbells={NORMAL_01=true}})
   assert(Service.GetEquippedDumbbell(legacy)==nil and legacy:GetAttribute("Win")==3)
  end)
  check("M: post-multiplier integer gain reaches totals and ranking mirrors",function()
   local p=equipped("NORMAL_03",5)
   Strength.AddStrength(p,1)
   local d=Data.Get(p).Data
   assert(d.Strength==20 and d.TotalStrengthEarned==20 and d.DailyStrengthEarned==20)
   assert(p:GetAttribute("TotalStrengthEarned")==20 and p:GetAttribute("DailyStrengthEarned")==20)
   assert(Data.Save(p))
   assert(R.Ordered.TotalStrengthRanking_v1[tostring(p.UserId)]==20)
   assert(R.Ordered["DailyStrengthRanking_"..Data.Today()][tostring(p.UserId)]==20)
  end)
  check("Attribute tampering cannot equip, affect multiplier or change saved equipment",function()
   local p=equipped("NORMAL_01")
   p:SetAttribute("EquippedDumbbell","NORMAL_05")
   Strength.AddStrength(p,1)
   assert(p:GetAttribute("Strength")==2)
   assert(Data.Save(p))
   assert(R.Records["Player_"..p.UserId].EquippedDumbell==nil)
   assert(R.Records["Player_"..p.UserId].EquippedDumbbell=="NORMAL_01")
   assert(p:GetAttribute("EquippedDumbbell")=="NORMAL_01")
  end)
  check("Equip rejected while save in flight; failure/retry retains equipment",function()
   local p=player({Win=10,OwnedDumbbells={NORMAL_01=true,NORMAL_03=true}})
   assert(Service.EquipDumbbell(p,"NORMAL_01"))
   R.BeforeUpdate=function()
    local success,code=Service.EquipDumbbell(p,"NORMAL_03")
    assert(not success and code=="DataSaving")
    assert(not Service.UnequipDumbbell(p))
   end
   assert(Data.Save(p))
   R.BeforeUpdate=nil
   assert(Service.EquipDumbbell(p,"NORMAL_03"))
   R.FailSave=true
   assert(not Data.Save(p))
   R.FailSave=false
   assert(Service.GetEquippedDumbbell(p)=="NORMAL_03" and Data.Save(p))
   Data.Release(p)
   assert(Data.Load(p) and Service.GetEquippedDumbbell(p)=="NORMAL_03")
  end)
  check("Unloaded equipment APIs reject changes and multiplier falls back to 1",function()
   local p=equipped("NORMAL_01")
   Data.Release(p)
   local success,code=Service.EquipDumbbell(p,"NORMAL_01")
   assert(not success and code=="DataNotLoaded")
   assert(not Service.UnequipDumbbell(p))
   assert(Service.GetEquippedDumbbell(p)==nil and Service.GetStrengthMultiplier(p)==1)
  end)
  check("Future decimal Master multiplier and invalid multipliers use definitions safely",function()
   -- Replace only NORMAL_01's definition inside an isolated Master clone.
   local decimalSource=replace(masterSource,'StrengthMultiplier=2}','StrengthMultiplier=1.1}')
   local decimalMaster=module("DecimalMaster",decimalSource)
   local decimalServiceSource=replace(typeShim..serviceSource,'require(script.Parent.DumbbellItemMaster)','require(script.Parent.DecimalMaster)')
   module("DecimalService",decimalServiceSource)
   local decimalStrengthSource=replace(typeShim..fakePlayers(game.ServerScriptService.Services.StrengthManager.Source),
    'require(script.Parent:WaitForChild("DumbbellService"))','require(script.Parent.DecimalService)')
   local decimalStrength=require(module("DecimalStrength",decimalStrengthSource))
   local p=equipped("NORMAL_01",1)
   for _=1,25 do decimalStrength.AddStrength(p,1) end
   assert(p:GetAttribute("Strength")==33) -- 25 * 1.2 * 1.1, remainder preserved
   assert(Data.Get(p).Data.TotalStrengthEarned==33)
   assert(math.abs(decimalStrength.GetGainRemainder(p))<1e-9)
   module("BadMaster",'return {Get=function(id) return {Category=id=="BAD_CATEGORY" and "Other" or "Dumbbell",StrengthMultiplier=({ZERO=0,NEGATIVE=-1,INF=math.huge,NAN=0/0,STRING="10"})[id]} end}')
   local badSource=replace(typeShim..serviceSource,'require(script.Parent.DumbbellItemMaster)','require(script.Parent.BadMaster)')
   local bad=require(module("BadService",badSource))
   for _,id in ipairs({"ZERO","NEGATIVE","INF","NAN","STRING","MISSING"}) do
    Data.Get(p).Data.OwnedDumbbells[id]=true
    Data.Get(p).Data.EquippedDumbbell=id
    assert(bad.GetStrengthMultiplier(p)==1)
   end
   local success,code=bad.EquipDumbbell(p,"BAD_CATEGORY")
   assert(not success and code=="InvalidCategory")
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return Tests
