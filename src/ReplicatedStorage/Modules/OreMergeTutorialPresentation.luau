-- Display-only adaptation of purchased TutorialClient.guiRect/draw and NotifyClient.pin.
-- No legacy tutorial, data, HUD holding, or input ownership is started here.
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local TextService=game:GetService("TextService")
local Config=require(script.Parent.Config)
local M={}

function M.VisibleRect(target,canvas)
 local pg=canvas:FindFirstAncestorOfClass("PlayerGui")
 local a=target.AbsolutePosition;local b=a+target.AbsoluteSize
 local x=target
 while x and x~=pg do
  if x:IsA("GuiObject") then
   if not x.Visible then return nil end
   if x~=target and x.ClipsDescendants then
    local p=x.AbsolutePosition;local q=p+x.AbsoluteSize
    a=Vector2.new(math.max(a.X,p.X),math.max(a.Y,p.Y))
    b=Vector2.new(math.min(b.X,q.X),math.min(b.Y,q.Y))
   end
  elseif x:IsA("ScreenGui") and not x.Enabled then return nil end
  x=x.Parent
 end
 if not x then return nil end
 local p=canvas.AbsolutePosition;local q=p+canvas.AbsoluteSize
 a=Vector2.new(math.max(a.X,p.X),math.max(a.Y,p.Y))
 b=Vector2.new(math.min(b.X,q.X),math.min(b.Y,q.Y))
 if b.X<=a.X or b.Y<=a.Y then return nil end
 return a-p,b-a
end

