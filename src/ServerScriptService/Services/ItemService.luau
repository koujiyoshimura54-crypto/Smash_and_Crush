-- Phase 7.3.2: server-authoritative ownership and Win purchases for regular items.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemMaster = require(ReplicatedStorage.Config:WaitForChild("ItemMaster"))
local ElementSetBonus = require(ReplicatedStorage.Modules:WaitForChild("ElementSetBonus"))
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
  if item.WorldId==2 and not Data.HasReachedWorld2(player) then return false,"WorldNotReached" end
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
 if s.Data.EquippedItems[item.ItemType]==itemId then Data.RefreshEquipmentTutorial(player);return true,"AlreadyEquipped" end
 -- No yield: only this type's slot is replaced; ownership is retained.
 s.Data.EquippedItems[item.ItemType]=itemId
 s.Dirty=true
 Data.RefreshEquipmentTutorial(player)
 return true,"Equipped"
end
-- Score combinations using one read-only training snapshot. A lower-effect Item
-- of the same type/element cannot beat a higher one, so retain only that frontier.
-- Duplicate units never create extra candidates. Equal candidates prefer current IDs.
function ItemService.EquipBestItems(player)
 local s,code=equipmentSession(player)
 if not s then return false,code end
 if s.Saving then return false,"DataSaving" end
 if s.PendingItemMutation then return false,"InventoryBusy" end
 -- Lazy require avoids the ItemService/StrengthReference initialization cycle.
 local Reference=require(script.Parent.StrengthReference)
 local components,candidates=Reference.GetContext(player,true)
 if not components then return false,candidates end
 local owned,current=s.Data.OwnedItems,s.Data.EquippedItems
 local pools,selected={},{}
 for _,kind in ipairs(ItemMaster.Kinds) do
  local byElement={}
  for id,count in pairs(owned) do
   local item=ItemMaster.Get(id)
   if item and item.ItemType==kind and finiteInteger(count) and count>0 then
    local key=item.Element
    local prior=byElement[key]
    local value=ElementSetBonus.GetBaseEffect(item)
    local old=prior and ElementSetBonus.GetBaseEffect(ItemMaster.Get(prior))
    if not prior or value>old or (value==old and
     (id==current[kind] or (prior~=current[kind] and id<prior))) then byElement[key]=id end
   end
  end
  local pool={}
  for _,id in pairs(byElement) do table.insert(pool,id) end
  table.sort(pool)
  if #pool==0 then pool[1]="" end
  pools[kind]=pool
  local item=ItemMaster.Get(current[kind])
  selected[kind]=item and item.ItemType==kind and (owned[current[kind]] or 0)>0 and current[kind] or ""
 end
 local function score(equipped)
  local effects=ElementSetBonus.GetEffects(owned,equipped)
  local rate=Reference.Calculate(components,candidates,effects)
  local changes=0
  for _,kind in ipairs(ItemMaster.Kinds) do if (current[kind] or "")~=equipped[kind] then changes+=1 end end
  return rate,effects.Glove,changes
 end
 local bestRate,bestDamage,bestChanges=score(selected)
 local function equal(a,b) return math.abs(a-b)<=1e-12*math.max(1,math.abs(a),math.abs(b)) end
 for _,protein in ipairs(pools.Protein) do
  for _,glove in ipairs(pools.Glove) do
   for _,belt in ipairs(pools.TrainingBelt) do
    local equipment={Protein=protein,Glove=glove,TrainingBelt=belt}
    local rate,damage,changes=score(equipment)
    local tied=equal(rate,bestRate)
    if (not tied and rate>bestRate) or (tied and
     ((not equal(damage,bestDamage) and damage>bestDamage) or
      (equal(damage,bestDamage) and changes<bestChanges))) then
     selected,bestRate,bestDamage,bestChanges=equipment,rate,damage,changes
    end
   end
  end
 end
 local changed=false
 -- EquipItem's existing owned/type rules are unchanged. No yield between slots.
 for _,kind in ipairs(ItemMaster.Kinds) do
  local id=selected[kind]
  if id~="" then
   local ok,reason=ItemService.EquipItem(player,id)
   if not ok then return false,reason end
   changed=changed or reason=="Equipped"
  end
 end
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
-- One effective Item calculation for training, Boss damage and references.
function ItemService.GetEffectiveEffects(player)
 local s=equipmentSession(player)
 return ElementSetBonus.GetEffects(s and s.Data.OwnedItems,s and s.Data.EquippedItems)
end
function ItemService.GetProteinBonus(player) return ItemService.GetEffectiveEffects(player).Protein end
function ItemService.GetGloveBossDamageBonus(player) return ItemService.GetEffectiveEffects(player).Glove end
function ItemService.GetBeltTreadmillBonus(player) return ItemService.GetEffectiveEffects(player).TrainingBelt end
function ItemService.GetEquippedElementSet(player)
 local s=equipmentSession(player)
 if not s then return nil end
 return ElementSetBonus.GetMatchingElement(s.Data.OwnedItems,s.Data.EquippedItems)
end
function ItemService.GetElementSetMultiplier(player)
 local s=equipmentSession(player)
 if not s then return 1 end
 return ElementSetBonus.GetMultiplier(s.Data.OwnedItems,s.Data.EquippedItems)
end

return ItemService
