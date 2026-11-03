-- Dumbbells-only measured presentation. Reference: 1586 x 992; no inventory/economy authority.
local RS=game.ReplicatedStorage
local HUD=require(script.Parent.HUDLayout)
local Style=require(RS.Config.StrengthHUDStyle)
local Format=require(script.Parent.NumberFormat)
local M={}
M.Geometry={Reference=Vector2.new(1586,992),Shell=Vector2.new(1426,864),Inset=16,Header=140,TabsY=148,TabsHeight=88,ContentY=270,
 LeftFraction=420/1394,Gap=16,CardGap=12,CardRatio=318/315,PopupWidth=538,PopupHeight=250}
local black=Color3.new()
local purple=ColorSequence.new(Color3.fromRGB(174,20,245),Color3.fromRGB(110,0,181))
local green=ColorSequence.new(Color3.fromRGB(138,255,58),Color3.fromRGB(38,229,0))
local gray=ColorSequence.new(Color3.fromRGB(166,166,166),Color3.fromRGB(98,98,98))
local function rect(o,x,y,w,h)o.AnchorPoint=Vector2.zero;o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h)end
local function layer(o,z)
 o:SetAttribute("ResponsiveOriginalZ",z)
 local p=o:FindFirstAncestor("InventoryPanel")
 o.ZIndex=z+(p and p.ZIndex>=200 and 200 or 0)
end
local function corner(o,r)
 local c=o:FindFirstChildOfClass("UICorner") or Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=o
end
local function ink(o,size,mode)
 local s=o:FindFirstChild("ReferenceOutline") or Instance.new("UIStroke")
 s.Name="ReferenceOutline";s.Color=black;s.Thickness=size;s.Transparency=0;s.Enabled=true
 s.ApplyStrokeMode=mode or Enum.ApplyStrokeMode.Border;s.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;s.Parent=o
 return s
end
local function text(o,size,stroke)
 o.Font=Style.Font;o.TextColor3=Color3.new(1,1,1);o.TextTransparency=0;o.TextStrokeTransparency=1
 o.TextWrapped=true;o.TextScaled=true;o.TextSize=size;o.BackgroundTransparency=1
 for _,c in o:GetChildren() do if c:IsA("UIStroke") then c:Destroy() end end
 ink(o,stroke or 4,Enum.ApplyStrokeMode.Contextual)
 local c=o:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
 c.MinTextSize=6;c.MaxTextSize=size;c.Parent=o
end
local function make(class,name,parent,z)
 local o=Instance.new(class);o.Name=name;o.BorderSizePixel=0
 o:SetAttribute("InventoryReferenceOwned",true);o.Parent=parent;layer(o,z)
 return o
end
local function label(name,parent,size,z)
 local o=make("TextLabel",name,parent,z);o.Active=false;o.Text="";text(o,size);return o
end
local function surface(o,r,studs)
 o:SetAttribute("InventoryReferenceOwned",true);o.BackgroundColor3=Color3.new(1,1,1);o.BackgroundTransparency=0
 for _,c in o:GetChildren() do if c:IsA("UIStroke") then c:Destroy() end end
 corner(o,r);ink(o,6)
 local g=o:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
 g.Color=purple;g.Rotation=90;g.Enabled=true;g.Parent=o
 local pattern=o:FindFirstChild("StudPattern")
 if studs then
  if not pattern then pattern=game.StarterGui.StrengthGui.ShopPanel.Top.StudPattern:Clone();pattern.Name="StudPattern";pattern.Parent=o end
  pattern:SetAttribute("InventoryReferenceOwned",true);pattern.BackgroundTransparency=1;pattern.Active=false
  pattern.Position=UDim2.new();pattern.AnchorPoint=Vector2.zero;pattern.Size=UDim2.fromScale(1,1)
  pattern.ScaleType=Enum.ScaleType.Tile;pattern.TileSize=UDim2.fromOffset(144,144);pattern.ImageTransparency=.66
  pattern.ImageColor3=Color3.new(1,1,1);pattern.Visible=true;corner(pattern,r);layer(pattern,o:GetAttribute("ResponsiveOriginalZ") or 32)
 elseif pattern then pattern.Visible=false end
 local rim=make("Frame","ReferenceRim",o,(o:GetAttribute("ResponsiveOriginalZ") or 32)+1)
 rim.BackgroundTransparency=1;rim.Size=UDim2.new(1,-10,1,-10);rim.Position=UDim2.fromOffset(5,5);corner(rim,math.max(2,r-5))
 local s=ink(rim,3);s.Color=Color3.fromRGB(219,122,255);rim.Active=false
