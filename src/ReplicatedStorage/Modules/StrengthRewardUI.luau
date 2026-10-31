local RS = game:GetService("ReplicatedStorage")
local Layout = require(script.Parent.HUDLayout)
local Config = require(RS.Config.StrengthRewardConfig)
local M = {}
local mounted=setmetatable({}, {__mode="k"})
local function make(class, name, parent, properties)
	local x = Instance.new(class); x.Name = name
	for k, v in pairs(properties or {}) do x[k] = v end
	x.Parent = parent; return x
end
function M.Build(gui)
	local existing = gui:FindFirstChild("OfflineRewards")
	if mounted[gui] then return existing,gui.StrengthLevelHUD.StrengthPacks end
	if existing then
		local row=gui.StrengthLevelHUD.StrengthPacks
		for _,product in ipairs(Config.Packs) do Layout.PurchaseButton(row[tostring(product.ProductId)].Purchase,"Robux","...") end
		Layout.PurchaseButton(existing.Double.Price,"Robux","...")
		-- Authored Edit objects retain no event connections when cloned into Play.
		for _,frame in ipairs({existing.Claim,existing.Double}) do
			local scale=frame.PressScale
			local settings=require(RS.Modules.Config).Button
			frame.Button.MouseButton1Down:Connect(function() scale.Scale=settings.pressScale end)
			frame.Button.MouseButton1Up:Connect(function() scale.Scale=1 end)
			frame.Button.MouseLeave:Connect(function() scale.Scale=1 end)
		end
		Layout.Mount(gui).Refresh()
		mounted[gui]=true
		return existing,row
	end
	local donorGui = gui.Parent:FindFirstChild("ScreenGui") or game.StarterGui.ScreenGui
	local donor = donorGui.Menus.OfflineEarnings
	local iconImage = donor.Main.Icon.Image
	local style = donor.Main.NormalEarned
	local function label(name, parent, text, position, size)
		local x = style:Clone(); x.Name = name; x.Text = text; x.Position = position; x.Size = size
		x.AnchorPoint = Vector2.zero; x.AutomaticSize = Enum.AutomaticSize.None; x.TextScaled = true
		x.TextWrapped = false; x.AutoLocalize = false; x.BackgroundTransparency = 1; x.Visible = true; x.ZIndex = 53
		x.Parent = parent; return x
	end
	local panel = make("Frame", "OfflineRewards", gui, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(700, 450), BackgroundColor3 = Color3.fromRGB(22, 26, 35), BackgroundTransparency = .22,
		BorderSizePixel = 0, Visible = false, ZIndex = 50})
	make("UICorner", "Corner", panel, {CornerRadius = UDim.new(0, 16)})
	make("UIStroke", "Border", panel, {Thickness = 6, Color = Color3.new(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	make("UIScale", "RewardScale", panel)
	label("Title", panel, "OFFLINE REWARDS", UDim2.fromOffset(30, 18), UDim2.fromOffset(640, 58)).TextColor3 = Color3.new(1, 1, 1)
	make("ImageLabel", "StrengthIcon", panel, {BackgroundTransparency = 1, Image = iconImage, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(245, 86), Size = UDim2.fromOffset(210, 210), ZIndex = 51})
	label("Amount", panel, "+0 STRENGTH", UDim2.fromOffset(25, 294), UDim2.fromOffset(650, 54)).TextColor3 = Color3.fromRGB(255, 223, 65)
	local function claim(name, source, text, x)
		local frame = source:Clone(); frame.Name = name; frame.AnchorPoint = Vector2.zero
		frame.Position = UDim2.fromOffset(x, 358); frame.Size = UDim2.fromOffset(320, 76); frame.Visible = true
		for _, child in ipairs(frame:GetDescendants()) do
			if child:IsA("LuaSourceContainer") then child:Destroy()
			elseif child:IsA("GuiObject") then child.ZIndex = 52 end
		end
		local price = frame:FindFirstChild("Price"); if price then price:Destroy() end
		frame.Title.Text = text; frame.Title.AutoLocalize = false; frame.Title.ZIndex = 54
		frame.Button.ZIndex = 59
		frame.Title.TextScaled = true; frame.Title.Position = UDim2.fromScale(.04, .06); frame.Title.Size = UDim2.fromScale(.92, .88)
		frame.Parent = panel
		local scale = make("UIScale", "PressScale", frame)
		local settings = require(RS.Modules.Config).Button
		local tween
		local function animate(value)
			if tween then tween:Cancel() end
			tween = game:GetService("TweenService"):Create(scale, TweenInfo.new(settings.seconds), {Scale = value}); tween:Play()
		end
		frame.Button.MouseButton1Down:Connect(function() animate(settings.pressScale) end)
		frame.Button.MouseButton1Up:Connect(function() animate(1) end)
		frame.Button.MouseLeave:Connect(function() animate(1) end)
		return frame
	end
	claim("Claim", donor.Main.Claim, "CLAIM", 22)
	local double = claim("Double", donor.Main.ClaimPremium, "CLAIM ×2", 358)
	double.Main.BackgroundColor3 = Color3.fromRGB(255, 213, 0)
	double.Title.Position = UDim2.fromScale(.03, .03); double.Title.Size = UDim2.fromScale(.94, .52)
	local price = make("TextButton", "Price", double, {BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Position = UDim2.fromScale(.28, .52), Size = UDim2.fromScale(.44, .42), ZIndex = 55, Active = false})
	Layout.PurchaseButton(price, "Robux", "...")
	local close = donor.Exit:Clone(); close.Name = "Close"; close.AnchorPoint = Vector2.new(.5, .5)
	close.Position = UDim2.new(1, -8, 0, 8); close.Size = UDim2.fromOffset(64, 64); close.Visible = true; close.Parent = panel
	for _, child in ipairs(close:GetDescendants()) do if child:IsA("GuiObject") then child.ZIndex = 60 end end
	close.Title.Text = "×"; close.Main.BackgroundColor3 = Color3.fromRGB(235, 25, 20)
	local row = make("Frame", "StrengthPacks", gui.StrengthLevelHUD, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58)})
	local health = gui.StrengthLevelHUD.LevelPanel.StrengthProgressBar:Clone()
	health.Name = "PlayerHealth"; health.AnchorPoint = Vector2.zero; health.Parent = gui.StrengthLevelHUD
	health.Level.Text = "HP"; health.Exp.Text = "-- / --"; health.Main.Visible = true
	health.Main.BackgroundColor3 = Color3.fromRGB(65, 205, 85)
	for index, product in ipairs(Config.Packs) do
		local card = make("Frame", tostring(product.ProductId), row, {BackgroundTransparency = 1,
			Position = UDim2.new((index - 1) / 3, 3, 0, 0), Size = UDim2.new(1 / 3, -6, 1, 0)})
		make("ImageLabel", "StrengthIcon", card, {BackgroundTransparency = 1, Image = iconImage, ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(.22, .45)})
		local amount = label("Amount", card, "+...", UDim2.fromScale(.23, 0), UDim2.fromScale(.77, .45)); amount.ZIndex = 10
		local purchase = make("TextButton", "Purchase", card, {Text = "", BackgroundTransparency = 1,
			Position = UDim2.fromScale(.06, .45), Size = UDim2.fromScale(.88, .55), ZIndex = 10})
		Layout.PurchaseButton(purchase, "Robux", "...")
	end
	Layout.Mount(gui).Refresh()
	mounted[gui]=true
	return panel, row
end
return M
