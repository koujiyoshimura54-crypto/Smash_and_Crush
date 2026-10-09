-- Rendering only: callers own purchase, ownership and equip decisions.
local M={}
function M.SetIdentity(nameLabel,imageLabel,name,image)
 if nameLabel then nameLabel.Text=name end
 if imageLabel then imageLabel.Image=image end
end
function M.SetButtonEnabled(button,enabled)
 button.Active=enabled==true
 button.AutoButtonColor=button.Active
end
-- Visuals only. Templates come from the purchased Shop already used in-game.
-- Existing controls, data labels, localization and input connections stay in place.
local palette={
 body=ColorSequence.new(Color3.fromRGB(229,163,255),Color3.fromRGB(255,190,221)),
 card=ColorSequence.new(Color3.fromRGB(246,190,255),Color3.fromRGB(255,151,207)),
 selected=ColorSequence.new(Color3.fromRGB(255,234,134),Color3.fromRGB(255,159,215)),
 header=ColorSequence.new(Color3.fromRGB(239,153,255),Color3.fromRGB(255,139,193)),
 equipped=ColorSequence.new(Color3.fromRGB(143,245,195),Color3.fromRGB(56,189,138)),
 action=ColorSequence.new(Color3.fromRGB(144,224,255),Color3.fromRGB(96,165,242)),
}
local bindings=setmetatable({},{__mode="k"})
local purchaseNames={BuyButton=true,WinButton=true,RobuxButton=true,WinPurchase=true,RobuxPurchase=true,Purchase=true,PurchasedButtonVisual=true}
local function protected(object)
 local current=object
 while current do
  if purchaseNames[current.Name] or current.Name=="PurchasedShopHeader" or current.Name=="PurchasedShopClose" or current:GetAttribute("PurchasedShopDecoration")
   or current.Name:find("Badge") or current.Name:find("Notification") then return true end
  current=current.Parent
 end
 return false
end
local function templates()
 local shop=game:GetService("StarterGui").StrengthGui.ShopPanel
 return shop,shop.Top,shop.MainScrollingFrame.Holder.Card02_StarterPack
end
local function copyProperties(target,source,properties)
 for _,key in ipairs(properties) do target[key]=source[key] end
end
local function decoration(source,parent,name)
 local old=parent:FindFirstChild(name)
 if old then old:SetAttribute("PurchasedShopDecoration",true);return old end
 local object=source:Clone()
 object.Name=name
 object:SetAttribute("PurchasedShopDecoration",true)
 for _,child in ipairs(object:GetDescendants()) do
  if child:IsA("LuaSourceContainer") then child:Destroy() end
 end
 object.Parent=parent
 return object
end
local strokeProperties={"ApplyStrokeMode","Color","Thickness","Transparency","LineJoinMode","StrokeSizingMode","BorderStrokePosition","BorderOffset","ZIndex","Enabled"}
local function stroke(parent,source,name)
 local object=parent:FindFirstChild(name)
 if not object then object=decoration(source,parent,name) end
 copyProperties(object,source,strokeProperties)
 return object
end
function M.ApplyPurchasedText(object)
 if protected(object) then return end
 if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
  local _,top=templates()
  object.FontFace=top.ShopText1.FontFace
  object.TextStrokeColor3=Color3.new(0,0,0)
  object.TextStrokeTransparency=0
 end
end
function M.SetSelected(object,selected)
 object:SetAttribute("PurchasedShopSelected",selected==true)
 M.ApplyPurchasedSurface(object)
end
function M.SetEquipped(object,equipped)
 object:SetAttribute("PurchasedShopEquipped",equipped==true)
 M.ApplyPurchasedSurface(object)
end
function M.ApplyPurchasedSurface(object)
 if protected(object) or not object:IsA("GuiObject") then return end
 local _,top,card=templates()
 local source=object:GetAttribute("PurchasedShopPanel") and top or card
 object.BackgroundColor3=Color3.new(1,1,1)
 object.BorderSizePixel=0
 stroke(object,source.OuterUIStroke,"UIStroke")
 stroke(object,source.InnerUIStroke,"PurchasedInnerUIStroke")
 local gradient=object:FindFirstChildOfClass("UIGradient")
 if not gradient then gradient=decoration(source.UIGradient,object,"UIGradient") end
 copyProperties(gradient,source.UIGradient,{"Rotation","Offset","Transparency","Scale","TileMode","Type","Enabled"})
 gradient.Color=object:GetAttribute("PurchasedShopEquipped") and palette.equipped
  or object.Name=="EquippedStatus" and palette.equipped
  or object.Name=="EquipButton" and palette.action
  or object:GetAttribute("PurchasedShopSelected") and palette.selected
  or object:GetAttribute("PurchasedShopPanel") and palette.body or palette.card
 -- A GuiObject background would become an extra card in a list/grid layout.
 -- Keep the purchased gradient/borders here; individual cards retain the studs.
 if object:FindFirstChildWhichIsA("UIGridStyleLayout") then return end
 local pattern=object:FindFirstChild("StudPattern")
 if not pattern then pattern=decoration(source.StudPattern,object,"StudPattern") end
 copyProperties(pattern,source.StudPattern,{"Image","ImageColor3","ImageTransparency","ScaleType","TileSize"})
 pattern:SetAttribute("PurchasedShopDecoration",true)
 pattern.AnchorPoint=Vector2.zero
 pattern.Position=UDim2.fromScale(0,0)
 pattern.Size=UDim2.fromScale(1,1)
 pattern.BackgroundTransparency=1
 pattern.ZIndex=object.ZIndex
 pattern.Active=false