end
function M.Skin(button,value,kind,enabled)
 button:SetAttribute("PurchaseFillBounds",true)
 HUD.PurchaseButton(button,"Win",value)
 local v=button.PurchasedButtonVisual;local main=v.Main
 local flow=main:FindFirstChildOfClass("UIListLayout");if flow then flow:Destroy() end
 local numeric=tostring(value):match("^%d")~=nil
 main.UIGradient.Color=kind=="Equip" and green or kind=="Equipped" and gray or main.UIGradient.Color
 if kind~="Equip" and kind~="Equipped" then
  main.UIGradient.Color=game.StarterGui.ScreenGui.Menus.RestockShop.Main.Common.Buy.Main.UIGradient.Color
 end
 for _,o in {v.Stroke,main} do
  o.BackgroundTransparency=0
  if o:FindFirstChildOfClass("UICorner") then o:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,16) end
 end
 v.Stroke.BackgroundColor3=black
 local outline=v.Stroke:FindFirstChildOfClass("UIStroke");if outline then outline.Color=black;outline.Thickness=4;outline.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize end
 local a=main.Amount;text(a,kind=="All" and 66 or kind=="Price" and 72 or 42,kind=="Price" and 5 or 3)
 a.AnchorPoint=Vector2.new(.5,.5);a.Position=UDim2.fromScale(numeric and .61 or .5,kind=="All" and .72 or .5)
 a.Size=UDim2.fromScale(numeric and .54 or .94,kind=="All" and .48 or .82)
 local icon=main.Icon;icon.Visible=numeric;icon.AnchorPoint=Vector2.new(.5,.5)
 icon.Position=UDim2.fromScale(.29,kind=="All" and .73 or .5);icon.Size=UDim2.fromScale(.25,kind=="All" and .44 or .66);icon.ScaleType=Enum.ScaleType.Fit
 local caption=main:FindFirstChild("SaleCaption")
 if kind=="All" and not caption then caption=label("SaleCaption",main,54,94);caption.Text="Sell All" end
 if caption then caption.Visible=kind=="All";caption.AnchorPoint=Vector2.new(.5,0);caption.Position=UDim2.fromScale(.5,.02);caption.Size=UDim2.fromScale(.95,.45) end
 if not enabled then main.UIGradient.Color=gray end
 button.Active=enabled==true;button.Interactable=button.Active;button.AutoButtonColor=false
 local base=button:GetAttribute("ResponsiveOriginalZ") or 39
 layer(v,base)
 for _,o in v:GetDescendants() do if o:IsA("GuiObject") then layer(o,base+(o.Name=="Stroke" and 0 or o.Name=="Main" and 1 or 2)) end end
 HUD.RefitPurchaseButton(button)
