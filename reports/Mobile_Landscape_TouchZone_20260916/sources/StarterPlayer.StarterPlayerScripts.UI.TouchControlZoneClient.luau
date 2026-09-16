-- Keeps Roblox's standard Dynamic Thumbstick while bounding its capture area in landscape.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local frame
local lastParentSize=Vector2.zero
local lastMenuRight=-1
local lastJumpLeft=-1

local function shown(object)
 local current=object
 while current do
  if current:IsA("GuiObject") and not current.Visible then return false end
  if current:IsA("ScreenGui") and not current.Enabled then return false end
  current=current.Parent
 end
 return true
end

local function findFrame()
 local touchGui=playerGui:FindFirstChild("TouchGui")
 if not touchGui or not touchGui.Enabled then return nil end
 local candidate=touchGui:FindFirstChild("DynamicThumbstickFrame",true)
 return candidate and candidate:IsA("GuiObject") and candidate or nil
end

local function leftMenuRight(parentPosition,parentWidth)
 local gui=playerGui:FindFirstChild("StrengthGui")
 local menu=gui and gui:FindFirstChild("LeftMenu")
 if not menu then return 0 end
 local right=0
 for _,object in ipairs(menu:GetDescendants()) do
  if object:IsA("GuiButton") and object.Active and shown(object) then
   local position=object.AbsolutePosition-parentPosition
   if position.X+object.AbsoluteSize.X*.5<parentWidth*.5 then
    right=math.max(right,position.X+object.AbsoluteSize.X+8)
   end
  end
 end
 return right
end

local function jumpLeft(parentPosition,parentWidth)
 local touchGui=playerGui:FindFirstChild("TouchGui")
 local jump=touchGui and touchGui:FindFirstChild("JumpButton",true)
 if not jump or not shown(jump) then return parentWidth end
 return jump.AbsolutePosition.X-parentPosition.X-8
end

local function layout()
 if not frame or not frame.Parent then frame=findFrame() end
 if not frame then return end
 local parent=frame.Parent
 if not parent:IsA("GuiObject") then return end
 local size=parent.AbsoluteSize
 if size.X<=0 or size.Y<=0 or size.X<size.Y then return end
 local tablet=math.min(size.X,size.Y)>=500
 local width
 local height
 if tablet then
  width=math.clamp(size.X*.26,240,320)
  height=math.clamp(size.Y*.38,220,300)
 else
  width=math.clamp(size.X*.40,220,300)
  height=math.clamp(size.Y*.58,190,260)
 end
 local menuRight=leftMenuRight(parent.AbsolutePosition,size.X)
 local jumpStart=jumpLeft(parent.AbsolutePosition,size.X)
 local x=math.min(menuRight,math.max(0,jumpStart-120))
 width=math.max(120,math.min(width,jumpStart-x))
 frame.AnchorPoint=Vector2.zero
 frame.Position=UDim2.new(0,x,1,-height)
 frame.Size=UDim2.fromOffset(width,height)
 frame:SetAttribute("GameTouchZoneClass",tablet and "TabletLandscape" or "SmartphoneLandscape")
 frame:SetAttribute("GameTouchZoneMaxSize",Vector2.new(tablet and 320 or 300,tablet and 300 or 260))
 lastParentSize=size
 lastMenuRight=menuRight
 lastJumpLeft=jumpStart
end

playerGui.DescendantAdded:Connect(function(object)
 if object.Name=="DynamicThumbstickFrame" and object:IsA("GuiObject") then
  frame=object
  task.defer(layout)
 end
end)
RunService.RenderStepped:Connect(function()
 local current=frame or findFrame()
 if current then
  frame=current
  local parent=current.Parent
  local size=parent and parent:IsA("GuiObject") and parent.AbsoluteSize or Vector2.zero
  local menuRight=parent and leftMenuRight(parent.AbsolutePosition,size.X) or 0
  local jumpStart=parent and jumpLeft(parent.AbsolutePosition,size.X) or size.X
  local maximum=math.min(size.X,size.Y)>=500 and Vector2.new(320,300) or Vector2.new(300,260)
  if size~=lastParentSize or math.abs(menuRight-lastMenuRight)>.5 or math.abs(jumpStart-lastJumpLeft)>.5
   or current.Size.X.Scale~=0 or current.Size.Y.Scale~=0
   or current.AbsoluteSize.X>maximum.X+1 or current.AbsoluteSize.Y>maximum.Y+1 then
   layout()
  end
 end
end)
task.defer(layout)
