local CollectionService=game:GetService("CollectionService")
local TREADMILL_TAG="TrainingTreadmill"
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Config = require(game:GetService("ReplicatedStorage").Config:WaitForChild("TreadmillConfig"))
local red = Color3.fromRGB(255, 60, 60)
local blue = Color3.fromRGB(55, 145, 255)

local function refresh()
 local count = tonumber(player:GetAttribute("RebirthCount")) or 0
 for _,model in ipairs(CollectionService:GetTagged(TREADMILL_TAG)) do
  local modelName=model.Name
  local display = model and model:FindFirstChild("TreadmillUIDisplay")
  local gui = display and display:FindFirstChild("TreadmillInfo")
  local required = gui and gui:FindFirstChild("Required")
  local entry = Config.GetForModel(model)
  if not entry then continue end
  if Config.WorldForModel(model)==2 then
   local label=model:FindFirstChild("StationBillboard") and model.StationBillboard:FindFirstChild("Multiplier")
   if label then label.Text=tostring(entry.Multiplier).."x Strength\n"..(entry.PurchaseEnabled==false and "Robux - Unavailable" or (entry.RequiredRebirth>0 and "Rebirth "..entry.RequiredRebirth.." Required" or "Available")) end
  end
  local strength = gui and gui:FindFirstChild("Strength")
  if strength then strength.Text = "×"..tostring(entry.Multiplier).." Strength" end
  if required and entry.RequiredRebirth then
   required.Text = tostring(entry.RequiredRebirth).." Rebirth Required"
   required.TextColor3 = count >= entry.RequiredRebirth and blue or red
  end
 end
end
player:GetAttributeChangedSignal("RebirthCount"):Connect(refresh)
CollectionService:GetInstanceAddedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
CollectionService:GetInstanceRemovedSignal(TREADMILL_TAG):Connect(function() task.defer(refresh) end)
refresh()
