-- Face Stage1 once per character, including respawns. Preserve spawn positions.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local function bind(player)
 local handled = setmetatable({}, {__mode="k"})
 local function faceCharacter(character)
  if handled[character] then return end
  handled[character] = true
  local root = character:WaitForChild("HumanoidRootPart", 10)
  local map = workspace:WaitForChild("GeneratedMap", 10)
  local corridor = map and map:WaitForChild("BattleCorridor", 10)
  local stage = corridor and corridor:WaitForChild("Stage01", 10)
  if not root or not stage then return end
  -- Spawn placement completes before the next simulation frame.
  RunService.Heartbeat:Wait()
  if player.Character ~= character or not root:IsDescendantOf(workspace) then return end
  local position = root.Position
  local target = stage:GetPivot().Position
  local direction = Vector3.new(target.X-position.X, 0, target.Z-position.Z)
  if direction.Magnitude < 0.01 then return end
  root.CFrame = CFrame.lookAt(position, position+direction, Vector3.yAxis)
  character:SetAttribute("SpawnFacingDirection", direction.Unit)
 end
 player.CharacterAdded:Connect(faceCharacter)
 if player.Character then task.spawn(faceCharacter, player.Character) end
end
Players.PlayerAdded:Connect(bind)
for _,player in Players:GetPlayers() do bind(player) end

