-- Temporary native Studio QA; requires isolated __PetQAMemory. Never ship this fixture.
local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local Pet=require(RS.Modules.Pet)
local Egg=require(RS.Modules.Egg)
local PS=require(game.ServerScriptService.Services.PetServer)
local Memory=require(RS.__PetQAMemory)
local Store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1"))
local H=game.HttpService
local function id()return H:GenerateGUID(false)end
local function ready(p)
 repeat task.wait(.1)until D.Get(p) and D.Get(p).Loaded
 if D.Get(p).StudioStartOverride then D.RestoreStudioStartOverride(p)end
 D.SetAutoTapEnabled(p,false)
 return D.Get(p)
end
local function seed(p,names)
 local s=ready(p);while s.Saving or s.PendingItemMutation do task.wait(.1) end
 local state=assert(Pet.NormalizeState(nil));state.Revision=(s.Data.Pets.Revision or 0)+1;local ids={}
 s.Data.TutorialCompleted=true;p:SetAttribute("TutorialCompleted",true)
 for i,name in ipairs(names)do ids[i]=id();state.Owned[ids[i]]=name end
 state=assert(Pet.NormalizeState(state))
 s.Data.Pets=state
 D.SetWin(p,100000000);D.Save(p)
 Store:UpdateAsync("Player_"..p.UserId,function(old)old.Pets=state;return old end)
 Pet.Publish(p,state)
 return ids
end
local function equip(p,key,request)
 local state,_,generation=D.GetPetState(p)
 return PS.equip(p,key,request or id(),state.Revision,generation)
end
local function hatch(p,eggName,name)
 local state,_,generation=D.GetPetState(p)
 local result={id=id(),pet=name,percent=assert(Egg.pets(eggName)[name])}
 local old=p:GetAttribute("CurrentWorld");p:SetAttribute("CurrentWorld",Egg.world(eggName))
 local ok,why=D.MutatePets(p,id(),state.Revision,"Hatch",{EggName=eggName,Count=1,PriceWin=Egg.price(eggName),Results={result}},generation)
 p:SetAttribute("CurrentWorld",old)
 assert(ok,why);return result.id
end

local ES=require(game.ServerScriptService.Services.EggServer)
local function request(p,action,a,b,oldRevision,requestId,oldGeneration)
 local state,_,generation=D.GetPetState(p)
 return ES.request(p,action,requestId or id(),oldRevision or state.Revision,a,b,oldGeneration or generation)
