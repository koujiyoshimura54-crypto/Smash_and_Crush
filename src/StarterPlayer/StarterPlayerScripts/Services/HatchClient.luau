type Result = {
	pet: string,
	percent: number,
	duplicate: boolean,

	bonus: number,
}

type Slot = {
	result: Result,

	aspect: number,

	centre: Vector2,
	cell: Vector2,

	holder: Frame,

	egg: ViewportFrame,
	eggScale: UIScale,
	pet: ViewportFrame,
	petScale: UIScale,
	glow: ImageLabel,

	name: TextLabel,
	rarity: TextLabel,
	bonus: TextLabel,

	phase: number,

	opened: boolean,
}

type Fleck = {
	frame: GuiObject,
	at: Vector2,
	velocity: Vector2,
	rotation: number,
	spin: number,
	age: number,
	life: number,
}

type Spin = {
	camera: Camera,
	base: CFrame,
}

type Show = {
	Rolls: {Result},
	egg: string?,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Janitor = require(ReplicatedStorage.Packages.Janitor)
-- Hatch starts only after the legacy server acknowledges its durable receipt.
local Config = require(ReplicatedStorage.Modules.Config)
local Egg = require(ReplicatedStorage.Modules.Egg)
local Pet = require(ReplicatedStorage.Modules.Pet)
local Limited = require(ReplicatedStorage.Config.LimitedEggConfig)
local MenuClient = require(script.Parent.MenuClient)
-- Foreign purchase UI/IDs are not loaded.

local GUI_NAME = "HatchGui"
local EGG_PATH = { "Assets", "RGBEgg" }
local WAIT_TIMEOUT = 10

local DISPLAY_ORDER = 20

local KNOCKING = "knocking"
local OPENING = "opening"
local DONE = "done"

local TEXT_FONT = Font.fromEnum(Enum.Font.GothamBlack)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)

local THINNEST_STROKE = 1

local UNTINTED = Color3.new(1, 1, 1)

local NAME_MIDDLE = 0.09
local VIEWPORT_MIDDLE = 0.4
local VIEWPORT_HEIGHT = 0.56
local RARITY_MIDDLE = 0.755
local BONUS_MIDDLE = 0.91

local HINT_MIDDLE = 0.95
local HINT_WIDTH = 0.5
local HINT_HEIGHT = 0.06

local NARROWEST = 0.04

local HOME = UDim2.fromScale(0.5, 0.5)

local TAU = 2 * math.pi