end
function M.StyleEquipped(page)
 page:SetAttribute("DumbbellReferenceLayout",true);page:SetAttribute("InventoryReferenceOwned",true)
 local eq=page.Equipped;layer(eq,32)
 for _,name in {"ItemName","Hint","Title","Preview","Multiplier"} do local o=eq:FindFirstChild(name);if o then o.Visible=false;o.Active=false end end
 local old=eq:FindFirstChild("ReferenceRim");if old then old:Destroy() end
 surface(eq,28,true)
 local badge=eq:FindFirstChild("EquippedBadge")
 if not badge then
  badge=make("Frame","EquippedBadge",eq,37);corner(badge,25);ink(badge,6)
  local grad=Instance.new("UIGradient");grad.Color=green;grad.Rotation=90;grad.Parent=badge
  badge.BackgroundColor3=Color3.new(1,1,1);badge.Active=false
  local t=label("Label",badge,52,38);t.Text="Equipped";t.AutoLocalize=false;t.Size=UDim2.fromScale(.95,.85);t.AnchorPoint=Vector2.new(.5,.5);t.Position=UDim2.fromScale(.5,.5)
 end
 local halo=eq:FindFirstChild("EquipmentGlow")
 if not halo then halo=game.StarterGui.StrengthGui.ShopPanel.MainScrollingFrame.Holder.Card01_SecretPack.Sunburst:Clone();halo.Name="EquipmentGlow";halo.Parent=eq end
 halo:SetAttribute("InventoryReferenceOwned",true);halo.BackgroundTransparency=1;halo.ImageColor3=Color3.fromRGB(240,174,255);halo.ImageTransparency=.18;halo.Visible=true;halo.Active=false;halo.ScaleType=Enum.ScaleType.Fit;layer(halo,34)
 eq.Preview.Visible=true;eq.Preview.ScaleType=Enum.ScaleType.Fit;layer(eq.Preview,36)
 eq.Multiplier.Visible=true;text(eq.Multiplier,82,6);layer(eq.Multiplier,38)
 page.Owned.Visible=false;page.WinLabel.Visible=false
end
function M.CreateCard(list,item,order)
 local card=make("TextButton",item.ItemId,list,32);card.Text="";card.AutoButtonColor=false;card.LayoutOrder=order;card.Visible=item.WorldId~=2
 card:SetAttribute("ItemId",item.ItemId);surface(card,25,true)
 local icon=make("ImageLabel","Icon",card,34);icon.BackgroundTransparency=1;icon.Image=item.Image;icon.ScaleType=Enum.ScaleType.Fit
 local effect=label("Multiplier",card,50,36);effect.Text="+"..Format.Format(item.StrengthBonus).." STR";effect.AutoLocalize=false
 local badge=make("Frame","CountBadge",card,37);badge.BackgroundColor3=Color3.fromRGB(125,0,170);corner(badge,24);ink(badge,4);badge.Active=false
 local count=label("OwnedCount",card,47,38);count.AutoLocalize=false
 local buy=make("TextButton","BuyButton",card,39);buy.Text="";buy:SetAttribute("PurchaseFillBounds",true)
 local price=label("Price",buy,42,39);price.Text=Format.Price(item.PriceWin)
 local wi=make("ImageLabel","WinIcon",buy,39);wi.BackgroundTransparency=1;wi.Image=game.StarterGui.StrengthGui.WinLabel.TrophyIcon.Image
 local sell=make("TextButton","SellButton",card,39);sell.Text="Sell";sell:SetAttribute("PurchaseFillBounds",true)
 return card
