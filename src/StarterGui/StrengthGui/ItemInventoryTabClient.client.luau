local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Badges=require(RS.Modules:WaitForChild("BadgeRenderer"))
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local player=Players.LocalPlayer
local Master=require(RS.Config:WaitForChild("ItemMaster"))
local ItemMultiplierConfig=require(RS.Config:WaitForChild("ItemMultiplierConfig"))
local Products=require(RS.Config:WaitForChild("DeveloperProductConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local robuxPrices={}
local stateRemote=RS.Remotes:WaitForChild("ItemInventoryState")
local equipRemote=RS.Remotes:WaitForChild("ItemEquipRequest")
local winRemote=RS.Remotes:WaitForChild("ItemPurchaseRequest")
local robuxRemote=RS.Remotes:WaitForChild("ItemRobuxPurchaseRequest")
local shell=script.Parent:WaitForChild("InventoryPanel")
local page=shell.Content.Items
local list=page.OwnedItems
local owned,equipped={},{}
local selectedId,pending
local rarityIndex=1
local rarities=Master.Rarities
local kinds=Master.Kinds
local names={Protein="Protein",Glove="Glove",TrainingBelt="Belt"}
local slots,tabs,rarityBadges={},{},{}
local categoryImages={
 Protein=Master.Get("PROTEIN_COMMON_FIRE").Image,
 Glove=Master.Get("GLOVE_COMMON_FIRE").Image,
 TrainingBelt=Master.Get("TRAININGBELT_COMMON_FIRE").Image,
}
local function style(o,color,radius)
 o.BackgroundColor3=color o.BorderSizePixel=0
 local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,radius or 12) c.Parent=o
 local s=Instance.new("UIStroke") s.Color=Color3.fromRGB(43,13,65) s.Thickness=2 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=o
 return s
end
local function label(parent,name,value,pos,size,z)
 local t=Instance.new("TextLabel") t.Name=name t.Text=value t.Position=pos t.Size=size
 t.BackgroundTransparency=1 t.Font=Enum.Font.GothamBlack t.TextColor3=Color3.new(1,1,1)
 t.TextScaled=true t.ZIndex=z or 35 t.Parent=parent
 local l=Instance.new("UITextSizeConstraint") l.MaxTextSize=30 l.MinTextSize=8 l.Parent=t
 return t
end
local function icon(parent,name,id,pos,size,z)
 local i=Instance.new("ImageLabel") i.Name=name i.Image=id i.Position=pos i.Size=size
 i.BackgroundTransparency=1 i.ScaleType=Enum.ScaleType.Fit i.ZIndex=z or 35 i.Parent=parent return i
end
page.Equipped.Size=UDim2.new(.44,0,1,0)
page.Owned.Position=UDim2.fromScale(.455,0) page.Owned.Size=UDim2.fromScale(.545,1)
page.Owned.Title.Text="Items"
page.Equipped.Hint.Visible=false
page.Equipped.Title.Text="Equip"
-- Header action, separate from the equipment sockets and item cards.
page.Equipped.Title.Size=UDim2.new(.34,-12,0,36)
local bestButton=Instance.new("TextButton")
bestButton.Name="BestEquipButton" bestButton.Text="BEST EQUIP"
bestButton.Position=UDim2.new(.36,0,0,12)
bestButton.Size=UDim2.new(.64,-12,0,36)
bestButton.Font=Enum.Font.GothamBlack bestButton.TextScaled=true
bestButton.TextColor3=Color3.new(1,1,1)
bestButton.TextStrokeColor3=Color3.new(0,0,0) bestButton.TextStrokeTransparency=.25
bestButton.ZIndex=35 bestButton.Parent=page.Equipped
style(bestButton,Color3.fromRGB(40,193,111),8)
local bestLimit=Instance.new("UITextSizeConstraint")
bestLimit.MinTextSize=8 bestLimit.MaxTextSize=22 bestLimit.Parent=bestButton
bestButton.Activated:Connect(function()
 if pending then return end
 pending="BestEquip"
 bestButton.Text="EQUIPPING..."
 bestButton.Interactable=false
 page.Status.Text=""
 equipRemote:FireServer(nil,"BestEquip")
end)

page.Empty.Visible=false
page.Status.Position=UDim2.new(.455,8,1,-22) page.Status.Size=UDim2.new(.545,-16,0,20)
page.Status.TextScaled=true
for n,kind in ipairs(kinds) do
 page.Equipped[kind].Visible=false
 local s=Instance.new("TextButton") s.Text="" s.Name=kind.."Socket" s.Position=UDim2.new(0,12,.14+(n-1)*.28,0)
 s.Size=UDim2.new(1,-24,.26,0) s.ZIndex=32 s.Parent=page.Equipped style(s,Color3.fromRGB(81,34,123))
 local studs=icon(s,"StudPattern","rbxassetid://111868739606818",UDim2.new(),UDim2.fromScale(1,1),32)
 studs.ScaleType=Enum.ScaleType.Tile studs.TileSize=UDim2.fromOffset(48,48) studs.ImageTransparency=.84
 local pic=icon(s,"EquippedImage",categoryImages[kind],UDim2.new(0,8,0,8),UDim2.new(.42,-12,1,-16),34)
 local none=label(s,"None","None",UDim2.new(.44,0,.1,0),UDim2.new(.56,-10,.8,0),35)
 none.TextWrapped=true
 none.TextXAlignment=Enum.TextXAlignment.Center
 none.Position=UDim2.new(.44,0,.3,0) none.Size=UDim2.new(.56,-10,.4,0)
 none.BackgroundTransparency=0
 style(none,Color3.fromRGB(99,99,112),8)
 local padding=Instance.new("UIPadding") padding.PaddingLeft=UDim.new(0,5) padding.PaddingRight=UDim.new(0,5) padding.Parent=none
 none:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=24
 local stars=label(s,"RarityStars","",UDim2.new(0,4,0,3),UDim2.new(.42,-4,.24,0),35)
 stars.TextColor3=Color3.fromRGB(255,220,65)
 stars:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=24
 stars.Visible=false
 slots[kind]={image=pic,none=none,stars=stars,socket=s}
 s.Activated:Connect(function()
  if pending or not Master.Get(equipped[kind]) then return end
  pending=kind equipRemote:FireServer(kind,"Unequip")
 end)
end
local tabbar=Instance.new("Frame") tabbar.Name="RarityTabs" tabbar.BackgroundTransparency=1
tabbar.Position=UDim2.new(.455,10,0,52) tabbar.Size=UDim2.new(.545,-24,0,34) tabbar.ZIndex=35 tabbar.Parent=page
list.Position=UDim2.new(.455,10,0,96) list.Size=UDim2.new(.545,-24,1,-124)
list.ScrollingDirection=Enum.ScrollingDirection.Y list.AutomaticCanvasSize=Enum.AutomaticSize.Y
list.CanvasSize=UDim2.new() list.ScrollBarThickness=6 list.ScrollBarImageColor3=Color3.fromRGB(233,157,255)
local grid=list:FindFirstChildOfClass("UIGridLayout")
grid.CellPadding=UDim2.fromOffset(8,8) grid.FillDirectionMaxCells=3 grid.SortOrder=Enum.SortOrder.LayoutOrder
local function layout()
 require(RS.Modules.ResponsivePanels).LayoutItems(script.Parent,page,list,grid)
end
list:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
list.ChildAdded:Connect(function() task.defer(layout) end)
shell.ResponsiveScale:GetPropertyChangedSignal("Scale"):Connect(layout)
task.defer(layout)
local render
local function request(remote,id)
 if pending then return end
 pending=id page.Status.Text="..." remote:FireServer(id)
end
local function priceButton(card,name,price,imageId,pos,size,color,remote,itemId)
 local b=Instance.new("TextButton") b.Name=name b.Text="" b.Position=pos b.Size=size b.ZIndex=35 b.Parent=card
 style(b,color,7)
 if imageId then
  icon(b,"Currency",imageId,UDim2.new(.16,0,.14,0),UDim2.new(.26,0,.72,0),36)
  label(b,"Price",tostring(price),UDim2.new(.43,0,.08,0),UDim2.new(.41,0,.84,0),36)
 else
  label(b,"Price",tostring(price),UDim2.new(.08,0,.08,0),UDim2.new(.84,0,.84,0),36)
 end
 if not remote then
  b.Active=false b.Interactable=false b.AutoButtonColor=false
  b.BackgroundColor3=Color3.fromRGB(70,53,87)
  if b:FindFirstChild("Currency") then b.Currency.ImageTransparency=.5 end
  b.Price.TextTransparency=.35
  return b
 end
 b.Activated:Connect(function()
  if (owned[itemId] or 0)>0 then return end
  request(remote,itemId)
 end)
 return b
end
render=function()
 for _,c in list:GetChildren() do if c:GetAttribute("InventoryItemCard") then c:Destroy() end end
 for kind,s in pairs(slots) do
  local item=Master.Get(equipped[kind])
  s.image.Image=item and item.Image or categoryImages[kind]
  s.image.Visible=true
  s.none.Visible=true
  s.none.Text=item and "Equipped" or "None"
  s.none.TextColor3=item and Color3.new(1,1,1) or Color3.fromRGB(214,214,222)
  s.none.BackgroundColor3=item and Color3.fromRGB(43,180,123) or Color3.fromRGB(99,99,112)
  s.image.ImageColor3=Color3.new(1,1,1)
  s.image.ImageTransparency=0
  s.socket.BackgroundColor3=Color3.fromRGB(81,34,123)
  s.stars.Visible=item~=nil
  s.stars.Text=item and string.rep("★",table.find(rarities,item.Rarity) or 0) or ""
  s.image.Position=item and UDim2.new(0,8,.29,0) or UDim2.new(0,8,0,8)
  s.image.Size=item and UDim2.new(.42,-12,.71,-6) or UDim2.new(.42,-12,1,-16)
 end
 for n,t in ipairs(tabs) do
  t.BackgroundColor3=n==rarityIndex and Color3.fromRGB(177,72,250) or Color3.fromRGB(83,26,133)
  t.UIStroke.Color=n==rarityIndex and Color3.new(1,1,1) or Color3.fromRGB(43,13,65)
  rarityBadges[n].Visible=page:GetAttribute("UnseenRarity_"..rarities[n])==true
 end
 local ids={}
 for id,item in pairs(Master.GetAll()) do if item.Rarity==rarities[rarityIndex] then table.insert(ids,id) end end
 table.sort(ids,function(a,b)
  local x,y=Master.Get(a),Master.Get(b)
  local order={}
  for i,kind in ipairs(Master.Kinds) do order[kind]=i end
  if x.ItemType~=y.ItemType then return (order[x.ItemType] or 99)<(order[y.ItemType] or 99) end
  return x.Element<y.Element
 end)
 for order,id in ipairs(ids) do
  local item=Master.Get(id)
  local c=Instance.new("TextButton") c.Name=id c.Text="" c.AutoButtonColor=false
  c.LayoutOrder=order c.ZIndex=32 c.Parent=list c:SetAttribute("InventoryItemCard",true)
  local stroke=style(c,Color3.fromRGB(103,32,160),12)
  stroke.Color=selectedId==id and Color3.new(1,1,1) or Color3.fromRGB(193,85,249) stroke.Thickness=3
  icon(c,"Icon",item.Image,UDim2.fromOffset(6,6),UDim2.new(1,-12,1,-66),33)
  local multiplier=label(c,"StrengthMultiplier",ItemMultiplierConfig.GetEffectText(item.ItemType,item.Rarity),UDim2.new(0,4,1,-59),UDim2.new(1,-8,0,20),34)
  multiplier.BackgroundTransparency=.12 multiplier.BackgroundColor3=Color3.fromRGB(72,24,111)
  local multiplierCorner=Instance.new("UICorner") multiplierCorner.CornerRadius=UDim.new(0,6) multiplierCorner.Parent=multiplier
  multiplier:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=17
  c.Activated:Connect(function()
   selectedId=id
   if (owned[id] or 0)>0 and equipped[item.ItemType]~=id and not pending then request(equipRemote,id) end
   render()
  end)
  if (owned[id] or 0)>0 then
   local isEquipped=equipped[item.ItemType]==id
   local b=Instance.new("TextButton")
   b.Name=isEquipped and "EquippedStatus" or "EquipButton"
   b.Text=isEquipped and "Equipped" or "Equip"
   b.Position=UDim2.new(0,3,1,-34) b.Size=UDim2.new(1,-6,0,31)
   b.Font=Enum.Font.GothamBlack b.TextColor3=Color3.new(1,1,1) b.TextScaled=true
   b.ZIndex=35 b.Parent=c
   style(b,isEquipped and Color3.fromRGB(45,125,112) or Color3.fromRGB(40,193,111),7)
   local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=8 limit.MaxTextSize=22 limit.Parent=b
   Presentation.SetButtonEnabled(b,not isEquipped) b.Interactable=not isEquipped
   if not isEquipped then
    if page:GetAttribute("UnseenItem_"..id)==true then
     local badge=Badges.GetOrClone(script.Parent.LeftMenu.InventoryButton.NotificationBadge,b,"ItemGuideBadge")
     badge.AnchorPoint=Vector2.new(1,0)
     badge.Position=UDim2.new(1,-2,0,2)
     badge.Size=UDim2.fromOffset(24,24)
     badge.BackgroundColor3=Color3.fromRGB(235,55,65)
     badge.BackgroundTransparency=0
     badge.ZIndex=b.ZIndex+2
     badge.Visible=true
     local corner=badge:FindFirstChildOfClass("UICorner")
     if corner then corner.CornerRadius=UDim.new(.5,0) end
     local text=badge:FindFirstChild("TextLabel")
     if text then text.Text="!";text.TextColor3=Color3.new(1,1,1);text.ZIndex=badge.ZIndex+1 end
     badge.Parent=b
    end
    b.Activated:Connect(function()
     if (owned[id] or 0)>0 and equipped[item.ItemType]~=id then request(equipRemote,id) end
    end)
   end
  elseif rarityIndex<=3 then
   local winText=tostring(item.WinPrice):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","").." Win"
   priceButton(c,"WinPurchase",winText,nil,UDim2.new(0,3,1,-34),UDim2.new(1,-6,0,31),Color3.fromRGB(235,184,36),winRemote,id)
  else
   priceButton(c,"RobuxPurchase",robuxPrices[item.Rarity] or item.RobuxPrice,"rbxasset://textures/ui/common/robux.png",UDim2.new(0,3,1,-34),UDim2.new(1,-6,0,31),Color3.fromRGB(30,160,226),robuxRemote,id)
  end
 end
end
for n=1,5 do
 local b=Instance.new("TextButton") b.Name="Star"..n b.Text="★"..n b.Font=Enum.Font.GothamBlack
 b.TextColor3=Color3.fromRGB(255,228,82) b.TextScaled=true b.Position=UDim2.new((n-1)/5,2,0,0)
 b.Size=UDim2.new(.2,-4,1,0) b.ZIndex=36 b.Parent=tabbar style(b,Color3.fromRGB(83,26,133),8)
 local stud=icon(b,"StudPattern","rbxassetid://111868739606818",UDim2.new(),UDim2.fromScale(1,1),36)
 stud.ScaleType=Enum.ScaleType.Tile stud.TileSize=UDim2.fromOffset(32,32) stud.ImageTransparency=.9
 local badge=Badges.GetOrClone(script.Parent.LeftMenu.InventoryButton.NotificationBadge,b,"RarityGuideBadge")
 badge.AnchorPoint=Vector2.new(1,0)
 badge.Position=UDim2.new(1,-2,0,2)
 badge.Size=UDim2.fromOffset(24,24)
 badge.BackgroundColor3=Color3.fromRGB(235,55,65)
 badge.BackgroundTransparency=0
 badge.ZIndex=b.ZIndex+2
 badge.Visible=false
 local corner=badge:FindFirstChildOfClass("UICorner")
 if corner then corner.CornerRadius=UDim.new(.5,0) end
 local text=badge:FindFirstChild("TextLabel")
 if text then text.Text="!";text.TextColor3=Color3.new(1,1,1);text.ZIndex=badge.ZIndex+1 end
 badge.Parent=b
 tabs[n]=b
 rarityBadges[n]=badge
 b.Activated:Connect(function()
  rarityIndex=n
  page:SetAttribute("UnseenRarity_"..rarities[n],nil)
  list.CanvasPosition=Vector2.zero
  render()
 end)
end
local function applyState(state)
 if typeof(state)~="table" or state.Loaded~=true or typeof(state.OwnedItems)~="table" then return false end
 owned=state.OwnedItems equipped=typeof(state.EquippedItems)=="table" and state.EquippedItems or {}
 render() return true
end
local function refresh()
 local ok,state=pcall(function() return stateRemote:InvokeServer() end)
 if not ok or not applyState(state) then page.Status.Text="Inventory is loading. Please reopen."
 else page.Status.Text="" end
end
-- Notification attributes survive card rebuilds and inventory close/reopen.
page.AttributeChanged:Connect(function(name)
 if string.sub(name,1,11)=="UnseenItem_" or string.sub(name,1,13)=="UnseenRarity_" then render() end
end)
RS.Remotes:WaitForChild("EnemyDropGachaResult").OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and result.OwnerUserId==player.UserId and result.Outcome=="ITEM" then refresh() end
end)
local function opened()
 if shell.Visible and page.Visible then
  rarityIndex=1
  page:SetAttribute("UnseenRarity_"..rarities[rarityIndex],nil)
  list.CanvasPosition=Vector2.zero
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
   bestButton.Text="BEST EQUIP"
   bestButton.Interactable=true
  end
  if typeof(result)~="table" or not applyState(result.State) then refresh() end
  page.Status.Text=typeof(result)=="table" and (result.Success and "" or (code=="Cancelled" and "" or tostring(code))) or "Please try again"
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
render()

task.spawn(function()
 for rarity,product in pairs(Products.ItemProducts) do
  robuxPrices[rarity]=MarketplacePrice.Get(product.ProductId,Enum.InfoType.Product,product.FallbackPrice)
 end
 if script.Parent then render() end
end)
