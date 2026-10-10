-- Injected production functions by BasicEggOffline.py; no live Roblox services.
local assertions=0
local function equal(a,b,label)
 assertions+=1
 assert(a==b,(label or "value")..": expected "..tostring(b)..", got "..tostring(a))
end
local function copy(value)
 if type(value)~="table" then return value end
 local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
end
local function guid(n) return string.format("00000000-0000-0000-0000-%012d",n) end
local odds={Dog=40,["Grey Cat"]=25,["Pink Bunny"]=15,Sheep=10,Bear=7,Camel=3}
local eggEntries={
 Basic={wins=100,Pets=odds},
 Rare={wins=10000,Pets={Cow=40,Giraffe=25,Lion=15,Lizard=10,Spider=7,Bat=3}},
 Legendary={wins=100000,Pets={Elephant=40,Mammoth=25,Penguin=15,Crocodile=10,Octopus=7,Shark=3}},
 Mythic={wins=1000000,Pets={Turtle=40,Alien=25,Anglerfish=15,Dino=10,Scorpion=7,["Evil Dragon"]=3}},
}
local modules={Config={Pets={},Egg={reach=15}},Egg={
 pets=function(name) return eggEntries[name] and eggEntries[name].Pets end,
 price=function(name) return eggEntries[name] and eggEntries[name].wins or 0 end,
 isEgg=function(name) return eggEntries[name]~=nil end,
}}
local generated=10000
local RS={Modules={Config="Config",Egg="Egg",Pet="Pet"},Config={LimitedEggConfig="Limited"}}
-- INSERT LIMITED CONFIG
local Players={}
local game={ReplicatedStorage=RS}
function game:GetService(name)
 if name=="Players" then return Players end
 if name=="ReplicatedStorage" then return RS end
 if name=="HttpService" then return {GenerateGUID=function() generated+=1;return guid(generated) end} end
 error(name)
end
local function require(name) return assert(modules[name],name) end
-- INSERT PET
modules.Pet=Pet
local productionPetModel=Pet.model
local attrs={}
local player={Parent=Players,SetAttribute=function(_,k,v) attrs[k]=v end,GetAttribute=function(_,k) return attrs[k] end}
local sessions={}
local PlayerDataService={}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function resetToken(d) return d.ResetToken end
local function normalizeShop(d) return copy(d) end
local function mergeShop(a,b) return {WinGrantedTotal=math.max(a.WinGrantedTotal,b.WinGrantedTotal)} end
local function metadata() return {},{} end
local retries=0
local function scheduleItemMutationRetry() retries+=1 end
local durable,mode,hook,writes
local function ownedUpdate(_,s,transform)
 if s.OwnershipLost then return nil end
 if mode=="before" then error("offline before commit") end
 if hook then local f=hook;hook=nil;f() end
 local nextValue=transform(copy(durable),{})
 -- Emulate UpdateAsync evaluating a transform again before committing.
 local repeated=transform(copy(durable),{})
 if nextValue then equal(nextValue.Pets.Revision,repeated.Pets.Revision,"callback retry revision") end
 if nextValue then durable=copy(nextValue);writes+=1 end
 if mode=="after" then error("lost reply after commit") end
 return nextValue
end
-- INSERT TRANSACTIONS
function PlayerDataService.ResolveItemMutation(p)
 local s=sessions[p]
 if not s or not s.PendingItemMutation then return false,"NoPendingMutation" end
 return resolvePetMutation(p,s,s.PendingItemMutation)
end
function PlayerDataService.Get(p) return sessions[p] end
function PlayerDataService.IsLoaded(p) return sessions[p] and sessions[p].Loaded==true end
local function reset(win)
 attrs={};mode=nil;hook=nil;writes=0;retries=0
 durable={Pets=assert(Pet.NormalizeState(nil)),Win=win or 1000,ShopRewards={WinGrantedTotal=0},ResetToken="test"}
 sessions[player]={Loaded=true,Data=copy(durable)}
 return sessions[player]
end
local function results(n,offset)
 local out={}
 for i=1,n do out[i]={id=guid((offset or 0)+i),pet="Dog",percent=40,duplicate=false,bonus=0} end
 return out
