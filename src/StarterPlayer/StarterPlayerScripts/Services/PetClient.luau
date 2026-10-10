local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Modules.Config)
local Pet = require(ReplicatedStorage.Modules.Pet)
local LimitedViewport = require(ReplicatedStorage.Modules.LimitedPetViewport)

local GUI_NAME = "ScreenGui"
local MENU_PATH = { "Menus", "Inventory" }
local ITEMS_PATH = { "Main", "Items" }

local INFO_PATH = { "Main", "2PetsEquipInfo" }
local ITEM_TEMPLATE_PATH = { "Assets", "Templates", "PetInventory" }
local CARD_TEMPLATE_PATH = { "Assets", "Templates", "PetHover" }
local ICONS_PATH = { "Assets", "Icons", "Pets" }
local MAIN_NAME = "Main"
local STROKE_NAME = "Stroke"
local ICON_NAME = "Icon"
local CHECK_NAME = "Checkmark"
local TITLE_NAME = "Title"
local BUTTON_NAME = "Button"
local RARITY_NAME = "Rarity"
local DESCRIPTION_NAME = "Description"
local TEXT_NAME = "Text"
local SHADOW_SUFFIX = "Shadow"
local WAIT_TIMEOUT = 10

local NAME_NAME = "Name"

local CARD_ZINDEX = 10

local UNTINTED = Color3.new(1, 1, 1)

local CARD_INDEX = "card"

local PetClient = {}

local Tiles: {[string]: GuiObject} = {}

local janitor = Janitor.new()

local cardJanitor = Janitor.new()

local cardRoot: GuiObject? = nil
local playerData: any = nil -- validated legacy Pet state, never purchased Data
local pending = false
local started = false
local bootstrapped = false
local remote: RemoteFunction? = nil
local itemTemplate: Instance? = nil
local cardTemplate: Instance? = nil
local icons: Instance? = nil
local menu: GuiObject? = nil
local itemsFrame: GuiObject? = nil
local infoLabel: GuiObject? = nil

local shown = true

local function findPath(root: Instance, path: {string}): Instance?
	local current: Instance? = root
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):FindFirstChild(name)
	end

	return current
end

local function waitForPath(root: Instance, path: {string}): Instance?
	local current: Instance? = root
	for _, name in ipairs(path) do
		if not current then return nil end
		current = (current :: Instance):WaitForChild(name, WAIT_TIMEOUT)
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

local function lighten(color: Color3, amount: number): Color3
	return color:Lerp(UNTINTED, amount)
end

local function darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

local function shifted(Run: {Color3}, blend: (Color3) -> Color3): {Color3}
	local Out: {Color3} = {}

	for index, color in ipairs(Run) do
		Out[index] = blend(color)
	end

	return Out
end

local function setGradient(holder: Instance?, Run: {Color3}, rotation: number)
	if not holder then return end

	local gradient = holder:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Parent = holder
	end

	gradient.Rotation = rotation
	gradient.Color = Pet.sequence(Run)
end

