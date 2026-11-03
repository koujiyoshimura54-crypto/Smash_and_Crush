-- Reproduce only the Shop artwork properties from BattleBagShopAssets_20261103.
-- Use the current canonical Edit DataModel; do not import an old GUI/model.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857,"Wrong place/universe")
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local holder=game.StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder
-- Product artwork only; keep shared Inventory/Pet/HUD styling untouched.
local function productIcon(x)
 return x:IsA("ImageLabel") and (x.Name=="Icon" or x.Name=="Icon1" or x.Name=="Icon2")
end
local function originalZ(x)
 return x:GetAttribute("ResponsiveOriginalZ") or x.ZIndex
end
local function layoutProductIcons(card)
 if not card:IsA("Frame") or not card:GetAttribute("PurchaseKind") then return end
 local z=originalZ(card)+1
 for _,x in card:GetChildren() do
  if x:IsA("GuiObject") and (x.Name=="StudPattern" or x.Name=="Sunburst") then z=math.max(z,originalZ(x)+1) end
 end
 local layerOffset=card.ZIndex-originalZ(card)
 local kind=card:GetAttribute("PurchaseKind")
 for _,icon in card:GetChildren() do
  if not productIcon(icon) then continue end
  icon.ScaleType=Enum.ScaleType.Fit
  icon:SetAttribute("ResponsiveOriginalZ",z)
  icon.ZIndex=z+layerOffset
  -- Retain each authored card design, reserving clear slots between its existing text/buttons.
  if kind=="Dumbbell" and icon.Name=="Icon" then
   icon.Position=UDim2.fromScale(.245,.36);icon.Size=UDim2.fromScale(.40,.64)
  elseif kind=="Item" and icon.Name=="Icon" then
   icon.Position=UDim2.new(icon.Position.X.Scale,icon.Position.X.Offset,.625,0)
   icon.Size=UDim2.new(icon.Size.X.Scale,icon.Size.X.Offset,.60,0)
  elseif kind=="ShopProduct" and (icon.Name=="Icon1" or icon.Name=="Icon2") then
   icon.Position=UDim2.new(icon.Position.X.Scale,icon.Position.X.Offset,.395,0)
   icon.Size=UDim2.new(icon.Size.X.Scale,icon.Size.X.Offset,.34,0)
  elseif (kind=="ShopProduct" or kind=="WinProduct" or kind=="DoubleWin") and icon.Name=="Icon" then
   icon.Position=UDim2.new(icon.Position.X.Scale,icon.Position.X.Offset,.34,0)
   icon.Size=UDim2.new(icon.Size.X.Scale,icon.Size.X.Offset,.34,0)
  end
 end
end

for _,card in holder:GetChildren() do layoutProductIcons(card) end
