local PurchaseHUD=require(game:GetService("ReplicatedStorage").Modules.HUDLayout)
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Badges=require(RS.Modules:WaitForChild("BadgeRenderer"))
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local ElementSetBonus=require(RS.Modules:WaitForChild("ElementSetBonus"))
local Products=require(RS.Config:WaitForChild("DeveloperProductConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local PriceFormat=require(RS.Modules:WaitForChild("NumberFormat"))
local robuxPrices={}
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local winRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local robuxRemote=RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")
local shell=script.Parent:WaitForChild("InventoryPanel")
local trophyImage=script.Parent:WaitForChild("WinLabel"):WaitForChild("TrophyIcon").Image
local page=shell.Content.Items
local list=page.OwnedItems
local owned,equipped={},{}
local stateLoaded=false
local equipmentGeneration
local function worldLocked(id)
 local item=Master.Get(id)
 return item and item.WorldId==2 and (owned[id] or 0)<=0 and equipped[item.ItemType]~=id
  and player:GetAttribute("World2Visited")~=true
end
local function visibleItem(item)
 return (item.WorldId or 1)==1 or player:GetAttribute("World1Cleared")==true
end
local selectedId,pending
local Forge=require(RS.Modules.ForgeClient)
local Sale=require(RS.Modules.ItemSale)
local SaleView=require(RS.Modules.DumbbellInventoryView)
local sale=SaleView.CreateSalePopup(page,"ItemSellPanel")
local saleId
local function closeSale()saleId=nil;sale.Popup.Visible=false end
local function updateSale()
 local unit=saleId and Sale.UnitPrice(saleId)
 if not unit or not shell.Visible or not page.Visible then closeSale();return end
 local available=Sale.Available(saleId,owned,equipped)
 local enabled=available>0 and not Forge.IsPending() and not pending
 SaleView.Skin(sale.One,PriceFormat.Price(unit),"Price",enabled)
 SaleView.Skin(sale.All,PriceFormat.Price(unit*available),"All",enabled)
 local size=PurchaseHUD.GetLocalSize(page)
 local w=math.min(SaleView.Geometry.PopupWidth,size.X-12)
 local h=math.min(SaleView.Geometry.PopupHeight,size.Y-12)
 sale.Popup.AnchorPoint=Vector2.new(.5,.5);sale.Popup.Position=UDim2.fromScale(.5,.5);sale.Popup.Size=UDim2.fromOffset(w,h)
 sale.Arrow.Visible=false
 sale.Title.Position=UDim2.fromOffset(18,8);sale.Title.Size=UDim2.fromOffset(w-36,72)
 sale.CloseButton.Position=UDim2.fromOffset(w-76,12);sale.CloseButton.Size=UDim2.fromOffset(60,60)
 local bw=(w-44)/2
 sale.One.Position=UDim2.fromOffset(16,94);sale.One.Size=UDim2.fromOffset(bw,h-110)
 sale.All.Position=UDim2.fromOffset(28+bw,94);sale.All.Size=UDim2.fromOffset(bw,h-110)
 sale.Popup.Visible=true
 PurchaseHUD.RefitPurchaseButton(sale.One);PurchaseHUD.RefitPurchaseButton(sale.All)
end
local function sell(all)
 if not saleId or pending or Forge.IsPending() then return end
 local id=saleId;local unit=Sale.UnitPrice(id);local available=Sale.Available(id,owned,equipped)
 if not unit or available<1 then updateSale();return end
 Forge.Request("SellItem",{ItemId=id,Count=all and available or 1,ExpectedCount=owned[id] or 0,UnitPrice=unit})
 updateSale()
end
sale.One.Activated:Connect(function()sell(false)end)
sale.All.Activated:Connect(function()sell(true)end)
sale.CloseButton.Activated:Connect(closeSale)
shell:GetPropertyChangedSignal("Visible"):Connect(function()if not shell.Visible then closeSale()end end)
page:GetPropertyChangedSignal("Visible"):Connect(function()if not page.Visible then closeSale()end end)
page:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSale)
local rarityIndex=1
local ranks,rankItems,rankRarities={},{},{}
for id,item in pairs(Master.GetAll()) do
 local rank=Presentation.ItemRank(item)
 if rank>0 then
  if not rankItems[rank] then rankItems[rank]={};rankRarities[rank]=item.Rarity;table.insert(ranks,rank) end
  table.insert(rankItems[rank],id)
 end
end
table.sort(ranks)
local kinds=Master.Kinds
-- Item-only reference presentation. Existing remotes/configs remain authoritative.
local Responsive=require(RS.Modules.ResponsivePanels)
local gui=script.Parent
local donor=game.StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card01_SecretPack
local purchaseText=game.StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy.Main.Amount
-- Existing purchased HatchClient TEXT_FONT; keep Win/Robux amount artwork intact.
local effectFont=Font.fromEnum(Enum.Font.GothamBlack)
local STAR_GOLD="rbxassetid://76134658177553"
local STAR_GREY="rbxassetid://126441080731699"
local checkTemplate=RS.Assets.Templates.PetInventory.Main.Checkmark
local slots,tabs,rarityBadges={},{},{}
local categoryImages={
 Protein=Master.Get("PROTEIN_COMMON_FIRE").Image,
 Glove=Master.Get("GLOVE_COMMON_FIRE").Image,
 TrainingBelt=Master.Get("TRAININGBELT_COMMON_FIRE").Image,
}
local palettes={
 Common={Color3.fromRGB(145,151,159),Color3.fromRGB(58,64,75),Color3.fromRGB(200,205,213)},
 Uncommon={Color3.fromRGB(0,209,58),Color3.fromRGB(0,103,36),Color3.fromRGB(49,255,92)},
 Rare={Color3.fromRGB(0,156,255),Color3.fromRGB(0,57,152),Color3.fromRGB(31,224,255)},
 Epic={Color3.fromRGB(165,0,255),Color3.fromRGB(67,0,151),Color3.fromRGB(240,39,255)},
 Legendary={Color3.fromRGB(255,217,36),Color3.fromRGB(218,130,0),Color3.fromRGB(255,245,96)},
}
local function layer(x,z)
 x:SetAttribute("ResponsiveOriginalZ",z)
 x.ZIndex=z+(shell.ZIndex>=200 and 200 or 0)
end
local function rect(x,a,b,w,h)
 x.AnchorPoint=Vector2.zero;x.Position=UDim2.fromOffset(a,b);x.Size=UDim2.fromOffset(w,h)
end
local function label(parent,name,value,pos,size,max)
 local t=purchaseText:Clone();t.Name=name;t.Text=value
 for _,x in t:GetChildren() do if not x:IsA("UIStroke") then x:Destroy() end end
 t:SetAttribute("InventoryReferenceOwned",true)
 t.AnchorPoint=Vector2.zero;t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.AutomaticSize=Enum.AutomaticSize.None
 t.FontFace=purchaseText.FontFace;t.TextColor3=Color3.new(1,1,1)
 t.TextTransparency=0;t.TextStrokeColor3=Color3.new();t.TextStrokeTransparency=1
 t.TextWrapped=false;t.TextScaled=true;t.AutoLocalize=false;t.TextXAlignment=Enum.TextXAlignment.Center
 t.Active=false;t.Visible=true;layer(t,40);t.Parent=parent
 local ink=t:FindFirstChildOfClass("UIStroke")
 if ink then ink.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;ink.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;ink.Thickness=2;ink.Color=Color3.new();ink.Enabled=true end
 local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize=8;limit.MaxTextSize=max or 32;limit.Parent=t
 return t
end
local function icon(parent,name,id,pos,size,z)
 local x=Instance.new("ImageLabel");x.Name=name;x.Image=id;x.Position=pos;x.Size=size
 x.BackgroundTransparency=1;x.ScaleType=Enum.ScaleType.Fit;x.Active=false;layer(x,z or 36);x.Parent=parent
 return x
end
local function surface(x,rarity,selected)
 local colors=palettes[rarity] or palettes.Common
 x:SetAttribute("InventoryReferenceOwned",true);x.BorderSizePixel=0;x.BackgroundTransparency=0;x.BackgroundColor3=Color3.new(1,1,1)
 local corner=x:FindFirstChildOfClass("UICorner") or Instance.new("UICorner");corner.CornerRadius=UDim.new(0,18);corner.Parent=x
 for _,name in {"OuterUIStroke","InnerUIStroke","UIGradient"} do
  if not x:FindFirstChild(name) then local part=donor[name]:Clone();part.Parent=x end
 end
 x.UIGradient.Color=ColorSequence.new(colors[1],colors[2]);x.UIGradient.Rotation=90;x.UIGradient.Enabled=true
 x.OuterUIStroke.Color=Color3.new();x.OuterUIStroke.Thickness=4;x.OuterUIStroke.Enabled=true
 x.InnerUIStroke.Color=selected and Color3.new(1,1,1) or colors[3];x.InnerUIStroke.Thickness=3;x.InnerUIStroke.Enabled=true
 for _,s in {x.OuterUIStroke,x.InnerUIStroke} do s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize end
 if not x:FindFirstChild("StudPattern") then
  local stud=donor.StudPattern:Clone();stud.Name="StudPattern";stud.Active=false
  stud.AnchorPoint=Vector2.zero;stud.Position=UDim2.new();stud.Size=UDim2.fromScale(1,1)
  stud.ScaleType=Enum.ScaleType.Tile;stud.TileSize=UDim2.fromOffset(100,100);stud.ImageTransparency=.87
  layer(stud,33);stud.Parent=x
 end
end
local function check(parent,name)
 local x=checkTemplate:Clone();x.Name=name;x.Visible=false;x.Active=false
 x.AnchorPoint=Vector2.zero;x.Position=UDim2.new(1,-54,0,8);x.Size=UDim2.fromOffset(46,46)
 layer(x,43);x.Parent=parent;return x
end
local function raritySelected(button,selected)
 button:SetAttribute("RaritySelected",selected)
 button.OuterUIStroke.Color=selected and Color3.new(1,1,1) or Color3.fromRGB(8,10,18)
 button.OuterUIStroke.Thickness=selected and 6 or 3
 button.InnerUIStroke.Color=Color3.fromRGB(255,250,210)
 button.InnerUIStroke.Thickness=3
 button.InnerUIStroke.Enabled=selected
 -- No hover/press palette is used as the persistent selection indicator.
 button.AutoButtonColor=false
end
local function stars(parent,item,pos,size)
 local row=parent:FindFirstChild("RarityStars")
 if not row then
  row=Instance.new("Frame");row.Name="RarityStars";row.BackgroundTransparency=1;row.Active=false;layer(row,39);row.Parent=parent
 end
 row.Position=pos;row.Size=size
 Presentation.SetItemImageStars(row,item,40)
 for _,star in row:GetDescendants() do if star:IsA("GuiObject") then layer(star,40) end end
 return row
end
local function effect(item)
 local value=ElementSetBonus.GetBaseEffect(item)
 if equipped[item.ItemType]==item.ItemId and (owned[item.ItemId] or 0)>0 then
  value=ElementSetBonus.GetEffects(owned,equipped)[item.ItemType]
 end
 if item.ItemType=="Protein" then return "Strength +"..tostring(value) end
 if item.ItemType=="Glove" then return string.format("Boss Damage +%g%%",value*100) end
 return "Treadmill +"..tostring(value).."×"
end

-- Claim this page before the shared skin sees any new descendants.
page:SetAttribute("InventoryReferenceOwned",true)
page:SetAttribute("ItemReferenceLayout",true)
for _,x in page:GetChildren() do if x:IsA("GuiObject") then x.Visible=x==page.Equipped or x==list or x==page.Status end end
for _,x in page.Equipped:GetChildren() do
 if x:IsA("GuiObject") then x.Visible=false elseif x:IsA("UIStroke") or x:IsA("UIGradient") then x.Enabled=false end
end
page.Equipped.BackgroundTransparency=1;page.Equipped.Active=false
local equipmentHeader=Instance.new("Frame");equipmentHeader.Name="EquipmentHeader";layer(equipmentHeader,32)
surface(equipmentHeader,"Epic");equipmentHeader.Parent=page.Equipped
local equipmentTitle=label(equipmentHeader,"Title","Equipped",UDim2.fromScale(.02,.1),UDim2.fromScale(.48,.8),40)
equipmentTitle.FontFace=Font.fromEnum(Enum.Font.GothamBlack)
local bestButton=Instance.new("TextButton");bestButton.Name="BestEquipButton";bestButton.Text="Best Equip"
bestButton.FontFace=purchaseText.FontFace;bestButton.TextScaled=true;bestButton.TextColor3=Color3.new(1,1,1)
bestButton.TextStrokeColor3=Color3.new();bestButton.TextStrokeTransparency=0;bestButton.AutoLocalize=false
bestButton.Position=UDim2.fromScale(.51,.14);bestButton.Size=UDim2.fromScale(.47,.72)
surface(bestButton,"Epic");bestButton.StudPattern.Visible=false;layer(bestButton,42);bestButton.Parent=equipmentHeader
bestButton.TextTransparency=1;bestButton.TextStrokeTransparency=1
local bestText=label(bestButton,"Label",bestButton.Text,UDim2.fromScale(.03,.08),UDim2.fromScale(.94,.84),30)
bestText.FontFace=Font.fromEnum(Enum.Font.GothamBlack);layer(bestText,44)
require(RS.Modules.EquipmentButtonStyle).Apply(bestButton)
bestButton:GetPropertyChangedSignal("Text"):Connect(function() bestText.Text=bestButton.Text end)
local bestLimit=Instance.new("UITextSizeConstraint");bestLimit.MinTextSize=8;bestLimit.MaxTextSize=32;bestLimit.Parent=bestButton
bestButton.Activated:Connect(function()
 if pending then return end
 pending="BestEquip";bestButton.Text="Equipping...";bestButton.Interactable=false
 page.Status.Text="";equipRemote:FireServer(nil,"BestEquip",equipmentGeneration)
end)
for _,kind in ipairs(kinds) do
 local s=Instance.new("TextButton");s.Name=kind.."Socket";s.Text="";s.AutoButtonColor=false
 surface(s,"Common");layer(s,32);s.Parent=page.Equipped
 local pic=icon(s,"EquippedImage",categoryImages[kind],UDim2.fromScale(.02,.07),UDim2.fromScale(.44,.86))
 local none=label(s,"None","None",UDim2.fromScale(.46,.32),UDim2.fromScale(.52,.36),30)
 local row=stars(s,nil,UDim2.fromScale(.44,.40),UDim2.fromScale(.54,.30))
 local tick=check(s,"EquippedCheck");tick.Position=UDim2.fromScale(.36,.06);tick.Size=UDim2.fromScale(.14,.28)
 slots[kind]={image=pic,none=none,stars=row,socket=s,check=tick}
 s.Activated:Connect(function()
  if pending or not Master.Get(equipped[kind]) then return end
  pending=kind;equipRemote:FireServer(kind,"Unequip",equipmentGeneration)
 end)
end
local tabbar=Instance.new("ScrollingFrame");tabbar.Name="RarityTabs";tabbar.BackgroundTransparency=1;tabbar.BorderSizePixel=0
tabbar.Active=true;tabbar.ScrollingDirection=Enum.ScrollingDirection.Y;tabbar.ScrollBarThickness=5;tabbar.CanvasSize=UDim2.new()
tabbar.ClipsDescendants=true;layer(tabbar,35);tabbar.Parent=page
list.BackgroundTransparency=1;list.Visible=true;list.Active=true;list.ScrollingEnabled=true
list.ScrollingDirection=Enum.ScrollingDirection.Y;list.AutomaticCanvasSize=Enum.AutomaticSize.None
list.CanvasSize=UDim2.new();list.ScrollBarThickness=9;list.ScrollBarImageColor3=Color3.fromRGB(191,202,223)
list.ClipsDescendants=true;layer(list,31)
for _,x in list:GetChildren() do
 if x:IsA("GuiObject") then x:Destroy() elseif x:IsA("UIStroke") or x:IsA("UIGradient") then x.Enabled=false end
end
local padding=list:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
padding.PaddingTop=UDim.new(0,5);padding.PaddingBottom=UDim.new(0,12)
padding.PaddingLeft=UDim.new(0,5);padding.PaddingRight=UDim.new(0,16);padding.Parent=list
local grid=list:FindFirstChildOfClass("UIGridLayout")
grid.CellPadding=UDim2.fromOffset(14,14);grid.SortOrder=Enum.SortOrder.LayoutOrder
local function layout() Responsive.LayoutItems(gui,page,list,grid) end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layout)
shell.ResponsiveScale:GetPropertyChangedSignal("Scale"):Connect(layout)
page:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
page.Status:GetPropertyChangedSignal("Text"):Connect(layout)
page.Status.BackgroundTransparency=1;page.Status.Active=false;page.Status.TextScaled=true
page.Status.FontFace=purchaseText.FontFace;page.Status.TextColor3=Color3.new(1,1,1)
page.Status.TextStrokeColor3=Color3.new();page.Status.TextStrokeTransparency=0;layer(page.Status,44)
local render
local function request(remote,id)
 if not stateLoaded or (remote~=equipRemote and worldLocked(id)) then return end
 if pending then return end
 pending=id;page.Status.Text="..."
 if remote==equipRemote then remote:FireServer(id,"Equip",equipmentGeneration) else remote:FireServer(id) end
