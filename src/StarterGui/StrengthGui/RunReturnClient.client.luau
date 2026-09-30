local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = script.Parent
local remote = RS:WaitForChild("Remotes"):WaitForChild("RunReturn")
local HUDLayout = require(RS.Modules:WaitForChild("HUDLayout"))
local menu = gui:WaitForChild("LeftMenu")
local left = gui:WaitForChild("HUD"):WaitForChild("LeftHUD")
local style = gui.StrengthLevelHUD.LevelPanel.Level
local slot = Instance.new("Frame")
slot.Name = "RunReturnButton"
slot.BackgroundTransparency = 1
slot.LayoutOrder = 6
slot:SetAttribute("DesignSize", Vector2.new(144, 144))
slot.Parent = left
local button = Instance.new("TextButton")
button.Name = "RunReturnButton"
button.BackgroundColor3 = Color3.fromRGB(55, 128, 180)
button.BorderSizePixel = 0
button.FontFace = style.FontFace
button.TextColor3 = style.TextColor3
button.TextSize = 32
button.TextWrapped = true
button.AutoLocalize = false
button.ZIndex = menu.InventoryButton.ZIndex
button.Text = "戻る"
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = button
local border = Instance.new("UIStroke")
border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
border.Color = Color3.fromRGB(20, 35, 60)
border.Thickness = 3
border.Parent = button
local outline = style:FindFirstChild("TextOutline")
if outline then outline:Clone().Parent = button end
button.Parent = menu
local pending, failed = nil, false
local function render()
	local visible = (player:GetAttribute("CurrentWorld") or 1) == 1
		and player:GetAttribute("RunInventoryActive") == true
	local busy = pending ~= nil or player:GetAttribute("RunReturnBusy") == true
	slot.Visible = visible
	button.Visible = visible
	button.Active = not busy
	button.AutoButtonColor = not busy
	button.Text = busy and "保存中…" or (failed and "失敗\n再試行" or "戻る")
end
button.Activated:Connect(function()
	if pending or player:GetAttribute("RunReturnBusy") then return end
	local id = player:GetAttribute("RunInventoryId")
	if typeof(id) ~= "string" then return end
	pending = id
	failed = false
	render()
	remote:FireServer(id)
end)
remote.OnClientEvent:Connect(function(id, success, code)
	if id ~= pending then return end
	pending = nil
	failed = not success and code ~= "StaleRun"
	render()
end)
for _, attribute in {"CurrentWorld", "RunInventoryActive", "RunReturnBusy"} do
	player:GetAttributeChangedSignal(attribute):Connect(render)
end
player:GetAttributeChangedSignal("RunInventoryId"):Connect(function()
	pending = nil
	failed = false
	render()
end)
render()
HUDLayout.Mount(gui).Refresh()
