-- Persistent, tab-scoped seen notifications. Ownership remains server-authoritative.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Badges=require(RS.Modules:WaitForChild("BadgeRenderer"))
local NotificationState=require(RS.Modules:WaitForChild("InventoryNotificationState"))
local player=Players.LocalPlayer
local gui=script.Parent
local badge=gui:WaitForChild("LeftMenu"):WaitForChild("InventoryButton"):WaitForChild("NotificationBadge")
local panel=gui:WaitForChild("InventoryPanel")
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local purchase=RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equip=RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote=RS.Remotes:WaitForChild("DumbbellInventoryState")
local itemStateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local Dumbbells=require(RS.Config:WaitForChild("DumbbellItemMaster"))
local ids={}
for _,item in ipairs(Dumbbells.GetSorted()) do
 if item.Category=="Dumbbell" then table.insert(ids,item.ItemId) end
end
local seenResults={}
local owned
local itemOwned={}
local affordable={}
local pending={}
local badges={}
local connections={}
local alive=true
local revision=0

-- Item guidance lives only on this client's Items page; keys are existing Item IDs.
local content=panel:WaitForChild("Content")
local itemPage=content:WaitForChild("Items")
local dumbbellPage=content:WaitForChild("Dumbbells")
local dumbbellList=dumbbellPage:WaitForChild("Items")
local itemTab=panel:WaitForChild("Tabs"):WaitForChild("Items")
local itemTabUnseen=false
local checkVisibleBuyNotifications
local function guideBadge(parent)
 local b=Badges.GetOrClone(badge,parent,"NotificationBadge")
 b.AnchorPoint=Vector2.new(1,0)
 b.Size=UDim2.fromOffset(24,24)
 b.Position=UDim2.new(1,-2,0,2)
 b.BackgroundColor3=Color3.fromRGB(235,55,65)
 b.BackgroundTransparency=0
 b.ZIndex=parent.ZIndex+2
 local corner=b:FindFirstChildOfClass("UICorner")
 if corner then corner.CornerRadius=UDim.new(.5,0) end
 local t=b:FindFirstChild("TextLabel")
 if t then t.Text="!";t.TextColor3=Color3.new(1,1,1);t.ZIndex=b.ZIndex+1 end
 return b
end
local itemTabBadge=guideBadge(itemTab)
local dumbbellTabBadge=guideBadge(panel.Tabs:WaitForChild("Dumbbells"))

local function render()
 local hasNew=false
 for _,id in ids do
  local canPurchase=affordable[id]==true
  local tabNew=canPurchase and not NotificationState.IsSeen("Dumbbells",id)
  local buyNew=canPurchase and not NotificationState.IsSeen("DumbbellBuy",id)
  hasNew=hasNew or tabNew
  local b=badges[id]
  if b then Badges.SetVisible(b,buyNew) end
 end
 itemTabUnseen=false
 for id,count in pairs(itemOwned) do
  if count>0 and not NotificationState.IsSeen("Items",id) then itemTabUnseen=true;break end
 end
 badge.Parent:SetAttribute("DumbbellNewAvailable",hasNew)
 badge.Parent:SetAttribute("ItemNewAvailable",itemTabUnseen)
 badge.Visible=hasNew or itemTabUnseen or badge.Parent:GetAttribute("AuraPurchaseAvailable")==true or badge.Parent:GetAttribute("SpeedPurchaseAvailable")==true
 Badges.SetVisible(itemTabBadge,itemTabUnseen)
 Badges.SetVisible(dumbbellTabBadge,hasNew)
 if checkVisibleBuyNotifications then task.defer(checkVisibleBuyNotifications) end
end
table.insert(connections,badge.Parent:GetAttributeChangedSignal("AuraPurchaseAvailable"):Connect(render))
table.insert(connections,badge.Parent:GetAttributeChangedSignal("SpeedPurchaseAvailable"):Connect(render))
local function evaluate(purchasable)
 if not owned then render();return end
 for _,id in ids do
  affordable[id]=purchasable[id]==true
  if owned[id]==true then pending[id]=nil end
 end
 render()
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedDumbbells)~="table"
  or typeof(state.PurchasableDumbbells)~="table" then return false end
 revision+=1
 owned=state.OwnedDumbbells
 evaluate(state.PurchasableDumbbells)
 return true
