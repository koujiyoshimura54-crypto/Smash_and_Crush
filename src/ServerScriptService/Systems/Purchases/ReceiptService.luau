-- The only ProcessReceipt implementation; no client remote can invoke this module.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Config.StageSkipConfig)
local Skip=require(game.ServerScriptService.Services.StageSkipService)
local Items=require(game.ServerScriptService.Systems.Purchases.ItemPurchaseService)
local M={}
local granted=Enum.ProductPurchaseDecision.PurchaseGranted
local pending=Enum.ProductPurchaseDecision.NotProcessedYet
local owner=game.JobId..":"..HttpService:GenerateGUID(false)
local applied,completed,inFlight={},{},{}
local store
local function getStore()
 if store then return store end
 if RunService:IsStudio() then
  -- Studio purchase tests never write into the live purchase journal.
  local entries={}
  store={}
  function store:UpdateAsync(key,transform)
   local value=transform(entries[key] and table.clone(entries[key]) or nil)
   if value~=nil then entries[key]=table.clone(value) end
   return entries[key] and table.clone(entries[key]) or nil
  end
 else
  -- Shared persistent purchase history for Stage Skip and regular items.
  store=game:GetService("DataStoreService"):GetDataStore("DeveloperProductReceipts_v1")
 end
 return store
end
local function matches(value,r)
 return value and value.PlayerId==r.PlayerId and value.ProductId==r.ProductId
end
-- Limited Egg: new prompts are policy/price gated; already-paid receipts are
-- fulfilled independently so a later policy/API outage cannot erase a purchase.
local Limited=require(game.ReplicatedStorage.Config.LimitedEggConfig)
local StoreConfig=require(game.ServerScriptService.Config.DataStoreConfig)
local StudioDebugConfig=require(game.ServerScriptService.Config.StudioDebugConfig)
local limitedStore
local function studioAuthorized(player)
 return RunService:IsStudio() and game.PlaceId==126576845524886 and game.GameId==10765181857
  and player and player.Parent==Players
  and type(StudioDebugConfig.ProductionCreatorUserIds)=="table"
  and StudioDebugConfig.ProductionCreatorUserIds[player.UserId]==true
  and StoreConfig.GetName("PlayerData_v1")=="PlayerData_v1_Studio"
  and StoreConfig.GetName("DeveloperProductReceipts_v1")=="DeveloperProductReceipts_v1_Studio"
end
local function getLimitedStore()
 if not RunService:IsStudio() then return getStore() end
 if not limitedStore then
  assert(StoreConfig.GetName("DeveloperProductReceipts_v1")=="DeveloperProductReceipts_v1_Studio","Studio journal required")
  limitedStore=game:GetService("DataStoreService"):GetDataStore(StoreConfig.GetName("DeveloperProductReceipts_v1"))
 end
 return limitedStore
end
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Pet=require(game.ReplicatedStorage.Modules.Pet)
local Marketplace=game:GetService("MarketplaceService")
local Policy=game:GetService("PolicyService")
local random=Random.new()
local promptBusy,requestBusy,nextRequest,ready=setmetatable({}, {__mode="k"}),setmetatable({}, {__mode="k"}),setmetatable({}, {__mode="k"}),setmetatable({}, {__mode="k"})
local deliveries,retries={},{}
local committedEvent
local initialized=false
local function receiptMatches(record,r)
 return matches(record,r) and record.Kind=="LimitedEgg"
  and Limited.ValidateResult(record.Result,record.TableVersion)
end
local function outcome()
 local roll=random:NextInteger(1,200)
 local cumulative=0
 for _,entry in ipairs(Limited.Entries) do
  cumulative+=entry.Percent*2
  if roll<=cumulative then return {id=HttpService:GenerateGUID(false),pet=entry.Name,percent=entry.Percent} end
 end
 error("Invalid limited Egg pool")
end
local function deliver(player,r,record)
 if record.Presented or player.Parent~=Players then return end
 local state=Data.GetPetState(player)
 if not state or state.Owned[record.Result.id]~=record.Result.pet then return end
 local session=Data.Get(player)
 local marker=session and session.Data.LimitedEggReceipts and session.Data.LimitedEggReceipts[r.PurchaseId]
 if not marker or marker.Result.id~=record.Result.id then return end
 local notice={ProductId=r.ProductId,PurchaseId=r.PurchaseId,Saved=true,Status="Granted",
  Result=table.clone(record.Result),State=state,TableVersion=record.TableVersion}
 deliveries[r.PurchaseId]={Player=player,Notice=notice,Record=record}
 if ready[player] and committedEvent then
  local ok,err=pcall(function() committedEvent:FireClient(player,notice) end)
  if not ok then warn("Limited Egg notification pending: "..tostring(err)) end
 end
