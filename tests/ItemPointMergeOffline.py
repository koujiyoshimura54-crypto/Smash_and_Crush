"""Actual merge/config/transaction Source with memory-only storage fault adapters."""
from pathlib import Path
import json, subprocess
root=Path(__file__).resolve().parents[1]
def source(p): return (root/"src"/p).read_text(encoding="utf8")
pds=source("ServerScriptService/Services/PlayerDataService.luau")
resolve=pds[pds.index("function PlayerDataService.ResolveItemMutation"):pds.index("-- Private validation and snapshot")]
batch=pds[pds.index("function PlayerDataService.ChangeItemCounts"):pds.index("-- The shared receipt journal")]
normalizer=pds[pds.index("local function normalizeItemMerge"):pds.index("local function defaults()")]
pre=r"""
local builtinTypeof=typeof
local function typeof(v) return type(v)=="table" and v.__instance and "Instance" or builtinTypeof(v) end
local function require(v)return v end
local function warn(_)end
local function signal()
 local s={handlers={}}
 function s:Connect(fn)table.insert(self.handlers,fn);return {Disconnect=function()end}end
 function s:Fire(...)for _,fn in ipairs(self.handlers)do fn(...)end end
 return s
end
local Players={PlayerRemoving=signal()}
local guid=0
local Http={GenerateGUID=function()guid+=1;return string.format("00000000-0000-0000-0000-%012x",guid)end}
local draws={.1,.1,.1};local cursor=0
local Random={new=function()return {NextNumber=function()cursor+=1;return draws[(cursor-1)%#draws+1]end}end}
local fakeClock=100
local os={clock=function()return fakeClock end}
local function node(t)t=t or {};function t:WaitForChild(k)return assert(self[k],k)end;function t:FindFirstChild(k)return self[k]end;return t end
local cfg,modules,services=node(),node(),node()
local RS=node({Config=cfg,Modules=modules,Remotes=node()})
local game={ReplicatedStorage=RS,ServerScriptService=node({Services=services}),
 GetService=function(_,n)return ({Players=Players,ReplicatedStorage=RS,HttpService=Http})[n]end}
cfg.DeveloperProductConfig={GetItemProduct=function(r)if r=="Epic" then return {ProductId=3711755218,FallbackPrice=25}elseif r=="Legendary" then return {ProductId=3711755280,FallbackPrice=50}end end}
"""
fixture=pre+"\nlocal Master=(function()\n"+source("ReplicatedStorage/Config/ItemMaster.luau")+"\nend)();cfg.ItemMaster=Master\n"
fixture+="local Config=(function()\n"+source("ReplicatedStorage/Config/ItemMergeConfig.luau")+"\nend)();cfg.ItemMergeConfig=Config\n"
fixture+=r"""
local function copy(t)if type(t)~="table" then return t end;local c={}for k,v in pairs(t)do c[k]=copy(v)end;return c end
local sessions,stored,storedMeta={},nil,{}
local mode,calls,retries,badges="ok",0,0,0
local reentry
local MAX_COUNT=9007199254740991
local function finite(v)return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function resetToken(raw)return raw and raw.ResetToken end
local function normalizeItems(raw)return copy(raw or {})end
local function defaults()return {OwnedItems={},EquippedItems={},ItemMergeJournal={Sequence=0}}end
local function metadata(info)return {},copy(info:GetMetadata())end
local function info(meta)return {GetMetadata=function()return copy(meta)end}end
local function ownedUpdate(player,s,transform)
 calls+=1
 if reentry then local fn=reentry;reentry=nil;fn() end
 if mode=="before" then error("write unavailable")end
 if mode=="reset" then local old=copy(stored);old.ResetToken="other";return transform(old,info(storedMeta))end
 local next,_,meta=transform(copy(stored),info(storedMeta))
 if not next then return nil end
 if mode=="callback" then next,_,meta=transform(copy(stored),info(storedMeta))end
 stored=copy(next);storedMeta=copy(meta)
 if mode=="lost" then error("ack lost after commit")end
 return copy(stored),info(storedMeta)
end
local function scheduleItemMutationRetry()retries+=1;return 1,retries end
local PlayerDataService={}
function PlayerDataService.Get(p)return sessions[p]end
function PlayerDataService.IsLoaded(p)return sessions[p] and sessions[p].Loaded end
function PlayerDataService.IsSaving(p)return sessions[p] and sessions[p].Saving end
function PlayerDataService.SetWin(p,n)sessions[p].Data.Win=n;p:SetAttribute("Win",n);return true end
services.PlayerDataService=PlayerDataService
"""
fixture+=normalizer+"\n"+resolve+"\n"+batch+"\n"
fixture+=r"""
cfg.ItemMultiplierConfig={};modules.ElementSetBonus={}
services.BadgeAwardService={Award=function()badges+=1 end}
"""
fixture+="local Items=(function()\n"+source("ServerScriptService/Services/ItemService.luau")+"\nend)();services.ItemService=Items\n"
fixture+="local Merge=(function()\n"+source("ServerScriptService/Services/ItemMergeService.luau")+"\nend)();services.ItemMergeService=Merge\n"
fixture+="local Price=(function()\n"+source("ReplicatedStorage/Modules/NumberFormat.luau")+"\nend)()\n"
fixture+=r"""
local function player(owned,win,equipped)
 local p={__instance=true,Parent=Players,Name="Mock",UserId=0,attributes={Win=win or 10000}}
 function p:IsA(k)return k=="Player"end
 function p:GetAttribute(k)return self.attributes[k]end
 function p:SetAttribute(k,v)self.attributes[k]=v end
 sessions[p]={Loaded=true,Data={Win=p.attributes.Win,OwnedItems=copy(owned),EquippedItems=copy(equipped or {}),ResetToken="generation",ItemMergeJournal={Sequence=0}}}
 stored=copy(sessions[p].Data);storedMeta={};mode="ok";calls=0;retries=0;cursor=0
 return p,sessions[p]
end
local function request(p,materials)
 local state=Merge.GetState(p)
 return {RequestId=Http:GenerateGUID(false),SessionToken=state.SessionToken,Sequence=state.NextSequence,Materials=materials}
end
local count=0
local function check(name,fn)fn();count+=1;print("PASS "..name)end
local function close(a,b)assert(math.abs(a-b)<1e-10,tostring(a).." ~= "..tostring(b))end
check("rarity interpolation and exact thresholds",function()
 for _,test in ipairs({{2,.5,.5},{9,1},{18,.5,.5},{27,1},{54,.5,.5},{81,1},{200,1}})do
  local odds=Config.RarityOdds(test[1]);for i=2,#test do close(odds[i-1].Probability,test[i])end
  local sum=0;for _,r in ipairs(odds)do sum+=r.Probability end;close(sum,1)
 end
 assert(Config.RarityOdds(81)[1].Rarity=="Legendary")
end)
check("independent mixed type/element sampling; absent categories excluded",function()
 local p=assert(Config.Evaluate({GLOVE_COMMON_FIRE=1,PROTEIN_COMMON_ICE=1}))
 assert(#p.Outcomes==8);local sum=0;for _,o in ipairs(p.Outcomes)do sum+=o.Probability;close(o.Probability,.125)end;close(sum,1)
 local values={.8,.8,.8};local i=0
 assert(Config.Sample(p,function()i+=1;return values[i]end)=="GLOVE_UNCOMMON_ICE");assert(i==3)
 local mono=assert(Config.Evaluate({GLOVE_RARE_FIRE=2}))
 for _,o in ipairs(mono.Outcomes)do local item=Master.Get(o.ItemId);assert(item.ItemType=="Glove" and item.Element=="Fire")end
 local max=assert(Config.Evaluate({GLOVE_LEGENDARY_FIRE=1,PROTEIN_COMMON_ICE=1}));assert(max.Rarities[1].Rarity=="Legendary")
end)
check("minimum, numeric/ownership validation, no arbitrary unit limit",function()
 assert(not Config.Evaluate({GLOVE_COMMON_FIRE=1}))
 for _,v in ipairs({0,-1,.5,math.huge,0/0})do assert(not Config.Evaluate({GLOVE_COMMON_FIRE=v}))end
 assert(not Config.Evaluate({GLOVE_COMMON_FIRE=2},{GLOVE_COMMON_FIRE=1}))
 assert(not Config.Evaluate({GLOVE_LEGENDARY_FIRE=Config.MaxInteger}))
 assert(Config.Evaluate({GLOVE_COMMON_FIRE=100000}))
end)
check("atomic consume/grant, equipment coherence, duplicate/old sequence",function()
 local p,s=player({GLOVE_COMMON_FIRE=3},10000,{Glove="GLOVE_COMMON_FIRE"})
 local r=request(p,{GLOVE_COMMON_FIRE=3})
 local ok,code,id=Merge.MergeItem(p,r);assert(ok and code=="Merged" and stored.OwnedItems[id]==1)
 assert(s.Data.ItemMergeJournal.Sequence==1 and s.Data.OwnedItems.GLOVE_COMMON_FIRE==nil and s.Data.EquippedItems.Glove=="")
 local before=copy(stored);local writes=calls
 assert(Merge.MergeItem(p,r));assert(calls==writes and stored.ItemMergeJournal.Sequence==1)
 local old=request(p,{[id]=2});old.Sequence=1;assert(not Merge.MergeItem(p,old))
end)
check("failed save retains materials/result; lost acknowledgement retry grants once",function()
 local p,s=player({PROTEIN_COMMON_FIRE=2});local r=request(p,{PROTEIN_COMMON_FIRE=2})
 mode="before";local ok,code=Merge.MergeItem(p,r);assert(not ok and code=="InventorySavePending")
 assert(stored.OwnedItems.PROTEIN_COMMON_FIRE==2 and s.Data.OwnedItems.PROTEIN_COMMON_FIRE==2)
 local op=s.PendingItemMutation;local id=op.ItemMerge.ResultItemId
 assert(not Merge.MergeItem(p,r));assert(s.PendingItemMutation==op)
 mode="lost";assert(not PlayerDataService.ResolveItemMutation(p));assert(stored.OwnedItems[id]==1)
 assert(s.Data.OwnedItems.PROTEIN_COMMON_FIRE==2)
 mode="callback";assert(PlayerDataService.ResolveItemMutation(p));assert(stored.OwnedItems[id]==1)
 assert(Merge.MergeItem(p,r));assert(Merge.GetState(p).LastResult.Success)
 assert(stored.ItemMergeJournal.RequestId==r.RequestId)
 -- Another item transaction changes ItemMutationId; old merge still cannot replay.
 mode="ok";assert(PlayerDataService.ChangeItemCount(p,"GLOVE_COMMON_ICE",1))
 local writes=calls;assert(Merge.MergeItem(p,r));assert(calls==writes)
end)
check("parallel/new requests, forged replay and expired session rejected",function()
 local p,s=player({GLOVE_COMMON_FIRE=5})
 local r=request(p,{GLOVE_COMMON_FIRE=2});mode="before";assert(not Merge.MergeItem(p,r))
 local second=request(p,{GLOVE_COMMON_FIRE=2});assert(not Merge.MergeItem(p,second))
 local forged=copy(r);forged.Materials.GLOVE_COMMON_FIRE=3;assert(not Merge.MergeItem(p,forged))
 mode="ok";assert(PlayerDataService.ResolveItemMutation(p));assert(Merge.MergeItem(p,r))
 Players.PlayerRemoving:Fire(p);assert(not Merge.MergeItem(p,r))
end)
check("reset-generation barrier refuses stale merge",function()
 local p,s=player({GLOVE_COMMON_FIRE=2})
 local r=request(p,{GLOVE_COMMON_FIRE=2});mode="reset"
 assert(not Merge.MergeItem(p,r));assert(stored.OwnedItems.GLOVE_COMMON_FIRE==2)
end)
check("reentrant concurrent request uses one operation and one draw result",function()
 local p,s=player({GLOVE_COMMON_FIRE=5})
 local r=request(p,{GLOVE_COMMON_FIRE=2});local second=request(p,{GLOVE_COMMON_FIRE=2})
 reentry=function()
  local ok,code=Merge.MergeItem(p,r);assert(not ok and code=="InventorySavePending")
  ok,code=Merge.MergeItem(p,second);assert(not ok and code=="DataSaving")
 end
 assert(Merge.MergeItem(p,r));assert(calls==1 and cursor==3 and stored.ItemMergeJournal.Sequence==1)
 local journal=assert(normalizeItemMerge(stored.ItemMergeJournal));assert(journal.RequestId==r.RequestId)
end)
check("Epic 4500 Win through existing atomic Item purchase; other offers retained",function()
 local p,s=player({})
 assert(Master.Get("PROTEIN_EPIC_FIRE").WinPrice==4500)
 assert(Items.PurchaseItemWithWin(p,"PROTEIN_EPIC_FIRE"))
 assert(stored.Win==5500 and s.Data.Win==5500 and stored.OwnedItems.PROTEIN_EPIC_FIRE==1)
 assert(Master.Get("PROTEIN_EPIC_FIRE").RobuxPrice==25)
 assert(not Master.Get("PROTEIN_LEGENDARY_FIRE").ShopPurchasable)
 p,s=player({},4499);assert(not Items.PurchaseItemWithWin(p,"PROTEIN_EPIC_FIRE"));assert(calls==0)
end)
check("price-only formatter; original count/Strength formatter retained",function()
 for _,t in ipairs({{149,"149"},{1000,"1K"},{4500,"4.5K"},{7500,"7.5K"},{1000000,"1M"},{1250000,"1.25M"}})do assert(Price.Price(t[1])==t[2])end
 assert(Price.PriceText("4,500 Win")=="4.5K Win")
 assert(Price.PriceText("OWNED")=="OWNED" and Price.PriceText("4.5K")=="4.5K")
 assert(Price.Plain(4500)=="4500")
end)
print("ITEM_POINT_MERGE_PASS "..count)
"""
result=subprocess.run([r"C:\Users\kouji\stage_skip_work\luau\luau.exe"],input="assert(loadstring("+json.dumps(fixture)+"))()\n",text=True,encoding="utf8",capture_output=True)
print(result.stdout);print(result.stderr)
assert "ITEM_POINT_MERGE_PASS 10" in result.stdout and "stack backtrace" not in result.stderr
