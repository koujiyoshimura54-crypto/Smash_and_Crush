local RS=game:GetService("ReplicatedStorage")
local TextService=game:GetService("TextService")
local Style=require(RS.Config.StrengthHUDStyle)
local M={}
local bound=setmetatable({}, {__mode="k"})
local function node(parent,class,name)
 local x=parent:FindFirstChild(name)
 if not x then x=Instance.new(class);x.Name=name;x.Parent=parent end
 return x
end
local function rect(x,px,py,w,h)
 x.AnchorPoint=Vector2.zero;x.Position=UDim2.fromOffset(px,py);x.Size=UDim2.fromOffset(w,h)
end
local function stroke(x,width,mode)
 local chosen
 for _,c in x:GetChildren() do if c:IsA("UIStroke") then
  if not chosen then chosen=c else c.Enabled=false end
 end end
 chosen=chosen or node(x,"UIStroke","Outline")
 chosen.Enabled=true;chosen.Color=Style.Colors.Outline;chosen.Thickness=width
 chosen.ApplyStrokeMode=mode;chosen.Transparency=0
 if mode==Enum.ApplyStrokeMode.Border then chosen.BorderStrokePosition=Enum.BorderStrokePosition.Inner end
 -- Purchased materials use relative stroke sizing. Our measured widths are pixels.
 chosen.StrokeSizingMode=Enum.StrokeSizingMode.FixedSize
 for _,c in chosen:GetChildren() do if c:IsA("UIGradient") then c.Enabled=false end end
 return chosen
end
local function corner(x,radius)
 local c=x:FindFirstChildOfClass("UICorner") or node(x,"UICorner","Corner")
 c.CornerRadius=UDim.new(0,radius)
end
local function gradient(x,top,bottom)
 local g=x:FindFirstChildOfClass("UIGradient") or node(x,"UIGradient","Shading")
 g.Enabled=true;g.Color=ColorSequence.new(top,bottom);g.Rotation=90
end
function M.Text(x,role)
 local s=assert(Style.Text[role],role)
 x.Font=Style.Font;x.TextSize=s.Size;x.TextScaled=false;x.TextWrapped=false
 x.RichText=false;x.AutoLocalize=false;x.TextColor3=Style.Colors.Text
 x.TextTransparency=0;x.TextStrokeTransparency=1;x.BackgroundTransparency=1
 stroke(x,s.Stroke,Enum.ApplyStrokeMode.Contextual)