end
local function refresh()
 local version=revision
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if alive and version==revision and ok then return applyState(state) end
 return owned~=nil
end
local function acquired(itemId)
 local item=Master.Get(itemId)
 if not item then return end
 itemOwned[itemId]=math.max(1,itemOwned[itemId] or 0)
 if panel.Visible and itemPage.Visible then
  NotificationState.MarkSeen("Items",{itemId})
 else
  itemPage:SetAttribute("UnseenItem_"..itemId,true)
  itemPage:SetAttribute("UnseenRarity_"..item.Rarity,true)
 end
 render()
end
local function currentItemIds()
 local out={}
 for id,count in pairs(itemOwned) do if count>0 then table.insert(out,id) end end
 return out
end
local function currentDumbbellIds()
 local out={}
 for _,id in ipairs(ids) do if affordable[id] then table.insert(out,id) end end
 return out
end
local function itemsOpened()
 if panel.Visible and itemPage.Visible then
  NotificationState.MarkSeen("Items",currentItemIds())
  for id in pairs(itemOwned) do itemPage:SetAttribute("UnseenItem_"..id,nil) end
  for _,rarity in ipairs({"Common","Uncommon","Rare","Epic","Legendary"}) do itemPage:SetAttribute("UnseenRarity_"..rarity,nil) end
 end
 render()
end
table.insert(connections,itemPage:GetPropertyChangedSignal("Visible"):Connect(itemsOpened))
table.insert(connections,panel:GetPropertyChangedSignal("Visible"):Connect(itemsOpened))
table.insert(connections,RS.Remotes:WaitForChild("ItemEquipRequest").OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.Success~=true then return end
 local state=result.State
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.EquippedItems)~="table" then return end
 for _,itemId in pairs(state.EquippedItems) do
  if Master.Get(itemId) then itemPage:SetAttribute("UnseenItem_"..itemId,nil) end
 end
end))
table.insert(connections,RS.Remotes:WaitForChild("ItemPurchaseRequest").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and result.Success==true and result.Code=="Purchased"
  and typeof(result.State)=="table" and result.State.Loaded==true
  and typeof(result.State.OwnedItems)=="table" and (result.State.OwnedItems[result.ItemId] or 0)>0 then
  acquired(result.ItemId)
 end
end))
local function opened()
 if panel.Visible then
  task.spawn(refresh)
  local dumbbellsPage=panel.Content:FindFirstChild("Dumbbells")
  if dumbbellsPage and dumbbellsPage.Visible then NotificationState.MarkSeen("Dumbbells",currentDumbbellIds()) end
 end
 render()
end
table.insert(connections,panel:GetPropertyChangedSignal("Visible"):Connect(opened))
table.insert(connections,panel.Content.Dumbbells:GetPropertyChangedSignal("Visible"):Connect(opened))
table.insert(connections,player:GetAttributeChangedSignal("Win"):Connect(function() task.spawn(refresh) end))
table.insert(connections,remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId
  or result.Outcome~="ITEM" or typeof(result.Id)~="string"
  or seenResults[result.Id] or not Master.Get(result.ItemId) then return end
 seenResults[result.Id]=true
 acquired(result.ItemId)
end))
local function inventoryResult(result)
 if typeof(result)=="table" then applyState(result.State) end
