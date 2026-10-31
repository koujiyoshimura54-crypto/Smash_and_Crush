return function(code)

local p={Parent=true};local data={World2Visited=false,HighestUnlockedWorld=1,RebirthCount=0,Strength=0}
local equipment={Dumbbell=0,Aura=0,Protein=0,Belt=0,Rebirth=1,VIP=1,Element=1,Pet=1};local owned={}
local normal={Name="normal",Multiplier=1,RequiredRebirth=0}
local re3={Name="re3",Multiplier=2,RequiredRebirth=3};local re5={Name="re5",Multiplier=3,RequiredRebirth=5}
local paid1={Name="paid1",Multiplier=20,RequiresPremium=true}
local w2={Name="w2",Multiplier=7,RequiredRebirth=7};local paid2={Name="paid2",Multiplier=35,RequiresPremium=true}
local folder1={GetChildren=function()return {normal,re3,re5,paid1}end}
local folder2={GetChildren=function()return {w2,paid2}end}
local area={FindFirstChild=function()return folder2 end};local map={FindFirstChild=function()return area end}
local workspace={FindFirstChild=function(_,name)return name=="Treadmills" and folder1 or map end}
local dependencies={PlayerDataService={Get=function()return {Loaded=true,Data=data}end},
DumbbellService={GetStrengthBonus=function()return equipment.Dumbbell end},
AuraService={GetStrengthBonus=function()return equipment.Aura end},
ItemService={GetProteinBonus=function()return equipment.Protein end,GetBeltTreadmillBonus=function()return equipment.Belt end,GetElementSetMultiplier=function()return equipment.Element end},
GamePassService={AreEffectsEnabled=function()return true end,HasPremiumTreadmill=function(_,w)return owned[w]==true end,GetVIPStrengthMultiplier=function()return equipment.VIP end},
PetServer={GetStrengthMultiplier=function()return equipment.Pet end},
RebirthConfig={GetMultiplier=function()return equipment.Rebirth end},TrainingConfig={BaseGain=1,TrainingInterval=.5},
TreadmillConfig={GetForModel=function(m)return m end}}
local parent={};local config={};for k in pairs(dependencies)do parent[k]=k;config[k]=k end
local game={GetService=function()return {Config=config}end}
local fn=assert(loadstring(code));setfenv(fn,setmetatable({script={Parent=parent},game=game,workspace=workspace,require=function(k)return dependencies[k]end},{__index=getfenv()}))
local M=fn();local checks=0
local function verify(expected,name)checks+=1;local rate,c=M.Get(p);assert(math.abs(rate-expected)<1e-8,name.." "..rate);return c end
verify(2,"W1 normal")
data.RebirthCount=2;verify(2,"Rebirth locked")
data.RebirthCount=3;verify(4,"Rebirth 3")
data.RebirthCount=5;verify(6,"Rebirth 5")
owned[1]=true;verify(40,"owned W1 premium");owned[1]=false
data.HighestUnlockedWorld=2;verify(6,"unlock alone is not arrival")
data.World2Visited=true;data.RebirthCount=7;verify(14,"W2 reached back in W1")
data.Strength=1e30;verify(14,"balance independence")
p.CurrentWorld=1;p.StrengthPotion=999;verify(14,"current world and potion independence")
owned[2]=true;local best=verify(70,"W2 premium");assert(best.World==2);checks+=1
equipment={Dumbbell=10,Aura=20,Protein=30,Belt=3,Rebirth=4,VIP=1.25,Element=1.5,Pet=2}
verify(61*38*4*1.25*1.5*2/.5,"complete equation")
assert(data.Strength==1e30 and p.CurrentWorld==1);checks+=1
return {Checks=checks,NoPlayerMutation=true,World2CandidateRetained=true}
end

