local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Camera = workspace.CurrentCamera

local SfxGroup = SoundService:FindFirstChild("SFX")

local Frames = require(script.Frames)
local MarketplaceCtrl = require(script.Parent.MarketplaceController)
local GlobalSignals = require(script.Parent.Parent.Utils.GlobalSignals)
local GlobalFunctions = require(ReplicatedStorage.Utils.GlobalFunctions)

local TWEEN_DURATION = 0.2
local BLUR_SIZE = 50
local FOV_OPEN = 50
local FOV_CLOSE = 70

local blur = Instance.new("BlurEffect")
blur.Size    = 0
blur.Enabled = false
blur.Parent  = game.Lighting

local UiController = {}
UiController.CurrentFrame = nil

local function getFrame(name: string): Frame?
	return Frames[name] or Frames.PopUps[name]
end

local function scaleUDim2(u: UDim2, rate: number): UDim2
	return UDim2.new(
		u.X.Scale  * rate, u.X.Offset * rate,
		u.Y.Scale  * rate, u.Y.Offset * rate
	)
end

local function cacheOriginalSize(item: GuiObject)
	if not item:GetAttribute("OriginalSize") then
		item:SetAttribute("OriginalSize", item.Size)
	end
end

local function makeSound(item: GuiObject, assetId: string): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = assetId
	sound.SoundGroup = SfxGroup
	sound.Parent = item
	return sound
end

local function tweenBlur(targetSize: number, targetFov: number)
	blur.Enabled = true

	TweenService:Create(
		blur,
		TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Quad),
		{ Size = targetSize }
	):Play()

	TweenService:Create(
		Camera,
		TweenInfo.new(0.3, Enum.EasingStyle.Quint),
		{ FieldOfView = targetFov }
	):Play()

	if targetSize == 0 then
		blur:GetPropertyChangedSignal("Size"):Once(function()
			if blur.Size == 0 then
				blur.Enabled = false
			end
		end)
	end
end

local function backgroundScroll(item: ImageLabel, axis: "X" | "Y")
	if not item:IsA("ImageLabel") then return end

	local rate = item:GetAttribute("Ui-Effect-Rate")
	if not rate or rate == 0 then return end

	local delay = item:GetAttribute("Ui-Effect-Delay") or 0
	local tileSize = axis == "Y" and item.TileSize.Y.Offset or item.TileSize.X.Offset
	local originPos = item.Position

	if axis == "Y" then
		item.Size += UDim2.fromOffset(0, tileSize * 3)
	else
		item.Size += UDim2.fromOffset(tileSize * 3, 0)
	end

	RunService.RenderStepped:Connect(function()
		if not item.Parent then return end

		local t = workspace:GetServerTimeNow() + delay
		local alpha = (t / math.abs(rate)) % 1
		local offset = alpha * tileSize * (rate < 0 and -1 or 1)

		if axis == "Y" then
			item.Position = originPos + UDim2.fromOffset(0, offset - tileSize)
		else
			item.Position = originPos + UDim2.fromOffset(offset - tileSize, 0)
		end
	end)
end

local Effects = {

	Shake = function(item: Frame)
		local angle = (math.abs(item:GetAttribute("Ui-Effect-Rate")) - 1) * 90
		item.Rotation = -angle

		local tween = TweenService:Create(
			item,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
			{ Rotation = angle }
		)
		

		local delay = item:GetAttribute("Ui-Effect-Delay")
		if delay then
			task.delay(delay, function () tween:Play() end)
		else
			tween:Play()
		end
	end,

	Spin = function(item: Frame)
		local tween = TweenService:Create(
			item,
			TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
			{ Rotation = 360 }
		)
		tween:Play()

		local delay = item:GetAttribute("Ui-Effect-Delay")
		if delay then
			tween.TimePosition = workspace:GetServerTimeNow() % delay
		end
	end,

	Float = function(item: GuiObject)
		local rate = item:GetAttribute("Ui-Effect-Rate")  or 6
		local delay = item:GetAttribute("Ui-Effect-Delay") or 0
		local speed = item:GetAttribute("Ui-Effect-Speed") or 2
		local originPos = item.Position

		task.delay(delay, function()
			if not item.Parent then return end

			TweenService:Create(
				item,
				TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Position = originPos + UDim2.fromOffset(0, rate) }
			):Play()
		end)
	end,

	Bg_Y = function(item: ImageLabel) backgroundScroll(item, "Y") end,
	Bg_X = function(item: ImageLabel) backgroundScroll(item, "X") end,

	Shine = function(item: ImageLabel)
		local shine = script.Shine:Clone()
		shine.Position = UDim2.fromScale(0, 0.5)
		shine.AnchorPoint = Vector2.new(1, 0.5)
		shine.Parent = item

		TweenService:Create(
			shine,
			TweenInfo.new(
				item:GetAttribute("Ui-Effect-Rate"),
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut,
				-1, true, 5
			),
			{ Position = UDim2.fromScale(1, 0.5), AnchorPoint = Vector2.new(0, 0.5) }
		):Play()
	end,
}