end
table.insert(connections,purchase.OnClientEvent:Connect(inventoryResult))
table.insert(connections,equip.OnClientEvent:Connect(inventoryResult))
table.insert(connections,NotificationState.Changed:Connect(render))
render()
task.spawn(function()
 while alive and not NotificationState.Load() do task.wait(2) end
 if not alive then return end
 local ok,state=pcall(function() return itemStateRemote:InvokeServer() end)
 if ok and typeof(state)=="table" and state.Loaded==true and typeof(state.OwnedItems)=="table" then
  itemOwned=state.OwnedItems
  for id,count in pairs(itemOwned) do
   local item=Master.Get(id)
   if count>0 and item and not NotificationState.IsSeen("Items",id) then
    itemPage:SetAttribute("UnseenItem_"..id,true)
    itemPage:SetAttribute("UnseenRarity_"..item.Rarity,true)
   end
  end
 end
 while alive and not owned do
  if refresh() then break end
  task.wait(2)
 end
 render()
end)
task.spawn(function()
 for _,id in ids do
  local buy=dumbbellList:WaitForChild(id):WaitForChild("BuyButton")
  local buyBadge=buy:FindFirstChild("DumbbellGuideBadge") or buy:FindFirstChild("Dumbbell1GuideBadge")
  if not buyBadge then buyBadge=badge:Clone();buyBadge.Visible=false;buyBadge.Parent=buy end
  buyBadge.Name="DumbbellGuideBadge"
 buyBadge.AnchorPoint=Vector2.new(1,0)
 buyBadge.Size=UDim2.fromOffset(24,24)
 buyBadge.Position=UDim2.new(1,-2,0,2)
 buyBadge.BackgroundColor3=Color3.fromRGB(235,55,65)
 buyBadge.BackgroundTransparency=0
 buyBadge.BorderSizePixel=0
 buyBadge.ZIndex=buy.ZIndex+1
 local corner=buyBadge:FindFirstChildOfClass("UICorner")
 if corner then corner.CornerRadius=UDim.new(0.5,0) end
 local text=buyBadge:WaitForChild("TextLabel")
 text.Visible=true
 text.Text="!"
 text.TextColor3=Color3.new(1,1,1)
 text.TextTransparency=0
 text.BackgroundTransparency=1
 text.AnchorPoint=Vector2.zero
 text.Position=UDim2.fromOffset(0,0)
 text.Size=UDim2.fromScale(1,1)
 text.TextSize=20
 text.ZIndex=buyBadge.ZIndex+1  badges[id]=buyBadge
  render()
 end
 local function intersectsViewport(button)
  if not panel.Visible or not dumbbellPage.Visible or not dumbbellList.Visible or not button.Visible then return false end
  local p,s=button.AbsolutePosition,button.AbsoluteSize
  local vp,vs=dumbbellList.AbsolutePosition,dumbbellList.AbsoluteSize
  local screen=gui.AbsoluteSize
  return s.X>0 and s.Y>0
   and p.X<vp.X+vs.X and p.X+s.X>vp.X and p.Y<vp.Y+vs.Y and p.Y+s.Y>vp.Y
   and p.X<screen.X and p.X+s.X>0 and p.Y<screen.Y and p.Y+s.Y>0
 end
 checkVisibleBuyNotifications=function()
  local visible={}
  for _,id in ids do
   local b=badges[id]
   local buy=b and b.Parent
   if affordable[id]==true and not NotificationState.IsSeen("DumbbellBuy",id)
    and buy and intersectsViewport(buy) then table.insert(visible,id) end
  end
  if #visible>0 then NotificationState.MarkSeen("DumbbellBuy",visible) end
 end
 local function queueVisibleCheck() task.defer(checkVisibleBuyNotifications) end
 table.insert(connections,dumbbellList:GetPropertyChangedSignal("CanvasPosition"):Connect(queueVisibleCheck))
 table.insert(connections,dumbbellList:GetPropertyChangedSignal("AbsolutePosition"):Connect(queueVisibleCheck))
 table.insert(connections,dumbbellList:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueVisibleCheck))
 table.insert(connections,dumbbellPage:GetPropertyChangedSignal("Visible"):Connect(queueVisibleCheck))
 table.insert(connections,panel:GetPropertyChangedSignal("Visible"):Connect(queueVisibleCheck))
 for _,id in ids do
  local buy=dumbbellList[id].BuyButton
  table.insert(connections,buy:GetPropertyChangedSignal("AbsolutePosition"):Connect(queueVisibleCheck))
  table.insert(connections,buy:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueVisibleCheck))
 end
 queueVisibleCheck()
end)
script.Destroying:Once(function()
 alive=false
 for _,connection in connections do connection:Disconnect() end
end)