function M.Mount(overlay,header)
 local canvas=overlay.Canvas;local focus=canvas.Highlight
 local note=canvas.Notification;local strip=note.Shade;local stack=note.Stack
 local template=stack.Line;local settings=Config.Notify
 local target,snap=nil,true
 local currentText,active=nil,nil
 local order=0
 local closing={};local tweens={};local destroyed=false
 local function tween(x,info,properties)
  local t=TweenService:Create(x,info,properties);table.insert(tweens,t);t:Play()
 end
 local openInfo=TweenInfo.new(settings.openSeconds,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
 local popInfo=TweenInfo.new(settings.openSeconds,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
 local closeInfo=TweenInfo.new(settings.closeSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 local function shadeSequence(edge)
  local points={};local values=settings.Shade;local last=#values-1
  for i,v in ipairs(values) do table.insert(points,NumberSequenceKeypoint.new((i-1)/last*edge,1-v)) end
  for i=#values,1,-1 do table.insert(points,NumberSequenceKeypoint.new(1-(i-1)/last*edge,1-values[i])) end
  return NumberSequence.new(points)
 end
 local function geometry(line)
  local viewport=canvas.AbsoluteSize
  local position=UDim2.fromScale(.5,settings.middle)
  local maxWidth=viewport.X*settings.lineWidth
  local maxHeight=viewport.Y*settings.lineHeight
  if header and header.Parent and header.Parent.Visible then
   local a=header.AbsolutePosition-canvas.AbsolutePosition;local size=header.AbsoluteSize
   local share=note:GetAttribute("HeaderWidthScale") or .7
   position=UDim2.fromOffset(a.X+size.X*(note:GetAttribute("HeaderCenterX") or .5),a.Y+size.Y*.5)
   -- Same pin renderer in the current title band. Reserve room for its 1.25x text,
   -- shade and pop so it cannot cover tabs, close, materials, or Merge.
   maxWidth=math.min(maxWidth,math.max(1,size.X*share-2*settings.shadePad*viewport.X)/settings.textScale)
   maxHeight=math.min(maxHeight,math.max(1,size.Y-8)/(settings.textScale*1.2))
  end
  stack.Position=position;strip.Position=position
  local size=UDim2.fromOffset(maxWidth,maxHeight)
  if line then
   local label=line.Message
   local measureKey=label.Text..":"..tostring(maxHeight)..":"..tostring(label.FontFace)
   if line:GetAttribute("MeasureKey")~=measureKey then
    line:SetAttribute("MeasuredWidth",TextService:GetTextSize(label.Text,maxHeight*settings.textScale,label.Font,Vector2.new(10000,10000)).X)
    line:SetAttribute("MeasureKey",measureKey)
   end
   local measured=Vector2.new(line:GetAttribute("MeasuredWidth"),0)
   local width=math.min(measured.X,maxWidth*settings.textScale)
   local shadeWidth=math.min(width+2*settings.shadePad*viewport.X,settings.width*viewport.X)
   local fade=strip.UIGradient
   if shadeWidth>0 then fade.Transparency=shadeSequence(math.min(settings.shadePad*viewport.X/shadeWidth,.5)) end
   -- Capture authored thickness once per pin; resizing never restores a stock style.
   line.Message.UIStroke.Thickness=math.max(line:GetAttribute("AuthoredThickness")*viewport.Y/(note:GetAttribute("ReferenceHeight") or 720),1)
   return size,UDim2.fromOffset(shadeWidth,(maxHeight+2*settings.shadeMargin*viewport.Y)*settings.shadeScale)
  end
  return size,UDim2.new()
 end
 local function close(line)
  if not line then return end
  closing[line]=true
  tween(line,closeInfo,{Size=UDim2.new()})
  tween(line.Message,closeInfo,{TextTransparency=1})
  tween(line.Message.UIStroke,closeInfo,{Transparency=1})
  tween(line.Message.UIScale,closeInfo,{Scale=.8})
  task.delay(settings.closeSeconds,function()
   closing[line]=nil;line:Destroy()
   if not active and not destroyed then note.Visible=false end
  end)
 end
 local function clearTweens()
  for _,t in tweens do t:Cancel() end;table.clear(tweens)
 end
 local renderer={}
 function renderer:Pin(text)
  if currentText==text then return end
  currentText=text
  clearTweens()
  -- Finish only obsolete notification instances, never duplicate pinned instructions.
  for line in closing do line:Destroy() end;table.clear(closing)
  close(active);active=nil
  if not text then tween(strip,closeInfo,{Size=UDim2.new()});return end
  local line=template:Clone();line.Name="PinnedLine";line.Visible=true
  order+=1;line.LayoutOrder=order
  line:SetAttribute("AuthoredThickness",template.Message.UIStroke.Thickness)
  local label=line.Message;label.Text=text
  local textTransparency=label.TextTransparency;local strokeTransparency=label.UIStroke.Transparency
  label.TextTransparency=1;label.UIStroke.Transparency=1;label.UIScale.Scale=.8
  line.Size=UDim2.new();line.Parent=stack;note.Visible=true;active=line
  local size,shade=geometry(line)
  tween(line,openInfo,{Size=size})
  tween(label,openInfo,{TextTransparency=textTransparency})
  tween(label.UIStroke,openInfo,{Transparency=strokeTransparency})
  tween(label.UIScale,popInfo,{Scale=1})
  tween(strip,openInfo,{Size=shade})
  line:SetAttribute("OpeningUntil",os.clock()+settings.openSeconds)
 end
 function renderer:Target(nextTarget)
  if not target then snap=true end
  target=nextTarget
  if not target then focus.Visible=false end
 end
 function renderer:Hide()
  self:Target(nil);self:Pin(nil)
  -- Death/modal/closure must not leave an outgoing instruction over another UI.
  clearTweens();if active then active:Destroy();active=nil end
  for line in closing do line:Destroy() end;table.clear(closing)
  strip.Size=UDim2.new();note.Visible=false
 end
 local function draw(delta)
  if active then
   local size,shade=geometry(active)
   if os.clock()>active:GetAttribute("OpeningUntil") then active.Size=size;strip.Size=shade end
  end
  if not target or not target.Parent then focus.Visible=false;return end
  local corner,size=M.VisibleRect(target,canvas)
  local viewport=canvas.AbsoluteSize
  if not corner or viewport.X<=0 or viewport.Y<=0 then focus.Visible=false;snap=true;return end
  local grow=focus:GetAttribute("GuiGrow") or Config.Tutorial.guiGrow
  local grown=size*grow+Vector2.new(focus:GetAttribute("PaddingX") or 0,focus:GetAttribute("PaddingY") or 0)*2
  local center=corner+size/2
  -- Preserve the authored AnchorPoint too; default is the donor's centered anchor.
  local anchor=focus.AnchorPoint
  local point=center+Vector2.new((anchor.X-.5)*grown.X,(anchor.Y-.5)*grown.Y)
  local position=UDim2.fromScale(point.X/viewport.X,point.Y/viewport.Y)
  local wanted=UDim2.fromScale(grown.X/viewport.X,grown.Y/viewport.Y)
  if snap then focus.Position=position;focus.Size=wanted;snap=false
  else
   local seconds=focus:GetAttribute("MoveSeconds") or Config.Tutorial.moveSeconds
   local alpha=seconds<=0 and 1 or math.clamp(1-math.exp(-delta/seconds),0,1)
   focus.Position=focus.Position:Lerp(position,alpha);focus.Size=focus.Size:Lerp(wanted,alpha)
  end
  focus.Visible=true
 end
 local connection=RunService.RenderStepped:Connect(draw)
 function renderer:Destroy()
  self:Hide();destroyed=true;connection:Disconnect()
 end
 return renderer
end
return M
