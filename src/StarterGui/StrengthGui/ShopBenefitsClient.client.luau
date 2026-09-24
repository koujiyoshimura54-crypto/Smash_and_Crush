local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(RS.Config.ShopProductConfig)
local Price=require(RS.Modules.MarketplacePrice)
local player=Players.LocalPlayer
local gui=script.Parent
local panel=gui:WaitForChild("ShopPanel")
local scroll=panel.MainScrollingFrame
local holder=scroll.Holder
local request=RS.Remotes:WaitForChild("ShopPurchaseRequest")
local remote=RS.Remotes:WaitForChild("ShopRewardState")
local state,active,detailsKey
local prices={}
local function label(parent,name,text,size)
 local t=Instance.new("TextLabel");t.Name=name;t.BackgroundTransparency=1;t.Text=text;t.TextColor3=Color3.new(1,1,1)
 t.Font=Enum.Font.GothamBold;t.TextSize=size;t.TextWrapped=true;t.ZIndex=52;t.Parent=parent;return t
end
local details=Instance.new("Frame");details.Name="ProductDetails";details.BackgroundColor3=Color3.fromRGB(33,38,62)
details.Position=UDim2.fromOffset(10,10);details.Size=UDim2.new(1,-20,1,-20);details.ZIndex=50;details.Visible=false;details.Parent=panel
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=details
local title=label(details,"Title","Product details",22);title.Position=UDim2.fromOffset(12,8);title.Size=UDim2.new(1,-78,0,44);title.TextXAlignment=Enum.TextXAlignment.Left
local close=Instance.new("TextButton");close.Name="Close";close.Text="×";close.Font=Enum.Font.GothamBold;close.TextSize=28;close.TextColor3=Color3.new(1,1,1)
close.BackgroundColor3=Color3.fromRGB(166,51,66);close.Size=UDim2.fromOffset(48,44);close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-8,0,8);close.ZIndex=53;close.Parent=details
local content=Instance.new("ScrollingFrame");content.Name="Content";content.BackgroundTransparency=1;content.BorderSizePixel=0
content.Position=UDim2.fromOffset(12,60);content.Size=UDim2.new(1,-24,1,-124);content.CanvasSize=UDim2.new();content.AutomaticCanvasSize=Enum.AutomaticSize.None;content.ScrollBarThickness=5;content.ZIndex=51;content.Parent=details
local description=label(content,"Description","",18);description.Size=UDim2.new(1,-12,0,0);description.AutomaticSize=Enum.AutomaticSize.None;description.TextYAlignment=Enum.TextYAlignment.Top;description.TextXAlignment=Enum.TextXAlignment.Left
local buy=Instance.new("TextButton");buy.Name="Purchase";buy.Text="";buy.Font=Enum.Font.GothamBold;buy.TextSize=18;buy.TextColor3=Color3.new(1,1,1)
buy.BackgroundColor3=Color3.fromRGB(50,164,83);buy.AnchorPoint=Vector2.new(.5,1);buy.Position=UDim2.new(.5,0,1,-8);buy.Size=UDim2.new(1,-24,0,48);buy.ZIndex=53;buy.Parent=details
local function focus(x)
 task.defer(function()
  local scale=panel.ResponsiveScale.Scale
  scroll.CanvasPosition=Vector2.new(0,math.max(0,scroll.CanvasPosition.Y+(x.AbsolutePosition.Y-scroll.AbsolutePosition.Y)))
 end)
end
local function owned(key)
 local x=state and state.Products and state.Products[key]
 return x and x.Owned==true
end
local function buttonText(key)
 local p=Config.Get(key)
 if active==key then return "PLEASE WAIT" end
 if owned(key) then
  local x=state.Products[key]
  return (p.Kind=="GamePass" and not x.Granted and state.GamePassEffectsEnabled~=false) and "OWNED • SYNCING" or "OWNED"
 end
 if key=="SecretPack" and state and not state.PaidRandomAllowed then return "UNAVAILABLE" end
 return prices[key] and (tostring(prices[key]).." Robux") or "..."
end
local function render()
 for _,key in ipairs(Config.Order) do
  local p=Config.Get(key);local card=holder[p.CardName];local button=card.PurchaseArea.Purchase
  card.LayoutOrder=p.Order
  local title=card:FindFirstChild("Title");if title then title.Text=p.Name end
  local icon=card:FindFirstChild("Icon") or card:FindFirstChild("Icon1");if icon then icon.Image=p.Icon end
  if p.Featured then
   card.Benefits.Text=key=="VIP" and ("+%g%% Strength"):format((p.StrengthMultiplier-1)*100) or Config.Description(key)
  else
   card.Benefits.Visible=false
   card.Text1.Text=tostring(p.WinAmount).." Win"
   local count=0 for _,n in pairs(p.Potions or {})do count+=n end
   card.Text2.Text=p.RandomItem and "Item + Aura" or "Potions ×"..count
   card.Icon1.Image=Config.Get("Win").Icon
   card.Icon2.Image=p.AuraId and Config.Auras[p.AuraId].Icon or gui.TimeRewardsPanel.Holder.Reward04.Decor.Icon.Image
  end
  button.PriceTag.Text=p.Kind=="Navigation" and p.ActionLabel or buttonText(key)
  button.CurrencyIcon.Visible=p.Kind~="Navigation" and not owned(key) and prices[key]~=nil
  button.Active=active==nil
  button.AutoButtonColor=button.Active
 end
 if detailsKey then
  buy.Text=buttonText(detailsKey)
  buy.Active=state~=nil and state.Loaded and active==nil and not owned(detailsKey)
   and (detailsKey~="SecretPack" or state.PaidRandomAllowed)
  buy.AutoButtonColor=buy.Active
 end
