-- Capacity presentation only; the server owns price validation and persistence.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local Responsive = require(RS.Modules:WaitForChild("ResponsivePanels"))
local Config = require(RS.Config:WaitForChild("InventoryCapacityPreviewConfig"))
local Upgrades = require(RS.Config:WaitForChild("InventoryCapacityConfig"))
local remote = RS:WaitForChild("Remotes"):WaitForChild("PurchaseInventoryCapacity")
local shop = gui:WaitForChild("ShopPanel")
local shopCard = shop.MainScrollingFrame.Holder.CardWin
local font = shop.Top.ShopText1.FontFace
local black = Color3.fromRGB(12, 14, 20)
local connections = {}
local function connect(signal, callback)
	table.insert(connections, signal:Connect(callback))
end
local function frame(name, parent, pos, size, color, z)
	local x = Instance.new("Frame")
	x.Name = name; x.Position = pos; x.Size = size
	x.BackgroundColor3 = color; x.BorderSizePixel = 0; x.ZIndex = z; x.Parent = parent
	return x
end
local function border(x, color, thickness, radius)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color; stroke.Thickness = thickness; stroke.Parent = x
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius); corner.Parent = x
end
local function label(name, parent, value, pos, size, textSize, color)
	local x = Instance.new("TextLabel")
	x.Name = name; x.Text = value; x.Position = pos; x.Size = size
	x.BackgroundTransparency = 1; x.FontFace = font; x.TextSize = textSize
	x.TextColor3 = color or Color3.new(1, 1, 1); x.TextScaled = true
	x.AutoLocalize = false; x.ZIndex = parent.ZIndex + 2; x.Parent = parent
	local outline = Instance.new("UIStroke")
	outline.Color = black; outline.Thickness = 3; outline.Parent = x
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 16; limit.MaxTextSize = textSize; limit.Parent = x
	return x
end
local function icon(name, parent, image, pos, size)
	local x = Instance.new("ImageLabel")
	x.Name = name; x.Image = image; x.BackgroundTransparency = 1
	x.Position = pos; x.Size = size; x.ScaleType = Enum.ScaleType.Fit
	x.ZIndex = parent.ZIndex + 2; x.Parent = parent
	return x
end
local panel = frame("InventoryCapacityUpgradePanel", gui, UDim2.new(),
	UDim2.fromOffset(Config.DesignSize.X, Config.DesignSize.Y), shop.BackgroundColor3, 60)
panel.Visible = false
panel:SetAttribute("ResponsiveDesignSize", Config.DesignSize)
border(panel, black, 7, 16)
local background = shopCard.StudPattern:Clone()
background.Name = "StudPattern"; background.AnchorPoint = Vector2.zero
background.Position = UDim2.new(); background.Size = UDim2.fromScale(1, 1)
background.ImageTransparency = .87; background.ZIndex = 61; background.Parent = panel

-- Clone only the authored Shop header; no product logic or title icon.
local top = shop.Top:Clone()
top.AnchorPoint = Vector2.zero; top.Position = UDim2.new(); top.Size = UDim2.new(1, 0, 0, 100)
top.ZIndex = 63
local titleIcon = top:FindFirstChild("MainShopIcon")
if titleIcon then titleIcon:Destroy() end
for _,d in top:GetDescendants() do
	if d:IsA("GuiObject") then d.ZIndex += 60 end
	if d:IsA("LuaSourceContainer") then d:Destroy() end
end
for _,name in {"ShopText1", "ShopText2"} do
	local text = top[name]
	text.Text = "UpGrade"; text.AutoLocalize = false; text.TextScaled = true
	text.AnchorPoint = Vector2.zero; text.Position = UDim2.fromOffset(28, name == "ShopText1" and 12 or 15)
	text.Size = UDim2.new(1, -144, 0, 76); text.TextXAlignment = Enum.TextXAlignment.Left
end
local close = top.Close
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 16)
close.Size = UDim2.fromOffset(68, 68); close.Text = ""; close.AutoLocalize = false
top.Parent = panel

local card = frame("InventoryCapacity", panel, UDim2.fromOffset(24, 124),
	UDim2.new(1, -48, 0, 270), Color3.fromRGB(65, 69, 77), 63)
border(card, Color3.fromRGB(228, 231, 239), 4, 14)
local pattern = shopCard.StudPattern:Clone()
pattern.Position = UDim2.new(); pattern.AnchorPoint = Vector2.zero; pattern.Size = UDim2.fromScale(1, 1)
pattern.ImageTransparency = .87; pattern.ZIndex = 64; pattern.Parent = card
local iconBox = frame("IconBox", card, UDim2.fromOffset(20, 34), UDim2.fromOffset(196, 196),
	Color3.fromRGB(114, 116, 121), 65)
border(iconBox, black, 6, 12)
icon("BagIcon", iconBox, gui.LeftMenu.InventoryButton.Icon.Image,
	UDim2.fromOffset(10, 10), UDim2.new(1, -20, 1, -20))
label("Label", card, "Inventory Capacity", UDim2.fromOffset(240, 22), UDim2.new(1, -262, 0, 60), 48)
local current = label("CurrentCapacity", card, "-", UDim2.fromOffset(242, 114), UDim2.fromOffset(112, 94), 72)
label("Arrow", card, ">>>", UDim2.fromOffset(362, 126), UDim2.fromOffset(132, 68), 48)
local nextValue = label("NextCapacity", card, "-", UDim2.fromOffset(500, 114), UDim2.fromOffset(112, 94),
	72, Color3.fromRGB(53, 255, 68))

