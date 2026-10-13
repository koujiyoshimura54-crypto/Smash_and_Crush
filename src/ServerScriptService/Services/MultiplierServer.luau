local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Modules.Config)
local Multiplier = require(ReplicatedStorage.Modules.Multiplier)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Data = require(ReplicatedStorage.Modules.Data).server

local FOLDER_NAME = "PerStepButtons"
local PRESS_NAME = "Press"
local BOARD_NAME = "BillboardGui"
local AMOUNT_NAME = "Amount"
local MAIN_NAME = "Main"
local PRICE_NAME = "Price"
local SHADOW_SUFFIX = "Shadow"
local ROOT_NAME = "HumanoidRootPart"

local AMOUNT_FORMAT = "+%s / Step"
local PRICE_FORMAT = "Requires %s Wins"

local STAND_REACH = 6

local TICK_SECONDS = 0.2

local MultiplierServer = {}

local Pads: {[number]: BasePart} = {}

local function setText(label: Instance?, text: string)
	if not (label and label:IsA("TextLabel")) then return end
	if label.Text == text then return end

	label.Text = text
end

local function setPair(root: Instance, name: string, text: string)
	setText(root:FindFirstChild(name), text)
	setText(root:FindFirstChild(name .. SHADOW_SUFFIX), text)
end

local function isInside(part: BasePart, position: Vector3): boolean
	local offset = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2

	if math.abs(offset.X) > half.X then return false end
	if math.abs(offset.Z) > half.Z then return false end

	return offset.Y >= -half.Y and offset.Y <= half.Y + STAND_REACH
end

local function stamp(model: Model, index: number)
 local board = model:FindFirstChild(BOARD_NAME)
 if not board then return end
 local master = require(ReplicatedStorage.Config.DumbbellItemMaster)
 local item = index >= 1 and index <= 7 and master.Get(string.format("NORMAL_%02d", index))
 local amount = board:FindFirstChild(AMOUNT_NAME)
 if amount then
  setPair(amount, MAIN_NAME, item and tostring(item.PriceWin) or "")
  local icon = amount:FindFirstChild("Icon")
  if icon and icon:IsA("ImageLabel") then
   icon.Image = game:GetService("StarterGui").StrengthGui.HUD.WinAmount.Inside.Icon.Image
   icon.Visible = item ~= nil and item ~= false
  end
 end
 setPair(board, PRICE_NAME, item and "+" .. tostring(item.StrengthBonus) or "")
end

local function buy(playerData: any, index: number, price: number): boolean
	local owned = playerData[Multiplier.OwnedField]
	if not owned then return false end

	local stored = owned()
	if type(stored) ~= "table" then return false end

	local key = tostring(index)
	if stored[key] == nil then
		warn(`[MultiplierServer] the profile carries no "{key}" to open`)
		return false
	end

	local paid = false

	playerData.wins(function(wins: number): number
		if wins < price then return wins end

		paid = true

		return wins - price
	end)

	if not paid then return false end

	owned[key](true)

	return true
end

local function press(playerData: any, index: number)
	local price = Multiplier.requirement(index)
	if not price then return end

	if not Multiplier.owned(playerData, index) then
		if not Multiplier.unlockable(playerData, index) then return end

		if not buy(playerData, index, price) then return end
	end

	if Multiplier.equipped(playerData) == index then return end

	playerData[Multiplier.EquippedField](index)
end

local function step()
	for _, player in ipairs(Players:GetPlayers()) do
		local playerData = Data[player]
		if not playerData then continue end

		local character = player.Character
		local root = character and character:FindFirstChild(ROOT_NAME)
		if not (root and root:IsA("BasePart")) then continue end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then continue end
		if humanoid.Health <= 0 then continue end

		for index, pad in Pads do
			if not isInside(pad, root.Position) then continue end

			press(playerData, index)
			break
		end
	end
end

function MultiplierServer.init()
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		warn(`[MultiplierServer] could not find {workspace:GetFullName()}.{FOLDER_NAME}`)
		return
	end

	for _, model in ipairs(folder:GetChildren()) do
		if not model:IsA("Model") then continue end

		local index = tonumber(model.Name)
		if not index then
			warn(`[MultiplierServer] {model:GetFullName()} is not named for a button`)
			continue
		end

		stamp(model, index)

		local pad = model:FindFirstChild(PRESS_NAME)
		if not (pad and pad:IsA("BasePart")) then
			warn(`[MultiplierServer] could not find {model:GetFullName()}.{PRESS_NAME}`)
			continue
		end

		Pads[index] = pad
	end
end

function MultiplierServer.start()
	while true do
		task.wait(TICK_SECONDS)
		step()
	end
end

return MultiplierServer