end
local function hatch(id,rev,n,offset)
 return PlayerDataService.MutatePets(player,guid(id),rev,"Hatch",{EggName="Basic",Count=n,PriceWin=100*n,Results=results(n,offset)})
end
local s=reset()
equal(hatch(101,0,3),true,"3 hatch")
equal(s.Data.Win,700);equal(durable.Win,700);equal(s.Data.Pets.Revision,1)
equal(s.Data.Pets.Owned[guid(1)],"Dog");equal(s.Data.Pets.Owned[guid(2)],"Dog")
equal(hatch(101,0,3),true,"receipt replay");equal(s.Data.Win,700);equal(durable.Win,700)
equal(select(2,hatch(102,0,1,10)),"PetStateChanged","stale replay")
equal(PlayerDataService.MutatePets(player,guid(103),1,"Equip",guid(1)),true)
equal(PlayerDataService.MutatePets(player,guid(104),2,"Equip",guid(2)),true)
equal(attrs.Pet,"Dog");equal(attrs.Pet2,"","retired mirror cleared")
equal(s.Data.Pets.Equipped[1],guid(2),"same species copy replaces by ID")
equal(PlayerDataService.MutatePets(player,guid(105),3,"Equip",guid(3)),true)
equal(s.Data.Pets.Equipped[1],guid(3));equal(s.Data.Pets.Equipped[2],nil)
equal(PlayerDataService.MutatePets(player,guid(106),4,"Equip",guid(2)),true)
equal(attrs.Pet,"Dog");equal(attrs.Pet2,"")
local loaded=assert(Pet.NormalizeState(copy(durable.Pets)))
equal(loaded.Equipped[1],guid(2),"reload individual equipment");equal(loaded.Equipped[2],nil)
equal(loaded.Owned[guid(1)],"Dog");equal(loaded.Owned[guid(3)],"Dog","replacement retains owned copies")
equal(s.Data.Win,700,"equip costs zero")
equal(select(2,PlayerDataService.MutatePets(player,guid(107),5,"Equip",guid(999))),"PetNotOwned")
equal(PlayerDataService.MutatePets(player,guid(108),5,"Equip",guid(2)),true,"toggle equipped copy off")
equal(attrs.Pet,"");equal(attrs.Pet2,"");equal(durable.Pets.Equipped[1],"")
equal(PlayerDataService.MutatePets(player,guid(108),5,"Equip",guid(2)),true,"equip receipt retry does not retoggle")
equal(durable.Pets.Equipped[1],"");equal(durable.Pets.Revision,6)
equal(Pet.payout(nil),1,"no ability")

