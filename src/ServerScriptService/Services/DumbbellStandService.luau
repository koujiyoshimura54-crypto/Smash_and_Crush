-- The existing server monitor owns stand entrances; authored exhibits stay fixed.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellStandConfig"))
local M = {}
local entries = setmetatable({}, {__mode = "k"})
local started = false

local function standing(player)
 if player.Parent ~= Players or (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return nil end
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 local root = character and character:FindFirstChild("HumanoidRootPart")
 if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
 return Config.GetStandingIndex(workspace:FindFirstChild(Config.FolderName), root.Position)
end

function M.Start(onEntry)
 if started then return end
 started = true
 local elapsed = 0
 RunService.Heartbeat:Connect(function(dt)
  elapsed += dt
  if elapsed < Config.PollSeconds then return end
  elapsed = 0
  for _, player in ipairs(Players:GetPlayers()) do
   local state = entries[player]
   if not state then state = {}; entries[player] = state end
   Config.AdvanceEntry(state, player.Character, standing(player))
   if not state.Index or state.Consumed then continue end
   state.Consumed = true
   local ok, consumed = pcall(onEntry, player, Config.GetItemId(state.Index))
   -- Unloaded or temporarily busy data can become ready while still on the pad.
   if ok and consumed == false then state.Consumed = false
   elseif not ok then warn("[DumbbellStand] Entry failed: " .. tostring(consumed)) end
  end
 end)
 Players.PlayerRemoving:Connect(function(player) entries[player] = nil end)
end

return M
