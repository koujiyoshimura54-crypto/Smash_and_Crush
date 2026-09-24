local Workspace = game:GetService("Workspace")

local Config = {
	StagesPerWorld = 10,
	TrainingLength = 166.272,
	TrainingWidth = 207.84,
	TrainingFrontZ = 27.5,
	StageLength = 14,
	StageWidth = 20,
	BossStageScale = 1.5,
	FloorThickness = 2,
	WallThickness = 2,
	WallHeight = 25,
	TrainingWallHeight = 36,
	GateThickness = 2,
	GateHeight = 18,
	Origin = Vector3.new(0, 0, 0),
}

local Colors = {
	TrainingFloor = Color3.fromRGB(185, 190, 200),
	TrainingWall = Color3.fromRGB(246, 190, 18),
	TrainingBackWall = Color3.fromRGB(246, 190, 18),
	CorridorEntrance = Color3.fromRGB(246, 190, 18),
	Spawn = Color3.fromRGB(255, 0, 170),
	TrainingSpaces = {
		Color3.fromRGB(80, 255, 80),
		Color3.fromRGB(255, 70, 190),
		Color3.fromRGB(40, 150, 255),
	},
	Floor = Color3.fromRGB(125, 125, 125),
	BossFloor = Color3.fromRGB(105, 105, 112),
	Wall = Color3.fromRGB(82, 87, 94),
	Gate = Color3.fromRGB(130, 70, 55),
	NextGate = Color3.fromRGB(65, 105, 150),
}

