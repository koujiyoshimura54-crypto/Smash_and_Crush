-- Layout slots own placement; existing public button paths remain stable.
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local M={}
local mounted=setmetatable({}, {__mode="k"})
function M.GetScale(object)
 local scale=1 local x=object
 while x and not x:IsA("ScreenGui") do
  local s=x:FindFirstChildOfClass("UIScale") if s then scale*=s.Scale end
  x=x.Parent
 end
 return math.max(scale,.001)
end
function M.GetLocalSize(object) return object.AbsoluteSize/M.GetScale(object) end
local function shown(x)
 while x do
  if x:IsA("GuiObject") and not x.Visible then return false end
  if x:IsA("ScreenGui") then return x.Enabled end
  x=x.Parent
 end
 return true
end
function M.GetControls(playerGui)
 local a={}
 local touch=playerGui:FindFirstChild("TouchGui")
 if touch and touch.Enabled then for _,x in ipairs(touch:GetDescendants()) do
  if (x.Name=="JumpButton" or x.Name=="ThumbstickStart" or x.Name=="ThumbstickEnd" or x.Name=="ThumbstickFrame") and x:IsA("GuiObject") and shown(x) then
   table.insert(a,{Name=x.Name,P=x.AbsolutePosition,S=x.AbsoluteSize})
  end
 end end
 return a
end

-- Rectangles use the same safe-area coordinate space as StrengthGui.
local function overlaps(a,b,gap)
 gap=gap or 0
 return a.X<b.X+b.W+gap and a.X+a.W+gap>b.X and a.Y<b.Y+b.H+gap and a.Y+a.H+gap>b.Y
end
local function tabletControls(playerGui)
 local out={}
 local touchGui=playerGui:FindFirstChild("TouchGui")
 if not touchGui then return out end
 for _,x in ipairs(touchGui:GetDescendants()) do
  -- DynamicThumbstickFrame is an input-capture area, not a visible joystick.
  if (x.Name=="JumpButton" or x.Name=="ThumbstickStart" or x.Name=="ThumbstickEnd" or x.Name=="ThumbstickFrame")
   and x:IsA("GuiObject") and shown(x) and x.AbsoluteSize.X>0 and x.AbsoluteSize.Y>0 then
   table.insert(out,{X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y})
  end
 end
 return out
end
local function freePosition(x,y,width,height,blocks,w,h,edge,minY,fixedX)
 local xs={x};local ys={y,minY,h-edge-height}
 if not fixedX then table.insert(xs,edge);table.insert(xs,w-edge-width);table.insert(xs,(w-width)/2) end
 for _,b in ipairs(blocks) do
  table.insert(ys,b.Y-height-10);table.insert(ys,b.Y+b.H+10)
  if not fixedX then table.insert(xs,b.X-width-10);table.insert(xs,b.X+b.W+10) end
 end
 local bestX,bestY,bestDistance
 for _,cx in ipairs(xs) do for _,cy in ipairs(ys) do
  if cx>=edge and cy>=minY and cx+width<=w-edge and cy+height<=h-edge then
   local clear=true;local rect={X=cx,Y=cy,W=width,H=height}
   for _,b in ipairs(blocks) do if overlaps(rect,b,8) then clear=false;break end end
   local distance=(cx-x)^2+(cy-y)^2
   if clear and (not bestDistance or distance<bestDistance) then bestX,bestY,bestDistance=cx,cy,distance end
  end
 end end
 return bestX,bestY
end

