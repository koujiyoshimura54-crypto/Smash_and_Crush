-- Phase 7.3.2: shop choices with server-authoritative regular item ownership and Win purchase.
local RS=game:GetService("ReplicatedStorage")
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local purchaseRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local robuxRemote=RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local panel=gui:WaitForChild("ShopPanel")
local scale=panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
scale.Name="ResponsiveScale"
scale.Parent=panel

local function close()
 panel.Visible=false
end

local designWidth,designHeight
local function layout()
 local view=gui.AbsoluteSize
 if view.X<=0 or view.Y<=0 then return end
 if not designWidth or not designHeight then
  designWidth=panel.AbsoluteSize.X/math.max(scale.Scale,0.001)
  designHeight=panel.AbsoluteSize.Y/math.max(scale.Scale,0.001)
  if designWidth<=0 then designWidth=view.X*panel.Size.X.Scale end
  if designHeight<=0 then designHeight=view.Y*panel.Size.Y.Scale end
 end
 scale.Scale=math.clamp(math.min(1,(view.X-24)/designWidth,(view.Y-24)/designHeight),0.35,1)
 panel.AnchorPoint=Vector2.new(0.5,0.5)
 panel.Position=UDim2.fromScale(0.5,0.5)
end

local rarityColors={
 Common=Color3.fromRGB(190,190,200),
 Uncommon=Color3.fromRGB(58,185,88),
 Rare=Color3.fromRGB(52,125,230),
 Epic=Color3.fromRGB(151,67,210),
 Legendary=Color3.fromRGB(235,181,42),
}
local elementColors={
 Fire=Color3.fromRGB(211,55,49),
 Ice=Color3.fromRGB(75,190,235),
 Electric=Color3.fromRGB(235,200,45),
}
local ownedItems={}
local equippedItems={}
local robuxPendingItemId
local pendingItemId
local pendingAction
local typeIds={Protein="PROTEIN",Glove="GLOVE",TrainingBelt="TRAININGBELT"}
local function getSelectedItemId(card)
 local typeId=typeIds[card:GetAttribute("ProductId")]
 local rarity=card:GetAttribute("SelectedRarity")
 local element=card:GetAttribute("SelectedElement")
 if not typeId or typeof(rarity)~="string" or typeof(element)~="string" then return nil end
 return typeId.."_"..string.upper(rarity).."_"..string.upper(element)
