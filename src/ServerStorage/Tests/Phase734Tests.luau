-- Phase 7.3.4: isolated production-source tests; no Robux or live stores used.
local T={}
function T.Run()
 local folder=Instance.new("Folder"); folder.Name="Phase734Sandbox"; folder.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=folder; return m end
 local function replace(s,a,b) local i,j=s:find(a,1,true); assert(i,"Missing seam: "..a); return s:sub(1,i-1)..b..s:sub(j+1) end
 local ok,err=pcall(function()
  local runtime=module("Runtime",[==[
local R={Stores={},Prompts={},PlayersList={},Sequence=0,StageApplications=0}
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
 local records=R.Stores[name]
 return {
  GetAsync=function(_,key) return R.Copy(records[key]) end,
  UpdateAsync=function(_,key,fn)
   if R.BeforeUpdate then R.BeforeUpdate(name,key) end
   if R.FailRead==name then error("simulated read failure") end
   fn(R.Copy(records[key])) -- callback may be retried
   local nextValue=fn(R.Copy(records[key]))
   if R.FailWrite and R.FailWrite(name,key,nextValue) then error("simulated write failure") end
   if nextValue~=nil then records[key]=R.Copy(nextValue) end
   return R.Copy(records[key])
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
   assert(Data.Get(p).Data.OwnedItems[id]==true,id)
   assert(R.Stores.PlayerData_v1["Player_"..p.UserId].OwnedItems[id]==true,"not persisted")
  end
  check("1-7: all 18 Epic/Legendary choices map to fixed product; exact durable ItemId",function()
   local n=0
   for id,item in pairs(Master.GetAll()) do
    if item.Rarity=="Epic" or item.Rarity=="Legendary" then
     local p=player()
     local product=item.Rarity=="Epic" and 3711755218 or 3711755280
     assert(Purchases.Prompt(p,id,product))
     local prompt=R.Prompts[#R.Prompts]
     assert(prompt.ProductId==product and prompt.ItemId==id)
     assert(not Data.Get(p).Data.OwnedItems[id],"prompt must not grant")
     assert(Receipts.ProcessReceipt(receipt(p,product,"all"))==granted)
     assertOwned(p,id)
     local count=0 for _ in pairs(Data.Get(p).Data.OwnedItems) do count+=1 end
     assert(count==1)
     n+=1
    end
   end
   assert(n==18)
  end)
  check("8-10: reject mismatch, invalid ID/type, Win rarity and unloaded/invalid player",function()
   local p=player()
   local yes,code=Purchases.Prompt(p,"PROTEIN_EPIC_FIRE",3711755280)
   assert(not yes and code=="ProductRarityMismatch")
   for _,id in ipairs({"INVALID","PROTEIN_COMMON_FIRE","NORMAL_01",123,false,{}}) do assert(not Purchases.Prompt(p,id)) end
   assert(not Purchases.Prompt(p,nil))
   assert(not Purchases.Prompt({},"PROTEIN_EPIC_FIRE"))
   Data.Release(p)
   assert(not Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
  end)
  check("11: already-owned paid receipt is acknowledged without duplicate ownership",function()
   local p=player()
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
   Data.Get(p).Data.OwnedItems.PROTEIN_EPIC_FIRE=true
   assert(Receipts.ProcessReceipt(receipt(p,3711755218,"owned"))==granted)
   assertOwned(p,"PROTEIN_EPIC_FIRE")
   local count=0 for _ in pairs(Data.Get(p).Data.OwnedItems) do count+=1 end assert(count==1)
  end)
  check("12/17: duplicate receipt in memory and fresh server journal does not regrant",function()
   local p=player()
   assert(Purchases.Prompt(p,"GLOVE_LEGENDARY_ICE"))
   local r=receipt(p,3711755280,"dedupe")
   assert(Receipts.ProcessReceipt(r)==granted)
   assert(Receipts.ProcessReceipt(r)==granted)
   local fresh=require(module("FreshReceipt",receiptSource))
   assert(fresh.ProcessReceipt(r)==granted)
   local forged=table.clone(r); forged.ProductId=3711755218
   assert(fresh.ProcessReceipt(forged)==pending)
   assertOwned(p,"GLOVE_LEGENDARY_ICE")
  end)
  check("13: missing pending, wrong player/product, and arbitrary receipt cannot infer item",function()
   local p=player()
   assert(Receipts.ProcessReceipt(receipt(p,3711755218,"none"))==pending)
   assert(next(Data.Get(p).Data.OwnedItems)==nil)
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_ICE"))
   assert(Receipts.ProcessReceipt(receipt(p,3711755280,"wrong"))==pending)
   local q=player()
   assert(Receipts.ProcessReceipt(receipt(q,3711755218,"wrong-user"))==pending)
   assert(next(Data.Get(p).Data.OwnedItems)==nil and next(Data.Get(q).Data.OwnedItems)==nil)
  end)
  check("Pending cannot be overwritten; one selection binds one PurchaseId",function()
   local p=player()
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
   assert(not Purchases.Prompt(p,"GLOVE_EPIC_ICE"))
   R.Marketplace.PromptProductPurchaseFinished:Fire(p.UserId,3711755218,true)
   assert(not Purchases.Prompt(p,"GLOVE_EPIC_ICE"))
   local r=receipt(p,3711755218,"first")
   R.FailWrite=function(name,_,value) return name=="DeveloperProductReceipts_v1" and value and value.Status=="Granted" end
   assert(Receipts.ProcessReceipt(r)==pending)
   R.FailWrite=nil
   assert(Receipts.ProcessReceipt(receipt(p,3711755218,"second"))==pending)
   assert(Receipts.ProcessReceipt(r)==granted)
   assertOwned(p,"PROTEIN_EPIC_FIRE")
   assert(Data.Get(p).Data.OwnedItems.GLOVE_EPIC_ICE==nil)
  end)
  check("Cancellation and prompt errors release unclaimed intent; close never grants",function()
   local p=player()
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
   R.Marketplace.PromptProductPurchaseFinished:Fire(p.UserId,3711755218,false)
   assert(Purchases.GetPending(p)==nil)
   assert(next(Data.Get(p).Data.OwnedItems)==nil)
   assert(Purchases.Prompt(p,"GLOVE_EPIC_ICE"))
   R.Marketplace.PromptProductPurchaseFinished:Fire(p.UserId,3711755218,true)
   assert(Purchases.GetPending(p).ItemId=="GLOVE_EPIC_ICE")
   assert(next(Data.Get(p).Data.OwnedItems)==nil)
   local q=player()
   R.PromptFailure=true
   assert(not Purchases.Prompt(q,"PROTEIN_EPIC_FIRE"))
   R.PromptFailure=nil
   assert(Purchases.GetPending(q)==nil)
  end)
  check("Rejoin/new service restores durable pending selection",function()
   local p=player()
   assert(Purchases.Prompt(p,"TRAININGBELT_LEGENDARY_ELECTRIC"))
   R.Players.PlayerRemoving:Fire(p)
   Data.Release(p); assert(Data.Load(p))
   local freshPurchases=require(module("FreshPurchases",dependencies(game.ServerScriptService.Systems.Purchases.ItemPurchaseService.Source)))
   assert(freshPurchases.GetPending(p).ItemId=="TRAININGBELT_LEGENDARY_ELECTRIC")
   local freshSource=replace(receiptSource,"require(script.Parent.ItemPurchaseService)","require(script.Parent.FreshPurchases)")
   local fresh=require(module("RejoinReceipts",freshSource))
   assert(fresh.ProcessReceipt(receipt(p,3711755280,"rejoin"))==granted)
   assertOwned(p,"TRAININGBELT_LEGENDARY_ELECTRIC")
  end)
  check("Ownership write failure defers; successful retry grants and preserves fields",function()
   local p=player({Strength=88,Win=12,RebirthCount=3,TotalStrengthEarned=100,DailyStrengthEarned=20,DailyDate=Data.Today(),OwnedDumbbells={NORMAL_01=true},EquippedDumbbell="NORMAL_01",OwnedItems={PROTEIN_RARE_FIRE=true},EquippedItems={Protein="PROTEIN_RARE_FIRE",Glove="",TrainingBelt=""}})
   assert(Purchases.Prompt(p,"GLOVE_EPIC_FIRE"))
   local r=receipt(p,3711755218,"write")
   R.FailWrite=function(name) return name=="PlayerData_v1" end
   assert(Receipts.ProcessReceipt(r)==pending)
   assert(not Data.Get(p).Data.OwnedItems.GLOVE_EPIC_FIRE)
   R.FailWrite=nil
   assert(Receipts.ProcessReceipt(r)==granted)
   assertOwned(p,"GLOVE_EPIC_FIRE")
   local d=Data.Get(p).Data
   assert(d.Strength==88 and d.Win==12 and d.RebirthCount==3 and d.TotalStrengthEarned==100 and d.DailyStrengthEarned==20)
   assert(d.OwnedDumbbells.NORMAL_01 and d.EquippedDumbbell=="NORMAL_01" and d.OwnedItems.PROTEIN_RARE_FIRE and d.EquippedItems.Protein=="PROTEIN_RARE_FIRE")
  end)
  check("Journal failure after grant retries idempotently; foreign lease prevents concurrent grant",function()
   local p=player()
   assert(Purchases.Prompt(p,"GLOVE_EPIC_ELECTRIC"))
   local r=receipt(p,3711755218,"lease")
   R.FailWrite=function(name,_,value) return name=="DeveloperProductReceipts_v1" and value and value.Status=="Granted" end
   assert(Receipts.ProcessReceipt(r)==pending)
   assertOwned(p,"GLOVE_EPIC_ELECTRIC")
   R.FailWrite=nil
   local fresh=require(module("OtherServerReceipt",receiptSource))
   assert(fresh.ProcessReceipt(r)==pending)
   R.Stores.DeveloperProductReceipts_v1[r.PurchaseId].LeaseUntil=0
   assert(fresh.ProcessReceipt(r)==granted)
   assert(Receipts.ProcessReceipt(r)==granted)
  end)
  check("Stale autosave unions durable purchases instead of deleting ownership",function()
   local p=player()
   assert(Data.Save(p))
   R.Stores.PlayerData_v1["Player_"..p.UserId].OwnedItems.PROTEIN_EPIC_FIRE=true
   Data.Get(p).Dirty=true
   assert(Data.Save(p))
   assertOwned(p,"PROTEIN_EPIC_FIRE")
  end)
  check("14: all 27 Win items still purchase; Epic/Legendary cannot use Win",function()
   local n=0
   for id,item in pairs(Master.GetAll()) do
    local p=player({Win=100})
    if item.ShopPurchasable then
     assert(Items.PurchaseItemWithWin(p,id))
     assert(p:GetAttribute("Win")==100-item.WinPrice)
     assert(Items.HasItem(p,id)); n+=1
    else assert(not Items.PurchaseItemWithWin(p,id)) end
   end
   assert(n==27)
  end)
  check("15/17: all 9 Stage Skip receipt mappings and dedupe preserved",function()
   local config=require(game.ReplicatedStorage.Config.StageSkipConfig)
   for stage,entry in pairs(config.Stages) do
    local p=player(); local r=receipt(p,entry.ProductId,"stage")
    local before=R.StageApplications
    assert(Receipts.ProcessReceipt(r)==granted)
    assert(p.LastStage==stage and p.NotifiedStage==stage)
    assert(Receipts.ProcessReceipt(r)==granted and R.StageApplications==before+1)
   end
   local p=player(); p.Ready=false
   local r=receipt(p,config.Stages[2].ProductId,"stage-not-ready")
   assert(Receipts.ProcessReceipt(r)==pending)
   p.Ready=true; assert(Receipts.ProcessReceipt(r)==granted)
   assert(Receipts.ProcessReceipt(receipt(p,123,"unknown"))==pending)
  end)

  check("Pending persistence failure opens no prompt; DataSaving receipt retries",function()
   local p=player()
   local count=#R.Prompts
   R.FailWrite=function(name) return name=="ItemPurchaseIntents_v1" end
   assert(not Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
   R.FailWrite=nil
   assert(#R.Prompts==count and Purchases.GetPending(p)==nil)
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_FIRE"))
   local r=receipt(p,3711755218,"saving")
   Data.Get(p).Saving=true
   assert(Receipts.ProcessReceipt(r)==pending)
   Data.Get(p).Saving=false
   assert(Receipts.ProcessReceipt(r)==granted)
  end)
  check("Receipt cleanup failure retries from Granted journal without consuming a new selection",function()
   local p=player()
   assert(Purchases.Prompt(p,"PROTEIN_EPIC_ICE"))
   local r=receipt(p,3711755218,"cleanup")
   R.FailWrite=function(name,_,value) return name=="ItemPurchaseIntents_v1" and value and value.Status=="Idle" end
   assert(Receipts.ProcessReceipt(r)==pending)
   assertOwned(p,"PROTEIN_EPIC_ICE")
   assert(R.Stores.DeveloperProductReceipts_v1[r.PurchaseId].Status=="Granted")
   R.FailWrite=nil
   assert(Receipts.ProcessReceipt(r)==granted and Purchases.GetPending(p)==nil)
   R.Marketplace.PromptProductPurchaseFinished:Fire(p.UserId,3711755218,true)
   assert(Purchases.Prompt(p,"GLOVE_EPIC_FIRE"))
   local fresh=require(module("ReplayAfterNewSelection",receiptSource))
   assert(fresh.ProcessReceipt(r)==granted)
   assert(Purchases.GetPending(p).ItemId=="GLOVE_EPIC_FIRE")
  end)
  check("Remote registers selection server-side; tampering/mismatch and rate limit rejected",function()
   local remotes={}
   for _,name in ipairs({"ItemPurchaseRequest","ItemEquipRequest","ItemInventoryState","ItemRobuxPurchaseRequest"}) do
    local remote={OnServerEvent=R.Signal(),Replies={}}
    function remote:FireClient(p,result) self.Replies[p]=result end
    remotes[name]=remote
   end
   R.Remotes=remotes
   local controller=dependencies(game.ServerScriptService.Systems.Controllers.ItemController.Source)
   for name in pairs(remotes) do
    controller=replace(controller,'RS:WaitForChild("'..name..'")','require(script.Parent.Runtime).Remotes.'..name)
   end
   require(module("ItemController",controller..'\nreturn true'))
   local remote=remotes.ItemRobuxPurchaseRequest
   local p=player()
   remote.OnServerEvent:Fire(p,"GLOVE_EPIC_ICE",3711755218)
   assert(remote.Replies[p].Success and remote.Replies[p].Code=="PromptOpened")
   assert(Purchases.GetPending(p).ItemId=="GLOVE_EPIC_ICE")
   remote.OnServerEvent:Fire(p,"PROTEIN_EPIC_FIRE")
   assert(remote.Replies[p].Code=="RateLimited")
   assert(Purchases.GetPending(p).ItemId=="GLOVE_EPIC_ICE")
   local q=player()
   remote.OnServerEvent:Fire(q,"GLOVE_LEGENDARY_ICE",3711755218)
   assert(not remote.Replies[q].Success and remote.Replies[q].Code=="ProductRarityMismatch")
   local x=player()
   remote.OnServerEvent:Fire(x,{ItemId="GLOVE_EPIC_ICE",PurchaseGranted=true})
   assert(not remote.Replies[x].Success and next(Data.Get(x).Data.OwnedItems)==nil)
   assert(Receipts.ProcessReceipt(receipt(p,3711755218,"remote"))==granted)
   assert(remote.Replies[p].Code=="Purchased" and remote.Replies[p].State.OwnedItems.GLOVE_EPIC_ICE)
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T
