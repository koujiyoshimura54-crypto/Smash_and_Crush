local PurchaseHUD=require(game:GetService("ReplicatedStorage").Modules.HUDLayout)
local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
-- Phase 7.2.3.3: Inventory UI backed by authoritative dumbbell server state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("DumbbellItemMaster"))
local purchaseRemote=RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equipRemote=RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote=RS.Remotes:WaitForChild("DumbbellInventoryState")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local shell=gui:WaitForChild("InventoryPanel")
local function applyInventoryFont(object)
 if object:FindFirstAncestor("PurchasedButtonVisual") then return end
 if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
  Presentation.ApplyPurchasedText(object)
  local limit=object:FindFirstChildOfClass("UITextSizeConstraint")
  if object.TextScaled and limit then limit.MinTextSize=math.min(limit.MinTextSize,6) end
 end
end
for _,object in ipairs(shell:GetDescendants()) do applyInventoryFont(object) end
shell.DescendantAdded:Connect(function(object)
 -- Runtime-created Cards and Merge controls may finish assigning their
 -- authored font after parenting. Apply the Inventory font after that work.
 task.defer(function()
  if object:IsDescendantOf(shell) then applyInventoryFont(object) end
 end)
end)
local panel=shell:WaitForChild("Content"):WaitForChild("Dumbbells")
local list=panel:WaitForChild("Items")
local grid=list:WaitForChild("UIGridLayout")
local status=shell.Content.Items.Status:Clone()
status.Name="Status"
status.Text=""
status.Position=UDim2.new(.38,8,1,-50)
status.Size=UDim2.new(.62,-16,0,44)
status.TextWrapped=true
status.TextScaled=true
status.Visible=false
status.Parent=panel
local statusToken=0
local cards={}

local selectedId
local owned={}
local stateLoaded=false
local equipped=""
local pending={}
local layout
local function worldLocked(itemId)
 local item=Master.Get(itemId)
 return item and item.WorldId==2 and owned[itemId]~=true and equipped~=itemId
  and player:GetAttribute("World2Visited")~=true
end
local function round(parent,radius)
 local corner=Instance.new("UICorner")
 corner.CornerRadius=UDim.new(0,radius)
 corner.Parent=parent
end
local function label(parent,name,text,position,size,color)
 local obj=Instance.new("TextLabel")
 obj.Name=name obj.Text=text obj.Position=position obj.Size=size
 obj.BackgroundTransparency=1 obj.BorderSizePixel=0
 obj.TextColor3=color or Color3.fromRGB(245,247,252)
 obj.Font=Enum.Font.GothamBold obj.TextSize=14
 obj.TextWrapped=true obj.ZIndex=32 obj.Parent=parent
 return obj
end
local function updateButtons()
 local requestPending=next(pending)~=nil
 for itemId,card in pairs(cards) do
  local button=card:FindFirstChild("BuyButton")
  if button then
   local isEquipped=equipped==itemId
   local isOwned=owned[itemId]==true
   local locked=worldLocked(itemId)
   Presentation.SetInventorySecret(card,card.Icon,locked or (stateLoaded and not isOwned and not isEquipped))
   button.Text=isEquipped and "Equipped" or (isOwned and "Equip" or "")
   button.WinIcon.Visible=not isOwned and not isEquipped
   button.Price.Visible=not isOwned and not isEquipped
   Presentation.SetButtonEnabled(button,stateLoaded and not locked and not isEquipped and not requestPending)
   button.Interactable=button.Active
   button.BackgroundColor3=isEquipped and Color3.fromRGB(70,76,88)
    or (isOwned and Color3.fromRGB(47,91,151) or Color3.fromRGB(43,121,88))
   PurchaseHUD.PurchaseButton(button,"Win",(isOwned or isEquipped) and button.Text or button.Price.Text)
   Presentation.SetEquipped(button,isEquipped)
   local visual=button:FindFirstChild("PurchasedButtonVisual");if visual then visual.Main.Amount.AutoLocalize=isOwned end
   Presentation.SetInventoryWorldLock(card,card.Icon,locked)
  end
 end
local item=Master.Get(equipped)
 panel.Equipped.Preview.Image=item and item.Image or ""
 panel.Equipped.ItemName.Text=item and item.Name or "None equipped"
 panel.Equipped.Multiplier.Text=item and ("+"..tostring(item.StrengthBonus).." Strength") or ""
 if selectedId and worldLocked(selectedId) then selectedId=nil;panel:SetAttribute("SelectedItemId",nil) end
 if layout then layout() end
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedDumbbells)~="table" then return false end
 owned=state.OwnedDumbbells
 stateLoaded=true
 equipped=typeof(state.EquippedDumbbell)=="string" and state.EquippedDumbbell or ""
 if typeof(state.Win)=="number" then panel.WinLabel.Text="Win  "..tostring(state.Win) end
 updateButtons()
 return true