end
local function updateCard(card)
 local selectedRarity=card:GetAttribute("SelectedRarity") or "Common"
 local selectedElement=card:GetAttribute("SelectedElement") or "Fire"
 for name,color in pairs(rarityColors) do
  local button=card.RarityOptions:FindFirstChild(name)
  local selected=name==selectedRarity
  button.BackgroundColor3=selected and color:Lerp(Color3.new(1,1,1),0.18) or Color3.fromRGB(43,43,51)
  button.TextColor3=selected and Color3.fromRGB(18,18,22) or color
  button.SelectionStroke.Thickness=selected and 3 or 1
 end
 for name,color in pairs(elementColors) do
  local button=card.ElementOptions:FindFirstChild(name)
  local selected=name==selectedElement
  button.BackgroundColor3=selected and color:Lerp(Color3.new(1,1,1),0.15) or Color3.fromRGB(43,43,51)
  button.TextColor3=selected and Color3.fromRGB(18,18,22) or color
  button.IconLabel.TextColor3=selected and Color3.fromRGB(18,18,22) or color
  button.NameLabel.TextColor3=selected and Color3.fromRGB(18,18,22) or color
  button.SelectionStroke.Thickness=selected and 4 or 2
 end
 local purchase=card.PurchaseOptions
 local useWin=selectedRarity=="Common" or selectedRarity=="Uncommon" or selectedRarity=="Rare"
 local itemId=getSelectedItemId(card)
 local item=itemId and Master.Get(itemId)
 if item and typeof(item.Image)=="string" then card.ImageBackground.ProductImage.Image=item.Image end
 local count=itemId and ownedItems[itemId] or 0
 local isOwned=count>0
 local isPending=itemId~=nil and itemId==pendingItemId
 local isEquipped=isOwned and equippedItems[card:GetAttribute("ProductId")]==itemId
 local idle=not pendingItemId and not robuxPendingItemId
 purchase.CountLabel.Text="OWNED ×"..tostring(count)
 purchase.WinBuyButton.Visible=useWin
 purchase.RobuxBuyButton.Visible=not useWin
 purchase.WinBuyButton.Active=useWin and idle
 purchase.WinBuyButton.AutoButtonColor=purchase.WinBuyButton.Active
 purchase.WinBuyButton.BuyLabel.Text=isPending and pendingAction=="Buy" and "..." or "BUY"
 purchase.WinBuyButton.PriceLabel.Text=tostring(card:GetAttribute("WinPrice_"..selectedRarity) or 0).." Win"
 purchase.RobuxBuyButton.Active=not useWin and idle
 purchase.RobuxBuyButton.AutoButtonColor=purchase.RobuxBuyButton.Active
 purchase.RobuxBuyButton.BuyLabel.Text=itemId==robuxPendingItemId and "..." or "BUY"
 purchase.RobuxBuyButton.PriceLabel.Text=tostring(card:GetAttribute("RobuxPrice_"..selectedRarity) or 0)
 purchase.EquipButton.Visible=isOwned
 purchase.EquipButton.Active=isOwned and not isEquipped and idle
 purchase.EquipButton.AutoButtonColor=purchase.EquipButton.Active
 purchase.EquipButton.Text=isEquipped and "EQUIPPED" or (isPending and pendingAction=="Equip" and "..." or "EQUIP")
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 ownedItems=state.OwnedItems
 equippedItems=typeof(state.EquippedItems)=="table" and state.EquippedItems or {}
 for _,card in ipairs(panel.Products:GetChildren()) do if card:IsA("Frame") then updateCard(card) end end
 return true
end
local function refreshState()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if ok then applyState(state) end
end
local function setupQuantityControls(card)
 local purchase=card.PurchaseOptions
 local count=purchase:FindFirstChild("CountLabel") or Instance.new("TextLabel")
 count.Name="CountLabel"
 count.BackgroundTransparency=1
 count.Position=UDim2.fromOffset(8,0)
 count.Size=UDim2.new(1,-16,0,24)
 count.Font=Enum.Font.GothamBold
 count.TextSize=18
 count.TextColor3=Color3.fromRGB(220,220,230)
 count.TextXAlignment=Enum.TextXAlignment.Left
 count.ZIndex=purchase.WinBuyButton.ZIndex
 count.Parent=purchase
 local equip=purchase:FindFirstChild("EquipButton") or Instance.new("TextButton")
 equip.Name="EquipButton"
 equip.Position=UDim2.new(.60,4,0,28)
 equip.Size=UDim2.new(.40,-12,0,80)
 equip.BackgroundColor3=Color3.fromRGB(57,76,91)
 equip.TextColor3=Color3.new(1,1,1)
 equip.Font=Enum.Font.GothamBold
 equip.TextSize=18
 equip.TextScaled=true
 equip.ZIndex=purchase.WinBuyButton.ZIndex
 equip.Parent=purchase
 if not equip:FindFirstChildOfClass("UICorner") then
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=equip
  local limit=Instance.new("UITextSizeConstraint"); limit.MaxTextSize=20; limit.MinTextSize=10; limit.Parent=equip
  local padding=Instance.new("UIPadding"); padding.PaddingLeft=UDim.new(0,5); padding.PaddingRight=UDim.new(0,5); padding.Parent=equip
 end
 for _,button in ipairs({purchase.WinBuyButton,purchase.RobuxBuyButton}) do
  button.Position=UDim2.fromOffset(8,28)
  button.Size=UDim2.new(.60,-12,0,80)
  button.BuyLabel.Position=UDim2.fromOffset(6,4)
  button.BuyLabel.Size=UDim2.new(1,-12,0,26)
  button.BuyLabel.TextSize=20
  button.PriceLabel.Position=UDim2.fromOffset(6,32)
  button.PriceLabel.Size=UDim2.new(1,-12,0,38)
  button.PriceLabel.TextSize=26
 end
 purchase.RobuxBuyButton.RobuxIcon.Position=UDim2.fromOffset(12,36)
 purchase.RobuxBuyButton.RobuxIcon.Size=UDim2.fromOffset(30,30)
 purchase.RobuxBuyButton.PriceLabel.Position=UDim2.fromOffset(46,32)
 purchase.RobuxBuyButton.PriceLabel.Size=UDim2.new(1,-54,0,38)
