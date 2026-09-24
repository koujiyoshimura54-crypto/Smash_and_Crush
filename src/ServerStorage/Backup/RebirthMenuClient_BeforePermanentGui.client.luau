local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Config=require(RS.Config:WaitForChild("RebirthConfig"))
local request=RS.Remotes:WaitForChild("RebirthRequest")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local button=menu:WaitForChild("RebirthButton")
local badge=button:WaitForChild("ReadyBadge")
local pack=workspace:FindFirstChild("EssentialUI_V1.05")
local starter=pack and pack:FindFirstChild("StarterGui")
local main=starter and starter:FindFirstChild("Main")
local frames=main and main:FindFirstChild("Frames")
local source=frames and frames:FindFirstChild("DailyRewards")
assert(source,"Essential Rewards frame not found")
local old=gui:FindFirstChild("RebirthPanel")
if old then old:Destroy() end
local panel=source:Clone()
panel.Name="RebirthPanel"
panel.Visible=false
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.ZIndex=1
panel.Parent=gui
panel.BackgroundColor3=Color3.fromRGB(70,72,82)
panel.BackgroundTransparency=0.12

local responsiveScale=panel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
responsiveScale.Name="ResponsiveScale"
responsiveScale.Scale=1
responsiveScale.Parent=panel
local designWidth,designHeight
local function positionPanel()
 local view=gui.AbsoluteSize
 if view.X<=0 or view.Y<=0 then return end
 if not designWidth or not designHeight then
  designWidth=panel.AbsoluteSize.X/math.max(responsiveScale.Scale,0.001)
  designHeight=panel.AbsoluteSize.Y/math.max(responsiveScale.Scale,0.001)
  if designWidth<=0 then designWidth=view.X*panel.Size.X.Scale end
  if designHeight<=0 then designHeight=view.Y*panel.Size.Y.Scale end
 end
 responsiveScale.Scale=math.clamp(math.min(1,(view.X-24)/designWidth,(view.Y-24)/designHeight),0.35,1)
 panel.AnchorPoint=Vector2.new(0.5,0.5)
 panel.Position=UDim2.fromScale(0.5,0.5)
end

menu:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionPanel)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionPanel)
positionPanel()

local top=panel:WaitForChild("Top")
for _,label in ipairs(top:GetChildren()) do
 if label:IsA("TextLabel") then label.Text="REBIRTH" end
end
local titleIcon=top:FindFirstChild("Icon")
if titleIcon and (titleIcon:IsA("ImageLabel") or titleIcon:IsA("ImageButton")) then
 titleIcon.Image="rbxassetid://93478531548309"
 titleIcon.ScaleType=Enum.ScaleType.Fit
end

local holder=panel:WaitForChild("Holder")
local layout=holder:FindFirstChildOfClass("UIListLayout")
if layout then layout:Destroy() end
holder.AnchorPoint=Vector2.new(0.5,0)
holder.Position=UDim2.new(0.5,0,0.19,0)
holder.Size=UDim2.new(0.86,0,0.46,0)
local current=holder:FindFirstChild("1")
assert(current,"Rewards card template not found")
current.Name="CurrentCard"
local after=holder:FindFirstChild("AfterCard")
if after then after:Destroy() end
after=current:Clone()
after.Name="AfterCard"
after.Parent=holder
current.AnchorPoint=Vector2.new(0,0)
current.Position=UDim2.new(0.02,0,0,0)
current.Size=UDim2.new(0.43,0,1,0)
after.AnchorPoint=Vector2.new(0,0)
after.Position=UDim2.new(0.55,0,0,0)
after.Size=current.Size
for _,child in ipairs(holder:GetChildren()) do
 if child:IsA("Frame") and child~=current and child~=after then child.Visible=false end
end

local function setupCard(card)
 for _,d in ipairs(card:GetDescendants()) do
  if d:IsA("TextLabel") or d:IsA("TextButton") then d.Visible=false end
 end
 local decor=card:FindFirstChild("Decor",true)
 if decor and decor:IsA("GuiObject") then
  decor.Visible=true
  decor.AnchorPoint=Vector2.new(0.5,0.5)
  decor.Position=UDim2.new(0.5,0,0.39,0)
  decor.Size=UDim2.new(0.68,0,0.52,0)
  local strengthIcon=decor:FindFirstChild("Icon")
  if strengthIcon and strengthIcon:IsA("ImageLabel") then
   strengthIcon.Image="rbxassetid://116168408268324"
   strengthIcon.ScaleType=Enum.ScaleType.Fit
  end
 end
 local reward=card:FindFirstChild("RewardText",true)
 if reward then
  reward.Visible=true
  reward.TextColor3=Color3.fromRGB(255,255,255)
  reward.AnchorPoint=Vector2.new(0.5,0.5)
  reward.Position=UDim2.new(0.5,0,0.82,0)
  reward.Size=UDim2.new(0.86,0,0.18,0)
  reward.TextWrapped=false
  reward.TextScaled=true
  reward.ZIndex=25
  for _,constraint in ipairs(reward:GetChildren()) do
   if constraint:IsA("UITextSizeConstraint") then constraint:Destroy() end
  end
 end
end
setupCard(current)
setupCard(after)

