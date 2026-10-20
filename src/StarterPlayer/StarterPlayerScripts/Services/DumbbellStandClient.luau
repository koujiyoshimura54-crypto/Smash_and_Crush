-- Local presentation only; the existing server monitor owns stepping and purchases.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Config = require(RS.Config:WaitForChild("DumbbellStandConfig"))
local Master = require(RS.Config:WaitForChild("DumbbellItemMaster"))
local NumberFormat = require(RS.Modules.NumberFormat)
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
 local owned = {}
 local loaded = false
 local equipped = Player:GetAttribute("EquippedDumbbell") or ""
 local function renderWorld(worldId)
  local folder = Config.GetFolder(worldId)
  if not folder then return end
  for _, item in ipairs(Master.GetSorted(worldId)) do
   local index = item.Grade
   local model = folder:FindFirstChild(tostring(index))
   local board = model and model:FindFirstChild("BillboardGui")
   local itemId = item.ItemId
   local press = Config.GetPress(folder, index,worldId)
   if press then
    if not originals[press] then originals[press] = press.Color end
    press.Color = equipped == itemId and require(RS.Modules.InventoryPresentation).EquippedColor or originals[press]
   end
   if not board then continue end
   if press then board.Adornee = press end
   local amount = board:FindFirstChild("Amount")
   setPair(amount, "Main", NumberFormat.Price(item.PriceWin))
   setPair(board, "Price", "+" .. tostring(item.StrengthBonus) .. " Strength")
   local itemIcon = board:FindFirstChild("ItemIcon")
   if itemIcon and itemIcon:IsA("ImageLabel") then itemIcon.Image = item.Image end
   setPair(board, "Status", equipped == itemId and "Equipped"
    or (loaded and (owned[itemId] and "Owned" or "Step to buy") or ""))
   for _,name in {"Status","StatusShadow"}do local label=board:FindFirstChild(name);if label then require(RS.Modules.InventoryPresentation).LocalizeEquipmentLabel(label)end end
   local icon = amount and amount:FindFirstChild("Icon")
   if icon and icon:IsA("ImageLabel") then
    icon.Image = WinIcon
    icon.Visible = true
   end
  end
 end
 local function render() renderWorld(1);renderWorld(2) end
 -- Read-only state presentation; purchase/equip remains server-detected on entry.
 local remotes = RS:WaitForChild("Remotes")
 local stateRemote = remotes:WaitForChild("DumbbellInventoryState")
 local revision = 0
 local function applyState(state)
  if typeof(state) ~= "table" or not state.Loaded then return end
  owned = state.OwnedDumbbells or {}
  equipped = state.EquippedDumbbell or ""
  loaded = true
  render()
 end
 local function reply(result)
  if typeof(result) ~= "table" then return end
  revision += 1
  applyState(result.State)
 end
 remotes:WaitForChild("DumbbellPurchaseRequest").OnClientEvent:Connect(reply)
 remotes:WaitForChild("DumbbellEquipRequest").OnClientEvent:Connect(reply)
 Player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(function()
  equipped = Player:GetAttribute("EquippedDumbbell") or ""
  render()
 end)
 local function bind(folder)
  folder.DescendantAdded:Connect(render)
  render()
 end
 workspace.ChildAdded:Connect(function(child) if child.Name == Config.FolderName then bind(child) end end)
 for worldId=1,2 do local folder=Config.GetFolder(worldId);if folder then bind(folder) end end
 workspace.DescendantAdded:Connect(function(child) if child==Config.GetFolder(2) then bind(child) end end)
 render()
 task.spawn(function()
  while Player.Parent and not loaded do
   local before = revision
   local ok, state = pcall(function() return stateRemote:InvokeServer() end)
   if ok and before == revision then applyState(state) end
   if not loaded then task.wait(1) end
  end
 end)
end

return M