end
local function refreshState()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if ok then applyState(state) end
end
local function formatWin(value)
 return require(RS.Modules.NumberFormat).Price(math.max(0,math.floor(tonumber(value) or 0)))
end
local function showStatus(message)
 statusToken+=1
 local token=statusToken
 status.Text=message or ""
 status.Visible=status.Text~=""
 if status.Visible then
  task.delay(3,function()
   if statusToken==token and status.Parent then status.Text="";status.Visible=false end
  end)
 end
end
local function purchaseFailureText(code,itemId)
 local item=Master.Get(itemId)
 if code=="NotEnoughWin" then return "NOT ENOUGH WIN!\nNeed "..formatWin(item and item.PriceWin).." Win" end
 if code=="DataSaving" then return "PLEASE WAIT...\nData is saving" end
 if code=="InventorySavePending" then return "PLEASE WAIT...\nSaving previous reward" end
 if code=="AlreadyOwned" then return "ALREADY OWNED" end
 if code=="DataNotLoaded" then return "PLEASE WAIT...\nInventory is loading" end
 return code and ("PURCHASE FAILED\n"..tostring(code)) or "PURCHASE FAILED"
end
local function selectCard(itemId)
 if worldLocked(itemId) or not stateLoaded then return end
 selectedId=itemId
 panel:SetAttribute("SelectedItemId",itemId)
 for id,card in pairs(cards) do
  local selected=id==selectedId
  Presentation.SetSelected(card,selected)
 end
end
local sortedItems=Master.GetSorted()
for order,item in ipairs(sortedItems) do
 local itemId=item.ItemId
 if item and item.Category=="Dumbbell" then
  local card=Instance.new("TextButton")
  card.Name=itemId card.Text="" card.AutoButtonColor=false
  card.LayoutOrder=order card.Size=UDim2.fromOffset(150,230)
  card.BackgroundColor3=Color3.fromRGB(113,54,156) card.BorderSizePixel=0
  card.ZIndex=31 card.Parent=list
  card:SetAttribute("ItemId",itemId)
  round(card,12)
  local stroke=Instance.new("UIStroke")
  stroke.Name="UIStroke" stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
  stroke.Color=Color3.fromRGB(49,19,66) stroke.Thickness=2 stroke.Parent=card
  local icon=Instance.new("ImageLabel")
  icon.Name="Icon" icon.BackgroundTransparency=1 icon.Image=item.Image
  icon.ScaleType=Enum.ScaleType.Fit
  icon.Position=UDim2.new(0,10,0,8) icon.Size=UDim2.new(1,-20,0,128)
  icon.ZIndex=32 icon.Parent=card

  label(card,"Multiplier",(item.WorldId==2 and "World 2 " or "").."+"..tostring(item.StrengthBonus).." Strength",UDim2.new(0,6,0,142),UDim2.new(1,-12,0,18),Color3.fromRGB(138,227,255))
  local buy=Instance.new("TextButton")
  buy.Name="BuyButton" buy.Text="" buy.Font=Enum.Font.GothamBold buy.TextSize=15
  buy.TextColor3=Color3.new(1,1,1) buy.BackgroundColor3=Color3.fromRGB(43,121,88)
  buy.BorderSizePixel=0 buy.Position=UDim2.new(0,10,1,-38) buy.Size=UDim2.new(1,-20,0,28)
  buy.ZIndex=33 buy.Parent=card round(buy,7)
  buy.TextStrokeColor3=Color3.new();buy.TextStrokeTransparency=0
  local price=label(buy,"Price",require(RS.Modules.NumberFormat).Price(item.PriceWin),UDim2.new(.5,0,0,0),UDim2.new(.5,-12,1,0),Color3.new(1,1,1))
  price.TextXAlignment=Enum.TextXAlignment.Left;price.TextStrokeColor3=Color3.new();price.TextStrokeTransparency=0;price.ZIndex=34
  local trophy=Instance.new("ImageLabel")
  trophy.Name="WinIcon";trophy.Image=gui.WinLabel.TrophyIcon.Image
  trophy.BackgroundTransparency=1;trophy.ScaleType=Enum.ScaleType.Fit;trophy.AnchorPoint=Vector2.new(1,.5)
  trophy.Position=UDim2.new(.5,-8,.5,0);trophy.ZIndex=34;trophy.Parent=buy
  cards[itemId]=card
  card.Activated:Connect(function() selectCard(itemId) end)
  Responsive.ConnectActivation(buy,function()
   if worldLocked(itemId) or not stateLoaded then return end
   selectCard(itemId)
   if next(pending)~=nil or equipped==itemId then return end
   pending[itemId]=true
   updateButtons()
   if owned[itemId]==true then
    equipRemote:FireServer(itemId)
   else
    purchaseRemote:FireServer(itemId)
   end
  end)
 end
