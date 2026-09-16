local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remote=RS:WaitForChild("Remotes"):WaitForChild("AutoTapRequest")
local config=require(RS:WaitForChild("Config"):WaitForChild("AutoTapConfig"))
local HUDLayout=require(RS:WaitForChild("Modules"):WaitForChild("HUDLayout"))
local strengthGui=playerGui:WaitForChild("StrengthGui")
local hud=strengthGui:WaitForChild("StrengthLevelHUD")
local bar=hud:WaitForChild("LevelPanel")
local button=Instance.new("TextButton")
button.Name="AutoTapButton"
button.AnchorPoint=Vector2.new(0,1)
button.Text=""
button.BackgroundColor3=Color3.new(1,1,1)
button.AutoButtonColor=true
button.ZIndex=bar.ZIndex+1
button.Parent=bar
local corner=bar:WaitForChild("Corner"):Clone()
corner.Parent=button
local stroke=bar:WaitForChild("Outline"):Clone()
stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
stroke.Parent=button
local gradient=Instance.new("UIGradient")
gradient.Rotation=90
gradient.Parent=button
local function label(name,text)
 local x=Instance.new("TextLabel")
 x.Name=name
 x.BackgroundTransparency=1
 x.Text=text
 x.Font=bar.Level.Font
 x.TextColor3=Color3.new(1,1,1)
 x.ZIndex=button.ZIndex+1
 x.Parent=button
 local outline=bar.Level:WaitForChild("TextOutline"):Clone()
 outline.Parent=x
 return x
end
local title=label("Title","Auto Tap")
local state=label("State","")
title.Position=UDim2.fromScale(0,0.06)
title.Size=UDim2.fromScale(1,0.38)
state.Position=UDim2.fromScale(0,0.43)
state.Size=UDim2.fromScale(1,0.51)
local function layout()
 -- Inherit the HUD's coordinate space/UIScale instead of reconstructing safe-area positions.
 local height=math.clamp(HUDLayout.GetLocalSize(bar).Y,44,54)
 button.Size=UDim2.fromOffset(math.round(height*1.35),height)
 button.Position=UDim2.new(1,8,1,0)
 title.TextSize=math.clamp(height*0.30,13,16)
 state.TextSize=math.clamp(height*0.44,19,24)
end
local function refresh()
 local enabled=player:GetAttribute("AutoTapEnabled")~=false
 state.Text=enabled and "ON" or "OFF"
 gradient.Color=enabled
  and ColorSequence.new(Color3.fromRGB(255,231,75),Color3.fromRGB(255,151,34))
  or ColorSequence.new(Color3.fromRGB(169,162,180),Color3.fromRGB(91,79,108))
end
layout()
refresh()
bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
player:GetAttributeChangedSignal("AutoTapEnabled"):Connect(refresh)
button.Activated:Connect(function() remote:FireServer("Toggle") end)
local function interactiveAt(position)
 if GuiService.MenuIsOpen or UIS:GetFocusedTextBox() then return true end
 for _,object in playerGui:GetGuiObjectsAtPosition(position.X,position.Y) do
  local node=object
  while node and node~=playerGui do
   if node:IsA("GuiButton") or node:IsA("TextBox") or node:IsA("ScrollingFrame")
    or (node:IsA("GuiObject") and node.Active) then return true end
   node=node.Parent
  end
 end
 return false
end
local lastSent=-math.huge
local function tap(position,processed)
 if processed or player:GetAttribute("AutoTapEnabled")~=false or interactiveAt(position) then return end
 local now=os.clock()
 if now-lastSent<math.min(config.ManualTapCooldown,config.ManualAttackCooldown) then return end
 lastSent=now
 -- The server chooses training versus the current contact combat target.
 remote:FireServer("Tap")
end
UIS.InputBegan:Connect(function(input,processed)
 if input.UserInputType==Enum.UserInputType.MouseButton1 then
  tap(Vector2.new(input.Position.X,input.Position.Y),processed)
 end
end)
-- Tap-in-world excludes drag gestures / thumbstick movement and processed UI touches.
UIS.TouchTapInWorld:Connect(tap)