end
function M.BindPurchasedPanel(panel)
 if bindings[panel] then return end
 assert(panel.Name=="InventoryPanel" or (panel.Name=="Panel" and panel.Parent.Name=="StageSkipGui"),"Purchased skin scope")
 local _,top=templates()
 local connections={}
 bindings[panel]=connections
 local function connect(signal,callback)
  table.insert(connections,signal:Connect(callback))
 end
 panel:SetAttribute("PurchasedShopPanel",true)
 M.ApplyPurchasedSurface(panel)

 local title=panel:WaitForChild("Title")
 local close=panel:WaitForChild("CloseButton")
 local header=decoration(top,panel,"PurchasedShopHeader")
 local duplicateClose=header:FindFirstChild("Close")
 if duplicateClose then duplicateClose:Destroy() end
 local shopIcon=header:FindFirstChild("MainShopIcon")
 if shopIcon then shopIcon:Destroy() end
 header.AnchorPoint=Vector2.zero
 header.Position=UDim2.fromOffset(0,0)
 header.Size=UDim2.new(1,0,0,58)
 header.ZIndex=panel.ZIndex+1
 header.UIGradient.Color=palette.header
 for _,object in ipairs(header:GetDescendants()) do
  if object:IsA("GuiObject") then object.ZIndex=header.ZIndex+object.ZIndex-top.ZIndex;object.Active=false end
 end
 local function heading()
  for _,name in ipairs({"ShopText1","ShopText2"}) do
   local text=header[name]
   text.Text=title.Text
   text.AutoLocalize=title.AutoLocalize
   text.RootLocalizationTable=title.RootLocalizationTable
   text.AnchorPoint=Vector2.new(0,.5)
   text.Position=UDim2.new(0,20,.5,name=="ShopText2" and 2 or 0)
   text.Size=UDim2.new(1,-92,.8,0)
   text.TextXAlignment=Enum.TextXAlignment.Left
  end
 end
 heading();connect(title:GetPropertyChangedSignal("Text"),heading)
 -- Keep original title and close paths for translations and existing callbacks.
 title:SetAttribute("PurchasedShopDecoration",true)
 close:SetAttribute("PurchasedShopDecoration",true)
 title.TextTransparency=1;title.TextStrokeTransparency=1
 for _,v in ipairs(title:GetChildren()) do if v:IsA("UIStroke") then v.Transparency=1 end end
 local closeVisual=decoration(top.Close,close,"PurchasedShopClose")
 closeVisual.Text=""
 closeVisual.AnchorPoint=Vector2.zero
 closeVisual.Position=UDim2.fromScale(0,0)
 closeVisual.Size=UDim2.fromScale(1,1)
 closeVisual.Active=false;closeVisual.Interactable=false;closeVisual.Selectable=false
 close.Position=UDim2.new(1,-53,0,7)
 close.AnchorPoint=Vector2.zero;close.Size=UDim2.fromOffset(44,44)
 close.ZIndex=panel.ZIndex+8
 close.BackgroundTransparency=1;close.TextTransparency=1;close.TextStrokeTransparency=1
 for _,v in ipairs(close:GetChildren()) do if v:IsA("UIStroke") then v.Transparency=1 end end
 closeVisual.ZIndex=close.ZIndex
 for _,v in ipairs(closeVisual:GetDescendants()) do
  if v:IsA("GuiObject") then v.ZIndex=close.ZIndex+v.ZIndex-top.Close.ZIndex;v.Active=false end
 end
 local installed=setmetatable({},{__mode="k"})
 local function apply(object)
  if not object:IsDescendantOf(panel) or protected(object) or object==title or object==close then return end
  M.ApplyPurchasedText(object)
  local surface=(object:IsA("Frame") or object:IsA("ScrollingFrame") or object:IsA("TextButton") or object:IsA("TextLabel"))
   and object.BackgroundTransparency<.95 and object.Name~="Divider"
  if surface then
   M.ApplyPurchasedSurface(object)
   if not installed[object] then
    installed[object]=true
    -- Existing state renderers may assign their old dark BackgroundColor3.
    connect(object:GetPropertyChangedSignal("BackgroundColor3"),function()
     if object.BackgroundColor3~=Color3.new(1,1,1) then M.ApplyPurchasedSurface(object) end
    end)
   end
  end
 end
 for _,object in ipairs(panel:GetDescendants()) do apply(object) end
 connect(panel.DescendantAdded,function(object)
  task.defer(function() apply(object) end)
 end)
 connect(panel.Destroying,function()
  for _,connection in ipairs(connections) do connection:Disconnect() end
  bindings[panel]=nil
 end)
end
return table.freeze(M)