end
local function showDetails(key)
 detailsKey=key;details.Visible=true;content.CanvasPosition=Vector2.zero
 title.Text=Config.Get(key).Name
 local text=Config.Description(key)
 if key=="VIP" then text..="\n\nVIP Aura is cosmetic. The daily bonus resets at 00:00 UTC. Normal Daily Rewards remain available separately." end
 if key=="SecretPack" then
  text..="\n\nPossible items and odds (one item):"
  local outcomes=Config.GetSecretOutcomes()
  for _,outcome in ipairs(outcomes) do
   local name=outcome.ItemId:gsub("_"," ")
   text..=("\n%s: %.5f%%"):format(name,outcome.Percent)
  end
  text..="\n\nProbabilities are rounded; displayed percentages may not total exactly 100%."
 end
 description.Text=text;render()
end
for _,key in ipairs(Config.Order) do
 local p=Config.Get(key);local card=holder[p.CardName]
 Responsive.ConnectActivation(card.PurchaseArea.Purchase,function()
  if p.Kind=="Navigation" then details.Visible=false;focus(holder.WinPurchaseHeading)
  else showDetails(key)end
 end)
end
Responsive.ConnectActivation(close,function()details.Visible=false end)
Responsive.ConnectActivation(buy,function()
 if not buy.Active or not detailsKey then return end
 active=detailsKey;request:FireServer(detailsKey);render()
 local key=detailsKey
 task.delay(12,function()if active==key then active=nil;render()end end)
end)
-- Repeatable Win products share the receipt path and current platform price lookup.
for index,product in ipairs(Config.WinProducts) do
 local card=holder.CardWin:Clone();card.Name="WinProduct_"..product.Key
 card:SetAttribute("PurchaseKind","WinProduct");card:SetAttribute("PurchaseKey",product.Key);card:SetAttribute("ShopFeatured",false)
 card.LayoutOrder=8;card.Title.Text=product.Name or (product.Amount.." Win");card.Benefits.Text=tostring(product.Amount).." Win"
 card.PurchaseArea.Purchase.PriceTag.Text="...";card.Parent=holder
 local enabled=Config.ForWinProduct(product.ProductId)==product
 card.PurchaseArea.Purchase.Active=enabled
 if enabled then
  Responsive.ConnectActivation(card.PurchaseArea.Purchase,function()request:FireServer(product.Key)end)
  task.spawn(function()
   local price,source=Price.Get(product.ProductId,Enum.InfoType.Product,product.FallbackPrice)
   Price.Apply(card.PurchaseArea.Purchase.PriceTag,price,source," Robux")
  end)
 else card.PurchaseArea.Purchase.PriceTag.Text="COMING SOON" end
end
holder.WinPurchaseEmpty.Visible=#Config.WinProducts==0
local function apply(message)
 if typeof(message)~="table" then return end
 if message.State then state=message.State else state=message end
 render()
end
local function refresh()
 local ok,value=pcall(function()return remote:InvokeServer()end)
 if ok then apply(value)end
end
request.OnClientEvent:Connect(function(message)
 if typeof(message)~="table" then return end
 if message.Code then
  active=nil
  if message.Code~="Prompted" and message.Code~="AlreadyOwned" then buy.Text=message.Code end
 end
 apply(message)
end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p)
 if p==player then active=nil;refresh()end
end)
Marketplace.PromptProductPurchaseFinished:Connect(function()active=nil;refresh()end)
player:GetAttributeChangedSignal("HasPremiumSpeed"):Connect(refresh)
panel:GetPropertyChangedSignal("Visible"):Connect(function()
 if panel.Visible then refresh() else details.Visible=false end
end)
panel:GetAttributeChangedSignal("FocusProduct"):Connect(function()
 local key=panel:GetAttribute("FocusProduct")
 if Config.Get(key) then focus(holder[Config.Get(key).CardName]);showDetails(key)end
end)
for _,key in ipairs(Config.Order) do
 local p=Config.Get(key)
 if p.PassId then task.spawn(function()
  prices[key]=Price.Get(p.PassId,Enum.InfoType.GamePass,p.FallbackPrice);render()
 end)end
end
local elapsed=0
local textMeasureKey
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.2 then return end;elapsed=0
 local s=panel.ResponsiveScale.Scale
 local small=require(RS.Modules.ResponsivePanels).Small(gui)
 for _,key in ipairs(Config.Order) do
  local card=holder[Config.Get(key).CardName]
  card.Benefits.TextSize=17
  local button=card.PurchaseArea.Purchase
  button.PriceTag.TextScaled=true;button.PriceTag.TextWrapped=true
 end
 close.Size=UDim2.fromOffset(48,44);close.TextSize=28
 buy.Size=UDim2.new(1,-24,0,48);buy.TextSize=18
 description.TextSize=18
 content.Size=UDim2.new(1,-24,1,-124)
 if details.Visible then
  local width=math.max(1,content.AbsoluteSize.X/s-12)
  local key=description.Text..":"..math.floor(width)..":"..description.TextSize
  if key~=textMeasureKey then
   textMeasureKey=key
   local bounds=game:GetService("TextService"):GetTextSize(description.Text,description.TextSize,description.Font,Vector2.new(width,100000))
   description.Size=UDim2.new(1,-12,0,bounds.Y+12)
   content.CanvasSize=UDim2.fromOffset(0,bounds.Y+12)
  end
 end
end)
render();task.spawn(refresh)
