-- Presentation metadata only: publish actual Lobby footprints outside Workspace streaming.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local bounds=RS:FindFirstChild("BattleBagLobbyBounds")
if not bounds then
 bounds=Instance.new("Folder");bounds.Name="BattleBagLobbyBounds";bounds.Parent=RS
end
local function publish()
 for world,name in {"GeneratedMap","World2Map"} do
  local map=workspace:FindFirstChild(name)
  local area=map and map:FindFirstChild("TrainingArea")
  local floor=area and area:FindFirstChild("Floor")
  if floor and floor:IsA("BasePart") then
   local prefix="World"..world
   if bounds:GetAttribute(prefix.."CFrame")~=floor.CFrame then bounds:SetAttribute(prefix.."CFrame",floor.CFrame) end
   if bounds:GetAttribute(prefix.."Size")~=floor.Size then bounds:SetAttribute(prefix.."Size",floor.Size) end
  end
 end
end
publish()
local elapsed=0
local connection=RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.5 then return end
 elapsed=0;publish()
end)
script.Destroying:Connect(function()connection:Disconnect()end)
