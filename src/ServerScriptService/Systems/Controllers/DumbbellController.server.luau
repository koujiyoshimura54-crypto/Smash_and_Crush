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
local seenRequests = setmetatable({}, {__mode="k"})
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
 -- Cancel only this player's matching waiting operation; cancellation never grants entry.
 if typeof(context) == "table" and context.Source == "DumbbellStand" and context.Action == "Cancel" then
  local operation = inFlight[player]
  if operation and operation.Phase == "Waiting" and operation.RequestId == context.RequestId then
   operation.Cancelled = true
   if inFlight[player] == operation then inFlight[player] = nil end
  end
  respond(target, player, itemId, context, false, "StandCancelled")
  return
 end
 if standRequest then
  local valid, code = Stand.CheckRequest(itemId, context)
  if not valid then respond(target, player, itemId, context, false, code); return end
 end
 if inFlight[player] then
  if standRequest and inFlight[player].RequestId == context.RequestId then return end
  respond(target, player, itemId, context, false, "PurchaseInProgress")
  return
 end
 if standRequest then
  local seen = seenRequests[player]
  if seen and seen[context.RequestId] then
   respond(target, player, itemId, context, false, "StandReentryRequired")
   return
  end
 end
 local now = os.clock()
 local last = isEquip and lastEquipRequest or lastRequest
 if last[player] and now - last[player] < 0.2 then
  respond(target, player, itemId, context, false, "RateLimited")
  return
 end
 last[player] = now
 local operation = {RequestId = standRequest and context.RequestId or nil,
  Character = player.Character, Phase = standRequest and "Waiting" or "Executing"}
 inFlight[player] = operation -- Acquire before the first possible wait, including Inventory operations.
 if standRequest then
  local seen = seenRequests[player] or {}; seenRequests[player] = seen
  seen[context.RequestId] = true -- Keep accepted IDs until disconnect, including cancelled/expired entries.
 end
 local ok, success, code = pcall(function()
  if standRequest then
   local allowed, reason = Stand.AwaitEntry(player, itemId, context, operation,
    function() return inFlight[player] == operation end)
   if not allowed then return false, reason end
  end
  operation.Phase = "Executing"
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
 if inFlight[player] == operation then inFlight[player] = nil end
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
 local operation = inFlight[player]
 if operation then operation.Cancelled = true end
 inFlight[player] = nil
 seenRequests[player] = nil
end)