end
local processLimitedReceipt
local function scheduleReceiptRetry(r)
 local key=r.PurchaseId
 if retries[key] then return end
 local ticket={PlayerId=r.PlayerId,ProductId=r.ProductId,PurchaseId=key}
 retries[key]=ticket
 task.spawn(function()
  for attempt=1,20 do
   task.wait(math.min(30,attempt*2))
   if not Players:GetPlayerByUserId(r.PlayerId) then break end
   if processLimitedReceipt(ticket)==granted then break end
  end
  retries[key]=nil
 end)
end
processLimitedReceipt=function(r)
 local key=r.PurchaseId
 local player=Players:GetPlayerByUserId(r.PlayerId)
 if not player or inFlight[key] then return pending end
 if RunService:IsStudio() and not studioAuthorized(player) then warn("[LimitedEgg01] Studio receipt denied");return pending end
 inFlight[key]=true
 local ok,decision=pcall(function()
  local rejected=false
  local function reserve(old,proposed)
   rejected=false
   if old then
    if not receiptMatches(old,r) then rejected=true;return nil end
    if old.Status=="Granted" then return old end
    if old.Status~="Reserved" or old.Owner~=owner and (old.LeaseUntil or 0)>os.time() then rejected=true;return nil end
    local nextRecord=table.clone(old);nextRecord.Owner=owner;nextRecord.LeaseUntil=os.time()+180
    return nextRecord
   end
   if not proposed then return nil end
   return {PlayerId=r.PlayerId,ProductId=r.ProductId,Kind="LimitedEgg",TableVersion=Limited.RollVersion,
    Result=proposed,Status="Reserved",Owner=owner,LeaseUntil=os.time()+180}
  end
  -- Recover the existing immutable outcome before generating any new proposal.
  local record=getLimitedStore():UpdateAsync(key,function(old) return reserve(old,nil) end)
  if not record and not rejected then
   local proposed=outcome()
   record=getLimitedStore():UpdateAsync(key,function(old) return reserve(old,proposed) end)
  end
  if not receiptMatches(record,r) then return pending end
  if record.Status=="Granted" then
   completed[key]=record;pcall(deliver,player,r,record);return granted
  end
  if record.Owner~=owner or player.Parent~=Players then return pending end
  -- Pet and immutable PurchaseId marker are one fenced PlayerData write.
  local success=Data.GrantLimitedEgg(player,key,record)
  if not success then return pending end
  local saved=getLimitedStore():UpdateAsync(key,function(old)
   if not receiptMatches(old,r) or old.Result.id~=record.Result.id then return nil end
   if old.Status=="Granted" then return old end
   if old.Owner~=owner then return nil end
   local final=table.clone(old);final.Status="Granted";final.Owner=nil;final.LeaseUntil=nil
   return final
  end)
  if not receiptMatches(saved,r) or saved.Status~="Granted" then return pending end
  completed[key]=saved
  print("[LimitedEgg01] saved receipt",key,saved.Result.id,saved.Result.pet,RunService:IsStudio() and "Studio" or "Production")
  pcall(deliver,player,r,saved)
  return granted
 end)
 inFlight[key]=nil
 if not ok then warn("Limited Egg receipt deferred: "..tostring(decision));return pending end
 return decision
end
local function productInfo()
 if not Limited.PurchaseEnabled then return nil,"PurchasesUnavailable" end
 -- Cloud Studio can inspect a prompt; receipt grants remain disabled in Studio.
 if RunService:IsStudio() and game.PlaceId~=126576845524886 then return nil,"LocalStudioUnsupported" end
 if game.GameId~=Limited.UniverseId then return nil,"WrongExperience" end
 local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(Limited.ProductId,Enum.InfoType.Product) end)
 if not ok or type(info)~="table" or info.ProductId~=Limited.ProductId or info.IsForSale~=true
  or type(info.PriceInRobux)~="number" or info.PriceInRobux~=info.PriceInRobux
  or info.PriceInRobux<=0 or info.PriceInRobux==math.huge then return nil,"PriceUnavailable" end
 if info.UniverseId~=nil then
  if info.UniverseId~=game.GameId then return nil,"WrongExperience" end
 else
  local listed,found=pcall(function()
   local pages=Marketplace:GetDeveloperProductsAsync()
   for _=1,100 do
    for _,entry in ipairs(pages:GetCurrentPage()) do if entry.ProductId==Limited.ProductId then return true end end
    if pages.IsFinished then return false end
    pages:AdvanceToNextPageAsync()
   end
   return false
  end)
  if not listed or not found then return nil,"ProductAssociationUnavailable" end
 end
 return info
