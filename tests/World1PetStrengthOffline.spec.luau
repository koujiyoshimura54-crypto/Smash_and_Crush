local checks=0
local function eq(a,b,label) checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
local function near(a,b)checks+=1;assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b))end
local function copy(t)if type(t)~="table" then return t end;local r={};for k,v in t do r[k]=copy(v)end;return r end
local function count(t)local n=0;for _ in t do n+=1 end;return n end
local function guid(n)return string.format("00000000-0000-0000-0000-%012d",n)end
local nativeTypeof=typeof
local function typeof(v)return type(v)=="table" and v.fakePlayer and "Instance" or nativeTypeof(v)end
local Color3={fromRGB=function()return {}end}
-- SOURCE ConfigEggs
-- SOURCE Limited
-- SOURCE Egg
-- SOURCE Pet
-- SOURCE PetServer
-- SOURCE EggServer
-- SOURCE Strength
-- SOURCE NumberFormat
local loadConfig=assert(loadstring(sourceConfigEggs))
setfenv(loadConfig,setmetatable({Color3=Color3},{__index=getfenv()}))
local Config=loadConfig()
local Limited=assert(loadstring(sourceLimited))()
Config.Egg={reach=15};Config.Pets={}
local RS={Modules={Config="Config",Egg="Egg",Pet="Pet",NumberFormat="NumberFormat"},Config={LimitedEggConfig="Limited",LevelRequirements="Level",RebirthMultiplierConfig="Rebirth"},Remotes={StrengthGain={FireClient=function()end}}}
function RS.Config:WaitForChild(n)return self[n]end
local services={PlayerDataService="Data",DumbbellService="Dumbbell",ItemService="Item",AuraService="Aura",PotionService="Potion",GamePassService="Pass",PetServer="PetServer"}
function services:WaitForChild(n)return self[n]end
local Players={}
local serial=0
local modules={Config=Config,Limited=Limited,Level={},Rebirth={GetMultiplier=function()return 2 end},
 Dumbbell={GetStrengthBonus=function()return 10 end},Aura={GetStrengthBonus=function()return 3 end},
 Item={GetProteinBonus=function()return 2 end,GetElementSetMultiplier=function()return 1.5 end},
 Potion={GetStrengthMultiplier=function()return 1.5 end},Pass={GetVIPStrengthMultiplier=function()return 1.25 end}}
local game={ReplicatedStorage=RS,ServerScriptService={Services=services}}
function game:GetService(name)
 if name=="ReplicatedStorage"then return RS elseif name=="Players"then return Players
 elseif name=="HttpService"then return {GenerateGUID=function()serial+=1;return guid(10000+serial)end}end
 error(name)
end
local function require(token)return assert(modules[token],tostring(token))end
local function load(source)
 local f=assert(loadstring(source));setfenv(f,setmetatable({game=game,require=require,typeof=typeof,script={Parent=services}},{__index=getfenv()}));return f()
