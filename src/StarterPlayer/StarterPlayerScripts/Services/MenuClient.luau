type Panel = {
	frame: GuiObject,
	base: UDim2,
}

type Menu = {
	frame: GuiObject,
	scale: UIScale,
	open: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Config = require(ReplicatedStorage.Modules.Config)

local GUI_NAME = "ScreenGui"
local MENUS_NAME = "Menus"
local ROW_NAMES = { "Left", "LeftDown" }
local BUTTON_NAME = "Button"
local EXIT_PATH = { "Exit", "Button" }
local BLUR_NAME = "MenuBlur"
local WAIT_TIMEOUT = 10

local MOVE_INFO = TweenInfo.new(Config.Menu.seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local MenuClient = {}

local Panels: {Panel} = {}
local Menus: {[string]: Menu} = {}

local Held: {[string]: boolean} = {}

local Shown: {[string]: boolean} = {}

local janitor = Janitor.new()

local screen: ScreenGui? = nil
local blur: BlurEffect? = nil
local openName: string? = nil
local openToken = 0

local slid = false

local function findPath(root: Instance, path: {string}): Instance?
	local current: Instance? = root
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):FindFirstChild(name)
	end

	return current
end

local function awayPosition(frame: GuiObject, base: UDim2): UDim2
	local gui = screen
	if not gui then return base end

	local viewport = gui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then return base end

	local corner = frame.AbsolutePosition - gui.AbsolutePosition
	local size = frame.AbsoluteSize
	local margin = Config.Menu.margin

	local left = corner.X / viewport.X
	local right = left + size.X / viewport.X
	local top = corner.Y / viewport.Y
	local bottom = top + size.Y / viewport.Y

	local nearest = math.min(left, 1 - right, top, 1 - bottom)

	if nearest == left then return base - UDim2.fromScale(right + margin, 0) end
	if nearest == 1 - right then return base + UDim2.fromScale(1 - left + margin, 0) end
	if nearest == top then return base - UDim2.fromScale(0, bottom + margin) end

	return base + UDim2.fromScale(0, 1 - top + margin)
end

local function slide(away: boolean)
	if slid == away then return end
	slid = away

	for _, panel in ipairs(Panels) do
		if Held[panel.frame.Name] then continue end

		local target = if away then awayPosition(panel.frame, panel.base) else panel.base

		TweenService:Create(panel.frame, MOVE_INFO, { Position = target }):Play()
	end
end

local function setBlur(size: number)
	local effect = blur
	if not effect then return end

	if size > 0 then effect.Enabled = true end

	TweenService:Create(effect, MOVE_INFO, { Size = size }):Play()
end

local function hideOthers(name: string)
	for menuName, menu in Menus do
		if menuName == name then continue end

		menu.frame.Visible = false
		menu.scale.Scale = 0
	end
end

local function collect(gui: ScreenGui)
	table.clear(Panels)
	table.clear(Menus)

	local folder = gui:FindFirstChild(MENUS_NAME)
	if not folder then
		warn(`[MenuClient] could not find {gui:GetFullName()}.{MENUS_NAME}`)
		return
	end

	screen = gui

	for _, child in ipairs(gui:GetChildren()) do
		if not child:IsA("GuiObject") then continue end

		if child.Name == Config.Leave.frame then continue end

		table.insert(Panels, { frame = child, base = child.Position })

		if not Held[child.Name] then continue end

		Shown[child.Name] = child.Visible
		child.Visible = false
	end

	for _, child in ipairs(folder:GetChildren()) do
		if not child:IsA("GuiObject") or child.Name ~= "Inventory" then continue end

		local scale = child:FindFirstChildWhichIsA("UIScale")
		if not scale then
			warn(`[MenuClient] {child:GetFullName()} carries no UIScale to open on`)
			continue
		end

		Menus[child.Name] = { frame = child, scale = scale, open = scale.Scale }

		child.Visible = false
		scale.Scale = 0
	end
end

local function bindRow(row: Instance)
	for _, child in ipairs(row:GetChildren()) do
		if not child:IsA("GuiObject") then continue end

		local name = child.Name
		if not Menus[name] then continue end

		local button = child:FindFirstChild(BUTTON_NAME)
		if not (button and button:IsA("GuiButton")) then continue end

		janitor:Add(button.Activated:Connect(function()
			MenuClient.open(name)
		end))
	end
end

local function bindButtons(gui: ScreenGui)
	for _, rowName in ipairs(ROW_NAMES) do
		local row = gui:FindFirstChild(rowName)
		if not row then
			warn(`[MenuClient] could not find {gui:GetFullName()}.{rowName}`)
			continue
		end

		bindRow(row)
	end

	for _, menu in Menus do
		local button = findPath(menu.frame, EXIT_PATH)
		if not (button and button:IsA("GuiButton")) then
			warn(`[MenuClient] could not find {menu.frame:GetFullName()}.{table.concat(EXIT_PATH, ".")}`)
			continue
		end

		janitor:Add(button.Activated:Connect(function()
			MenuClient.close()
		end))
	end
end

local function bind(gui: ScreenGui)
	janitor:Cleanup()

	openName = nil
	openToken += 1

	slid = false

	collect(gui)
	bindButtons(gui)
end

function MenuClient.open(name: string)
	local menu = Menus[name]
	if not menu then
		warn(`[MenuClient] no menu named {name}`)
		return
	end
	if openName == name then return end

	local wasOpen = openName ~= nil
	openName = name

	hideOthers(name)
	menu.frame.Visible = true

	if wasOpen then
		menu.scale.Scale = menu.open
		return
	end

	openToken += 1

	menu.scale.Scale = 0

	slide(true)
	setBlur(Config.Menu.blurSize)
	TweenService:Create(menu.scale, MOVE_INFO, { Scale = menu.open }):Play()
end

function MenuClient.close()
	local name = openName
	if not name then return end
	openName = nil

	local menu = Menus[name]
	if not menu then return end

	openToken += 1
	local token = openToken

	slide(false)
	setBlur(0)

	local fade = TweenService:Create(menu.scale, MOVE_INFO, { Scale = 0 })
	fade.Completed:Connect(function()
		if openToken ~= token then return end

		menu.frame.Visible = false

		local effect = blur
		if effect then effect.Enabled = false end
	end)
	fade:Play()
end

function MenuClient.shroud(on: boolean)
	openToken += 1
	local token = openToken

	if on then
		local name = openName
		local menu = if name then Menus[name] else nil

		openName = nil

		if menu then
			menu.frame.Visible = false
			menu.scale.Scale = 0
		end

		slide(true)
		setBlur(Config.Menu.blurSize)
		return
	end

	slide(false)
	setBlur(0)

	task.delay(Config.Menu.seconds, function()
		if openToken ~= token then return end
		if openName then return end

		local effect = blur
		if effect then effect.Enabled = false end
	end)
end

function MenuClient.hold(name: string, on: boolean)
	if (Held[name] == true) == on then return end

	Held[name] = if on then true else nil

	for _, panel in ipairs(Panels) do
		local frame = panel.frame
		if frame.Name ~= name then continue end

		if on then
			Shown[name] = frame.Visible
			frame.Visible = false
			return
		end

		local wasShown = Shown[name]
		Shown[name] = nil

		if wasShown == false then return end

		frame.Position = awayPosition(frame, panel.base)
		frame.Visible = true

		TweenService:Create(frame, MOVE_INFO, { Position = panel.base }):Play()
		return
	end
end

function MenuClient.rebase(frame: GuiObject, position: UDim2)
	for _, panel in ipairs(Panels) do
		if panel.frame ~= frame then continue end

		panel.base = position
		return
	end
end

function MenuClient.forget(frame: GuiObject)
	for index, panel in ipairs(Panels) do
		if panel.frame ~= frame then continue end

		table.remove(Panels, index)
		return
	end
end

function MenuClient.knows(name: string): boolean
	return Menus[name] ~= nil
end

function MenuClient.shown(): string?
	return openName
end

function MenuClient.init()
	local effect = Instance.new("BlurEffect")
	effect.Name = BLUR_NAME
	effect.Size = 0
	effect.Enabled = false
	effect.Parent = Lighting

	blur = effect
end

function MenuClient.start()
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

return MenuClient