end
-- The existing abbreviated-number convention, with three significant figures.
-- Keeps 1440 -> 1.44K and long values bounded without shrinking the pack font.
function M.Number(value)
 local n=math.max(0,tonumber(value) or 0)
 local suffixes={"","K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
 local index=1
 while n>=1000 and index<#suffixes do n/=1000;index+=1 end
 if index==1 then return tostring(math.floor(n+.5)) end
 local places=n<10 and 2 or n<100 and 1 or 0
 local rounded=math.floor(n*10^places+.5)/10^places
 if rounded>=1000 and index<#suffixes then rounded=1;index+=1;places=2 end
 return string.format("%."..places.."f",rounded):gsub("(%..-)0+$","%1"):gsub("%.$","")..suffixes[index]
end
local function image(parent,name,asset,z)
 local x=node(parent,"ImageLabel",name)
 x.BackgroundTransparency=1;x.BorderSizePixel=0;x.Image=asset
 x.ImageTransparency=0;x.ScaleType=Enum.ScaleType.Fit;x.Active=false;x.ZIndex=z
 return x
end
local function gauge(bar,isHealth)
 local c=Style.Colors;local g=Style.Geometry;local b=Style.Border
 bar.BackgroundTransparency=0;bar.BackgroundColor3=Color3.new(1,1,1)
 bar.BorderSizePixel=0;bar.Active=false;bar.ClipsDescendants=false
 corner(bar,isHealth and b.HealthRadius or b.GaugeRadius)
 stroke(bar,b.Gauge,Enum.ApplyStrokeMode.Border)
 gradient(bar,isHealth and c.HealthEmpty or c.EmptyTop,isHealth and c.HealthEmpty or c.EmptyBottom)
 local old=bar:FindFirstChild("Stroke");if old then old.Visible=false end
 -- Clip the full-width rounded color field, preserving a square leading edge
 -- at 0 < progress < 1. Do not round a narrow half-progress rectangle.
 local clip=node(bar,"Frame","FillClip")
 clip.BackgroundTransparency=1;clip.ClipsDescendants=true;clip.Active=false;clip.ZIndex=bar.ZIndex+1
 clip.AnchorPoint=Vector2.zero;clip.Position=UDim2.fromOffset(b.Gauge,b.Gauge)
 local fill=bar:FindFirstChild("Main") or clip.Main
 if not fill:GetAttribute("ReferenceFill") then
  clip.Size=fill.Size;clip.Visible=fill.Visible
  fill:SetAttribute("ReferenceFill",true)
 end
 fill.Parent=clip;fill.AnchorPoint=Vector2.zero;fill.Position=UDim2.new();fill.Visible=true
 fill.BackgroundColor3=Color3.new(1,1,1);fill.BackgroundTransparency=0;fill.BorderSizePixel=0
 fill.ZIndex=clip.ZIndex;fill.Active=false
 corner(fill,(isHealth and b.HealthRadius or b.GaugeRadius)-b.Gauge)
 for _,v in fill:GetChildren() do if v:IsA("UIStroke") then v.Enabled=false end end
 gradient(fill,isHealth and c.HealthTop or c.LevelTop,isHealth and c.HealthBottom or c.LevelBottom)
 bar.Exp.ZIndex=bar.ZIndex+3;M.Text(bar.Exp,isHealth and "Health" or "Progress")
 bar.Level.Visible=not isHealth
 if not isHealth then M.Text(bar.Level,"Level");bar.Level.ZIndex=bar.ZIndex+3 end
 if isHealth then image(bar,"Heart",Style.Assets.Heart,bar.ZIndex+4).ImageColor3=Style.Assets.HeartTint end
 return clip
end
function M.SetFill(bar,progress)
 local clip=bar:FindFirstChild("FillClip")
 if clip then
  progress=math.clamp(progress,0,1)
  clip.Size=UDim2.new(progress,-2*Style.Border.Gauge*progress,1,-2*Style.Border.Gauge)
  clip.Visible=progress>0
 end
end
function M.BindPress(button,visual)
 if bound[button] then return end
 bound[button]=true
 local scale=node(visual,"UIScale","PressScale")
 local settings=require(RS.Modules.Config).Button
 local tween
 local function animate(value)
  if tween then tween:Cancel() end
  tween=game:GetService("TweenService"):Create(scale,TweenInfo.new(settings.seconds),{Scale=value});tween:Play()
 end
 button.MouseButton1Down:Connect(function()if button.Active then animate(settings.pressScale)end end)
 button.MouseButton1Up:Connect(function()animate(1)end)
 button.MouseLeave:Connect(function()animate(1)end)
 button.Activated:Connect(function()
  local ui=game:GetService("SoundService"):FindFirstChild("UI")
  local sound=ui and ui:FindFirstChild("Click")
  if sound and sound:IsA("Sound") then sound:Play() end
 end)
end
function M.Apply(gui)
 local hud=gui.StrengthLevelHUD;local g=Style.Geometry
 hud.Active=false;hud.ClipsDescendants=false
 local panel=hud.LevelPanel
 panel.BackgroundTransparency=1;panel.ClipsDescendants=false;panel.Active=false
 panel.Outline.Enabled=false
 panel.Level.Visible=false;panel.ProgressText.Visible=false;panel.ProgressBackground.Visible=false
 local level=panel.StrengthProgressBar
 level.AnchorPoint=Vector2.zero;level.Position=UDim2.new();level.Size=UDim2.fromScale(1,1)
 gauge(level,false)
 local health=hud.PlayerHealth
 gauge(health,true)
 local total=hud.StrengthValueContainer
 total.Active=false;total.ClipsDescendants=false
 local list=total:FindFirstChildOfClass("UIListLayout");if list then list:Destroy() end
 M.Text(total.Strength,"Strength");M.Text(total.StrengthUnit,"Strength")
 image(total,"StrengthIcon",Style.Assets.Strength,10)
 for index,product in ipairs(require(RS.Config.StrengthRewardConfig).Packs) do
  local card=hud.StrengthPacks[tostring(product.ProductId)]
  card.Active=false;card.BorderSizePixel=0;card.BackgroundColor3=Color3.new(1,1,1);card.BackgroundTransparency=0
  card.ClipsDescendants=true;card.ZIndex=10
  corner(card,Style.Border.PackRadius);stroke(card,Style.Border.Pack,Enum.ApplyStrokeMode.Border)
  gradient(card,Style.Colors.Packs[index][1],Style.Colors.Packs[index][2])
  local art=node(card,"Frame","Art")
  art.BackgroundTransparency=1;art.BorderSizePixel=0;art.Active=false;art.ClipsDescendants=true;art.ZIndex=11
  art.Position=UDim2.fromOffset(Style.Border.Pack,Style.Border.Pack)
  art.Size=UDim2.new(1,-2*Style.Border.Pack,1,-2*Style.Border.Pack)
  for _,name in {"StrengthIcon","StudPattern"} do local old=card:FindFirstChild(name);if old then old.Parent=art end end
  local stud=image(art,"StudPattern",Style.Assets.Studs,11)
  stud.ImageTransparency=1;stud.Size=UDim2.fromScale(1,1)
  local asset=Style.Assets
  -- Reuse one cell of the purchased 512px, 4x4 texture. Smaller raised squares
  -- retain the measured spacing instead of shrinking the entire repeating tile.
  for r=0,asset.StudRows-1 do for c=0,asset.StudColumns-1 do
   local tile=image(stud,"Cell"..c.."_"..r,asset.Studs,11)
   tile.ImageRectOffset=Vector2.zero;tile.ImageRectSize=Vector2.new(asset.StudCell,asset.StudCell)
   tile.ImageTransparency=asset.StudTransparency
   rect(tile,asset.StudOrigin.X+c*asset.StudSpacing,asset.StudOrigin.Y+r*asset.StudSpacing,asset.StudSize,asset.StudSize)
  end end
  local icon=image(art,"StrengthIcon",Style.Assets.Strength,12)
  icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5)
  icon.Size=UDim2.fromOffset(g.PackIconSize,g.PackIconSize)
  M.Text(card.Amount,"Pack");card.Amount.ZIndex=13
  card.Amount.AnchorPoint=Vector2.zero;card.Amount.Position=UDim2.new();card.Amount.Size=UDim2.fromScale(1,1)
  local button=card.Purchase
  local old=button:FindFirstChild("PurchasedButtonVisual");if old then old:Destroy() end
  button.Text="";button.BackgroundTransparency=1;button.BorderSizePixel=0;button.AutoButtonColor=false
  button.AnchorPoint=Vector2.zero;button.Position=UDim2.new();button.Size=UDim2.fromScale(1,1);button.ZIndex=15
  button:SetAttribute("ProductId",product.ProductId)
  M.BindPress(button,card)
 end
 M.Offline(gui.OfflineRewards)
