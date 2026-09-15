local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local WorldPassConfig=require(RS.Config:WaitForChild("WorldPassConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local function passIdFor(card)
 if card:GetAttribute("PurchaseKind")=="DoubleWin" then return WorldPassConfig.GetDoubleWinPassId(WorldPassConfig.GetWorld(game.PlaceId)) end
 return tonumber(card:GetAttribute("PurchaseKey"))
end
local player=Players.LocalPlayer
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local shop=gui:WaitForChild("ShopPanel")
local responsiveScale=shop:FindFirstChild("ResponsiveScale") or Instance.new("UIScale")
responsiveScale.Name="ResponsiveScale"
responsiveScale.Scale=1
responsiveScale.Parent=shop
local function layoutShop()
 require(RS.Modules.ResponsivePanels).Fit(shop,gui)
end

local holder=shop:WaitForChild("MainScrollingFrame"):WaitForChild("Holder")
-- Reuse authored cards and their layout; definitions supply all Dumbbell values.
local DumbbellMaster=require(RS.Config:WaitForChild("DumbbellItemMaster"))
local function syncDumbbellCards()
 local existing={}
 local template
 local firstOrder
 for _,card in ipairs(holder:GetChildren()) do
  if card:IsA("Frame") and card:GetAttribute("PurchaseKind")=="Dumbbell" then
   existing[card:GetAttribute("PurchaseKey")]=card
   if not firstOrder or card.LayoutOrder<firstOrder then
    firstOrder=card.LayoutOrder;template=card
   end
  end
 end
 if not template then return end
 for order,item in ipairs(DumbbellMaster.GetSorted()) do
  local card=existing[item.ItemId]
  if not card then
   card=template:Clone()
   card.Name="Dumbbell_"..item.ItemId
   card:SetAttribute("PurchaseKey",item.ItemId)
   card.Parent=holder
  end
  card.LayoutOrder=firstOrder+order-1
  card:SetAttribute("ShopOrder",card.LayoutOrder)
  card:SetAttribute("ShopSection","Dumbbells")
  local icon=card:FindFirstChild("Icon")
  local title=card:FindFirstChild("Title")
  local price=card:FindFirstChild("PriceTag",true)
  if icon then icon.Image=item.Image end
  if title then title.Text="+"..tostring(item.StrengthBonus).." Strength" end
  if price then price.Text=tostring(item.PriceWin) end
 end
end
syncDumbbellCards()
local ItemMaster=require(RS.Config:WaitForChild("ItemMaster"))
local itemOrder=20
for _,card in ipairs(holder:GetChildren()) do
 if card:IsA("Frame") and card:GetAttribute("PurchaseKind")=="Item" then
  itemOrder+=1;card.LayoutOrder=itemOrder
  local item=ItemMaster.Get(card:GetAttribute("PurchaseKey"))
  if item then
   card.Visible=item.ShopPurchasable==true
   local price=card:FindFirstChild("PriceTag",true)
   if price then price.Text=tostring(item.WinPrice) end
   local icon=card:FindFirstChild("Icon")
   if icon then icon.Image=item.Image end
   local currency=card:FindFirstChild("CurrencyIcon",true)
   if currency then currency.Image=gui.WinLabel.TrophyIcon.Image end
  end
 end
end

local dumbbellRemote=RS.Remotes:WaitForChild("DumbbellPurchaseRequest")
local itemRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local doubleWinRemote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
local pending=false

task.spawn(function()
 gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutShop)
menu:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutShop)
layoutShop()


end)


local function setOpen(open)
 shop.Visible=open
 if open then
  layoutShop()
  local inventory=gui:FindFirstChild("InventoryPanel")
  local merge=gui:FindFirstChild("MergePanel")
  local rebirth=gui:FindFirstChild("RebirthPanel")
  if inventory then inventory.Visible=false end
  if merge then merge.Visible=false end
  if rebirth then rebirth.Visible=false end
 end
end

