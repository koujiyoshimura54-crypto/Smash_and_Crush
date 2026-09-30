-- Preserve Roblox's standard Dynamic Thumbstick capture area and hide only its frame background.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
playerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor

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

playerGui.DescendantAdded:Connect(hideZoneBackground)
for _,object in ipairs(playerGui:GetDescendants()) do hideZoneBackground(object) end