end
function M.Offline(panel)
 local o=Style.Offline
 panel.Size=UDim2.fromOffset(o.Width,o.Height)
 corner(panel,o.Radius)
 -- Preserve the existing outside panel border; gauge borders are inset.
 local border=panel:FindFirstChild("Border");if border then border.Thickness=o.Border end
 for name,box in {Title=o.Title,StrengthIcon=o.Icon,Amount=o.Amount,Claim=o.Claim,Double=o.Double} do rect(panel[name],table.unpack(box)) end
 panel.Close.Size=UDim2.fromOffset(o.CloseSize,o.CloseSize)
 panel.Close.Position=UDim2.new(1,-o.CloseInset,0,o.CloseInset)
 M.Text(panel.Title,"OfflineTitle");M.Text(panel.Amount,"OfflineAmount")
 panel.Amount.TextColor3=Color3.fromRGB(255,223,65)
 M.Text(panel.Claim.Title,"Claim");M.Text(panel.Double.Title,"DoubleClaim");M.Text(panel.Close.Title,"Close")
 panel.Claim.Title.AnchorPoint=Vector2.zero;panel.Double.Title.AnchorPoint=Vector2.zero
 panel.Close.Title.Size=UDim2.fromScale(1,.9)
 -- Preserve the existing purchased Robux icon/glyph, price skin and popup layout.
 local visual=panel.Double.Price:FindFirstChild("PurchasedButtonVisual")
 if visual then M.Text(visual.Main.Amount,"Price");visual.Main.Amount.Size=UDim2.fromScale(.94,.9) end
 for _,frame in {panel.Claim,panel.Double} do M.BindPress(frame.Button,frame) end
