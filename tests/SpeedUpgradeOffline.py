"""Run actual scoped Speed transaction functions against memory-only failures.

No Roblox process, network, DataStore or rbxl writes. Production module functions
are extracted, not reimplemented; ownership/update scheduling are test doubles.
"""
from pathlib import Path
import json
import subprocess

root = Path(__file__).resolve().parents[1]
source = (root / "src/ServerScriptService/Services/PlayerDataService.luau").read_text(encoding="utf-8")
config = (root / "src/ReplicatedStorage/Config/SpeedConfig.luau").read_text(encoding="utf-8")
speed = (root / "src/ServerScriptService/Services/SpeedService.luau").read_text(encoding="utf-8")

def section(text, start, end):
    return text[text.index(start):text.index(end, text.index(start))]

fixture = """
local SpeedConfig=(function()
""" + config + """
end)()
local Config=SpeedConfig
local sessions,PlayerDataService={},{}
local stored,failBefore,failAfter,during,requests,premium,repeatCallback
local guid=0
local Pass={HasPremiumSpeed=function()return premium==true end,AreEffectsEnabled=function()return true end}
local game={ServerScriptService={Services={GamePassService=Pass}}}
local function require(x)return x end
local HttpService={GenerateGUID=function()guid+=1;return tostring(guid) end}
local function finite(v)return typeof(v)=="number" and v==v and math.abs(v)~=math.huge end
local function resetToken(d)return d.ResetToken end
local function metadata()return {1},{Keep="unchanged"} end
local function scheduleItemMutationRetry(_,_,op)op.RetryScheduled=true end
local function ownedUpdate(player,s,transform)
 requests+=1
 if s.OwnershipLost then return nil end
 if failBefore then failBefore=false;error("injected pre-commit failure") end
 local nextData=transform(stored,{})
 if repeatCallback then nextData=transform(stored,{}) end
 if nextData then stored=table.clone(nextData) end
 if during then local f=during;during=nil;f() end
 if failAfter then failAfter=false;error("injected lost acknowledgement") end
 return nextData and table.clone(stored)
end
""" + section(source, "function PlayerDataService.SetWin(", "function PlayerDataService.RecordStrengthGain(") + section(source, "local function resolveSpeedPurchase(", "local function resolveCapacityPurchase(") + """
function PlayerDataService.ResolveItemMutation(player)
 local s=sessions[player]
 return resolveSpeedPurchase(player,s,s.PendingItemMutation)
end
""" + section(source, "function PlayerDataService.PurchaseSpeed(", "-- Server-only entry point.") + """
local Data={Get=function(p)return sessions[p] end}
local M={}
""" + section(speed, "function M.GetState(", "-- Equipment/source identity") + """
local boosts={}
local function activeBoost()return nil end
local TRANSITION_BOOST_MULTIPLIER=2
""" + section(speed, "function M.Apply(", "function M.ClearTransitionBoost(") + """
local function fixture(win,stage,legacy,ownedPremium)
 premium=ownedPremium;requests=0;failBefore=false;failAfter=false;during=nil;repeatCallback=false
 stored={Win=win,SpeedUpgradeStage=stage,OwnedSpeeds=legacy and {Speed1=true} or {},
  ResetToken="fixture",InventoryCapacity=5,Keep="untouched"}
 local attrs={}
 local hum={WalkSpeed=0}
 local p={Character={FindFirstChildOfClass=function()return hum end}}
 function p:GetAttribute(k)return attrs[k] end
 function p:SetAttribute(k,v)attrs[k]=v end
 sessions[p]={Loaded=true,Data=table.clone(stored)}
 sessions[p].Data.SpeedUpgradeStage=assert(SpeedConfig.NormalizeStage(stage,stored.OwnedSpeeds))
 attrs.Win=win
 return p,sessions[p],hum
end
local count=0
local function check(name,f)f();count+=1;print("PASS "..name) end
check("four sequential tiers / total 1000 / reload and respawn apply / cap",function()
 local p,s,hum=fixture(1000,nil)
 assert(M.Apply(p).WalkSpeed==24 and hum.WalkSpeed==24)
 for stage=0,3 do
  assert(PlayerDataService.PurchaseSpeed(p,"Upgrade",stage))
  assert(s.Data.SpeedUpgradeStage==stage+1)
  assert(stored.SpeedUpgradeStage==stage+1)
  s.Data=table.clone(stored)
  s.Data.SpeedUpgradeStage=assert(SpeedConfig.NormalizeStage(stored.SpeedUpgradeStage,stored.OwnedSpeeds))
  M.Apply(p);assert(hum.WalkSpeed==28+stage*4)
 end
 assert(stored.Win==0 and stored.Keep=="untouched" and stored.InventoryCapacity==5)
 local ok,code=PlayerDataService.PurchaseSpeed(p,"Upgrade",4)
 assert(not ok and code=="MaxSpeed")
end)
check("insufficient / future stage / retired 600 route / invalid requests",function()
 local p,s=fixture(99,0)
 local ok,code=PlayerDataService.PurchaseSpeed(p,"Upgrade",0)
 assert(not ok and code=="NotEnoughWin" and requests==0)
 for _,args in {{"Upgrade",2},{"Speed1",0},{"Upgrade",0/0},{"Upgrade",.5}} do
  assert(not PlayerDataService.PurchaseSpeed(p,args[1],args[2]))
 end
 assert(requests==0 and s.Data.Win==99)
end)
check("duplicate and reentrant requests never skip / callback replay",function()
 local p,s=fixture(1000,0);repeatCallback=true
 during=function()
  assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
  assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",1))
 end
 assert(PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 for _=1,5 do assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0)) end
 assert(stored.Win==900 and stored.SpeedUpgradeStage==1 and s.Data.Win==900)
end)
check("pre-commit failure reserves balance and retries same operation",function()
 local p,s=fixture(150,0);failBefore=true
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 assert(stored.Win==150 and s.Data.Win==150 and s.Data.SpeedUpgradeStage==0)
 local id=s.PendingItemMutation.Id
 assert(not PlayerDataService.SetWin(p,100))
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",1))
 assert(PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 assert(stored.SpeedUpgradePurchaseId==id and stored.Win==50 and s.Data.Win==50)
end)
check("lost response does not double charge; earned Win survives; pending resolves after Premium",function()
 local p,s=fixture(150,0);failAfter=true
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 assert(stored.Win==50 and stored.SpeedUpgradeStage==1 and s.Data.Win==150)
 assert(PlayerDataService.SetWin(p,175));premium=true
 assert(PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 assert(s.Data.Win==75 and stored.Win==50 and s.Data.SpeedUpgradeStage==1)
end)
check("session/reset barriers reject stale pending operation",function()
 local p,s=fixture(150,0);failBefore=true
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0))
 stored.ResetToken="new"
 assert(not PlayerDataService.ResolveItemMutation(p))
 assert(s.PendingItemMutation==nil and stored.Win==150)
 p,s=fixture(150,0);s.OwnershipLost=true
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",0) and requests==0)
end)
check("legacy Boost completes upgrades; Premium max not addition; no debit",function()
 local p,s,hum=fixture(1000,nil,true)
 assert(s.Data.SpeedUpgradeStage==4 and M.Apply(p).WalkSpeed==40)
 assert(not PlayerDataService.PurchaseSpeed(p,"Upgrade",4))
 p,s,hum=fixture(1000,2,false,true)
 assert(M.Apply(p).WalkSpeed==50 and hum.WalkSpeed==50)
 local ok,code=PlayerDataService.PurchaseSpeed(p,"Upgrade",2)
 assert(not ok and code=="PremiumOwned" and requests==0 and stored.Win==1000)
 assert(SpeedConfig.NormalizeStage(5)==nil)
end)
print("SPEED_UPGRADE_PASS "..count)
"""
exe = Path(r"C:\Users\kouji\stage_skip_work\luau\luau.exe")
result = subprocess.run([str(exe)], input="assert(loadstring("+json.dumps(fixture)+"))()\n",
                        text=True, encoding="utf-8", capture_output=True)
print(result.stdout)
print(result.stderr)
assert "SPEED_UPGRADE_PASS 7" in result.stdout and "stack backtrace" not in result.stderr