end
local function priceButton(card,name,price,imageId,remote,itemId)
 local b=Instance.new("TextButton");b.Name=name;b.Text="";b.BackgroundTransparency=1;layer(b,42);b.Parent=card
 local amount=label(b,"Price",PriceFormat.PriceText(price),UDim2.new(),UDim2.fromScale(1,1),32)
 if imageId then icon(b,"Currency",imageId,UDim2.new(),UDim2.fromScale(.2,1),43) end
 -- Exact existing Win/Robux artwork, gradients, amount font and currency glyph.
 PurchaseHUD.BindPurchaseButton(b,name=="WinPurchase" and "Win" or "Robux",amount)
 local visual=b:FindFirstChild("PurchasedButtonVisual")
 if visual then
  local objects={visual};for _,x in visual:GetDescendants() do if x:IsA("GuiObject") then table.insert(objects,x) end end
  for _,x in objects do x:SetAttribute("ResponsiveOriginalZ",x.ZIndex-(shell.ZIndex>=200 and 200 or 0)) end
 end
 b.Activated:Connect(function()
  if (owned[itemId] or 0)>0 then return end
  request(remote,itemId)
 end)
 return b
end
render=function()
 -- Keep scroll position across acknowledgements, counts, and notification refreshes.
 local scroll=list.CanvasPosition
 for _,c in list:GetChildren() do if c:GetAttribute("InventoryItemCard") then c:Destroy() end end
 for kind,s in pairs(slots) do
  local item=Master.Get(equipped[kind])
  if item and (item.ItemType~=kind or (owned[item.ItemId] or 0)<=0) then item=nil end
  s.image.Image=item and item.Image or categoryImages[kind]
  s.image.ImageColor3=Color3.new(1,1,1);s.image.ImageTransparency=item and 0 or .35
  s.none.Visible=item==nil;s.check.Visible=item~=nil
  surface(s.socket,item and item.Rarity or "Common")
  stars(s.socket,item,UDim2.fromScale(.44,.40),UDim2.fromScale(.54,.30))
  s.socket.Active=item~=nil;s.socket.Interactable=item~=nil
 end
 local visibleRanks={}
 for _,rank in ipairs(ranks) do
  local visible,unseen=false,false
  for _,id in ipairs(rankItems[rank]) do
   if visibleItem(Master.Get(id)) then visible=true;unseen=unseen or page:GetAttribute("UnseenItem_"..id)==true end
  end
  tabs[rank].Visible=visible;rarityBadges[rank].Visible=visible and unseen
  if visible then table.insert(visibleRanks,rank) end
 end
 if not tabs[rarityIndex] or not tabs[rarityIndex].Visible then rarityIndex=visibleRanks[1] end
 for _,rank in ipairs(ranks) do
  local t=tabs[rank]
  surface(t,rankRarities[rank]);raritySelected(t,rank==rarityIndex);t.StudPattern.Visible=false
 end
 local ids={}
 for id,item in pairs(Master.GetAll()) do if Presentation.ItemRank(item)==rarityIndex and visibleItem(item) then table.insert(ids,id) end end
 local typeOrder={};for i,kind in ipairs(kinds) do typeOrder[kind]=i end
 table.sort(ids,function(a,b)
  local x,y=Master.Get(a),Master.Get(b)
  if Presentation.ItemRank(x)~=Presentation.ItemRank(y) then return Presentation.ItemRank(x)<Presentation.ItemRank(y) end
  if x.Element~=y.Element then return table.find(Master.Elements,x.Element)<table.find(Master.Elements,y.Element) end
  return (typeOrder[x.ItemType] or 99)<(typeOrder[y.ItemType] or 99)
 end)
 for order,id in ipairs(ids) do
  local item=Master.Get(id)
  local c=Instance.new("TextButton");c.Name=id;c.Text="";c.AutoButtonColor=false
  c.LayoutOrder=order;c:SetAttribute("InventoryItemCard",true)
  surface(c,item.Rarity,selectedId==id);layer(c,32);c.Parent=list
  local picture=icon(c,"Icon",item.Image,UDim2.new(),UDim2.new(),36)
  local locked=worldLocked(id)
  Presentation.SetInventorySecret(c,picture,stateLoaded and (owned[id] or 0)<=0 and equipped[item.ItemType]~=id)
  local effectLabel=label(c,"Effect",effect(item),UDim2.new(),UDim2.new(),34)
  effectLabel.FontFace=effectFont
  effectLabel:FindFirstChildOfClass("UIStroke").Thickness=2.5
  stars(c,item,UDim2.new(),UDim2.new())
  local tick=check(c,"EquippedCheck");tick.Visible=equipped[item.ItemType]==id and (owned[id] or 0)>0
  local count=label(c,"OwnedCount","×"..tostring(owned[id] or 0),UDim2.fromOffset(8,8),UDim2.fromOffset(65,28),24)
  count.Visible=(owned[id] or 0)>1;count.TextXAlignment=Enum.TextXAlignment.Left
  c.Activated:Connect(function()
   if sale.Popup.Visible or Forge.IsPending() or worldLocked(id) or not stateLoaded then return end
   selectedId=id
   if (owned[id] or 0)>0 and equipped[item.ItemType]~=id and not pending then request(equipRemote,id) end
   render()
  end)
  if (owned[id] or 0)>0 then
   local unit=Sale.UnitPrice(id)
   if unit then
    local sellButton=Instance.new("TextButton");sellButton.Name="SellButton";sellButton.Text="Sell";layer(sellButton,42);sellButton.Parent=c
    SaleView.Skin(sellButton,"Sell","Sell",Sale.Available(id,owned,equipped)>0 and not Forge.IsPending() and not pending)
    sellButton.Activated:Connect(function()
     if pending or Forge.IsPending() then return end
     saleId=id;updateSale();task.spawn(Forge.Refresh)
    end)
   end
   local isEquipped=equipped[item.ItemType]==id
   local b=Instance.new("TextButton");b.Name=isEquipped and "EquippedStatus" or "EquipButton";b.Text=""
   surface(b,"Uncommon");b.StudPattern.Visible=false;layer(b,42);b.Parent=c
   local text=label(b,"Label",isEquipped and "Equipped" or "Equip",UDim2.fromScale(.03,.08),UDim2.fromScale(.94,.84),34);layer(text,44)
   Presentation.SetEquipped(b,isEquipped)
   text.AutoLocalize=true
   b.Active=not isEquipped;b.Interactable=not isEquipped
   if not isEquipped then
    if page:GetAttribute("UnseenItem_"..id)==true then
     local badge=Badges.GetOrClone(gui.LeftMenu.InventoryButton.NotificationBadge,b,"ItemGuideBadge")
     badge.AnchorPoint=Vector2.new(1,0);badge.Position=UDim2.new(1,-2,0,2);badge.Size=UDim2.fromOffset(24,24)
     badge.Visible=true;badge.Active=false;layer(badge,47)
     for _,x in badge:GetDescendants() do if x:IsA("GuiObject") then x.Active=false;layer(x,48) end end
    end
    b.Activated:Connect(function()
     if (owned[id] or 0)>0 and equipped[item.ItemType]~=id then request(equipRemote,id) end
    end)
   end
  elseif not locked and item.ShopPurchasable then
   priceButton(c,"WinPurchase",item.WinPrice,trophyImage,winRemote,id)
  elseif not locked and item.RobuxPurchasable then
   priceButton(c,"RobuxPurchase",robuxPrices[item.Rarity] or item.RobuxPrice,"rbxasset://textures/ui/common/robux.png",robuxRemote,id)
  end
 end
 layout();list.CanvasPosition=scroll;updateSale()