end
local function eligibility(player)
 if RunService:IsStudio() and not studioAuthorized(player) then return nil,"StudioDeveloperRequired" end
 local session=Data.Get(player)
 if not session or not session.Loaded or not session.Data then return nil,"DataNotLoaded" end
 if session.OwnershipLost then return nil,"SessionOwnershipLost" end
 if session.Saving or session.PendingItemMutation then return nil,"DataSaving" end
 local snapshot=session.Data
 local success,policy=pcall(function() return Policy:GetPolicyInfoForPlayerAsync(player) end)
 if not success or type(policy)~="table" or type(policy.ArePaidRandomItemsRestricted)~="boolean" then return nil,"PolicyUnavailable" end
 if policy.ArePaidRandomItemsRestricted then return nil,"PaidRandomRestricted" end
 for _,entry in ipairs(Limited.Entries) do if not Pet.model(entry.Name) then return nil,"PetModelUnavailable" end end
 local info,reason=productInfo()
 if not info then return nil,reason end
 if player.Parent~=Players or Data.Get(player)~=session or session.Data~=snapshot or session.OwnershipLost then
  return nil,"SessionOwnershipLost"
 end
 if session.Saving or session.PendingItemMutation then return nil,"DataSaving" end
 return info
end
local function nearEntrance(player)
 local model=workspace:FindFirstChild(Limited.Entrance)
 local part=model and model.PrimaryPart
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 return part and root and hum and hum.Health>0 and (player:GetAttribute("CurrentWorld") or 1)==1
  and (root.Position-part.Position).Magnitude<=24
end
function M.LimitedRequest(player,action,value)
 if action=="Offer" or action=="Purchase" then print("[LimitedEgg01] request",action,player and player.UserId,game.PlaceId) end
 if not player or player.Parent~=Players then return {ok=false,reason="InvalidPlayer"} end
 if action=="Ready" then
  ready[player]=true
  for _,delivery in pairs(deliveries) do
   if delivery.Player==player and committedEvent then
    pcall(function() committedEvent:FireClient(player,delivery.Notice) end)
   end
  end
  return {ok=true}
 end
 if requestBusy[player] or os.clock()<(nextRequest[player] or 0) then return {ok=false,reason="PleaseWait"} end
 requestBusy[player]=true;nextRequest[player]=os.clock()+0.75
 local ok,response=pcall(function()
  if action=="Acknowledge" then
   if type(value)~="string" or value=="" or #value>100 then return {ok=false,reason="InvalidReceipt"} end
   if RunService:IsStudio() and not studioAuthorized(player) then return {ok=false,reason="StudioDeveloperRequired"} end
   local saved=getLimitedStore():UpdateAsync(value,function(old)
    if not old or old.PlayerId~=player.UserId or old.ProductId~=Limited.ProductId or old.Kind~="LimitedEgg"
     or old.Status~="Granted" then return nil end
    local final=table.clone(old);final.Presented=true;return final
   end)
   if saved and saved.Presented then deliveries[value]=nil;return {ok=true} end
   return {ok=false,reason="NotificationPending"}
  end
  if action~="Offer" and action~="Purchase" then return {ok=false,reason="InvalidAction"} end
  if promptBusy[player] then return {ok=false,reason="PurchaseBusy"} end
  if not nearEntrance(player) then return {ok=false,reason="TooFarFromEgg"} end
  local info,reason=eligibility(player)
  if not info then return {ok=false,reason=reason} end
  if action=="Offer" then return {ok=true,ProductId=Limited.ProductId,Price=info.PriceInRobux,TableVersion=Limited.RollVersion} end
  if value~=Limited.RollVersion or not nearEntrance(player) then return {ok=false,reason="OfferChanged"} end
  promptBusy[player]=true
  print("[LimitedEgg01] prompting",player.UserId,Limited.ProductId)
  local prompted,err=pcall(function() Marketplace:PromptProductPurchase(player,Limited.ProductId) end)
  if not prompted then promptBusy[player]=nil;warn("Limited Egg prompt failed: "..tostring(err));return {ok=false,reason="PromptFailed"} end
  return {ok=true}
 end)
 requestBusy[player]=nil
 if not ok then promptBusy[player]=nil;warn("Limited Egg request failed: "..tostring(response));return {ok=false,reason="PurchaseUnavailable"} end
 if action=="Offer" or action=="Purchase" then print("[LimitedEgg01] response",action,response.ok,response.reason or "Allowed") end
 return response
