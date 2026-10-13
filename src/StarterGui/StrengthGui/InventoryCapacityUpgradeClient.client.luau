-- Capacity and sequential Speed presentation; existing server routes own all purchases.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
local Responsive = require(RS.Modules:WaitForChild("ResponsivePanels"))
local Config = require(RS.Config:WaitForChild("InventoryCapacityPreviewConfig"))
local Upgrades = require(RS.Config:WaitForChild("InventoryCapacityConfig"))
local SpeedConfig = require(RS.Config:WaitForChild("SpeedConfig"))
local speedRemote = RS:WaitForChild("Remotes"):WaitForChild("SpeedPurchaseRequest")
local speedStateRemote = RS.Remotes:WaitForChild("SpeedInventoryState")
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
-- Use the actual yellow Win artwork in this measured card rectangle. Do not
-- derive its aspect from CurrentCamera (Edit capture may report a 1x1 viewport).
local function bindWinButton(button, priceLabel)
 for _,d in button:GetDescendants() do
  if d:IsA("GuiObject") then d.Visible=false end
  if d:IsA("UIStroke") then d.Enabled=false end
 end
 button.BackgroundTransparency=1; button.TextTransparency=1
 local visual=game:GetService("StarterGui").ScreenGui.Menus.RestockShop.Main.Common.Buy:Clone()
 visual.Name="PurchasedButtonVisual"
 local input=visual:FindFirstChild("Button")
 if input then input:Destroy() end
 visual.AnchorPoint=Vector2.zero;visual.Position=UDim2.new()
 visual.Size=UDim2.fromScale(1,1);visual.Visible=true;visual.ZIndex=button.ZIndex
 for _,d in visual:GetDescendants() do
  if d:IsA("LuaSourceContainer") then d:Destroy()
  elseif d:IsA("GuiObject") then
   d.Active=false
   d.ZIndex=button.ZIndex+(d.Name=="Stroke" and 0 or d.Name=="Main" and 1 or 2)
  end
 end
 visual.Parent=button
 local function update()
  visual.Main.Amount.Text=priceLabel.Text
  visual.Main.Icon.Visible=priceLabel.Text:match("^%d")~=nil
 end
 connect(priceLabel:GetPropertyChangedSignal("Text"),update)
 update()
end
local panel = frame("InventoryCapacityUpgradePanel", gui, UDim2.new(),
	UDim2.fromOffset(Config.DesignSize.X, Config.DesignSize.Y), Color3.fromRGB(14, 19, 27), 60)
panel.BackgroundTransparency = .16
panel.Visible = false
panel:SetAttribute("ResponsiveDesignSize", Config.DesignSize)
border(panel, black, 7, 16)
-- Clone only the authored Shop header; no product logic or title icon.
local top = shop.Top:Clone()
top.AnchorPoint = Vector2.zero; top.Position = UDim2.new(); top.Size = UDim2.new(1, 0, 0, 132)
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
	text.Size = UDim2.new(1, -180, 0, 104); text.TextXAlignment = Enum.TextXAlignment.Left
end
local close = top.Close
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -16, 0, 16)
close.Size = UDim2.fromOffset(100, 100); close.Text = ""; close.AutoLocalize = false
top.Parent = panel

local card = frame("InventoryCapacity", panel, UDim2.fromOffset(34, 166),
	UDim2.new(1, -68, 0, 300), Color3.fromRGB(65, 69, 77), 63)
border(card, Color3.fromRGB(228, 231, 239), 4, 14)
local pattern = shopCard.StudPattern:Clone()
pattern.Position = UDim2.new(); pattern.AnchorPoint = Vector2.zero; pattern.Size = UDim2.fromScale(1, 1)
pattern.ImageTransparency = .87; pattern.ZIndex = 64; pattern.Parent = card
local iconBox = frame("IconBox", card, UDim2.fromOffset(30, 40), UDim2.fromOffset(256, 230),
	Color3.fromRGB(114, 116, 121), 65)
border(iconBox, black, 6, 12)
icon("BagIcon", iconBox, gui.LeftMenu.InventoryButton.Icon.Image,
	UDim2.fromOffset(10, 10), UDim2.new(1, -20, 1, -20))
label("Label", card, "Inventory Capacity", UDim2.fromOffset(320, 18), UDim2.new(1, -346, 0, 80), 64)
local current = label("CurrentCapacity", card, "-", UDim2.fromOffset(322, 138), UDim2.fromOffset(142, 94), 88)
label("Arrow", card, ">>>", UDim2.fromOffset(476, 148), UDim2.fromOffset(150, 76), 60)
local nextValue = label("NextCapacity", card, "-", UDim2.fromOffset(648, 138), UDim2.fromOffset(142, 94),
	88, Color3.fromRGB(53, 255, 68))

