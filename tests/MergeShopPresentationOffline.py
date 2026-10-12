from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1]
client=(root/'src/StarterPlayer/StarterPlayerScripts/Services/PetClient.luau').read_text(encoding='utf-8')
builders=client[client.index('local function buildTile('):client.index('function PetClient.setShown(')]
fixture=r"""

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

-- The reference-layout controller is exercised against real Instances in MergeShopReferenceEdit.luau.
-- Keep this isolated regression specifically for the unchanged purchased PetClient builders.
local raised=node("Raised","ScrollingFrame");raised.ZIndex=220;raised.Parent=gui
for _,name in ipairs({"Bat","Bear","Dog","Grey Cat"}) do
 local selected=0
 local tile,cleanup=PetClient.createMaterialTile("one",name,1,raised,function()selected+=1 end)
 eq(tile.Main.Icon.Image,icons[name].Texture)
 eq(tile.Main.Icon.ZIndex,223);eq(tile.Main.ZIndex,222)
 eq(tile.Main.Icon.Visible,true);eq(tile.Main.Icon.ImageTransparency,0)
 tile.Button.Activated:fire();eq(selected,1);eq(equipRequests,0)
 PetClient.setMaterialSelection(tile,name,true,false)
 eq(tile.Main.Checkmark.Visible,true);eq(tile.Main.Icon.Image,icons[name].Texture)
 PetClient.setMaterialSelection(tile,name,false,false);eq(tile.Main.Checkmark.Visible,false)
 local second,cleanupSecond=PetClient.createMaterialTile("two",name,2,raised,function()end)
 eq(second.Main.Icon.Image,tile.Main.Icon.Image);eq(second.Name,"two")
 cleanup();eq(tile.destroyed,true);eq(second.destroyed,nil)
 cleanupSecond();eq(second.destroyed,true)
end
eq(itemTemplate.Main.Icon.ZIndex,2);eq(itemTemplate.Main.ZIndex,4)
local inv=buildTile("inventory","Grey Cat",1)
eq(inv.Main.Icon.ZIndex,2);eq(inv.Main.Icon.Image,icons["Grey Cat"].Texture)
inv.Button.Activated:fire();eq(equipRequests,1)
local limited=buildTile("paid","Pet_081",2)
janitor:Destroy();eq(boundViews,cleanedViews)
print("MERGE_PURCHASED_TILE_OFFLINE_PASS",checks)
"""

fixture=fixture.replace('-- INSERT MATERIAL BUILDERS',builders)
result=subprocess.run([sys.argv[1]],input="assert(loadstring("+json.dumps(fixture)+"))()\n",text=True,capture_output=True)
print(result.stdout)
if result.returncode or 'MERGE_PURCHASED_TILE_OFFLINE_PASS' not in result.stdout:
 print(result.stderr,file=sys.stderr)
 raise SystemExit(1)