end
for _,n in ipairs(ranks) do
 local b=Instance.new("TextButton");b.Name="Star"..n;b.Text="";b.AutoButtonColor=false
 b.LayoutOrder=n;b:SetAttribute("ItemRank",n)
 surface(b,rankRarities[n]);b.StudPattern.Visible=false;layer(b,36);b.Parent=tabbar
 local star=icon(b,"RankStar",STAR_GOLD,UDim2.fromScale(.34,.5),UDim2.fromScale(.34,.78),40)
 star.AnchorPoint=Vector2.new(.5,.5);star.ImageColor3=Color3.new(1,1,1)
 local square=Instance.new("UIAspectRatioConstraint");square.AspectRatio=1;square.Parent=star
 local number=label(b,"Label",n>5 and "×"..n or tostring(n),UDim2.fromScale(n>5 and .49 or .53,.08),UDim2.fromScale(n>5 and .43 or .30,.84),40)
 number.FontFace=effectFont
 local badge=Badges.GetOrClone(gui.LeftMenu.InventoryButton.NotificationBadge,b,"RarityGuideBadge")
 badge.AnchorPoint=Vector2.new(1,0);badge.Position=UDim2.new(1,-2,0,2);badge.Size=UDim2.fromOffset(24,24)
 badge.Visible=false;badge.Active=false;layer(badge,47)
 for _,x in badge:GetDescendants() do if x:IsA("GuiObject") then x.Active=false;layer(x,48) end end
 tabs[n]=b;rarityBadges[n]=badge
 b.Activated:Connect(function() rarityIndex=n;list.CanvasPosition=Vector2.zero;render() end)
