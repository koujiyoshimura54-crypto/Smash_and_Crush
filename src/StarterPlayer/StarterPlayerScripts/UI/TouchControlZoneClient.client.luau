-- Preserve Roblox's standard Dynamic Thumbstick capture area and hide only its frame background.
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
-- Match StarterGui's saved policy from the first frame, and repair only on events.
-- CurrentScreenOrientation is the actual device result, not a writable setting.
local lifetime={}
local function landscape()
 if playerGui.ScreenOrientation~=Enum.ScreenOrientation.LandscapeSensor then
  playerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor
 end
end
landscape()
table.insert(lifetime,playerGui:GetPropertyChangedSignal("ScreenOrientation"):Connect(landscape))
table.insert(lifetime,UserInputService.WindowFocused:Connect(landscape))
table.insert(lifetime,player.CharacterAdded:Connect(landscape))
table.insert(lifetime,player:GetAttributeChangedSignal("CurrentWorld"):Connect(landscape))

local bound=setmetatable({}, {__mode="k"})
local function hideZoneBackground(object)
 if object.Name~="DynamicThumbstickFrame" or not object:IsA("GuiObject") or bound[object] then return end
 object.BackgroundTransparency=1
 local changing=false
 local connection=object:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
  if changing or object.BackgroundTransparency==1 then return end
  changing=true
  object.BackgroundTransparency=1
  changing=false
 end)
 bound[object]=connection
 object.Destroying:Once(function()
  connection:Disconnect()
  bound[object]=nil
 end)
end

table.insert(lifetime,playerGui.DescendantAdded:Connect(hideZoneBackground))
for _,object in ipairs(playerGui:GetDescendants()) do hideZoneBackground(object) end

script.Destroying:Once(function()
 for _,connection in lifetime do connection:Disconnect() end
 for _,connection in bound do connection:Disconnect() end
 table.clear(bound)
end)
