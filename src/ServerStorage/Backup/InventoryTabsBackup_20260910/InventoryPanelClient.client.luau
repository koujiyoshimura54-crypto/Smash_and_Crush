-- Phase 7.2.3.3: Inventory UI backed by authoritative dumbbell server state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("DumbbellItemMaster"))
local purchaseRemote=RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local equipRemote=RS.Remotes:WaitForChild("DumbbellEquipRequest")
local stateRemote=RS.Remotes:WaitForChild("DumbbellInventoryState")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local panel=gui:WaitForChild("InventoryPanel")
local list=panel:WaitForChild("Items")
local grid=list:WaitForChild("UIGridLayout")
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
   button.Text=isEquipped and "EQUIPPED" or (isOwned and "EQUIP" or "BUY")
   button.Active=not isEquipped and not requestPending
   button.AutoButtonColor=button.Active
   button.BackgroundColor3=isEquipped and Color3.fromRGB(70,76,88)
    or (isOwned and Color3.fromRGB(47,91,151) or Color3.fromRGB(43,121,88))
  end
 end
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
local function selectCard(itemId)
 selectedId=itemId
 panel:SetAttribute("SelectedItemId",itemId)
 for id,card in pairs(cards) do
  local selected=id==selectedId
  card.UIStroke.Color=selected and Color3.fromRGB(65,220,255) or Color3.fromRGB(10,14,22)
  card.UIStroke.Thickness=selected and 3 or 2
  card.BackgroundColor3=selected and Color3.fromRGB(38,62,82) or Color3.fromRGB(36,43,58)
 end
end
for order,itemId in ipairs({"NORMAL_01","NORMAL_02","NORMAL_03","NORMAL_04","NORMAL_05"}) do
 local item=Master.Get(itemId)
 if item and item.Category=="Dumbbell" then
  local card=Instance.new("TextButton")
  card.Name=itemId card.Text="" card.AutoButtonColor=false
  card.LayoutOrder=order card.Size=UDim2.fromOffset(150,230)
  card.BackgroundColor3=Color3.fromRGB(36,43,58) card.BorderSizePixel=0
  card.ZIndex=31 card.Parent=list
  card:SetAttribute("ItemId",itemId)
  round(card,12)
  local stroke=Instance.new("UIStroke")
  stroke.Name="UIStroke" stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
  stroke.Color=Color3.fromRGB(10,14,22) stroke.Thickness=2 stroke.Parent=card
  local icon=Instance.new("ImageLabel")
  icon.Name="Icon" icon.BackgroundTransparency=1 icon.Image=item.Image
  icon.ScaleType=Enum.ScaleType.Fit
  icon.Position=UDim2.new(0,10,0,8) icon.Size=UDim2.new(1,-20,0,92)
  icon.ZIndex=32 icon.Parent=card
  label(card,"ItemName",item.Name,UDim2.new(0,8,0,103),UDim2.new(1,-16,0,36))
  label(card,"Multiplier","×"..tostring(item.StrengthMultiplier).." Strength",UDim2.new(0,6,0,142),UDim2.new(1,-12,0,18),Color3.fromRGB(138,227,255))
  label(card,"Price",tostring(item.PriceWin).." Win",UDim2.new(0,6,0,165),UDim2.new(1,-12,0,18),Color3.fromRGB(255,218,110))
  local buy=Instance.new("TextButton")
  buy.Name="BuyButton" buy.Text="BUY" buy.Font=Enum.Font.GothamBold buy.TextSize=15
  buy.TextColor3=Color3.new(1,1,1) buy.BackgroundColor3=Color3.fromRGB(43,121,88)
  buy.BorderSizePixel=0 buy.Position=UDim2.new(0,10,1,-38) buy.Size=UDim2.new(1,-20,0,28)
  buy.ZIndex=33 buy.Parent=card round(buy,7)
  cards[itemId]=card
  card.Activated:Connect(function() selectCard(itemId) end)
  buy.Activated:Connect(function()
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
 local view=gui.AbsoluteSize
 if view.X<=0 or view.Y<=0 then return end
 local left=menu.Position.X.Offset+menu.AbsoluteSize.X+20
 local width=math.floor(math.min(520,view.X*0.52,view.X-left-20))
 local height=math.floor(math.min(580,view.Y-40))
 panel.Position=UDim2.fromOffset(left,math.max(12,(view.Y-height)/2))
 panel.Size=UDim2.fromOffset(math.max(180,width),math.max(180,height))
 local columns=width>=450 and 3 or 2
 local cellWidth=math.floor((list.AbsoluteSize.X-16-(columns-1)*12)/columns)
 grid.FillDirectionMaxCells=columns
 grid.CellSize=UDim2.fromOffset(math.max(70,cellWidth),230)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
menu:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
menu.InventoryButton.Activated:Connect(function()
 panel.Visible=not panel.Visible
 if panel.Visible then updateWin() refreshState() layout() end
end)
panel.CloseButton.Activated:Connect(function() panel.Visible=false end)
purchaseRemote.OnClientEvent:Connect(function(result)
 local itemId=typeof(result)=="table" and result.ItemId or nil
 if itemId then pending[itemId]=nil end
 if typeof(result)=="table" and not applyState(result.State) then refreshState() end
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
