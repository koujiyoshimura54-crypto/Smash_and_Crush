-- Phase 7.2.2: server inventory, Win purchases and single-slot equipment.
local Players = game:GetService("Players")
local Master = require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))
local Data = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Counts=require(game.ReplicatedStorage.Modules.InventoryCounts)
local M = {}
local busy = setmetatable({}, {__mode="k"})
local function finite(value)
 return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
function M.HasDumbbell(player, itemId)
 if typeof(itemId) ~= "string" then return false end
 local session = Data.Get(player)
 return session ~= nil and session.Loaded == true and (Counts.Count(session.Data.OwnedDumbbells[itemId]) or 0)>0
end
-- Return a copy, never the mutable session inventory. nil means not loaded.
function M.GetOwnedDumbbells(player)
 local session = Data.Get(player)
 if not session or not session.Loaded then return nil, "DataNotLoaded" end
 return Counts.Owned(session.Data.OwnedDumbbells)
end
-- One authoritative eligibility path for purchase, inventory UI and notifications.
local function purchaseEligibility(player, itemId)
 if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
  return false, "InvalidPlayer"
 end
 local item = Master.Get(itemId)
 if not item then return false, "InvalidItemId" end
 if item.Category ~= "Dumbbell" then return false, "InvalidCategory" end
 local session = Data.Get(player)
 if not session or not session.Loaded or not session.Data then return false, "DataNotLoaded" end
 -- Save reapplies its snapshot to Attributes. Do not advertise or accept a purchase until it finishes.
 if session.Saving then return false, "DataSaving" end
 if session.PendingItemMutation then return false, "InventorySavePending" end
 local owned = session.Data.OwnedDumbbells
 if typeof(owned) ~= "table" then return false, "InventoryUnavailable" end
 if (Counts.Count(owned[itemId]) or 0)>0 then return false, "AlreadyOwned" end
 if item.WorldId == 2 and not Data.HasReachedWorld2(player) then return false, "WorldNotReached" end
 local price = item.PriceWin
 if not finite(price) or price <= 0 or price % 1 ~= 0 then return false, "InvalidPrice" end
 local win = player:GetAttribute("Win")
 if not finite(win) or win < 0 or win % 1 ~= 0 then return false, "InvalidWin" end
 if win < price then return false, "NotEnoughWin" end
 return true, "Available", session, owned, price, win
end
function M.CanPurchaseDumbbell(player, itemId)
 local available, code = purchaseEligibility(player, itemId)
 return available, code
end
function M.GetPurchasableDumbbells(player)
 local session = Data.Get(player)
 if not session or not session.Loaded or not session.Data then return nil, "DataNotLoaded" end
 local result = {}
 for _, item in ipairs(Master.GetSorted()) do
  if purchaseEligibility(player, item.ItemId) then result[item.ItemId] = true end
 end
 return result
end
function M.PurchaseDumbbell(player, itemId)
 if busy[player] then return false, "PurchaseInProgress" end
 busy[player] = true
 local ok, success, result = pcall(function()
  local available, code, session, owned, price, win = purchaseEligibility(player, itemId)
  if not available then return false, code end
  if Master.Get(itemId).WorldId~=2 then
   local id=game.HttpService:GenerateGUID(false)
   return Data.MutateForge(player,{Action="BuyDumbbell",ItemId=itemId,Id=id,
    Sequence=session.Data.ForgeJournal.Sequence+1,Signature="BuyDumbbell|"..itemId,ResultId=itemId})
  end
  -- Existing World2 purchase path and prices are retained.
  -- No yields from validation through debit and ownership insertion.
  -- Reuse the existing Win setter; the Attribute remains the balance authority.
  if not Data.SetWin(player, win - price) then return false, "DataNotLoaded" end
  owned[itemId] = 1
  session.Dirty = true
  return true, "Purchased"
 end)
 busy[player] = nil
 if not ok then
  warn("Dumbbell purchase failed for " .. player.Name .. ": " .. tostring(success))
  return false, "PurchaseFailed"
 end
 return success, result
end
-- Return the equipped ItemId, or nil when unloaded/unequipped/invalid.
-- Never trust the replicated Attribute for gameplay or persistence.
function M.GetEquippedDumbbell(player)
 local session = Data.Get(player)
 if not session or not session.Loaded or not session.Data then return nil end
 local itemId = session.Data.EquippedDumbbell
 local item = Master.Get(itemId)
 if not item or item.Category ~= "Dumbbell" or (Counts.Count(session.Data.OwnedDumbbells[itemId]) or 0)<1 then return nil end
 return itemId
end
function M.GetStrengthBonus(player)
 local itemId = M.GetEquippedDumbbell(player)
 local item = itemId and Master.Get(itemId)
 local bonus = item and item.StrengthBonus
 return finite(bonus) and bonus >= 0 and bonus or 0
end
function M.EquipDumbbell(player, itemId)
 if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
  return false, "InvalidPlayer"
 end
 local item = Master.Get(itemId)
 if not item then return false, "InvalidItemId" end
 if item.Category ~= "Dumbbell" then return false, "InvalidCategory" end
 if busy[player] then return false, "PurchaseInProgress" end
 -- The data setter validates loaded/saving/ownership and is idempotent.
 -- No yield between validation and assignment; only one ItemId is stored.
 return Data.SetEquippedDumbbell(player, itemId)
end
function M.UnequipDumbbell(player)
 if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
  return false, "InvalidPlayer"
 end
 if busy[player] then return false, "PurchaseInProgress" end
 return Data.SetEquippedDumbbell(player, "")
end
function M.GetDumbbellCounts(player)
 local s=Data.Get(player)
 return s and s.Loaded and table.clone(s.Data.OwnedDumbbells) or nil
end
return M