local purchase = Instance.new("TextButton")
purchase.Name = "Purchase"; purchase.Text = ""; purchase.AutoLocalize = false
purchase.BackgroundColor3 = Color3.fromRGB(45, 230, 43); purchase.BorderSizePixel = 0
purchase.Position = UDim2.fromOffset(892, 170); purchase.Size = UDim2.fromOffset(414, 96)
purchase.ZIndex = 65; purchase.Parent = card
border(purchase, Color3.fromRGB(11, 43, 9), 6, 12)
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(128, 255, 60), Color3.fromRGB(9, 179, 22))
gradient.Rotation = 90; gradient.Parent = purchase
icon("TrophyIcon", purchase, gui.WinLabel.TrophyIcon.Image, UDim2.fromOffset(8, 13), UDim2.fromOffset(76, 80))
local price = label("Price", purchase, "", UDim2.fromOffset(88, 15), UDim2.new(1, -98, 1, -30), 54)
local status = label("PurchaseFeedback", card, "", UDim2.fromOffset(320, 264), UDim2.new(1, -350, 0, 28), 26)
-- Clone the existing capacity card, including purchased Stud and Win visuals.
-- Capacity and Speed keep separate state, labels and server result streams.
local speedCard = card:Clone()
speedCard.Name = "Speed"; speedCard.Position = UDim2.fromOffset(34, 490); speedCard.Parent = panel
speedCard.Label.Text = "Speed"
speedCard.IconBox.BagIcon.Name = "SpeedIcon"
speedCard.IconBox.SpeedIcon.Image = "rbxassetid://"..tostring(SpeedConfig.Speed1.ImageAssetId)
local speedCurrent, speedNext = speedCard.CurrentCapacity, speedCard.NextCapacity
speedCurrent.Name = "CurrentSpeed"; speedNext.Name = "NextSpeed"
local speedBuy, speedPrice, speedStatus = speedCard.Purchase, speedCard.Purchase.Price, speedCard.PurchaseFeedback
bindWinButton(speedBuy,speedPrice)
local speedState = {Loaded=false}
local speedPurchasing, speedRequestStage = false, nil
local speedRefreshBusy, speedRevision = false, 0
local function refreshSpeed()
 local loaded = speedState.Loaded == true
 local premium = speedState.PremiumOwned == true
 local stage = speedState.UpgradeStage or 0
 local tier = loaded and SpeedConfig.Upgrades[stage]
 -- After a failed acknowledgement, retry the same expected stage through the
 -- server's durable gate. Do not strand the UI after automatic retries expire.
 local enabled = loaded and tier ~= nil and not premium and not speedPurchasing
 speedCurrent.Text = loaded and tostring(premium and speedState.WalkSpeed or speedState.UpgradeSpeed) or "-"
 speedNext.Text = not loaded and "-" or premium and "MAX" or tier and tostring(tier.NextSpeed) or "MAX"
 speedPrice.Text = not loaded and "..." or premium and "OWNED" or tier and tostring(tier.PriceWin) or "MAX"
 speedBuy.Active = enabled; speedBuy.Interactable = enabled; speedBuy.AutoButtonColor = enabled
 speedBuy.TrophyIcon.Visible = false -- The purchased visual owns the currency glyph.
 if speedState.UpgradePending then speedStatus.Text = speedPurchasing and "Saving..." or "Save pending. Please retry."
 elseif premium then speedStatus.Text = "Premium owned"
 elseif loaded and not tier then speedStatus.Text = "MAX" end
end
local function applySpeed(state)
 if typeof(state) ~= "table" or state.Loaded ~= true then return end
 speedState = state; speedRevision += 1
 if speedRequestStage and state.UpgradeStage > speedRequestStage then
  speedPurchasing = false; speedRequestStage = nil; speedStatus.Text = "Upgraded!"
 end
 refreshSpeed()
end
local function requestSpeedState()
 if speedRefreshBusy then return end
 speedRefreshBusy = true
 local revision = speedRevision
 task.spawn(function()
  local ok, state = pcall(function() return speedStateRemote:InvokeServer() end)
  speedRefreshBusy = false
  if ok and revision == speedRevision then applySpeed(state) end
 end)
