"""Execute actual Press geometry, entry gate, Controller and DumbbellService.

Memory-only Luau adapters; no Roblox process, real purchases or DataStore access.
"""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]

def source(path):
    return (root / "src" / path).read_text(encoding="utf-8")

config = source("ReplicatedStorage/Config/DumbbellStandConfig.luau")
master = source("ReplicatedStorage/Config/DumbbellItemMaster.luau")
gate = source("ServerScriptService/Services/DumbbellStandService.luau")
service = source("ServerScriptService/Services/DumbbellService.luau")
controller = source("ServerScriptService/Systems/Controllers/DumbbellController.server.luau")

fixture = r'''
local realTypeof=typeof
local function typeof(v) return type(v)=="table" and v.__instance and "Instance" or realTypeof(v) end
local clock=100
local os={clock=function()return clock end}
local function require(v)return v end
local function signal()
 local s={handlers={}}
 function s:Connect(fn)table.insert(self.handlers,fn);return {Disconnect=function()end} end
 function s:Fire(...)for _,fn in ipairs(self.handlers)do fn(...)end end
 return s
end
local V={}
local vmt={__div=function(a,b)return V.new(a.X/b,a.Y/b,a.Z/b)end}
function V.new(x,y,z)return setmetatable({X=x,Y=y,Z=z},vmt)end
local CFrame={}
local cmt={}
function CFrame.new(x,y,z)return setmetatable({X=x,Y=y,Z=z,A=0},cmt)end
function CFrame.Angles(_,y,_)local c=CFrame.new(0,0,0);c.A=y;return c end
function cmt.__mul(a,b)local c=CFrame.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z);c.A=a.A+b.A;return c end
function cmt.__index(c,k)
 if k=="PointToObjectSpace" then return function(_,p)
  local x,z=p.X-c.X,p.Z-c.Z
  return V.new(math.cos(c.A)*x-math.sin(c.A)*z,p.Y-c.Y,math.sin(c.A)*x+math.cos(c.A)*z)
 end end
end
local function node(class)
 local n={__instance=true,ClassName=class,children={}}
 function n:IsA(k)return k==class or (k=="BasePart" and class=="Part")end
 function n:FindFirstChild(k)return self.children[k]end
 function n:WaitForChild(k)return assert(self.children[k],k)end
 return n
end
local Players={players={},PlayerRemoving=signal()}
function Players:GetPlayers()return self.players end
local RunService={Heartbeat=signal()}
local RS=node("ReplicatedStorage");RS.Config=node("Folder");RS.Remotes=node("Folder")
local services=node("Folder");local SSS={Services=services}
local workspace=node("Workspace")
local game={ServerScriptService=SSS}
function game:GetService(k)return assert(({Players=Players,RunService=RunService,ReplicatedStorage=RS})[k],k)end
local Master=(function()
''' + master + r'''
end)()
local Config=(function()
''' + config + r'''
end)()
RS.Config.children.DumbbellStandConfig=Config;RS.Config.children.DumbbellItemMaster=Master
local sessions,charges,saveCalls={},0,0
local Data={}
function Data.Get(p)return sessions[p]end
function Data.SetWin(p,w)
 local s=sessions[p];if not s or not s.Loaded then return false end
 if w<s.Data.Win then charges+=1 end
 s.Data.Win=w;p.attrs.Win=w;s.Dirty=true;return true
end
function Data.SetEquippedDumbbell(p,id)
 local s=sessions[p];if not s or not s.Loaded then return false,"DataNotLoaded" end
 if s.Saving then return false,"DataSaving" end
 if id~="" and s.Data.OwnedDumbbells[id]~=true then return false,"NotOwned" end
 s.Data.EquippedDumbbell=id;p.attrs.EquippedDumbbell=id;s.Dirty=true;return true,"Equipped"
end
services.children.PlayerDataService=Data
services.children.TrainingLobbyAreaService={IsInTrainingLobby=function(p)return p.InLobby and p.Character and p.Character.Humanoid.Health>0 end}
local script={Parent=services}
local Gate=(function()
''' + gate + r'''
end)()
services.children.DumbbellStandService=Gate
local Service=(function()
''' + service + r'''
end)()
services.children.DumbbellService=Service
local function remote()
 local r={OnServerEvent=signal(),responses={}}
 function r:FireClient(p,value)table.insert(self.responses,value);self.last=value end
 return r
end
local purchase,equip=remote(),remote()
local inventory={}
RS.Remotes.children.DumbbellPurchaseRequest=purchase
RS.Remotes.children.DumbbellEquipRequest=equip
RS.Remotes.children.DumbbellInventoryState=inventory
local function loadController()
''' + controller + r'''
end
loadController()
local pads=node("Folder");workspace.children.PerStepButtons=pads
for i=1,12 do
 local model=node("Model");local press=node("Part")
 press.CFrame=CFrame.new(i*20,4,0);press.Size=V.new(7,1.4,7.3)
 model.children.Press=press;pads.children[tostring(i)]=model
end
local function player(win)
 local p=node("Player");p.Parent=Players;p.InLobby=true;p.attrs={Win=win,CurrentWorld=1}
 function p:GetAttribute(k)return self.attrs[k]end
 local character=node("Model");local hum={Health=100};character.Humanoid=hum
 function character:FindFirstChildOfClass(k)return k=="Humanoid" and hum end
 local rootPart=node("Part");rootPart.Position=V.new(-50,8,0);character.children.HumanoidRootPart=rootPart
 p.Character=character
 sessions[p]={Loaded=true,Data={Win=win,OwnedDumbbells={},EquippedDumbbell=""}}
 table.insert(Players.players,p);return p,sessions[p],rootPart
end
local seq=0
local function request(p,index,isEquip,id)
 seq+=1;clock+=.3
 local ctx={Source="DumbbellStand",StandIndex=index,RequestId="request-"..seq}
 local r=isEquip and equip or purchase;r.OnServerEvent:Fire(p,id or Config.GetItemId(index),ctx)
 return r.last
end
local function off(rootPart)rootPart.Position=V.new(-50,8,0);RunService.Heartbeat:Fire(.11)end
local function on(rootPart,i)local c=pads.children[tostring(i)].children.Press.CFrame;rootPart.Position=V.new(c.X,c.Y+3,c.Z);RunService.Heartbeat:Fire(.11)end
local count=0
local function check(name,fn)fn();count+=1;print("PASS "..name)end
check("seven mappings; held 8-12; moved/rotated current Press geometry",function()
 for i=1,7 do assert(Config.GetItemId(i)==string.format("NORMAL_%02d",i))end
 for _,i in ipairs({0,8,12,1.5,math.huge})do assert(Config.GetItemId(i)==nil)end
 local press=pads.children["1"].children.Press
 assert(Config.IsInside(press,V.new(20,7,0)))
 assert(not Config.IsInside(press,V.new(24,7,0)))
 assert(not Config.IsInside(press,V.new(20,11,0)))
 press.CFrame=CFrame.new(450,4,120)*CFrame.Angles(0,math.pi/2,0)
 assert(Config.IsInside(press,V.new(450,7,123)))
 assert(not Config.IsInside(press,V.new(450,7,124)))
 press.CFrame=CFrame.new(20,4,0)
end)
check("unowned purchase/debit and automatic equip; continuous occupancy rejected",function()
 local p,s,rootPart=player(100);on(rootPart,1);local before=charges
 local result=request(p,1,false)
 assert(result.Success and result.Source=="DumbbellStand" and result.RequestId)
 assert(s.Data.Win==95 and s.Data.OwnedDumbbells.NORMAL_01 and s.Data.EquippedDumbbell=="NORMAL_01" and charges==before+1)
 for _=1,3 do local r=request(p,1,false);assert(not r.Success and r.Code=="StandReentryRequired")end
 assert(s.Data.Win==95 and charges==before+1)
 off(rootPart);on(rootPart,1);local r=request(p,1,false)
 assert(r.Success and r.Code=="AlreadyEquipped" and charges==before+1)
end)
check("owned equip without charge; Inventory remains available outside pad",function()
 local p,s,rootPart=player(100);s.Data.OwnedDumbbells.NORMAL_02=true
 on(rootPart,2);local before=charges;assert(request(p,2,true).Success)
 assert(s.Data.EquippedDumbbell=="NORMAL_02" and s.Data.Win==100 and charges==before)
 off(rootPart);clock+=.3;purchase.OnServerEvent:Fire(p,"NORMAL_03")
 assert(purchase.last.Success and purchase.last.Source==nil and s.Data.Win==70 and s.Data.EquippedDumbbell=="NORMAL_03")
 local st=inventory.OnServerInvoke(p);assert(st.OwnedDumbbells.NORMAL_03 and st.EquippedDumbbell=="NORMAL_03" and st.Win==70)
end)
check("insufficient Win, save/load gates; no automatic retry until reentry",function()
 local p,s,rootPart=player(0);on(rootPart,1);local before=charges
 assert(request(p,1,false).Code=="NotEnoughWin")
 s.Data.Win=20;p.attrs.Win=20
 assert(request(p,1,false).Code=="StandReentryRequired")
 off(rootPart);on(rootPart,1);s.Saving=true
 assert(request(p,1,false).Code=="DataSaving")
 off(rootPart);on(rootPart,1);s.Saving=false;s.PendingItemMutation={}
 assert(request(p,1,false).Code=="InventorySavePending")
 off(rootPart);on(rootPart,1);s.PendingItemMutation=nil;s.Loaded=false
 assert(request(p,1,false).Code=="DataNotLoaded" and charges==before)
end)
check("server refuses wrong mapping, range, world, dead and held pads",function()
 local p,s,rootPart=player(1000);on(rootPart,1);local before=charges
 assert(request(p,1,false,"NORMAL_07").Code=="InvalidStand")
 assert(request(p,2,false).Code=="StandOutOfRange")
 p.attrs.CurrentWorld=2;assert(request(p,1,false).Code=="WrongWorld")
 p.attrs.CurrentWorld=1;p.Character.Humanoid.Health=0;assert(request(p,1,false).Code=="StandOutOfRange")
 p.Character.Humanoid.Health=100;on(rootPart,8);assert(request(p,8,false,"NORMAL_01").Code=="InvalidStand")
 assert(s.Data.Win==1000 and charges==before)
end)
check("stale client ownership resolves on server; request replay across Remotes",function()
 local p,s,rootPart=player(100);s.Data.OwnedDumbbells.NORMAL_04=true;on(rootPart,4)
 local before=charges;assert(request(p,4,false).Success)
 assert(s.Data.EquippedDumbbell=="NORMAL_04" and s.Data.Win==100 and charges==before)
 assert(request(p,4,true).Code=="StandReentryRequired")
 local originalPurchase=Service.PurchaseDumbbell
 local reentrantCode
 Service.PurchaseDumbbell=function(player,id)
  equip.OnServerEvent:Fire(player,"NORMAL_02")
  reentrantCode=equip.last.Code
  return originalPurchase(player,id)
 end
 local q,qs,qr=player(100);on(qr,1);before=charges
 assert(request(q,1,false).Success)
 Service.PurchaseDumbbell=originalPurchase
 assert(reentrantCode=="PurchaseInProgress" and charges==before+1 and qs.Data.Win==95)
end)
check("client entry latch records pending entrances, exit and character reset",function()
 local state={};local char={};local sent=0
 local pending=false
 local function tick(index)local entered=Config.AdvanceEntry(state,char,index);if entered and not pending then sent+=1 end end
 tick(1);tick(1);tick(1);assert(sent==1)
 pending=true;tick(2);pending=false;tick(2);assert(sent==1)
 tick(nil);tick(2);assert(sent==2)
 char={};tick(2);assert(sent==3)
end)
assert(saveCalls==0)
print("DUMBBELL_STAND_PASS "..count)
'''

exe = Path(r"C:\Users\kouji\stage_skip_work\luau\luau.exe")
result = subprocess.run([str(exe)], input="assert(loadstring(" + json.dumps(fixture) + "))()\n",
                        text=True, encoding="utf-8", capture_output=True)
print(result.stdout)
print(result.stderr)
assert "DUMBBELL_STAND_PASS 7" in result.stdout and "stack backtrace" not in result.stderr