end
function M.LayoutShell(panel,header,titleIcon,close)
 local page=panel.Content.Dumbbells
 if not page.Visible or not page:GetAttribute("DumbbellReferenceLayout") then return false end
 local w,h=panel.Size.X.Offset,panel.Size.Y.Offset;local narrow=w<900
 local hh=narrow and 100 or 140;local ty=hh+8;local th=narrow and 64 or 88;local cy=ty+th+34
 local body=panel.PurchasedInventoryBody
 rect(body,0,hh,w,h-hh);body.BackgroundColor3=Color3.fromRGB(54,0,91);body.BackgroundTransparency=0
 body.UIStroke.Thickness=8;body.UICorner.CornerRadius=UDim.new(0,38)
 rect(header,0,0,w,hh);layer(header,70);header.OuterUIStroke.Thickness=8;header.UICorner.CornerRadius=UDim.new(0,38)
 header.ShopText1.Font=Style.Font
 rect(header.ShopText1,narrow and 110 or 176,0,w-(narrow and 210 or 310),hh)
 header.ShopText1:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=narrow and 76 or 110
 header.StudPattern.TileSize=UDim2.fromOffset(144,144)
 if titleIcon then rect(titleIcon,30,8,narrow and 90 or 140,hh-10) end
 local cs=narrow and 72 or 102;rect(close,w-cs-20,(hh-cs)/2,cs,cs)
 rect(panel.Tabs,16,ty,w-32,th)
 local gap=12;local first=(w-32-gap*3)*.28;local other=(w-32-gap*3-first)/3
 for i,name in {"Dumbbells","Items","Aura","Speed"} do
  local b=panel.Tabs[name];rect(b,i==1 and 0 or first+gap+(i-2)*(other+gap),0,i==1 and first or other,th)
 end
 rect(panel.Content,16,cy,w-32,h-cy-16)
 return true