local purchase = Instance.new("TextButton")
purchase.Name = "Purchase"; purchase.Text = ""; purchase.AutoLocalize = false
purchase.BackgroundColor3 = Color3.fromRGB(45, 230, 43); purchase.BorderSizePixel = 0
purchase.Position = UDim2.fromOffset(648, 132); purchase.Size = UDim2.fromOffset(278, 106)
purchase.ZIndex = 65; purchase.Parent = card
border(purchase, Color3.fromRGB(11, 43, 9), 6, 12)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(128, 255, 60), Color3.fromRGB(9, 179, 22))
gradient.Rotation = 90; gradient.Parent = purchase
icon("TrophyIcon", purchase, gui.WinLabel.TrophyIcon.Image, UDim2.fromOffset(8, 13), UDim2.fromOffset(76, 80))
local price = label("Price", purchase, "", UDim2.fromOffset(88, 15), UDim2.new(1, -98, 1, -30), 54)
local status = label("PurchaseFeedback", panel, "", UDim2.fromOffset(24, 410), UDim2.new(1, -48, 0, 44), 30)
local purchasing = false
local requestedCapacity
local function refresh()
	local capacity = player:GetAttribute("RunInventoryCapacity")
	local tier = Upgrades.Upgrades[capacity]
	current.Text = typeof(capacity) == "number" and tostring(capacity) or "-"
	nextValue.Text = tier and tostring(tier.NextCapacity) or "MAX"
	price.Text = tier and require(RS.Modules.NumberFormat).Format(tier.PriceWin) or "MAX"
	purchase.TrophyIcon.Visible = tier ~= nil
	purchase.Active = tier ~= nil and not purchasing
	purchase.AutoButtonColor = purchase.Active
	gradient.Enabled = tier ~= nil
	purchase.BackgroundColor3 = tier and Color3.fromRGB(45, 230, 43) or Color3.fromRGB(110, 116, 120)
end
connect(player:GetAttributeChangedSignal("RunInventoryCapacity"), refresh)
Responsive.ConnectActivation(purchase, function()
	if not panel.Visible or purchasing then return end
	local capacity = player:GetAttribute("RunInventoryCapacity")
	if not Upgrades.Upgrades[capacity] then return end
	purchasing = true
	requestedCapacity = capacity
	status.Text = "Saving..."
	refresh()
	remote:FireServer(capacity)
end)
connect(remote.OnClientEvent, function(success, code)
	purchasing = false
	local messages = {
		NotEnoughWin = "Not enough Win", InventorySavePending = "Save pending. Please retry.",
		DataSaving = "Please try again", DataNotLoaded = "Loading...", MaxCapacity = "MAX",
		CapacityChanged = "Capacity updated", SessionOwnershipLost = "Please rejoin",
	}
	status.Text = success and "Upgraded!" or messages[code] or "Purchase failed. Please retry."
	refresh()
end)
connect(player:GetAttributeChangedSignal("InventoryCapacityPurchasePending"), function()
	if player:GetAttribute("InventoryCapacityPurchasePending") == false then
		purchasing = false
		if requestedCapacity and (player:GetAttribute("InventoryCapacity") or 0) > requestedCapacity then
			status.Text = "Upgraded!"
		end
		refresh()
	end
end)
local inside, dismissed = false, false
Responsive.ConnectActivation(close, function() panel.Visible = false; dismissed = true end)
local trigger, stall
local function attachStall()
	local found = workspace:FindFirstChild("ShopStallTemplate")
	if found == stall and trigger and trigger.Parent then return end
	if trigger then trigger:Destroy(); trigger = nil end
	stall = found
	if not stall or not stall:IsA("Model") then return end
	trigger = Instance.new("Part")
	trigger.Name = "InventoryCapacityTrigger"; trigger.Size = Config.TriggerSize
	trigger.CFrame = stall:GetPivot() * Config.TriggerOffset
	trigger.Anchored = true; trigger.Transparency = 1
	trigger.CanCollide = false; trigger.CanTouch = false; trigger.CanQuery = false
	trigger.Parent = stall
end
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
	elapsed += dt; if elapsed < .15 then return end; elapsed = 0
	attachStall()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local near = false
	if trigger and root and hum and hum.Health > 0 and (player:GetAttribute("CurrentWorld") or 1) == 1 then
		local p = trigger.CFrame:PointToObjectSpace(root.Position)
		local h = trigger.Size / 2
		near = math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
	end
	if not near then panel.Visible = false; dismissed = false
	elseif not inside and not dismissed then
		-- Leave every existing shop/panel state intact; skip while one is open.
		local otherOpen = false
		for _,name in {"ShopPanel", "InventoryPanel", "MergePanel", "RebirthPanel", "DailyRewardsPanel", "TimeRewardsPanel", "CommunityRewardsPanel"} do
			local other = gui:FindFirstChild(name)
			if other and other.Visible then otherOpen = true; break end
		end
		if not otherOpen then status.Text = ""; refresh(); panel.Visible = true end
	end
	inside = near
	if panel.Visible then Responsive.Fit(panel, gui) end
end)
script.Destroying:Once(function()
	for _,c in connections do c:Disconnect() end
	if trigger then trigger:Destroy() end
	panel:Destroy()
end)
refresh()