local function tint(tile: Instance, name: string)
	local Run = Pet.colors(name)
	if not Run then return end

	local settings = Config.Inventory

	local rotation = settings.gradientRotation

	local main = tile:FindFirstChild(MAIN_NAME)
	if main then
		setGradient(main, Run, rotation)
		setGradient(main:FindFirstChildOfClass("UIStroke"), shifted(Run, function(color: Color3): Color3
			return lighten(color, settings.tileLighten)
		end), rotation)
	end

	local stroke = tile:FindFirstChild(STROKE_NAME)
	if not stroke then return end

	local Dark = shifted(Run, function(color: Color3): Color3
		return darken(color, settings.tileDarken)
	end)

	setGradient(stroke, Dark, rotation)

	if stroke:IsA("GuiObject") then
		stroke.BackgroundColor3 = Dark[#Dark]
	end
end

local function cursor(): Vector2
	local inset = GuiService:GetGuiInset()
	local mouse = UserInputService:GetMouseLocation()

	return Vector2.new(mouse.X - inset.X, mouse.Y - inset.Y)
end

function PetClient.moveCard()
	local card = cardJanitor:Get(CARD_INDEX)
	local root = cardRoot
	if not (card and root) then return end

	local size = root.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end

	local point = cursor() - root.AbsolutePosition
	local settings = Config.Inventory

	card.Position = UDim2.fromScale(
		math.clamp(point.X / size.X + settings.hoverOffsetX, 0, 1 - card.Size.X.Scale),
		math.clamp(point.Y / size.Y + settings.hoverOffsetY, 0, 1 - card.Size.Y.Scale)
	)
end

function PetClient.hideCard()
	cardJanitor:Remove(CARD_INDEX)
	cardRoot = nil
end

function PetClient.showCard(name: string, root: GuiObject)
	local template = cardTemplate
	if not (root and template) then return end

	cardRoot = root

	local card = cardJanitor:Add(template:Clone(), "Destroy", CARD_INDEX)
	card.ZIndex = CARD_ZINDEX

	card.AnchorPoint = Vector2.zero

	setPair(card, NAME_NAME, name)

	local rarity = Pet.rarity(name)
	local label = card:FindFirstChild(RARITY_NAME)
	if rarity and label and label:IsA("TextLabel") then
		setPair(card, RARITY_NAME, rarity)

		local gradient = label:FindFirstChildOfClass("UIGradient")
		local Run = Pet.colors(name)
		if gradient and Run then
			label.TextColor3 = UNTINTED

			gradient.Rotation = Pet.rotation(name)
			gradient.Color = Pet.sequence(Run)
		end
	end

	if LimitedViewport.supports(name) then
		for _,key in {RARITY_NAME,RARITY_NAME..SHADOW_SUFFIX} do
			local old=card:FindFirstChild(key) if old and old:IsA("GuiObject") then old.Visible=false end
		end
	end
	local description = card:FindFirstChild(DESCRIPTION_NAME)
	if description then
		setPair(description, TEXT_NAME, "Cosmetic pet")
		local icon = description:FindFirstChild(ICON_NAME)
		if icon and icon:IsA("GuiObject") then icon.Visible = false end
	end

	card.Parent = root

	PetClient.moveCard()
end

function PetClient.placeCard(position: UDim2, size: UDim2?)
	local card = cardJanitor:Get(CARD_INDEX)
	if not card then return end

	if size then
		card.Size = size
	end

	card.Position = UDim2.fromScale(
		math.clamp(position.X.Scale, 0, math.max(0, 1 - card.Size.X.Scale)),
		math.clamp(position.Y.Scale, 0, math.max(0, 1 - card.Size.Y.Scale))
	)
end

function PetClient.pinCard(name: string, root: GuiObject, position: UDim2, size: UDim2?, zIndex: number?)
	PetClient.showCard(name, root)

	cardRoot = nil

	local card = cardJanitor:Get(CARD_INDEX)
	if card and zIndex then
		card.ZIndex = zIndex
	end

	PetClient.placeCard(position, size)
end

local function refreshChecks()
	local Equipped = if playerData then playerData.Equipped else {}
	local count = if Equipped[1] and Equipped[1] ~= "" then 1 else 0
	setText(infoLabel, `Equipped ({count}/{Pet.MaxEquipped})`)

	for name, tile in Tiles do
		local main = tile:FindFirstChild(MAIN_NAME)
		local check = if main then main:FindFirstChild(CHECK_NAME) else nil
		if not (check and check:IsA("GuiObject")) then continue end

		local visible = table.find(Equipped, name) ~= nil
		if check.Visible == visible then continue end

		check.Visible = visible
	end
end

local function buildTile(id: string, name: string, order: number): GuiObject?
	local template = itemTemplate
	if not template then return nil end

	local tile = janitor:Add(template:Clone())
	tile.Name = id
	tile.Visible = shown

	tile.LayoutOrder = order

	setPair(tile, TITLE_NAME, name)

	local main = tile:FindFirstChild(MAIN_NAME)
	if main then
		local icon = main:FindFirstChild(ICON_NAME)
		local decal = if icons then icons:FindFirstChild(name) else nil
		if icon and icon:IsA("ImageLabel") and LimitedViewport.supports(name) then
			janitor:Add(LimitedViewport.bind(icon,name),true)
		elseif icon and icon:IsA("ImageLabel") and decal and decal:IsA("Decal") then
			icon.Image = decal.Texture
		else
			warn(`[PetClient] could not find {table.concat(ICONS_PATH, ".")}.{name}`)
		end
	end

	tint(tile, name)

	local button = tile:FindFirstChild(BUTTON_NAME)
	if not (button and button:IsA("GuiButton")) then
		warn(`[PetClient] could not find {tile:GetFullName()}.{BUTTON_NAME}`)
		return tile
	end

	janitor:Add(button.Activated:Connect(function()
		task.spawn(PetClient.request, "Equip", id)
	end))

	janitor:Add(button.MouseEnter:Connect(function()
		local root = menu
		if not root then return end

		PetClient.showCard(name, root)
	end))

	janitor:Add(button.MouseMoved:Connect(PetClient.moveCard))
	janitor:Add(button.MouseLeave:Connect(PetClient.hideCard))

	return tile
end

function PetClient.setShown(on: boolean)
	shown = on

	local info = infoLabel
	if info and info.Visible ~= on then
		info.Visible = on
	end

	for _, tile in Tiles do
		if tile.Visible == on then continue end

		tile.Visible = on
	end
end

local function rebuild()
	janitor:Cleanup()
	table.clear(Tiles)

	local root = itemsFrame
	if not root then return end

	local ids = {}
	for id in pairs(if playerData then playerData.Owned else {}) do table.insert(ids, id) end
	table.sort(ids, function(a, b)
		local left, right = playerData.Owned[a], playerData.Owned[b]
		return if left == right then a < b else left < right
	end)
	for order, id in ipairs(ids) do
		local name = playerData.Owned[id]
		local tile = buildTile(id, name, order)
		if not tile then continue end

		Tiles[id] = tile
		tile.Parent = root
	end

	refreshChecks()
end

local function bind(gui: ScreenGui)
	janitor:Cleanup()
	cardJanitor:Cleanup()
	table.clear(Tiles)

	cardRoot = nil
	menu = nil
	itemsFrame = nil
	infoLabel = nil

	local root = findPath(gui, MENU_PATH)
	if not (root and root:IsA("GuiObject")) then
		warn(`[PetClient] could not find {gui:GetFullName()}.{table.concat(MENU_PATH, ".")}`)
		return
	end

	local items = findPath(root, ITEMS_PATH)
	if not (items and items:IsA("GuiObject")) then
		warn(`[PetClient] could not find {root:GetFullName()}.{table.concat(ITEMS_PATH, ".")}`)
		return
	end

	menu = root
	itemsFrame = items

	local info = findPath(root, INFO_PATH)
	if info and info:IsA("GuiObject") then
		infoLabel = info
		info.Visible = shown
		info.AutoLocalize = false -- Do not translate using the retired two-pet caption.
	else
		warn(`[PetClient] could not find {root:GetFullName()}.{table.concat(INFO_PATH, ".")}`)
	end

	rebuild()
end

function PetClient.start()
	if started then return end
	started = true
	remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PetRequest") :: RemoteFunction

	itemTemplate = waitForPath(ReplicatedStorage, ITEM_TEMPLATE_PATH)
	if not itemTemplate then
		warn(`[PetClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(ITEM_TEMPLATE_PATH, ".")}`)
	end

	cardTemplate = waitForPath(ReplicatedStorage, CARD_TEMPLATE_PATH)
	if not cardTemplate then
		warn(`[PetClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(CARD_TEMPLATE_PATH, ".")}`)
	end

	icons = waitForPath(ReplicatedStorage, ICONS_PATH)
	if not icons then
		warn(`[PetClient] could not find {ReplicatedStorage:GetFullName()}.{table.concat(ICONS_PATH, ".")}`)
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

	Player:GetAttributeChangedSignal("PetInventoryRevision"):Connect(function()
		task.spawn(PetClient.refresh)
	end)
	task.spawn(function()
		while Player.Parent and not playerData do
			PetClient.refresh()
			if not playerData then task.wait(2) end
		end
	end)
end

function PetClient.state()
	return playerData
end

function PetClient.busy()
	return pending or Player:GetAttribute("PetSavePending")==true
end

local function accept(response)
	if type(response)~="table" or type(response.state)~="table" then return end
	local state=Pet.NormalizeState(response.state)
	if not state then return end
	if playerData and state.Revision<playerData.Revision then return end
	playerData=state
	rebuild()
end

function PetClient.refresh()
	if not remote then return end
	local ok,response=pcall(function() return remote:InvokeServer("GetState") end)
	if ok then accept(response) end
end

function PetClient.notify(reason)
	local messages={
		NotEnoughWin="Not enough Win.",DataNotLoaded="Player data is not ready.",
		DataSaving="Saving. Please wait.",InventorySavePending="Saving pets. Please wait.",
		TooFarFromEgg="Move closer to the Egg.",PetStateChanged="Pet inventory refreshed. Please try again.",
		StudioOverrideActive="Pet purchases are unavailable during a Studio data override.",
		PetRequestFailed="Unable to confirm the request. Please wait.",PleaseWait="Please wait.",
	}
	require(script.Parent.NotifyClient).push({{text=messages[reason] or "Pet request unavailable. Please try again."}})
end

function PetClient.request(action,a,b)
	if pending or not remote then return end
	if not playerData then PetClient.notify("DataNotLoaded");return end
	if require(script.Parent.HatchClient).playing() then return end
	pending=true
	local id=HttpService:GenerateGUID(false)
	local revision=playerData.Revision
	local reported=false
	while Player.Parent do
		local ok,response=pcall(function() return remote:InvokeServer(action,id,revision,a,b) end)
		if ok and type(response)=="table" then
			accept(response)
			if response.ok then
				-- Receipt identity prevents an unrelated refresh/retry from replaying Hatch.
				if action=="OpenEgg" and playerData and playerData.LastRequestId==id then
					require(script.Parent.HatchClient).play(playerData.LastResults,a)
				end
				pending=false
				return
			end
			if response.reason~="InventorySavePending" and response.reason~="PetRequestFailed" then
				pending=false
				PetClient.notify(response.reason)
				return
			end
		end
		-- Lost response: retry this exact ID/revision; never silently create another roll.
		if not reported then PetClient.notify("InventorySavePending");reported=true end
		task.wait(2)
	end
	pending=false
end

function PetClient.bootstrap()
	if bootstrapped then return end
	bootstrapped=true
	local gui=Player:WaitForChild("PlayerGui"):WaitForChild(GUI_NAME)
	-- Reuse only the purchased Pet menu and its original HUD button.
	for _,child in ipairs(gui:GetChildren()) do
		if child:IsA("GuiObject") then child.Visible=child.Name=="Left" end
	end
	local left=gui:WaitForChild("Left")
	for _,child in ipairs(left:GetChildren()) do
		if child:IsA("GuiObject") then child.Visible=child.Name=="Inventory" end
	end
	left.AnchorPoint=Vector2.new(1,0.5)
	left.Position=UDim2.new(1,-16,0.5,0)
	left.Size=UDim2.fromOffset(72,72)
	local aspect=left:FindFirstChildOfClass("UIAspectRatioConstraint")
	if aspect then aspect.AspectRatio=1 end
	local entry=left:WaitForChild("Inventory")
	entry.AnchorPoint=Vector2.zero
	entry.Position=UDim2.fromScale(0,0)
	entry.Size=UDim2.fromScale(1,1)
	setPair(entry,"Title","Pets")
	local menus=gui:WaitForChild("Menus")
	for _,child in ipairs(menus:GetChildren()) do
		if child:IsA("GuiObject") then child.Visible=false end
	end
	local inventory=menus:WaitForChild("Inventory")
	local tabs=inventory:FindFirstChild("Tabs")
	if tabs then
		for _,tab in ipairs(tabs:GetChildren()) do
			if tab:IsA("GuiObject") then tab.Visible=tab.Name=="Pets" end
		end
	end
	local main=inventory:WaitForChild("Main")
	local otherItems=main:FindFirstChild("ItemsTab")
	if otherItems and otherItems:IsA("GuiObject") then otherItems.Visible=false end
	-- No Trail, best-equip purchase, or other purchased inventory handlers are started.
	local menuClient=require(script.Parent.MenuClient)
	menuClient.init();menuClient.start()
	require(script.Parent.ButtonClient).start()
	require(script.Parent.NotifyClient).start()
	require(script.Parent.HatchClient).start()
	PetClient.start()
	require(script.Parent.PetFollowClient).start()
	require(script.Parent.EggClient).start()
	require(script.Parent.StandClient).start()
	gui.Enabled=true
end

return PetClient
