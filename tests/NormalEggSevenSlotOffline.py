"""Execute the real EggClient stampSheet using GUI mocks; no Studio or game data."""
from pathlib import Path
import json
import subprocess
import sys

root=Path(__file__).resolve().parents[1]
client=(root/'src/StarterPlayer/StarterPlayerScripts/Services/EggClient.luau').read_text(encoding='utf-8')
stamp=client[client.index('local function findPath('):client.index('local function press(')]
egg=(root/'src/ReplicatedStorage/Modules/Egg.luau').read_text(encoding='utf-8')
shared=(root/'tests/NormalEggMergeOffline.py').read_text(encoding='utf-8')
shared=shared[shared.index('local names={'):shared.index('local ranks=')]
presentation=(root/'tests/MergeShopPresentationOffline.py').read_text(encoding='utf-8')
nodes=presentation[presentation.index('local checks=0'):presentation.index('local materialState=')]
fixture=nodes+shared.replace('-- SOURCE JSON',json.dumps(egg))+r'''
methods.FindFirstChildWhichIsA=methods.FindFirstChildOfClass
local SLOTS_PATH={"Background","Pets"}
local BACKGROUND_NAME,INFO_NAME,PERCENT_NAME,SHADOW_SUFFIX="Background","Info","Percent","Shadow"
local Config=legacy;Config.Eggs.titleFormat="%s Egg";Config.Eggs.percentFormat="%g%%"
local Enum={SortOrder={LayoutOrder=0}}
local UDim={new=function(scale,offset)return {Scale=scale,Offset=offset}end}
local UDim2={new=function(x,dx,y,dy)return {X={Scale=x,Offset=dx},Y={Scale=y,Offset=dy}}end}
local icons=node("Pets","Folder")
for _,list in pairs(names)do for _,name in ipairs(list)do
 local icon=node(name,"Decal");icon.Texture="icon-for-"..name;icon.Parent=icons
end end
local function warn(message)error(message)end
-- ACTUAL STAMP
for _,eggName in ipairs(Egg.NormalOrder)do
 local folder=node("Pets","Folder")
 local layout=node("UIListLayout","UIListLayout");layout.Padding=UDim.new(.05,0);layout.Wraps=true;layout.Parent=folder
 for index=1,6 do
  local tile=node(tostring(index),"ImageLabel",{node("Percent","TextLabel"),node("Button","TextButton")})
  tile.Parent=folder
 end
 local background=node("Background","Frame",{node("Info","TextLabel"),folder})
 local host=node(eggName,"BillboardGui",{background})
 local before=clones
 stampSheet(eggName,host)
 eq(background.Info.Text,eggName.." Egg")
 local total=0
 local list=Egg.ranked(Egg.pets(eggName))
 for index,slot in ipairs(list)do
  local tile=folder[tostring(index)]
  eq(tile.Visible,true);eq(tile.LayoutOrder,index)
  eq(tile.Image,"icon-for-"..names[eggName][index],"image follows original order")
  eq(tile.Percent.Text,string.format("%g%%",slot.percent),"server draw matches numeric UI")
  eq(tile.Size.X.Scale,.13);eq(tile.Size.Y.Scale,.13)
  total+=tonumber(tile.Percent.Text:sub(1,-2))
 end
 eq(total,100);eq(#folder:GetChildren(),8,"seven cards plus original layout")
 eq(layout.Wraps,false)
 checks+=1;assert(math.abs(7*folder["1"].Size.X.Scale+6*layout.Padding.Scale-1)<1e-9,"one-row footprint")
 local firstClones=clones
 stampSheet(eggName,host);eq(clones,firstClones,"restamp does not clone duplicate seventh")
 for _,tile in folder:GetChildren()do if tile:IsA("ImageLabel")then tile.Visible=false end end
 stampSheet(eggName,host);eq(folder["7"].Visible,true,"reopen restores seventh")
 eq(clones,firstClones)
end
print("NORMAL_EGG_SEVEN_SLOT_OFFLINE_PASS",checks)
'''
fixture=fixture.replace('-- ACTUAL STAMP',stamp)
result=subprocess.run([sys.argv[1]],input='assert(loadstring('+json.dumps(fixture)+'))()\n',text=True,capture_output=True)
print(result.stdout)
if result.returncode or 'NORMAL_EGG_SEVEN_SLOT_OFFLINE_PASS' not in result.stdout:
    print(result.stderr,file=sys.stderr)
    raise SystemExit(1)
