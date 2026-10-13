type Shoe = {
	model: Model,

	pivot: CFrame,
}

type Board = {
	gui: BillboardGui,

	offset: Vector3,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Modules.Config)

local SHOES_NAME = "ShoesModels"
local PADS_NAME = "PerStepButtons"
local BOARD_NAME = "BillboardGui"
local WAIT_TIMEOUT = 10

local FloatClient = {}

local Shoes: {[number]: Shoe} = {}
local Boards: {[number]: Board} = {}

local elapsed = 0

local function addShoe(model: Instance)
	if not model:IsA("Model") then return end

	local index = tonumber(model.Name)
	if not index then return end

	local shoe = Shoes[index]
	if shoe and shoe.model == model then return end

	Shoes[index] = { model = model, pivot = model:GetPivot() }
end

local function addBoard(model: Instance)
	if not model:IsA("Model") then return end

	local index = tonumber(model.Name)
	if not index then return end

	local gui = model:FindFirstChild(BOARD_NAME)
	if not (gui and gui:IsA("BillboardGui")) then return end

	local board = Boards[index]
	if board and board.gui == gui then return end

	Boards[index] = { gui = gui, offset = gui.StudsOffset }
end

local function advance(delta: number)
	local settings = Config.Float

	elapsed = (elapsed + delta) % settings.seconds

	local rise = settings.studs * (1 - math.cos(elapsed / settings.seconds * math.pi * 2)) / 2
	local lift = Vector3.yAxis * rise

	for _, shoe in Shoes do
		if not shoe.model.Parent then continue end

		-- Saved Dumbbell exhibits1..7 keep their authored transform.
		local index = tonumber(shoe.model.Name)
		if index and index >= 1 and index <= 7 and shoe.model:FindFirstChild("Bar") then continue end
		shoe.model:PivotTo(shoe.pivot + lift)
	end

	for _, board in Boards do
		if not board.gui.Parent then continue end

		board.gui.StudsOffset = board.offset + lift
	end
end

function FloatClient.start()
	local shoes = workspace:WaitForChild(SHOES_NAME, WAIT_TIMEOUT)
	if not shoes then
		warn(`[FloatClient] could not find {workspace:GetFullName()}.{SHOES_NAME}`)
		return
	end

	local pads = workspace:WaitForChild(PADS_NAME, WAIT_TIMEOUT)
	if not pads then
		warn(`[FloatClient] could not find {workspace:GetFullName()}.{PADS_NAME}`)
		return
	end

	for _, model in ipairs(shoes:GetChildren()) do
		addShoe(model)
	end

	for _, model in ipairs(pads:GetChildren()) do
		addBoard(model)
	end

	shoes.ChildAdded:Connect(addShoe)

	pads.DescendantAdded:Connect(function(descendant: Instance)
		if descendant.Name ~= BOARD_NAME then return end

		local model = descendant.Parent
		if not model then return end

		addBoard(model)
	end)

	RunService.Heartbeat:Connect(advance)
end

return FloatClient
