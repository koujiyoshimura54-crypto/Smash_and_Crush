-- Presentation only. Existing reward buttons keep their public paths/signals.
local RS=game:GetService("ReplicatedStorage")
local Style=require(RS.Config.RightHUDStyle)
local Assets=require(RS.Config.StrengthHUDStyle).Assets
local M={}
local function write(x,k,v)if x[k]~=v then x[k]=v end end
local function node(parent,class,name)
 local x=parent:FindFirstChild(name)
 if not x then x=Instance.new(class);x.Name=name;x.Parent=parent end
 return x
end
local function text(parent,name,value,z)
 local x=node(parent,"TextLabel",name)
 x.BackgroundTransparency=1;x.BorderSizePixel=0;x.Active=false;x.AutoLocalize=false
 x.Font=Style.Font;x.Text=value;x.TextWrapped=false;x.TextScaled=true
 x.TextColor3=Style.TextColor;x.TextStrokeTransparency=1;x.ZIndex=z
 local stroke=node(x,"UIStroke","Outline");stroke.Color=Style.OutlineColor;stroke.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;stroke.Thickness=Style.TextStroke
 return x
end
function M.EnsureBanners(gui,strengthGui)
 for index,name in {"DoubleWinButton","StrengthPassButton"} do
  local button=node(gui,"ImageButton",name)
  if button:GetAttribute("RightBannerVersion")==3 then continue end
  button:SetAttribute("RightBannerVersion",3)
  button.Image="";button.BackgroundTransparency=1;button.BorderSizePixel=0;button.AutoButtonColor=false
  button.ClipsDescendants=false;button.ZIndex=20
  local aspect=button:FindFirstChildOfClass("UIAspectRatioConstraint");if aspect then aspect:Destroy() end
  local old=button:FindFirstChild("OwnedBadge");if old then old.Visible=false end
  local art=node(button,"Frame","Banner");art.Size=UDim2.fromScale(1,1);art.BackgroundColor3=Color3.new(1,1,1)
  art.BorderSizePixel=0;art.ZIndex=20;art.Active=false
  local corner=node(art,"UICorner","Corner");corner.CornerRadius=UDim.new(0,13)
  local outline=node(art,"UIStroke","Outline");outline.Color=Style.OutlineColor;outline.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize;outline.Thickness=Style.Border
  local gradient=node(art,"UIGradient","Gradient");local stops={}
  local colors=index==1 and Style.Gold or Style.Rainbow
  for i,color in colors do table.insert(stops,ColorSequenceKeypoint.new((i-1)/(#colors-1),color)) end
  gradient.Color=ColorSequence.new(stops);gradient.Rotation=index==1 and 90 or 12
  local studs=node(art,"ImageLabel","Studs");studs.BackgroundTransparency=1;studs.Size=UDim2.fromScale(1,1)
  studs.Image=Assets.Studs;studs.ImageTransparency=.82;studs.ScaleType=Enum.ScaleType.Tile
  studs.TileSize=UDim2.fromOffset(96,96);studs.ZIndex=21;studs.Active=false
  local icon=node(art,"ImageLabel","Motif");icon.BackgroundTransparency=1;icon.AnchorPoint=Vector2.new(.5,.5)
  icon.Position=UDim2.fromScale(.5,.38);icon.Size=UDim2.fromScale(.48,1.38);icon.ScaleType=Enum.ScaleType.Fit
  icon.Image=index==1 and strengthGui.WinLabel.TrophyIcon.Image or Assets.Strength;icon.ZIndex=22;icon.Active=false
  local label=text(art,"Title",index==1 and "×2 Wins" or "×2 Strength",23)
  label.Position=UDim2.fromScale(.025,.28);label.Size=UDim2.fromScale(.95,.66)
  local row=node(button,"Frame","PriceRow");row.BackgroundTransparency=1;row.Active=false
  row.Position=UDim2.new(0,0,1,Style.PriceGap);row.Size=UDim2.new(1,0,0,Style.PriceHeight);row.ZIndex=24
  local only=text(row,"Only","Only",24);only.Position=UDim2.fromScale(.14,0);only.Size=UDim2.fromScale(.28,1)
  local previousCurrency=row:FindFirstChild("Currency")
  if previousCurrency and not previousCurrency:IsA("TextLabel") then previousCurrency:Destroy() end
  local currency=text(row,"Currency",utf8.char(0xE002),24);currency.Font=Enum.Font.GothamBold
  currency.Outline.Thickness=1.5
  currency.Position=UDim2.fromScale(.44,0);currency.Size=UDim2.fromOffset(Style.PriceHeight,Style.PriceHeight)
  currency.ZIndex=24;currency.Active=false;currency.Visible=false
  local price=text(row,"Amount","...",24);price.Position=UDim2.fromScale(.58,0);price.Size=UDim2.fromScale(.32,1)
  price.TextXAlignment=Enum.TextXAlignment.Left
  local status=text(row,"Status","",24);status.Size=UDim2.fromScale(1,1);status.Visible=false
 end
end
function M.SetState(button,price,source,owned,ready,busy)
 local row=button.PriceRow
 row.Only.Visible=not owned;row.Amount.Visible=not owned;row.Currency.Visible=not owned and price~=nil
 row.Amount.Text=price~=nil and require(RS.Modules.NumberFormat).Price(price) or "..."
 row.Amount:SetAttribute("PriceSource",source)
 row.Status.Visible=owned;row.Status.Text=owned and "Owned" or ""
 button.Active=ready and not owned and not busy
 button.Selectable=button.Active;button.AutoButtonColor=button.Active
end
function M.Layout(gui,oldRightScale)
 local w,h=gui.AbsoluteSize.X,gui.AbsoluteSize.Y
 if w<=0 or h<=0 then return end
 local menu=gui:FindFirstChild("LeftMenu");if not menu then return end
 local size=math.max(Style.RewardMinTouch,144*oldRightScale*Style.RewardSizeRatio)
 local scale=size/144
 local radius=Style.BadgeDesignSize*Style.BadgeImageScale*oldRightScale*Style.RewardBadgeSizeRatio/2
  *(math.cos(math.rad(Style.BadgeMaxRotation))+math.sin(math.rad(Style.BadgeMaxRotation)))
 for i,name in {"TimeRewardsButton","DailyRewardsButton"} do
  local button=menu:FindFirstChild(name)
  if button then
   local s=node(button,"UIScale","HUDScale");write(s,"Scale",scale)
   write(button,"Size",UDim2.fromOffset(144,144));write(button,"AnchorPoint",Vector2.zero)
   local x=w-Style.RewardRight-size-(2-i)*(size+Style.RewardGap)
   write(button,"Position",UDim2.fromOffset(x,0));write(button,"ClipsDescendants",false)
   local label=button:FindFirstChild("Label")
   if label then
    write(label,"Text",i==1 and "Playtime" or "Daily");write(label,"AutoLocalize",false)
    write(label,"TextTruncate",Enum.TextTruncate.None)
    local limit=label:FindFirstChildOfClass("UITextSizeConstraint")
    if limit then write(limit,"MinTextSize",1) end
   end
   local badge=button:FindFirstChild("NotificationBadge")
   if badge then
    -- Cancel the icon reduction, then halve this entire badge exactly once.
    -- BadgeRenderer keeps the existing image, color and rotation animation.
    local independent=node(badge,"UIScale","RewardBadgeScale")
    write(independent,"Scale",oldRightScale/scale*Style.RewardBadgeSizeRatio)
    write(badge,"AnchorPoint",Vector2.new(.5,.5))
    -- Overlap the icon's upper-right corner; leave room above for its rotation.
    write(badge,"Position",UDim2.new(1,0,0,math.ceil(radius/scale)))
    write(badge,"ZIndex",button.ZIndex+10)
   end
  end
 end
 local boost=gui.Parent:FindFirstChild("World1DoubleWinGui")
 if not boost then return end
 M.EnsureBanners(boost,gui)
 local scaleBanner=math.clamp(math.min(w/1738,h/905)^.65,Style.BannerMinScale,Style.BannerMaxScale)
 local right=math.max(10,w*Style.BannerRightRatio)
 local top=math.max(size+24,h*Style.BannerTopRatio)
 for i,name in {"DoubleWinButton","StrengthPassButton"} do
  local button=boost[name]
  local s=button:FindFirstChild("MenuLayoutScale") or node(button,"UIScale","HUDScale")
  write(s,"Scale",scaleBanner);write(button,"Size",UDim2.fromOffset(Style.BannerWidth,Style.BannerHeight))
  write(button,"AnchorPoint",Vector2.new(1,0))
  write(button,"Position",UDim2.fromOffset(w-right,top+(i-1)*(Style.BannerHeight+Style.BannerGap)*scaleBanner))
 end
end
return M