local SWING_INFO = TweenInfo.new(Config.Hatch.shakeSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local PUNCH_INFO = TweenInfo.new(Config.Hatch.shakeSeconds * 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP_INFO = TweenInfo.new(Config.Hatch.popSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local REVEAL_INFO = TweenInfo.new(Config.Hatch.revealSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local CHARGE_INFO = TweenInfo.new(Config.Hatch.Charge.seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local CHARGE_SWING_INFO = TweenInfo.new(Config.Hatch.Charge.swingSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local SHADE_INFO = TweenInfo.new(Config.Hatch.shadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GLOW_INFO = TweenInfo.new(Config.Hatch.Burst.glowSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_IN_INFO = TweenInfo.new(Config.Hatch.Burst.flashRiseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLASH_OUT_INFO = TweenInfo.new(Config.Hatch.Burst.flashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TEXT_INFO = TweenInfo.new(Config.Hatch.Pop.seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local HatchClient = {}

local Pending: {Show} = {}
local playVerified: ({Result}, string?) -> boolean
local shownLimited: {[string]: boolean} = {} -- Session-only visual deduplication, never a save/grant marker.

local Slots: {Slot} = {}
local Cameras: {Spin} = {}
local Flecks: {Fleck} = {}

local janitor = Janitor.new()

local eggTemplate: Instance? = nil
local hint: TextLabel? = nil
local hintScale: UIScale? = nil
local stage: string? = nil
local knocks = 0

local shade: TextButton? = nil
local flash: Frame? = nil
local board: Frame? = nil
local burst: Frame? = nil

local screen = Vector2.one

local shakeStrength = 0
local shakeSpan = 0
local shakeUntil = 0

local fanfared = false

local knockSound: Sound? = nil
local crackSound: Sound? = nil
local rareSound: Sound? = nil

local shows = 0

local playToken = 0

local function waitForPath(root: Instance, path: {string}): Instance?
	local current: Instance? = root
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):WaitForChild(name, WAIT_TIMEOUT)
	end

	return current
end

local function waitForSound(path: {string}): Sound?
	local found = waitForPath(SoundService, path)
	if found and found:IsA("Sound") then return found end

	warn(`[HatchClient] could not find {SoundService:GetFullName()}.{table.concat(path, ".")}`)

	return nil
end

local function playSound(sound: Sound?, pitch: number, volume: number)
	if not sound then return end

	local clone = sound:Clone()
	clone.PlaybackSpeed = sound.PlaybackSpeed * pitch
	clone.Volume = sound.Volume * volume
	clone.Parent = SoundService

	clone:Play()

	task.delay(Config.Hatch.Sounds.lifeSeconds, function()
		clone:Destroy()
	end)
end

local function strokeWidth(): number
	local camera = Workspace.CurrentCamera
	if not camera then return THINNEST_STROKE end

	return math.max(camera.ViewportSize.Y * Config.Hatch.strokeShare, THINNEST_STROKE)
end

local function newLabel(parent: Instance, position: UDim2, width: number, height: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = position
	label.Size = UDim2.fromScale(width, height)
	label.FontFace = TEXT_FONT
	label.TextScaled = true
	label.TextColor3 = TEXT_COLOR

	label.Text = ""
	label.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = strokeWidth()
	stroke.Parent = label

	local scale = Instance.new("UIScale")
	scale.Parent = label

	return label
end

local function pop(label: TextLabel)
	local settings = Config.Hatch.Pop

	local scale = label:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = settings.from
		TweenService:Create(scale, TEXT_INFO, { Scale = 1 }):Play()
	end

	label.TextTransparency = 1
	TweenService:Create(label, TEXT_INFO, { TextTransparency = 0 }):Play()

	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not stroke then return end

	stroke.Transparency = 1
	TweenService:Create(stroke, TEXT_INFO, { Transparency = 0 }):Play()
end

local function mount(viewport: ViewportFrame, template: Instance, zoom: number, aspect: number)
	local model: Model

	if template:IsA("Model") then
		model = template:Clone()
	elseif template:IsA("BasePart") then
		model = Instance.new("Model")

		local part = template:Clone()
		part.Parent = model
		model.PrimaryPart = part
	else
		warn(`[HatchClient] {template:GetFullName()} is neither a model nor a part`)
		return
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("LayerCollector") then
			part:Destroy()
			continue
		end

		if not part:IsA("BasePart") then continue end

		part.Anchored = true
		part.CanCollide = false
	end

	local limitedSize = Pet.prepareLimited(model,template.Name,nil,false)
	local size: Vector3
	if limitedSize then
		size=limitedSize
	else
		-- Preserve the original path for the existing purchased Pets and Eggs.
		local primary = model.PrimaryPart
		if primary then primary.CFrame = CFrame.new(primary.Position) end
		local box
		box,size = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() - box.Position)
	end

	local settings = Config.Hatch

	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.fieldOfView

	local reach = math.max(size.X, size.Y, size.Z) / 2

	local fit = math.tan(math.rad(settings.fieldOfView / 2)) * math.min(aspect, 1)
	local distance = reach / fit * zoom
	if limitedSize then
		-- A bounding sphere also fits the existing rotating camera, at every angle.
		distance=(size.Magnitude/2)/math.sin(math.atan(fit))*math.max(zoom,1)
	end
	local base = CFrame.lookAt(Vector3.new(0, 0, distance), Vector3.zero)

	camera.CFrame = base
	camera.Parent = viewport

	viewport.CurrentCamera = camera
	model.Parent = viewport

	table.insert(Cameras, { camera = camera, base = base })
end

local function paint(label: TextLabel, petName: string)
	local Run = Pet.colors(petName)
	if not Run then return end

	label.TextColor3 = UNTINTED

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = Config.Inventory.gradientRotation
	gradient.Color = Pet.sequence(Run)
	gradient.Parent = label
end

local function across(share: number): number
	if screen.X <= 0 then return share end

	return share * screen.Y / screen.X
end

local function square(share: number): UDim2
	return UDim2.fromScale(across(share), share)
end

local function colorsOf(petName: string): {Color3}
	return Pet.colors(petName) or { UNTINTED }
end

local function ring(at: Vector2, color: Color3, shape: {[string]: any})
	local layer = burst
	if not layer then return end

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(at.X, at.Y)
	frame.Size = square(shape.ringFrom)
	frame.BackgroundTransparency = 1
	frame.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = math.max(screen.Y * shape.ringThickness, THINNEST_STROKE)
	stroke.Transparency = shape.ringTransparency
	stroke.Parent = frame

	local info = TweenInfo.new(shape.ringSeconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	TweenService:Create(frame, info, { Size = square(shape.ringTo) }):Play()
	TweenService:Create(stroke, info, { Transparency = 1, Thickness = THINNEST_STROKE }):Play()

	task.delay(shape.ringSeconds, function()
		frame:Destroy()
	end)
end

local function fleck(at: Vector2, color: Color3, strength: number)
	local layer = burst
	if not layer then return end

	local settings = Config.Hatch.Burst

	local size = settings.fleckSize * (1 + (math.random() * 2 - 1) * settings.fleckVary)

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(at.X, at.Y)
	frame.Size = square(size)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Rotation = math.random() * 360
	frame.Parent = layer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(settings.fleckCorner, 0)
	corner.Parent = frame

	local angle = math.random() * TAU
	local speed = settings.speed * strength * (settings.least + math.random() * (1 - settings.least))

	table.insert(Flecks, {
		frame = frame,
		at = at,
		velocity = Vector2.new(across(math.cos(angle) * speed), math.sin(angle) * speed),
		rotation = frame.Rotation,
		spin = (math.random() * 2 - 1) * settings.spin,
		age = 0,
		life = settings.life * (1 + (math.random() * 2 - 1) * settings.lifeVary),
	})
end

local function throw(strength: number, seconds: number)
	shakeStrength = math.max(shakeStrength, strength)
	shakeSpan = seconds
	shakeUntil = os.clock() + seconds
end

local function drift()
	local frame = board
	if not frame then return end

	local left = shakeUntil - os.clock()

	if left <= 0 or shakeSpan <= 0 then
		shakeStrength = 0

		if frame.Position ~= HOME then
			frame.Position = HOME
		end

		return
	end

	local amount = shakeStrength * (left / shakeSpan) ^ Config.Hatch.Knock.fade

	frame.Position = UDim2.fromScale(
		0.5 + across((math.random() * 2 - 1) * amount),
		0.5 + (math.random() * 2 - 1) * amount
	)
end

local function breathe()
	local settings = Config.Hatch.Idle
	local glow = Config.Hatch.Burst
	local now = os.clock()

	for _, slot in ipairs(Slots) do
		local bob = math.sin((now / settings.bobSeconds + slot.phase) * TAU) * settings.bob

		slot.holder.Position = UDim2.fromScale(0.5, 0.5 + bob)
		slot.holder.Rotation = math.sin((now / settings.swaySeconds + slot.phase) * TAU) * settings.sway

		if not slot.opened then continue end

		slot.glow.Rotation = (now * glow.glowSpin) % 360
	end

	local scale = hintScale
	if not scale then return end

	scale.Scale = 1 + math.sin(now / settings.hintSeconds * TAU) * settings.hintPulse
end

local function stepFlecks(delta: number)
	local settings = Config.Hatch.Burst

	for index = #Flecks, 1, -1 do
		local piece = Flecks[index]

		piece.age += delta

		if piece.age >= piece.life then
			piece.frame:Destroy()
			table.remove(Flecks, index)
			continue
		end

		piece.velocity *= math.exp(-settings.drag * delta)
		piece.velocity += Vector2.new(0, settings.gravity * delta)
		piece.at += piece.velocity * delta
		piece.rotation += piece.spin * delta

		piece.frame.Position = UDim2.fromScale(piece.at.X, piece.at.Y)
		piece.frame.Rotation = piece.rotation

		local left = 1 - piece.age / piece.life
		piece.frame.BackgroundTransparency = if left >= settings.fade then 0 else 1 - left / settings.fade
	end
end

local function flashScreen(color: Color3)
	local frame = flash
	if not frame then return end

	local settings = Config.Hatch.Burst

	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 1

	TweenService:Create(frame, FLASH_IN_INFO, { BackgroundTransparency = settings.flashTransparency }):Play()

	task.delay(settings.flashRiseSeconds, function()
		if not frame.Parent then return end

		TweenService:Create(frame, FLASH_OUT_INFO, { BackgroundTransparency = 1 }):Play()
	end)
end

local function fanfare(rarity: string, petName: string)
	if fanfared then return end
	if not Config.Hatch.Fanfare[rarity] then return end

	fanfared = true

	flashScreen(colorsOf(petName)[1])
	playSound(rareSound, 1, Config.Hatch.Sounds.rareVolume)
end

local function explode(slot: Slot, token: number)
	local settings = Config.Hatch.Burst
	local Run = colorsOf(slot.result.pet)

	for index = 1, settings.rings do
		local color = Run[(index - 1) % #Run + 1]

		task.delay((index - 1) * settings.ringGap, function()
			if playToken ~= token then return end

			ring(slot.centre, color, settings)
		end)
	end

	for index = 1, settings.flecks do
		fleck(slot.centre, Run[(index - 1) % #Run + 1], 1)
	end

	slot.glow.ImageColor3 = Run[1]

	TweenService:Create(slot.glow, GLOW_INFO, { ImageTransparency = settings.glowTransparency }):Play()
end

local function knock(slot: Slot, token: number, strength: number)
	local settings = Config.Hatch

	TweenService:Create(slot.eggScale, PUNCH_INFO, { Scale = 1 + (settings.punch - 1) * strength }):Play()

	for index = 1, settings.shakeSwings do
		if playToken ~= token then return end

		local angle = settings.shakeAngle * strength
		local swing = TweenService:Create(slot.egg, SWING_INFO, {
			Rotation = if index % 2 == 1 then angle else -angle,
		})

		swing:Play()
		swing.Completed:Wait()
	end

	if playToken ~= token then return end

	TweenService:Create(slot.egg, SWING_INFO, { Rotation = 0 }):Play()
	TweenService:Create(slot.eggScale, PUNCH_INFO, { Scale = 1 }):Play()
end

local function knockAll(index: number)
	local settings = Config.Hatch
	local knocking = settings.Knock
	local sounds = settings.Sounds
	local token = playToken

	local strength = 1 + (index - 1) * knocking.grow

	for _, slot in ipairs(Slots) do
		task.spawn(knock, slot, token, strength)

		ring(slot.centre, knocking.color, knocking)

		for _ = 1, knocking.flecks do
			fleck(slot.centre, knocking.color, strength)
		end
	end

	throw(knocking.shake * strength, knocking.shakeSeconds)

	playSound(knockSound, sounds.knockPitch + (index - 1) * sounds.knockStep, sounds.knockVolume)
end

local function shudder(slot: Slot, token: number)
	local settings = Config.Hatch.Charge

	TweenService:Create(slot.eggScale, CHARGE_INFO, { Scale = settings.scale }):Play()

	local swings = math.max(math.floor(settings.seconds / settings.swingSeconds), 1)

	for index = 1, swings do
		if playToken ~= token then return end

		local angle = settings.angle * (index / swings)
		local swing = TweenService:Create(slot.egg, CHARGE_SWING_INFO, {
			Rotation = if index % 2 == 1 then angle else -angle,
		})

		swing:Play()
		swing.Completed:Wait()
	end
end

local function reveal(slot: Slot, token: number, index: number)
	local settings = Config.Hatch
	local sounds = settings.Sounds
	local result = slot.result

	TweenService:Create(slot.eggScale, POP_INFO, { Scale = 0 }):Play()

	playSound(crackSound, sounds.crackPitch + (index - 1) * sounds.crackStep, sounds.crackVolume)

	task.delay(settings.popSeconds, function()
		if playToken ~= token then return end

		slot.egg.Visible = false
		slot.opened = true

		local model = Pet.model(result.pet)
		if model then
			mount(slot.pet, model, settings.zoom, slot.aspect)
		else
			warn(`[HatchClient] could not find a model for {result.pet}`)
		end

		slot.pet.Visible = true
		TweenService:Create(slot.petScale, REVEAL_INFO, { Scale = 1 }):Play()

		explode(slot, token)

		slot.name.Text = string.format(settings.nameFormat, result.pet, result.percent)
		pop(slot.name)

		local rarity = Pet.rarity(result.pet)
		if rarity then
			slot.rarity.Text = rarity
			paint(slot.rarity, result.pet)
			pop(slot.rarity)

			fanfare(rarity, result.pet)
		end

		-- Duplicate copies are retained in the inventory; no Speed conversion.
	end)
end

local function open()
	local settings = Config.Hatch
	local charge = settings.Charge
	local token = playToken

	stage = OPENING

	local label = hint
	if label then
		label.Text = ""
	end

	local dim = shade
	if dim then
		TweenService:Create(dim, SHADE_INFO, { BackgroundTransparency = settings.openShade }):Play()
	end

	for _, slot in ipairs(Slots) do
		task.spawn(shudder, slot, token)
	end

	throw(charge.shake, charge.seconds)

	playSound(knockSound, settings.Sounds.chargePitch, settings.Sounds.chargeVolume)

	task.delay(charge.seconds, function()
		if playToken ~= token then return end

		for index, slot in ipairs(Slots) do
			task.delay((index - 1) * settings.stagger, function()
				if playToken ~= token then return end

				reveal(slot, token, index)
			end)
		end
	end)

	local last = charge.seconds
		+ (#Slots - 1) * settings.stagger
		+ settings.popSeconds
		+ settings.revealSeconds

	task.delay(last, function()
		if playToken ~= token then return end

		stage = DONE

		local closing = hint
		if not closing then return end

		closing.Text = settings.closeHint
		pop(closing)
	end)
end

local function clear()
	janitor:Cleanup()
	table.clear(Slots)
	table.clear(Cameras)
	table.clear(Flecks)

	playToken += 1
	stage = nil
	hint = nil
	hintScale = nil
	shade = nil
	flash = nil
	board = nil
	burst = nil
	fanfared = false
	shakeStrength = 0
	shakeUntil = 0
end

local function finish()
	clear()

	shows += 1

	MenuClient.shroud(false)

	local queued = table.remove(Pending, 1)
	if not queued then return end

	playVerified(queued.Rolls, queued.egg)
end

local function pressed()
	if stage == KNOCKING then
		knocks -= 1

		knockAll(Config.Hatch.clicks - knocks)

		if knocks > 0 then return end

		open()
		return
	end

	if stage ~= DONE then return end

	finish()
end

local function templateFor(name: string?): Instance?
	if not name then return eggTemplate end
	if not Egg.isEgg(name) then return eggTemplate end

	local folder = Workspace:FindFirstChild(Egg.FolderName)
	local model = folder and folder:FindFirstChild(name)

	if not model then return eggTemplate end

	return model
end

local function layout(count: number): (number, number, Vector2)
	local settings = Config.Hatch

	local best, bestRows, bestColumns = 0, 1, count

	for rows = 1, count do
		local columns = math.ceil(count / rows)

		local across = (settings.spread - settings.gap * (columns - 1)) / (columns * settings.width)
		local down = (settings.tall - settings.rowGap * (rows - 1)) / (rows * settings.height)

		local scale = math.min(across, down, 1)
		if scale <= best then continue end

		best, bestRows, bestColumns = scale, rows, columns
	end

	local width = math.max(settings.width * best, NARROWEST)

	return bestColumns, bestRows, Vector2.new(width, settings.height * (width / settings.width))
end

local function build(Results: {Result}, eggName: string?): boolean
	local playerGui = Player:FindFirstChildOfClass("PlayerGui")
	local template = templateFor(eggName)
	if not (playerGui and template) then return false end

	local settings = Config.Hatch

	local camera = Workspace.CurrentCamera
	screen = if camera and camera.ViewportSize.Y > 0 then camera.ViewportSize else Vector2.one

	local gui = janitor:Add(Instance.new("ScreenGui"))
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = DISPLAY_ORDER

	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local catcher = Instance.new("TextButton")
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.BackgroundColor3 = Color3.new(0, 0, 0)
	catcher.BackgroundTransparency = settings.shade
	catcher.AutoButtonColor = false
	catcher.Text = ""
	catcher.Parent = gui

	shade = catcher

	local lit = Instance.new("Frame")
	lit.Size = UDim2.fromScale(1, 1)
	lit.BackgroundColor3 = UNTINTED
	lit.BackgroundTransparency = 1
	lit.BorderSizePixel = 0
	lit.Parent = catcher

	flash = lit

	local stack = Instance.new("Frame")
	stack.AnchorPoint = Vector2.new(0.5, 0.5)
	stack.Position = HOME
	stack.Size = UDim2.fromScale(1, 1)
	stack.BackgroundTransparency = 1
	stack.Parent = catcher

	board = stack

	local sparks = Instance.new("Frame")
	sparks.Size = UDim2.fromScale(1, 1)
	sparks.BackgroundTransparency = 1
	sparks.Parent = catcher

	burst = sparks

	local count = #Results
	local columns, rows, cell = layout(count)

	local stepX = cell.X + settings.gap
	local stepY = cell.Y + settings.rowGap

	local labelWidth = math.min(settings.labelWidth, stepX / cell.X)

	local aspect = (cell.X * screen.X) / (cell.Y * VIEWPORT_HEIGHT * screen.Y)

	for index, result in ipairs(Results) do
		local line = math.ceil(index / columns)
		local column = index - (line - 1) * columns

		local held = math.min(columns, count - (line - 1) * columns)

		local x = 0.5 + (column - (held + 1) / 2) * stepX
		local y = settings.middle + (line - (rows + 1) / 2) * stepY

		if rows == 1 then
			y += if index % 2 == 0 then settings.wave else -settings.wave
		end

		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(x, y)
		frame.Size = UDim2.fromScale(cell.X, cell.Y)
		frame.Parent = stack

		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromScale(1, 1)
		holder.Parent = frame

		local glow = Instance.new("ImageLabel")
		glow.BackgroundTransparency = 1
		glow.Image = settings.Burst.glowTexture
		glow.ImageTransparency = 1
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromScale(0.5, VIEWPORT_MIDDLE)
		glow.Size = UDim2.fromScale(settings.Burst.glowSize, VIEWPORT_HEIGHT * settings.Burst.glowSize)
		glow.Parent = holder

		local egg = Instance.new("ViewportFrame")
		egg.BackgroundTransparency = 1
		egg.AnchorPoint = Vector2.new(0.5, 0.5)
		egg.Position = UDim2.fromScale(0.5, VIEWPORT_MIDDLE)
		egg.Size = UDim2.fromScale(1, VIEWPORT_HEIGHT)
		egg.Parent = holder

		local eggScale = Instance.new("UIScale")
		eggScale.Parent = egg

		local pet = Instance.new("ViewportFrame")
		pet.BackgroundTransparency = 1
		pet.AnchorPoint = Vector2.new(0.5, 0.5)
		pet.Position = UDim2.fromScale(0.5, VIEWPORT_MIDDLE)
		pet.Size = UDim2.fromScale(1, VIEWPORT_HEIGHT)
		pet.Visible = false
		pet.Parent = holder

		local petScale = Instance.new("UIScale")
		petScale.Scale = 0
		petScale.Parent = pet

		mount(egg, template, settings.eggZoom, aspect)

		table.insert(Slots, {
			result = result,
			aspect = aspect,

			centre = Vector2.new(x, y + (VIEWPORT_MIDDLE - 0.5) * cell.Y),
			cell = cell,

			holder = holder,
			egg = egg,
			eggScale = eggScale,
			pet = pet,
			petScale = petScale,
			glow = glow,

			name = newLabel(frame, UDim2.fromScale(0.5, NAME_MIDDLE), labelWidth, settings.nameHeight),
			rarity = newLabel(frame, UDim2.fromScale(0.5, RARITY_MIDDLE), labelWidth, settings.rarityHeight),
			bonus = newLabel(frame, UDim2.fromScale(0.5, BONUS_MIDDLE), labelWidth, settings.bonusHeight),

			phase = (index - 1) * settings.Idle.phase,
			opened = false,
		})
	end

	local label = newLabel(catcher, UDim2.fromScale(0.5, HINT_MIDDLE), HINT_WIDTH, HINT_HEIGHT)
	label.Text = settings.clickHint
	label.Parent = catcher

	hint = label
	hintScale = label:FindFirstChildOfClass("UIScale")

	janitor:Add(catcher.Activated:Connect(pressed))

	janitor:Add(RunService.RenderStepped:Connect(function(delta: number)
		local turn = CFrame.Angles(0, os.clock() / settings.spinSeconds * TAU, 0)

		for _, spin in ipairs(Cameras) do
			spin.camera.CFrame = turn * spin.base
		end

		breathe()
		drift()
		stepFlecks(delta)
	end))

	return true
end

function HatchClient.playing(): boolean
	return stage ~= nil
end

function HatchClient.shown(): number
	return shows
end

playVerified = function(Results: {Result}, eggName: string?): boolean
	if type(Results) ~= "table" then return false end

	local egg = if type(eggName) == "string" and eggName ~= "" then eggName else nil

	local Rolls: {Result} = {}

	for _, entry in ipairs(Results) do
		if type(entry) ~= "table" then continue end
		if type(entry.pet) ~= "string" then continue end

		table.insert(Rolls, {
			pet = entry.pet,
			percent = if type(entry.percent) == "number" then entry.percent else 0,
			duplicate = false, -- Every copy is retained; no duplicate-Speed conversion.
			bonus = 0,
		})
	end

	if #Rolls == 0 then return false end

	if stage then
		table.insert(Pending, { Rolls = Rolls, egg = egg })
		return true
	end

	playToken += 1
	stage = KNOCKING
	knocks = Config.Hatch.clicks

	MenuClient.shroud(true)

	if build(Rolls, egg) then return true end

	clear()

	shows += 1

	MenuClient.shroud(false)
	return false
end

function HatchClient.play(Results: {Result}, eggName: string?)
 -- Regular Win-Egg acknowledgements must not start a paid limited reveal.
 if type(Results)~="table" then return false end
 for _,result in Results do
  if type(result)=="table" and Pet.isLimited(result.pet) then return false end
 end
 return playVerified(Results,eggName)
end

-- Reserved consumer for a FUTURE trusted server post-save notification.
-- Only ReceiptService's server-confirmed LimitedEggCommitted notification calls this.
-- The purchase-finished event and inventory refresh never grant or reveal a receipt.
function HatchClient.playCommittedLimited(notice)
 if type(notice)~="table" or notice.Saved~=true or notice.Status~="Granted" then
  return false,"NotCommitted"
 end
 local purchaseId=notice.PurchaseId
 if notice.ProductId~=Limited.ProductId or type(purchaseId)~="string" or #purchaseId==0 or #purchaseId>128 then
  return false,"InvalidReceipt"
 end
 local result=notice.Result
 if type(result)~="table" or type(result.pet)~="string" or type(result.id)~="string" or #result.id==0 then
  return false,"InvalidResult"
 end
 local entry=Limited.ByName[result.pet]
 if not entry or result.percent~=entry.Percent or not Pet.model(result.pet) then return false,"InvalidResult" end
 local state=Pet.NormalizeState(notice.State)
 if not state or state.Owned[result.id]~=result.pet then return false,"ResultNotOwned" end
 if shownLimited[purchaseId] then return false,"AlreadyShown" end
 shownLimited[purchaseId]=true -- Claim before building/queueing so repeats cannot race.
 local ok,accepted=pcall(playVerified,{{pet=result.pet,percent=entry.Percent,duplicate=false,bonus=0}},nil)
 if not ok or not accepted then
  shownLimited[purchaseId]=nil
  if not ok then clear();MenuClient.shroud(false);warn("[HatchClient] Limited display failed: "..tostring(accepted)) end
  return false,"PresentationUnavailable"
 end
 return true,"Queued"
end

function HatchClient.start()
	eggTemplate = waitForPath(ReplicatedStorage, EGG_PATH)
	if not eggTemplate then
		warn(`[HatchClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(EGG_PATH, ".")}`)
	end

	local sounds = Config.Hatch.Sounds

	knockSound = waitForSound(sounds.knockPath)
	crackSound = waitForSound(sounds.crackPath)
	rareSound = waitForSound(sounds.rarePath)

end

return HatchClient
