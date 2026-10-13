-- Isolated geometry/entry validation, not the purchased Multiplier/Data gameplay.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Config:WaitForChild("DumbbellStandConfig"))
local Master = require(RS.Config:WaitForChild("DumbbellItemMaster"))
local Lobby = require(script.Parent:WaitForChild("TrainingLobbyAreaService"))
local M = {}
local entries = setmetatable({}, {__mode = "k"})
local started = false

local function standing(player)
 if (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return nil end
 if not Lobby.IsInTrainingLobby(player) then return nil end
 local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return nil end
 return Config.GetStandingIndex(workspace:FindFirstChild(Config.FolderName), root.Position)
end

local function snapshot(player)
 local state = entries[player]
 if not state then state = {}; entries[player] = state end
 Config.AdvanceEntry(state, player.Character, standing(player))
 return state
end

function M.Validate(player, itemId, context)
 if typeof(context) ~= "table" or context.Source ~= Config.Source
  or typeof(context.RequestId) ~= "string" or #context.RequestId < 1 or #context.RequestId > 64 then
  return false, "InvalidStandRequest"
 end
 local index = context.StandIndex
 if Config.GetItemId(index) ~= itemId or not Master.Get(itemId) then return false, "InvalidStand" end
 if (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return false, "WrongWorld" end
 local state = snapshot(player)
 if state.Index ~= index then return false, "StandOutOfRange" end
 if state.Consumed then return false, "StandReentryRequired" end
 state.Consumed = true
 return true
end

local function reconcileDisplays()
 local folder = workspace:FindFirstChild(Config.FolderName)
 local displays = workspace:FindFirstChild(Config.DisplayFolderName)
 if not folder or not displays then return end
 for index = 1, 7 do
  local press = Config.GetPress(folder, index)
  local display = displays:FindFirstChild(tostring(index))
  if press and display and display:IsA("Model") and display:FindFirstChild("Bar") then
   local target = press.CFrame * Config.DisplayOffset
   if display:GetPivot() ~= target then display:PivotTo(target) end
  end
 end
end

function M.Start()
 if started then return end
 started = true
 reconcileDisplays()
 local elapsed = 0
 RunService.Heartbeat:Connect(function(dt)
  elapsed += dt
  if elapsed < Config.PollSeconds then return end
  elapsed = 0
  for _, player in ipairs(Players:GetPlayers()) do snapshot(player) end
  reconcileDisplays()
 end)
 Players.PlayerRemoving:Connect(function(player) entries[player] = nil end)
end

return M
