local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local remote = RS:WaitForChild("Remotes"):WaitForChild("RunReturn")
local HUDLayout = require(RS.Modules:WaitForChild("HUDLayout"))
local menu = gui:WaitForChild("LeftMenu")
local hud = gui:WaitForChild("HUD")
local combat = RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local style = gui.StrengthLevelHUD.LevelPanel.Level
local button = Instance.new("TextButton")
button.Name = "RunReturnButton"
button.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
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
button.Visible = false
button.Parent = hud
local pending, failed = nil, false
local defeated, unlocked = {}, {}
local humanoid, healthConnection
local initialized, waitingForProgress, inLobby = false, false, true
local function render()
	local busy = pending ~= nil or player:GetAttribute("RunReturnBusy") == true
	local visible = (player:GetAttribute("CurrentWorld") or 1) == 1
		and player:GetAttribute("RunInventoryActive") == true
		and initialized and not inLobby and not waitingForProgress
		and unlocked[player:GetAttribute("CurrentStage") or 1] == true
		and not defeated[player:GetAttribute("CurrentStage") or 1]
		and humanoid ~= nil and humanoid.Health > 0 and not busy
	button.Visible = visible
	button.Active = not busy
	button.AutoButtonColor = not busy
	button.Text = busy and "保存中…" or (failed and "失敗\n再試行" or "戻る")
end
button.Activated:Connect(function()
	if not button.Visible or pending or player:GetAttribute("RunReturnBusy") then return end
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
for _, attribute in {"CurrentWorld", "CurrentStage", "RunInventoryActive", "RunReturnBusy"} do
	player:GetAttributeChangedSignal(attribute):Connect(render)
end
player:GetAttributeChangedSignal("RunInventoryId"):Connect(function()
	initialized = false
	table.clear(unlocked)
	pending = nil
	failed = false
	render()
	-- Reconcile after a new RunId even if attributes and remotes arrive separately.
	combat:FireServer({Type = "RequestState"})
end)
-- Read the existing combat snapshot; no ownership or Return state is mutated.
combat.OnClientEvent:Connect(function(data)
	if typeof(data) ~= "table" then return end
	if data.Type == "Initialize" then
		table.clear(defeated)
		table.clear(unlocked)
		for stage, cleared in data.Cleared or {} do
			if cleared then defeated[stage] = true end
		end
		for stage, skipped in data.Skipped or {} do
			if skipped then defeated[stage] = true end
		end
		initialized, waitingForProgress = true, false
	elseif data.Type == "WallInitialize" or data.Type == "WallCleared" then
		local state = data.State
		if typeof(state) ~= "table" or typeof(state.MajorStage) ~= "number" then return end
		unlocked[state.MajorStage] = state.Skipped ~= true and (state.Current or 1) >= 5
	elseif data.Type == "Stage1BossUnlocked" then
		if typeof(data.MajorStage) ~= "number" then return end
		unlocked[data.MajorStage] = true
	elseif data.Type == "EnemyDefeated" then
		defeated[data.Stage] = true
		waitingForProgress = true
	elseif data.Type == "StageCleared" then
		waitingForProgress = false
	else
		return
	end
	render()
end)
-- Character health gates presentation immediately, including death before respawn.
local function bindCharacter(character)
	if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
	humanoid = nil
	render()
	local hum = character:WaitForChild("Humanoid", 10)
	if player.Character ~= character or not hum then return end
	humanoid = hum
	healthConnection = hum.HealthChanged:Connect(render)
	render()
end
player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function()
	if healthConnection then healthConnection:Disconnect(); healthConnection = nil end
	humanoid = nil
	initialized = false
	table.clear(unlocked)
	render()
end)
if player.Character then task.spawn(bindCharacter, player.Character) end
-- RunActive also covers the training lobby. Check its existing floor footprint
-- only for presentation, without adding server state or changing Run logic.
local elapsed = 0
local connection = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < .2 then return end
	elapsed = 0
	local map = workspace:FindFirstChild("GeneratedMap")
	local area = map and map:FindFirstChild("TrainingArea")
	local floor = area and area:FindFirstChild("Floor")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local lobby = true
	if floor and root then
		local pos = floor.CFrame:PointToObjectSpace(root.Position)
		lobby = math.abs(pos.X) <= floor.Size.X / 2 and math.abs(pos.Z) <= floor.Size.Z / 2
	end
	if lobby ~= inLobby then inLobby = lobby; render() end
end)
script.Destroying:Once(function()
	connection:Disconnect()
	if healthConnection then healthConnection:Disconnect() end
end)
render()
HUDLayout.Mount(gui).Refresh()
combat:FireServer({Type = "RequestState"})
