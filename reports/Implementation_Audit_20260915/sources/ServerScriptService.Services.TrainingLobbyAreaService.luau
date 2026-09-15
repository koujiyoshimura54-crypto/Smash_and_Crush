-- Phase 7.2.4: authoritative lightweight Training Lobby boundary query.
local Workspace = game:GetService("Workspace")
local AreaService = {}

local function getTrainingFloor()
 local map = Workspace:FindFirstChild("GeneratedMap")
 local area = map and map:FindFirstChild("TrainingArea")
 local floor = area and area:FindFirstChild("Floor")
 return floor and floor:IsA("BasePart") and floor or nil
end

function AreaService.IsInTrainingLobby(player)
 if typeof(player) ~= "Instance" or not player:IsA("Player") then return false end
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 local floor = getTrainingFloor()
 if not humanoid or humanoid.Health <= 0 or not root or not floor then return false end
 local localPosition = floor.CFrame:PointToObjectSpace(root.Position)
 local half = floor.Size * 0.5
 -- Use the authored lobby floor footprint; allow normal jumps above it.
 return math.abs(localPosition.X) <= half.X
  and math.abs(localPosition.Z) <= half.Z
  and localPosition.Y >= -5
  and localPosition.Y <= 50
end

return table.freeze(AreaService)

