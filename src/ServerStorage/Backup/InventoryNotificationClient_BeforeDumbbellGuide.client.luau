-- Session-only unseen Gacha items; the server sends ITEM only after AddItem succeeds.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local gui=script.Parent
local badge=gui:WaitForChild("LeftMenu"):WaitForChild("InventoryButton"):WaitForChild("NotificationBadge")
local panel=gui:WaitForChild("InventoryPanel")
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local HasUnseenItem=false
local seen={}
local function setUnseen(value)
 HasUnseenItem=value
 badge.Visible=HasUnseenItem
end
setUnseen(false)
local visibility=panel:GetPropertyChangedSignal("Visible"):Connect(function()
 if panel.Visible then setUnseen(false) end
end)
local notification=remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId
  or result.Outcome~="ITEM" or typeof(result.Id)~="string"
  or seen[result.Id] or not Master.Get(result.ItemId) then return end
 seen[result.Id]=true
 -- Items received while Inventory is open are already being viewed.
 setUnseen(not panel.Visible)
end)
script.Destroying:Once(function()
 visibility:Disconnect()
 notification:Disconnect()
end)
