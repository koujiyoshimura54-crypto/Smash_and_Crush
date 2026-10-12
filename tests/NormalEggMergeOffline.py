"""Run actual shared Egg helpers without Roblox/players/DataStores."""
from pathlib import Path
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'src/ReplicatedStorage/Modules/Egg.luau').read_text(encoding='utf-8')

FIXTURE = r'''
local checks=0
local function eq(a,b,msg) checks+=1;assert(a==b,(msg or "")..": "..tostring(a).." ~= "..tostring(b)) end
local function near(a,b) checks+=1;assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b)) end
local names={
 Basic={"Dog","Grey Cat","Pink Bunny","Sheep","Bear","Camel"},
 Rare={"Cow","Giraffe","Lion","Lizard","Spider","Bat"},
 Legendary={"Elephant","Mammoth","Penguin","Crocodile","Octopus","Shark"},
 Mythic={"Turtle","Alien","Anglerfish","Dino","Scorpion","Evil Dragon"},
}
local legacy={Eggs={Eggs={},Buttons={Open1=1,Open3=3,Open8=8}}}
local odds={40,25,15,10,7,3}
local prices={Basic=100,Rare=10000,Legendary=100000,Mythic=1000000}
for egg,list in pairs(names) do
 local pets={};for index,name in ipairs(list) do pets[name]=odds[index] end
 legacy.Eggs.Eggs[egg]={Pets=pets,wins=prices[egg]}
end
local paid={ByName={}}
for _,name in ipairs({"Pet_042","Pet_064","Pet_081","Pet_086","Pet_094","Pet_024","Pet_135"})do paid.ByName[name]={}end
local configToken,limitedToken={},{}
local rs={Modules={Config=configToken},Config={LimitedEggConfig=limitedToken}}
local environment=setmetatable({game={GetService=function()return rs end},require=function(token)return token==configToken and legacy or paid end},{__index=getfenv()})
local loadEgg=assert(loadstring(-- SOURCE JSON
))
setfenv(loadEgg,environment)
local Egg=loadEgg()
local ranks={"E","E","E","D","C","B","A"}
local targetOdds={25,25,25,15,6.5,3,.5}
local points={10,10,10,20,30,40,50}
for _,egg in ipairs(Egg.NormalOrder) do
 eq(Egg.validateNormalPool(egg),false,"unapproved incomplete pool never live")
 eq(Egg.price(egg),prices[egg])
 local total=0
 for index,name in ipairs(names[egg]) do
  eq(Egg.pets(egg)[name],odds[index],"legacy chances remain active")
  total+=Egg.pets(egg)[name]
  local meta=Egg.mergePet(name)
  eq(meta.Egg,egg);eq(meta.Slot,index);eq(meta.Rank,ranks[index])
  eq(meta.TargetPercent,targetOdds[index]);eq(meta.Points,points[index]*Egg.NormalPools[egg].Coefficient)
  eq(meta.Percent,odds[index]);eq(meta.PoolApproved,false)
 end
 eq(total,100)
end
for name in pairs(paid.ByName)do eq(Egg.mergePet(name),nil,"paid materials excluded")end
eq(Egg.mergePet("UnknownPet"),nil)
eq(Egg.mergePet("Slime"),nil,"unapproved proposed Pet not registered")
eq(Egg.count("Open1"),1);eq(Egg.count("Open3"),3);eq(Egg.count("Open8"),8)
-- Validation tests mutate this isolated helper instance only, never the game/file.
local pool=Egg.NormalPools.Basic
pool.Approved=true;eq(Egg.validateNormalPool("Basic"),false,"six still refused")
pool.Species[7]="Dog";eq(Egg.validateNormalPool("Basic"),false,"duplicate refused")
pool.Species[7]="Pet_042";eq(Egg.validateNormalPool("Basic"),false,"paid refused")
pool.Species[7]="Slime";eq(Egg.validateNormalPool("Basic"),true,"complete approved test pool")
local ordered=Egg.ranked(Egg.pets("Basic"))
local sum=0;local distinct={}
for i,slot in ipairs(ordered)do
 eq(slot.pet,pool.Species[i]);eq(slot.percent,targetOdds[i]);sum+=slot.percent
 eq(distinct[slot.pet],nil);distinct[slot.pet]=true
 local meta=Egg.mergePet(slot.pet);eq(meta.Rank,ranks[i]);eq(meta.Points,points[i])
end
eq(sum,100);eq(#ordered,7)
pool.Species[7]=nil;pool.Approved=false
local rows={
 {20,60,40,0,0},{30,40,60,0,0},{40,20,80,0,0},{50,0,100,0,0},
 {100,0,60,40,0},{150,0,40,60,0},{200,0,20,80,0},{250,0,0,100,0},
 {500,0,0,60,40},{750,0,0,40,60},{1000,0,0,20,80},{1250,0,0,0,100},
}
local function checkPreview(p,count,expected)
 local view=Egg.mergePreview(p,count);eq(view.Eligible,true)
 local seen,sum={},0
 for _,out in ipairs(view.Outcomes)do
  eq(seen[out.Egg],nil);seen[out.Egg]=out.Percent;sum+=out.Percent
  checks+=1;assert(out.Percent>0,"zero outcomes hidden")
 end
 near(sum,100)
 if expected then for i,egg in ipairs(Egg.NormalOrder)do near(seen[egg] or 0,expected[i])end end
 return view
end
for _,row in ipairs(rows)do checkPreview(row[1],2,{row[2],row[3],row[4],row[5]})end
for index=2,#rows do
 local a,b=rows[index-1],rows[index];local expected={}
 for i=1,4 do expected[i]=(a[i+1]+b[i+1])/2 end
 checkPreview((a[1]+b[1])/2,2,expected)
end
for p=20,1300 do checkPreview(p,2)end
checkPreview(20.12345,2);checkPreview(55.5555,2);checkPreview(321.4321,3)
for n=2,5 do checkPreview(Egg.mergePet("Dog").Points*n,n,{(5-n)*20,n*20,0,0})end
checkPreview(Egg.mergePet("Dog").Points+Egg.mergePet("Camel").Points,2,{0,100,0,0})
checkPreview(Egg.mergePet("Cow").Points+Egg.mergePet("Bear").Points,2,{0,76,24,0})
checkPreview(Egg.mergePet("Turtle").Points+Egg.mergePet("Dog").Points,2,{0,0,0,100})
local capped=checkPreview(10000,1000,{0,0,0,100});eq(capped.Surplus,8750);eq(capped.EffectivePoints,1250)
for _,count in ipairs({0,1})do local p=Egg.mergePreview(1250,count);eq(p.Eligible,false);eq(#p.Outcomes,0)end
for _,p in ipairs({-1,0,19,math.huge,0/0})do eq(Egg.mergePreview(p,2).Eligible,false)end
print("NORMAL_EGG_MERGE_OFFLINE_PASS",checks)
'''

if __name__ == '__main__':
    program = FIXTURE.replace('-- SOURCE JSON', json.dumps(SOURCE))
    result = subprocess.run([sys.argv[1]], input='assert(loadstring('+json.dumps(program)+'))()\n', text=True, capture_output=True)
    print(result.stdout)
    if result.returncode or 'NORMAL_EGG_MERGE_OFFLINE_PASS' not in result.stdout:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(1)
