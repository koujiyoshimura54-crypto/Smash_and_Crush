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

