-- Purchased PerStep Press geometry; prices/equipment belong to DumbbellItemMaster.
local Master = require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))
local M = {}
M.FolderName = "PerStepButtons"
M.Source = "DumbbellStand"
M.PollSeconds = 0.1
M.StandReach = 6

function M.GetItemId(index)
 if typeof(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #Master.GetSorted() then return nil end
 local itemId = string.format("NORMAL_%02d", index)
 return Master.Get(itemId) and itemId or nil
end

function M.GetPress(folder, index)
 if not M.GetItemId(index) or not folder then return nil end
 local model = folder:FindFirstChild(tostring(index))
 local press = model and model:IsA("Model") and model:FindFirstChild("Press")
 return press and press:IsA("BasePart") and press or nil
end

-- Same oriented footprint and vertical reach as purchased MultiplierServer.
-- Resolve CFrame on every check, so later manual moves never leave a stale zone.
function M.IsInside(press, position)
 if not press then return false end
 local offset = press.CFrame:PointToObjectSpace(position)
 local half = press.Size / 2
 return math.abs(offset.X) <= half.X and math.abs(offset.Z) <= half.Z
  and offset.Y >= -half.Y and offset.Y <= half.Y + M.StandReach
end

function M.GetStandingIndex(folder, position)
 for _, item in ipairs(Master.GetSorted()) do
  local index = item.Grade
  if M.IsInside(M.GetPress(folder, index), position) then return index end
 end
 return nil
end

-- Server entry latch: reset on exit, another stand or a changed character.
function M.AdvanceEntry(state, character, index)
 local entered = index ~= nil and (state.Character ~= character or state.Index ~= index)
 if state.Character ~= character or state.Index ~= index then
  state.Character = character
  state.Index = index
  state.Consumed = false
 end
 return entered
end

return table.freeze(M)