end
local function updateWin()
 panel.WinLabel.Text="Win  "..tostring(player:GetAttribute("Win") or 0)
end
player:GetAttributeChangedSignal("Win"):Connect(updateWin)
updateWin()
layout=function()
 local compact=shell.Size.Y.Scale==0 and shell.Size.Y.Offset<500
 panel.Equipped.Visible=true
 panel.Owned.Position=UDim2.new(.30,0,0,0)
 panel.Owned.Size=UDim2.fromScale(.70,1)
 list.Position=UDim2.new(.30,8,0,48)
 list.Size=UDim2.new(.70,-16,1,-56)
 local scale=math.max(shell.ResponsiveScale.Scale,.01)
 local width=list.AbsoluteSize.X/scale
 local padding=list:FindFirstChildOfClass("UIPadding")
 if padding then width-=padding.PaddingLeft.Offset+padding.PaddingRight.Offset end
 local columns=math.clamp(math.floor((width*scale+14*scale)/(148+14*scale)),1,3)
 local cellWidth=math.floor((width-(columns-1)*14)/columns)
 if cellWidth<=0 then return end
 local iconHeight=math.max(compact and 84 or 104,76/scale)
 local effectHeight=math.max(28,22/scale)
 local buttonHeight=math.max(42,40/scale)
 local height=math.max(compact and 186 or 206,10+iconHeight+8+effectHeight+8+buttonHeight+12)
 grid.FillDirectionMaxCells=columns
 grid.CellPadding=UDim2.fromOffset(14,14)
 grid.CellSize=UDim2.fromOffset(cellWidth,height)
 list.Active=true
 list.ScrollingEnabled=true
 list.ScrollingDirection=Enum.ScrollingDirection.Y
 list.AutomaticCanvasSize=Enum.AutomaticSize.Y
 list.CanvasSize=UDim2.new()
 for _,card in pairs(cards) do
  card.Icon.Position=UDim2.fromOffset(12,10)
  card.Icon.Size=UDim2.new(1,-24,0,iconHeight)
  if card:GetAttribute("InventoryWorldLocked") then
   card.Icon.Position=UDim2.fromScale(.08,.07);card.Icon.Size=UDim2.fromScale(.84,.86)
  end
  local strength=card.Multiplier
  strength.Position=UDim2.new(0,8,0,10+iconHeight+8)
  strength.Size=UDim2.new(1,-16,0,effectHeight)
  strength.TextSize=22
  strength.TextScaled=true
  strength.TextStrokeColor3=Color3.new();strength.TextStrokeTransparency=0
  local button=card.BuyButton
  local bh=buttonHeight
  button.Position=UDim2.new(0,12,1,-bh-12)
  button.Size=UDim2.new(1,-24,0,bh)
  button.TextSize=22
  button.Price.TextSize=24
  button.WinIcon.Size=UDim2.fromOffset(compact and 32 or 36,compact and 32 or 36)
 end
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
shell.ResponsiveScale:GetPropertyChangedSignal("Scale"):Connect(layout)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
task.defer(layout)

local function updateEquippedPreview()
 local item=Master.Get(equipped)
 panel.Equipped.Preview.Image=item and item.Image or ""
 panel.Equipped.ItemName.Text=item and item.Name or "None equipped"
 panel.Equipped.Multiplier.Text=item and ("+"..tostring(item.StrengthBonus).." Strength") or ""
end
local function opened()
 if shell.Visible and panel.Visible then updateWin() refreshState() updateEquippedPreview() end
end
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
panel:GetPropertyChangedSignal("Visible"):Connect(opened)
player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(function()
 if shell.Visible then refreshState() updateEquippedPreview() end
end)
purchaseRemote.OnClientEvent:Connect(function(result)
 local itemId=typeof(result)=="table" and result.ItemId or nil
 if itemId then pending[itemId]=nil end
 if typeof(result)=="table" and not applyState(result.State) then refreshState() end
 if typeof(result)=="table" and result.Success==false then
  showStatus(purchaseFailureText(result.Code,itemId))
 else
  showStatus("")
 end
 updateButtons()
end)
equipRemote.OnClientEvent:Connect(function(result)
 table.clear(pending)
 if typeof(result)=="table" and not applyState(result.State) then refreshState() end
 updateButtons()
end)
player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(function()
 if panel.Visible then refreshState() end
end)
player:GetAttributeChangedSignal("World2Visited"):Connect(updateButtons)
updateButtons()
