-- Phase 7.3.4: durable, server-authoritative selection for two fixed item products.
local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local M={}
local Products=require(game.ReplicatedStorage.Config:WaitForChild("DeveloperProductConfig"))
local types=Master.TypePrefixes
local elements=Master.ElementSet
local busy,prompts={},{}
local notify
local store
local function getStore()
 if store then return store end
 if RunService:IsStudio() then
  -- Match ReceiptService: Studio uses an isolated in-memory purchase journal.
  local entries={}
  store={}
  function store:UpdateAsync(key,transform)
   local value=transform(entries[key] and table.clone(entries[key]) or nil)
   if value~=nil then entries[key]=table.clone(value) end
   return entries[key] and table.clone(entries[key]) or nil
  end
 else
  store=game:GetService("DataStoreService"):GetDataStore("ItemPurchaseIntents_v1")
 end
 return store
end
local function validPlayer(player)
 return typeof(player)=="Instance" and player:IsA("Player") and player.Parent==Players
end
local function key(player) return "Player_"..tostring(player.UserId) end
local function active(value) return typeof(value)=="table" and value.Status=="Pending" end
local function report(player,success,code,itemId)
 if notify and player.Parent==Players then
  local ok,err=pcall(notify,player,success,code,itemId)
  if not ok then warn("Item purchase notification failed: "..tostring(err)) end
 end
end
function M.SetNotifier(fn) notify=fn end
function M.RarityForProduct(productId)
 if typeof(productId)~="number" then return nil end
 return Products.GetItemRarity(productId)
end
function M.ValidateItem(itemId,productId)
 local item=Master.Get(itemId)
 if not item then return nil,"InvalidItemId" end
 local expected=Products.GetItemProductId(item.Rarity)
 if not expected then return nil,"NotRobuxPurchasable" end
 if productId~=nil and productId~=expected then return nil,"ProductRarityMismatch" end
 if not types[item.ItemType] or not elements[item.Element] then return nil,"InvalidItemDefinition" end
 if item.ItemId~=itemId or itemId~=types[item.ItemType].."_"..item.Rarity:upper().."_"..item.Element:upper() then
  return nil,"InvalidItemDefinition"
 end
 return item,expected
end
function M.GetPending(player)
 if not validPlayer(player) then return nil,"InvalidPlayer" end
 local ok,value=pcall(function()
  return getStore():UpdateAsync(key(player),function(old)
   if active(old) and old.Sequence==nil then
    local migrated=table.clone(old); migrated.Sequence=1; return migrated
   end
   return old
  end)
 end)
 if not ok then return nil,"PendingUnavailable" end
 if not active(value) then return nil end
 return table.clone(value)
end
local function cancel(player,intent)
 local ok,value=pcall(function()
  return getStore():UpdateAsync(key(player),function(old)
   if active(old) and old.IntentId==intent.IntentId and old.PurchaseId==nil then
    return {Status="Idle",Sequence=old.Sequence or 1}
   end
   return old
  end)
 end)
 return ok and (not active(value) or value.IntentId~=intent.IntentId)
end
function M.Prompt(player,itemId,expectedProductId)
 if not validPlayer(player) then return false,"InvalidPlayer" end
 local item,productId=M.ValidateItem(itemId,expectedProductId)
 if not item then return false,productId end
 if not Data.IsLoaded(player) then return false,"DataNotLoaded" end
 if Data.IsSaving(player) then return false,"DataSaving" end
 if busy[player] or prompts[player] then return false,"PurchaseInProgress" end
 busy[player]=true
 local ok,success,code=pcall(function()
  local intent={Status="Pending",PlayerId=player.UserId,ItemId=itemId,ExpectedProductId=productId,
   Timestamp=os.time(),IntentId=HttpService:GenerateGUID(false)}
  local saved=getStore():UpdateAsync(key(player),function(old)
   if active(old) then return old end
   -- Never overwrite malformed records and lose a potentially paid selection.
   if old~=nil and (typeof(old)~="table" or old.Status~="Idle") then return nil end
   local nextIntent=table.clone(intent)
   nextIntent.Sequence=(old and old.Sequence or 0)+1
   return nextIntent
  end)
  if not active(saved) or saved.IntentId~=intent.IntentId then return false,"PendingPurchaseExists" end
  if not validPlayer(player) or not Data.IsLoaded(player) then
   cancel(player,intent)
   return false,"PlayerUnavailable"
  end
  prompts[player]=intent
  local prompted=pcall(MarketplaceService.PromptProductPurchase,MarketplaceService,player,productId)
  if not prompted then
   prompts[player]=nil
   cancel(player,intent)
   return false,"PromptUnavailable"
  end
  return true,"PromptOpened"
 end)
 busy[player]=nil
 if not ok then return false,"PendingSaveFailed" end
 return success,code,productId
end
-- Claim a previously journaled selection for exactly one PurchaseId.
function M.ClaimPending(player,receipt,record)
 if not validPlayer(player) or player.UserId~=receipt.PlayerId or not Data.IsLoaded(player) then return false end
 if record.PlayerId~=receipt.PlayerId or record.ProductId~=receipt.ProductId then return false end
 if not M.ValidateItem(record.ItemId,receipt.ProductId) then return false end
 local ok,value=pcall(function()
  return getStore():UpdateAsync(key(player),function(old)
   if not active(old) or old.PlayerId~=receipt.PlayerId or old.IntentId~=record.IntentId
    or old.ItemId~=record.ItemId or old.ExpectedProductId~=receipt.ProductId then return nil end
   if old.PurchaseId~=nil and old.PurchaseId~=receipt.PurchaseId then return nil end
   local nextValue=table.clone(old)
   nextValue.PurchaseId=receipt.PurchaseId
   return nextValue
  end)
 end)
 return ok and active(value) and value.IntentId==record.IntentId and value.PurchaseId==receipt.PurchaseId
end
function M.Grant(player,receipt,record)
 if not M.ValidateItem(record.ItemId,receipt.ProductId) then return false end
 if record.PlayerId~=player.UserId or record.PlayerId~=receipt.PlayerId or record.ProductId~=receipt.ProductId then return false end
 return Data.GrantPurchasedItem(player,record.ItemId,receipt.PurchaseId,record.QuantityVersion,record.IntentSequence)
end
-- Called only after the shared receipt journal is durably Granted.
function M.Complete(player,receipt,record)
 local ok,value=pcall(function()
  return getStore():UpdateAsync(key(player),function(old)
   if not active(old) or old.IntentId~=record.IntentId then return old or {Status="Idle"} end
   if old.PurchaseId~=receipt.PurchaseId then return nil end
   return {Status="Idle",Sequence=old.Sequence or 1}
  end)
 end)
 if not ok or (active(value) and value.IntentId==record.IntentId) then return false end
 report(player,true,"Purchased",record.ItemId)
 return true
end
function M.OnPromptClosed(userId,productId,purchased)
 local player=Players:GetPlayerByUserId(userId)
 local intent=player and prompts[player]
 if not intent or intent.ExpectedProductId~=productId then return end
 prompts[player]=nil
 if purchased then
  -- A closed prompt is never proof of payment and never grants ownership.
  report(player,false,"AwaitingReceipt",intent.ItemId)
 else
  local cleared=cancel(player,intent)
  report(player,false,cleared and "Cancelled" or "AwaitingReceipt",intent.ItemId)
 end
end
MarketplaceService.PromptProductPurchaseFinished:Connect(M.OnPromptClosed)
Players.PlayerRemoving:Connect(function(player)
 busy[player]=nil
 prompts[player]=nil
 -- Durable pending selection remains available to the next server.
end)
return M

