local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local Pet=require(RS.Modules.Pet)
local Egg=require(RS.Modules.Egg)
local PS=require(game.ServerScriptService.Services.PetServer)
local Memory=require(RS.__P3QAMemory)
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
 local s=ready(p);local state=assert(Pet.NormalizeState(nil));local ids={}
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
local function run(p)
 local checks={}
 local function check(name,ok,detail)assert(ok,name..": "..tostring(detail));checks[#checks+1]={Name=name,Detail=detail or true}end
 local legacy={Version=1,Revision=0,Owned={a="Dog",b="Grey Cat"},Equipped={"a"},LastRequestId="",LastResults={}}
 local normalized=assert(Pet.NormalizeState(legacy))
 check("old one-pet migration",normalized.Equipped[1]=="a" and normalized.Owned.b=="Grey Cat" and Pet.HasDiscovered(normalized,"Dog"))
 legacy.Equipped={"a","a","a"};normalized=assert(Pet.NormalizeState(legacy))
 check("duplicate IDs normalized once",#Pet.EquippedEntries(normalized)==1)
 local ids=seed(p,{"Dog","Dog","Elephant","Crocodile"})
 check("zero pets",PS.GetStrengthMultiplier(p)==1)
 for i=1,3 do local ok,why=equip(p,ids[i]);check("equip slot "..i,ok,why)end
 local state=D.GetPetState(p)
 check("same species distinct copies",#Pet.EquippedEntries(state)==3 and state.Equipped[1]~=state.Equipped[2])
 local ok,why=equip(p,ids[4]);check("full refuses implicit replacement",not ok and why=="PetSlotsFull",why)
 local M=require(RS.Modules.PetMerge)
 for i=1,3 do local allowed,reason=M.Eligible(state,ids[i]);check("equipped merge protection "..i,not allowed and reason=="PetEquipped",reason)end
 check("actual additive multiplier",math.abs(PS.GetStrengthMultiplier(p)-1.24)<1e-9,PS.GetStrengthMultiplier(p))
 local request=id();check("unequip",equip(p,ids[2],request))
 state=D.GetPetState(p);local revision=state.Revision
 local retry,reason=PS.equip(p,ids[2],request,revision,select(3,D.GetPetState(p)))
 check("retry no second toggle",retry and #Pet.EquippedEntries(D.GetPetState(p))==2,reason)
 check("explicit replacement after free slot",equip(p,ids[4]))
 local native=require(game.ServerScriptService.Services.StrengthManager)
 local fn=Pet.StrengthPercent
 Pet.StrengthPercent=function(name)if name=="Dog"then return 10 elseif name=="Crocodile"then return 20 elseif name=="Elephant"then return 30 end return fn(name)end
 local worked,err=xpcall(function()
  local d=D.Get(p).Data;d.EquippedItems={Protein="",Glove="",TrainingBelt=""};d.EquippedAura="";d.EquippedDumbbell="";d.RebirthCount=0
  local before=native.GetStrength(p);local context=require(game.ServerScriptService.Services.StrengthReference).GetContext(p,false)
  native.AddStrength(p,10,1,1)
  check("10+20+30 percent native training",math.abs(native.GetStrength(p)-before-16)<1e-6,native.GetStrength(p)-before)
  check("reward reference same multiplier",math.abs(context[1].Pet-1.6)<1e-9,context[1].Pet)
 end,debug.traceback)
 Pet.StrengthPercent=fn;assert(worked,err)
 state=D.GetPetState(p)
 D.Save(p)
 local disk=Store:GetAsync("Player_"..p.UserId);local reload=assert(Pet.NormalizeState(H:JSONDecode(H:JSONEncode(disk.Pets))))
 check("isolated persisted equipment and history",#Pet.EquippedEntries(reload)==3 and Pet.HasDiscovered(reload,"Dog"))
 -- Existing durable transaction consumes two unequipped copies; discovery must survive.
 local extra=hatch(p,"Basic","Grey Cat");local extra2=hatch(p,"Basic","Grey Cat")
 state=D.GetPetState(p);local preview=assert(M.Evaluate(state,{extra,extra2}))
 local egg=preview.Outcomes[1].Egg;local pet=Egg.NormalPools[egg].Species[1]
 local result={id=id(),pet=pet,percent=Egg.pets(egg)[pet]}
 request=id()
 ok,why=D.MutatePets(p,request,state.Revision,"Merge",{Materials={extra,extra2},EggName=egg,Results={result}},select(3,D.GetPetState(p)))
 check("normal merge transaction",ok,why)
 state=D.GetPetState(p);check("discovery survives actual consumption",not state.Owned[extra] and not state.Owned[extra2] and Pet.HasDiscovered(state,"Grey Cat"))
 local r=state.Revision
 ok,why=D.MutatePets(p,request,r,"Merge",{},select(3,D.GetPetState(p)))
 check("merge replay unchanged",ok and D.GetPetState(p).Revision==r,why)
 D.Save(p);disk=Store:GetAsync("Player_"..p.UserId)
 check("discovery persisted after consumption",disk.Pets.Discovered["Grey Cat"]==true)
 return {Checks=checks,State=D.GetPetState(p),Multiplier=PS.GetStrengthMultiplier(p)}
end
local function handle(p,action,arg)
 if action=="Run"then return run(p)
 elseif action=="Seed"then return seed(p,arg or {})
 elseif action=="Hatch"then return hatch(p,arg.Egg,arg.Pet)
 elseif action=="State"then return D.GetPetState(p)
 elseif action=="Equip"then return equip(p,arg)
 elseif action=="Reload"then
  D.Save(p);local disk=Store:GetAsync("Player_"..p.UserId)
  D.Get(p).Data.Pets=assert(Pet.NormalizeState(H:JSONDecode(H:JSONEncode(disk.Pets))));Pet.Publish(p,D.Get(p).Data.Pets)
  return D.GetPetState(p)
 elseif action=="Death"then p.Character.Humanoid.Health=0;return true
 elseif action=="World"then D.UnlockWorld(p,2);D.MarkWorld2Reached(p);p:SetAttribute("CurrentWorld",arg);require(game.ServerScriptService.Services.LobbySpawnService).MoveToLobby(p,p.Character,arg);return true
 elseif action=="ResetCommand"then local ok,why=require(game.ServerScriptService.Systems.Debug.StudioDebugService).Execute(p,"/resetdata");return {Ok=ok,Why=why,State=D.GetPetState(p)}
 elseif action=="Reset"then local ok=D.Reset(p);return {Ok=ok,State=D.GetPetState(p)}
 elseif action=="HUD"then
  local data=D.Get(p).Data;local master=require(RS.Config.ItemMaster);local equipped={}
  local elements=arg=="Set" and {"Ice","Ice","Ice"} or {"Fire","Ice","Electric"}
  for i,kind in ipairs({"Protein","Glove","TrainingBelt"})do local key=master.Id(kind,"Rare",elements[i],1);data.OwnedItems[key]=2;equipped[kind]=key end
  data.EquippedItems=equipped
  local state={Loaded=true,OwnedItems=table.clone(data.OwnedItems),EquippedItems=table.clone(equipped),World1Cleared=true}
  RS.Remotes.ItemEquipRequest:FireClient(p,{State=state})
  return state
 elseif action=="Drop"then
  local result={Id=id(),OwnerUserId=p.UserId,WorldId=1,Outcome=arg,OreId="ORE_001",ItemId="PROTEIN_COMMON_FIRE"}
  RS.Remotes.EnemyDropGachaResult:FireClient(p,result);RS.Remotes.EnemyDropGachaResult:FireClient(p,result);return result
 end
end
local remote=Instance.new("RemoteFunction");remote.Name="__P3QARemote";remote.Parent=RS
remote.OnServerInvoke=handle
local q=Instance.new("BindableFunction");q.Name="__P3QAServer";q.Parent=game.ServerStorage
q.OnInvoke=function(action,arg,userId)
 local p=userId and game.Players:GetPlayerByUserId(userId) or game.Players:GetPlayers()[1]
 return handle(p,action,arg)
end
for _,p in game.Players:GetPlayers()do task.spawn(ready,p)end
game.Players.PlayerAdded:Connect(function(p)task.spawn(ready,p)end)