end
local messages = {
 NotEnoughWin="Not enough Win", InventorySavePending="Save pending. Please retry.",
 DataSaving="Please try again", DataNotLoaded="Loading...", MaxCapacity="MAX", MaxSpeed="MAX",
 CapacityChanged="Capacity updated", SpeedStageChanged="Speed updated",
 SessionOwnershipLost="Please rejoin", PremiumOwned="Premium owned",
 Pending="Checking ownership. Please retry.", OwnershipUnavailable="Ownership unavailable. Please retry.",
 RequestInProgress="Please try again",
}
Responsive.ConnectActivation(speedBuy, function()
 if not panel.Visible or not speedBuy.Active or not speedBuy.Interactable or speedPurchasing then return end
 speedPurchasing=true; speedRequestStage=speedState.UpgradeStage
 speedStatus.Text="Saving..."; refreshSpeed()
 speedRemote:FireServer("Upgrade",speedRequestStage)
end)
connect(speedRemote.OnClientEvent,function(result)
 if typeof(result) ~= "table" then return end
 if result.Action == "Upgrade" then
  speedPurchasing=false
  speedStatus.Text=result.Success and "Upgraded!" or messages[result.Code] or "Purchase failed. Please retry."
 end
 applySpeed(result.State)
end)
connect(player:GetAttributeChangedSignal("SpeedUpgradeStage"), requestSpeedState)
connect(player:GetAttributeChangedSignal("SpeedUpgradePurchasePending"), requestSpeedState)
connect(player:GetAttributeChangedSignal("HasPremiumSpeed"), requestSpeedState)
bindWinButton(purchase,price)
local purchasing = false
local requestedCapacity
local function refresh()
	local capacity = player:GetAttribute("RunInventoryCapacity")
	local tier = Upgrades.Upgrades[capacity]
	current.Text = typeof(capacity) == "number" and tostring(capacity) or "-"
	nextValue.Text = tier and tostring(tier.NextCapacity) or "MAX"
	price.Text = tier and require(RS.Modules.NumberFormat).Format(tier.PriceWin) or "MAX"
	purchase.TrophyIcon.Visible = false
	purchase.Active = tier ~= nil and not purchasing
	purchase.Interactable = purchase.Active
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
	local capacityMessages = {
		NotEnoughWin = "Not enough Win", InventorySavePending = "Save pending. Please retry.",
		DataSaving = "Please try again", DataNotLoaded = "Loading...", MaxCapacity = "MAX",
		CapacityChanged = "Capacity updated", SessionOwnershipLost = "Please rejoin",
	}
	status.Text = success and "Upgraded!" or capacityMessages[code] or "Purchase failed. Please retry."
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
-- Match the measured 1410 x 800 reference; reflow only for portrait widths.
local scale = Instance.new("UIScale"); scale.Name = "UpgradeScale"; scale.Parent = panel
local function layout()
 local v = gui.AbsoluteSize
 local narrow = v.X < 700 and v.X < v.Y
 local w,h = narrow and 700 or 1410, narrow and 1000 or 800
 scale.Scale = math.clamp(narrow and math.min((v.X-24)/w,(v.Y-24)/h) or math.min(v.X/1846,v.Y/852),.05,1)
 panel.Size=UDim2.fromOffset(w,h); panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.fromOffset(v.X/2,v.Y/2)
 for i,row in {card,speedCard} do
  row.Position=UDim2.fromOffset(34,166+(i-1)*(narrow and 414 or 324))
  row.Size=UDim2.new(1,-68,0,narrow and 394 or 300)
  row.IconBox.Position=UDim2.fromOffset(narrow and 20 or 30,narrow and 92 or 40)
  row.IconBox.Size=UDim2.fromOffset(narrow and 180 or 256,narrow and 180 or 230)
  row.Label.Position=UDim2.fromOffset(narrow and 206 or 320,18)
  row.Label.Size=UDim2.new(1,narrow and -220 or -346,0,80)
  local a=row:FindFirstChild("CurrentCapacity") or row.CurrentSpeed
  local b=row:FindFirstChild("NextCapacity") or row.NextSpeed
  a.Position=UDim2.fromOffset(narrow and 214 or 322,narrow and 116 or 138)
  a.Size=UDim2.fromOffset(narrow and 112 or 142,narrow and 94 or 126)
  row.Arrow.Position=UDim2.fromOffset(narrow and 330 or 476,narrow and 126 or 148)
  row.Arrow.Size=UDim2.fromOffset(narrow and 88 or 150,76)
  b.Position=UDim2.fromOffset(narrow and 436 or 648,narrow and 116 or 138)
  b.Size=UDim2.fromOffset(142,narrow and 94 or 126)
  row.Purchase.Position=UDim2.fromOffset(narrow and 216 or 892,narrow and 248 or 170)
  row.Purchase.Size=UDim2.fromOffset(narrow and 394 or 414,96)
  row.PurchaseFeedback.Position=UDim2.fromOffset(narrow and 206 or 320,narrow and 356 or 264)
  row.PurchaseFeedback.Size=UDim2.new(1,narrow and -222 or -350,0,28)
 end
end
connect(gui:GetPropertyChangedSignal("AbsoluteSize"),layout)
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
		if not otherOpen then status.Text = ""; speedStatus.Text = ""; refresh(); refreshSpeed(); requestSpeedState(); panel.Visible = true end
	end
	inside = near
	if panel.Visible then layout() end
end)
script.Destroying:Once(function()
	for _,c in connections do c:Disconnect() end
	if trigger then trigger:Destroy() end
	panel:Destroy()
end)
refresh()
refreshSpeed()
requestSpeedState()
layout()