end
local function fit()
 Responsive.Fit(shell,gui);layout()
end
page:GetPropertyChangedSignal("Visible"):Connect(fit)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
task.defer(fit)
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 if state.EquipmentGeneration and state.EquipmentGeneration~=player:GetAttribute("ForgeSessionToken") then return false end
 equipmentGeneration=state.EquipmentGeneration or player:GetAttribute("ForgeSessionToken")
 owned=state.OwnedItems equipped=typeof(state.EquippedItems)=="table" and state.EquippedItems or {}
 stateLoaded=true
 render() return true
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if not ok or not applyState(state) then page.Status.Text="Inventory is loading. Please reopen."
 else page.Status.Text="" end
end
Forge.Changed:Connect(function(state)
 if state and state.Loaded and state.Token==player:GetAttribute("ForgeSessionToken") and state.OwnedItems then
  owned=state.OwnedItems;equipped=state.EquippedItems or equipped;stateLoaded=true
  equipmentGeneration=state.Token;render()
 else updateSale() end
end)
Forge.Completed:Connect(function(op,response)
 if op.Action~="SellItem" then return end
 page.Status.Text=response.Success and "" or tostring(response.Code)
 refresh();updateSale()
end)
-- Forge's confirmed snapshot already includes Items/equipment and refreshes this page.
RS.Remotes:WaitForChild("RunLootBanked").OnClientEvent:Connect(function()Forge.Refresh()end)
-- Notification attributes survive card rebuilds and inventory close/reopen.
local notificationRenderQueued=false
page.AttributeChanged:Connect(function(name)
 if string.sub(name,1,11)~="UnseenItem_" and string.sub(name,1,13)~="UnseenRarity_" then return end
 if notificationRenderQueued then return end
 notificationRenderQueued=true
 task.defer(function()
  notificationRenderQueued=false
  if script.Parent then render() end
 end)
end)
RS.Remotes:WaitForChild("EnemyDropGachaResult").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and result.OwnerUserId==player.UserId and result.Outcome=="ITEM" then refresh() end
end)
local function opened()
 if shell.Visible and page.Visible then
  refresh()
 end
