-- Phase 7.3.2: server-authoritative ownership and Win purchases for regular items.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemMaster = require(ReplicatedStorage.Config:WaitForChild("ItemMaster"))
local ItemMultiplierConfig = require(ReplicatedStorage.Config:WaitForChild("ItemMultiplierConfig"))
local Data = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Badges = require(game.ServerScriptService.Services:WaitForChild("BadgeAwardService"))
local ItemService = {}
local busy = setmetatable({}, {__mode="k"})
local transactions=setmetatable({}, {__mode="k"})

local function finiteInteger(value)
 return typeof(value)=="number" and value==value and value~=math.huge and value~=-math.huge and value%1==0
end

function ItemService.GetItemCount(player,itemId)
 if typeof(itemId)~="string" then return 0 end
 local s=Data.Get(player)
 if not s or not s.Loaded or not s.Data then return 0 end
 return s.Data.OwnedItems[itemId] or 0
end
function ItemService.HasItem(player,itemId)
 return ItemService.GetItemCount(player,itemId)>0
end
local function changeItem(player,itemId,amount,sign,transaction)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if not ItemMaster.Get(itemId) then return false,"InvalidItemId" end
 if not finiteInteger(amount) or amount<=0 or amount>9007199254740991 then return false,"InvalidAmount" end
 if transaction~=nil then
  local context=transactions[transaction]
  if not context or context.Player~=player then return false,"InvalidTransaction" end
  local delta=(context.Deltas[itemId] or 0)+amount*sign
  local count=ItemService.GetItemCount(player,itemId)+delta
  if count<0 then return false,"NotEnoughItems" end
  if count>9007199254740991 then return false,"CountOverflow" end
  context.Deltas[itemId]=delta~=0 and delta or nil
  return true,"Staged"
 end
 return Data.ChangeItemCount(player,itemId,amount*sign)
end
function ItemService.AddItem(player,itemId,amount,transaction) return changeItem(player,itemId,amount,1,transaction) end
function ItemService.NotifyRegularItemGranted(player,itemId)
 local item=ItemMaster.Get(itemId)
 if item and item.Rarity=="Legendary" then Badges.Award(player,"FirstLegendary") end
end
function ItemService.RemoveItem(player,itemId,amount,transaction) return changeItem(player,itemId,amount,-1,transaction) end

-- Server-only batch scope. Existing AddItem/RemoveItem calls stage their changes
-- when passed this private token; nothing is consumed until the batch commits.
function ItemService.RunItemTransaction(player,callback,timeReward)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(callback)~="function" then return false,"InvalidTransaction" end
 local token={}
 local context={Player=player,Deltas={}}
 transactions[token]=context
 local ok,success,code=pcall(callback,token)
 transactions[token]=nil
 if not ok then return false,"TransactionFailed" end
 if not success then return false,code end
 local changed,reason=Data.ChangeItemCounts(player,context.Deltas,timeReward)
 if changed and timeReward and timeReward.ItemGrantSource then
  for itemId,delta in pairs(context.Deltas) do if delta>0 then ItemService.NotifyRegularItemGranted(player,itemId) end end
 end
 return changed,reason
end

function ItemService.GetOwnedItems(player)
 local session=Data.Get(player)
 if not session or not session.Loaded or not session.Data then return nil,"DataNotLoaded" end
 if typeof(session.Data.OwnedItems)~="table" then return nil,"InventoryUnavailable" end
 return table.clone(session.Data.OwnedItems)
end

