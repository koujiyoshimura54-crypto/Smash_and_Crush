from pathlib import Path
import subprocess,sys,json
root=Path(__file__).resolve().parents[1]
source=(root/'src/StarterGui/StrengthUI/MergePanel_New/MergePanelClient_New.client.luau').read_text(encoding='utf-8')
setup=source[source.index('local gui=player:'):source.index('local template=script.Parent:')]
fixture="""
local checks=0
local function eq(a,b,msg) checks+=1;assert(a==b,(msg or "")..": "..tostring(a).." ~= "..tostring(b))end
local clones=0
local function event()
 local x={callbacks={}}
 function x:Connect(f)table.insert(self.callbacks,f);return {Disconnect=function()end}end
 function x:fire(...)for _,f in self.callbacks do f(...)end end
 return x
end
local methods={}
local mt={__index=function(x,k)return methods[k]end}
local function node(name,class,children)
 local n=setmetatable({Name=name,ClassName=class or "Frame",children={},attrs={},Activated=event(),Visible=false,Text=""},mt)
 for _,child in ipairs(children or {})do n.children[#n.children+1]=child;n[child.Name]=child;child.Parent=n end
 return n
end
function methods:IsA(c)return self.ClassName==c or c=="GuiObject" and (self.ClassName=="Frame" or self.ClassName=="ScrollingFrame" or self.ClassName=="TextButton")end
function methods:WaitForChild(k)return assert(self[k],"missing "..k)end
function methods:FindFirstChild(k)return self[k]end
function methods:GetChildren()return table.clone(self.children)end
function methods:GetDescendants()
 local out={} local function add(x)for _,child in x.children do table.insert(out,child);add(child)end end add(self);return out
end
function methods:Destroy()self.destroyed=true end
function methods:SetAttribute(k,v)self.attrs[k]=v end
function methods:GetAttribute(k)return self.attrs[k]end
function methods:GetPropertyChangedSignal(k)
 self.events=self.events or {};self.events[k]=self.events[k] or event();return self.events[k]
end
function methods:Clone()
 clones+=1;local kids={}for _,child in self.children do table.insert(kids,child:Clone())end
 local n=node(self.Name,self.ClassName,kids);n.Visible=self.Visible;n.Text=self.Text
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
function player:WaitForChild()return {WaitForChild=function()return gui end}end
function player:GetAttribute()return self.world or 1 end
local pos={X=30,Y=0,Z=0}
player.Character.FindFirstChild=function()return {Position=pos}end
local origin=0;local cylinder=false
local area={Shape=2,Size=setmetatable({X=20,Y=20,Z=20},{__div=function(v,n)return {X=v.X/n,Y=v.Y/n,Z=v.Z/n}end}),CFrame={PointToObjectSpace=function(_,p)return {X=p.X-origin,Y=p.Y,Z=p.Z}end},IsA=function(_,c)return c=="BasePart" or (c=="Part" and cylinder)end}
local workspace={FindFirstChild=function()return {FindFirstChild=function()return area end}end}
local beat=event()
local game={GetService=function()return {Heartbeat=beat}end}
local RS={Modules={ResponsivePanels="Responsive"}}
local require=function()return {Fit=function()end}end
local Instance={new=function(c)return node("",c)end}
local Enum={AutomaticSize={None=0},PartType={Cylinder=2}}
local UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end}
local Vector2={new=function(...)return {...}end}
local function mount()
-- INSERT SETUP
 return {shop=shop,page=page,tabs=tabButtons}
end
local result=mount()
eq(result.shop.Name,"MergeShopPanel")
eq(result.shop.Top.ShopText1.Text,"Merge")
eq(result.shop.Top.ShopText2.Text,"Merge")
eq(result.tabs.Item.PriceTag.Text,"Item")
eq(result.tabs.Pet.PriceTag.Text,"Pet")
eq(#beat.callbacks,1,"single proximity connection")
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
eq(clones,count,"reentry no clones")
origin=100;beat:fire(.1);eq(result.shop.Visible,false,"moved model trigger follows")
pos.X=100;beat:fire(.1);eq(result.shop.Visible,true)
player.world=2;beat:fire(.1);eq(result.shop.Visible,false,"World2 excluded")
player.world=1;beat:fire(.1);eq(result.shop.Visible,true)
inv.Visible=true;inv:GetPropertyChangedSignal("Visible"):fire()
eq(result.shop.Visible,false,"Inventory hides Shop")
eq(clones,count)
cylinder=true;pos.Y=9;pos.Z=9;beat:fire(.1);eq(result.shop.Visible,false,"cylinder corner is outside")
pos.Z=0;beat:fire(.1);eq(result.shop.Visible,true)
pos.X=111;beat:fire(.1);eq(result.shop.Visible,false)
print("MERGE_SHOP_PRESENTATION_OFFLINE_PASS",checks)
"""
fixture=fixture.replace('-- INSERT SETUP',setup)
result=subprocess.run([sys.argv[1]],input="assert(loadstring("+json.dumps(fixture)+"))()\n",text=True,capture_output=True)
print(result.stdout)
if result.returncode or 'MERGE_SHOP_PRESENTATION_OFFLINE_PASS' not in result.stdout:
 print(result.stderr,file=sys.stderr)
 raise SystemExit(1)