end
local Egg=load(sourceEgg);modules.Egg=Egg
local Pet=load(sourcePet);modules.Pet=Pet
local NumberFormat=load(sourceNumberFormat);modules.NumberFormat=NumberFormat
local expected={Basic={2,2,2,4,6,8,12},Rare={8,8,8,12,18,25,35},Legendary={20,20,20,30,45,60,80},Mythic={45,45,45,60,80,100,130}}
local expectedNames={Basic={"Dog","Grey Cat","Pink Bunny","Sheep","Bear","Camel","Slime"},Rare={"Cow","Giraffe","Lion","Lizard","Spider","Bat","Shroom"},Legendary={"Elephant","Mammoth","Penguin","Crocodile","Octopus","Shark","Ninja"},Mythic={"Turtle","Alien","Anglerfish","Dino","Scorpion","Evil Dragon","Chimpanzini Bananini"}}
local odds={25,25,25,15,6.5,3,.5}
for egg,p in expected do
 eq(#Egg.NormalPools[egg].Species,7)
 local total=0
 for slot,percent in p do
  local name=Egg.NormalPools[egg].Species[slot];eq(name,expectedNames[egg][slot]);eq(Pet.StrengthPercent(name),percent)
  eq(Egg.pets(egg)[name],odds[slot]);total+=odds[slot];Config.Pets[name]={}
 end
 eq(total,100)
end
local paid={Pet_042=90,Pet_064=90,Pet_081=90,Pet_086=110,Pet_094=130,Pet_024=160,Pet_135=200}
for name,percent in paid do eq(Pet.StrengthPercent(name),percent);eq(Egg.mergePet(name),nil)end
eq(Limited.ByName.Pet_024.Percent,3);eq(Limited.ByName.Pet_135.Percent,.5)
eq(Limited.ProductId,3717610547);eq(Limited.Count,1);eq(Limited.RollVersion,1)
eq(Pet.StrengthPercent("UnapprovedPet"),nil)
eq(Egg.mergePet("Slime").Points,50);eq(Egg.mergePet("Chimpanzini Bananini").Points,6250)

local sessions,PlayerDataService={},{}
modules.Data=PlayerDataService
local durable,writes,Player
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function resetToken(d)return d.ResetToken end
local function normalizeShop(s)return copy(s)end
local function mergeShop(a,b)return {WinGrantedTotal=math.max(a.WinGrantedTotal,b.WinGrantedTotal)}end
local function metadata()return {},{}end
local function scheduleItemMutationRetry()error("Unexpected retry")end
local function ownedUpdate(_,s,transform)
 local value=transform(copy(durable),{});if value then durable=copy(value);writes+=1 end;return value
end
-- TRANSACTIONS
function PlayerDataService.ResolveItemMutation(p)
 local s=sessions[p];return resolvePetMutation(p,s,s.PendingItemMutation)
end
function PlayerDataService.Get(p)return sessions[p]end
function PlayerDataService.GetLevelState()return 1,0 end
function PlayerDataService.AddStrengthGain(p,gain)
 local after=p:GetAttribute("Strength")+gain;p:SetAttribute("Strength",after);return after
end
local position=setmetatable({},{__sub=function()return {Magnitude=0}end})
local parts={}
for _,name in Egg.NormalOrder do
 local label={Text="",IsA=function()return true end};local prize={FindFirstChild=function(_,key)return key=="Info" and label or nil end}
 parts[name]={Name=name,Position=position,IsA=function()return true end,FindFirstChild=function(_,key)return key=="Prize" and prize end,label=label}
end
local folder={FindFirstChild=function(_,name)return parts[name]end,GetChildren=function()local a={};for _,p in parts do table.insert(a,p)end;return a end}
local workspace={FindFirstChild=function(_,name)return name=="Eggs" and folder end}
local function reset(win)
 writes=0
 local attrs={Strength=0,Win=win,CurrentWorld=1,RebirthCount=1}
 Player={fakePlayer=true,UserId=101,Parent=Players,IsA=function(_,n)return n=="Player"end,GetAttribute=function(_,n)return attrs[n]end,SetAttribute=function(_,n,v)attrs[n]=v end}
 Player.Character={FindFirstChild=function()return {Position=position}end,FindFirstChildOfClass=function()return {Health=100}end}
 durable={Win=win,Pets=assert(Pet.NormalizeState(nil)),ShopRewards={WinGrantedTotal=0},ResetToken="test"}
 durable.Pets.Owned={old="Dog",duplicate="Dog"};durable.Pets.Equipped={"old"}
 sessions[Player]={Loaded=true,Data=copy(durable)};return sessions[Player]
end
Pet.model=function(name)return (Config.Pets[name] or Limited.ByName[name]) and {}end
local PetServer=load(sourcePetServer);modules.PetServer=PetServer
local f=assert(loadstring(sourceEggServer));setfenv(f,setmetatable({game=game,require=require,script={Parent=services},workspace=workspace},{__index=getfenv()}));local EggServer=f()
local OPENS_NAME="Opens"
local SHADOW_SUFFIX="Shadow"
local ReplicatedStorage=RS
-- PRICE UI
local prices={Basic=15,Rare=100,Legendary=300,Mythic=1000}
local function priceUI(name)
 local children={}
 for _,key in {"Open1","Open3","Open8"}do
  local title={Text="",IsA=function(_,c)return c=="TextLabel"end}
  table.insert(children,{Name=key,Title=title,FindFirstChild=function(_,n)return n=="Title" and title end})
 end
 local open={FindFirstChild=function(_,n)return n=="Opens" and {GetChildren=function()return children end}end}
 stampSheet(name,open);return children
end
local operation=0
for egg,unit in prices do
 eq(Egg.price(egg),unit)
 for _,frame in priceUI(egg)do
  local n=Egg.count(frame.Name);local total=unit*n
  eq(frame.Title.Text,string.format("Open %d\n%s Win",n,NumberFormat.Price(total)))
  local s=reset(total);operation+=1
  local response=EggServer.request(Player,"OpenEgg",guid(operation),0,egg,frame.Name)
  eq(response.ok,true);eq(s.Data.Win,0);eq(durable.Win,0)
  eq(count(durable.Pets.Owned),2+n);eq(durable.Pets.Owned.old,"Dog");eq(durable.Pets.Owned.duplicate,"Dog")
  eq(durable.Pets.Equipped[1],"old");eq(#durable.Pets.LastResults,n)
  eq(EggServer.request(Player,"OpenEgg",guid(operation),0,egg,frame.Name).ok,true)
  eq(s.Data.Win,0);eq(count(durable.Pets.Owned),2+n)
  s=reset(total-1);operation+=1
  response=EggServer.request(Player,"OpenEgg",guid(operation),0,egg,frame.Name)
  eq(response.reason,"NotEnoughWin");eq(writes,0);eq(s.Data.Win,total-1);eq(count(s.Data.Pets.Owned),2)
 end
end
EggServer.init()
for name,part in parts do eq(part.label.Text,NumberFormat.Price(prices[name]))end

local Strength=load(sourceStrength)
local function equip(name)
 local s=sessions[Player];s.Data.Pets.Owned.target=name;s.Data.Pets.Equipped={"target"};durable.Pets=copy(s.Data.Pets)
end
local function gain(amount,ticks,multiplier)
 Player:SetAttribute("Strength",0);return Strength.AddStrength(Player,amount,ticks,multiplier)
end
local s=reset(123);s.Data.Pets.Equipped={""}
local walk=gain(5,2);local treadmill=gain(5,1,4)
near(walk,84.375);near(treadmill,450)
for name,factor in {Dog=1.02,["Chimpanzini Bananini"]=2.3,Pet_135=3,Pet_042=1.9}do
 equip(name);near(PetServer.GetStrengthMultiplier(Player),factor)
 near(gain(5,2),walk*factor);near(gain(5,1,4),treadmill*factor)
 Player:SetAttribute("Strength",0);near(Strength.AddRewardStrength(Player,100),100)
 near(Strength.GetNormalTrainingGain(Player,5),40);eq(Player:GetAttribute("Win"),123)
 Player:SetAttribute("CurrentWorld",2);near(gain(5,2),walk);near(gain(5,1,4),treadmill);Player:SetAttribute("CurrentWorld",1)
end
equip("Dog");s.Data.Pets.Owned.extra="Dog";s.Data.Pets.Equipped[2]="extra"
near(PetServer.GetStrengthMultiplier(Player),1.02,"only first slot")
Player:SetAttribute("Pet","Pet_135");Player:SetAttribute("PetStrengthMultiplier",999)
near(gain(5,2),walk*1.02,"client/display mirrors ignored")
s.Data.Pets.Equipped={"stale-id"};near(PetServer.GetStrengthMultiplier(Player),1)
equip("UnapprovedPet");near(PetServer.GetStrengthMultiplier(Player),1)
equip("Dog");s.OwnershipLost=true;near(PetServer.GetStrengthMultiplier(Player),1);s.OwnershipLost=nil
s.Loaded=false;near(PetServer.GetStrengthMultiplier(Player),1);s.Loaded=true
-- Confirm real equip/unequip transactions and reload preserve individual IDs/ownership.
s=reset(50);s.Data.Pets.Owned.paid="Pet_135";durable=copy(s.Data)
local before=count(s.Data.Pets.Owned)
eq(PetServer.equip(Player,"paid",guid(800),0),true);near(PetServer.GetStrengthMultiplier(Player),3)
eq(PetServer.equip(Player,"paid",guid(800),0),true);near(PetServer.GetStrengthMultiplier(Player),3)
s.Data.Pets=assert(Pet.NormalizeState(copy(durable.Pets)));near(PetServer.GetStrengthMultiplier(Player),3)
eq(count(s.Data.Pets.Owned),before);eq(s.Data.Pets.Owned.old,"Dog");eq(s.Data.Pets.Owned.duplicate,"Dog")
eq(PetServer.equip(Player,"paid",guid(801),1),true);near(PetServer.GetStrengthMultiplier(Player),1)
eq(PetServer.equip(Player,"missing",guid(802),2),false);eq(s.Data.Win,50)
eq(Pet.MaxEquipped,1);eq(Pet.payout(nil),1,"retired purchased payout unchanged")
print("WORLD1_PET_STRENGTH_OFFLINE_PASS",checks,"12 price paths; normal/fixed/world2 gains; immutable IDs")
