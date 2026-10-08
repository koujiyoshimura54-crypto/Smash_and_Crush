type Sheet = {
	part: BasePart,
	base: CFrame,
	open: BillboardGui?,
	size: UDim2?,
	share: number,
	drift: Vector2,
	openness: number,

	janitor: any,
}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Janitor = require(ReplicatedStorage.Packages.Janitor)
-- Requests are acknowledged through the legacy Pet transaction bridge.
local Config = require(ReplicatedStorage.Modules.Config)
local Egg = require(ReplicatedStorage.Modules.Egg)
local ButtonClient = require(script.Parent.ButtonClient)
local NotifyClient = require(script.Parent.NotifyClient)
local PetClient = require(script.Parent.PetClient)
local HatchClient = require(script.Parent.HatchClient)

local TEMPLATE_PATH = { "Assets", "Templates", "OpenEgg" }
local ICONS_PATH = { "Assets", "Icons", "Pets" }
local SLOTS_PATH = { "Background", "Pets" }
local GUI_NAME = "ScreenGui"
local BACKGROUND_NAME = "Background"
local PETS_NAME = "Pets"
local OPENS_NAME = "Opens"
local BUTTON_NAME = "Button"
local INFO_NAME = "Info"
local PERCENT_NAME = "Percent"
local SHADOW_SUFFIX = "Shadow"
local ROOT_NAME = "HumanoidRootPart"
local WAIT_TIMEOUT = 10
local TURN = math.pi * 2

local CARD_ZINDEX = 100

local EggClient = {}

local Eggs: {[string]: Sheet} = {}

local playerData: any = nil
local screen: ScreenGui? = nil
local template: BillboardGui? = nil
local icons: Instance? = nil

local function findPath(root: Instance, path: {string}): Instance?
	local current: Instance? = root
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):FindFirstChild(name)
	end

	return current
end

local function setText(label: Instance?, text: string)
	if not (label and label:IsA("TextLabel")) then return end
	if label.Text == text then return end

	label.Text = text
end

local function setPair(root: Instance, name: string, text: string)
	setText(root:FindFirstChild(name), text)
	setText(root:FindFirstChild(name .. SHADOW_SUFFIX), text)
end

local function setIcon(frame: ImageLabel, petName: string)
	local decal = if icons then icons:FindFirstChild(petName) else nil
	if not (decal and decal:IsA("Decal")) then
		warn(`[EggClient] could not find {table.concat(ICONS_PATH, ".")}.{petName}`)
		return
	end
	if frame.Image == decal.Texture then return end

	frame.Image = decal.Texture
end

local function stampSheet(name: string, open: BillboardGui)
	local background = open:FindFirstChild(BACKGROUND_NAME)
	if background then
		setPair(background, INFO_NAME, string.format(Config.Eggs.titleFormat, name))
	else
		warn(`[EggClient] {name} sheet has no {BACKGROUND_NAME}`)
	end

	local Pets = Egg.pets(name)
	if not Pets then return end

	local folder = findPath(open, SLOTS_PATH)
	if not folder then
		warn(`[EggClient] {name} sheet has no {table.concat(SLOTS_PATH, ".")}`)
		return
	end

	local Frames: {ImageLabel} = {}
	for _, child in ipairs(folder:GetChildren()) do
		if not child:IsA("ImageLabel") then continue end

		table.insert(Frames, child)
	end

	table.sort(Frames, function(a: ImageLabel, b: ImageLabel): boolean
		return (tonumber(a.Name) or math.huge) < (tonumber(b.Name) or math.huge)
	end)

	local layout = folder:FindFirstChildWhichIsA("UIListLayout")
	if layout then layout.SortOrder = Enum.SortOrder.LayoutOrder end

	local List = Egg.ranked(Pets)

	for index, frame in ipairs(Frames) do
		local slot = List[index]

		frame.LayoutOrder = index

		if frame.Visible ~= (slot ~= nil) then
			frame.Visible = slot ~= nil
		end

		if not slot then continue end

		setPair(frame, PERCENT_NAME, string.format(Config.Eggs.percentFormat, slot.percent))
		setIcon(frame, slot.pet)
	end

	if #List <= #Frames then return end

	warn(`[EggClient] {name} holds {#List} pets and its sheet has room for {#Frames}`)
end

local function press(name: string, button: string, count: number)
	local price = Egg.price(name) * count
	if price <= 0 then return end

	local settings = Config.Eggs
	if PetClient.busy() or HatchClient.playing() then return end
	local wins = Player:GetAttribute("Win")

	if type(wins) ~= "number" or wins < price then
		NotifyClient.push({ { text = settings.shortText, from = settings.denyFrom, to = settings.denyTo } })
		return
	end

	task.spawn(PetClient.request, "OpenEgg", name, button)
end

local function cursor(): Vector2
	local inset = GuiService:GetGuiInset()
	local mouse = UserInputService:GetMouseLocation()

	return Vector2.new(mouse.X - inset.X, mouse.Y - inset.Y)
end

