-- Phase 7.4.1: isolated production-source tests; no Robux or live stores used.
local T={}
function T.Run()
 local folder=Instance.new("Folder"); folder.Name="Phase741Sandbox"; folder.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=folder; return m end
 local function replace(s,a,b) local i,j=s:find(a,1,true); assert(i,"Missing seam: "..a); return s:sub(1,i-1)..b..s:sub(j+1) end
 local ok,err=pcall(function()
  local runtime=module("Runtime",[==[
local R={Stores={},Metadata={},UserIds={},Prompts={},PlayersList={},Sequence=0,StageApplications=0}
local H=game:GetService("HttpService")
function R.Copy(v) if v==nil then return nil end return H:JSONDecode(H:JSONEncode(v)) end
function R.Signal()
 local s={Listeners={}}
 function s:Connect(fn) table.insert(self.Listeners,fn) end
 function s:Fire(...) for _,fn in ipairs(self.Listeners) do fn(...) end end
 return s
end
R.Players={PlayerRemoving=R.Signal()}
function R.Players:GetPlayerByUserId(id) return R.PlayersList[id] end
R.Marketplace={PromptProductPurchaseFinished=R.Signal()}
function R.Marketplace:PromptProductPurchase(player,product)
 if R.PromptFailure then error("simulated prompt failure") end
 local intent=R.Stores.ItemPurchaseIntents_v1["Player_"..player.UserId]
 assert(intent and intent.ItemId and intent.ExpectedProductId==product,"Prompt before durable intent")
 table.insert(R.Prompts,{Player=player,ProductId=product,ItemId=intent.ItemId})
end
R.RunService={IsStudio=function() return false end}
R.Http={GenerateGUID=function() R.Sequence+=1; return "guid-"..R.Sequence end}
R.DSS={}
function R.DSS:GetDataStore(name)
 R.Stores[name]=R.Stores[name] or {}
 R.Metadata[name]=R.Metadata[name] or {}
 R.UserIds[name]=R.UserIds[name] or {}
 local records=R.Stores[name]
 local function info(key)
  return {GetMetadata=function() return R.Copy(R.Metadata[name][key] or {}) end,
   GetUserIds=function() return R.Copy(R.UserIds[name][key] or {}) end}
 end
 return {
  GetAsync=function(_,key) return R.Copy(records[key]),info(key) end,
  UpdateAsync=function(_,key,fn)
   if R.BeforeUpdate then R.BeforeUpdate(name,key) end
   if R.FailRead==name then error("simulated read failure") end
   fn(R.Copy(records[key]),info(key)) -- retry the callback against unchanged input
   local nextValue,users,meta=fn(R.Copy(records[key]),info(key))
   if R.FailWrite and R.FailWrite(name,key,nextValue) then error("simulated write failure") end
   if nextValue==nil then return nil end -- match the engine's cancelled-update contract
   records[key]=R.Copy(nextValue)
   R.Metadata[name][key]=R.Copy(meta or {})
   R.UserIds[name][key]=R.Copy(users or {})
   if R.FailAfterWrite and R.FailAfterWrite(name,key,nextValue) then error("simulated lost acknowledgement") end
   return R.Copy(records[key]),info(key)
  end,
 }
end
function R.DSS:GetOrderedDataStore() return {SetAsync=function() end} end
return R
]==])
  local R=require(runtime)
  local shim='local realTypeof=typeof\nlocal function typeof(v) if type(v)=="table" and v.TestPlayer then return "Instance" end return realTypeof(v) end\n'
  local function dependencies(source)
   for service,field in pairs({Players="Players",MarketplaceService="Marketplace",RunService="RunService",HttpService="Http",DataStoreService="DSS"}) do
    local before='game:GetService("'..service..'")'
    if source:find(before,1,true) then source=replace(source,before,'require(script.Parent.Runtime).'..field) end
   end
   return shim..source
  end
  module("PlayerDataService",dependencies(game.ServerScriptService.Services.PlayerDataService.Source))
  module("ItemService",dependencies(game.ServerScriptService.Services.ItemService.Source))
  module("ItemPurchaseService",dependencies(game.ServerScriptService.Systems.Purchases.ItemPurchaseService.Source))
  module("StageSkipService",[==[
local R=require(script.Parent.Runtime)
local S={}
local locks={}
function S.TryLock(p) if locks[p] then return false end locks[p]=true return true end
function S.Unlock(p) locks[p]=nil end
function S.GetStartCFrame(p,stage) return p.Ready~=false and CFrame.new() or nil end
function S.ApplyLocked(p,stage)
 if p.Ready==false then return false end
 R.StageApplications+=1; p.LastStage=stage; return true
end
function S.NotifyReceipt(p,stage) p.NotifiedStage=stage end
return S
]==])
  local receiptSource=dependencies(game.ServerScriptService.Systems.Purchases.ReceiptService.Source)
  module("ReceiptService",receiptSource)
  local Data=require(folder.PlayerDataService)
  local Items=require(folder.ItemService)
  local Purchases=require(folder.ItemPurchaseService)
  local Receipts=require(folder.ReceiptService)
  local Master=require(game.ReplicatedStorage.Config.ItemMaster)
  local granted=Enum.ProductPurchaseDecision.PurchaseGranted
  local pending=Enum.ProductPurchaseDecision.NotProcessedYet
  local nextUser=734000
  local function player(raw)
   nextUser+=1
   local p={TestPlayer=true,UserId=nextUser,Name="Test734",Parent=R.Players,Attributes={}}
   function p:IsA(name) return name=="Player" end
   function p:GetAttribute(name) return self.Attributes[name] end
   function p:SetAttribute(name,value) self.Attributes[name]=value end
   R.PlayersList[p.UserId]=p
   if raw then R.Stores.PlayerData_v1=R.Stores.PlayerData_v1 or {}; R.Stores.PlayerData_v1["Player_"..p.UserId]=R.Copy(raw) end
   assert(Data.Load(p))
   return p
  end
  local function receipt(p,product,suffix) return {PlayerId=p.UserId,ProductId=product,PurchaseId=tostring(p.UserId).."-"..suffix} end
  local function check(name,fn) fn(); table.insert(results,"PASS "..name) end
  local function assertOwned(p,id)
   assert((Data.Get(p).Data.OwnedItems[id] or 0)>=1,id)
   assert((R.Stores.PlayerData_v1["Player_"..p.UserId].OwnedItems[id] or 0)>=1,"not persisted")
  end

  R.Roll=0;R.Index=1;R.Rolls=0;R.Picks=0;R.Jobs={}
  R.Random={new=function() return {
   NextNumber=function() R.Rolls+=1;return R.Roll end,
   NextInteger=function(_,a,b) assert(a==1 and b==9);R.Picks+=1;return R.Index end
  } end}
  R.Task={spawn=function(fn) table.insert(R.Jobs,fn) end,wait=function() if R.OnWait then R.OnWait() end end}
  local dropSource=dependencies(game.ServerStorage.Legacy.Modules.BossItemDropService.Source)
  dropSource=replace(dropSource,"local rng=Random.new()","local rng=require(script.Parent.Runtime).Random.new()")
  dropSource=replace(dropSource,"local M={}","local M={}\nlocal task=require(script.Parent.Runtime).Task")
  R.FlashCount=0;R.BossCF=CFrame.new(10,20,30)
  R.FlashRemote={FireAllClients=function(_,cf) assert(cf==R.BossCF);R.FlashCount+=1 end}
  dropSource=replace(dropSource,'game.ReplicatedStorage.Remotes:WaitForChild("BossDropFlash")','require(script.Parent.Runtime).FlashRemote')
  dropSource=replace(dropSource,'local M={}',[[local M={}
local workspace={FindFirstChild=function(_,name)
 assert(name=="Enemies")
 return {FindFirstChild=function() return {FindFirstChild=function() return {CFrame=require(script.Parent.Runtime).BossCF} end} end}
end}
]])
  local Drops=require(module("BossItemDropService",dropSource))
  local function run(major) return {Defeated={[major]=true}} end
  local function flush() local jobs=R.Jobs;R.Jobs={};for _,job in ipairs(jobs) do job() end end
  check("Normal .1-.4 across all 10 stages: no random draw and no item",function()
   local p=player();local before=R.Rolls
   for major=1,10 do for sub=1,4 do assert(not Drops.OnBossDefeated(p,major,sub,run(major))) end end
   assert(R.Rolls==before and #R.Jobs==0 and next(Items.GetOwnedItems(p))==nil)
  end)
  check("All 10 Boss stages draw once per run; duplicate defeat cannot select or grant twice",function()
   local p=player();R.Roll=0;local before=R.Rolls
   for major=1,10 do local victory=run(major)
    assert(Drops.OnBossDefeated(p,major,5,victory))
    assert(not Drops.OnBossDefeated(p,major,5,victory))
   end
   flush();assert(R.Rolls==before+10 and Items.GetItemCount(p,"PROTEIN_COMMON_FIRE")==10)
  end)
  check("30% boundary: 0 and .299999 succeed; .30 and .999999 select nothing",function()
   local p=player()
   for _,value in ipairs({0,0.299999,0.30,0.999999}) do
    R.Roll=value;local before=R.Picks
    local ok,code=Drops.OnBossDefeated(p,1,5,run(1))
    assert(ok and (code=="DropSelected")==(value<.3))
    assert(R.Picks-before==(value<.3 and 1 or 0))
   end
   flush()
  end)
  check("Deterministic 1000-point probability grid selects exactly 300 drops",function()
   local p=player();local before=R.Picks
   for i=0,999 do R.Roll=(i+.5)/1000;assert(Drops.OnBossDefeated(p,1,5,run(1))) end
   assert(R.Picks-before==300)
   R.Jobs={} -- probability-only test; no production inventory touched
  end)
  check("All 9 uniform integer outcomes are existing Common definitions; new and owned count +1",function()
   R.Roll=0;local seen={}
   local p=player({Win=61})
   for i=1,9 do R.Index=i
    local ok,_,id=Drops.OnBossDefeated(p,1,5,run(1));assert(ok)
    local item=Master.Get(id);assert(item and item.Rarity=="Common" and not seen[id]);seen[id]=true
    flush();assert(Items.GetItemCount(p,id)==1)
    assert(Drops.OnBossDefeated(p,1,5,run(1)));flush();assert(Items.GetItemCount(p,id)==2)
   end
   assert(Data.Save(p));Data.Release(p);assert(Data.Load(p))
   for id in pairs(seen) do assert(Items.GetItemCount(p,id)==2) end
   assert(Data.Get(p).Data.Win==61)
  end)
  check("Busy save retains selection; accepted failed write retries without another roll/add",function()
   R.Roll=0;R.Index=1
   local p=player();Data.Get(p).Saving=true
   local before=R.Rolls
   assert(Drops.OnBossDefeated(p,1,5,run(1)))
   R.OnWait=function() Data.Get(p).Saving=false end
   flush();R.OnWait=nil
   assert(Items.GetItemCount(p,"PROTEIN_COMMON_FIRE")==1 and R.Rolls==before+1)
   local q=player()
   R.FailAfterWrite=function(name) return name=="PlayerData_v1" end
   assert(Drops.OnBossDefeated(q,1,5,run(1)));flush()
   R.FailAfterWrite=nil;assert(Data.Save(q))
   assert(Items.GetItemCount(q,"PROTEIN_COMMON_FIRE")==1)
  end)
  check("Unconfirmed victory, skipped state, invalid stage and wrong owner cannot drop",function()
   local p=player();local before=R.Rolls
   assert(not Drops.OnBossDefeated(p,1,5,{Defeated={},Skipped={[1]=true}}))
   for _,major in ipairs({0,11,1.5}) do assert(not Drops.OnBossDefeated(p,major,5,run(major))) end
   local victory=run(1);R.Roll=.9
   assert(Drops.OnBossDefeated(p,1,5,victory))
   assert(not Drops.OnBossDefeated(player(),1,5,victory))
   assert(R.Rolls==before+1)
  end)
  check("Actual EnemyManager defeat body: one drop; Trophy and Stage progression unchanged",function()
   local source=game.ServerScriptService.World.EnemyManager.Source
   local first=assert(source:find("local function defeat(p,n)",1,true))
   local last=assert(source:find("local function monitor()",first,true))
   local body=source:sub(first,last-1)
   local harness=[==[
local R=require(script.Parent.Runtime)
local ItemDrops=require(script.Parent.BossItemDropService)
local Players=R.Players
local sessions={}
local ps={Defeated={},Gauges={}}
local function state() return ps end
local Boss={Reset=function() R.Reset=(R.Reset or 0)+1 end}
local Stage={ClearStage=function() R.Clears=(R.Clears or 0)+1;return true end,GetState=function() return {CurrentStage=2} end}
local Trophy={Spawn=function() R.Trophies=(R.Trophies or 0)+1 end}
local Wall={Config={[1]={}},IsBossUnlockedForStage=function() return true end}
local function send(_,event) table.insert(R.Events,event.Type) end
local task={delay=function(_,fn) table.insert(R.Delayed,fn) end}
]==]..body.."\nreturn defeat"
   local defeat=require(module("DefeatHarness",harness))
   local p=player({Win=70});local hum={Health=100}
   p.Character={FindFirstChildOfClass=function() return hum end}
   R.Events={};R.Delayed={};R.Roll=0;R.Index=1;local before=R.Rolls
   defeat(p,1);defeat(p,1)
   for _,fn in ipairs(R.Delayed) do fn() end
   flush()
   assert(R.Rolls==before+1 and R.Clears==1 and R.Trophies==1 and R.Reset==1)
   assert(p:GetAttribute("Win")==70 and Items.GetItemCount(p,"PROTEIN_COMMON_FIRE")==1)
   assert(table.find(R.Events,"EnemyDefeated") and table.find(R.Events,"StageCleared"))
   local monitor=source:sub(last)
   local wallBranch=monitor:match("elseif wallHit and power>0 then(.-)elseif enemyHit then")
   assert(wallBranch and not wallBranch:find("defeat(p,n)",1,true) and not wallBranch:find("ItemDrops",1,true))
   local skip=game.ServerScriptService.Services.StageSkipService.Source
   assert(skip:find("Enemy.StartRun(player,target)",1,true) and not skip:find("ItemDrops",1,true) and not skip:find("OnBossDefeated",1,true))
  end)

  check("Flash only after successful +1; one notification at captured Boss position; no-drop and duplicate silent",function()
   R.Roll=0;R.Index=1;local p=player();local victory=run(1)
   local before=R.FlashCount
   assert(Drops.OnBossDefeated(p,1,5,victory))
   assert(R.FlashCount==before)
   flush();assert(R.FlashCount==before+1)
   assert(not Drops.OnBossDefeated(p,1,5,victory));flush();assert(R.FlashCount==before+1)
   R.Roll=.7;assert(Drops.OnBossDefeated(p,2,5,run(2)));flush();assert(R.FlashCount==before+1)
   assert(not Drops.OnBossDefeated(p,2,4,run(2)));flush();assert(R.FlashCount==before+1)
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T