end
function M.InitializeLimited()
 if initialized then return end;initialized=true
 local folder=game.ReplicatedStorage.Remotes.GameRemotes
 local function remote(name,class)
  local x=folder:FindFirstChild(name)
  if x then assert(x:IsA(class),name.." has the wrong class") else x=Instance.new(class);x.Name=name;x.Parent=folder end
  return x
 end
 local request=remote("LimitedEggPurchase","RemoteFunction")
 committedEvent=remote("LimitedEggCommitted","RemoteEvent")
 request.OnServerInvoke=M.LimitedRequest
 print("[LimitedEgg01] server ready",game.PlaceId,Limited.ProductId)
 Marketplace.PromptProductPurchaseFinished:Connect(function(userId,productId)
  if productId~=Limited.ProductId then return end
  local player=Players:GetPlayerByUserId(userId)
  if player then promptBusy[player]=nil end -- completion/cancel only unlocks; never grants
 end)
 Players.PlayerRemoving:Connect(function(player)
  promptBusy[player]=nil;requestBusy[player]=nil;nextRequest[player]=nil;ready[player]=nil
  for id,d in pairs(deliveries) do if d.Player==player then deliveries[id]=nil end end
 end)
 task.spawn(function()
  while initialized do
   task.wait(5)
   for _,d in pairs(deliveries) do
    if ready[d.Player] and d.Player.Parent==Players then
     pcall(function() committedEvent:FireClient(d.Player,d.Notice) end)
    end
   end
  end
 end)
end

-- Item receipts share the Stage Skip journal, lease owner and PurchaseId caches.
local function processItemReceipt(r)
 local key=r.PurchaseId
 if completed[key] then return matches(completed[key],r) and granted or pending end
 local player=Players:GetPlayerByUserId(r.PlayerId)
 if not player or inFlight[key] then return pending end
 inFlight[key]=true
 local ok,decision=pcall(function()
  local intent,intentError=Items.GetPending(player)
  if intentError then return pending end
  local now=os.time()
  local journal=getStore()
  local record=journal:UpdateAsync(key,function(old)
   if old and not matches(old,r) then return nil end
   if old and old.Status=="Granted" then return old end
   if old and old.Owner~=owner and (old.LeaseUntil or 0)>now then return nil end
   if old then
    -- Keep the original ItemId/IntentId even when a later selection exists.
    if not old.ItemId or not old.IntentId then return nil end
    local nextRecord=table.clone(old)
    if not nextRecord.IntentSequence and intent and intent.IntentId==old.IntentId then
     nextRecord.IntentSequence=intent.Sequence
    end
    nextRecord.Owner=owner
    nextRecord.LeaseUntil=now+180
    return nextRecord
   end
   if not intent or intent.PlayerId~=r.PlayerId or intent.ExpectedProductId~=r.ProductId
    or not Items.ValidateItem(intent.ItemId,r.ProductId)
    or (intent.PurchaseId~=nil and intent.PurchaseId~=key) then return nil end
   return {PlayerId=r.PlayerId,ProductId=r.ProductId,ItemId=intent.ItemId,IntentId=intent.IntentId,
    Timestamp=intent.Timestamp,IntentSequence=intent.Sequence,QuantityVersion=1,Status="Reserved",Owner=owner,LeaseUntil=now+180}
  end)
  if not matches(record,r) then return pending end
  if record.Status=="Granted" then
   if not Items.Complete(player,r,record) then return pending end
   completed[key]=record
   return granted
  end
  if record.Owner~=owner or not Items.ClaimPending(player,r,record) then return pending end
  if player.Parent~=Players then return pending end
  -- Idempotent durable ownership union; retry even after a failed journal write.
  if not Items.Grant(player,r,record) then return pending end
  applied[key]={PlayerId=r.PlayerId,ProductId=r.ProductId,ItemId=record.ItemId}
  local saved=journal:UpdateAsync(key,function(old)
   if not matches(old,r) or old.ItemId~=record.ItemId or old.IntentId~=record.IntentId then return nil end
   if old.Status=="Granted" then return old end
   if old.Owner~=owner then return nil end
   local final=table.clone(old)
   final.Status="Granted"
   final.Owner=nil
   final.LeaseUntil=nil
   return final
  end)
  if matches(saved,r) and saved.Status=="Granted" and Items.Complete(player,r,saved) then
   completed[key]=saved
   return granted
  end
  return pending
 end)
 inFlight[key]=nil
 if not ok then warn("Item receipt deferred: "..tostring(decision)); return pending end
 return decision