end
local function run(p)
 local checks={}
 local function check(name,ok,detail) assert(ok,name..": "..tostring(detail));table.insert(checks,{Name=name,Detail=detail or true}) end
 local ids=seed(p,{"Dog","Dog","Grey Cat","Bear","Elephant","Crocodile","Ninja","Shark","Mammoth"})
 local state=D.GetPetState(p)
 local ordered=Pet.InventoryIds(state)
 check("inventory numeric descending",ordered[1]==ids[7] and ordered[2]==ids[8] and ordered[3]==ids[6])
 local groups=require(RS.Modules.PetMerge).Groups(state)
 check("merge points still descending",groups[1].Points>=groups[2].Points and groups[1].Name=="Ninja")
 local req=id();local rev=state.Revision
 local response=request(p,"BestEquip",{Strength=999999,Ids={"unowned"}},nil,rev,req)
 check("one authoritative top-three operation",response.ok and response.state.Revision==rev+1,response.reason)
 state=response.state;local selected={}
 for _,key in ipairs(state.Equipped) do selected[key]=true end
 check("strongest three owned copies",selected[ids[7]] and selected[ids[8]] and selected[ids[6]] and not selected.unowned)
 response=request(p,"BestEquip",nil,nil,rev,req)
 check("same request replay no mutation",response.ok and response.reason=="AlreadyApplied" and response.state.Revision==rev+1)
 response=request(p,"BestEquip")
 check("rapid new request throttled",not response.ok and response.reason=="PleaseWait",response.reason)
 task.wait(.8);response=request(p,"BestEquip")
 check("already-best is a no-op",response.ok and response.reason=="AlreadyBestEquipped" and response.state.Revision==rev+1)
 task.wait(.8);response=request(p,"BestEquip",nil,nil,rev)
 check("stale revision refused",not response.ok and response.reason=="PetStateChanged",response.reason)
 local current,_,gen=D.GetPetState(p)
 response=request(p,"BestEquip",nil,nil,current.Revision,nil,gen+1)
 check("old view refused",not response.ok and response.reason=="PetStateChanged")
 for _,key in ipairs(state.Equipped) do
  local allowed,reason=require(RS.Modules.PetMerge).Eligible(state,key)
  check("equipped merge guard "..state.Owned[key],not allowed and reason=="PetEquipped")
 end
 -- Exact existing percentages: 80 + 60 + 30 = +170%, not multiplied together.
 check("additive multiplier unchanged",math.abs(PS.GetStrengthMultiplier(p)-2.7)<1e-9,PS.GetStrengthMultiplier(p))
 local data=D.Get(p).Data;data.EquippedItems={Protein="",Glove="",TrainingBelt=""};data.EquippedAura="";data.EquippedDumbbell="";data.RebirthCount=0
 local strength=require(game.ServerScriptService.Services.StrengthManager)
 local start=strength.GetStrength(p);strength.AddStrength(p,10,1,1)
 check("native training receives multiplier once",math.abs(strength.GetStrength(p)-start-27)<1e-6,strength.GetStrength(p)-start)
 D.Save(p)
 local disk=Store:GetAsync("Player_"..p.UserId)
 local reloaded=assert(Pet.NormalizeState(H:JSONDecode(H:JSONEncode(disk.Pets))))
 check("isolated persistence and discovery",#Pet.EquippedEntries(reloaded)==3 and reloaded.Discovered.Ninja)
 D.Get(p).Data.Pets=reloaded;Pet.Publish(p,reloaded)
 check("manual unequip after Best Equip",equip(p,state.Equipped[1]))
 check("manual replacement",equip(p,ids[1]))
 ids=seed(p,{"Dog","Dog","Dog","Dog"})
 check("manual tie setup 4",equip(p,ids[4]))
 check("manual tie setup 2",equip(p,ids[2]))
 check("manual tie setup 3",equip(p,ids[3]))
 state=D.GetPetState(p);local old=table.concat(state.Equipped,",")
 local ok,why=PS.bestEquip(p,id(),state.Revision,select(3,D.GetPetState(p)))
 check("ties keep equipped individuals and slots",ok and table.concat(D.GetPetState(p).Equipped,",")==old,why)
 for count=0,2 do
  local names={} for i=1,count do names[i]="Dog" end
  ids=seed(p,names);state=D.GetPetState(p)
  ok,why=PS.bestEquip(p,id(),state.Revision,select(3,D.GetPetState(p)))
  check("owned count "..count,ok and #Pet.EquippedEntries(D.GetPetState(p))==count,why)
 end
 ids=seed(p,{"Dog","Dog","Elephant","Crocodile","Ninja","Shark","Bear","Grey Cat","Mammoth"})
 state=D.GetPetState(p);PS.bestEquip(p,id(),state.Revision,select(3,D.GetPetState(p)))
 return {Checks=checks,State=D.GetPetState(p),Multiplier=PS.GetStrengthMultiplier(p)}
end
local function eggs(p)
 seed(p,{})
 p:SetAttribute("CurrentWorld",1)
 p.Character:PivotTo(CFrame.new(Egg.part("Basic").Position+Vector3.new(0,0,9)))
 D.SetWin(p,100);D.Save(p)
 local out={}
 for _,count in ipairs({1,3,8}) do
  task.wait(.8)
  local before=D.Get(p).Data.Win
  local response=request(p,"OpenEgg","Basic","Open"..count)
  assert(response.ok,response.reason)
  local after=D.Get(p).Data.Win
  assert(before-after==3*count and #response.state.LastResults==count)
  table.insert(out,{Count=count,Price=Egg.price("Basic")*count,Before=before,After=after,Reason=response.reason})
 end
 D.SetWin(p,2);D.Save(p);task.wait(.8)
 local rev=D.GetPetState(p).Revision
 local response=request(p,"OpenEgg","Basic","Open1")
 assert(not response.ok and response.reason=="NotEnoughWin" and D.Get(p).Data.Win==2 and D.GetPetState(p).Revision==rev)
 return {Charges=out,Insufficient=response.reason,Sign=workspace.Eggs.Basic.Prize.Info.Text,State=D.GetPetState(p)}
end
local function handle(p,action,arg)
 ready(p)
 if action=="Run" then return run(p)
 elseif action=="Eggs" then return eggs(p)
 elseif action=="Seed" then return seed(p,arg)
 elseif action=="State" then return D.GetPetState(p)
 elseif action=="Best" then local state,_,generation=D.GetPetState(p);local ok,why=PS.bestEquip(p,id(),state.Revision,generation);return {Ok=ok,Why=why,State=D.GetPetState(p)}
 elseif action=="Equip" then return equip(p,arg)
 elseif action=="Death" then p.Character.Humanoid.Health=0;return true
 elseif action=="Reload" then D.Save(p);local disk=Store:GetAsync("Player_"..p.UserId);D.Get(p).Data.Pets=assert(Pet.NormalizeState(H:JSONDecode(H:JSONEncode(disk.Pets))));Pet.Publish(p,D.Get(p).Data.Pets);return D.GetPetState(p)
 elseif action=="Hatch" then return hatch(p,arg.Egg,arg.Pet)
 elseif action=="Win" then D.SetWin(p,arg);D.Save(p);return D.Get(p).Data.Win
 end
end
local remote=Instance.new("RemoteFunction");remote.Name="__PetQARemote";remote.Parent=RS
remote.OnServerInvoke=handle
local probe=Instance.new("BindableFunction");probe.Name="__PetQAServer";probe.Parent=game.ServerStorage
probe.OnInvoke=function(action,arg)return handle(game.Players:GetPlayers()[1],action,arg)end
for _,p in game.Players:GetPlayers() do task.spawn(ready,p) end
game.Players.PlayerAdded:Connect(function(p)task.spawn(ready,p)end)