local arrow=panel:FindFirstChild("RebirthArrow")
if arrow then arrow:Destroy() end
arrow=Instance.new("TextLabel")
arrow.Name="RebirthArrow"
arrow.BackgroundTransparency=1
arrow.Text=">"
arrow.TextColor3=Color3.fromRGB(255,255,255)
arrow.Font=Enum.Font.GothamBlack
arrow.TextScaled=true
arrow.AnchorPoint=Vector2.new(0.5,0.5)
arrow.Size=UDim2.new(0.08,0,0.12,0)
arrow.Position=UDim2.new(0.5,0,0.42,0)
arrow.ZIndex=25
arrow.Parent=panel

local templateLabel=top:FindFirstChildWhichIsA("TextLabel") or current:FindFirstChild("RewardText",true)
local function addLabel(name,text,pos,size)
 local x=templateLabel:Clone()
 x.Name=name
 x.Text=text
 x.Position=pos
 x.Size=size
 x.AnchorPoint=Vector2.new(0.5,0.5)
 x.ZIndex=25
 x.Parent=panel
 return x
end
local progress=addLabel("RebirthProgress","Lv. 1 / N/A",UDim2.new(0.5,0,0.695,0),UDim2.new(0.78,0,0.045,0))
local note=addLabel("RebirthNotice","RebirthするとStrengthとLevelがリセットされます",UDim2.new(0.5,0,0.815,0),UDim2.new(0.86,0,0.04,0))
note.TextWrapped=true
local rebirth=panel:WaitForChild("UnlockALL")
rebirth.Name="RebirthConfirmButton"
rebirth.Visible=true
rebirth.Text="REBIRTH!"
rebirth.Position=UDim2.new(0.5,0,0.915,0)
rebirth.Size=UDim2.new(0.48,0,0.125,0)
rebirth.AnchorPoint=Vector2.new(0.5,0.5)
rebirth.ZIndex=26
local buttonText=rebirth:FindFirstChild("TextLabel",true)
if buttonText then
 buttonText.Text="REBIRTH!"
 buttonText.Visible=true
 buttonText.ZIndex=28
 buttonText.AnchorPoint=Vector2.new(0.5,0.5)
 buttonText.Position=UDim2.fromScale(0.5,0.5)
 buttonText.Size=UDim2.fromScale(0.9,0.75)
 buttonText.TextScaled=true
end
for _,label in ipairs({progress,note}) do
 label.TextScaled=true
 label.TextXAlignment=Enum.TextXAlignment.Center
 label.TextYAlignment=Enum.TextYAlignment.Center
end
local gauge=Instance.new("Frame")
gauge.Name="RebirthLevelBar"
gauge.AnchorPoint=Vector2.new(0.5,0.5)
gauge.Position=UDim2.fromScale(0.5,0.755)
gauge.Size=UDim2.fromScale(0.72,0.045)
gauge.BackgroundColor3=Color3.fromRGB(35,40,48)
gauge.BorderSizePixel=0
gauge.ZIndex=24
gauge.Parent=panel
local fill=Instance.new("Frame")
fill.Name="Fill"
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=rebirth.BackgroundColor3
fill.BorderSizePixel=0
fill.ZIndex=25
fill.ClipsDescendants=true
fill.Parent=gauge
for _,decoration in ipairs(rebirth:GetChildren()) do
 if decoration:IsA("UIStroke") or decoration:IsA("UICorner") then
  decoration:Clone().Parent=gauge
 elseif decoration:IsA("UIGradient") then
  decoration:Clone().Parent=fill
 elseif decoration:IsA("ImageLabel") and decoration.Name=="StudPattern" then
  local pattern=decoration:Clone()
  pattern.ZIndex=26
  pattern.Parent=fill
 end
end

local close=top:WaitForChild("Close")
local function applyLook(b)
 local original=b.Size
 b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(.1,Enum.EasingStyle.Quad),{Size=original}):Play() end)
 b.MouseButton1Down:Connect(function() TweenService:Create(b,TweenInfo.new(.1,Enum.EasingStyle.Quad),{Size=original}):Play() end)
end
applyLook(close)
applyLook(rebirth)

local function level() return tonumber(player:GetAttribute("Level")) or 1 end
local function count() return math.max(0,math.floor(tonumber(player:GetAttribute("RebirthCount")) or 0)) end
local function multiplier(n) return 1+n*0.2 end
local function refresh()
 local lv=level()
 local n=count()
 local req=Config.GetRequiredLevel(n)
 local can=req~=nil and lv>=req
 badge.Visible=can
 fill.Size=UDim2.fromScale(can and 1 or (req and req>0 and math.clamp(lv/req,0,1) or 0),1)
 progress.Text=("Lv.%d / %s"):format(lv,tostring(req or "N/A"))
 local cr=current:FindFirstChild("RewardText",true)
 local ar=after:FindFirstChild("RewardText",true)
 if cr then cr.Text=("x%.1f"):format(multiplier(n)) end
 if ar then ar.Text=("x%.1f"):format(multiplier(n+1)) end
 rebirth.Active=can
 rebirth.AutoButtonColor=can
end
button.Activated:Connect(function() panel.Visible=not panel.Visible; refresh() end)
close.Activated:Connect(function() panel.Visible=false end)
rebirth.Activated:Connect(function()
 refresh()
 if rebirth.Active then request:FireServer("Request") end
end)
request.OnClientEvent:Connect(function(d)
 if d.Type=="Success" then panel.Visible=true; refresh()
 elseif d.Type=="Denied" then panel.Visible=true; refresh() end
end)
player:GetAttributeChangedSignal("Level"):Connect(refresh)
player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
refresh()