local checks=0
local function eq(a,b,msg) checks+=1;assert(a==b,(msg or "")..": "..tostring(a).." ~= "..tostring(b))end
local function near(a,b)checks+=1;assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b))end
local function signal()
 local s={handlers={}};function s:Connect(f)table.insert(self.handlers,f);return {Disconnect=function()end}end
 function s:Fire(...)for _,f in self.handlers do f(...)end end;return s
end
local nativeTypeof=typeof
local function typeof(v)return type(v)=="table" and v.fakePlayer and "Instance" or nativeTypeof(v)end
-- SOURCE Master
-- SOURCE Stand
-- SOURCE Service
-- SOURCE Monitor
-- SOURCE Controller
-- SOURCE Strength
-- SOURCE Format
local modules={};local services={};local RS={Config={},Modules={},Remotes={}}
function RS.Config:WaitForChild(k)return self[k]end
function services:WaitForChild(k)return self[k]end
function RS.Remotes:WaitForChild(k)return self[k]end
local Players={players={},PlayerRemoving=signal()};function Players:GetPlayers()return self.players end
local RunService={Heartbeat=signal()}
local game={ReplicatedStorage=RS,ServerScriptService={Services=services}}
function game:GetService(k)return assert(({Players=Players,ReplicatedStorage=RS,RunService=RunService})[k],k)end
local script={Parent=services};local workspace={}
local function require(k)return assert(modules[k],tostring(k))end
local function load(s)
 local f=assert(loadstring(s));setfenv(f,setmetatable({game=game,require=require,script=script,workspace=workspace,typeof=typeof},{__index=getfenv()}));return f()
