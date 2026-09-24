local engineTypeof=typeof
local function typeof(v) if type(v)=="table" and v.IsTestPlayer then return "Instance" end return engineTypeof(v) end
-- Phase 7.2.2: server inventory, Win purchases and single-slot equipment.
local Players = require(script.Parent.Runtime).Players
local Master = require(script.Parent.DumbbellItemMaster)
local Data = require(script.Parent:WaitForChild("PlayerDataService"))
local M = {}
local busy = setmetatable({}, {__mode="k"})
local function finite(value)
 return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end
function M.HasDumbbell(player, itemId)
 if typeof(itemId) ~= "string" then return false end
 local session = Data.Get(player)
 return session ~= nil and session.Loaded == true and session.Data.OwnedDumbbells[itemId] == true
end
-- Return a copy, never the mutable session inventory. nil means not loaded.
function M.GetOwnedDumbbells(player)
 local session = Data.Get(player)
 if not session or not session.Loaded then return nil, "DataNotLoaded" end
 return table.clone(session.Data.OwnedDumbbells)
end
function M.PurchaseDumbbell(player, itemId)
 if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
  return false, "InvalidPlayer"
 end
 local item = Master.Get(itemId)
 if not item then return false, "InvalidItemId" end
 if item.Category ~= "Dumbbell" then return false, "InvalidCategory" end
 if busy[player] then return false, "PurchaseInProgress" end
 busy[player] = true
 local ok, success, result = pcall(function()
  local session = Data.Get(player)
  if not session or not session.Loaded or not session.Data then return false, "DataNotLoaded" end
  -- Save reapplies its snapshot to Attributes. Do not purchase until it finishes.
  if session.Saving then return false, "DataSaving" end
  local owned = session.Data.OwnedDumbbells
  if typeof(owned) ~= "table" then return false, "InventoryUnavailable" end
  if owned[itemId] == true then return false, "AlreadyOwned" end
  local price = item.PriceWin
  if not finite(price) or price <= 0 or price % 1 ~= 0 then return false, "InvalidPrice" end
  local win = player:GetAttribute("Win")
  if not finite(win) or win < 0 or win % 1 ~= 0 then return false, "InvalidWin" end
  if win < price then return false, "NotEnoughWin" end
  -- No yields from validation through debit and ownership insertion.
  -- Reuse the existing Win setter; the Attribute remains the balance authority.
  if not Data.SetWin(player, win - price) then return false, "DataNotLoaded" end
  owned[itemId] = true
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
 if not item or item.Category ~= "Dumbbell" or session.Data.OwnedDumbbells[itemId] ~= true then return nil end
 return itemId
end
function M.GetStrengthMultiplier(player)
 local itemId = M.GetEquippedDumbbell(player)
 local item = itemId and Master.Get(itemId)
 local multiplier = item and item.StrengthMultiplier
 return finite(multiplier) and multiplier > 0 and multiplier or 1
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
return M