function M.Mount(gui)
 if mounted[gui] then return mounted[gui] end
 local hud=gui:WaitForChild("HUD");local menu=gui:WaitForChild("LeftMenu")
 menu.MenuScale.Scale=1;menu.Position=UDim2.new()
 local function follow(slot,button,scale)
  if not button then return end
  local ui=button:FindFirstChild("HUDScale") or button:FindFirstChild("MenuLayoutScale")
  if not ui then ui=Instance.new("UIScale");ui.Name="HUDScale";ui.Parent=button end
  ui.Scale=scale
  local design=slot:GetAttribute("DesignSize")
  button.Size=UDim2.fromOffset(design.X,design.Y);button.AnchorPoint=Vector2.zero
  local origin=button.Parent.AbsolutePosition
  local center=(slot.AbsoluteSize.X-design.X*scale)/2
  button.Position=UDim2.fromOffset(slot.AbsolutePosition.X-origin.X+center,slot.AbsolutePosition.Y-origin.Y)
 end
 local function scaleOf(x,s)
  local u=x:FindFirstChild("HUDScale")
  if not u then u=Instance.new("UIScale");u.Name="HUDScale";u.Parent=x end
  u.Scale=s
 end
 local lastRightTarget,rightTween,hadOverlay
 local function layout()
  local v=gui.AbsoluteSize if v.X<=0 or v.Y<=0 then return end
  local w,h=v.X,v.Y;local compact=w<700 or h<500
  local controls=M.GetControls(gui.Parent);local touch=#controls>0
  local edge=math.clamp(w*.02,8,24)
  local preferred=math.clamp(math.min((w/1917)^.45,(h/1022)^.45),.34,1)
  local win=gui:FindFirstChild("WinLabel")
  local winScale=compact and .6 or preferred
  local winY=compact and 4 or 72*preferred
  local winX=compact and w>h and (w-280*winScale)/2 or (compact and edge or 20)
  hud.TopHUD.Position=UDim2.fromOffset(winX,winY);hud.TopHUD.Size=UDim2.fromOffset(280,64);hud.TopHUD.HUDScale.Scale=winScale
  if win then scaleOf(win,winScale);win.Position=UDim2.fromOffset(winX,winY) end
  local top=compact and (w>h and 8 or winY+64*winScale+10) or 144*preferred
  local leftBottom=h-16;local rightBottom=h-16;local thumbEnd=0;local jumpStart=w
  for _,r in ipairs(controls) do
   if r.Name=="JumpButton" then rightBottom=math.min(rightBottom,r.P.Y-10);jumpStart=math.min(jumpStart,r.P.X-12)
   else leftBottom=math.min(leftBottom,r.P.Y-10);thumbEnd=math.max(thumbEnd,r.P.X+r.S.X+12) end
  end
  local columns=2 -- Original two-column LeftMenu, including on phones.
  local rows=math.ceil(5/columns)
  local leftWidth=(columns*144+(columns-1)*14)
  local leftHeight=(rows*144+(rows-1)*14)
  local limitW=compact and w>h and math.max(44,winX-edge-12) or math.max(144,w*.45)
  local ls=math.clamp(math.min(preferred,(leftBottom-top)/leftHeight,limitW/leftWidth),.12,1)
  local rs=math.clamp(math.min(preferred,(rightBottom-top)/476),44/144,1)
  local tablet=touch and math.min(w,h)>=500
  local tabletBase=ls
  if tablet then
   -- Preserve the approved landscape design budget without reading the large
   -- DynamicThumbstickFrame capture rectangle. Physical controls are checked below.
   local referenceBottom=Vector2.new(0,h/3).Y -- Match GuiObject coordinate precision.
   local designHeight=w>=h and (referenceBottom-10-top) or (h-16-top)
   tabletBase=math.clamp(math.min(preferred,designHeight/leftHeight,limitW/leftWidth),.12,1)
  end
  local leftScale=(tablet and tabletBase or ls)*(tablet and 3.0 or 1)
  local leftX,leftY=edge,top
  local physicalControls=tablet and tabletControls(gui.Parent) or {}
  local minLeftY=math.min(top,winY+64*winScale+6)
  local left=hud.LeftHUD
  left.UIGridLayout.FillDirectionMaxCells=columns
  left.Size=UDim2.fromOffset(leftWidth,leftHeight);left.Position=UDim2.fromOffset(edge,top);left.HUDScale.Scale=leftScale
  local right=hud.RightHUD
  local rightX=w-edge-211*rs
  local rightY=top
  local handle=mounted[gui]
  local overlay=handle and handle.OverlayRoot
  if overlay and not overlay.Parent then overlay=nil;handle.OverlayRoot=nil end
  if overlay then
   local oscale=math.clamp(preferred,.6,1)
   local ow,oh=220*oscale,240*oscale
   local oy=8;local ox=w-edge-ow
   local stacked=oy+oh+12+476*rs<=rightBottom
   if stacked then rightY=math.max(top,oy+oh+12)
   else ox=rightX-12-ow;oy=math.max(8,winY+64*winScale+12) end
   scaleOf(overlay,oscale)
   overlay.Size=UDim2.fromOffset(220,240);overlay.AnchorPoint=Vector2.zero
   overlay.Position=UDim2.fromOffset(ox,oy)
   overlay.Parent.DisplayOrder=45
   local slot=hud.Overlay.RouletteSlot
   slot.Visible=true;slot.Position=UDim2.fromOffset(ox,oy);slot.Size=UDim2.fromOffset(ow,oh)
   gui:SetAttribute("PanelReserveTop",w<h and oy+oh+12 or 0)
   gui:SetAttribute("PanelReserveRight",w>=h and ox<(w+920)/2+12 and w-ox+12 or 0)
  else
   hud.Overlay.RouletteSlot.Visible=false
   gui:SetAttribute("PanelReserveTop",0);gui:SetAttribute("PanelReserveRight",0)
  end
  if tablet then
   local function leftRect() return {X=leftX,Y=leftY,W=leftWidth*leftScale,H=leftHeight*leftScale} end
   -- Move within the available screen before limiting the final (3x) size.
   leftY=math.max(minLeftY,math.min(leftY,h-edge-leftHeight*leftScale))
   leftScale=math.min(leftScale,(w-2*edge)/leftWidth,(h-edge-leftY)/leftHeight)
   local rr={X=rightX,Y=rightY,W=211*rs,H=476*rs}
   if overlaps(leftRect(),rr,10) then
    local blocks=table.clone(physicalControls);table.insert(blocks,leftRect())
    local nx,ny=freePosition(rightX,rightY,rr.W,rr.H,blocks,w,h,edge,top,true)
    if nx then rightX,rightY=nx,ny
    else
     -- No vertical slot for RightHUD: use its actual left edge as a last-resort limit.
     leftScale=math.min(leftScale,math.max(1,rightX-leftX-12)/leftWidth)
    end
   end
   for _,r in ipairs(physicalControls) do for i=0,4 do
    local bottom=math.floor(i/columns)*158+144
    local button={X=leftX+(i%columns)*158*leftScale,Y=leftY+(bottom-144)*leftScale,W=144*leftScale,H=144*leftScale}
    if overlaps(button,r,10) then
     local candidateY=r.Y-10-bottom*leftScale
     if candidateY>=minLeftY then leftY=math.min(leftY,candidateY)
     else leftScale=math.min(leftScale,math.max(1,r.Y-leftY-10)/bottom) end
    end
   end end
   left.Position=UDim2.fromOffset(leftX,leftY);left.HUDScale.Scale=leftScale
  end
  local target=UDim2.fromOffset(rightX,rightY)
  if target~=lastRightTarget then
   if rightTween then rightTween:Cancel();rightTween=nil end
   if hadOverlay and not overlay then
    rightTween=TweenService:Create(right,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=target});rightTween:Play()
   else right.Position=target end
   lastRightTarget=target
  end
  hadOverlay=overlay~=nil
  right.HUDScale.Scale=rs
  for _,slot in ipairs(left:GetChildren()) do if slot:IsA("Frame") then follow(slot,menu:FindFirstChild(slot.Name),leftScale) end end
  for _,slot in ipairs(right:GetChildren()) do if slot:IsA("Frame") then
   local boost=gui.Parent:FindFirstChild("World1DoubleWinGui")
   follow(slot,slot.Name=="DoubleWinButton" and boost and boost:FindFirstChild("DoubleWinButton") or menu:FindFirstChild(slot.Name),rs)
  end end
  local strength=gui:FindFirstChild("StrengthLevelHUD")
  local potion=gui:FindFirstChild("PotionStatus")
  local statusBlocks
  if strength then
   local sw,sh,sx,sy
   if touch then
    -- Mobile status HUD is centered on the full viewport and may overlap controls.
    sw=math.min(400,w-2*edge);sx=(w-sw)/2;sy=h-70;sh=58
   elseif compact then
    local laneStart=edge;local laneEnd=jumpStart
    if laneEnd-laneStart>=180 then
     sw=math.min(400,laneEnd-laneStart-16);sx=(laneStart+laneEnd-sw)/2;sy=h-70;sh=58
    else
     local gapLeft=edge+leftWidth*ls+10;local gapRight=right.Position.X.Offset-10
     sw=math.max(160,math.min(300,gapRight-gapLeft));sx=(gapLeft+gapRight-sw)/2
     sy=math.min(leftBottom,rightBottom)-66;sh=58
    end
   else
    sw=w*(1158/1918);local bh=math.min(w/1918,h/1006)*74
    sh=bh*1.75;sx=(w-sw)/2;sy=h*(919/1006)-sh
   end
   if tablet then
    -- Only interactive HUD is reserved here; display HUD may overlap touch controls.
    local blocks={}
    table.insert(blocks,{X=rightX,Y=rightY,W=211*rs,H=476*rs})
    table.insert(blocks,{X=winX,Y=winY,W=280*winScale,H=64*winScale})
    -- Keep the empty sixth slot available; the five actual buttons are obstacles.
    for i=0,4 do table.insert(blocks,{X=leftX+(i%columns)*158*leftScale,
     Y=leftY+math.floor(i/columns)*158*leftScale,W=144*leftScale,H=144*leftScale}) end
    local slot=hud.Overlay.RouletteSlot
    if slot.Visible then table.insert(blocks,{X=slot.Position.X.Offset,Y=slot.Position.Y.Offset,W=slot.Size.X.Offset,H=slot.Size.Y.Offset}) end
    statusBlocks=blocks
   end
   if touch then
    hud.BottomStatus.AnchorPoint=Vector2.new(.5,0);hud.BottomStatus.Position=UDim2.new(.5,0,0,sy)
    strength.AnchorPoint=Vector2.new(.5,0);strength.Position=UDim2.new(.5,0,0,sy)
   else
    hud.BottomStatus.AnchorPoint=Vector2.zero;hud.BottomStatus.Position=UDim2.fromOffset(sx,sy)
    strength.AnchorPoint=Vector2.zero;strength.Position=UDim2.fromOffset(sx,sy)
   end
   hud.BottomStatus.Size=UDim2.fromOffset(sw,sh);strength.Size=UDim2.fromOffset(sw,sh)
   local small=touch or compact;local bh=small and 32 or sh/1.75;local th=small and 22 or bh*.62;local gap=small and 4 or bh*.13
   local strengthDisplay=strength:FindFirstChild("StrengthValueContainer")
   if strengthDisplay then
    strengthDisplay.Position=UDim2.new();strengthDisplay.Size=UDim2.new(1,0,0,th)
    local textSize=small and 18 or th*.94
    for _,label in ipairs({strengthDisplay.Strength,strengthDisplay.StrengthUnit}) do
     label.Size=UDim2.new(0,0,1,0);label.AutomaticSize=Enum.AutomaticSize.X;label.TextSize=textSize;label.TextScaled=false
    end
   else
    strength.Strength.Position=UDim2.new();strength.Strength.Size=UDim2.new(1,0,0,th);strength.Strength.TextSize=small and 18 or th*.94
    strength.Strength.TextScaled=false
   end
   local bar=strength.LevelPanel;bar.Position=UDim2.fromOffset(0,th+gap);bar.Size=UDim2.new(1,0,0,bh)
   for _,label in ipairs({bar.Level,bar.ProgressText}) do label.TextScaled=true end
   bar.ProgressBackground.ProgressClip.Fill.Size=UDim2.fromOffset(bar.AbsoluteSize.X,bar.AbsoluteSize.Y)
   if potion and potion.Visible then
    local count=0 for _,r in ipairs(potion:GetChildren()) do if r:IsA("Frame") and r.Visible then count+=1 end end
    local ph=math.max(38,count*42-4)
    local pw=math.min(202,small and sw or 202)
    potion.Size=UDim2.fromOffset(pw,ph)
    local px=small and sx+(sw-pw)/2 or 14
    local py=small and math.max(4,sy-ph-8) or h-ph-14
    local slot=hud.Overlay.RouletteSlot
    if slot.Visible then
     local op=slot.Position;local os=slot.Size
     if px<op.X.Offset+os.X.Offset and px+pw>op.X.Offset and py<op.Y.Offset+os.Y.Offset and py+ph>op.Y.Offset then
      local available=op.X.Offset-12-edge
      if available>=140 then pw=math.min(pw,available);px=op.X.Offset-12-pw
      else py=op.Y.Offset+os.Y.Offset+8 end
     end
    end
    if tablet and statusBlocks then
     local blocks=table.clone(statusBlocks)
     table.insert(blocks,{X=sx,Y=sy,W=sw,H=sh})
     local current={X=px,Y=py,W=pw,H=ph};local collision=false
     for _,r in ipairs(blocks) do if overlaps(current,r,8) then collision=true;break end end
     if collision then
      local nx,ny=freePosition(px,py,pw,ph,blocks,w,h,edge,4,false)
      if nx then px,py=nx,ny end
     end
    end
    potion.Size=UDim2.fromOffset(pw,ph)
    potion.Position=UDim2.fromOffset(px,py)
   end
  end
 end
 local conn=RunService.RenderStepped:Connect(layout)
 local handle={Refresh=layout}
 mounted[gui]=handle
 gui.Destroying:Connect(function()conn:Disconnect();mounted[gui]=nil end)
 layout()
 return handle
end
function M.Reserve(gui,root)
 local handle=M.Mount(gui)
 handle.OverlayRoot=root
 handle.Refresh()
 return function()
  if handle.OverlayRoot==root then handle.OverlayRoot=nil;handle.Refresh() end
 end
end
return M

