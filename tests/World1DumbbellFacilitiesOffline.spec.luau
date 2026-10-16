local checks=0
local function eq(a,b,msg)checks+=1;assert(a==b,(msg or "")..": "..tostring(a).." ~= "..tostring(b))end
local function signal()
 local s={handlers={}}
 function s:Connect(fn)table.insert(self.handlers,fn);return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in self.handlers do fn(...)end end
 return s
end
local function node(class,name)
 local n={ClassName=class,Name=name,children={},DescendantAdded=signal(),ChildAdded=signal(),Parent=true}
 function n:IsA(k)return k==self.ClassName or k=="BasePart" and self.ClassName=="Part"end
 function n:FindFirstChild(k)return self.children[k]end
 function n:WaitForChild(k)return assert(self.children[k],k)end
 function n:GetChildren()local out={};for _,v in self.children do table.insert(out,v)end;return out end
 return n
end
-- SOURCE Master
-- SOURCE Config
-- SOURCE Format
-- SOURCE Client
-- SOURCE Float
-- GEOMETRY
local signals={};local Player={Parent=true,attrs={EquippedDumbbell=""}}
function Player:GetAttribute(k)return self.attrs[k]end
function Player:GetAttributeChangedSignal(k)signals[k]=signals[k] or signal();return signals[k]end
function Player:SetAttribute(k,v)self.attrs[k]=v;self:GetAttributeChangedSignal(k):Fire()end
local RS=node("ReplicatedStorage","ReplicatedStorage");RS.Config=node("Folder","Config");RS.Modules={}
local remotes=node("Folder","Remotes");RS.children.Remotes=remotes
local purchase,equip={OnClientEvent=signal()},{OnClientEvent=signal()}
remotes.children.DumbbellPurchaseRequest=purchase;remotes.children.DumbbellEquipRequest=equip
local state={Loaded=false};local invokes=0
remotes.children.DumbbellInventoryState={InvokeServer=function()invokes+=1;return state end}
local tasks={};local task={spawn=function(fn)table.insert(tasks,fn)end,wait=function()
 state={Loaded=true,OwnedDumbbells={NORMAL_01=true},EquippedDumbbell=""}
end}
local workspace=node("Workspace","Workspace")
local pads=node("Folder","PerStepButtons");workspace.children.PerStepButtons=pads
local shoes=node("Folder","ShoesModels");workspace.children.ShoesModels=shoes
local RunService={Heartbeat=signal()}
local win="rbxassetid://125143776516842"
local game={GetService=function(_,k)return assert(({Players={LocalPlayer=Player},ReplicatedStorage=RS,RunService=RunService,
 StarterGui={StrengthGui={HUD={WinAmount={Inside={Icon={Image=win}}}}}}})[k],k)end}
local V={};local vmt={__div=function(v,n)return V.new(v.X/n,v.Y/n,v.Z/n)end,
 __mul=function(v,n)return V.new(v.X*n,v.Y*n,v.Z*n)end,__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end}
function V.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},vmt)end;V.yAxis=V.new(0,1,0)
local function load(s)
 local fn=assert(loadstring(s));setfenv(fn,setmetatable({game=game,workspace=workspace,require=function(v)return v end,task=task,
 Vector3=V,Color3={fromRGB=function(r,g,b)return r..","..g..","..b end}},{__index=getfenv()}));return fn()
end
local Master=load(sourceMaster);RS.Config.children.DumbbellItemMaster=Master;RS.Config.DumbbellItemMaster=Master
local Config=load(sourceConfig);RS.Config.children.DumbbellStandConfig=Config;RS.Config.DumbbellStandConfig=Config
local Format=load(sourceFormat);RS.Modules.NumberFormat=Format;RS.Modules.Config={Float={seconds=4,studs=2}}
for i,g in geometry do
 local model=node("Model",tostring(i));pads.children[model.Name]=model
 local press=node("Part","Press");model.children.Press=press;press.Size=V.new(unpack(g.size));press.Color="original"..i
 local p=g.position
 -- Saved rotation14: local X is world Z; local Z is negative world X.
 press.CFrame={PointToObjectSpace=function(_,v)return V.new(v.Z-p[3],v.Y-p[2],-(v.X-p[1]))end}
 local board=node("BillboardGui","BillboardGui");model.children.BillboardGui=board;board.StudsOffset=V.new(0,10,0)
 local amount=node("Frame","Amount");board.children.Amount=amount
 for _,name in {"Main","MainShadow"}do amount.children[name]=node("TextLabel",name)end
 amount.children.Icon=node("ImageLabel","Icon")
 for _,name in {"Price","PriceShadow","Status"}do board.children[name]=node("TextLabel",name)end
 board.children.ItemIcon=node("ImageLabel","ItemIcon")
 local display=node("Model",tostring(i));display.children.Bar=node("Part","Bar");shoes.children[tostring(i)]=display
 function display:GetPivot()return V.new(unpack(p))end
 function display:PivotTo()error("Authored Dumbbell exhibit moved: "..i)end
