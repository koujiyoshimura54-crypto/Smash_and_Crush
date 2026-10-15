-- Presentation only. All purchase/equip/merge/Skip decisions remain in callers.
local M={}
local bindings=setmetatable({},{__mode="k"})
local function templates()
 local shop=game.StarterGui.StrengthGui.ShopPanel
 return shop,shop.Top,shop.MainScrollingFrame.Holder.Card01_SecretPack
end
local colors={
 purple=ColorSequence.new(Color3.fromRGB(190,0,255),Color3.fromRGB(85,0,245)),
 blue=ColorSequence.new(Color3.fromRGB(0,210,255),Color3.fromRGB(0,65,255)),
 card=ColorSequence.new(Color3.fromRGB(119,0,225),Color3.fromRGB(48,0,126)),
 blueCard=ColorSequence.new(Color3.fromRGB(0,137,245),Color3.fromRGB(0,46,133)),
 selected=ColorSequence.new(Color3.fromRGB(223,0,255),Color3.fromRGB(128,0,255)),
 equipped=ColorSequence.new(Color3.fromRGB(38,215,75),Color3.fromRGB(0,112,50)),
 action=ColorSequence.new(Color3.fromRGB(0,190,255),Color3.fromRGB(0,84,238)),
}
local purchase={BuyButton=true,WinButton=true,RobuxButton=true,WinPurchase=true,RobuxPurchase=true,Purchase=true,PurchasedButtonVisual=true}
local function protected(x)
 while x do
  if x:GetAttribute("InventoryReferenceOwned") then return true end
  if purchase[x.Name] or x.Name=="PurchasedShopHeader" or x.Name=="PurchasedShopClose"
   or x:GetAttribute("PurchasedShopDecoration") or x.Name:find("Badge") or x.Name:find("Notification") then return true end
  x=x.Parent
 end
 return false
end
local function copy(x,donor,keys) for _,k in keys do x[k]=donor[k] end end
local function decoration(donor,parent,name)
 local x=parent:FindFirstChild(name)
 if not x then
  x=donor:Clone();x.Name=name
  for _,c in x:GetDescendants() do if c:IsA("LuaSourceContainer") then c:Destroy() end end
  x.Parent=parent
 end
 x:SetAttribute("PurchasedShopDecoration",true)
 return x
end
local strokeKeys={"ApplyStrokeMode","Color","Thickness","Transparency","LineJoinMode","StrokeSizingMode","BorderStrokePosition","BorderOffset","ZIndex","Enabled"}
local function stroke(parent,donor,name)
 local x=decoration(donor,parent,name);copy(x,donor,strokeKeys);return x
end
local function isBody(x)
 return x:GetAttribute("PurchasedShopPanel") or x.Name=="Equipped" or x.Name=="Owned" or x.Name=="MergeFlow" or x:IsA("ScrollingFrame")
end
local function isSkip(x) return x:FindFirstAncestor("StageSkipGui")~=nil end
local function tile(x,pattern,donor)
 local scale=1
 while x and not x:IsA("ScreenGui") do
  local s=x:FindFirstChildOfClass("UIScale") if s then scale*=s.Scale end
  x=x.Parent
 end
 copy(pattern,donor,{"Image","ImageColor3","ImageTransparency","ScaleType"})
 -- Shop's ninety-pixel tiles stay ninety pixels after responsive scaling.
 pattern.TileSize=UDim2.fromOffset(donor.TileSize.X.Offset/math.max(scale,.01),donor.TileSize.Y.Offset/math.max(scale,.01))
end
function M.SetIdentity(label,image,name,asset) if label then label.Text=name end if image then image.Image=asset end end
-- Regular Item overlays only. Reuse existing stars or the purchased Shop title;
-- the authoritative rank comes from ItemMaster, never a second rarity table.
function M.SetItemStars(icon,item,existing)
 local master=require(game.ReplicatedStorage.Config.ItemMaster)
 local rank=item and master.RarityRank[item.Rarity]
 local stars=existing or icon:FindFirstChild("RarityStars")
 if not rank or not master.TypePrefixes[item.ItemType] then
  if stars then stars.Visible=false;stars.Text="" end
  return stars
 end
 local _,top=templates()
 local donor=top.ShopText1
 if not stars then
  stars=donor:Clone();stars.Name="RarityStars"
  for _,child in stars:GetDescendants() do if child:IsA("LuaSourceContainer") then child:Destroy() end end
  stars.AnchorPoint=Vector2.zero;stars.Position=UDim2.fromScale(.02,.02)
  -- Leave the upper-right purchased selection check and bottom stack count clear.
  stars.Size=UDim2.fromScale(.67,.22);stars.Parent=icon
 end
 stars:SetAttribute("PurchasedShopDecoration",true)
 stars.FontFace=donor.FontFace;stars.BackgroundTransparency=1
 stars.TextColor3=Color3.fromRGB(255,220,65);stars.TextTransparency=0
 stars.TextStrokeColor3=Color3.new(0,0,0);stars.TextStrokeTransparency=donor.TextStrokeTransparency
 stars.TextScaled=true;stars.TextWrapped=false;stars.AutoLocalize=false
 stars.TextXAlignment=Enum.TextXAlignment.Center;stars.Active=false;stars.Visible=true
 stars.Text=string.rep("★",rank);stars.ZIndex=icon.ZIndex+2
 local ink=stars:FindFirstChildOfClass("UIStroke")
 if not ink then local source=donor:FindFirstChildOfClass("UIStroke");if source then ink=source:Clone();ink.Parent=stars end end
 if ink then ink.Enabled=true;ink.Color=Color3.new(0,0,0);ink.Thickness=1;ink.Transparency=0;ink.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;ink.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize end
 local limit=stars:FindFirstChildOfClass("UITextSizeConstraint")
 if limit then limit.MinTextSize=6;limit.MaxTextSize=24 end
 return stars
