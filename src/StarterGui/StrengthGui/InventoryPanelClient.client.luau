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
 Presentation.ApplyInventoryContentFont(object)
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
local counts={}
local Forge=require(RS.Modules.ForgeClient)
local NumberFormat=require(RS.Modules.NumberFormat)
local View=require(RS.Modules.DumbbellInventoryView)
local view=View.Mount(panel,gui)
local stateLoaded=false
local equipmentGeneration
local equipped=""
local pending={}
local layout
local function worldLocked(itemId)
 local item=Master.Get(itemId)
 return item and item.WorldId==2
  and (not stateLoaded or player:GetAttribute("World2Visited")~=true)
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
 local requestPending=next(pending)~=nil or Forge.IsPending()
 View.Skin(panel.Equipped.BestEquipButton,"Best Equip","Best",stateLoaded and next(owned)~=nil and not requestPending)
 for itemId,card in pairs(cards) do
  local hidden=worldLocked(itemId)
  card.Visible=not hidden
  card.Active=not hidden and stateLoaded
  card.Interactable=card.Active
  if hidden then Presentation.SetSelected(card,false) end
  card.OwnedCount.Text=(counts[itemId] or 0)>0 and ("×"..counts[itemId]) or ""
  local sale=card.SellButton
  sale.Visible=(counts[itemId] or 0)>0 and Master.Get(itemId).SellWin~=nil
  sale.Text="Sell"
  View.Skin(sale,"Sell","Sell",not hidden and stateLoaded and not requestPending)
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
   View.Skin(button,(isOwned or isEquipped) and button.Text or button.Price.Text,
    isEquipped and "Equipped" or isOwned and "Equip" or "Buy",button.Active)
   local visual=button:FindFirstChild("PurchasedButtonVisual");if visual then visual.Main.Amount.AutoLocalize=isOwned end
   card:SetAttribute("InventoryWorldLocked",false)
  end
 end
local item=Master.Get(equipped)
 panel.Equipped.Preview.Image=item and item.Image or ""
 panel.Equipped.ItemName.AutoLocalize=item==nil -- Only actual Dumbbell names stay English.
 panel.Equipped.ItemName.Text=item and item.Name or "None equipped"
 panel.Equipped.Multiplier.Text=item and ("+"..NumberFormat.Format(item.StrengthBonus).." STR") or ""
 if selectedId and worldLocked(selectedId) then selectedId=nil;panel:SetAttribute("SelectedItemId",nil) end
 if view.Selected then
  local saleItem=Master.Get(view.Selected)
  local available=math.max(0,(counts[view.Selected] or 0)-(equipped==view.Selected and 1 or 0))
  if worldLocked(view.Selected) then view:Close() else view:UpdateSale(saleItem,available,requestPending) end
 end
 if layout then layout() end
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedDumbbells)~="table" then return false end
 if state.EquipmentGeneration and state.EquipmentGeneration~=player:GetAttribute("ForgeSessionToken") then return false end
 equipmentGeneration=state.EquipmentGeneration or player:GetAttribute("ForgeSessionToken")
 owned=state.OwnedDumbbells
 counts=state.DumbbellCounts or {}
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
Responsive.ConnectActivation(panel.Equipped.BestEquipButton,function()
 if not stateLoaded or next(pending)~=nil or Forge.IsPending() or next(owned)==nil then return end
 pending.__BestEquip=true;updateButtons()
 equipRemote:FireServer("__BestEquip",nil,equipmentGeneration)
end)
local sortedItems=Master.GetSorted()
for order,item in ipairs(sortedItems) do
 local itemId=item.ItemId
 if item and item.Category=="Dumbbell" then
  local card=View.CreateCard(list,item,order)
  local buy=card.BuyButton
  local sell=card.SellButton
  Responsive.ConnectActivation(sell,function()
   if worldLocked(itemId) or not sell.Active or Forge.IsPending() then return end
   selectCard(itemId);view:Open(itemId,card);updateButtons()
  end)
  cards[itemId]=card
  card.Activated:Connect(function() selectCard(itemId) end)
  Responsive.ConnectActivation(buy,function()
   if worldLocked(itemId) or not stateLoaded then return end
   selectCard(itemId)
   if next(pending)~=nil or equipped==itemId then return end
   pending[itemId]=true
   updateButtons()
   if owned[itemId]==true then
    equipRemote:FireServer(itemId,nil,equipmentGeneration)
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
layout=function() view:Layout(cards) end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
shell.ResponsiveScale:GetPropertyChangedSignal("Scale"):Connect(layout)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
task.defer(layout)

local function updateEquippedPreview()
 local item=Master.Get(equipped)
 panel.Equipped.Preview.Image=item and item.Image or ""
 panel.Equipped.Multiplier.Text=item and ("+"..NumberFormat.Format(item.StrengthBonus).." STR") or ""
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
local function acceptForgeState(state)
 if state and state.Loaded then
  counts=state.DumbbellCounts or counts;equipped=state.EquippedDumbbell or equipped
  owned={} for id,n in pairs(counts) do if n>0 then owned[id]=true end end
 end
end
Forge.Changed:Connect(function(state) acceptForgeState(state);updateButtons() end)
local saleBusy=false
local function sellSelected(all)
 if saleBusy or Forge.IsPending() or next(pending)~=nil then return end
 local id=view.Selected
 if not id or worldLocked(id) then return end
 saleBusy=true
 local state=Forge.Refresh()
 acceptForgeState(state)
 local item=Master.Get(id)
 local available=state and state.Loaded and math.max(0,(state.DumbbellCounts[id] or 0)-(state.EquippedDumbbell==id and 1 or 0)) or 0
 if view.Selected==id and item and item.SellWin and available>0 then
  local ok,code=Forge.Request("SellDumbbell",{ItemId=id,Count=all and available or 1})
  if not ok then showStatus(code) end
 end
 saleBusy=false;updateButtons()
end
Responsive.ConnectActivation(view.One,function()sellSelected(false)end)
Responsive.ConnectActivation(view.All,function()sellSelected(true)end)
Responsive.ConnectActivation(view.CloseButton,function()view:Close()end)

Forge.Completed:Connect(function(op,result)
 if op.Action=="SellDumbbell" then
  refreshState();showStatus(result.Success and "Sold" or tostring(result.Code))
 end
end)
player:GetAttributeChangedSignal("ForgeInventoryRevision"):Connect(function() task.defer(refreshState) end)
updateButtons()