-- Legacy two-slot migration is ordered and does not remove or mutate owned copies.
do
 local raw=copy(loaded);raw.Equipped={guid(3),guid(1)}
 local migrated=assert(Pet.NormalizeState(raw))
 equal(migrated.Equipped[1],guid(3),"first valid, not sorted ID")
 equal(#migrated.Equipped,1);equal(migrated.Owned[guid(1)],"Dog")
 equal(raw.Equipped[2],guid(1),"normalization leaves input untouched")
 equal(migrated.Revision,raw.Revision);equal(migrated.LastRequestId,raw.LastRequestId)
 for _,first in ipairs({"",guid(999),guid(1)}) do
  raw.Equipped={first,guid(1)}
  equal(assert(Pet.NormalizeState(raw)).Equipped[1],guid(1),"empty/stale/duplicate first")
 end
 raw.Equipped={[2]=guid(1)}
 equal(assert(Pet.NormalizeState(raw)).Equipped[1],guid(1),"sparse legacy second")
 raw.Equipped={guid(999),guid(998)}
 equal(assert(Pet.NormalizeState(raw)).Equipped[1],"","no valid equipment")
 raw.Equipped={guid(1),guid(2),guid(3)}
 equal(select(2,Pet.NormalizeState(raw)),"InvalidPetEquip","reject extra slots")
 raw.Equipped={42,guid(1)}
 equal(select(2,Pet.NormalizeState(raw)),"InvalidPetEquip","reject malformed slot type")
 s=reset();durable.Pets=copy(loaded);durable.Pets.Equipped={guid(1),guid(2)};s.Data.Pets=copy(durable.Pets)
 attrs.Pet2="Dog"
 local read=assert(PlayerDataService.GetPetState(player))
 equal(read.Equipped[1],guid(1));equal(read.Equipped[2],nil);equal(writes,0,"migration read never writes store")
 Pet.Publish(player,read);equal(attrs.Pet2,"")
 equal(PlayerDataService.MutatePets(player,guid(109),read.Revision,"Equip",guid(3)),true,"commit normalized legacy equipment")
 equal(#durable.Pets.Equipped,1);equal(durable.Pets.Equipped[1],guid(3))
 equal(durable.Pets.Owned[guid(1)],"Dog");equal(durable.Pets.Owned[guid(2)],"Dog")
 equal(assert(Pet.NormalizeState(copy(durable.Pets))).Equipped[1],guid(3),"reload single slot")
end

-- Exact purchased UI check/count updater; no Roblox UI or rendering required.
do
 local MAIN_NAME,CHECK_NAME="Main","Checkmark"
 local checks={}
 local Tiles={}
 for i=1,3 do
  local check={Visible=true,IsA=function() return true end};checks[i]=check
  local main={FindFirstChild=function() return check end}
  Tiles[guid(i)]={FindFirstChild=function() return main end}
 end
 local infoLabel={Text="You can equip 2 pets"}
 local function setText(label,text) label.Text=text end
 local playerData=assert(Pet.NormalizeState(loaded))
 -- INSERT PET UI CHECKS
 refreshChecks();equal(infoLabel.Text,"Equipped (1/1)")
 equal(checks[1].Visible,false);equal(checks[2].Visible,true);equal(checks[3].Visible,false)
 playerData.Equipped={guid(3)};refreshChecks()
 equal(checks[2].Visible,false);equal(checks[3].Visible,true)
 playerData.Equipped={""};refreshChecks();equal(infoLabel.Text,"Equipped (0/1)")
 equal(checks[3].Visible,false)
end

-- Exact follower refresh/despawn; cosmetic movement is unchanged and not simulated.
do
 local PET_INDEX="pet"
 local clones,removed=0,0
 local models={pet2={}}
 local janitor={Remove=function(_,key) if models[key] then removed+=1;models[key]=nil end end,
  Add=function(_,model,_,key) models[key]=model;return model end}
 local Followers={[player]={[2]={name="Dog"}}}
 local Watched={[player]=janitor}
 local function decorate() end
 local function dress() end
 local function resize() end
 local originalModel=Pet.model
 Pet.model=function() return {Clone=function() clones+=1;return {} end} end
 -- INSERT FOLLOW REFRESH
 attrs.Pet="Dog";attrs.Pet2="Dog"
 refresh(player);equal(Followers[player][2],nil);equal(models.pet2,nil,"stale second follower destroyed")
 equal(clones,1);refresh(player);equal(clones,1,"repeat refresh creates no duplicate")
 attrs.Pet="Bear";refresh(player);equal(clones,2);equal(Followers[player][1].name,"Bear")
 attrs.Pet="";refresh(player);equal(Followers[player][1],nil);equal(models.pet1,nil)
 equal(removed,3,"retired/replaced/unequipped models cleaned")
 Pet.model=originalModel
end

s=reset();mode="after"
equal(select(2,hatch(201,0,8)),"InventorySavePending","ambiguous commit")
equal(durable.Win,200);equal(s.Data.Win,1000);equal(attrs.PetSavePending,true)
equal(select(2,hatch(202,0,1,20)),"DataSaving","concurrent request")
equal(PlayerDataService.SetWin(player,900),false,"reserve pending balance")
equal(PlayerDataService.SetWin(player,1010),true,"reward during pending")
equal(retries,1);mode=nil
equal(hatch(201,0,8),true,"same receipt confirmation")
equal(durable.Win,200);equal(s.Data.Win,210,"retain live reward")
equal(s.Data.Pets.Revision,1);equal(#s.Data.Pets.LastResults,8);equal(attrs.PetSavePending,false)

s=reset();mode="before"
equal(select(2,hatch(301,0,1)),"InventorySavePending");equal(durable.Win,1000)
mode=nil;equal(hatch(301,0,1),true);equal(durable.Win,900)
s=reset();hook=function()
 equal(select(2,hatch(402,0,1,20)),"DataSaving","concurrent during yielding write")
 equal(select(2,hatch(401,0,1)),"InventorySavePending","same request while resolving")
 durable.ShopRewards.WinGrantedTotal=50;durable.Win+=50
end
equal(hatch(401,0,1),true);equal(durable.Win,950);equal(s.Data.Win,950)
s=reset(99);equal(select(2,hatch(501,0,1)),"NotEnoughWin");equal(writes,0)
s=reset();s.Loaded=false;equal(select(2,hatch(502,0,1)),"DataNotLoaded");equal(writes,0)
s=reset();s.OwnershipLost=true;equal(select(2,hatch(503,0,1)),"SessionOwnershipLost");equal(writes,0)
s=reset();s.StudioStartOverride={};equal(select(2,hatch(504,0,1)),"StudioOverrideActive");equal(writes,0)
s=reset();durable.ResetToken="new";equal(select(2,hatch(505,0,1)),"SaveSupersededByReset");equal(writes,0)
s=reset();durable.Pets={Version=99};equal(select(2,hatch(506,0,1)),"InvalidPetsVersion");equal(writes,0)
s=reset();equal(select(2,hatch(507,0,2)),"InvalidPetHatch");equal(writes,0)
s=reset();equal(select(2,PlayerDataService.MutatePets(player,guid(508),0,"Hatch",{EggName="Basic",Count=1,PriceWin=100,Results={{id=guid(1),pet="Dog",percent=3}}})),"InvalidPetResult")
equal(writes,0)

-- Exact server request path with deliberately limited fixture geometry.
local script={Parent={PlayerDataService="Data",PetServer="Pets"}}
modules.Data=PlayerDataService
modules.Pets={state=PlayerDataService.GetPetState,equip=function(p,id,r,rev) return PlayerDataService.MutatePets(p,r,rev,"Equip",id) end}
modules.Egg.count=function(button) return ({Open1=1,Open3=3,Open8=8})[button] end
modules.Egg.FolderName="Eggs"
local distance=99
local position=setmetatable({}, {__sub=function() return {Magnitude=distance} end})
local anchor={Position=position,IsA=function(_,c) return c=="BasePart" end}
local workspace={FindFirstChild=function() return {FindFirstChild=function(_,name) return eggEntries[name] and anchor end} end}
player.Character={FindFirstChild=function() return {Position=position} end,FindFirstChildOfClass=function() return {Health=100} end}
-- INSERT EGG SERVER
local function request(action,a,b)
 -- A new fixture player identity avoids the production per-player throttle.
 local fresh=table.clone(player);sessions[fresh]=sessions[player]
 return EggServer.request(fresh,action,guid(900),0,a,b)
end
s=reset();equal(request("OpenEgg","Unknown","Open1").reason,"EggUnavailable")
equal(request("OpenEgg","Basic","Open2").reason,"InvalidOpenCount")
equal(request("OpenEgg","Basic","Open1").reason,"TooFarFromEgg")
distance=0
s=reset(99);equal(request("OpenEgg","Basic","Open1").reason,"NotEnoughWin")
s=reset();s.Loaded=false;equal(request("OpenEgg","Basic","Open1").reason,"DataNotLoaded")
equal(writes,0,"rejected requests never write")

-- All purchased Egg groups/counts use their own server-selected price and pool.
modules.Egg.ranked=function(pool)
 local list={};for pet,percent in pairs(pool) do table.insert(list,{pet=pet,percent=percent}) end
 table.sort(list,function(a,b) return a.percent>b.percent end)
 return list
end
local picked=0
modules.Egg.pick=function(list) picked+=1;local item=list[(picked-1)%#list+1];return item.pet,item.percent end
Pet.model=function(name)
 for _,entry in pairs(eggEntries) do if entry.Pets[name] then return {} end end
 return nil
end
for name,entry in pairs(eggEntries) do
 for _,count in ipairs({1,3,8}) do
  s=reset(entry.wins*count+7);picked=0
  local response=request("OpenEgg",name,"Open"..count)
  equal(response.ok,true,name.." hatch "..count)
  equal(durable.Win,7,name.." exact count price")
  equal(#durable.Pets.LastResults,count)
  local owned=0;for id,pet in pairs(durable.Pets.Owned) do owned+=1;equal(entry.Pets[pet]~=nil,true,name.." pool") end
  equal(owned,count,"individual copy IDs")
  for _,result in ipairs(durable.Pets.LastResults) do equal(result.percent,entry.Pets[result.pet]);equal(result.bonus,0) end
  equal(request("OpenEgg",name,"Open"..count).ok,true,"receipt replay across counts")
  equal(durable.Win,7);equal(durable.Pets.Revision,1)
  local loaded=assert(Pet.NormalizeState(copy(durable.Pets)))
  local id=loaded.LastResults[1].id
  equal(PlayerDataService.MutatePets(player,guid(901),1,"Equip",id),true)
  equal(attrs.Pet,loaded.Owned[id]);equal(attrs.Pet2,"")
  equal(#durable.Pets.Equipped,1)
 end
 s=reset(entry.wins-1);equal(request("OpenEgg",name,"Open1").reason,"NotEnoughWin");equal(writes,0)
 s=reset(entry.wins);distance=16;equal(request("OpenEgg",name,"Open1").reason,"TooFarFromEgg");equal(writes,0);distance=0
end
-- Cross-Egg or reduced-price payloads cannot bypass the persistence validator.
s=reset(10000000)
for _,payload in ipairs({
 {EggName="Rare",Count=1,PriceWin=100,Results={{id=guid(1),pet="Cow",percent=40}}},
 {EggName="Unknown",Count=1,PriceWin=100,Results=results(1)},
 {EggName="Rare",Count=1,PriceWin=10000,Results=results(1)},
 {EggName="Mythic",Count=1,PriceWin=1000000,Results={{id=guid(1),pet="Turtle",percent=3}}},
}) do
 equal(PlayerDataService.MutatePets(player,guid(999),0,"Hatch",payload),false)
 equal(writes,0)
end
s=reset(10000);mode="after"
equal(request("OpenEgg","Rare","Open1").reason,"InventorySavePending")
equal(durable.Win,0);mode=nil;distance=999
equal(request("OpenEgg","Rare","Open1").ok,true,"lost reply confirms away from Egg")
equal(durable.Win,0);equal(durable.Pets.Revision,1);distance=0
-- Limited Phase 4: exact model lookup / server ownership / existing persistence.
do
 local templates={}
 for _,entry in modules.Limited.Entries do
  templates[entry.Name]={Name=entry.Name,IsA=function(_,kind) return kind=="Model" end}
 end
 local folder={FindFirstChild=function(_,name) return templates[name] end}
 local assets={FindFirstChild=function(_,name) if name==modules.Limited.ModelsFolder then return folder end end}
 function RS:FindFirstChild(name) return name=="Assets" and assets or nil end
 Pet.model=productionPetModel
 for _,entry in modules.Limited.Entries do equal(Pet.model(entry.Name),templates[entry.Name],"exact registered model") end
 local total=0;for _,entry in modules.Limited.Entries do total+=entry.Percent end
 equal(total,100);equal(modules.Limited.ByName.Pet_024.Percent,3);equal(modules.Limited.ByName.Pet_135.Percent,0.5)
 equal(modules.Limited.PurchaseEnabled,false,"purchase remains disabled")
 -- Synthetic in-memory ownership only; not a live grant or paid receipt.
 s=reset(500)
 for i,entry in modules.Limited.Entries do durable.Pets.Owned[guid(7000+i)]=entry.Name end
 durable.Pets.Owned[guid(7008)]="Pet_042"
 s.Data.Pets=copy(durable.Pets)
 -- INSERT LIMITED SERVER
 for i,entry in modules.Limited.Entries do
  local id=guid(7000+i)
  equal(limitedServer.equip(player,id,guid(7100+i),s.Data.Pets.Revision),true,"equip limited "..entry.Name)
  equal(s.Data.Pets.Equipped[1],id);equal(s.Data.Pets.Equipped[2],nil);equal(attrs.Pet,entry.Name)
 end
 local writeCount=writes
 equal(select(2,limitedServer.equip(player,guid(7999),guid(7200),s.Data.Pets.Revision)),"PetNotOwned")
 equal(writes,writeCount,"unowned equip never persists")
 equal(limitedServer.equip(player,guid(7007),guid(7201),s.Data.Pets.Revision),true)
 equal(s.Data.Pets.Equipped[1],"","select equipped copy to remove")
 equal(attrs.Pet,"");equal(attrs.Pet2,"")
 equal(limitedServer.equip(player,guid(7001),guid(7202),s.Data.Pets.Revision),true)
 equal(limitedServer.equip(player,guid(7008),guid(7203),s.Data.Pets.Revision),true)
 equal(s.Data.Pets.Equipped[1],guid(7008),"same species switches by copy ID")
 equal(s.Data.Pets.Owned[guid(7001)],"Pet_042","prior copy retained")
 equal(durable.Win,500,"limited equip has no payment")
 local count=0;for _ in pairs(durable.Pets.Owned) do count+=1 end;equal(count,8)
 local old=copy(durable.Pets);old.Equipped={guid(7004),guid(7001)}
 local migrated=assert(Pet.NormalizeState(old));equal(migrated.Equipped[1],guid(7004));equal(migrated.Equipped[2],nil)

 -- Exact future notification consumer with a queue spy; no animation/UI/Remote.
 local HatchClient={};local Limited=modules.Limited;local shownLimited={}
 local calls=0;local last;local fail=false
 local playVerified=function(results,egg)
  if fail then return false end
  calls+=1;last={results=results,egg=egg};return true
 end
 local function clear() end
 local MenuClient={shroud=function() end}
 local function warn() end
 -- INSERT LIMITED HATCH GATE
 local notice={ProductId=Limited.ProductId,PurchaseId="offline-receipt-1",Saved=true,Status="Granted",
  Result={id=guid(7001),pet="Pet_042",percent=25},State=copy(durable.Pets)}
 local bad=copy(notice);bad.Saved=false;equal(select(2,HatchClient.playCommittedLimited(bad)),"NotCommitted")
 bad=copy(notice);bad.Status="Cancelled";equal(HatchClient.playCommittedLimited(bad),false)
 bad=copy(notice);bad.ProductId=1;equal(HatchClient.playCommittedLimited(bad),false)
 bad=copy(notice);bad.Result.id=guid(7999);equal(select(2,HatchClient.playCommittedLimited(bad)),"ResultNotOwned")
 bad=copy(notice);bad.Result.percent=1;equal(HatchClient.playCommittedLimited(bad),false)
 equal(calls,0,"cancel/unconfirmed/invalid notifications produce no reveal")
 equal(HatchClient.play({{pet="Pet_042",percent=25}},nil),false,"generic Win route rejects limited result")
 equal(HatchClient.playCommittedLimited(notice),true);equal(calls,1);equal(last.egg,nil,"RGBEgg fallback selected")
 equal(last.results[1].pet,"Pet_042");equal(last.results[1].bonus,0);equal(#last.results,1)
 equal(select(2,HatchClient.playCommittedLimited(notice)),"AlreadyShown");equal(calls,1)
 local second=copy(notice);second.PurchaseId="offline-receipt-2";second.Result.id=guid(7008)
 fail=true;equal(HatchClient.playCommittedLimited(second),false);fail=false
 equal(HatchClient.playCommittedLimited(second),true);equal(calls,2)
 equal(HatchClient.playCommittedLimited(notice),false,"older notification still deduplicated");equal(calls,2)
end

print("BASIC_EGG_OFFLINE_PASS",assertions)