end
function M.Mount(page,gui)
 M.StyleEquipped(page)
 local view={Selected=nil};local shell=page:FindFirstAncestor("InventoryPanel");local list=page.Items;local grid=list.UIGridLayout
 local popup=make("Frame","DumbbellSellPanel",page,90);popup.Active=true;popup.Visible=false;surface(popup,30,false)
 popup.UIGradient.Color=ColorSequence.new(Color3.fromRGB(108,0,170),Color3.fromRGB(81,0,131))
 local arrow=make("Frame","Pointer",popup,89);arrow.BackgroundColor3=Color3.fromRGB(113,0,176);arrow.Rotation=45;arrow.Size=UDim2.fromOffset(32,32);ink(arrow,6)
 local title=label("SellTitle",popup,64,92);title.Text="Sell"
 local close=game.StarterGui.StrengthGui.ShopPanel.Top.Close:Clone();close.Name="Close";close.Parent=popup
 close:SetAttribute("InventoryReferenceOwned",true);close.Text="";layer(close,96)
 for _,o in close:GetDescendants() do if o:IsA("GuiObject") then layer(o,97);o.Active=false end end
 local one=make("TextButton","SellOne",popup,93);one.Text="";one:SetAttribute("PurchaseFillBounds",true)
 local all=make("TextButton","SellAll",popup,93);all.Text="";all:SetAttribute("PurchaseFillBounds",true)
 local connections={}
 local function connect(signal,fn)connections[#connections+1]=signal:Connect(fn)end
 local function follow()
  local card=view.Card
  if not view.Selected or not card or not card.Parent or not card.Visible or not shell.Visible or not page.Visible then popup.Visible=false;return end
  local scale=HUD.GetScale(page);local size=HUD.GetLocalSize(page)
  local cp=(card.AbsolutePosition-page.AbsolutePosition)/scale
  local button=card.SellButton;local bp=(button.AbsolutePosition-page.AbsolutePosition)/scale
  local bs=HUD.GetLocalSize(button);local cs=HUD.GetLocalSize(card)
  local lp=(list.AbsolutePosition-page.AbsolutePosition)/scale;local ls=HUD.GetLocalSize(list)
  if bp.Y+bs.Y<lp.Y or bp.Y>lp.Y+ls.Y then popup.Visible=false;return end
  local w=math.min(M.Geometry.PopupWidth,size.X-12);local h=math.min(M.Geometry.PopupHeight,size.Y-12)
  local x=math.clamp(cp.X,6,math.max(6,size.X-w-6))
  local below=bp.Y+bs.Y+22
  local y=below+h<=size.Y-6 and below or bp.Y-h-22
  y=math.clamp(y,6,math.max(6,size.Y-h-6))
  rect(popup,x,y,w,h);popup.Visible=true
  local atTop=y>=bp.Y+bs.Y
  arrow.Position=UDim2.fromOffset(math.clamp(bp.X+bs.X/2-x-16,30,w-62),atTop and -16 or h-16)
  rect(title,18,8,w-36,72);rect(close,w-76,12,60,60)
  local bw=(w-44)/2;rect(one,16,94,bw,h-110);rect(all,28+bw,94,bw,h-110)
 end
 function view:Close()self.Selected=nil;self.Card=nil;popup.Visible=false end
 function view:Open(id,card)self.Selected=id;self.Card=card;follow()end
 function view:UpdateSale(item,available,pending)
  if not item then self:Close();return end
  M.Skin(one,Format.Price(item.SellWin or 0),"Price",available>0 and not pending and item.SellWin~=nil)
  M.Skin(all,Format.Price(available*(item.SellWin or 0)),"All",available>0 and not pending and item.SellWin~=nil)
  popup:SetAttribute("ItemId",item.ItemId);popup:SetAttribute("SellableCount",available);follow()
 end
 function view:Layout(cards)
  local size=HUD.GetLocalSize(page);if size.X<1 or size.Y<1 then return end
  local left=math.floor(size.X*M.Geometry.LeftFraction);local gap=16
  rect(page.Equipped,0,0,left,size.Y)
  local eq=page.Equipped;rect(eq.EquippedBadge,left*.19,20,left*.64,78)
  rect(eq.EquipmentGlow,10,size.Y*.17,left-20,size.Y*.64)
  rect(eq.Preview,left*.055,size.Y*.26,left*.89,size.Y*.47)
  rect(eq.Multiplier,12,size.Y*.77,left-24,size.Y*.17)
  rect(list,left+gap,0,size.X-left-gap,size.Y)
  local pad=list:FindFirstChildOfClass("UIPadding");if pad then pad.PaddingLeft=UDim.new(0,6);pad.PaddingRight=UDim.new(0,6);pad.PaddingTop=UDim.new(0,6);pad.PaddingBottom=UDim.new(0,6) end
  local width=size.X-left-gap-12;local cols=size.X<900 and 2 or 3;local cw=(width-(cols-1)*12)/cols;local ch=cw*M.Geometry.CardRatio
  grid.CellPadding=UDim2.fromOffset(12,16);grid.CellSize=UDim2.fromOffset(cw,ch);grid.FillDirectionMaxCells=cols
  list.Active=true;list.ScrollingEnabled=true;list.ScrollingDirection=Enum.ScrollingDirection.Y;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.ScrollBarThickness=5
  for _,c in pairs(cards) do
   rect(c.Icon,cw*.07,ch*.12,cw*.86,ch*.47)
   rect(c.OwnedCount,cw*.67,9,cw*.28,ch*.15)
   rect(c.CountBadge,cw*.67,9,cw*.28,ch*.15);c.CountBadge.Visible=c.OwnedCount.Text~=""
   rect(c.Multiplier,8,ch*.57,cw-16,ch*.16)
   local hasSale=c.SellButton.Visible;local bw=hasSale and (cw-38)*.54 or cw-28
   rect(c.BuyButton,14,ch*.76,bw,ch*.18)
   rect(c.SellButton,26+bw,ch*.76,cw-bw-40,ch*.18)
   HUD.RefitPurchaseButton(c.BuyButton);if c.SellButton.Visible then HUD.RefitPurchaseButton(c.SellButton) end
  end
  follow()
 end
 connect(list:GetPropertyChangedSignal("CanvasPosition"),follow)
 connect(page:GetPropertyChangedSignal("AbsolutePosition"),follow)
 connect(page:GetPropertyChangedSignal("Visible"),function()if not page.Visible then view:Close()end end)
 connect(shell:GetPropertyChangedSignal("Visible"),function()if not shell.Visible then view:Close()end end)
 connect(page.Destroying,function()for _,c in connections do c:Disconnect()end end)
 view.Popup=popup;view.One=one;view.All=all;view.CloseButton=close
 return view
end
return M
