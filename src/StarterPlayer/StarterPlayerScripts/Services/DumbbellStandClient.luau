-- Purchased world billboards and Press entry; old-Smash Remotes remain the owner.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Config = require(RS.Config:WaitForChild("DumbbellStandConfig"))
local Master = require(RS.Config:WaitForChild("DumbbellItemMaster"))
local Notify = require(script.Parent:WaitForChild("NotifyClient"))
local WinIcon = game:GetService("StarterGui").StrengthGui.HUD.WinAmount.Inside.Icon.Image
local M = {}
local started = false

local function setPair(root, name, text)
 for _, suffix in ipairs({"", "Shadow"}) do
  local label = root and root:FindFirstChild(name .. suffix)
  if label and label:IsA("TextLabel") then
   label.AutoLocalize = false
   label.Text = text
  end
 end
end

local function failure(code, itemId)
 local item = Master.Get(itemId)
 if code == "NotEnoughWin" then return "NOT ENOUGH WIN! Need " .. tostring(item and item.PriceWin or 0) .. " Win" end
 if code == "DataNotLoaded" then return "PLEASE WAIT... Inventory is loading" end
 if code == "DataSaving" then return "PLEASE WAIT... Data is saving" end
 if code == "InventorySavePending" then return "PLEASE WAIT... Saving previous reward" end
 if code == "RateLimited" or code == "PurchaseInProgress" then return "PLEASE WAIT... Step off and try again" end
 if code == "StandReentryRequired" then return "Step off the stand before trying again" end
 if code == "RequestTimeout" then return "Request not confirmed. Step off and try again" end
 if code == "StandOutOfRange" or code == "WrongWorld" then return "Stand unavailable. Step off and try again" end
 return "Dumbbell request failed: " .. tostring(code or "Unknown")
end

local function notify(text)
 -- PetClient.bootstrap already starts the actual purchased notification system.
 -- Do not create a second NotifyGui or start the purchased Main.
 task.spawn(function()
  local deadline = os.clock() + Config.RequestTimeout
  while not Notify.ready() and os.clock() < deadline do task.wait(0.1) end
  if Notify.ready() then Notify.push({{text = text}})
  else warn("[DumbbellStand] " .. text) end
 end)
end

function M.start()
 if started then return end
 started = true
 local remotes = RS:WaitForChild("Remotes")
 local purchase = remotes:WaitForChild("DumbbellPurchaseRequest")
 local equip = remotes:WaitForChild("DumbbellEquipRequest")
 local stateRemote = remotes:WaitForChild("DumbbellInventoryState")
 local state = {Loaded = false, OwnedDumbbells = {}, EquippedDumbbell = ""}
 local entry = {}
 local pending
 local refreshing = false
 local originals = setmetatable({}, {__mode = "k"})
 local function render()
  local folder = workspace:FindFirstChild(Config.FolderName)
  if not folder then return end
  for index = 1, 12 do
   local model = folder:FindFirstChild(tostring(index))
   local board = model and model:FindFirstChild("BillboardGui")
   if not board then continue end
   local itemId = Config.GetItemId(index)
   local item = itemId and Master.Get(itemId)
   if not item then
    setPair(board, "Price", "")
    setPair(board:FindFirstChild("Amount"), "Main", "")
    local amount = board:FindFirstChild("Amount")
    local icon = amount and amount:FindFirstChild("Icon")
    if icon and icon:IsA("ImageLabel") then icon.Visible = false end
    continue
   end
   local press = Config.GetPress(folder, index)
   if press then
    board.Adornee = press
    if not originals[press] then originals[press] = press.Color end
    press.Color = state.EquippedDumbbell == itemId and Color3.fromRGB(255,255,0)
     or (state.OwnedDumbbells[itemId] == true and Color3.fromRGB(0,200,0) or originals[press])
   end
   local amount = board:FindFirstChild("Amount")
   -- Keep the purchased two-row board; never add a separate description panel.
   setPair(amount, "Main", tostring(item.PriceWin))
   local icon = amount and amount:FindFirstChild("Icon")
   if icon and icon:IsA("ImageLabel") then icon.Image = WinIcon; icon.Visible = true end
   setPair(board, "Price", "+" .. tostring(item.StrengthBonus))
  end
 end
 local function applyState(value)
  if typeof(value) ~= "table" or value.Loaded ~= true or typeof(value.OwnedDumbbells) ~= "table" then return false end
  state = value
  render()
  return true
 end
 local function refresh()
  if refreshing then return end
  refreshing = true
  task.spawn(function()
   local ok, value = pcall(function() return stateRemote:InvokeServer() end)
   refreshing = false
   if ok then applyState(value) else warn("[DumbbellStand] State lookup failed: " .. tostring(value)) end
  end)
 end
 local function response(result)
  if typeof(result) ~= "table" then return end
  applyState(result.State) -- Inventory operations update the same world billboards.
  if result.Source ~= Config.Source then return end
  if not pending or result.RequestId ~= pending.RequestId then return end
  local itemId = pending.ItemId
  pending = nil
  if result.Success == false then notify(failure(result.Code, itemId)) end
  render()
 end
 purchase.OnClientEvent:Connect(response)
 equip.OnClientEvent:Connect(response)
 Player:GetAttributeChangedSignal("EquippedDumbbell"):Connect(refresh)
 Player:GetAttributeChangedSignal("Win"):Connect(refresh)
 Player.CharacterAdded:Connect(refresh)
 refresh()
 render()
 local elapsed, retry = 0, 0
 RunService.Heartbeat:Connect(function(dt)
  elapsed += dt
  retry += dt
  if elapsed < Config.PollSeconds then return end
  elapsed = 0
  local folder = workspace:FindFirstChild(Config.FolderName)
  local character = Player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local index
  if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")
   and (Player:GetAttribute("CurrentWorld") or 1) == 1 then
   index = Config.GetStandingIndex(folder, root.Position)
  end
  local entered = Config.AdvanceEntry(entry, character, index)
  if not state.Loaded and retry >= 1 then retry = 0; refresh() end
  if not entered or pending then return end
  local itemId = Config.GetItemId(index)
  if state.Loaded and state.EquippedDumbbell == itemId then return end
  if not state.Loaded then notify(failure("DataNotLoaded", itemId)); return end
  local requestId = HttpService:GenerateGUID(false)
  pending = {RequestId = requestId, ItemId = itemId}
  render()
  local context = {Source = Config.Source, StandIndex = index, RequestId = requestId}
  local target = state.OwnedDumbbells[itemId] == true and equip or purchase
  local ok, err = pcall(function() target:FireServer(itemId, context) end)
  if not ok then
   pending = nil
   warn("[DumbbellStand] Request failed: " .. tostring(err))
   notify(failure("RequestTimeout", itemId))
   render()
   return
  end
  task.delay(Config.RequestTimeout, function()
   if pending and pending.RequestId == requestId then
    pending = nil
    notify(failure("RequestTimeout", itemId))
    refresh()
    render()
   end
  end)
 end)
end

return M
