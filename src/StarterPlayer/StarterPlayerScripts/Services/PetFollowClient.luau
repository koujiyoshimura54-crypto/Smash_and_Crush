type Follower = {
	name: string,

	position: Vector3?,

	yaw: number?,

	phase: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Config = require(ReplicatedStorage.Modules.Config)
local Pet = require(ReplicatedStorage.Modules.Pet)
local Trail = require(ReplicatedStorage.Modules.Trail)

local FOLDER_NAME = "Pets"
local ROOT_NAME = "HumanoidRootPart"

local ATTACHMENT_NAMES = { "Att0", "Att1" }
local DECORATION_NAME = "RarityTrail"

local PET_INDEX = "pet"

local EPSILON = 1e-4

local TAU = 2 * math.pi

local PetFollowClient = {}

local Followers: {[Player]: {[number]: Follower}} = {}

local Watched: {[Player]: any} = {}

local folder: Folder? = nil
local started = false

local function dress(model: Model)
	for _, part in ipairs(model:GetDescendants()) do
		if not part:IsA("BasePart") then continue end

		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
end

local function middleOf(part: BasePart): Vector3
	local total = Vector3.zero
	local found = 0

	for _, name in ipairs(ATTACHMENT_NAMES) do
		local attachment = part:FindFirstChild(name)
		if not (attachment and attachment:IsA("Attachment")) then continue end

		total += attachment.Position
		found += 1
	end

	return if found > 0 then total / found else Vector3.zero
end

local function decorate(model: Model, name: string)
	local trailName = Pet.trail(name)
	if not trailName then return end

	local asset = Trail.part(trailName)
	if not asset then
		warn(`[PetFollowClient] no part under Assets.Trails named "{trailName}"`)
		return
	end

	local pivot = model:GetPivot()
	model.WorldPivot = CFrame.new(pivot.Position)
	local box = model:GetBoundingBox()
	model.WorldPivot = pivot

	local part = asset:Clone()
	part.Name = DECORATION_NAME
	part.CFrame = box * CFrame.new(-middleOf(part))
	part.Parent = model
end

local function resize(model: Model)
	local primary = model.PrimaryPart
	if primary then
		primary.CFrame = CFrame.new(primary.Position)
	end

	local height = model:GetExtentsSize().Y
	if height <= 0 then return end

	model:ScaleTo(Config.PetFollow.height / height)
end

local function indexOf(slot: number): string
	return PET_INDEX .. slot
end

local function despawn(player: Player, slot: number)
	local Slots = Followers[player]
	if Slots then
		Slots[slot] = nil
	end

	local janitor = Watched[player]
	if not janitor then return end

	janitor:Remove(indexOf(slot))
end

local function refresh(player: Player)
	local janitor = Watched[player]
	if not janitor then return end

	local Slots = Followers[player]
	if not Slots then
		Slots = {}
		Followers[player] = Slots
	end

	-- Remove retired slots before refreshing the single purchased follower.
	for slot in pairs(Slots) do
		if slot > Pet.MaxEquipped then despawn(player, slot) end
	end

	for slot, attribute in ipairs(Pet.Attributes) do
		local name = player:GetAttribute(attribute)
		if type(name) ~= "string" or name == Pet.None then
			despawn(player, slot)
			continue
		end

		local follower = Slots[slot]
		if follower and follower.name == name then continue end

		local template = Pet.model(name)
		if not template then
			warn(`[PetFollowClient] could not find a model for {name}`)
			despawn(player, slot)
			continue
		end

		despawn(player, slot)

		local model = janitor:Add(template:Clone(), "Destroy", indexOf(slot))
		model.Name = `{player.Name} {slot}`

		decorate(model, name)

		dress(model)
		resize(model)

		Slots[slot] = {
			name = name,
			position = nil,
			yaw = nil,
			phase = 0,
		}
	end
end

local function update(delta: number)
	local root = folder
	if not root then return end

	local settings = Config.PetFollow
	local clock = os.clock()

	for player, Slots in Followers do
		local janitor = Watched[player]
		if not janitor then continue end

		local character = player.Character
		local body = if character then character:FindFirstChild(ROOT_NAME) else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil

		for slot, follower in Slots do
			local model = janitor:Get(indexOf(slot))
			if not (model and model:IsA("Model")) then continue end

			if not (body and body:IsA("BasePart") and humanoid) then
				if model.Parent then
					model.Parent = nil
				end

				follower.position = nil
				follower.yaw = nil
				continue
			end

			local ground = body.Position.Y - body.Size.Y / 2 - humanoid.HipHeight
			local side = settings.side * (settings.Sides[slot] or 0)
			local behind = body.CFrame * Vector3.new(side, 0, settings.back)
			local target = Vector3.new(behind.X, ground + settings.up, behind.Z)

			local position = follower.position or target
			local offset = target - position
			local distance = offset.Magnitude
			local step = 0

			if distance > settings.teleport then
				position = target
			elseif distance > settings.arrive then
				local speed = math.max(settings.floor, humanoid.WalkSpeed * settings.catchUp)

				step = math.min(distance - settings.arrive, speed * delta)
				position += offset.Unit * step
			end

			follower.position = position

			local moving = step > settings.crawl * delta

			local cadence = delta / settings.hopSeconds

			if moving then
				follower.phase += cadence
			else
				follower.phase = math.min(math.ceil(follower.phase), follower.phase + cadence)
			end

			local arc = math.abs(math.sin(follower.phase * math.pi))

			local rise = arc * settings.rise + (1 - arc) * math.sin(clock * settings.bobRate) * settings.bob

			local heading = if moving then offset else body.CFrame.LookVector
			heading = Vector3.new(heading.X, 0, heading.Z)

			if heading.Magnitude > EPSILON then
				local wanted = math.atan2(-heading.X, -heading.Z)
				local current = follower.yaw

				if not current then
					follower.yaw = wanted
				else
					local difference = (wanted - current + math.pi) % TAU - math.pi
					follower.yaw = current + difference * (1 - math.exp(-settings.turn * delta))
				end
			end

			local angle = follower.yaw or 0

			local pitch = math.sin(follower.phase * TAU) * math.rad(settings.pitch)
			local stand = position + Vector3.yAxis * rise

			model:PivotTo(CFrame.new(stand) * CFrame.Angles(0, angle + math.rad(settings.yaw), 0) * CFrame.Angles(pitch, 0, 0))

			if model.Parent ~= root then
				model.Parent = root
			end
		end
	end
end

local function track(player: Player)
	if Watched[player] then return end

	local janitor = Janitor.new()
	Watched[player] = janitor

	for _, attribute in ipairs(Pet.Attributes) do
		janitor:Add(player:GetAttributeChangedSignal(attribute):Connect(function()
			refresh(player)
		end))
	end

	refresh(player)
end

local function release(player: Player)
	local janitor = Watched[player]
	if not janitor then return end

	Followers[player] = nil
	Watched[player] = nil
	janitor:Destroy()
end

function PetFollowClient.start()
	if started then return end
	started = true
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace

	folder = created

	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(release)

	for _, player in ipairs(Players:GetPlayers()) do
		track(player)
	end

	RunService.RenderStepped:Connect(update)
end

return PetFollowClient
