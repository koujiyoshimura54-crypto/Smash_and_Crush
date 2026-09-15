-- Phase 7.2.2: the client supplies only an ItemId; all decisions are server-side.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Service = require(game.ServerScriptService.Services:WaitForChild("DumbbellService"))
local remote = RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equipRemote = RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote = RS.Remotes:WaitForChild("DumbbellInventoryState")
local lastRequest = setmetatable({}, {__mode="k"})
local function getInventoryState(player)
 local owned = Service.GetOwnedDumbbells(player)
 return {
  Loaded = owned ~= nil,
  OwnedDumbbells = owned or {},
  EquippedDumbbell = Service.GetEquippedDumbbell(player) or "",
  Win = player:GetAttribute("Win") or 0,
 }
end
stateRemote.OnServerInvoke = getInventoryState
remote.OnServerEvent:Connect(function(player, itemId)
 local now = os.clock()
 if lastRequest[player] and now - lastRequest[player] < 0.2 then return end
 lastRequest[player] = now
 local success, code = Service.PurchaseDumbbell(player, itemId)
 if success then
  -- PurchaseDumbbell has completed and released its transaction lock.
  -- Reuse the existing authoritative equip path so every newly bought
  -- Dumbbell replaces the current single-slot equipment immediately.
  success, code = Service.EquipDumbbell(player, itemId)
 end
 if player.Parent == Players then
  remote:FireClient(player, {
   Success = success,
   Code = code,
   ItemId = typeof(itemId) == "string" and #itemId <= 128 and itemId or nil,
   State = getInventoryState(player),
  })
 end
end)
local lastEquipRequest = setmetatable({}, {__mode="k"})
equipRemote.OnServerEvent:Connect(function(player, itemId)
 local now = os.clock()
 if lastEquipRequest[player] and now - lastEquipRequest[player] < 0.2 then return end
 lastEquipRequest[player] = now
 local success, code
 -- Empty string is the explicit unequip request; all other values are ItemIds.
 if itemId == "" then
  success, code = Service.UnequipDumbbell(player)
 else
  success, code = Service.EquipDumbbell(player, itemId)
 end
 if player.Parent == Players then
  equipRemote:FireClient(player, {
   Success = success,
   Code = code,
   EquippedDumbbell = Service.GetEquippedDumbbell(player) or "",
   State = getInventoryState(player),
  })
 end
end)
Players.PlayerRemoving:Connect(function(player)
 lastRequest[player] = nil
 lastEquipRequest[player] = nil
end)

