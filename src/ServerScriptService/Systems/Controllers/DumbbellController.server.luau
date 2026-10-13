-- Existing Inventory and purchased Press stations share one Dumbbell authority.
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
  OwnedDumbbells = owned or {},
  PurchasableDumbbells = purchasable or {},
  EquippedDumbbell = Service.GetEquippedDumbbell(player) or "",
  Win = player:GetAttribute("Win") or 0,
 }
end
local function respond(target, player, itemId, context, success, code)
 if player.Parent ~= Players then return end
 local tagged = typeof(context) == "table" and context.Source == "DumbbellStand"
 target:FireClient(player, {
  Success = success,
  Code = code,
  ItemId = typeof(itemId) == "string" and #itemId <= 128 and itemId or nil,
  State = getInventoryState(player),
  Source = tagged and "DumbbellStand" or nil,
  RequestId = tagged and typeof(context.RequestId) == "string" and #context.RequestId <= 64 and context.RequestId or nil,
 })
end
local function handle(target, player, itemId, context, isEquip)
 local standRequest = context ~= nil
 if inFlight[player] then
  respond(target, player, itemId, context, false, "PurchaseInProgress")
  return
 end
 if standRequest then
  local allowed, code = Stand.Validate(player, itemId, context)
  if not allowed then respond(target, player, itemId, context, false, code); return end
 end
 local now = os.clock()
 local last = isEquip and lastEquipRequest or lastRequest
 if last[player] and now - last[player] < 0.2 then
  respond(target, player, itemId, context, false, "RateLimited")
  return
 end
 last[player] = now
 inFlight[player] = true
 local ok, success, code = pcall(function()
  -- Resolve ownership again on the server, including a recent Inventory purchase.
  if standRequest and Service.GetEquippedDumbbell(player) == itemId then return true, "AlreadyEquipped" end
  if isEquip or (standRequest and Service.HasDumbbell(player, itemId)) then
   if itemId == "" and not standRequest then return Service.UnequipDumbbell(player) end
   return Service.EquipDumbbell(player, itemId)
  end
  local bought, reason = Service.PurchaseDumbbell(player, itemId)
  if not bought then return false, reason end
  -- Preserve the existing purchase -> single-slot automatic equip contract.
  return Service.EquipDumbbell(player, itemId)
 end)
 inFlight[player] = nil
 if not ok then
  warn("[DumbbellController] Request failed: " .. tostring(success))
  success, code = false, "PurchaseFailed"
 end
 respond(target, player, itemId, context, success, code)
end
stateRemote.OnServerInvoke = getInventoryState
Stand.Start()
remote.OnServerEvent:Connect(function(player, itemId, context)
 handle(remote, player, itemId, context, false)
end)
equipRemote.OnServerEvent:Connect(function(player, itemId, context)
 handle(equipRemote, player, itemId, context, true)
end)
Players.PlayerRemoving:Connect(function(player)
 lastRequest[player] = nil
 lastEquipRequest[player] = nil
 inFlight[player] = nil
end)
