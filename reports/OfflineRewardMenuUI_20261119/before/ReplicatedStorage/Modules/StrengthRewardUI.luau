local RS = game:GetService("ReplicatedStorage")
local Layout = require(script.Parent.HUDLayout)
local Config = require(RS.Config.StrengthRewardConfig)
local Presentation = require(script.Parent.StrengthHUDPresentation)
local O = require(RS.Config.StrengthHUDStyle).Offline
local M = {}
function M.DurationTitle(seconds)
	if type(seconds) ~= "number" then return "OFFLINE REWARDS" end
	seconds = Config.OfflineSeconds(seconds)
	local hours = seconds / 3600
	local duration = hours >= 1 and string.format("%.2f", hours):gsub("0+$", ""):gsub("%.$", "")
		or string.format("%.2f", seconds / 60):gsub("0+$", ""):gsub("%.$", "")
	local unit = hours >= 1 and (hours == 1 and "Hour" or "Hours") or (seconds == 60 and "Minute" or "Minutes")
	return duration .. " " .. unit .. " of Offline Rewards"
end
local mounted=setmetatable({}, {__mode="k"})
local function make(class, name, parent, properties)
	local x = Instance.new(class); x.Name = name
	for k, v in pairs(properties or {}) do x[k] = v end
	x.Parent = parent; return x
end
function M.Build(gui)
	local existing = gui:FindFirstChild("OfflineRewards")
	if existing then
		local row=gui.StrengthLevelHUD.StrengthPacks
		Presentation.Apply(gui)
		Layout.Mount(gui).Refresh()
		mounted[gui]=true
		return existing,row
	end
	local donorGui = gui.Parent:FindFirstChild("ScreenGui") or game.StarterGui.ScreenGui
	local donor = donorGui.Menus.OfflineEarnings
	local iconImage = require(RS.Config.StrengthHUDStyle).Assets.Strength
	local style = donor.Main.NormalEarned
	local function label(name, parent, text, position, size)
		local x = style:Clone(); x.Name = name; x.Text = text; x.Position = position; x.Size = size
		x.AnchorPoint = Vector2.zero; x.AutomaticSize = Enum.AutomaticSize.None; x.TextScaled = true
		x.TextWrapped = false; x.AutoLocalize = false; x.BackgroundTransparency = 1; x.Visible = true; x.ZIndex = 53
		x.Parent = parent; return x
	end
	local panel = make("Frame", "OfflineRewards", gui, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(O.Width, O.Height), BackgroundColor3 = Color3.fromRGB(22, 26, 35), BackgroundTransparency = .22,
		BorderSizePixel = 0, Visible = false, ZIndex = 50})
	make("UICorner", "Corner", panel, {CornerRadius = UDim.new(0, O.Radius)})
	make("UIStroke", "Border", panel, {Thickness = O.Border, Color = Color3.new(0, 0, 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	make("UIScale", "RewardScale", panel)
	label("Title", panel, "OFFLINE REWARDS", UDim2.fromOffset(O.Title[1],O.Title[2]), UDim2.fromOffset(O.Title[3],O.Title[4])).TextColor3 = Color3.new(1, 1, 1)
	make("ImageLabel", "StrengthIcon", panel, {BackgroundTransparency = 1, Image = iconImage, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(O.Icon[1],O.Icon[2]), Size = UDim2.fromOffset(O.Icon[3],O.Icon[4]), ZIndex = 51})
	label("Amount", panel, "+0 STRENGTH", UDim2.fromOffset(O.Amount[1],O.Amount[2]), UDim2.fromOffset(O.Amount[3],O.Amount[4])).TextColor3 = Color3.fromRGB(255, 223, 65)
	local function claim(name, source, text, x)
		local frame = source:Clone(); frame.Name = name; frame.AnchorPoint = Vector2.zero
		frame.Position = UDim2.fromOffset(x, O.Claim[2]); frame.Size = UDim2.fromOffset(O.Claim[3], O.Claim[4]); frame.Visible = true
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
		return frame
	end
	claim("Claim", donor.Main.Claim, "CLAIM", O.Claim[1])
	local double = claim("Double", donor.Main.ClaimPremium, "CLAIM ×2", O.Double[1])
	double.Main.BackgroundColor3 = Color3.fromRGB(255, 213, 0)
	double.Title.Position = UDim2.fromScale(.03, .03); double.Title.Size = UDim2.fromScale(.94, .52)
	local price = make("TextButton", "Price", double, {BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		Position = UDim2.fromScale(.28, .52), Size = UDim2.fromScale(.44, .42), ZIndex = 55, Active = false})
	-- One full-size Double.Button owns input; Price is presentation only.
	local close = donor.Exit:Clone(); close.Name = "Close"; close.AnchorPoint = Vector2.new(.5, .5)
	close.Position = UDim2.new(1, -O.CloseInset, 0, O.CloseInset); close.Size = UDim2.fromOffset(O.CloseSize, O.CloseSize); close.Visible = true; close.Parent = panel
	for _, child in ipairs(close:GetDescendants()) do if child:IsA("GuiObject") then child.ZIndex = 60 end end
	close.Title.Text = "×"; close.Main.BackgroundColor3 = Color3.fromRGB(235, 25, 20)
	local row = make("Frame", "StrengthPacks", gui.StrengthLevelHUD, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58)})
	local health = gui.StrengthLevelHUD.LevelPanel.StrengthProgressBar:Clone()
	health.Name = "PlayerHealth"; health.AnchorPoint = Vector2.zero; health.Parent = gui.StrengthLevelHUD
 health.Level.Text = "HP"; health.Exp.Text = "-- / --"
 local healthFill=health:FindFirstChild("Main") or health.FillClip.Main
 healthFill.Visible=true
	for index, product in ipairs(Config.Packs) do
		local card = make("Frame", tostring(product.ProductId), row, {BackgroundTransparency = 1,
			Position = UDim2.new((index - 1) / 3, 3, 0, 0), Size = UDim2.new(1 / 3, -6, 1, 0)})
		make("ImageLabel", "StrengthIcon", card, {BackgroundTransparency = 1, Image = iconImage, ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(.22, .45)})
		local amount = label("Amount", card, "+...", UDim2.fromScale(.23, 0), UDim2.fromScale(.77, .45)); amount.ZIndex = 10
		local purchase = make("TextButton", "Purchase", card, {Text = "", BackgroundTransparency = 1,
			Position = UDim2.fromScale(.06, .45), Size = UDim2.fromScale(.88, .55), ZIndex = 10})

	end
	Presentation.Apply(gui)
	Layout.Mount(gui).Refresh()
	mounted[gui]=true
	return panel, row
end
return M