end
function M.LayoutItems(hud)
 local row=hud:FindFirstChild("ItemEffectHUD");if not row then return end
 local g=Style.Geometry
 for index,kind in {"Protein","Glove","TrainingBelt"} do
  local entry=row:FindFirstChild(kind)
  if entry and entry.Visible then
   M.Text(entry.Effect,"Item")
   local textWidth=math.ceil(TextService:GetTextSize(entry.Effect.Text,Style.Text.Item.Size,Style.Font,Vector2.new(2000,g.ItemHeight)).X)
   local iconSize,textX=g.ItemIcons[index],g.ItemTextOffsets[index]
   rect(entry,g.ItemColumns[index],0,textX+textWidth,g.ItemHeight)
   rect(entry.IconSlot,(g.ItemHeight-iconSize)/2,(g.ItemHeight-iconSize)/2,iconSize,iconSize)
   rect(entry.Effect,textX,0,textWidth,g.ItemHeight)
  end
 end
 row.AnchorPoint=Vector2.zero;row.Position=UDim2.fromOffset(g.ItemRowX,g.ItemY);row.Size=UDim2.fromOffset(g.ItemRowWidth,g.ItemHeight)
 row.Active=false
 local badge=hud:FindFirstChild("ElementSetBonus")
 if badge then
  M.Text(badge.Multiplier,"AutoTitle");badge.Multiplier.Size=UDim2.fromOffset(0,g.BadgeHeight)
  badge.ElementIcon.Size=UDim2.fromOffset(21,21);badge.Size=UDim2.fromOffset(0,g.BadgeHeight)
  badge.AnchorPoint=Vector2.new(.5,1);badge.Position=UDim2.new(.5,0,0,-g.BadgeGap)
 end
