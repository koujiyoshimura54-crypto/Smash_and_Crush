type Button = {
	frame: GuiObject,
	button: GuiButton,
	tween: Tween?,
	scaled: boolean,
	base: UDim2,
	hover: UDim2,
	press: UDim2,

	tip: GuiObject?,

	hovered: boolean,
	pressed: boolean,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Config = require(ReplicatedStorage.Modules.Config)

local GUI_NAME = "ScreenGui"
local CLICK_PATH = { "UI", "Click" }
local HOVER_PATH = { "UI", "Hover" }
local WAIT_TIMEOUT = 10

local HOVER_NAME = "Hover"

local SIZE_INFO = TweenInfo.new(Config.Button.seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local ButtonClient = {}

local Buttons: {[GuiButton]: Button} = {}

local janitor = Janitor.new()

local clickSound: Sound? = nil
local hoverSound: Sound? = nil

local function waitForSound(path: {string}): Sound?
	local current: Instance? = SoundService
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):WaitForChild(name, WAIT_TIMEOUT)
	end

	return if current and current:IsA("Sound") then current else nil
end

local function scaled(size: UDim2, factor: number): UDim2
	return UDim2.new(
		size.X.Scale * factor,
		size.X.Offset * factor,
		size.Y.Scale * factor,
		size.Y.Offset * factor
	)
end

local function play(sound: Sound?, button: GuiButton)
	if not sound or not require(ReplicatedStorage.Modules.UIFeedback).CanSound(button,"Click") then return end

	sound:Play()
end

local function resize(entry: Button)
 local wasAnimating=entry.tween and entry.tween.PlaybackState==Enum.PlaybackState.Playing
 if entry.tween then entry.tween:Cancel();entry.tween=nil end
 if entry.button:GetAttribute("NoButtonScale")==true then
  if entry.scaled or wasAnimating then entry.frame.Size=entry.base;entry.scaled=false end
  return
 end
 local target = if entry.pressed then entry.press elseif entry.hovered then entry.hover else entry.base
 entry.scaled=entry.pressed or entry.hovered
 entry.tween=TweenService:Create(entry.frame,SIZE_INFO,{Size=target})
 entry.tween:Play()
end

local function showTip(entry: Button, on: boolean)
	local tip = entry.tip
	if not tip then return end
	if tip.Visible == on then return end

	tip.Visible = on
end

local function bindButton(button: GuiButton, bag: any)
	if Buttons[button] then return end

	local frame = button.Parent
	if not (frame and frame:IsA("GuiObject")) then return end

	local base = frame.Size
	local hoverScale = Config.Button.hoverScale

	local tip = frame:FindFirstChild(HOVER_NAME)

	local entry: Button = {
		frame = frame,
  button = button, tween = nil, scaled = false,
		base = base,
		hover = scaled(base, hoverScale),
		press = scaled(base, hoverScale * Config.Button.pressScale),
		tip = if tip and tip:IsA("GuiObject") then tip else nil,
		hovered = false,
		pressed = false,
	}

	Buttons[button] = entry
	button:SetAttribute("ExistingHoverSE",true)
	button:SetAttribute("ExistingClickSE",true)

	bag:Add(function()
		Buttons[button] = nil
  if entry.tween then entry.tween:Cancel() end
		if button:GetAttribute("NoButtonScale")~=true then frame.Size = base end

		showTip(entry, false)
	end, true)

 bag:Add(button:GetAttributeChangedSignal("NoButtonScale"):Connect(function()
  entry.hovered=false;entry.pressed=false;resize(entry)
 end))
	bag:Add(button.MouseEnter:Connect(function()
		entry.hovered = true
		require(ReplicatedStorage.Modules.UIFeedback).Hover(button)
		resize(entry)
		showTip(entry, true)
	end))

	bag:Add(button.MouseLeave:Connect(function()
		require(ReplicatedStorage.Modules.UIFeedback).Leave(button)
		entry.hovered = false
		entry.pressed = false
		resize(entry)
		showTip(entry, false)
	end))

	bag:Add(button.MouseButton1Down:Connect(function()
		entry.pressed = true
		resize(entry)
	end))

	bag:Add(button.MouseButton1Up:Connect(function()
		entry.pressed = false
		resize(entry)
	end))

	bag:Add(button.Activated:Connect(function()
		play(clickSound,button)
	end))
end

local function bind(gui: ScreenGui)
	janitor:Cleanup()

	for _, descendant in ipairs(gui:GetDescendants()) do
		if not descendant:IsA("GuiButton") then continue end

		bindButton(descendant, janitor)
	end

	janitor:Add(gui.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("GuiButton") then return end

		bindButton(descendant, janitor)
	end))
end

function ButtonClient.attach(root: Instance, bag: any)
	for _, descendant in ipairs(root:GetDescendants()) do
		if not descendant:IsA("GuiButton") then continue end

		bindButton(descendant, bag)
	end

	bag:Add(root.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("GuiButton") then return end

		bindButton(descendant, bag)
	end))
end

function ButtonClient.start()
	clickSound = waitForSound(CLICK_PATH)
	hoverSound = waitForSound(HOVER_PATH)

	if not clickSound then
		warn(`[ButtonClient] could not find {SoundService:GetFullName()}.{table.concat(CLICK_PATH, ".")}`)
	end
	if not hoverSound then
		warn(`[ButtonClient] could not find {SoundService:GetFullName()}.{table.concat(HOVER_PATH, ".")}`)
	end

	local playerGui = Player:WaitForChild("PlayerGui")

	local gui = playerGui:WaitForChild(GUI_NAME, WAIT_TIMEOUT)
	if gui and gui:IsA("ScreenGui") then
		bind(gui)
	end

	playerGui.ChildAdded:Connect(function(child)
		if child.Name ~= GUI_NAME then return end
		if not child:IsA("ScreenGui") then return end

		bind(child)
	end)
end

return ButtonClient
