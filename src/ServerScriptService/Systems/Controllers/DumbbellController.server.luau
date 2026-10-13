-- Inventory and server-detected stands share the existing purchase/equip authority.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Service = require(game.ServerScriptService.Services:WaitForChild("DumbbellService"))
local Stand = require(game.ServerScriptService.Services:WaitForChild("DumbbellStandService"))
local remote = RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equipRemote = RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote = RS.Remotes:WaitForChild("DumbbellInventoryState")
local lastRequest = setmetatable({}, {__mode="k"})
local lastEquipRequest = setmetatable({}, {__mode="k"})
local inFlight = setmetatable({}, {__mode="k"})
local function getInventoryState(player)
 local owned = Service.GetOwnedDumbbells(player)
 local purchasable = Service.GetPurchasableDumbbells(player)
 return {
  Loaded = owned ~= nil and purchasable ~= nil,
  OwnedDumbbells = owned or {}, PurchasableDumbbells = purchasable or {},
  EquippedDumbbell = Service.GetEquippedDumbbell(player) or "",
  Win = player:GetAttribute("Win") or 0,
 }
end
local function respond(target, player, itemId, success, code, source)
 if player.Parent ~= Players then return end
 target:FireClient(player, {
  Success = success, Code = code,
  ItemId = typeof(itemId) == "string" and #itemId <= 128 and itemId or nil,
  State = getInventoryState(player), Source = source,
 })
end
local function execute(player, itemId, isEquip, isStand)
 if inFlight[player] then return false, "PurchaseInProgress" end
 inFlight[player] = true
 local ok, success, code = pcall(function()
  if isStand and Service.GetEquippedDumbbell(player) == itemId then return true, "AlreadyEquipped" end
  if isEquip or (isStand and Service.HasDumbbell(player, itemId)) then
   if itemId == "" and not isStand then return Service.UnequipDumbbell(player) end
   return Service.EquipDumbbell(player, itemId)
  end
  local bought, reason = Service.PurchaseDumbbell(player, itemId)
  if not bought then return false, reason end
  return Service.EquipDumbbell(player, itemId)
 end)
 inFlight[player] = nil
 if not ok then
  warn("[DumbbellController] Request failed: " .. tostring(success))
  return false, "PurchaseFailed"
 end
 return success, code
end
local function inventory(target, player, itemId, context, isEquip)
 -- The former client stand protocol is no longer an equipment entrance.
 if context ~= nil then respond(target, player, itemId, false, "InvalidStandRequest"); return end
 if inFlight[player] then respond(target, player, itemId, false, "PurchaseInProgress"); return end
 local now = os.clock()
 local last = isEquip and lastEquipRequest or lastRequest
 if last[player] and now - last[player] < 0.2 then
  respond(target, player, itemId, false, "RateLimited"); return
 end
 last[player] = now
 local success, code = execute(player, itemId, isEquip, false)
 respond(target, player, itemId, success, code)
end
stateRemote.OnServerInvoke = getInventoryState
remote.OnServerEvent:Connect(function(player, itemId, context)
 inventory(remote, player, itemId, context, false)
end)
equipRemote.OnServerEvent:Connect(function(player, itemId, context)
 inventory(equipRemote, player, itemId, context, true)
end)
Stand.Start(function(player, itemId)
 if not Service.GetOwnedDumbbells(player) then return false end
 local success, code = execute(player, itemId, false, true)
 if not success and (code == "DataNotLoaded" or code == "DataSaving"
  or code == "InventorySavePending" or code == "PurchaseInProgress") then return false end
 if code ~= "AlreadyEquipped" then respond(remote, player, itemId, success, code, "DumbbellStand") end
 return true
end)
Players.PlayerRemoving:Connect(function(player)
 lastRequest[player] = nil; lastEquipRequest[player] = nil; inFlight[player] = nil
end)