local function pointerIn(egg: Sheet, open: BillboardGui): Vector2?
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local size = open.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return nil end

	local point = camera:WorldToViewportPoint(egg.part.Position + open.StudsOffsetWorldSpace)
	if point.Z <= 0 then return nil end

	local corner = Vector2.new(point.X, point.Y) - size / 2

	return (cursor() - corner) / size
end

local function cardSize(open: BillboardGui): UDim2?
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local size = open.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return nil end

	local viewport = camera.ViewportSize
	local settings = Config.Egg

	return UDim2.fromScale(
		settings.cardWidth * viewport.X / size.X,
		settings.cardHeight * viewport.Y / size.Y
	)
end

local function follow(egg: Sheet, open: BillboardGui, petName: string?)
	local at = pointerIn(egg, open)
	local size = cardSize(open)
	if not (at and size) then return end

	local settings = Config.Inventory
	local position = UDim2.fromScale(at.X + settings.hoverOffsetX, at.Y + settings.hoverOffsetY)

	if petName then
		PetClient.pinCard(petName, open, position, size, CARD_ZINDEX)
		return
	end

	PetClient.placeCard(position, size)
end

local function bindSheet(egg: Sheet, open: BillboardGui)

	ButtonClient.attach(open, egg.janitor)

	local name = egg.part.Name

	local Pets = Egg.pets(name)
	if not Pets then return end

	local found = open:FindFirstChild(BACKGROUND_NAME)
	local folder = if found then found:FindFirstChild(PETS_NAME) else nil
	if not folder then
		warn(`[EggClient] could not find {open:GetFullName()}.{BACKGROUND_NAME}.{PETS_NAME}`)
		return
	end

	for index, slot in ipairs(Egg.ranked(Pets)) do
		local frame = folder:FindFirstChild(tostring(index))
		local button = if frame then frame:FindFirstChild(BUTTON_NAME) else nil
		if not (button and button:IsA("GuiButton")) then continue end

		local petName = slot.pet

		egg.janitor:Add(button.MouseEnter:Connect(function()
			follow(egg, open, petName)
		end))

		egg.janitor:Add(button.MouseMoved:Connect(function()
			follow(egg, open, nil)
		end))

		egg.janitor:Add(button.MouseLeave:Connect(PetClient.hideCard))
	end

	local opens = open:FindFirstChild(OPENS_NAME)
	if not opens then
		warn(`[EggClient] could not find {open:GetFullName()}.{OPENS_NAME}`)
		return
	end

	for _, frame in ipairs(opens:GetChildren()) do
		local count = Egg.count(frame.Name)
		if not count then continue end

		local button = frame:FindFirstChild(BUTTON_NAME)
		if not (button and button:IsA("GuiButton")) then
			warn(`[EggClient] could not find {frame:GetFullName()}.{BUTTON_NAME}`)
			continue
		end

		local buttonName = frame.Name

		egg.janitor:Add(button.Activated:Connect(function()
			press(name, buttonName, count)
		end))
	end
end

local function build(egg: Sheet)
	egg.janitor:Cleanup()

	egg.open = nil
	egg.size = nil

	local gui = screen
	local source = template
	if not (gui and source) then return end

	local open = egg.janitor:Add(source:Clone())

	egg.size = open.Size

	open.Name = egg.part.Name
	open.Adornee = egg.part
	open.Enabled = false

	stampSheet(egg.part.Name, open)
	bindSheet(egg, open)

	open.Parent = gui

	egg.open = open

	egg.share = 0
	egg.drift = Vector2.zero
	egg.openness = 0
end

local function register(part: BasePart)
	local egg = Eggs[part.Name]

	if egg then
		egg.part = part

		local open = egg.open
		if open then open.Adornee = part end

		return
	end

	local made: Sheet = {
		part = part,
		base = part.CFrame,
		open = nil,
		size = nil,
		share = 0,
		drift = Vector2.zero,
		openness = 0,
		janitor = Janitor.new(),
	}

	Eggs[part.Name] = made

	build(made)
end

local function bind(gui: ScreenGui)
	screen = gui

	for _, egg in Eggs do
		build(egg)
	end
end

local function setSize(open: BillboardGui, size: UDim2)
	if open.Size == size then return end

	open.Size = size
end

local function setOffset(open: BillboardGui, offset: Vector3)
	if open.StudsOffsetWorldSpace == offset then return end

	open.StudsOffsetWorldSpace = offset
end

local function setEnabled(open: BillboardGui, enabled: boolean)
	local wanted = enabled and not HatchClient.playing()
	if open.Enabled == wanted then return end

	open.Enabled = wanted
end

local function better(angle: number, distance: number, bestAngle: number, bestDistance: number): boolean
	if math.abs(angle - bestAngle) <= Config.Egg.tie then return distance < bestDistance end

	return angle < bestAngle
end