local function applyButtonLook(button)
 local original=button.Size
 local hoverRate=tonumber(button:GetAttribute("Ui-Hover-Rate")) or 1.08
 local clickRate=tonumber(button:GetAttribute("Ui-Click-Rate")) or .9
 local function scaled(rate)
  return UDim2.new(original.X.Scale*rate,original.X.Offset*rate,original.Y.Scale*rate,original.Y.Offset*rate)
 end
 button.MouseEnter:Connect(function()
  TweenService:Create(button,TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=scaled(hoverRate)}):Play()
 end)
 button.MouseLeave:Connect(function()
  TweenService:Create(button,TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=original}):Play()
 end)
 button.MouseButton1Down:Connect(function()
  TweenService:Create(button,TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=scaled(clickRate)}):Play()
 end)
 button.MouseButton1Up:Connect(function()
  TweenService:Create(button,TweenInfo.new(.2,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out),{Size=scaled(hoverRate)}):Play()
 end)
end

local function purchase(card)
 if pending then return end
 local kind=card:GetAttribute("PurchaseKind")
 local key=card:GetAttribute("PurchaseKey")
 if typeof(kind)~="string" or typeof(key)~="string" then return end
 pending=true
 if kind=="GamePass" then
  local passId=tonumber(key)
  if passId then
   local ok=pcall(function() MarketplaceService:PromptGamePassPurchase(player,passId) end)
   if not ok then pending=false end
  else pending=false end
 elseif kind=="DoubleWin" then
  doubleWinRemote:FireServer("Prompt")
  task.delay(.5,function() pending=false end)
 elseif kind=="Dumbbell" then
  dumbbellRemote:FireServer(key)
 elseif kind=="Item" then
  itemRemote:FireServer(key)
 else
  pending=false
 end
end

for _,card in ipairs(holder:GetChildren()) do
 if card:IsA("Frame") and card:GetAttribute("PurchaseKind") and card:GetAttribute("PurchaseKind")~="ShopProduct" and card:GetAttribute("PurchaseKind")~="WinProduct" then
  local button=card:FindFirstChild("Purchase",true)
  if button and button:IsA("TextButton") then
   applyButtonLook(button)
   Responsive.ConnectActivation(button,function() purchase(card) end)
  end
  local gift=card:FindFirstChild("Gift")
  if gift and gift:IsA("GuiButton") then gift.Active=false end
 end
end

local close=shop.Top:WaitForChild("Close")
applyButtonLook(close)
Responsive.ConnectActivation(close,function() setOpen(false) end)
menu.ShopButton.Activated:Connect(function() setOpen(not shop.Visible) end)
for _,name in ipairs({"InventoryButton","RebirthButton","SkipButton","MergeButton"}) do
 local button=menu:FindFirstChild(name)
 if button and button:IsA("GuiButton") then button.Activated:Connect(function() setOpen(false) end) end
end

dumbbellRemote.OnClientEvent:Connect(function() pending=false end)
itemRemote.OnClientEvent:Connect(function() pending=false end)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(finishedPlayer)
 if finishedPlayer==player then pending=false end
end)
player:GetAttributeChangedSignal("HasWorld1DoubleWin"):Connect(function() pending=false end)

local function refreshEssentialPassDisplays()
for _,card in ipairs(holder:GetChildren()) do
  if card:IsA("Frame") then
   local kind=card:GetAttribute("PurchaseKind")
   if kind=="GamePass" or kind=="DoubleWin" then
    local passId=passIdFor(card)
    if kind=="DoubleWin" then
     local title=card:FindFirstChild("Title")
     if title then title.Text="x"..tostring(WorldPassConfig.GetWinMultiplier(WorldPassConfig.GetWorld(game.PlaceId))).." Win" end
    end
    local button=card:FindFirstChild("Purchase",true)
    local priceTag=button and button:FindFirstChild("PriceTag",true)
    if passId and priceTag then
     local ownOk,owned=pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId) end)
     if ownOk and owned==true then
      priceTag.Text="OWNED"
      local currencyIcon=button:FindFirstChild("CurrencyIcon")
      if currencyIcon then currencyIcon.Visible=false end
     else
      local price,source=MarketplacePrice.Get(passId,Enum.InfoType.GamePass,nil)
      MarketplacePrice.Apply(priceTag,price,source," Robux")
      if price~=nil then
       local currencyIcon=button:FindFirstChild("CurrencyIcon")
       if currencyIcon then currencyIcon.Visible=true end
      end
     end
    end
   end
  end
 end
end
task.spawn(refreshEssentialPassDisplays)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(finishedPlayer)
 if finishedPlayer==player then task.delay(0.1,refreshEssentialPassDisplays) end
end)
