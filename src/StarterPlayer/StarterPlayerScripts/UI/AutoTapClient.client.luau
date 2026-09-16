local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local remote=RS:WaitForChild("Remotes"):WaitForChild("AutoTapRequest")
local config=require(RS:WaitForChild("Config"):WaitForChild("AutoTapConfig"))
local gui=Instance.new("ScreenGui")
gui.Name="AutoTapGui"
gui.ResetOnSpawn=false
gui.DisplayOrder=11
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=playerGui
local button=Instance.new("TextButton")
button.Name="Toggle"
button.AnchorPoint=Vector2.new(0.5,0)
button.Font=Enum.Font.GothamBold
button.TextSize=18
button.TextColor3=Color3.new(1,1,1)
button.AutoButtonColor=true
button.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,10)
corner.Parent=button
local stroke=Instance.new("UIStroke")
stroke.Color=Color3.fromRGB(28,40,55)
stroke.Thickness=2
stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
stroke.Parent=button
local function layout()
 button.Size=UDim2.fromOffset(UIS.TouchEnabled and 112 or 128,UIS.TouchEnabled and 52 or 58)
 button.Position=UDim2.new(0.70,0,0,UIS.TouchEnabled and 5 or 10)
end
local function refresh()
 local enabled=player:GetAttribute("AutoTapEnabled")~=false
 button.Text="Auto Tap\n"..(enabled and "ON" or "OFF")
 button.BackgroundColor3=enabled and Color3.fromRGB(45,151,90) or Color3.fromRGB(110,116,128)
end
layout()
refresh()
UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(layout)
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
