-- Local presentation only; the existing server monitor owns stepping and purchases.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Config = require(RS.Config:WaitForChild("DumbbellStandConfig"))
local Master = require(RS.Config:WaitForChild("DumbbellItemMaster"))
local WinIcon = game:GetService("StarterGui").StrengthGui.HUD.WinAmount.Inside.Icon.Image
local M = {}
local started = false
local function setPair(root, name, text)
 for _, suffix in ipairs({"", "Shadow"}) do
  local label = root and root:FindFirstChild(name .. suffix)
  if label and label:IsA("TextLabel") then label.AutoLocalize = false; label.Text = text end
 end
end

function M.start()
 if started then return end
 started = true
 local originals = {}
 local function render()
  local folder = workspace:FindFirstChild(Config.FolderName)
  if not folder then return end
  local equipped = Player:GetAttribute("EquippedDumbbell") or ""
  for index = 1, 12 do
   local model = folder:FindFirstChild(tostring(index))
   local board = model and model:FindFirstChild("BillboardGui")
   local itemId = Config.GetItemId(index)
   local item = itemId and Master.Get(itemId)
   local press = Config.GetPress(folder, index)
   if press then
    if not originals[press] then originals[press] = press.Color end
    press.Color = equipped == itemId and Color3.fromRGB(0,200,0) or originals[press]
   end
   if not board then continue end
   if press then board.Adornee = press end
   local amount = board:FindFirstChild("Amount")
   setPair(amount, "Main", item and require(RS.Modules.NumberFormat).Price(item.PriceWin) or "")
   setPair(board, "Price", item and "+" .. tostring(item.StrengthBonus) or "")
   local icon = amount and amount:FindFirstChild("Icon")
   if icon and icon:IsA("ImageLabel") then
    if item then icon.Image = WinIcon end
    icon.Visible = item ~= nil and item ~= false
   end
  end
 end
 Player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(render)
 local function bind(folder)
  folder.DescendantAdded:Connect(render)
  render()
 end
 workspace.ChildAdded:Connect(function(child) if child.Name == Config.FolderName then bind(child) end end)
 local folder = workspace:FindFirstChild(Config.FolderName)
 if folder then bind(folder) else render() end
end

return M