local Scale = {
	ImageTileScale = function(item: ImageLabel, rate: number)
		local function update()
			local tileSize = item.Parent.AbsoluteSize.X / rate
			item.TileSize = UDim2.new(0, tileSize, 0, tileSize)
		end
		item.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		update()
	end,
}

local HoverEffects = {
	Expand = function(item: ImageButton, rate: number)
		cacheOriginalSize(item)
		local original = item:GetAttribute("OriginalSize")

		item.MouseEnter:Connect(function()
			item:TweenSize(scaleUDim2(original, rate), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
		end)
		item.MouseLeave:Connect(function()
			item:TweenSize(original, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
		end)
	end,
}

local ClickEffects = {
	In = function(item: ImageButton, rate: number)
		cacheOriginalSize(item)
		local original = item:GetAttribute("OriginalSize")

		item.MouseButton1Click:Connect(function()
			item:TweenSize(scaleUDim2(original, rate), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
			task.delay(0.1, function()
				item:TweenSize(original, Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.2, true)
			end)
		end)
	end,
}

local HoverSounds = {
	Default = function(item: GuiObject)
		local sound = makeSound(item, "rbxassetid://139800881181209")
		item.MouseEnter:Connect(function() sound:Play() end)
	end,
}

local ClickSounds = {
	Default = function(item: GuiObject)
		local sound = makeSound(item, "rbxassetid://88442833509532")
		item.MouseButton1Click:Connect(function() sound:Play() end)
	end,

	UiClose = function(item: GuiObject)
		local sound = makeSound(item, "rbxassetid://74657965144290")
		item.MouseButton1Click:Connect(function() sound:Play() end)
	end,

	Money = function(item: GuiObject)
		local sound = makeSound(item, "rbxassetid://1210852193")
		item.MouseButton1Click:Connect(function() sound:Play() end)
	end,
}

local EFFECT_REGISTRY: { [string]: { handlers: { [string]: (GuiObject, any) -> () }, rateAttr: string? } } = {
	["Ui-Effect"]      = { handlers = Effects,      rateAttr = nil             },
	["Ui-Scale"]       = { handlers = Scale,        rateAttr = "Ui-Scale-Rate" },
	["Ui-Hover"]       = { handlers = HoverEffects, rateAttr = "Ui-Hover-Rate" },
	["Ui-Click"]       = { handlers = ClickEffects, rateAttr = "Ui-Click-Rate" },
	["Ui-Hover-Sound"] = { handlers = HoverSounds,  rateAttr = nil             },
	["Ui-Click-Sound"] = { handlers = ClickSounds,  rateAttr = nil             },
}

local MARKETPLACE_ATTRS: { [string]: (GuiObject, any) -> () } = {

	["Ui-Product"] = function(item, v)
		MarketplaceCtrl:SetProductButton(item, v)
	end,

	["Ui-Product-Robux"] = function(item, v)
		item.Text = " " .. tostring(MarketplaceCtrl:GetPrice("Product", v) or "?")
	end,

	["Ui-Pass"] = function(item, v)
		MarketplaceCtrl:SetPassButton(item, v)
	end,

	["Ui-Pass-Robux"] = function(item, v)
		item.Text = " " .. tostring(MarketplaceCtrl:GetPrice("Pass", v) or "?")
	end,

	["Ui-Gift-Pass"] = function(item, v)
		MarketplaceCtrl:SetPassGiftButton(item, v)
	end,

	["Ui-Gift-Product"] = function(item, v)
		MarketplaceCtrl:SetProductGiftButton(item, v)
	end,

	["Ui-Pack"] = function(item, v)
		MarketplaceCtrl:SetPackButton(item, v)
	end,

	["Ui-Pack-Robux"] = function(item, v)
		item.Text = " " .. tostring(MarketplaceCtrl:GetPrice("Pack", v) or "?")
	end,
}

local function applyEffectRegistry(item: GuiObject)
	for attr, entry in EFFECT_REGISTRY do
		local key = item:GetAttribute(attr)
		if not key then continue end

		local handler = entry.handlers[key]
		if not handler then continue end

		local rate = entry.rateAttr and item:GetAttribute(entry.rateAttr)
		handler(item, rate)
	end
end

local function applyMarketplace(item: GuiObject)
	for attr, handler in MARKETPLACE_ATTRS do
		local value = item:GetAttribute(attr)
		if value then
			handler(item, value)
		end
	end
end

local function applyFrameToggle(item: GuiButton)
	local frameTarget = item:GetAttribute("Ui-Frame")
	item.MouseButton1Click:Connect(function()
		if UiController.CurrentFrame == frameTarget then
			UiController:CloseCurrentFrame(true)
		else
			UiController:OpenFrame(frameTarget)
		end
	end)
end

local function applyCloseButton(item: GuiButton)
	item.MouseButton1Click:Connect(function()
		UiController:CloseCurrentFrame(true)
	end)
end

local EFFECT_SELECTOR = table.concat({
	"[$Ui-Effect]",
	"[$Ui-Scale]",
	"[$Ui-Hover]",
	"[$Ui-Click]",
	"[$Ui-Hover-Sound]",
	"[$Ui-Click-Sound]",
}, ", ")

local MARKETPLACE_SELECTOR = table.concat({
	"[$Ui-Product]",
	"[$Ui-Product-Robux]",
	"[$Ui-Pass]",
	"[$Ui-Pass-Robux]",
	"[$Ui-Gift-Pass]",
	"[$Ui-Gift-Product]",
	"[$Ui-Pack]",
	"[$Ui-Pack-Robux]",
}, ", ")

local FRAME_TOGGLE_SELECTOR = "GuiButton[$Ui-Frame]"
local CLOSE_BUTTON_SELECTOR  = "GuiButton[$Ui-Close]"

local function runBulkSetup(root: Instance)
	for _, item in root:QueryDescendants(EFFECT_SELECTOR) do
		applyEffectRegistry(item)
	end

	for _, item in root:QueryDescendants(MARKETPLACE_SELECTOR) do
		applyMarketplace(item)
	end

	for _, item in root:QueryDescendants(FRAME_TOGGLE_SELECTOR) do
		applyFrameToggle(item :: GuiButton)
	end

	for _, item in root:QueryDescendants(CLOSE_BUTTON_SELECTOR) do
		applyCloseButton(item :: GuiButton)
	end
end

local function setupItem(item: GuiObject)
	local hasEffect = false
	for attr in EFFECT_REGISTRY do
		if item:GetAttribute(attr) then
			hasEffect = true
			break
		end
	end
	if hasEffect then applyEffectRegistry(item) end

	local hasMarket = false
	for attr in MARKETPLACE_ATTRS do
		if item:GetAttribute(attr) then
			hasMarket = true
			break
		end
	end
	if hasMarket then applyMarketplace(item) end

	if item:GetAttribute("Ui-Frame") and item:IsA("GuiButton") then
		applyFrameToggle(item :: GuiButton)
	end

	if item:GetAttribute("Ui-Close") and item:IsA("GuiButton") then
		applyCloseButton(item :: GuiButton)
	end
end

function UiController:CloseCurrentFrame(tween: boolean)
	if not UiController.CurrentFrame then return end

	local frame = getFrame(UiController.CurrentFrame)
	UiController.CurrentFrame = nil

	if tween then
		frame:TweenPosition(
			UDim2.fromScale(frame.Position.X.Scale, 0.6),
			Enum.EasingDirection.In, Enum.EasingStyle.Quad, TWEEN_DURATION
		)
		task.delay(TWEEN_DURATION, function() frame.Visible = false end)

		if blur.Enabled then
			tweenBlur(0, FOV_CLOSE)
		end
	else
		frame.Visible = false
	end
end

function UiController:OpenFrame(frameName: string, noBlur: boolean?)
	if UiController.CurrentFrame == frameName then return end

	UiController:CloseCurrentFrame(false)

	local frame = getFrame(frameName)
	frame.Position = UDim2.fromScale(frame.Position.X.Scale, 0.6)
	frame.Visible  = true
	frame:TweenPosition(
		UDim2.fromScale(frame.Position.X.Scale, 0.5),
		Enum.EasingDirection.Out, Enum.EasingStyle.Quad, TWEEN_DURATION
	)
	UiController.CurrentFrame = frameName

	if not noBlur then
		tweenBlur(BLUR_SIZE, FOV_OPEN)
	end
end

local function initCashDisplay()
	local Main = PlayerGui:WaitForChild("Main")
	local CashLabel = Main.HUD.Left.Icon
	local TransactionRoot = CashLabel.main.Transactions

	local AddTemplate = TransactionRoot.Add
	local SubTemplate = TransactionRoot.Subtract
	AddTemplate.Parent = nil
	SubTemplate.Parent = nil

	local CashLeaderstats: NumberValue = Player:WaitForChild("leaderstats").Cash
	local prevValue = CashLeaderstats.Value
	local activeRender = nil

	local tickSound = Instance.new("Sound")
	tickSound.SoundId = "rbxassetid://607665037"
	tickSound.Volume = 1
	tickSound.SoundGroup = SfxGroup
	tickSound.Parent = SoundService

	local function setCashLabel(amount: number)
		local formatted = GlobalFunctions.FormatNumber(amount)
		CashLabel.main.Text = formatted
		CashLabel.shadow.Text = formatted
	end

	local function tweenCashValue(from: number, to: number, duration: number)
		if activeRender then
			activeRender:Disconnect()
			activeRender = nil
		end

		local startTime = tick()
		local lastTick = 0

		activeRender = RunService.RenderStepped:Connect(function()
			local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
			setCashLabel(math.floor(from + (to - from) * alpha))

			if to > from and tick() - lastTick >= 0.05 then
				lastTick = tick()
				tickSound:Play()
			end

			if alpha >= 1 then
				setCashLabel(to)
				activeRender:Disconnect()
				activeRender = nil
			end
		end)
	end

	local function showTransactionBadge(amount: number)
		local template = amount > 0 and AddTemplate or SubTemplate
		local badge = template:Clone()
		badge.Visible = true
		badge.Parent = TransactionRoot

		local originalSize = badge.Size
		badge.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)

		local sign = amount > 0 and "+" or "-"
		local formatted = sign .. GlobalFunctions.FormatNumber(math.abs(amount))
		badge.main.Text = formatted
		badge.shadow.Text = formatted

		local openInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
		local closeInfo = TweenInfo.new(0.20, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
		local collapsed = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 0)

		local openTween = TweenService:Create(badge, openInfo, { Size = originalSize })
		openTween:Play()
		openTween.Completed:Wait()

		task.wait(2)

		local closeTween = TweenService:Create(badge, closeInfo, { Size = collapsed })
		closeTween:Play()
		closeTween.Completed:Wait()

		badge:Destroy()
	end

	setCashLabel(prevValue)

	CashLeaderstats.Changed:Connect(function(newValue: number)
		local diff = newValue - prevValue
		if diff == 0 then return end

		task.spawn(showTransactionBadge, diff)
		tweenCashValue(prevValue, newValue, 0.5)

		prevValue = newValue
	end)
end

function UiController:init()

	task.defer(function()
		runBulkSetup(PlayerGui)
	end)

	PlayerGui.DescendantAdded:Connect(function(item)
		task.spawn(setupItem, item)
	end)

	GlobalSignals.UI.OpenFrame:Connect(function(frameName, noBlur)
		UiController:OpenFrame(frameName, noBlur)
	end)

	GlobalSignals.UI.CloseFrame:Connect(function(tween)
		UiController:CloseCurrentFrame(tween)
	end)

	initCashDisplay()
end

return UiController