end
function M.Layout(gui,w,h,blocks)
 local g=Style.Geometry;local hud=gui.StrengthLevelHUD
 local viewportHeight=h
 if gui:IsA("ScreenGui") and not gui.IgnoreGuiInset then
  local top,bottom=game:GetService("GuiService"):GetGuiInset()
  viewportHeight+=top.Y+bottom.Y
 end
 local compact=w<700 or h<500
 local scale=compact and math.min((w-2*g.Edge-g.AutoMinTouch)/(g.Width+g.AutoGap),viewportHeight/g.Reference.Y)
  or math.min(w/g.Reference.X,viewportHeight/g.Reference.Y)
 -- Reserve Auto Tap to the right on narrow displays, without altering its input.
 scale=math.min(scale,(w-2*g.Edge)/(g.Width+g.AutoGap+g.AutoWidth))
 local autoWidth=math.ceil(math.max(g.AutoWidth,compact and g.AutoMinTouch/scale or 0))
 local autoHeight=math.ceil(math.max(g.AutoHeight,compact and g.AutoMinTouch/scale or 0))
 local x=math.clamp((w-g.Width*scale)/2+g.CenterOffset*scale,g.Edge,math.max(g.Edge,w-g.Edge-(g.Width+g.AutoGap+autoWidth)*scale))
 local y=h-(g.Bottom+g.Height)*scale
 -- Only interactive rectangles reserve space: do not move the user's menus.
 local function intersects(a,b)
  return a.X<b.X+b.W and a.X+a.W>b.X and a.Y<b.Y+b.H and a.Y+a.H>b.Y
 end
 if blocks then
  local preferredY=y
  for candidate=preferredY,0,-4 do
   local packRect={X=x,Y=candidate+g.PacksY*scale,W=g.Width*scale,H=g.PackHeight*scale}
   local autoRect={X=x+(g.Width+g.AutoGap)*scale,Y=candidate+(g.LevelY+g.LevelHeight-autoHeight)*scale,W=autoWidth*scale,H=autoHeight*scale}
   local clear=true
   for _,block in blocks do if intersects(packRect,block) or intersects(autoRect,block) then clear=false;break end end
   if clear then y=candidate;break end
  end
 end
 node(hud,"UIScale","ReferenceScale").Scale=scale
 rect(hud,x,y,g.Width,g.Height)
 local slot=gui:FindFirstChild("HUD") and gui.HUD:FindFirstChild("BottomStatus")
 if slot then rect(slot,x,y,g.Width*scale,g.Height*scale) end
 local health=hud:FindFirstChild("PlayerHealth")
 if health then
  rect(health,g.HealthX,g.HealthY,g.HealthWidth,g.HealthHeight)
  rect(health.FillClip.Main,0,0,g.HealthWidth-2*Style.Border.Gauge,g.HealthHeight-2*Style.Border.Gauge)
  M.SetFill(health,health.FillClip.Size.X.Scale)
  rect(health.Exp,0,0,g.HealthWidth,g.HealthHeight);health.Exp.TextXAlignment=Enum.TextXAlignment.Center
  rect(health.Heart,g.HeartX,g.HeartY,g.HeartSize,g.HeartSize)
 end
 local total=hud.StrengthValueContainer
 rect(total,g.StrengthX,g.StrengthY,g.StrengthWidth,g.StrengthHeight)
 rect(total.StrengthIcon,0,(g.StrengthHeight-g.ArmSize)/2,g.ArmSize,g.ArmSize)
 local number,unit=total.Strength,total.StrengthUnit
 local size=Style.Text.Strength.Size
 local function measured(text,s)return TextService:GetTextSize(text,s,Style.Font,Vector2.new(2000,200)).X end
 local width=measured(number.Text.." "..unit.Text,size)
 size=math.max(Style.Text.Strength.MinSize,math.min(size,size*g.StrengthTextWidth/math.max(1,width)))
 number.TextSize=size;unit.TextSize=size
 number.AutomaticSize=Enum.AutomaticSize.None;unit.AutomaticSize=Enum.AutomaticSize.None
 local nw=math.ceil(measured(number.Text,size));local gap=math.ceil(measured(" ",size))
 rect(number,g.StrengthTextX,0,nw,g.StrengthHeight)
 rect(unit,g.StrengthTextX+nw+gap,0,g.StrengthTextWidth-nw-gap,g.StrengthHeight)
 number.TextXAlignment=Enum.TextXAlignment.Left;unit.TextXAlignment=Enum.TextXAlignment.Left
 rect(hud.LevelPanel,0,g.LevelY,g.Width,g.LevelHeight)
 local bar=hud.LevelPanel.StrengthProgressBar
 rect(bar.FillClip.Main,0,0,g.Width-2*Style.Border.Gauge,g.LevelHeight-2*Style.Border.Gauge)
 M.SetFill(bar,bar.FillClip.Size.X.Scale)
 rect(bar.Level,g.LevelInset,0,220,g.LevelHeight);bar.Level.TextXAlignment=Enum.TextXAlignment.Left
 rect(bar.Exp,250,0,g.Width-250-g.LevelInset,g.LevelHeight);bar.Exp.TextXAlignment=Enum.TextXAlignment.Right
 rect(hud.StrengthPacks,0,g.PacksY,g.Width,g.PackHeight)
 local cardWidth=(g.Width-2*g.PackGap)/3
 for index,product in ipairs(require(RS.Config.StrengthRewardConfig).Packs) do
  local left=math.round((index-1)*(cardWidth+g.PackGap))
  local right=index==3 and g.Width or math.round(index*(cardWidth+g.PackGap))-g.PackGap
  rect(hud.StrengthPacks[tostring(product.ProductId)],left,0,right-left,g.PackHeight)
 end
 local auto=hud.LevelPanel:FindFirstChild("AutoTapButton")
 if auto then
  rect(auto,g.Width+g.AutoGap,g.LevelHeight-autoHeight,autoWidth,autoHeight);auto.Visible=true
  stroke(auto,Style.Border.Gauge,Enum.ApplyStrokeMode.Border)
  M.Text(auto.Title,"AutoTitle");M.Text(auto.State,"AutoState")
  if compact then
   auto.Title.TextSize=math.max(Style.Text.AutoTitle.Size,Style.Text.AutoTitle.MinScreenSize/scale)
   auto.State.TextSize=math.max(Style.Text.AutoState.Size,Style.Text.AutoState.MinScreenSize/scale)
  end
 end
 M.LayoutItems(hud)
 local offline=gui:FindFirstChild("OfflineRewards")
 if offline then local o=Style.Offline;offline.RewardScale.Scale=math.min(1,(w-o.MarginX)/o.Width,(h-o.MarginY)/o.Height) end
 return x,y,g.Width*scale,g.Height*scale
end
return M
