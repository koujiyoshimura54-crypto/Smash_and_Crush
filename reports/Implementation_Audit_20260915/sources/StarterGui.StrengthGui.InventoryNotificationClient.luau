-- Session-only notifications. Ownership is supplied by existing server inventory state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Badges=require(RS.Modules:WaitForChild("BadgeRenderer"))
local player=Players.LocalPlayer
local gui=script.Parent
local badge=gui:WaitForChild("LeftMenu"):WaitForChild("InventoryButton"):WaitForChild("NotificationBadge")
local panel=gui:WaitForChild("InventoryPanel")
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local purchase=RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equip=RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote=RS.Remotes:WaitForChild("DumbbellInventoryState")
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local Dumbbells=require(RS.Config:WaitForChild("DumbbellItemMaster"))
local ids={}
for _,item in ipairs(Dumbbells.GetSorted()) do
 if item.Category=="Dumbbell" then table.insert(ids,item.ItemId) end
end
local HasUnseenItem=false
local seen={}
local owned
local affordable={}
local pending={}
local unseen={}
local badges={}
local connections={}
local alive=true
local revision=0

-- Item guidance lives only on this client's Items page; keys are existing Item IDs.
local itemPage=panel:WaitForChild("Content"):WaitForChild("Items")
local itemTab=panel:WaitForChild("Tabs"):WaitForChild("Items")
local itemTabUnseen=false
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
  if affordable[id] then hasNew=true end
  local b=badges[id]
  if b then b.Visible=pending[id]==true and affordable[id]==true and not unseen[id] end
 end
 badge.Visible=HasUnseenItem or hasNew or badge.Parent:GetAttribute("AuraPurchaseAvailable")==true or badge.Parent:GetAttribute("SpeedPurchaseAvailable")==true
 Badges.SetVisible(itemTabBadge,itemTabUnseen)
 Badges.SetVisible(dumbbellTabBadge,hasNew)
end
table.insert(connections,badge.Parent:GetAttributeChangedSignal("AuraPurchaseAvailable"):Connect(render))
table.insert(connections,badge.Parent:GetAttributeChangedSignal("SpeedPurchaseAvailable"):Connect(render))
local function evaluate()
 if not owned then render();return end
 local win=player:GetAttribute("Win")
 if typeof(win)~="number" then return end
 for _,id in ids do
  local item=Dumbbells.Get(id)
  local can=item~=nil and typeof(item.PriceWin)=="number" and win>=item.PriceWin and owned[id]~=true
  if can and not affordable[id] then
   pending[id]=true
   unseen[id]=not panel.Visible
  elseif not can then
   unseen[id]=nil
   if owned[id]==true then pending[id]=nil end
  end
  affordable[id]=can
 end
 render()
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedDumbbells)~="table" then return false end
 revision+=1
 owned=state.OwnedDumbbells
 evaluate()
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
 itemPage:SetAttribute("UnseenItem_"..itemId,true)
 itemPage:SetAttribute("UnseenRarity_"..item.Rarity,true)
 HasUnseenItem=not panel.Visible
 itemTabUnseen=not (panel.Visible and itemPage.Visible)
 render()
end
local function itemsOpened()
 if panel.Visible and itemPage.Visible then itemTabUnseen=false end
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
  HasUnseenItem=false
  table.clear(unseen)
  task.spawn(refresh)
 end
 render()
end
table.insert(connections,panel:GetPropertyChangedSignal("Visible"):Connect(opened))
table.insert(connections,player:GetAttributeChangedSignal("Win"):Connect(evaluate))
table.insert(connections,remote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" or result.OwnerUserId~=player.UserId
  or result.Outcome~="ITEM" or typeof(result.Id)~="string"
  or seen[result.Id] or not Master.Get(result.ItemId) then return end
 seen[result.Id]=true
 acquired(result.ItemId)
end))
local function inventoryResult(result)
 if typeof(result)=="table" then applyState(result.State) end
end
table.insert(connections,purchase.OnClientEvent:Connect(inventoryResult))
table.insert(connections,equip.OnClientEvent:Connect(inventoryResult))
render()
task.spawn(function()
 while alive and not owned do
  if refresh() then break end
  task.wait(2)
 end
end)
task.spawn(function()
 local items=panel:WaitForChild("Content"):WaitForChild("Dumbbells"):WaitForChild("Items")
 for _,id in ids do
  local buy=items:WaitForChild(id):WaitForChild("BuyButton")
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
end)
script.Destroying:Once(function()
 alive=false
 for _,connection in connections do connection:Disconnect() end
end)