end
function M.SetButtonEnabled(button,enabled) button.Active=enabled==true;button.AutoButtonColor=button.Active end
function M.ApplyPurchasedText(x)
 if protected(x) or not (x:IsA("TextLabel") or x:IsA("TextButton") or x:IsA("TextBox")) then return end
 local _,top,card=templates()
 local description=x.Name:find("Description") or x.Name:find("Instruction") or x.Name=="Status" or x.Name=="Benefits"
 local donor=description and card.Benefits or (x.Name=="EquippedStatus" or x.Name=="EquipButton") and card.Owned.PriceTag or card:FindFirstChild("Title")
 if x.Parent and x.Parent.Name=="Tabs" then donor=top.ShopText1 end
 copy(x,donor,{"FontFace","TextColor3","TextStrokeColor3","TextStrokeTransparency"})
 local ink=donor:FindFirstChildWhichIsA("UIStroke")
 if ink then
  local existing=x:FindFirstChild("PurchasedTextUIStroke")
  if not existing and x.BackgroundTransparency>=.95 then
   for _,v in x:GetChildren() do if v:IsA("UIStroke") and v.ApplyStrokeMode==Enum.ApplyStrokeMode.Contextual then existing=v;break end end
  end
  for _,v in x:GetChildren() do
   if v:IsA("UIStroke") and v.ApplyStrokeMode==Enum.ApplyStrokeMode.Contextual and v~=existing then v:Destroy() end
  end
  if existing then copy(existing,ink,strokeKeys);ink=existing else ink=stroke(x,ink,"PurchasedTextUIStroke") end
  ink.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
  ink.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
  ink.Thickness=description and 1 or 2;ink.Enabled=true
 end
end
function M.ApplyPurchasedSurface(x)
 if protected(x) or not x:IsA("GuiObject") then return end
 local shop,top,card=templates()
 local root=x:GetAttribute("PurchasedShopPanel")
 local body=isBody(x)
 x.BorderSizePixel=0
 local outer=stroke(x,root and shop.UIStroke or card.OuterUIStroke,"UIStroke")
 outer.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;outer.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 outer.Thickness=root and 4 or 2;outer.Enabled=root or not body
 local inner=stroke(x,card.InnerUIStroke,"PurchasedInnerUIStroke")
 inner.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;inner.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 inner.Thickness=1;inner.Enabled=not body
 local corner=x:FindFirstChildOfClass("UICorner") if corner then corner.CornerRadius=top.Close.UICorner.CornerRadius end
 local gradient=x:FindFirstChildOfClass("UIGradient") or decoration(card.UIGradient,x,"UIGradient")
 copy(gradient,card.UIGradient,{"Rotation","Offset","Transparency","Scale","TileMode","Type"})
 local textSurface=(x:IsA("TextButton") or x:IsA("TextLabel")) and x.Text~=""
 gradient.Color=x:GetAttribute("PurchasedShopEquipped") and colors.equipped or x.Name=="EquippedStatus" and colors.equipped
  or x.Name=="EquipButton" and colors.action or x:GetAttribute("PurchasedShopSelected") and colors.selected or isSkip(x) and colors.blueCard or colors.card
 gradient.Enabled=not body and not textSurface
 local fill=body and shop.BackgroundColor3 or textSurface and gradient.Color.Keypoints[1].Value or Color3.new(1,1,1)
 x:SetAttribute("PurchasedShopSurfaceColor",fill)
 x.BackgroundColor3=fill;x.BackgroundTransparency=root and shop.BackgroundTransparency or body and 1 or 0
 local pattern=x:FindFirstChild("StudPattern")
 if not pattern and not body and not x:FindFirstChildWhichIsA("UIGridStyleLayout") then pattern=decoration(card.StudPattern,x,"StudPattern") end
 if pattern then
  tile(x,pattern,card.StudPattern);pattern:SetAttribute("PurchasedShopDecoration",true)
  pattern.AnchorPoint=Vector2.zero;pattern.Position=UDim2.fromScale(0,0);pattern.Size=UDim2.fromScale(1,1)
  pattern.BackgroundTransparency=1;pattern.ZIndex=x.ZIndex;pattern.Active=false;pattern.Visible=not body and not textSurface
 end