end
local Master=load(sourceMaster);modules.Master=Master;RS.Config.DumbbellItemMaster="Master"
local DumbbellItemMaster=Master
local Config=load(sourceStand);modules.Stand=Config;RS.Config.DumbbellStandConfig="Stand"
local sessions,PlayerDataService={},{};modules.Data=PlayerDataService;services.PlayerDataService="Data"
function PlayerDataService.Get(p)return sessions[p]end
local debits=0
function PlayerDataService.SetWin(p,w)local s=sessions[p];if not s or not s.Loaded then return false end;s.Data.Win=w;p:SetAttribute("Win",w);debits+=1;return true end
function PlayerDataService.GetLevelState()return 1,0 end
function PlayerDataService.AddStrengthGain(p,g)local v=(p:GetAttribute("Strength") or 0)+g;p:SetAttribute("Strength",v);return v end
-- PERSISTENCE
local Service=load(sourceService);modules.Service=Service;services.DumbbellService="Service"
local NumberFormat=load(sourceFormat);modules.Format=NumberFormat;RS.Modules.NumberFormat="Format"
local prices={5,15,40,100,200,400,750,1250,2000,3500,6000,10000}
local bonuses={3,5,9,15,25,45,75,120,180,280,450,700}
local images={131314372434925,126019719977317,96428309215438,77317637436768,134662273184560,92138447886967,79967244610623,11017141876908,129522181601539,92929093922544,89748292939648,121194224737958}
eq(#Master.GetSorted(),12)
local function player(win)
 local p={fakePlayer=true,Parent=Players,Name="Fixture",attrs={Win=win,Strength=0,CurrentWorld=1,RebirthCount=1}}
 function p:IsA(k)return k=="Player"end;function p:GetAttribute(k)return self.attrs[k]end
 function p:SetAttribute(k,v)self.attrs[k]=v end
 sessions[p]={Loaded=true,Data={Win=win,OwnedDumbbells={},EquippedDumbbell=""}};table.insert(Players.players,p)
 return p,sessions[p]
end
for i,item in Master.GetSorted()do
 local id=string.format("NORMAL_%02d",i)
 eq(item.ItemId,id);eq(item.Grade,i);eq(item.PriceWin,prices[i]);eq(item.StrengthBonus,bonuses[i]);eq(item.Image,"rbxassetid://"..images[i]);eq(Config.GetItemId(i),id)
 local p,s=player(prices[i]);local before=debits
 eq(Service.PurchaseDumbbell(p,id),true);eq(p:GetAttribute("Win"),0);eq(s.Data.OwnedDumbbells[id],true);eq(debits,before+1)
 eq(Service.PurchaseDumbbell(p,id),false);eq(p:GetAttribute("Win"),0);eq(debits,before+1)
 eq(Service.EquipDumbbell(p,id),true);eq(Service.GetStrengthBonus(p),bonuses[i])
 p:SetAttribute("EquippedDumbbell","NORMAL_01");eq(Service.GetEquippedDumbbell(p),id)
 local data=assert(reload(s.Data));sessions[p].Data=data;eq(data.EquippedDumbbell,id);eq(data.OwnedDumbbells[id],true)
 eq(Service.GetStrengthBonus(p),bonuses[i]);eq(Service.UnequipDumbbell(p),true);eq(Service.GetStrengthBonus(p),0)
 p,s=player(prices[i]-1);before=debits
 eq(Service.PurchaseDumbbell(p,id),false);eq(debits,before);eq(p:GetAttribute("Win"),prices[i]-1);eq(next(s.Data.OwnedDumbbells),nil)
end
for _,i in {0,13,1.5,math.huge,1e30}do eq(Config.GetItemId(i),nil)end
local legacy,ls=player(0)
for i=1,7 do ls.Data.OwnedDumbbells[string.format("NORMAL_%02d",i)]=true end
ls.Data.EquippedDumbbell="NORMAL_07";ls.Data.OwnedDumbbells.FUTURE_UNKNOWN=true
ls.Data=assert(reload(ls.Data));eq(Service.GetEquippedDumbbell(legacy),"NORMAL_07")
eq(ls.Data.OwnedDumbbells.FUTURE_UNKNOWN,true);local before=debits
for i=1,7 do eq(Service.EquipDumbbell(legacy,string.format("NORMAL_%02d",i)),true)end;eq(debits,before)

-- Execute the real monitor/controller with simulated oriented Press geometry.
local pads={};local function folder(children)return {FindFirstChild=function(_,k)return children[k]end}end
for i=1,12 do
 local press={Size={X=8,Y=2,Z=8},CFrame={PointToObjectSpace=function(_,p)return {X=p.X-i*20,Y=p.Y,Z=p.Z}end}}
 setmetatable(press.Size,{__div=function(v,n)return {X=v.X/n,Y=v.Y/n,Z=v.Z/n}end})
 function press:IsA(k)return k=="BasePart"end
 local m=folder({Press=press});function m:IsA(k)return k=="Model"end;pads[tostring(i)]=m
end
function workspace:FindFirstChild(k)return k=="PerStepButtons" and folder(pads)end
local Monitor=load(sourceMonitor);modules.Monitor=Monitor;services.DumbbellStandService="Monitor"
local function remote()return {OnServerEvent=signal(),FireClient=function(self,_,r)self.result=r end}end
local purchase,equip=remote(),remote();local stateRemote={}
RS.Remotes.DumbbellPurchaseRequest=purchase;RS.Remotes.DumbbellEquipRequest=equip;RS.Remotes.DumbbellInventoryState=stateRemote
load(sourceController)
local p,s=player(50000);s.Data.OwnedDumbbells.NORMAL_01=true
local root={Position={X=-50,Y=0,Z=0},IsA=function()return true end};local hum={Health=100}
p.Character={FindFirstChildOfClass=function()return hum end,FindFirstChild=function()return root end}
for i=1,12 do
 root.Position={X=-50,Y=0,Z=0};RunService.Heartbeat:Fire(.11)
 before=debits;local oldWin=p:GetAttribute("Win")
 root.Position={X=i*20,Y=3,Z=0};RunService.Heartbeat:Fire(.11)
 eq(s.Data.EquippedDumbbell,string.format("NORMAL_%02d",i));eq(p:GetAttribute("Win"),oldWin-(i==1 and 0 or prices[i]))
 local paid=debits;RunService.Heartbeat:Fire(.11);eq(debits,paid)
end
eq(stateRemote.OnServerInvoke(p).OwnedDumbbells.NORMAL_12,true)
p:SetAttribute("CurrentWorld",2);root.Position={X=20,Y=3,Z=0};RunService.Heartbeat:Fire(.11);eq(s.Data.EquippedDumbbell,"NORMAL_12")
-- The actual Strength formula is unchanged: Dumbbell only in Training; Pet stays last.
services.ItemService="Item";modules.Item={GetProteinBonus=function()return 2 end,GetElementSetMultiplier=function()return 1.5 end}
services.AuraService="Aura";modules.Aura={GetStrengthBonus=function()return 3 end}
services.PotionService="Potion";modules.Potion={GetStrengthMultiplier=function()return 1.5 end}
services.GamePassService="Pass";modules.Pass={GetVIPStrengthMultiplier=function()return 1.25 end}
services.PetServer="PetServer";local petFactor=2.3;modules.PetServer={GetStrengthMultiplier=function()return petFactor end}
RS.Config.LevelRequirements="Level";modules.Level={};RS.Config.RebirthMultiplierConfig="Rebirth";modules.Rebirth={GetMultiplier=function()return 2 end}
RS.Remotes.StrengthGain={FireClient=function()end}
local Strength=load(sourceStrength)
for i=1,12 do
 s.Data.EquippedDumbbell=string.format("NORMAL_%02d",i)
 p:SetAttribute("Strength",0);near(Strength.AddStrength(p,1,1,4),(1+bonuses[i]+3+2)*2*4*1.5*1.25*1.5*2.3)
 p:SetAttribute("Strength",0);near(Strength.AddStrength(p,1,1),(1+3+2)*2*1.5*1.25*1.5*2.3)
 p:SetAttribute("Strength",0);near(Strength.AddRewardStrength(p,100),100)
end

-- Actual UI builders/layout/state functions against synthetic Instances.
-- UI NODES
local function rgb(...)return {...}end;local Color3={fromRGB=rgb,new=rgb}
local function ud(x,o)return {Scale=x or 0,Offset=o or 0}end
local UDim={new=ud}
UDim2.new=function(x,xo,y,yo)return {X=ud(x,xo),Y=ud(y,yo)}end
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end
UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
Vector2.new=function(x,y)return {X=x,Y=y}end
Enum.Font={GothamBold=1};Enum.ApplyStrokeMode={Border=1};Enum.ScaleType={Fit=1};Enum.TextXAlignment={Left=0}
local find=methods.FindFirstChild
function methods:FindFirstChild(k,deep)
 local n=find(self,k);if n or not deep then return n end
 for _,c in self.children do local d=c:FindFirstChild(k,true);if d then return d end end
end
local gui={WinLabel={TrophyIcon={Image="native-win"}}}
local cards,owned,pending={},{},{};local equipped=""
local shell={Size=UDim2.fromOffset(1130,812),ResponsiveScale={Scale=1}}
local grid={};local list=node("Items","ScrollingFrame");list.AbsoluteSize={X=740,Y=500}
local panel={Equipped={Preview={},ItemName={},Multiplier={}},WinLabel={},Owned={}}
local PurchaseHUD={PurchaseButton=function(button,_,text)button.rendered=text end}
local Presentation={SetSelected=function()end,SetButtonEnabled=function(b,v)b.Active=v end}
local Responsive={ConnectActivation=function(b,f)b.Activated:Connect(f)end}
local equipRemote={FireServer=function(_,id)eq(id,"NORMAL_08")end}
local purchaseRemote={FireServer=function(_,id)eq(id,"NORMAL_12")end}
local function selectCard()end
-- INVENTORY HELPERS
-- INVENTORY STATE
-- INVENTORY BUILD
-- INVENTORY LAYOUT
eq(#list:GetChildren(),12)
for i,item in Master.GetSorted()do
 local c=cards[item.ItemId];eq(c.LayoutOrder,i);eq(c.Icon.Image,item.Image);eq(c.Multiplier.Text,"+"..bonuses[i].." Strength");eq(c.BuyButton.Price.Text,NumberFormat.Price(prices[i]))
end
applyState({Loaded=true,OwnedDumbbells={NORMAL_08=true},EquippedDumbbell="NORMAL_08"})
eq(cards.NORMAL_08.BuyButton.Text,"EQUIPPED");eq(cards.NORMAL_08.BuyButton.Active,false)
eq(panel.Equipped.Preview.Image,Master.Get("NORMAL_08").Image)
applyState({Loaded=true,OwnedDumbbells={NORMAL_08=true},EquippedDumbbell=""})
eq(cards.NORMAL_08.BuyButton.Text,"EQUIP");cards.NORMAL_08.BuyButton.Activated:fire();table.clear(pending)
cards.NORMAL_12.BuyButton.Activated:fire();table.clear(pending)
for _,view in {{740,1,3},{460,.7,2},{460,.52,1}}do
 list.AbsoluteSize.X=view[1]*view[2];shell.ResponsiveScale.Scale=view[2];layout()
 eq(grid.FillDirectionMaxCells,view[3]);eq(list.Active,true);eq(list.ScrollingEnabled,true)
 local c=cards.NORMAL_12;local iconBottom=c.Icon.Position.Y.Offset+c.Icon.Size.Y.Offset
 local effectBottom=c.Multiplier.Position.Y.Offset+c.Multiplier.Size.Y.Offset
 local buttonTop=grid.CellSize.Y.Offset+c.BuyButton.Position.Y.Offset
 checks+=1;assert(iconBottom<c.Multiplier.Position.Y.Offset and effectBottom<buttonTop)
 checks+=1;assert(c.BuyButton.Size.Y.Offset*view[2]>=40-1e-8)
 local total=math.ceil(12/view[3])*(grid.CellSize.Y.Offset+14)-14
 checks+=1;assert(total>500/view[2],"list must scroll instead of shrinking all cards")
end
local holder=node("Holder","Frame",{node("UIListLayout","UIListLayout")})
holder.AbsoluteSize={X=900,Y=600};holder.UIListLayout.Padding=ud(0,10);holder.UIListLayout.AbsoluteContentSize={Y=2000}
for i=1,5 do
 local c=node("Authored"..i,"Frame",{node("Icon","ImageLabel"),node("Title","TextLabel"),node("PurchaseArea","Frame",{node("Purchase","TextButton",{node("PriceTag","TextLabel")})})})
 c.LayoutOrder=29+i;c:SetAttribute("PurchaseKind","Dumbbell");c:SetAttribute("PurchaseKey",string.format("NORMAL_%02d",i));c.Parent=holder
end
local DumbbellMaster=Master;local responsiveScale={Scale=1,GetPropertyChangedSignal=function()return event()end}
local shop={MainScrollingFrame={}};local task={defer=function(f)f()end}
-- SHOP BUILD
local count=0
for _,c in holder:GetChildren()do if c:GetAttribute("PurchaseKind")=="Dumbbell" then
 count+=1;local item=Master.Get(c:GetAttribute("PurchaseKey"));eq(c.LayoutOrder,29+item.Grade);eq(c.Icon.Image,item.Image);eq(c.Title.Text,"+"..item.StrengthBonus.." Strength");eq(c.PurchaseArea.Purchase.PriceTag.Text,NumberFormat.Price(item.PriceWin))
end end;eq(count,12)
local dumbbellState;local pending=false
-- SHOP STATE
renderDumbbellState({Loaded=true,OwnedDumbbells={NORMAL_08=true,NORMAL_12=true},EquippedDumbbell="NORMAL_12"})
local function shopCard(id)for _,c in holder:GetChildren()do if c:GetAttribute("PurchaseKey")==id then return c end end end
eq(shopCard("NORMAL_08").PurchaseArea.Purchase.PriceTag.Text,"EQUIP")
eq(shopCard("NORMAL_12").PurchaseArea.Purchase.PriceTag.Text,"EQUIPPED")
eq(shopCard("NORMAL_12").PurchaseArea.Purchase.Interactable,false)
for _,view in {{900,1,2},{650,.52,1}}do
 holder.AbsoluteSize.X=view[1]*view[2];responsiveScale.Scale=view[2];layoutDumbbellShop()
 near(shopCard("NORMAL_12").Size.X.Offset,(view[1]-24-(view[3]-1)*10)/view[3])
 eq(shop.MainScrollingFrame.CanvasSize.Y.Offset,2016);eq(holder.UIListLayout.VerticalAlignment,Enum.VerticalAlignment.Top)
end
print("WORLD1_DUMBBELL_TWELVE_PASS",checks,"catalogue, actual purchase/equip/stand control flow, save normalization, formula and simulated UI")