local function choose(camera: Camera): Sheet?
	local character = Player.Character
	local root = if character then character:FindFirstChild(ROOT_NAME) else nil
	if not (root and root:IsA("BasePart")) then return nil end

	local from = camera.CFrame.Position
	local look = camera.CFrame.LookVector

	local chosen: Sheet? = nil
	local bestAngle, bestDistance = math.huge, math.huge

	for _, egg in Eggs do
		if not egg.open then continue end
		if not egg.part.Parent then continue end

		local anchor = egg.base.Position

		local distance = (anchor - root.Position).Magnitude
		if distance > Config.Egg.reach then continue end

		local towards = anchor - from
		local length = towards.Magnitude
		if length <= 0 then continue end

		local angle = math.acos(math.clamp(look:Dot(towards / length), -1, 1))

		if chosen and not better(angle, distance, bestAngle, bestDistance) then continue end

		chosen, bestAngle, bestDistance = egg, angle, distance
	end

	return chosen
end

local function fitAxis(at: number, half: number, size: number): number
	if half * 2 >= size then return at end

	return math.clamp(at, half, size - half)
end

local function fit(egg: Sheet, camera: Camera, delta: number, wanted: boolean)
	local open = egg.open
	local size = egg.size
	if not (open and size) then return end

	local step = if wanted then delta else -delta
	egg.openness = math.clamp(egg.openness + step / Config.Egg.openSeconds, 0, 1)

	setEnabled(open, egg.openness > 0)

	if egg.openness <= 0 then
		egg.share = 0
		egg.drift = Vector2.zero
		return
	end

	local viewport = camera.ViewportSize
	if viewport.X <= 0 or viewport.Y <= 0 then return end

	local anchor = egg.base.Position
	local point = camera:WorldToViewportPoint(anchor)

	local still = anchor - egg.part.Position

	if point.Z <= 0 then
		egg.share = 0
		egg.drift = Vector2.zero

		setSize(open, size)
		setOffset(open, still)
		return
	end

	local perStud = viewport.Y / (2 * point.Z * math.tan(math.rad(camera.FieldOfView) / 2))
	if perStud <= 0 then return end

	local width = size.X.Scale * perStud
	local height = size.Y.Scale * perStud
	if width <= 0 or height <= 0 then return end

	local margin = Config.Egg.margin * viewport.Y
	local room = Vector2.new(viewport.X - margin * 2, viewport.Y - margin * 2)

	if room.X <= 0 or room.Y <= 0 then return end

	local landed = egg.share > 0
	local ease = if landed then 1 - math.exp(-Config.Egg.catchUp * delta) else 1

	local goal = math.min(Config.Egg.width * viewport.X, room.X, room.Y * width / height) / width
	egg.share += (goal - egg.share) * ease

	setSize(open, UDim2.fromScale(size.X.Scale * egg.share * egg.openness, size.Y.Scale * egg.share * egg.openness))

	local halfX = size.X.Scale * egg.share * perStud / 2 + margin
	local halfY = size.Y.Scale * egg.share * perStud / 2 + margin

	local target = Vector2.new(fitAxis(point.X, halfX, viewport.X) - point.X, fitAxis(point.Y, halfY, viewport.Y) - point.Y)

	egg.drift = egg.drift:Lerp(target, ease)
	egg.drift = Vector2.new(
		fitAxis(point.X + egg.drift.X, halfX, viewport.X) - point.X,
		fitAxis(point.Y + egg.drift.Y, halfY, viewport.Y) - point.Y
	)

	local frame = camera.CFrame

	setOffset(open, still + (frame.RightVector * egg.drift.X - frame.UpVector * egg.drift.Y) / perStud)
end

function EggClient.start()
	-- Basic-only startup; no purchased Data profile is loaded.

	local found = findPath(ReplicatedStorage, TEMPLATE_PATH)
	if found and found:IsA("BillboardGui") then
		template = found
	else
		warn(`[EggClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(TEMPLATE_PATH, ".")}`)
	end

	icons = findPath(ReplicatedStorage, ICONS_PATH)
	if not icons then
		warn(`[EggClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(ICONS_PATH, ".")}`)
	end

	local folder = workspace:WaitForChild(Egg.FolderName, WAIT_TIMEOUT)
	if not folder then
		warn(`[EggClient] could not find {workspace:GetFullName()}.{Egg.FolderName}`)
		return
	end

	for _, child in ipairs(folder:GetChildren()) do
		if not child:IsA("BasePart") or child.Name ~= "Basic" then continue end

		register(child)
	end

	folder.ChildAdded:Connect(function(child)
		if not child:IsA("BasePart") or child.Name ~= "Basic" then return end

		register(child)
	end)

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

	local rise = Config.Egg.rise
	local rate = TURN / Config.Egg.seconds

	RunService.RenderStepped:Connect(function(delta: number)
		local offset = Vector3.yAxis * (math.sin(os.clock() * rate) * rise)
		local camera = workspace.CurrentCamera

		for _, egg in Eggs do
			if not egg.part.Parent then continue end

			egg.part.CFrame = egg.base + offset
		end

		if not camera then return end

		local chosen = choose(camera)

		for _, egg in Eggs do
			if not egg.part.Parent then continue end

			fit(egg, camera, delta, egg == chosen)
		end
	end)
end

return EggClient
