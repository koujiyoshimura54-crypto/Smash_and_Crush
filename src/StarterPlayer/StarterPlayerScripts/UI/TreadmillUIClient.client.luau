local treadmillFolder=workspace:WaitForChild("Treadmill")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Config = require(game:GetService("ReplicatedStorage").Config:WaitForChild("TreadmillConfig"))
local red = Color3.fromRGB(255, 60, 60)
local blue = Color3.fromRGB(55, 145, 255)

local function refresh()
 local count = tonumber(player:GetAttribute("RebirthCount")) or 0
 for modelName in pairs(Config.Assignments) do
  local model = treadmillFolder:FindFirstChild(modelName)
  local display = model and model:FindFirstChild("TreadmillUIDisplay")
  local gui = display and display:FindFirstChild("TreadmillInfo")
  local required = gui and gui:FindFirstChild("Required")
  local entry = Config.Get(modelName)
  local strength = gui and gui:FindFirstChild("Strength")
  if strength then strength.Text = "×"..tostring(entry.Multiplier).." Strength" end
  if required and entry.RequiredRebirth then
   required.Text = tostring(entry.RequiredRebirth).." Rebirth Required"
   required.TextColor3 = count >= entry.RequiredRebirth and blue or red
  end
 end
end
player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
treadmillFolder.DescendantAdded:Connect(function(instance)
 if instance.Name == "Required" or instance.Name == "TreadmillInfo" then
  task.defer(refresh)
 end
end)
refresh()
