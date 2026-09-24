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
  module("ItemMaster",game.ReplicatedStorage.Config.ItemMaster.Source)
  local function dependencies(source)
   source=source:gsub('require%(game%.ReplicatedStorage%.Config%.ItemMaster%)','require(script.Parent.ItemMaster)')
   source=source:gsub('require%(game:GetService%("ReplicatedStorage"%).Config:WaitForChild%("ItemMaster"%)%)','require(script.Parent.ItemMaster)')
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
  local Master=require(folder.ItemMaster)
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

  module("ItemMergeService",dependencies(game.ServerScriptService.Services.ItemMergeService.Source))
  local Merge=require(folder.ItemMergeService)
  local source="PROTEIN_RARE_FIRE"
  local target="PROTEIN_EPIC_FIRE"
  check("All 36 upgrades preserve type/element and advance exactly one rarity; 9 Legendary rejected",function()
   local n,l=0,0
   local nextRarity={Common="Uncommon",Uncommon="Rare",Rare="Epic",Epic="Legendary"}
   for id,item in pairs(Master.GetAll()) do
    local p=player({OwnedItems={[id]=3}})
    if item.Rarity=="Legendary" then assert(not Merge.CanMerge(p,id));assert(not Merge.MergeItem(p,id));l+=1
    else
     local result=assert(Merge.GetMergeResult(id))
     local definition=Master.Get(result)
     assert(definition.ItemType==item.ItemType and definition.Element==item.Element and definition.Rarity==nextRarity[item.Rarity])
     assert(Merge.CanMerge(p,id));assert(Merge.MergeItem(p,id))
     assert(Items.GetItemCount(p,id)==0 and Items.GetItemCount(p,result)==1)
     assert(Items.GetEquippedItems(p)[item.ItemType]=="")
     n+=1
    end
   end
   assert(n==36 and l==9)
  end)
  check("Counts 0/1/2 rejected; invalid input/player and unloaded data rejected",function()
   for count=0,2 do local p=player({OwnedItems={[source]=count}});assert(not Merge.MergeItem(p,source));assert(Items.GetItemCount(p,source)==count) end
   local p=player()
   for _,id in ipairs({"INVALID","NORMAL_01",false,123,{}}) do assert(not Merge.MergeItem(p,id)) end
   assert(not Merge.MergeItem(p,nil));assert(not Merge.MergeItem({},source))
   Data.Release(p);assert(not Merge.MergeItem(p,source))
  end)
  check("5 becomes 2; existing target increments; equipment retained and result never auto-equipped",function()
   local p=player({OwnedItems={[source]=5,[target]=7},EquippedItems={Protein=source,Glove="",TrainingBelt=""}})
   assert(Merge.MergeItem(p,source))
   assert(Items.GetItemCount(p,source)==2 and Items.GetItemCount(p,target)==8)
   assert(Items.GetEquippedItems(p).Protein==source)
   assert(math.abs(Items.GetItemStrengthMultiplier(p)-1.2)<1e-9)
   assert(not Merge.MergeItem(p,source))
  end)
  check("Last three copies auto-unequip only source slot; multiplier and save/reload preserved",function()
   local p=player({Win=88,Strength=42,RebirthCount=2,TotalStrengthEarned=120,DailyStrengthEarned=20,DailyDate=Data.Today(),
    OwnedItems={[source]=3,GLOVE_EPIC_ICE=1},EquippedItems={Protein=source,Glove="GLOVE_EPIC_ICE",TrainingBelt=""},
    OwnedDumbbells={NORMAL_01=true},EquippedDumbbell="NORMAL_01"})
   assert(Merge.MergeItem(p,source))
   assert(Items.GetEquippedItems(p).Protein=="" and Items.GetEquippedItems(p).Glove=="GLOVE_EPIC_ICE")
   assert(math.abs(Items.GetItemStrengthMultiplier(p)-1.35)<1e-9)
   local saved=R.Stores.PlayerData_v1["Player_"..p.UserId]
   assert(saved.EquippedItems.Protein=="")
   assert(Data.Save(p));Data.Release(p);assert(Data.Load(p))
   local d=Data.Get(p).Data
   assert(Items.GetItemCount(p,source)==0 and Items.GetItemCount(p,target)==1 and d.EquippedItems.Protein=="")
   assert(d.Win==88 and d.Strength==42 and d.RebirthCount==2 and d.TotalStrengthEarned==120 and d.DailyStrengthEarned==20)
   assert(d.OwnedDumbbells.NORMAL_01 and d.EquippedDumbbell=="NORMAL_01")
  end)
  check("Write failure commits neither side; retry atomically consumes/grants once",function()
   local p=player({OwnedItems={[source]=3}})
   R.FailWrite=function(name) return name=="PlayerData_v1" end
   assert(not Merge.MergeItem(p,source))
   assert(Items.GetItemCount(p,source)==3 and Items.GetItemCount(p,target)==0)
   assert(not Merge.MergeItem(p,source))
   R.FailWrite=nil;assert(Data.Save(p))
   assert(Items.GetItemCount(p,source)==0 and Items.GetItemCount(p,target)==1)
   assert(Data.Save(p));assert(Items.GetItemCount(p,target)==1)
  end)
  check("Lost acknowledgement replays same mutation ID without duplicate increment",function()
   local p=player({OwnedItems={[source]=5,[target]=2}})
   R.FailAfterWrite=function(name) return name=="PlayerData_v1" end
   assert(not Merge.MergeItem(p,source))
   local saved=R.Stores.PlayerData_v1["Player_"..p.UserId]
   assert(saved.OwnedItems[source]==2 and saved.OwnedItems[target]==3)
   R.FailAfterWrite=nil;assert(Data.Save(p))
   assert(Items.GetItemCount(p,source)==2 and Items.GetItemCount(p,target)==3)
  end)
  check("Stale stock and target overflow cannot cause partial mutation or negative count",function()
   local p=player({OwnedItems={[source]=3}})
   assert(Data.Save(p))
   R.Stores.PlayerData_v1["Player_"..p.UserId].OwnedItems[source]=2
   assert(not Merge.MergeItem(p,source))
   local saved=R.Stores.PlayerData_v1["Player_"..p.UserId]
   assert(saved.OwnedItems[source]==2 and not saved.OwnedItems[target])
   local q=player({OwnedItems={[source]=3,[target]=9007199254740991}})
   assert(not Merge.MergeItem(q,source));assert(Items.GetItemCount(q,source)==3)
  end)
  check("Failed transaction callback discards staged removal; invalid tokens rejected",function()
   local p=player({OwnedItems={[source]=3}})
   assert(not Items.RunItemTransaction(p,function(token)
    assert(Items.RemoveItem(p,source,3,token))
    return Items.AddItem(p,"INVALID",1,token)
   end))
   assert(Items.GetItemCount(p,source)==3)
   assert(not Items.RemoveItem(p,source,3,{}))
  end)
  check("Receipt replay after Merge cannot restore consumed paid copies",function()
   local p=player({OwnedItems={[target]=2}})
   assert(Purchases.Prompt(p,target))
   local r=receipt(p,3711755218,"merge")
   assert(Receipts.ProcessReceipt(r)==granted)
   assert(Merge.MergeItem(p,target))
   assert(Receipts.ProcessReceipt(r)==granted)
   assert(Items.GetItemCount(p,target)==0 and Items.GetItemCount(p,"PROTEIN_LEGENDARY_FIRE")==1)
  end)
  check("Remote rejects forged result arguments; returns authoritative updated inventory",function()
   local remote={OnServerEvent=R.Signal(),Replies={}}
   function remote:FireClient(p,result) self.Replies[p]=result end
   R.MergeRemote=remote
   local controller=dependencies(game.ServerScriptService.Systems.Controllers.ItemMergeController.Source)
   controller=replace(controller,'RS.Remotes:WaitForChild("ItemMergeRequest")','require(script.Parent.Runtime).MergeRemote')
   require(module("ItemMergeController",controller.."\nreturn true"))
   local p=player({OwnedItems={[source]=3}})
   remote.OnServerEvent:Fire(p,source,"PROTEIN_LEGENDARY_FIRE")
   assert(not remote.Replies[p].Success and Items.GetItemCount(p,source)==3)
   remote.OnServerEvent:Fire(p,source)
   local result=remote.Replies[p]
   assert(result.Success and result.ResultItemId==target and result.State.OwnedItems[target]==1 and not result.State.OwnedItems[source])
   remote.OnServerEvent:Fire(p,source);assert(remote.Replies[p].Code=="RateLimited")
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T