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
function M.SetSelected(x,value) x:SetAttribute("PurchasedShopSelected",value==true);M.ApplyPurchasedSurface(x) end
function M.SetEquipped(x,value) x:SetAttribute("PurchasedShopEquipped",value==true);M.ApplyPurchasedSurface(x) end
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
 for _,name in {"InventoryTitleIcon","Divider"} do local x=panel:FindFirstChild(name) if x then x.Visible=false end end
 for _,x in header:GetDescendants() do if x:IsA("GuiObject") then x.ZIndex=header.ZIndex+x.ZIndex-top.ZIndex;x.Active=false end end
 local function heading()
  for _,name in {"ShopText1","ShopText2"} do
   local x=header[name];x.Text=title.Text;x.AutoLocalize=title.AutoLocalize;x.RootLocalizationTable=title.RootLocalizationTable
   x.AnchorPoint=Vector2.new(0,.5);x.Position=UDim2.new(0,20,.5,name=="ShopText2" and 2 or 0)
   x.Size=UDim2.new(1,-92,.8,0);x.TextXAlignment=Enum.TextXAlignment.Left
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
  tile(header,header.StudPattern,top.StudPattern)
  for _,x in panel:GetDescendants() do
   if x.Name=="StudPattern" and x:IsA("ImageLabel") and x.Visible and not x:FindFirstAncestor("PurchasedButtonVisual") and not x:FindFirstAncestor("PurchasedShopClose") then tile(x.Parent,x,top.StudPattern) end
  end
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