end
local function redraw()
 for _,card in ipairs(panel.Products:GetChildren()) do if card:IsA("Frame") then updateCard(card) end end
end
for _,card in ipairs(panel.Products:GetChildren()) do
 if card:IsA("Frame") then
  setupQuantityControls(card)
  for name in pairs(rarityColors) do
   card.RarityOptions[name].Activated:Connect(function()
    card:SetAttribute("SelectedRarity",name)
    updateCard(card)
   end)
  end
  for name in pairs(elementColors) do
   card.ElementOptions[name].Activated:Connect(function()
    card:SetAttribute("SelectedElement",name)
    updateCard(card)
   end)
  end
  card.PurchaseOptions.WinBuyButton.Activated:Connect(function()
   local rarity=card:GetAttribute("SelectedRarity")
   local itemId=getSelectedItemId(card)
   if not itemId or pendingItemId or robuxPendingItemId then return end
   if rarity~="Common" and rarity~="Uncommon" and rarity~="Rare" then return end
   pendingItemId=itemId
   pendingAction="Buy"
   redraw()
   purchaseRemote:FireServer(itemId)
  end)
  card.PurchaseOptions.EquipButton.Activated:Connect(function()
   local itemId=getSelectedItemId(card)
   if not itemId or pendingItemId or robuxPendingItemId or (ownedItems[itemId] or 0)<1 then return end
   if equippedItems[card:GetAttribute("ProductId")]==itemId then return end
   pendingItemId=itemId
   pendingAction="Equip"
   redraw()
   equipRemote:FireServer(itemId)
  end)
  card.PurchaseOptions.RobuxBuyButton.Activated:Connect(function()
   local rarity=card:GetAttribute("SelectedRarity")
   local itemId=getSelectedItemId(card)
   if rarity~="Epic" and rarity~="Legendary" then return end
   if not itemId or robuxPendingItemId or pendingItemId then return end
   robuxPendingItemId=itemId
   for _,other in ipairs(panel.Products:GetChildren()) do if other:IsA("Frame") then updateCard(other) end end
   robuxRemote:FireServer(itemId)
  end)
  updateCard(card)
 end
end

menu.ShopButton.Activated:Connect(function()
 local opening=not panel.Visible
 panel.Visible=opening
 if opening then
  local inventory=gui:FindFirstChild("InventoryPanel")
  if inventory then inventory.Visible=false end
  refreshState()
  layout()
 end
end)
panel.Header.CloseButton.Activated:Connect(close)
menu.InventoryButton.Activated:Connect(close)
menu.RebirthButton.Activated:Connect(close)
menu.SkipButton.Activated:Connect(close)
purchaseRemote.OnClientEvent:Connect(function(result)
 pendingItemId=nil
 if typeof(result)=="table" and not applyState(result.State) then refreshState() end
end)
equipRemote.OnClientEvent:Connect(function(result)
 pendingItemId=nil
 if typeof(result)~="table" or not applyState(result.State) then refreshState() end
end)
robuxRemote.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 if result.Code~="PromptOpened" and result.Code~="AwaitingReceipt" then
  robuxPendingItemId=nil
 end
 -- Ownership already existed on a repeat purchase; only the result code releases its lock.
 if not applyState(result.State) then
  for _,card in ipairs(panel.Products:GetChildren()) do if card:IsA("Frame") then updateCard(card) end end
 end
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
menu:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