end
function M.SetSelected(x,value)
 x:SetAttribute("PurchasedShopSelected",value==true)
 local visual=x:FindFirstChild("InventoryTabVisual")
 if visual then
  visual.UIGradient.Color=value and ColorSequence.new(Color3.fromRGB(0,222,255),Color3.fromRGB(0,148,236))
   or ColorSequence.new(Color3.fromRGB(172,0,255),Color3.fromRGB(76,0,225))
  visual.UIGradient.Rotation=90
  visual.InnerUIStroke.Color=value and Color3.fromRGB(86,244,255) or Color3.fromRGB(200,83,255)
 else M.ApplyPurchasedSurface(x) end
end
function M.SetEquipped(x,value) x:SetAttribute("PurchasedShopEquipped",value==true);M.ApplyPurchasedSurface(x) end

-- Measured from the owner's 1672x941 reference: panel (271,76), 1130x812.
-- All painted parts below are clones of purchased Shop/Restock/Inventory parts.
local inventoryBold=Font.fromEnum(Enum.Font.GothamBlack) -- purchased HatchClient TEXT_FONT
local function referenceLayer(x,z,panel)
 x.ZIndex=z+(panel.ZIndex>=200 and 200 or 0)
 x:SetAttribute("ResponsiveOriginalZ",z)
end
local function referenceRect(x,a,b,w,h)
 x.AnchorPoint=Vector2.zero;x.Position=UDim2.fromOffset(a,b);x.Size=UDim2.fromOffset(w,h)
end
local function referenceText(x,max)
 x.FontFace=inventoryBold;x.TextColor3=Color3.new(1,1,1)
 x.TextWrapped=true;x.TextScaled=true;x.TextTransparency=0;x.TextStrokeTransparency=1;x.AutoLocalize=false
 local limit=x:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
 limit.MinTextSize=6;limit.MaxTextSize=max;limit.Parent=x
 for _,s in x:GetChildren() do if s:IsA("UIStroke") then
  s.Enabled=true;s.Color=Color3.new(0,0,0);s.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
  s.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;s.Thickness=4;s.Transparency=0
 end end
end
local function referenceClean(x)
 for _,c in x:GetDescendants() do if c:IsA("LuaSourceContainer") then c:Destroy() end end
 for _,c in x:GetChildren() do
  if c:IsA("UIGridStyleLayout") or c:IsA("UIAspectRatioConstraint") or c:IsA("UISizeConstraint") or c:IsA("UIPadding") or c:IsA("UIScale") then c:Destroy() end
 end