end
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
page:GetPropertyChangedSignal("Visible"):Connect(opened)
for _,remote in ipairs({equipRemote,winRemote,robuxRemote}) do
 remote.OnClientEvent:Connect(function(result)
  local code=typeof(result)=="table" and result.Code
  if code~="PromptOpened" and code~="AwaitingReceipt" then
   pending=nil
   bestButton.Text="Best Equip"
   bestButton.Interactable=true
  end
  if typeof(result)~="table" or not applyState(result.State) then refresh() end
  page.Status.Text=typeof(result)=="table" and (result.Success and "" or (code=="Cancelled" and "" or tostring(code))) or "Please try again"
  if code=="NotEnoughWin" then local item=Master.Get(result.ItemId);if item then page.Status.Text="Not enough Win. Need "..PriceFormat.Price(item.WinPrice).." Win" end end
  if typeof(result)=="table" and result.Action=="BestEquip" then
   if result.Success then
    page.Status.Text=code=="AlreadyBestEquipped" and "Best items already equipped." or "Best items equipped."
   elseif code=="SaveFailed" then
    page.Status.Text="Equipment save failed. Please retry BEST EQUIP."
   end
  end
 end)
end
RS.Remotes:WaitForChild("ItemMergeRequest").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and shell.Visible then if not applyState(result.State) then refresh() end end
end)
player:GetAttributeChangedSignal("World2Visited"):Connect(function() if selectedId and worldLocked(selectedId) then selectedId=nil end;render() end)
player:GetAttributeChangedSignal("World1Cleared"):Connect(function()
 if selectedId and not visibleItem(Master.Get(selectedId)) then selectedId=nil end
 render()
end)
render()

task.spawn(function()
 for rarity,product in pairs(Products.ItemProducts) do
  robuxPrices[rarity]=MarketplacePrice.Get(product.ProductId,Enum.InfoType.Product,product.FallbackPrice)
 end
 if script.Parent then render() end
end)