local function createPart(parent, name, size, position, color, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Transparency = transparency or 0
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local BlockColors = {
	Color3.fromRGB(235, 45, 45),
	Color3.fromRGB(35, 105, 225),
	Color3.fromRGB(250, 205, 25),
	Color3.fromRGB(40, 175, 75),
}

local function createVisualBlock(parent, name, size, cframe, colorIndex)
	local block = Instance.new("Part")
	block.Name = name
	block.Size = size
	block.CFrame = cframe
	block.Anchored = true
	block.CanCollide = false
	block.CanTouch = false
	block.CanQuery = false
	block.Material = Enum.Material.Plastic
	block.Color = BlockColors[(colorIndex - 1) % #BlockColors + 1]
	block.TopSurface = Enum.SurfaceType.Studs
	block.BottomSurface = Enum.SurfaceType.Inlet
	block.Parent = parent
	return block
end

local function blockifyFloor(parent, collider, tileX, tileZ, colorOffset)
	collider.Transparency = 1
	local folder = Instance.new("Folder")
	folder.Name = collider.Name .. "_BlockSkin"
	folder.Parent = parent
	local columns = math.ceil(collider.Size.X / tileX)
	local rows = math.ceil(collider.Size.Z / tileZ)
	for row = 1, rows do
		local zStart = (row - 1) * tileZ
		local depth = math.min(tileZ, collider.Size.Z - zStart)
		for column = 1, columns do
			local xStart = (column - 1) * tileX
			local width = math.min(tileX, collider.Size.X - xStart)
			local x = -collider.Size.X / 2 + xStart + width / 2
			local z = -collider.Size.Z / 2 + zStart + depth / 2
			createVisualBlock(
				folder,
				("Block_%02d_%02d"):format(row, column),
				Vector3.new(width, collider.Size.Y, depth),
				collider.CFrame * CFrame.new(x, 0, z),
				row + column + colorOffset
			)
		end
	end
end

local function blockifyWall(parent, collider, segmentLength, layerHeight, colorOffset)
	collider.Transparency = 1
	local folder = Instance.new("Folder")
	folder.Name = collider.Name .. "_BlockSkin"
	folder.Parent = parent
	local alongX = collider.Size.X > collider.Size.Z
	local length = alongX and collider.Size.X or collider.Size.Z
	local segments = math.ceil(length / segmentLength)
	local layers = math.ceil(collider.Size.Y / layerHeight)
	for layer = 1, layers do
		local yStart = (layer - 1) * layerHeight
		local height = math.min(layerHeight, collider.Size.Y - yStart)
		for segment = 1, segments do
			local start = (segment - 1) * segmentLength
			local blockLength = math.min(segmentLength, length - start)
			local along = -length / 2 + start + blockLength / 2
			local y = -collider.Size.Y / 2 + yStart + height / 2
			local seam = 0.18
			local size = alongX
				and Vector3.new(math.max(0.2, blockLength - seam), math.max(0.2, height - seam), collider.Size.Z)
				or Vector3.new(collider.Size.X, math.max(0.2, height - seam), math.max(0.2, blockLength - seam))
			local offset = alongX and Vector3.new(along, y, 0) or Vector3.new(0, y, along)
			createVisualBlock(
				folder,
				("Block_%02d_%02d"):format(layer, segment),
				size,
				collider.CFrame * CFrame.new(offset),
				layer + segment + colorOffset
			)
		end
	end
end

local function addTrainingWallAccents(parent, collider, colorOffset)
	local folder = Instance.new("Folder")
	folder.Name = collider.Name .. "_WallAccents"
	folder.Parent = parent
	local alongX = collider.Size.X > collider.Size.Z
	local length = alongX and collider.Size.X or collider.Size.Z
	local count = math.ceil(length / 24)
	local protrusion = 0.45
	for side = -1, 1, 2 do
		for i = 1, count do
			local blockLength = math.min(24, length - (i - 1) * 24)
			local along = -length / 2 + (i - 1) * 24 + blockLength / 2
			local offset
			local size
			if alongX then
				offset = Vector3.new(along, 4.5, side * (collider.Size.Z / 2 + protrusion))
				size = Vector3.new(math.max(4, blockLength - 1.0), 2.6, 0.9)
			else
				offset = Vector3.new(side * (collider.Size.X / 2 + protrusion), 4.5, along)
				size = Vector3.new(0.9, 2.6, math.max(4, blockLength - 1.0))
			end
			createVisualBlock(folder, ("Face_%d_%02d"):format(side, i), size, collider.CFrame * CFrame.new(offset), colorOffset + i + side)
		end
	end
	for i = 1, count do
		local blockLength = math.min(24, length - (i - 1) * 24)
		local along = -length / 2 + (i - 1) * 24 + blockLength / 2
		local offset
		local size
		if alongX then
			offset = Vector3.new(along, collider.Size.Y / 2 + 0.35, 0)
			size = Vector3.new(math.max(4, blockLength - 1.0), 0.7, collider.Size.Z + 0.8)
		else
			offset = Vector3.new(0, collider.Size.Y / 2 + 0.35, along)
			size = Vector3.new(collider.Size.X + 0.8, 0.7, math.max(4, blockLength - 1.0))
		end
		createVisualBlock(folder, ("Top_%02d"):format(i), size, collider.CFrame * CFrame.new(offset), colorOffset + i + 2)
	end
end

local function addGridWallSurface(parent, collider, colorOffset)
	local folder = Instance.new("Folder")
	folder.Name = collider.Name .. "_GridBlocks"
	folder.Parent = parent
	local alongX = collider.Size.X > collider.Size.Z
	local length = alongX and collider.Size.X or collider.Size.Z
	local spacing = 16
	local blockAlong = 4
	local blockHeight = 3
	local protrusion = 1.2
	local count = math.ceil(length / spacing)
	local rows = 3
	local function addBlock(name, size, offset, index)
		createVisualBlock(folder, name, size, collider.CFrame * CFrame.new(offset), colorOffset + index)
	end
	for side = -1, 1, 2 do
		for row = 1, rows do
			local y = -collider.Size.Y / 2 + 1.5 + (row - 1) * 4
			for i = 1, count do
				local segment = math.min(spacing, length - (i - 1) * spacing)
				local along = -length / 2 + (i - 1) * spacing + segment / 2
				if alongX then
					addBlock(("Face_%d_%d_%02d"):format(side, row, i),
						Vector3.new(math.min(blockAlong, segment - 0.8), blockHeight, protrusion),
						Vector3.new(along, y, side * (collider.Size.Z / 2 + protrusion / 2)), row + i + side)
				else
					addBlock(("Face_%d_%d_%02d"):format(side, row, i),
						Vector3.new(protrusion, blockHeight, math.min(blockAlong, segment - 0.8)),
						Vector3.new(side * (collider.Size.X / 2 + protrusion / 2), y, along), row + i + side)
				end
			end
		end
	end
	-- End faces: one column of the same square凸部 on each narrow side.
	for side = -1, 1, 2 do
		for row = 1, rows do
			local y = -collider.Size.Y / 2 + 1.5 + (row - 1) * 4
			local endOffset = side * (length / 2 + protrusion / 2)
			if alongX then
				addBlock(("End_%d_%d"):format(side, row),
					Vector3.new(protrusion, blockHeight, math.min(2.0, collider.Size.Z)),
					Vector3.new(endOffset, y, 0), row + side + 5)
			else
				addBlock(("End_%d_%d"):format(side, row),
					Vector3.new(math.min(2.0, collider.Size.X), blockHeight, protrusion),
					Vector3.new(0, y, endOffset), row + side + 5)
			end
		end
	end
	-- Top row follows the same grid rhythm without changing the wall collider.
	for i = 1, count do
		local segment = math.min(spacing, length - (i - 1) * spacing)
		local along = -length / 2 + (i - 1) * spacing + segment / 2
		if alongX then
			addBlock(("Top_%02d"):format(i),
				Vector3.new(math.min(blockAlong, segment - 0.8), protrusion, collider.Size.Z + 0.4),
				Vector3.new(along, collider.Size.Y / 2 + protrusion / 2, 0), i + 9)
		else
			addBlock(("Top_%02d"):format(i),
				Vector3.new(collider.Size.X + 0.4, protrusion, math.min(blockAlong, segment - 0.8)),
				Vector3.new(0, collider.Size.Y / 2 + protrusion / 2, along), i + 9)
		end
	end
end

local function addWallPreviewSurface(parent, collider, colorOffset)
	local folder = Instance.new("Folder")
	folder.Name = collider.Name .. "_PreviewGrid"
	folder.Parent = parent
	local yellow = Color3.fromRGB(246, 190, 18)
	local alongX = collider.Size.X > collider.Size.Z
	local length = alongX and collider.Size.X or collider.Size.Z
	local spacing, blockSize, blockHeight, protrusion = 4, 1.5, 1.5, 0.45
	local count = math.ceil(length / spacing)
	local rows = math.max(3, math.floor(collider.Size.Y / 2.5))
	local function block(name, size, offset, index, color)
		createVisualBlock(folder, name, size, collider.CFrame * CFrame.new(offset), index + colorOffset)
		local p = folder:FindFirstChild(name)
		if p then
			p.Color = color or yellow
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end
	end
	for side = -1, 1, 2 do
		for row = 1, rows do
			local y = -collider.Size.Y / 2 + 1.5 + (row - 1) * 3
			for i = 1, count do
				local seg = math.min(spacing, length - (i - 1) * spacing)
				local along = -length / 2 + (i - 1) * spacing + seg / 2
				if alongX then
					block(("Face_%d_%02d_%02d"):format(side, row, i),
						Vector3.new(math.min(blockSize, seg - 0.5), blockHeight, protrusion),
						Vector3.new(along, y, side * (collider.Size.Z / 2 + protrusion / 2)), row + i, yellow)
				else
					block(("Face_%d_%02d_%02d"):format(side, row, i),
						Vector3.new(protrusion, blockHeight, math.min(blockSize, seg - 0.5)),
						Vector3.new(side * (collider.Size.X / 2 + protrusion / 2), y, along), row + i, yellow)
				end
			end
		end
	end
	for side = -1, 1, 2 do
		for row = 1, rows do
			local y = -collider.Size.Y / 2 + 1.5 + (row - 1) * 3
			local e = side * (length / 2 + protrusion / 2)
			if alongX then
				block(("End_%d_%02d"):format(side, row), Vector3.new(protrusion, blockHeight, math.min(blockSize, collider.Size.Z - 0.3)), Vector3.new(e, y, 0), row + 7, yellow)
			else
				block(("End_%d_%02d"):format(side, row), Vector3.new(math.min(blockSize, collider.Size.X - 0.3), blockHeight, protrusion), Vector3.new(0, y, e), row + 7, yellow)
			end
		end
	end
	for i = 1, count do
		local seg = math.min(spacing, length - (i - 1) * spacing)
		local along = -length / 2 + (i - 1) * spacing + seg / 2
		if alongX then
			block(("Top_%02d"):format(i), Vector3.new(math.min(blockSize, seg - 0.5), protrusion, math.min(blockSize, collider.Size.Z)), Vector3.new(along, collider.Size.Y / 2 + protrusion / 2, 0), i + 11, yellow)
		else
			block(("Top_%02d"):format(i), Vector3.new(math.min(blockSize, collider.Size.X), protrusion, math.min(blockSize, seg - 0.5)), Vector3.new(0, collider.Size.Y / 2 + protrusion / 2, along), i + 11, yellow)
		end
	end
end

local function addTrainingSign(parent, wall)
	local sign = createPart(parent, "TrainingAreaSign", Vector3.new(36, 7, 0.6), wall.Position + Vector3.new(0, 1.5, 1.0), Color3.fromRGB(35, 40, 55), 0, false)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TrainingAreaSignGui"
	gui.Face = Enum.NormalId.Front
	gui.AlwaysOnTop = true
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "TRAINING AREA"
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

local function addEntranceFrame(parent)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingEntranceFrame"
	folder.Parent = parent
	local blue = Color3.fromRGB(35, 105, 225)
	local function b(name, size, pos)
		local p = createVisualBlock(folder, name, size, CFrame.new(pos), 2)
		p.Color = blue
	end
	b("LeftPillar", Vector3.new(2.4, 12, 2.4), Vector3.new(Config.Origin.X - 11, 7, Config.TrainingFrontZ))
	b("RightPillar", Vector3.new(2.4, 12, 2.4), Vector3.new(Config.Origin.X + 11, 7, Config.TrainingFrontZ))
	b("TopBeam", Vector3.new(24, 2.4, 2.4), Vector3.new(Config.Origin.X, 12.4, Config.TrainingFrontZ))
end

local function addTrainingFloorAccents(parent, floor)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingFloorAccents"
	folder.Parent = parent
	local colors = {Color3.fromRGB(246, 190, 18), Color3.fromRGB(40, 175, 75)}
	local i = 0
	for _, z in ipairs({floor.Position.Z - floor.Size.Z / 2 + 10, floor.Position.Z + floor.Size.Z / 2 - 10}) do
		for _, x in ipairs({floor.Position.X - 48, floor.Position.X - 24, floor.Position.X, floor.Position.X + 24, floor.Position.X + 48}) do
			i += 1
			local p = createVisualBlock(folder, ("Panel_%02d"):format(i), Vector3.new(12, 0.3, 6), CFrame.new(x, floor.Position.Y + floor.Size.Y / 2 + 0.18, z), i)
			p.Color = colors[((i - 1) % #colors) + 1]
		end
	end
end

local function addNextWorldFrame(parent, gate)
	local folder = Instance.new("Folder")
	folder.Name = "NextWorldBlockFrame"
	folder.Parent = parent
	local blue = Color3.fromRGB(35, 105, 225)
	local z, x, width, y = gate.Position.Z, gate.Position.X, gate.Size.X, gate.Position.Y
	local function b(name, size, pos)
		local p = createVisualBlock(folder, name, size, CFrame.new(pos), 2)
		p.Color = blue
	end
	b("LeftPillar", Vector3.new(2.4, gate.Size.Y + 2, 2.4), Vector3.new(x - width / 2 - 1.2, y, z))
	b("RightPillar", Vector3.new(2.4, gate.Size.Y + 2, 2.4), Vector3.new(x + width / 2 + 1.2, y, z))
	b("TopBeam", Vector3.new(width + 5, 2.4, 2.4), Vector3.new(x, y + gate.Size.Y / 2 + 1.2, z))
end

local function clonePreviewWall(parent, collider, name)
	local templates = game:GetService("ServerStorage"):FindFirstChild("MapTemplates")
	local template = templates and templates:FindFirstChild("LEGO_Wall_Preview") or Workspace:FindFirstChild("LEGO_Wall_Preview")
	if not template or not template:IsA("Model") then warn("LEGO_Wall_Preview template missing for "..name) return end
	local clone = template:Clone(); clone.Name = name .. "_LEGO_Wall"
	local base = clone:FindFirstChild("WallBody", true); if not base then clone:Destroy() return end
	local alongX = collider.Size.X > collider.Size.Z
	local sourcePivot = template:GetPivot()
	local pivot = collider.CFrame * (alongX and CFrame.new() or CFrame.Angles(0, math.rad(90), 0))
	local sx = (alongX and collider.Size.X or collider.Size.Z) / 16
	local sy = collider.Size.Y / 28
	local sz = (alongX and collider.Size.Z or collider.Size.X) / 2
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			local rel = sourcePivot:ToObjectSpace(part.CFrame); local pos = rel.Position; local rot = rel - pos
			part.Size = Vector3.new(part.Size.X * sx, part.Size.Y * sy, part.Size.Z * sz)
			part.CFrame = pivot * CFrame.new(pos.X * sx, pos.Y * sy, pos.Z * sz) * rot
			part.Anchored = true; part.CanTouch = false; part.CanQuery = false; part.CanCollide = part == base
		end
	end
	clone.Parent = parent
	collider.Transparency = 1; collider.CanCollide = false
end

local oldMap = Workspace:FindFirstChild("GeneratedMap")
if oldMap then
	oldMap:Destroy()
end

local generatedMap = Instance.new("Model")
generatedMap.Name = "GeneratedMap"
generatedMap:SetAttribute("Phase", "1.1")
generatedMap:SetAttribute("GeneratedBy", "Phase11_GenerateGrayboxMap")

local trainingArea = Instance.new("Model")
trainingArea.Name = "TrainingArea"
trainingArea.Parent = generatedMap

local floorY = Config.Origin.Y
local surfaceY = floorY + Config.FloorThickness / 2
local trainingCenterZ = Config.TrainingFrontZ - Config.TrainingLength / 2
local trainingFloor = createPart(
	trainingArea, "Floor",
	Vector3.new(Config.TrainingWidth, Config.FloorThickness, Config.TrainingLength),
	Vector3.new(Config.Origin.X, floorY, trainingCenterZ),
	Colors.TrainingFloor
)
trainingFloor.Material = Enum.Material.Plastic
trainingFloor.MaterialVariant = "LEGO_Floor_PBR_Gray_V3"

local spawn = Workspace:FindFirstChild("SpawnLocation") or Instance.new("SpawnLocation")
spawn.Name = "SpawnLocation"
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(30, surfaceY + 0.5, -40)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = Colors.Spawn
spawn.Parent = trainingArea

local trainingSpaceX = { -50, -40, -30, -20, -10 }
local trainingSpaceZ = { -38, -18 }
for row, zOffset in trainingSpaceZ do
	for column, xOffset in trainingSpaceX do
		createPart(
			trainingArea,
			("TrainingSpace_%d_%d"):format(row, column),
			Vector3.new(8, 0.2, 14),
			Vector3.new(Config.Origin.X + xOffset, surfaceY + 0.1, Config.Origin.Z + zOffset),
			Colors.TrainingSpaces[(column + row - 2) % #Colors.TrainingSpaces + 1],
			0,
			false
		)
	end
end

local treadmillFolder = Workspace:WaitForChild("Treadmill")
local treadmillTemplate = treadmillFolder:FindFirstChild("Tredmill01") or treadmillFolder:FindFirstChild("Tredmill")
if treadmillTemplate then
	treadmillTemplate.Name = "Tredmill01"
	local treadmillRotation = treadmillTemplate:GetPivot().Rotation
	local treadmillY = treadmillTemplate:GetPivot().Position.Y
	for index = 1, 10 do
		local name = ("Tredmill%02d"):format(index)
		local treadmill = treadmillFolder:FindFirstChild(name)
		if not treadmill then
			treadmill = treadmillTemplate:Clone()
			treadmill.Name = name
			treadmill.Parent = treadmillFolder
		end
		local row = math.floor((index - 1) / 5) + 1
		local column = (index - 1) % 5 + 1
		treadmill:PivotTo(CFrame.new(trainingSpaceX[column], treadmillY, trainingSpaceZ[row]) * treadmillRotation)
	end
end

local trainingWallY = surfaceY + Config.TrainingWallHeight / 2
createPart(
	trainingArea, "LeftWall",
	Vector3.new(Config.WallThickness, Config.TrainingWallHeight, Config.TrainingLength),
	Vector3.new(Config.Origin.X - Config.TrainingWidth / 2 + Config.WallThickness / 2, trainingWallY, trainingCenterZ),
	Colors.TrainingWall
)
createPart(
	trainingArea, "RightWall",
	Vector3.new(Config.WallThickness, Config.TrainingWallHeight, Config.TrainingLength),
	Vector3.new(Config.Origin.X + Config.TrainingWidth / 2 - Config.WallThickness / 2, trainingWallY, trainingCenterZ),
	Colors.TrainingWall
)
createPart(
	trainingArea, "BackWall",
	Vector3.new(Config.TrainingWidth, Config.TrainingWallHeight, Config.WallThickness),
	Vector3.new(Config.Origin.X, trainingWallY, trainingCenterZ - Config.TrainingLength / 2 + Config.WallThickness / 2),
	Colors.TrainingBackWall
)

local entranceSideWidth = (Config.TrainingWidth - Config.StageWidth) / 2
local entranceZ = Config.TrainingFrontZ - Config.WallThickness / 2
for side = -1, 1, 2 do
	createPart(
		trainingArea,
		side < 0 and "CorridorEntranceLeft" or "CorridorEntranceRight",
		Vector3.new(entranceSideWidth, Config.TrainingWallHeight, Config.WallThickness),
		Vector3.new(
			Config.Origin.X + side * (Config.StageWidth / 2 + entranceSideWidth / 2),
			trainingWallY,
			entranceZ
		),
		Colors.CorridorEntrance
	)
end

-- Training Lobby walls use the V3 PBR material; physical convex Parts are no longer generated.
for _, wall in ipairs({
	trainingArea.LeftWall,
	trainingArea.RightWall,
	trainingArea.BackWall,
	trainingArea.CorridorEntranceLeft,
	trainingArea.CorridorEntranceRight,
}) do
	wall.Material = Enum.Material.Plastic
	wall.MaterialVariant = "LEGO_Floor_PBR_V3_Test"
end

local corridor = Instance.new("Model")
corridor.Name = "BattleCorridor"
corridor.Parent = generatedMap

local cursorZ = Config.TrainingFrontZ
for stageNumber = 1, Config.StagesPerWorld do
	local isBoss = stageNumber == Config.StagesPerWorld
	local scale = isBoss and Config.BossStageScale or 1
	local stageLength = Config.StageLength * scale
	local stageWidth = Config.StageWidth * scale
	local centerZ = cursorZ + stageLength / 2

	local stage = Instance.new("Model")
	stage.Name = ("Stage%02d"):format(stageNumber)
	stage:SetAttribute("StageNumber", stageNumber)
	stage:SetAttribute("IsBossStage", isBoss)
	stage:SetAttribute("StageLength", stageLength)
	stage:SetAttribute("StageWidth", stageWidth)
	stage.Parent = corridor

	createPart(stage, "Floor",
		Vector3.new(stageWidth, Config.FloorThickness, stageLength),
		Vector3.new(Config.Origin.X, floorY, centerZ),
		isBoss and Colors.BossFloor or Colors.Floor)

	local wallY = surfaceY + Config.WallHeight / 2
	createPart(stage, "LeftWall",
		Vector3.new(Config.WallThickness, Config.WallHeight, stageLength),
		Vector3.new(Config.Origin.X - stageWidth / 2 + Config.WallThickness / 2, wallY, centerZ),
		Colors.Wall)
	createPart(stage, "RightWall",
		Vector3.new(Config.WallThickness, Config.WallHeight, stageLength),
		Vector3.new(Config.Origin.X + stageWidth / 2 - Config.WallThickness / 2, wallY, centerZ),
		Colors.Wall)

	createPart(stage, "EnemySpawn",
		Vector3.new(6, 1, 6),
		Vector3.new(Config.Origin.X, surfaceY + 0.5, cursorZ + Config.StageLength / 2),
		Color3.fromRGB(255, 0, 0), 1, false)

	if isBoss then
		createPart(stage, "BossSpawn",
			Vector3.new(10, 1, 10),
			Vector3.new(Config.Origin.X, surfaceY + 0.5, cursorZ + Config.StageLength / 2),
			Color3.fromRGB(255, 170, 0), 1, false)
	end

	local gate = createPart(stage, "Gate",
		Vector3.new(stageWidth - Config.WallThickness * 2, Config.GateHeight, Config.GateThickness),
		Vector3.new(Config.Origin.X, surfaceY + Config.GateHeight / 2, cursorZ + stageLength - Config.GateThickness / 2),
		Colors.Gate)

	cursorZ += stageLength
end

local nextWorldArea = Instance.new("Model")
nextWorldArea.Name = "NextWorldArea"
nextWorldArea.Parent = generatedMap

local nextWorldGate = createPart(
	nextWorldArea, "NextWorldGate",
	Vector3.new(Config.StageWidth * Config.BossStageScale, Config.GateHeight + 6, Config.GateThickness * 2),
	Vector3.new(Config.Origin.X, surfaceY + (Config.GateHeight + 6) / 2, cursorZ + Config.GateThickness * 2),
	Colors.NextGate
)
nextWorldGate:SetAttribute("Destination", "FutureWorld")
addNextWorldFrame(nextWorldArea, nextWorldGate)

-- Lightweight, non-colliding block accents around TrainingArea and the future-world gate.
-- These are visual-only; all gameplay colliders remain the original Parts.
local accentFolder = Instance.new("Folder")
accentFolder.Name = "BlockAccents"
accentFolder.Parent = nextWorldArea
local accentY = surfaceY + 1.5
for _,x in ipairs({Config.Origin.X - 12, Config.Origin.X + 12}) do
	for _,z in ipairs({cursorZ + 4, cursorZ + 16}) do
		createVisualBlock(
			accentFolder,
			("Accent_%d_%d"):format(x, z),
			Vector3.new(6, 3, 6),
			CFrame.new(x, accentY, z),
			math.floor(x + z)
		)
	end
end

-- Publish only after TrainingArea, BattleCorridor (Stage01-10), and NextWorldArea are complete.
generatedMap.Parent = Workspace