end
local function setupInventoryReference(panel,header,titleIcon,close)
 local shop,top,card=templates()
 panel:SetAttribute("InventoryReferenceLayout",true)
 panel:SetAttribute("ResponsiveDesignSize",Vector2.new(1130,812))
 panel:SetAttribute("PurchasedShopSurfaceColor",shop.BackgroundColor3)
 panel.BackgroundTransparency=1
 for _,x in panel:GetChildren() do
  if x:IsA("UIStroke") or x:IsA("UIGradient") then x.Enabled=false end
 end
 local body=decoration(shop,panel,"PurchasedInventoryBody")
 body:SetAttribute("InventoryReferenceOwned",true);referenceClean(body)
 for _,x in body:GetChildren() do if x:IsA("GuiObject") then x:Destroy() end end
 body.Visible=true;body.BackgroundColor3=Color3.fromRGB(7,20,32);body.BackgroundTransparency=.12
 body.ClipsDescendants=false;referenceLayer(body,30,panel)
 local corner=body:FindFirstChildOfClass("UICorner") or panel.UICorner:Clone();corner.Parent=body;corner.CornerRadius=UDim.new(0,24)
 body.UIStroke.Enabled=true;body.UIStroke.Color=Color3.new(0,0,0);body.UIStroke.Thickness=4
 body.UIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
 header:SetAttribute("InventoryReferenceOwned",true);referenceClean(header)
 local hc=header:FindFirstChildOfClass("UICorner") or panel.UICorner:Clone();hc.Parent=header;hc.CornerRadius=UDim.new(0,24)
 header.UIGradient.Color=ColorSequence.new(Color3.fromRGB(194,0,255),Color3.fromRGB(81,0,239));header.UIGradient.Rotation=90
 header.InnerUIStroke.Color=Color3.fromRGB(193,61,255)
 header.OuterUIStroke.Thickness=4;header.OuterUIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
 for _,name in {"ShopText1","ShopText2"} do referenceText(header[name],112);header[name].Text="Inventory" end
 header.ShopText2.Visible=false -- one outlined title, no legacy offset title underneath
 header.ShopText1.TextXAlignment=Enum.TextXAlignment.Left
 if titleIcon then titleIcon:SetAttribute("InventoryReferenceOwned",true) end
 close:SetAttribute("InventoryReferenceOwned",true)
 local v=close.PurchasedShopClose
 v.UIGradient.Color=ColorSequence.new(Color3.fromRGB(255,67,188),Color3.fromRGB(234,0,130));v.UIGradient.Rotation=90
 v.TextLabel.Text="X";referenceText(v.TextLabel,76)
 v.TextLabel.AnchorPoint=Vector2.new(.5,.5);v.TextLabel.Position=UDim2.fromScale(.5,.5);v.TextLabel.Size=UDim2.fromScale(.88,.88)
 for _,name in {"Dumbbells","Items","Aura","Speed"} do
  local button=panel.Tabs[name];button:SetAttribute("InventoryReferenceOwned",true)
  button.BackgroundTransparency=1;button.Text="";button.Active=true;button.Interactable=true
  for _,x in button:GetChildren() do
   if x:IsA("GuiObject") and not x.Name:find("Badge") and not x.Name:find("Notification") then x.Visible=false
   elseif x:IsA("UIStroke") then x.Enabled=false end
  end
  local visual=decoration(card.Owned,button,"InventoryTabVisual");referenceClean(visual)
  visual:SetAttribute("InventoryReferenceOwned",true)
  visual.Text="";visual.Visible=true;visual.Active=false;visual.Interactable=false;visual.Selectable=false
  visual.AnchorPoint=Vector2.zero;visual.Position=UDim2.new();visual.Size=UDim2.fromScale(1,1)
  visual.UICorner.CornerRadius=UDim.new(0,18);visual.StudPattern.Visible=false
  visual.OuterUIStroke.Color=Color3.new(0,0,0);visual.OuterUIStroke.Thickness=4;visual.OuterUIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
  visual.InnerUIStroke.Thickness=2;visual.InnerUIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
  visual.UIStrokeInner.Enabled=false
  visual.PriceTag.Text=name;referenceText(visual.PriceTag,42)
  visual.PriceTag.AnchorPoint=Vector2.new(.5,.5);visual.PriceTag.Position=UDim2.fromScale(.5,.5);visual.PriceTag.Size=UDim2.fromScale(.95,.78)
  M.SetSelected(button,panel:GetAttribute("SelectedTab")==name)
 end
end
local function layoutInventoryReference(panel,header,titleIcon,close)
 local w,h=panel.Size.X.Offset,panel.Size.Y.Offset
 local items=panel.Content.Items
 local itemView=items.Visible and items:GetAttribute("ItemReferenceLayout")==true
 local narrow=w<900;local hh=narrow and 104 or (itemView and 140 or 132);local th=narrow and 64 or 74
 local inset=itemView and 20 or 30
 referenceRect(panel.PurchasedInventoryBody,0,hh,w,h-hh)
 referenceRect(header,0,0,w,hh);referenceLayer(header,70,panel)
 referenceLayer(header.StudPattern,70,panel);header.StudPattern.TileSize=UDim2.fromOffset(150,150)
 local is=narrow and 92 or 146
 if titleIcon then referenceRect(titleIcon,26,4,is,hh-8);referenceLayer(titleIcon,74,panel) end
 referenceRect(header.ShopText1,narrow and 128 or 196,8,w-(narrow and 240 or 320),hh-16);referenceLayer(header.ShopText1,75,panel)
 local cs=narrow and 76 or 94
 -- Transparent live input stays above the noninteractive purchased GuiButton artwork.
 referenceRect(close,w-cs-14,(hh-cs)/2,cs,cs);referenceLayer(close,84,panel)
 for _,x in close.PurchasedShopClose:GetDescendants() do if x:IsA("GuiObject") then referenceLayer(x,82,panel) end end
 referenceLayer(close.PurchasedShopClose,81,panel)
 referenceRect(panel.Tabs,inset,hh+16,w-inset*2,th)
 local gap=12;local tw=(w-inset*2-gap*3)/4
 for i,name in {"Dumbbells","Items","Aura","Speed"} do
  local b=panel.Tabs[name];referenceRect(b,(i-1)*(tw+gap),0,tw,th);referenceLayer(b,64,panel)
  local v=b.InventoryTabVisual;referenceLayer(v,61,panel);referenceLayer(v.PriceTag,63,panel)
  -- TextScaled constraints are screen-sized: share the longest tab's fit on all four.
  local scale=panel:FindFirstChildOfClass("UIScale")
  v.PriceTag:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=math.max(6,math.min(42,tw*(scale and scale.Scale or 1)/5.4))
 end
 local y=hh+16+th+(itemView and 20 or 26)
 referenceRect(panel.Content,inset,y,w-inset*2,h-y-16)
end

