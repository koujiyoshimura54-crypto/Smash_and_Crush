-- Phase 7.3.2: Remote bridge for regular item state and Win purchases.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Service=require(game.ServerScriptService.Services:WaitForChild("ItemService"))
local purchaseRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local lastEquipRequest=setmetatable({}, {__mode="k"})
local lastRequest=setmetatable({}, {__mode="k"})

local function getState(player)
 local owned=Service.GetOwnedItems(player)
 return {
  Loaded=owned~=nil,
  OwnedItems=owned or {},
  EquippedItems=Service.GetEquippedItems(player) or {},
  Win=player:GetAttribute("Win") or 0,
 }
end

stateRemote.OnServerInvoke=getState
purchaseRemote.OnServerEvent:Connect(function(player,itemId)
 local now=os.clock()
 local success,code
 if lastRequest[player] and now-lastRequest[player]<0.2 then
  success,code=false,"RateLimited"
 else
  lastRequest[player]=now
  success,code=Service.PurchaseItemWithWin(player,itemId)
 end
 if player.Parent==Players then
  purchaseRemote:FireClient(player,{
   Success=success,
   Code=code,
   ItemId=typeof(itemId)=="string" and #itemId<=128 and itemId or nil,
   State=getState(player),
  })
 end
end)
Players.PlayerRemoving:Connect(function(player) lastRequest[player]=nil end)

-- Equip: FireServer(itemId). Unequip: FireServer(itemType, "Unequip").
equipRemote.OnServerEvent:Connect(function(player,value,action)
 local now=os.clock()
 local success,code
 local cooldown=action=="BestEquip" and 1 or 0.2
 if lastEquipRequest[player] and now-lastEquipRequest[player]<cooldown then
  success,code=false,"RateLimited"
 else
  lastEquipRequest[player]=now
  if action==nil or action=="Equip" then
   success,code=Service.EquipItem(player,value)
  elseif action=="BestEquip" then
   if value~=nil then success,code=false,"InvalidRequest"
   else success,code=Service.EquipBestItems(player) end
  elseif action=="Unequip" then
   success,code=Service.UnequipItem(player,value)
  else
   success,code=false,"InvalidAction"
  end
 end
 if player.Parent==Players then
  equipRemote:FireClient(player,{Success=success,Code=code,Action=action,State=getState(player)})
 end
end)
Players.PlayerRemoving:Connect(function(player) lastEquipRequest[player]=nil end)

-- Fixed Robux item purchases. The server records the choice before prompting.
local robuxRemote=RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")
local Purchases=require(game.ServerScriptService.Systems.Purchases.ItemPurchaseService)
local lastRobuxRequest=setmetatable({}, {__mode="k"})
local function robuxReply(player,success,code,itemId)
 if player.Parent==Players then
  robuxRemote:FireClient(player,{Success=success,Code=code,ItemId=itemId,State=getState(player)})
 end
end
Purchases.SetNotifier(robuxReply)
robuxRemote.OnServerEvent:Connect(function(player,itemId,expectedProductId)
 local now=os.clock()
 if lastRobuxRequest[player] and now-lastRobuxRequest[player]<0.5 then
  robuxReply(player,false,"RateLimited")
  return
 end
 lastRobuxRequest[player]=now
 local success,code=Purchases.Prompt(player,itemId,expectedProductId)
 robuxReply(player,success,code,typeof(itemId)=="string" and #itemId<=128 and itemId or nil)
end)
Players.PlayerRemoving:Connect(function(player) lastRobuxRequest[player]=nil end)