end

function M.ProcessReceipt(r)
 if typeof(r)=="table" and r.ProductId==Limited.ProductId then
  if type(r.PurchaseId)~="string" or r.PurchaseId=="" or #r.PurchaseId>100
   or type(r.PlayerId)~="number" or r.PlayerId~=r.PlayerId or r.PlayerId<=0 or r.PlayerId%1~=0 or r.PlayerId==math.huge then return pending end
  local decision=processLimitedReceipt(r)
  if decision==pending and (not RunService:IsStudio() or studioAuthorized(Players:GetPlayerByUserId(r.PlayerId))) then scheduleReceiptRetry(r) end
  return decision
 end
 local shopDecision=require(game.ServerScriptService.Services.ShopRewardService).ProcessWinReceipt(r)
 if shopDecision then return shopDecision end
 if typeof(r)~="table" or typeof(r.PurchaseId)~="string" or r.PurchaseId=="" or #r.PurchaseId>100 then return pending end
 if Items.RarityForProduct(r.ProductId) then
  if typeof(r.PlayerId)~="number" or r.PlayerId~=r.PlayerId or r.PlayerId%1~=0 or r.PlayerId<=0 then return pending end
  return processItemReceipt(r)
 end
 local stage=Config.StageForProduct(r.ProductId)
 if not stage or typeof(r.PlayerId)~="number" or r.PlayerId%1~=0 then return pending end
 local key=r.PurchaseId
 if completed[key] then
  return matches(completed[key],r) and granted or pending
 end
 local player=Players:GetPlayerByUserId(r.PlayerId)
 if not player or inFlight[key] or not Skip.TryLock(player) then return pending end
 inFlight[key]=true
 local ok,decision=pcall(function()
  if not applied[key] and not Skip.GetStartCFrame(player,stage) then return pending end
  local journal=getStore()
  local now=os.time()
  -- Atomic reservation prevents two active servers from granting the same receipt.
  -- No gameplay side effects inside UpdateAsync's retryable callback.
  local record=journal:UpdateAsync(key,function(old)
   if old and not matches(old,r) then return nil end
   if old and old.Status=="Granted" then return old end
   if old and old.Owner~=owner and old.LeaseUntil>now then return nil end
   return {PlayerId=r.PlayerId,ProductId=r.ProductId,Status="Reserved",Owner=owner,LeaseUntil=now+180}
  end)
  if not matches(record,r) then return pending end
  if record.Status=="Granted" then completed[key]=record return granted end
  if record.Owner~=owner then return pending end
  if not applied[key] then
   if player.Parent~=Players then return pending end
   local success=Skip.ApplyLocked(player,stage)
   if not success then return pending end
   -- Retained across player departure and Run resets, including a failed journal write.
   applied[key]={PlayerId=r.PlayerId,ProductId=r.ProductId}
   Skip.NotifyReceipt(player,stage)
  elseif not matches(applied[key],r) then
   return pending
  end
  local saved=journal:UpdateAsync(key,function(old)
   if not matches(old,r) then return nil end
   if old.Status=="Granted" then return old end
   if old.Owner~=owner then return nil end
   return {PlayerId=r.PlayerId,ProductId=r.ProductId,Status="Granted"}
  end)
  if matches(saved,r) and saved.Status=="Granted" then
   completed[key]=saved
   return granted
  end
  return pending
 end)
 inFlight[key]=nil
 Skip.Unlock(player)
 if not ok then
  warn("Receipt deferred: "..tostring(decision))
  return pending
 end
 return decision
end
return M
