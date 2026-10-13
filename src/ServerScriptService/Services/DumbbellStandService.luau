-- Isolated geometry/entry validation, not the purchased Multiplier/Data gameplay.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(RS.Config:WaitForChild("DumbbellStandConfig"))
local Master = require(RS.Config:WaitForChild("DumbbellItemMaster"))
local M = {}
local entries = setmetatable({}, {__mode = "k"})
local started = false

local function standing(player)
 if (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return nil end
 local character = player.Character
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health <= 0 then return nil end
 local root = character and character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return nil end
 return Config.GetStandingIndex(workspace:FindFirstChild(Config.FolderName), root.Position)
end

local function snapshot(player)
 local state = entries[player]
 if not state then state = {}; entries[player] = state end
 Config.AdvanceEntry(state, player.Character, standing(player))
 return state
end

-- Rejection-only diagnostics. Client positions are evidence, never authorization.
local function vector(value)
 if typeof(value) ~= "Vector3" then return nil end
 for _, component in ipairs({value.X, value.Y, value.Z}) do
  if component ~= component or math.abs(component) == math.huge then return nil end
 end
 return {value.X, value.Y, value.Z}
end

local function reject(player, context, code, detected)
 local ok = pcall(function()
  local character = player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local position = root and root:IsA("BasePart") and root.Position or nil
  local folder = workspace:FindFirstChild(Config.FolderName)
  local index = context.StandIndex
  local press = Config.GetPress(folder, index)
  local matches = {}
  if position then
   for candidate = 1, 7 do
    if Config.IsInside(Config.GetPress(folder, candidate), position) then
     table.insert(matches, candidate)
    end
   end
  end
  local relative = press and position and press.CFrame:PointToObjectSpace(position)
  local half = press and press.Size / 2
  warn("[DumbbellStandReject] " .. HttpService:JSONEncode({
   Code = code,
   RequestId = context.RequestId,
   RequestedStandIndex = typeof(index) == "number" and index or nil,
   DetectedStandIndex = detected or 0,
   GeometricStandIndex = matches[1] or 0,
   InsideStandIndices = matches,
   CurrentWorldAttribute = player:GetAttribute("CurrentWorld") or "unset",
   CurrentWorld = player:GetAttribute("CurrentWorld") or 1,
   HasCharacter = character ~= nil,
   Health = humanoid and humanoid.Health or 0,
   HipHeight = humanoid and humanoid.HipHeight or nil,
   RootPosition = vector(position),
   RootSize = root and root:IsA("BasePart") and vector(root.Size) or nil,
   RelativeToPress = vector(relative),
   PressCFrame = press and {press.CFrame:GetComponents()} or nil,
   PressSize = press and vector(press.Size) or nil,
   Limits = half and {HalfX = half.X, HalfZ = half.Z, MinY = -half.Y, MaxY = half.Y + Config.StandReach} or nil,
   OutsideX = relative and math.abs(relative.X) > half.X or false,
   OutsideZ = relative and math.abs(relative.Z) > half.Z or false,
   OutsideY = relative and (relative.Y < -half.Y or relative.Y > half.Y + Config.StandReach) or false,
   ClientRootPosition = vector(context.ClientRootPosition),
   ClientRelativeToPress = vector(context.ClientRelativeToPress),
  }))
 end)
 if not ok then warn("[DumbbellStandReject] " .. code .. " (diagnostic unavailable)") end
 return false, code
end

function M.CheckRequest(itemId, context)
 if typeof(context) ~= "table" or context.Source ~= Config.Source
  or context.Action ~= nil or typeof(context.RequestId) ~= "string"
  or #context.RequestId < 1 or #context.RequestId > 64 then
  return false, "InvalidStandRequest"
 end
 local index = context.StandIndex
 if Config.GetItemId(index) ~= itemId or not Master.Get(itemId) then return false, "InvalidStand" end
 return true
end

function M.Validate(player, itemId, context)
 local valid, code = M.CheckRequest(itemId, context)
 if not valid then return false, code end
 local index = context.StandIndex
 if (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return reject(player, context, "WrongWorld", nil) end
 local state = snapshot(player)
 if state.Index ~= index then return reject(player, context, "StandOutOfRange", state.Index) end
 if state.Consumed then return false, "StandReentryRequired" end
 state.Consumed = true
 return true
end

-- One bounded server observation window; reported client coordinates never grant entry.
function M.AwaitEntry(player, itemId, context, operation, isCurrent)
 local valid, code = M.CheckRequest(itemId, context)
 if not valid then return false, code end
 local deadline = os.clock() + Config.SyncWaitSeconds
 while true do
  if operation.Cancelled or not isCurrent() or player.Parent ~= Players
   or player.Character ~= operation.Character then return false, "StandCancelled" end
  if (player:GetAttribute("CurrentWorld") or 1) ~= 1 then
   return reject(player, context, "WrongWorld", nil)
  end
  local character = player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
   return false, "StandCancelled"
  end
  local remaining = deadline - os.clock()
  if remaining <= 0 then return reject(player, context, "StandOutOfRange", standing(player)) end
  -- Read live Press geometry every time; a stale position on another pad may be replication lag.
  if Config.GetStandingIndex(workspace:FindFirstChild(Config.FolderName), root.Position) == context.StandIndex then
   return M.Validate(player, itemId, context)
  end
  task.wait(math.min(Config.SyncPollSeconds, remaining))
 end
end

function M.Start()
 if started then return end
 started = true
 local elapsed = 0
 RunService.Heartbeat:Connect(function(dt)
  elapsed += dt
  if elapsed < Config.PollSeconds then return end
  elapsed = 0
  for _, player in ipairs(Players:GetPlayers()) do snapshot(player) end
 end)
 Players.PlayerRemoving:Connect(function(player) entries[player] = nil end)
end

return M
