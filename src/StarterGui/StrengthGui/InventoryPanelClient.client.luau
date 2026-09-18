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
 if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
  object.Font=Enum.Font.FredokaOne
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
local equipped=""
local pending={}
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
   button.Text=isEquipped and "EQUIPPED" or (isOwned and "EQUIP" or "")
   button.WinIcon.Visible=not isOwned and not isEquipped
   button.Price.Visible=not isOwned and not isEquipped
   Presentation.SetButtonEnabled(button,not isEquipped and not requestPending)
   button.BackgroundColor3=isEquipped and Color3.fromRGB(70,76,88)
    or (isOwned and Color3.fromRGB(47,91,151) or Color3.fromRGB(43,121,88))
  end
 end
local item=Master.Get(equipped)
 panel.Equipped.Preview.Image=item and item.Image or ""
 panel.Equipped.ItemName.Text=item and item.Name or "None equipped"
 panel.Equipped.Multiplier.Text=item and ("+"..tostring(item.StrengthBonus).." Strength") or ""
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedDumbbells)~="table" then return false end
 owned=state.OwnedDumbbells
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
 local text=tostring(math.max(0,math.floor(tonumber(value) or 0)))
 return text:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
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
 if code=="AlreadyOwned" then return "ALREADY OWNED" end
 if code=="DataNotLoaded" then return "PLEASE WAIT...\nInventory is loading" end
 return code and ("PURCHASE FAILED\n"..tostring(code)) or "PURCHASE FAILED"
end
local function selectCard(itemId)
 selectedId=itemId
 panel:SetAttribute("SelectedItemId",itemId)
 for id,card in pairs(cards) do
  local selected=id==selectedId
  card.UIStroke.Color=selected and Color3.fromRGB(65,220,255) or Color3.fromRGB(49,19,66)
  card.UIStroke.Thickness=selected and 3 or 2
  card.BackgroundColor3=selected and Color3.fromRGB(145,77,189) or Color3.fromRGB(113,54,156)
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

  label(card,"Multiplier","+"..tostring(item.StrengthBonus).." Strength",UDim2.new(0,6,0,142),UDim2.new(1,-12,0,18),Color3.fromRGB(138,227,255))
  local buy=Instance.new("TextButton")
  buy.Name="BuyButton" buy.Text="" buy.Font=Enum.Font.GothamBold buy.TextSize=15
  buy.TextColor3=Color3.new(1,1,1) buy.BackgroundColor3=Color3.fromRGB(43,121,88)
  buy.BorderSizePixel=0 buy.Position=UDim2.new(0,10,1,-38) buy.Size=UDim2.new(1,-20,0,28)
  buy.ZIndex=33 buy.Parent=card round(buy,7)
  buy.TextStrokeColor3=Color3.new();buy.TextStrokeTransparency=0
  local price=label(buy,"Price",tostring(item.PriceWin),UDim2.new(.5,0,0,0),UDim2.new(.5,-12,1,0),Color3.new(1,1,1))
  price.TextXAlignment=Enum.TextXAlignment.Left;price.TextStrokeColor3=Color3.new();price.TextStrokeTransparency=0;price.ZIndex=34
  local trophy=Instance.new("ImageLabel")
  trophy.Name="WinIcon";trophy.Image=gui.WinLabel.TrophyIcon.Image
  trophy.BackgroundTransparency=1;trophy.ScaleType=Enum.ScaleType.Fit;trophy.AnchorPoint=Vector2.new(1,.5)
  trophy.Position=UDim2.new(.5,-8,.5,0);trophy.ZIndex=34;trophy.Parent=buy
  cards[itemId]=card
  card.Activated:Connect(function() selectCard(itemId) end)
  Responsive.ConnectActivation(buy,function()
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
local function layout()
 local compact=false -- Keep the original equipped preview and two-column card layout.
 panel.Equipped.Visible=not compact
 panel.Owned.Position=compact and UDim2.new() or UDim2.new(.38,0,0,0)
 panel.Owned.Size=compact and UDim2.fromScale(1,1) or UDim2.fromScale(.62,1)
 list.Position=compact and UDim2.fromOffset(10,58) or UDim2.new(.38,10,0,58)
 list.Size=compact and UDim2.new(1,-20,1,-70) or UDim2.new(.62,-20,1,-70)
 local scale=math.max(shell.ResponsiveScale.Scale,.01)
 local width=list.AbsoluteSize.X/scale
 local padding=list:FindFirstChildOfClass("UIPadding")
 if padding then width-=padding.PaddingLeft.Offset+padding.PaddingRight.Offset end
 local cellWidth=math.floor((width-20)/2)
 if cellWidth<=0 then return end
 local height=compact and 480 or 310
 grid.FillDirectionMaxCells=2
 grid.CellSize=UDim2.fromOffset(cellWidth,height)
 for _,card in pairs(cards) do
  card.Icon.Position=UDim2.fromOffset(12,10)
  card.Icon.Size=UDim2.new(1,-24,0,compact and 272 or 192)
  local strength=card.Multiplier
  strength.Position=UDim2.new(0,8,0,compact and 286 or 204)
  strength.Size=UDim2.new(1,-16,0,compact and 64 or 40)
  strength.TextSize=compact and 40 or 26
  strength.TextStrokeColor3=Color3.new();strength.TextStrokeTransparency=0
  local button=card.BuyButton
  local bh=compact and 112 or 54
  button.Position=UDim2.new(0,12,1,-bh-12)
  button.Size=UDim2.new(1,-24,0,bh)
  button.TextSize=compact and 38 or 25
  button.Price.TextSize=compact and 48 or 30
  button.WinIcon.Size=UDim2.fromOffset(compact and 64 or 36,compact and 64 or 36)
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
updateButtons()
