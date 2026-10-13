-- Purchased PerStep Press geometry; prices/equipment belong to DumbbellItemMaster.
local M = {}
M.FolderName = "PerStepButtons"
M.DisplayFolderName = "ShoesModels"
M.Source = "DumbbellStand"
M.PollSeconds = 0.1
M.RequestTimeout = 10
M.SyncWaitSeconds = 1
M.SyncPollSeconds = 0.05
M.StandReach = 6
-- Three-times exhibit: 3.3-stud height, resting 0.05 above purchased Press top.
M.DisplayOffset = CFrame.new(0, 2.38442, 0) * CFrame.Angles(0, math.pi / 2, 0)

function M.GetItemId(index)
 if typeof(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 7 then return nil end
 return string.format("NORMAL_%02d", index)
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
 for index = 1, 7 do
  if M.IsInside(M.GetPress(folder, index), position) then return index end
 end
 return nil
end

-- Shared entry latch. Entering another pad while awaiting a reply still records
-- that entrance; it must be exited before another automatic operation is allowed.
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