end
-- Actual Config against all saved Press positions and near-edge interior samples.
for i,g in geometry do
 local p=g.position
 for _,x in {-0.49,0,0.49}do for _,z in {-0.49,0,0.49}do
  eq(Config.GetStandingIndex(pads,V.new(p[1]+x*g.size[3],p[2]+3,p[3]+z*g.size[1])),i,"saved oriented pad")
 end end
 eq(Config.GetStandingIndex(pads,V.new(p[1],p[2]+20,p[3])),nil)
end
local Client=load(sourceClient);Client.start();Client.start()
eq(#purchase.OnClientEvent.handlers,1);eq(#equip.OnClientEvent.handlers,1);eq(#tasks,1)
eq(pads.children["1"].children.BillboardGui.children.Status.Text,"")
tasks[1]();eq(invokes,2);eq(pads.children["1"].children.BillboardGui.children.Status.Text,"Owned")
for i,item in Master.GetSorted()do
 local board=pads.children[tostring(i)].children.BillboardGui
 eq(board.children.ItemIcon.Image,item.Image);eq(board.children.Amount.children.Main.Text,Format.Price(item.PriceWin))
 eq(board.children.Amount.children.MainShadow.Text,Format.Price(item.PriceWin));eq(board.children.Amount.children.Icon.Image,win)
 eq(board.children.Price.Text,"+"..item.StrengthBonus.." Strength");eq(board.children.PriceShadow.Text,board.children.Price.Text)
 state={Loaded=true,OwnedDumbbells={[item.ItemId]=true},EquippedDumbbell=item.ItemId}
 purchase.OnClientEvent:Fire({Success=true,State=state})
 eq(board.children.Status.Text,"Equipped");eq(pads.children[tostring(i)].children.Press.Color,"0,200,0")
 for j=1,12 do if i~=j then eq(pads.children[tostring(j)].children.BillboardGui.children.Status.Text,"Step to buy")end end
 -- Unequip via authoritative acknowledgement, before attribute replication.
 state.EquippedDumbbell="";equip.OnClientEvent:Fire({Success=true,State=state})
 eq(board.children.Status.Text,"Owned");eq(pads.children[tostring(i)].children.Press.Color,"original"..i)
 Player:SetAttribute("EquippedDumbbell",item.ItemId);eq(board.children.Status.Text,"Equipped")
 Player:SetAttribute("EquippedDumbbell","");eq(board.children.Status.Text,"Owned")
 pads.DescendantAdded:Fire();eq(board.children.Status.Text,"Owned")
end
-- Recreated client after rejoin reads owned state; no ownership migration or request.
state={Loaded=true,OwnedDumbbells={NORMAL_12=true},EquippedDumbbell="NORMAL_12"}
local Rejoined=load(sourceClient);Rejoined.start();tasks[2]();eq(pads.children["12"].children.BillboardGui.children.Status.Text,"Equipped")
-- Execute the real floating update: all twelve exhibits stay at authored transforms;
-- unrelated old shoe behavior and board animation remain active.
local other=node("Model","13");local moved=0;function other:GetPivot()return V.new(0,0,0)end
function other:PivotTo()moved+=1 end;shoes.children["13"]=other
local Float=load(sourceFloat);Float.start();RunService.Heartbeat:Fire(.5)
eq(moved,1);eq(pads.children["12"].children.BillboardGui.StudsOffset.Y>10,true)
print("WORLD1_DUMBBELL_FACILITIES_PASS",checks,"saved geometry, actual client state and float Source; simulation only")
