from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1]
source=(root/'src/StarterGui/StrengthUI/MergePanel_New/MergePanelClient_New.client.luau').read_text(encoding='utf-8')
setup=source[source.index('local gui=player:'):source.index('local template=script.Parent:')]
client=(root/'src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau').read_text(encoding='utf-8')
builders=client[client.index('local function buildTile('):client.index('function PetClient.setShown(')]
egg_source=(root/'src/ReplicatedStorage/Modules/Egg.luau').read_text(encoding='utf-8')
# Reuse the actual module fixture without running its tests or importing/writing caches.
math_test=(root/'tests/NormalEggMergeOffline.py').read_text(encoding='utf-8')
egg_fixture=math_test[math_test.index('local names={'):math_test.index('local ranks=')]
fixture="""
local checks=0
local function eq(a,b,msg) checks+=1;assert(a==b,(msg or "")..": "..tostring(a).." ~= "..tostring(b))end
local clones=0;local shellClones=0
local function event()
 local x={callbacks={}}
 function x:Connect(f)local c={f=f,active=true};table.insert(self.callbacks,c);return {Disconnect=function()c.active=false end}end
 function x:fire(...)for _,c in self.callbacks do if c.active then c.f(...) end end end
 return x
end
local methods={}
local mt={
 __index=function(x,k)
  if k=="Parent" then return rawget(x,"_Parent") end
  if methods[k] then return methods[k] end
  for _,c in x.children do if c.Name==k and not c.destroyed then return c end end
 end,
 __newindex=function(x,k,v)
  if k=="Parent" then
   local old=rawget(x,"_Parent")
   if old then for i,c in old.children do if c==x then table.remove(old.children,i);break end end end
   rawset(x,"_Parent",v);if v then table.insert(v.children,x) end
  else rawset(x,k,v) end
 end
}
local function node(name,class,children)
 local n=setmetatable({Name=name,ClassName=class or "Frame",ZIndex=6,children={},attrs={},Activated=event(),Destroying=event(),Visible=false,Text=""},mt)
 for _,child in ipairs(children or {})do child.Parent=n end
 return n
end
function methods:IsA(c)return self.ClassName==c or c=="GuiObject" and (self.ClassName=="Frame" or self.ClassName=="ScrollingFrame" or self.ClassName=="TextButton" or self.ClassName=="TextLabel" or self.ClassName=="ImageLabel") or c=="GuiButton" and self.ClassName=="TextButton"end
function methods:WaitForChild(k)return assert(self[k],"missing "..k)end
function methods:FindFirstChild(k)return self[k]end
function methods:GetChildren()return table.clone(self.children)end
function methods:GetDescendants()
 local out={} local function add(x)for _,child in x.children do table.insert(out,child);add(child)end end add(self);return out
end
function methods:Destroy()
 if self.destroyed then return end
 self.Destroying:fire()
 for _,c in self:GetChildren()do c:Destroy()end
 self.Parent=nil;self.destroyed=true
end
function methods:FindFirstChildOfClass(k)for _,c in self.children do if c:IsA(k)then return c end end end
function methods:SetAttribute(k,v)self.attrs[k]=v end
function methods:GetAttribute(k)return self.attrs[k]end
function methods:GetPropertyChangedSignal(k)
 self.events=self.events or {};self.events[k]=self.events[k] or event();return self.events[k]
end
function methods:Clone()
 clones+=1;if self.Name=="ShopPanel" then shellClones+=1 end;local kids={}for _,child in self.children do table.insert(kids,child:Clone())end
 local n=node(self.Name,self.ClassName,kids);n.Visible=self.Visible;n.Text=self.Text;n.Image=self.Image
 n.ZIndex=self.ZIndex;n.ImageTransparency=self.ImageTransparency;n.Size=self.Size;n.ClipsDescendants=self.ClipsDescendants
 for k,v in self.attrs do n.attrs[k]=v end return n
end
local own=node("Owned","TextButton",{node("PriceTag","TextLabel"),node("StudPattern","ImageLabel")})
local originalPage=node("Merge","Frame",{node("MergePanel")})
local inv=node("InventoryPanel","Frame",{node("Content","Frame",{originalPage})})
local originalShop=node("ShopPanel","Frame",{
 node("Top","Frame",{node("ShopText1","TextLabel"),node("ShopText2","TextLabel"),node("Close","TextButton")}),
 node("MainScrollingFrame","ScrollingFrame",{node("Holder","Frame",{node("Card01_SecretPack","Frame",{own})})})
})
local gui=node("StrengthGui","ScreenGui",{inv,originalShop,node("RebirthPanel")})
local skip=node("StageSkipGui","ScreenGui",{node("Panel")})
gui.Parent=node("PlayerGui","Folder",{skip})
local player={Character={FindFirstChild=function()return {Position={X=30,Y=0,Z=0}}end}}
local services=node("Services","Folder",{node("PetClient","ModuleScript")})
function player:WaitForChild(name)
 if name=="PlayerScripts" then return node("PlayerScripts","Folder",{services}) end
 return {WaitForChild=function()return gui end}
end
function player:GetAttribute()return self.world or 1 end
local pos={X=30,Y=0,Z=0}
player.Character.FindFirstChild=function()return {Position=pos}end
local origin=0;local cylinder=false
local area={Shape=2,Size=setmetatable({X=20,Y=20,Z=20},{__div=function(v,n)return {X=v.X/n,Y=v.Y/n,Z=v.Z/n}end}),CFrame={PointToObjectSpace=function(_,p)return {X=p.X-origin,Y=p.Y,Z=p.Z}end},IsA=function(_,c)return c=="BasePart" or (c=="Part" and cylinder)end}
local workspace={FindFirstChild=function()return {FindFirstChild=function()return area end}end}
local beat=event()
local counterDonor=node("2PetsEquipInfo","TextLabel")
local listDonor=node("Items","ScrollingFrame",{node("UIListLayout","UIListLayout")})
local starterInventory=node("Inventory","Frame",{node("Main","Frame",{counterDonor,listDonor})})
local game={GetService=function()return {Heartbeat=beat}end,StarterGui={ScreenGui={Menus={Inventory=starterInventory}}}}
local RS={Modules={ResponsivePanels="Responsive",Egg="Egg",LimitedPetViewport="EggViewport"}}
local candidateDonor=node("1","ImageLabel",{node("Percent","TextLabel"),node("Button","TextButton"),node("UIAspectRatioConstraint","UIAspectRatioConstraint")})
RS.Assets={Templates={OpenEgg={Background={Pets={["1"]=candidateDonor}}}}}
local SharedEgg
do
-- INSERT EGG FIXTURE
-- Local module fixture ends with local Egg; retain it outside this block.
SharedEgg=Egg
end
local Egg=SharedEgg
local eggViews,eggCleanups=0,0
local EggViewport={mountEgg=function(host,name)
 eggViews+=1
 local viewport=node("NormalEggViewport","ViewportFrame");viewport.Parent=host
 return function()eggCleanups+=1;viewport:Destroy()end,viewport
end}

local Instance={new=function(c)return node("",c)end}
local Enum={AutomaticSize={None=0,Y=1},PartType={Cylinder=2},ScrollingDirection={Y=1},VerticalAlignment={Top=0},SortOrder={LayoutOrder=1}}
local UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end}
local Vector2={zero={0,0},new=function(...)return {...}end}

local materialState={Revision=1,Owned={id1="Dog",id2="Dog",id3="Grey Cat",paid="Pet_081"},Equipped={"id3"}}
local equipRequests,refreshRequests=0,0
local PetClient={state=function()return materialState end,refresh=function()refreshRequests+=1 end}
PetClient.request=function()equipRequests+=1 end
PetClient.showCard=function()end;PetClient.moveCard=function()end;PetClient.hideCard=function()end
local Janitor={}
function Janitor.new()
 local j={entries={}}
 function j:Add(x,method)table.insert(self.entries,{x=x,method=method});return x end
 function j:Destroy()
  for _,entry in self.entries do
   if type(entry.x)=="function" then entry.x()
   elseif entry.method then entry.x[entry.method](entry.x)
   elseif entry.x.Disconnect then entry.x:Disconnect()
   elseif entry.x.Destroy then entry.x:Destroy()end
  end
  self.entries={}
 end
 return j
end
local janitor=Janitor.new()
local MAIN_NAME,ICON_NAME,CHECK_NAME,TITLE_NAME,BUTTON_NAME,STROKE_NAME="Main","Icon","Checkmark","Title","Button","Stroke"
local ITEM_TEMPLATE_PATH,ICONS_PATH={},{}
local shown=true
local itemTemplate=node("PetInventory","Frame",{node("Stroke","Frame"),node("Main","Frame",{node("Icon","ImageLabel"),node("Checkmark","ImageLabel")}),node("Title","TextLabel"),node("Button","TextButton")})
itemTemplate.ZIndex=4;itemTemplate.Stroke.ZIndex=2;itemTemplate.Main.ZIndex=4
itemTemplate.Main.Icon.ZIndex=2;itemTemplate.Main.Icon.Visible=true;itemTemplate.Main.Icon.ImageTransparency=0
itemTemplate.Main.Icon.Size=UDim2.new(1,0,1,0);itemTemplate.Main.Icon.ClipsDescendants=false
itemTemplate.Main.Checkmark.ZIndex=4;itemTemplate.Title.ZIndex=6;itemTemplate.Button.ZIndex=198
itemTemplate.Button.MouseEnter=event();itemTemplate.Button.MouseMoved=event();itemTemplate.Button.MouseLeave=event()
-- Fresh cloned buttons carry the same signal interface.
local cloneMethod=methods.Clone
function methods:Clone()
 local n=cloneMethod(self)
 if n:IsA("GuiButton")then n.MouseEnter=event();n.MouseMoved=event();n.MouseLeave=event()end
 return n
end
local decal=node("Grey Cat","Decal");decal.Texture="rbxassetid://85629003230143"
local icons=node("Pets","Folder",{decal})
for name,id in pairs({Dog="105828778488847",Bat="86063284560749",Bear="117916941085535"})do
 local icon=node(name,"Decal");icon.Texture="rbxassetid://"..id;icon.Parent=icons
end
for _,name in ipairs({"Cow","Elephant","Turtle"})do
 local icon=node(name,"Decal");icon.Texture="purchased-icon";icon.Parent=icons
end
local boundViews,cleanedViews=0,0
local LimitedViewport={supports=function(name)return name=="Pet_081"end,bind=function()boundViews+=1;return function()cleanedViews+=1 end end}
local setPair=function(root,name,text)root[name].Text=text end
local tint=function(tile,name)tile:SetAttribute("OriginalTint",name)end
local findPath=function()return nil end
local menu=nil
local warn=function(...)print(...)end
local task={spawn=function(f,...)return f(...)end}
-- INSERT MATERIAL BUILDERS
local require=function(token)
 if token=="Egg"then return Egg elseif token=="EggViewport"then return EggViewport
 elseif type(token)=="table" and token.Name=="PetClient" then return PetClient end
 return {Fit=function()end}
end

local function mount()
-- INSERT SETUP
 return {shop=shop,page=page,tabs=tabButtons,pet=petPage,list=materialList,clear=clearMaterials,merge=mergeMaterials,count=selectedLabel,empty=emptyLabel,preview=previewLabel,getTiles=function()return materialTiles end,getCandidates=function()return candidateTiles end}
end
local result=mount()
eq(result.shop.Name,"MergeShopPanel")
eq(result.shop.Top.ShopText1.Text,"Merge")
eq(result.shop.Top.ShopText2.Text,"Merge")
eq(result.tabs.Item.PriceTag.Text,"Item")
eq(result.tabs.Pet.PriceTag.Text,"Pet")
eq(#beat.callbacks,2,"one proximity and one material poll")
local count=clones
eq(mount(),nil,"second mount refused")
eq(clones,count,"no repeated clones")
beat:fire(.1);eq(result.shop.Visible,false)
pos.X=0;beat:fire(.1);eq(result.shop.Visible,true)
eq(result.page.Visible,true)
result.tabs.Pet.Activated:fire()
eq(result.page.Visible,false,"empty Pet body")
eq(result.shop:GetAttribute("SelectedTab"),"Pet")
eq(#result.tabs.Pet.Activated.callbacks,1)
result.tabs.Item.Activated:fire();eq(result.page.Visible,true)
result.shop.Top.Close.Activated:fire();eq(result.shop.Visible,false)
beat:fire(.1);eq(result.shop.Visible,false,"closed inside stays closed")
pos.X=30;beat:fire(.1);pos.X=0;beat:fire(.1);eq(result.shop.Visible,true,"reentry opens")
eq(result.shop:GetAttribute("SelectedTab"),"Item")
eq(shellClones,1,"reentry no shell clones")
origin=100;beat:fire(.1);eq(result.shop.Visible,false,"moved model trigger follows")
pos.X=100;beat:fire(.1);eq(result.shop.Visible,true)
player.world=2;beat:fire(.1);eq(result.shop.Visible,false,"World2 excluded")
player.world=1;beat:fire(.1);eq(result.shop.Visible,true)
inv.Visible=true;inv:GetPropertyChangedSignal("Visible"):fire()
eq(result.shop.Visible,false,"Inventory hides Shop")
eq(shellClones,1)
cylinder=true;pos.Y=9;pos.Z=9;beat:fire(.1);eq(result.shop.Visible,false,"cylinder corner is outside")
pos.Z=0;beat:fire(.1);eq(result.shop.Visible,true)
pos.X=111;beat:fire(.1);eq(result.shop.Visible,false)

player.world=1;pos.X=100;pos.Y=0;pos.Z=0
beat:fire(.5)
result.shop.Visible=true
result.tabs.Pet.Activated:fire()
eq(result.pet.Visible,true)
eq(result.list.AutomaticCanvasSize,Enum.AutomaticSize.Y,"scrollable list")
local tiles=result.getTiles()
eq(tiles.id1.Name,"id1");eq(tiles.id2.Name,"id2","same species distinct copy")
eq(tiles.id1.Title.Text,"Dog")
eq(tiles.id1.Main.Icon.Image,"rbxassetid://105828778488847")
eq(tiles.id2.Main.Icon.Image,tiles.id1.Main.Icon.Image,"duplicate copies share correct purchased image")
eq(tiles.id1.Main.Icon.Visible,true);eq(tiles.id1.Main.Icon.ImageTransparency,0)
eq(tiles.id1.Main.Icon.ZIndex,tiles.id1.Main.ZIndex+1,"Global icon is above opaque card Main")
eq(tiles.id1.Main.Checkmark.ZIndex,tiles.id1.Main.Icon.ZIndex+1)
eq(tiles.id1.Button.ZIndex>tiles.id1.Main.Icon.ZIndex,true)
eq(itemTemplate.Main.Icon.ZIndex,2,"donor unchanged")
eq(tiles.paid,nil,"Robux Limited species excluded, inventory unchanged")
eq(materialState.Owned.paid,"Pet_081")
eq(tiles.id1:GetAttribute("MergeRank"),"E");eq(tiles.id1:GetAttribute("MergePoints"),10)
eq(tiles.id1.MergeRankPoints.Text,"E  |  10 pt")
eq(tiles.id3.Title.Text,"Grey Cat (Equipped)")
eq(tiles.id3.Button.Interactable,false)
eq(#result.merge.Activated.callbacks,0,"Merge has no execution handler")
eq(result.merge.Interactable,false)
tiles.id3.Button.Activated:fire();eq(result.count:GetAttribute("SelectedCount"),0,"equipped copy blocked")
tiles.id1.Button.Activated:fire();eq(result.count:GetAttribute("SelectedCount"),1)
eq(tiles.id1.Main.Checkmark.Visible,true)
tiles.id2.Button.Activated:fire();eq(result.count:GetAttribute("SelectedCount"),2)
eq(result.preview:GetAttribute("TotalPoints"),20)
eq(result.getCandidates().Basic.Percent.Text,"60%")
eq(result.getCandidates().Rare.Percent.Text,"40%")
eq(result.getCandidates().Legendary,nil,"zero-percent candidates absent")
eq(result.getCandidates().Mythic,nil)
eq(result.getCandidates().Basic.EggName.Text,"Basic")
eq(result.shop.Top.ShopText1.AutoLocalize,false)
eq(result.merge.PriceTag.AutoLocalize,false)
local beforeViews=eggViews;beat:fire(.5);eq(eggViews,beforeViews,"poll does not remount Viewports")
Egg.NormalPools.Basic.Icon="configured-image"
beat:fire(.5)
eq(result.getCandidates().Basic.Image,"configured-image","per-Egg configured image takes priority")
eq(result.getCandidates().Basic.NormalEggViewport,nil)
Egg.NormalPools.Basic.Icon="";beat:fire(.5)
eq(result.getCandidates().Basic.NormalEggViewport.Name,"NormalEggViewport")
eq(result.merge.Interactable,false,"minimum met still disabled")
tiles.id1.Button.Activated:fire();eq(result.count:GetAttribute("SelectedCount"),1)
result.clear.Activated:fire();eq(result.count:GetAttribute("SelectedCount"),0)
eq(next(result.getCandidates()),nil,"incomplete inputs show no valid results")
eq(equipRequests,0,"selection never calls equip")
for i=4,10 do materialState.Owned["id"..i]="Grey Cat"end
beat:fire(.5);tiles=result.getTiles()
for i=4,10 do tiles["id"..i].Button.Activated:fire()end
eq(result.count:GetAttribute("SelectedCount"),7,"no fixed five-slot cap")
eq(result.merge.Active,false)
materialState.Owned.id4=nil;beat:fire(.5)
eq(result.count:GetAttribute("SelectedCount"),6,"lost copy pruned")
materialState.Equipped={"id5"};beat:fire(.5)
eq(result.count:GetAttribute("SelectedCount"),5,"newly equipped copy pruned")
eq(result.getTiles().id5.Button.Interactable,false)
result.tabs.Item.Activated:fire()
eq(result.page.Visible,true);eq(result.pet.Visible,false)
eq(next(result.getTiles()),nil,"hidden cards cleaned")
eq(next(result.getCandidates()),nil,"hidden Egg Viewports cleaned")
materialState.Owned.id6=nil;beat:fire(.5)
result.tabs.Pet.Activated:fire()
eq(result.getTiles().id1.Main.Icon.Image,"rbxassetid://105828778488847","image survives rebuild after tab switch")
eq(result.count:GetAttribute("SelectedCount"),4,"selection survives tabs, obsolete copies do not")
result.shop.Visible=false;result.shop:GetPropertyChangedSignal("Visible"):fire()
eq(result.count:GetAttribute("SelectedCount"),0,"close clears selection")
eq(next(result.getTiles()),nil)
eq(cleanedViews,boundViews,"all Viewports cleaned on close")
result.shop.Visible=true;result.tabs.Pet.Activated:fire()
eq(result.count:GetAttribute("SelectedCount"),0)
materialState.Owned={basic="Dog",rare="Cow",legendary="Elephant",mythic="Turtle",paid="Pet_135"};materialState.Equipped={}
beat:fire(.5);tiles=result.getTiles()
eq(tiles.paid,nil)
tiles.basic.Button.Activated:fire();tiles.rare.Button.Activated:fire()
eq(result.preview:GetAttribute("TotalPoints"),60)
eq(result.getCandidates().Rare.Percent.Text,"92%")
eq(result.getCandidates().Legendary.Percent.Text,"8%")
eq(result.getCandidates().Legendary.EggName.Text,"Legendary")
result.clear.Activated:fire()
tiles.basic.Button.Activated:fire();tiles.legendary.Button.Activated:fire()
eq(result.getCandidates().Mythic.EggName.Text,"Mythic")
eq(result.getCandidates().Mythic.Percent.Text,"1.6%")
result.clear.Activated:fire()
tiles.basic.Button.Activated:fire();tiles.mythic.Button.Activated:fire()
eq(result.getCandidates().Mythic.Percent.Text,"100%")
eq(result.preview.Text,"Total: 1260 pt | Above 1250 pt: no extra effect.")
eq(result.merge.Interactable,false)
result.clear.Activated:fire()
materialState={Revision=2,Owned={},Equipped={""}}
itemTemplate.Clone=function()error("copy capability denied")end
materialState={Revision=2,Owned={blocked="Grey Cat"},Equipped={""}};beat:fire(.5)
eq(result.empty.Text,"Purchased Pet UI unavailable.")
eq(next(result.getTiles()),nil,"no substitute card")
eq(result.count:GetAttribute("SelectedCount"),0)
itemTemplate.Clone=nil
materialState={Revision=2,Owned={},Equipped={""}};beat:fire(.5)
eq(result.empty.Text,"No owned normal Pets.")
eq(next(result.getTiles()),nil)
materialState=nil;beat:fire(.5);eq(result.empty.Text,"Pet inventory is loading.")
materialState={Revision=3,Owned={id1="Dog"},Equipped={""}};beat:fire(.5)
local materialTile=result.getTiles().id1
janitor:Destroy()
eq(materialTile.destroyed,nil,"Inventory janitor does not own material cards")
eq(equipRequests,0)
local inventoryTile=buildTile("inventory-id","Grey Cat",1)
eq(inventoryTile.Main.Icon.Image,"rbxassetid://85629003230143")
eq(inventoryTile.Main.Icon.ZIndex,2,"Inventory retains original Sibling layering")
eq(inventoryTile.Main.ZIndex,4)
inventoryTile.Button.Activated:fire();eq(equipRequests,1,"legacy Inventory equip callback retained")
local raised=node("RaisedList","ScrollingFrame");raised.ZIndex=120;raised.Parent=gui
for _,name in ipairs({"Bat","Bear","Dog","Grey Cat"})do
 local tile,cleanup=PetClient.createMaterialTile("layer-"..name,name,1,raised,function()end)
 eq(tile.Main.Icon.Image,icons[name].Texture)
 eq(tile.Main.ZIndex,122);eq(tile.Main.Icon.ZIndex,123)
 PetClient.setMaterialSelection(tile,name,true,false)
 eq(tile.Main.Icon.Image,icons[name].Texture,"selection never clears image")
 eq(tile.Main.Icon.Visible,true)
 cleanup();eq(tile.destroyed,true)
end
local limitedTile=buildTile("limited-inventory","Pet_081",1)
janitor:Destroy();eq(cleanedViews,boundViews,"existing bound-Viewport cleanup preserved")
result.shop:Destroy()
eq(cleanedViews,boundViews,"destroy releases remaining Viewports")
eq(shellClones,1)
eq(eggViews,eggCleanups,"all Egg Viewports cleaned")
print("MERGE_PET_SELECTION_OFFLINE_PASS",checks)

print("MERGE_SHOP_PRESENTATION_OFFLINE_PASS",checks)
"""
fixture=fixture.replace('-- INSERT SETUP',setup).replace('-- INSERT MATERIAL BUILDERS',builders)
fixture=fixture.replace('-- INSERT EGG FIXTURE',egg_fixture.replace('-- SOURCE JSON',json.dumps(egg_source)))
result=subprocess.run([sys.argv[1]],input="assert(loadstring("+json.dumps(fixture)+"))()\n",text=True,capture_output=True)
print(result.stdout)
if result.returncode or 'MERGE_PET_SELECTION_OFFLINE_PASS' not in result.stdout:
 print(result.stderr,file=sys.stderr)
 raise SystemExit(1)