local speedViews=setmetatable({},{__mode="k"})
function M.BuildSpeedView(panel,config)
 if speedViews[panel] then return speedViews[panel] end
 M.BindPurchasedPanel(panel)
 local HUD=require(game.ReplicatedStorage.Modules.HUDLayout)
 local _,top,donor=templates()
 local page=panel.Content.Speed
 for _,x in page:GetChildren() do if x:IsA("GuiObject") then x.Visible=false end end
 local list=panel.Content.Aura.AuraList:Clone();list.Name="SpeedList";referenceClean(list)
 for _,x in list:GetChildren() do if x:IsA("GuiObject") then x:Destroy() end end
 list:SetAttribute("InventoryReferenceOwned",true);list.BackgroundTransparency=1;list.BorderSizePixel=0
 for _,x in list:GetChildren() do if x:IsA("UIStroke") or x:IsA("UIGradient") then x.Enabled=false end end
 list.Position=UDim2.new();list.Size=UDim2.fromScale(1,1);list.Visible=true;list.Active=true
 list.ScrollingEnabled=true;list.ScrollingDirection=Enum.ScrollingDirection.Y
 list.AutomaticCanvasSize=Enum.AutomaticSize.None;list.CanvasSize=UDim2.new();list.ScrollBarThickness=5
 list.Parent=page;referenceLayer(list,31,panel)
 local function label(parent,name,text,max)
  local x=top.ShopText1:Clone();x.Name=name;referenceClean(x);x.Text=text;x.Visible=true
  x.BackgroundTransparency=1;x.AnchorPoint=Vector2.zero;referenceText(x,max)
  x.TextXAlignment=Enum.TextXAlignment.Center;x.Parent=parent;referenceLayer(x,40,panel);return x
 end
 local rows={}
 for i,name in {"Current","Premium"} do
  local row=donor:Clone();row.Name=name;referenceClean(row)
  for _,x in row:GetChildren() do if x:IsA("GuiObject") and x.Name~="StudPattern" then x:Destroy() end end
  row:SetAttribute("InventoryReferenceOwned",true);row.Visible=true;row.BackgroundColor3=Color3.new(1,1,1);row.BackgroundTransparency=0
  row.AnchorPoint=Vector2.zero;row.Parent=list;referenceLayer(row,32,panel)
  local corner=panel.UICorner:Clone();corner.CornerRadius=UDim.new(0,28);corner.Parent=row
  row.UIGradient.Color=i==1 and ColorSequence.new(Color3.fromRGB(25,85,147),Color3.fromRGB(10,43,96))
   or ColorSequence.new(Color3.fromRGB(105,10,191),Color3.fromRGB(43,3,103));row.UIGradient.Rotation=90
  row.OuterUIStroke.Thickness=4;row.OuterUIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
  row.InnerUIStroke.Color=i==1 and Color3.fromRGB(38,126,216) or Color3.fromRGB(175,24,255)
  row.InnerUIStroke.Thickness=3;row.InnerUIStroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
  row.StudPattern.Image=top.StudPattern.Image;row.StudPattern.ScaleType=Enum.ScaleType.Tile
  row.StudPattern.TileSize=UDim2.fromOffset(180,180);row.StudPattern.ImageTransparency=.9
  row.StudPattern.Size=UDim2.fromScale(1,1);row.StudPattern.Position=UDim2.new();row.StudPattern.AnchorPoint=Vector2.zero
  referenceLayer(row.StudPattern,33,panel)
  local title=label(row,"Title",name=="Current" and "Current Speed" or "Premium Speed",58);title.TextXAlignment=Enum.TextXAlignment.Left
  local icon=panel.Tabs.Speed.Icon:Clone();icon.Name="Icon";icon.Visible=true;icon.Parent=row;referenceLayer(icon,35,panel)
  icon.ScaleType=Enum.ScaleType.Fit;icon.ImageTransparency=0
  local value=label(row,"SpeedValue","...",142)
  local unit=label(row,"Unit","Walk Speed",40)
  local button
  if i==1 then
   button=donor.Owned:Clone();button.Name="ActiveStatus";referenceClean(button)
   button.Text="";button.Visible=true;button.Active=false;button.Interactable=false;button.Selectable=false
   button.Parent=row;referenceLayer(button,42,panel);referenceLayer(button.PriceTag,45,panel)
   button.PriceTag.Text="ACTIVE";referenceText(button.PriceTag,52)
   button.PriceTag.AnchorPoint=Vector2.zero;button.PriceTag.Position=UDim2.fromScale(.28,.12);button.PriceTag.Size=UDim2.fromScale(.68,.76)
   button.StudPattern.Visible=false;button.UICorner.CornerRadius=UDim.new(0,22)
   local check=game.ReplicatedStorage.Assets.Templates.PetInventory.Main.Checkmark:Clone()
   check.Name="Checkmark";check.Visible=true;check.AnchorPoint=Vector2.new(.5,.5)
   check.Position=UDim2.fromScale(.16,.5);check.Size=UDim2.fromScale(.23,.72);check.Parent=button;referenceLayer(check,45,panel)
  else
   button=panel.Content.Aura.AuraList.RedAuraCard.BuyButton:Clone();button.Name="BuyButton";referenceClean(button)
   for _,x in button:GetChildren() do if x:IsA("GuiObject") then x:Destroy() end end
   button:SetAttribute("InventoryReferenceOwned",true);button.Parent=row;button.Text="";button.Visible=true
   referenceLayer(button,42,panel);HUD.PurchaseButton(button,"Robux","...")
   local visual=button:FindFirstChild("PurchasedButtonVisual")
   if visual then
    local layers={visual};for _,x in visual:GetDescendants() do if x:IsA("GuiObject") then table.insert(layers,x) end end
    for _,x in layers do x:SetAttribute("ResponsiveOriginalZ",x.ZIndex-(panel.ZIndex>=200 and 200 or 0)) end
   end
  end
  rows[name]={Root=row,Title=title,Icon=icon,Value=value,Unit=unit,Button=button}
 end
 local status=label(page,"SpeedStatus","",22);status:SetAttribute("InventoryReferenceOwned",true)
 status.TextXAlignment=Enum.TextXAlignment.Center
 local connections={}
 local function layout()
  local s=HUD.GetLocalSize(page);local gap=20;local footer=status.Text~="" and 32 or 0
  local h=math.max(240,(s.Y-footer-gap)/2)
  list.Size=UDim2.new(1,0,1,-footer);list.CanvasSize=UDim2.fromOffset(0,2*h+gap)
  for i,name in {"Current","Premium"} do
   local r=rows[name];local w=math.max(s.X-4,1)
   referenceRect(r.Root,2,(i-1)*(h+gap)+2,w-4,h-4)
   referenceRect(r.Title,24,6,w-48,64)
   referenceRect(r.Icon,w*.035,76,w*.33,h-84)
   referenceRect(r.Value,w*.395,h*.32,w*.235,h*.45)
   referenceRect(r.Unit,w*.385,h*.71,w*.255,h*.18)
   referenceRect(r.Button,w*.685,h*.40,w*.29,h*.38)
   if w<800 then
    -- Keep purchased Robux aspect/readability; move the action below the value on phones.
    referenceRect(r.Icon,w*.035,h*.24,w*.36,h*.54)
    referenceRect(r.Value,w*.47,h*.21,w*.46,h*.30)
    referenceRect(r.Unit,w*.42,h*.51,w*.53,h*.16)
    referenceRect(r.Button,w*.40,h-100,w*.56,88)
   end
  end
  referenceRect(status,0,s.Y-30,s.X,28)
 end
 table.insert(connections,page:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
 local view={BuyButton=rows.Premium.Button,Rows=rows,List=list}
 function view:SetState(state,pending,price,source,message)
  local active=state.ActiveSpeedItemId
  local item=active=="Premium" and config.Premium or config.Speed1
  -- Server GetState.WalkSpeed excludes transient movement multipliers.
  rows.Current.Value.Text=state.Loaded and typeof(state.WalkSpeed)=="number" and tostring(state.WalkSpeed) or "..."
  rows.Current.Icon.Image="rbxassetid://"..tostring(item.ImageAssetId)
  rows.Current.Button.Visible=state.Loaded==true
  rows.Premium.Value.Text=tostring(config.Premium.WalkSpeed)
  rows.Premium.Icon.Image="rbxassetid://"..tostring(config.Premium.ImageAssetId)
  local owned=state.PremiumOwned==true
  local shown=owned and (active=="Premium" and "ACTIVE" or "OWNED") or pending and "..." or (price~=nil and require(game.ReplicatedStorage.Modules.NumberFormat).Price(price) or "...")
  HUD.PurchaseButton(view.BuyButton,"Robux",shown)
  local enabled=state.Loaded==true and not owned and not pending and source=="Marketplace" and price~=nil
  view.BuyButton.Active=enabled;view.BuyButton.Interactable=enabled;view.BuyButton.AutoButtonColor=enabled
  view.BuyButton:SetAttribute("PriceSource",source)
  status.Text=message or "";status.Visible=status.Text~="";layout()
 end
 function view:Destroy()
  for _,c in connections do c:Disconnect() end
  list:Destroy();status:Destroy();speedViews[panel]=nil
 end
 table.insert(connections,panel.Destroying:Connect(function()for _,c in connections do c:Disconnect() end;speedViews[panel]=nil end))
 speedViews[panel]=view;layout();return view
end
function M.BindPurchasedPanel(panel)
 if bindings[panel] then return end
 assert(panel.Name=="InventoryPanel" or (panel.Name=="Panel" and panel.Parent.Name=="StageSkipGui"),"Purchased skin scope")
 local _,top=templates()
 local connections={};bindings[panel]=connections
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 panel:SetAttribute("PurchasedShopPanel",true);M.ApplyPurchasedSurface(panel)
 local title,close=panel.Title,panel.CloseButton
 local header=decoration(top,panel,"PurchasedShopHeader")
 for _,name in {"Close","MainShopIcon"} do local x=header:FindFirstChild(name) if x then x:Destroy() end end
 header.AnchorPoint=Vector2.zero;header.Position=UDim2.fromOffset(0,0);header.Size=UDim2.new(1,0,0,68);header.ZIndex=panel.ZIndex+1
 local palette=isSkip(panel) and colors.blue or colors.purple
 header.UIGradient.Color=palette;header.InnerUIStroke.Color=palette.Keypoints[1].Value
 tile(header,header.StudPattern,top.StudPattern)
 local divider=panel:FindFirstChild("Divider") if divider then divider.Visible=false end
 for _,x in header:GetDescendants() do if x:IsA("GuiObject") then x.ZIndex=header.ZIndex+x.ZIndex-top.ZIndex;x.Active=false end end
 local titleIcon=panel:FindFirstChild("InventoryTitleIcon") or panel:FindFirstChild("SkipTitleIcon")
 if not titleIcon and isSkip(panel) then
  titleIcon=decoration(game.StarterGui.StrengthGui.LeftMenu.SkipButton.Icon,panel,"SkipTitleIcon")
 end
 if titleIcon then
  titleIcon:SetAttribute("PurchasedShopDecoration",true)
  titleIcon.Visible=true;titleIcon.Active=false;titleIcon.AnchorPoint=Vector2.new(0,.5)
  titleIcon.Size=UDim2.fromOffset(40,40);titleIcon.ZIndex=header.ZIndex+4
 end
 local function heading()
  for _,name in {"ShopText1","ShopText2"} do
   local x=header[name];x.Text=title.Text;x.AutoLocalize=title.AutoLocalize;x.RootLocalizationTable=title.RootLocalizationTable
   x.AnchorPoint=Vector2.new(0,.5);x.Position=UDim2.new(0,titleIcon and 68 or 20,.5,name=="ShopText2" and 2 or 0)
   x.Size=UDim2.new(1,titleIcon and -140 or -92,.8,0);x.TextXAlignment=Enum.TextXAlignment.Left
  end
 end
 heading();connect(title:GetPropertyChangedSignal("Text"),heading)
 title:SetAttribute("PurchasedShopDecoration",true);close:SetAttribute("PurchasedShopDecoration",true)
 title.TextTransparency=1;title.TextStrokeTransparency=1
 for _,x in title:GetChildren() do if x:IsA("UIStroke") then x.Enabled=false end end
 local visual=decoration(top.Close,close,"PurchasedShopClose")
 visual.Text="";visual.AnchorPoint=Vector2.zero;visual.Position=UDim2.fromScale(0,0);visual.Size=UDim2.fromScale(1,1)
 visual.Active=false;visual.Interactable=false;visual.Selectable=false
 close.AnchorPoint=Vector2.zero;close.Position=UDim2.new(1,-57,0,10);close.Size=UDim2.fromOffset(48,48);close.ZIndex=panel.ZIndex+8
 close.BackgroundTransparency=1;close.TextTransparency=1;close.TextStrokeTransparency=1;visual.ZIndex=close.ZIndex
 for _,x in close:GetChildren() do if x:IsA("UIStroke") then x.Enabled=false end end
 for _,x in visual:GetDescendants() do if x:IsA("GuiObject") then x.ZIndex=close.ZIndex+x.ZIndex-top.Close.ZIndex;x.Active=false end end
 local installed=setmetatable({},{__mode="k"})
 local function apply(x)
  if not x:IsDescendantOf(panel) or protected(x) then return end
  M.ApplyPurchasedText(x)
  local surface=(x:IsA("Frame") or x:IsA("ScrollingFrame") or x:IsA("TextButton") or x:IsA("TextLabel"))
   and (x.BackgroundTransparency<.95 or isBody(x)) and x.Name~="Divider"
  if surface then
   M.ApplyPurchasedSurface(x)
   if not installed[x] then
    installed[x]=true
    connect(x:GetPropertyChangedSignal("BackgroundColor3"),function()
     if x.BackgroundColor3~=x:GetAttribute("PurchasedShopSurfaceColor") then M.ApplyPurchasedSurface(x) end
    end)
   end
  end
 end
 for _,x in panel:GetDescendants() do apply(x) end
 if panel.Name=="InventoryPanel" then setupInventoryReference(panel,header,titleIcon,close) end
 local function layout()
  local compact=panel.Size.Y.Scale==0 and panel.Size.Y.Offset<500
  if panel.Name=="InventoryPanel" then
   header.Size=UDim2.new(1,0,0,compact and 54 or 68)
   panel.Tabs.Position=UDim2.fromOffset(16,compact and 64 or 80);panel.Tabs.Size=UDim2.new(1,-32,0,compact and 42 or 46)
   panel.Content.Position=UDim2.fromOffset(16,compact and 118 or 138);panel.Content.Size=UDim2.new(1,-32,1,compact and -132 or -152)
   close.Size=UDim2.fromOffset(compact and 40 or 48,compact and 40 or 48);close.Position=UDim2.new(1,compact and -49 or -57,0,compact and 7 or 10)
   local d=panel.Content.Dumbbells.Equipped
   d.Size=UDim2.new(.29,-10,1,0)
   d.Preview.Position=UDim2.new(0,16,0,48);d.Preview.Size=UDim2.new(1,-32,0,compact and 84 or 150)
   d.ItemName.Position=UDim2.new(0,8,0,compact and 140 or 210);d.ItemName.Size=UDim2.new(1,-16,0,40)
   d.Multiplier.Position=UDim2.new(0,8,0,compact and 184 or 256);d.Multiplier.Size=UDim2.new(1,-16,0,30)
   for _,tab in panel.Tabs:GetChildren() do
    if tab:IsA("TextButton") then tab.TextScaled=true local limit=tab:FindFirstChildOfClass("UITextSizeConstraint") if limit then limit.MaxTextSize=23 end end
   end
   if not panel.Content.Items:GetAttribute("ItemReferenceLayout") then
   local equipment=panel.Content.Items.Equipped
   equipment.Title.Position=UDim2.fromOffset(8,compact and 4 or 12)
   equipment.Title.Size=UDim2.new(1,-16,0,compact and 22 or 28)
   local best=equipment:FindFirstChild("BestEquipButton")
   if best then best.Position=UDim2.fromOffset(8,compact and 32 or 46);best.Size=UDim2.new(1,-16,0,compact and 24 or 32) end
   for i,name in {"ProteinSocket","GloveSocket","TrainingBeltSocket"} do
    local socket=panel.Content.Items.Equipped:FindFirstChild(name)
    if socket then
     socket.Position=compact and UDim2.new(0,8,(i-1)/3,62-(i-1)*70/3) or UDim2.fromOffset(8,92+(i-1)*108)
     socket.Size=compact and UDim2.new(1,-16,1/3,-70/3-8) or UDim2.new(1,-16,0,98)
    end
   end
   end
  else
   panel.Stages.Position=UDim2.fromOffset(16,82);panel.Stages.Size=UDim2.new(1,-32,1,-126)
   panel.Stages.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.Stages.CanvasSize=UDim2.new()
   local list=panel.Stages:FindFirstChildOfClass("UIListLayout") if list then list.Padding=UDim.new(0,12) end
   for _,row in panel.Stages:GetChildren() do
    if row:IsA("Frame") and row:FindFirstChild("StageLabel") then
     row.Size=UDim2.new(1,-10,0,76)
     local label=row.StageLabel;label.Position=UDim2.new(0,14,0,16);label.Size=UDim2.new(.33,-22,0,44)
     label.TextScaled=true;label.TextXAlignment=Enum.TextXAlignment.Left
     local limit=label:FindFirstChildOfClass("UITextSizeConstraint") if limit then limit.MinTextSize=10;limit.MaxTextSize=26 end
     for i,name in {"WinButton","RobuxButton"} do
      local button=row[name];button.AnchorPoint=Vector2.new(0,.5)
      button.Position=UDim2.new(.33+(i-1)*.335,0,.5,0);button.Size=UDim2.new(.335,-12,0,46)
     end
    end
   end
  end
  if titleIcon then titleIcon.Position=UDim2.fromOffset(16,header.Size.Y.Offset/2);titleIcon.Visible=true end
  tile(header,header.StudPattern,top.StudPattern)
  for _,x in panel:GetDescendants() do
   if x.Name=="StudPattern" and x:IsA("ImageLabel") and x.Visible and not x.Parent:GetAttribute("InventoryReferenceOwned") and not x:FindFirstAncestor("PurchasedButtonVisual") and not x:FindFirstAncestor("PurchasedShopClose") then tile(x.Parent,x,top.StudPattern) end
  end
  if panel.Name=="InventoryPanel" then layoutInventoryReference(panel,header,titleIcon,close) end
 end
 layout();connect(panel:GetPropertyChangedSignal("Size"),layout)
 local scale=panel:FindFirstChildOfClass("UIScale") if scale then connect(scale:GetPropertyChangedSignal("Scale"),layout) end
 connect(panel.DescendantAdded,function(x) task.defer(function()
  apply(x)
  if x.Name=="ProteinSocket" or x.Name=="GloveSocket" or x.Name=="TrainingBeltSocket" then layout() end
 end) end)
 connect(panel.Destroying,function() for _,c in connections do c:Disconnect() end bindings[panel]=nil end)
end
return table.freeze(M)