function ItemService.PurchaseItemWithWin(player,itemId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then
  return false,"InvalidPlayer"
 end
 local item=ItemMaster.Get(itemId)
 if not item then return false,"InvalidItemId" end
 if item.ShopPurchasable~=true then return false,"NotWinPurchasable" end
 local price=item.WinPrice
 if not finiteInteger(price) or price<=0 then return false,"InvalidPrice" end
 if busy[player] then return false,"PurchaseInProgress" end
 busy[player]=true
 local ok,success,code=pcall(function()
  local session=Data.Get(player)
  if not session or not session.Loaded or not session.Data then return false,"DataNotLoaded" end
  if session.Saving then return false,"DataSaving" end
  local owned=session.Data.OwnedItems
  if typeof(owned)~="table" then return false,"InventoryUnavailable" end
  local win=player:GetAttribute("Win")
  if not finiteInteger(win) or win<0 then return false,"InvalidWin" end
  if win<price then return false,"NotEnoughWin" end
  local changed,reason=Data.ChangeItemCount(player,itemId,1,price)
  if not changed then return false,reason end
  ItemService.NotifyRegularItemGranted(player,itemId)
  return true,"Purchased"
 end)
 busy[player]=nil
 if not ok then
  warn("Item purchase failed for "..player.Name..": "..tostring(success))
  return false,"PurchaseFailed"
 end
 return success,code
end

-- Phase 7.3.3: regular items have independent, server-owned type slots.
local slots={}
for _,kind in ipairs(ItemMaster.Kinds) do slots[kind]=true end
local function equipmentSession(player)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then
  return nil,"InvalidPlayer"
 end
 local s=Data.Get(player)
 if not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 if typeof(s.Data.OwnedItems)~="table" or typeof(s.Data.EquippedItems)~="table" then
  return nil,"InventoryUnavailable"
 end
 return s
end
function ItemService.GetEquippedItems(player)
 local s,code=equipmentSession(player)
 if not s then return nil,code end
 return table.clone(s.Data.EquippedItems)
end
function ItemService.EquipItem(player,itemId)
 local item=ItemMaster.Get(itemId)
 if not item then return false,"InvalidItemId" end
 if not slots[item.ItemType] then return false,"InvalidItemType" end
 local s,code=equipmentSession(player)
 if not s then return false,code end
 if s.Saving then return false,"DataSaving" end
 if ItemService.GetItemCount(player,itemId)<1 then return false,"NotOwned" end
 if s.Data.EquippedItems[item.ItemType]==itemId then return true,"AlreadyEquipped" end
 -- No yield: only this type's slot is replaced; ownership is retained.
 s.Data.EquippedItems[item.ItemType]=itemId
 s.Dirty=true
 return true,"Equipped"
end
-- Best Equip only selects IDs; ownership, slot replacement and dirty tracking
-- remain in EquipItem. No yield occurs until all three slots are processed.
local rarityRank=ItemMaster.RarityRank
local bestSlotOrder=ItemMaster.Kinds
function ItemService.EquipBestItems(player)
 local s,code=equipmentSession(player)
 if not s then return false,code end
 if s.Saving then return false,"DataSaving" end
 if s.PendingItemMutation then return false,"InventoryBusy" end
 local selected,ranks={},{}
 for id,count in pairs(s.Data.OwnedItems) do
  local item=ItemMaster.Get(id)
  local rank=item and rarityRank[item.Rarity]
  if item and slots[item.ItemType] and rank and finiteInteger(count) and count>0 then
   local kind=item.ItemType
   if not ranks[kind] or rank>ranks[kind]
    or (rank==ranks[kind] and id<selected[kind]) then
    selected[kind],ranks[kind]=id,rank
   end
  end
 end
 local changed=false
 for _,kind in ipairs(bestSlotOrder) do
  local id=selected[kind]
  if id then
   local current=s.Data.EquippedItems[kind]
   local item=ItemMaster.Get(current)
   if item and item.ItemType==kind and rarityRank[item.Rarity]==ranks[kind]
    and ItemService.HasItem(player,current) then
    id=current
   end
   local success,reason=ItemService.EquipItem(player,id)
   if not success then return false,reason end
   if reason=="Equipped" then changed=true end
  end
 end
 -- EquipItem already marks changed slots Dirty. Match manual Equip:
 -- reply immediately; periodic/leave/shutdown saves persist EquippedItems.
 return true,changed and "BestEquipped" or "AlreadyBestEquipped"
end

function ItemService.UnequipItem(player,itemType)
 if typeof(itemType)~="string" or not slots[itemType] then return false,"InvalidItemType" end
 local s,code=equipmentSession(player)
 if not s then return false,code end
 if s.Saving then return false,"DataSaving" end
 s.Data.EquippedItems[itemType]=""
 s.Dirty=true
 return true,"Unequipped"
end
-- All effects use the existing owned, type-matched equipped slot.
local function getEquippedRarity(player, itemType)
 local s=equipmentSession(player)
 if not s then return nil end
 local id=s.Data.EquippedItems[itemType]
 local item=ItemMaster.Get(id)
 if item and item.ItemType==itemType and ItemService.GetItemCount(player,id)>0 then
  return item.Rarity
 end
 return nil
end
function ItemService.GetProteinBonus(player)
 return ItemMultiplierConfig.GetProteinBonus(getEquippedRarity(player,"Protein"))
end
function ItemService.GetGloveBossDamageBonus(player)
 return ItemMultiplierConfig.GetGloveBossDamageBonus(getEquippedRarity(player,"Glove"))
end
function ItemService.GetBeltTreadmillBonus(player)
 return ItemMultiplierConfig.GetBeltTreadmillBonus(getEquippedRarity(player,"TrainingBelt"))
end

return ItemService
