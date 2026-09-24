local Players = game:GetService("Players")

local player = Players.LocalPlayer

local NORMAL_SCALE = Vector3.one
local MUSCLE_THRESHOLDS = { 3, 7, 13, 25, 49, 97, 193, 385, 769, 1537 }
local MUSCLE_GROWTH_FACTORS = { 4, 7, 9, 10, 11, 12, 13, 14, 15, 16 }
local HEIGHT_SCALES = { 1.20, 1.35, 1.50, 1.70, 1.90, 2.15, 2.40, 2.70, 3.00, 3.50 }
local PART_SCALE_KEYS = {
	UpperTorso = "UpperTorso",
	LowerTorso = "LowerTorso",
	LeftUpperArm = "UpperArm",
	RightUpperArm = "UpperArm",
	LeftLowerArm = "LowerArm",
	RightLowerArm = "LowerArm",
	LeftUpperLeg = "UpperLeg",
	RightUpperLeg = "UpperLeg",
	LeftLowerLeg = "LowerLeg",
	RightLowerLeg = "LowerLeg",
}
local MUSCLE1_GROWTH = {
	UpperTorso = Vector3.new(0.12, 0, 0.10),
	UpperArm = Vector3.new(0.15, 0, 0.15),
	LowerArm = Vector3.new(0.08, 0, 0.08),
	LowerTorso = Vector3.new(0.05, 0, 0.05),
	HeightOnly = Vector3.zero,
}
-- Use torso X/Z growth as the reference; Height is applied once by getPartScale.
MUSCLE1_GROWTH.UpperLeg = MUSCLE1_GROWTH.UpperTorso * 0.75
MUSCLE1_GROWTH.LowerLeg = MUSCLE1_GROWTH.UpperTorso * 0.60

local activeCharacter
local activeHumanoid
local normalHipHeight
local normalParts
local normalMotors
local preparedCharacters = {}

local function scaleCFramePosition(value, scale)
	return CFrame.new(value.Position * scale) * value.Rotation
end

local function getMuscleStage(strength)
	if typeof(strength) ~= "number" then
		return 0
	end

	local stage = 0
	for muscleStage, threshold in MUSCLE_THRESHOLDS do
		if strength < threshold then
			break
		end
		stage = muscleStage
	end
	return stage
end

local function getHeightScale(muscleStage)
	return HEIGHT_SCALES[muscleStage] or 1
end

local function getPartScale(partName, muscleStage)
	local scaleKey = PART_SCALE_KEYS[partName]
	local muscle1Growth = scaleKey and MUSCLE1_GROWTH[scaleKey]
	local growthFactor = MUSCLE_GROWTH_FACTORS[muscleStage]
	if not muscle1Growth or not growthFactor then
		return NORMAL_SCALE
	end

	return Vector3.new(
		1 + muscle1Growth.X * growthFactor,
		getHeightScale(muscleStage),
		1 + muscle1Growth.Z * growthFactor
	)
end

local function applyCurrentStrength()
	local character = activeCharacter
	if not character or character ~= player.Character or not normalParts or not normalMotors then
		return
	end

	local muscleStage = getMuscleStage(player:GetAttribute("Strength"))
	activeHumanoid.HipHeight = normalHipHeight * getHeightScale(muscleStage)

	for partName, normalData in normalParts do
		local scale = getPartScale(partName, muscleStage)
		normalData.Part.Size = normalData.Size * scale

		for attachment, normalPosition in normalData.Attachments do
			if attachment.Parent == normalData.Part then
				attachment.Position = normalPosition * scale
			end
		end
	end

	for motor, normalData in normalMotors do
		if motor.Parent then
			local part0Scale = getPartScale(normalData.Part0Name, muscleStage)
			local part1Scale = getPartScale(normalData.Part1Name, muscleStage)
			motor.C0 = scaleCFramePosition(normalData.C0, part0Scale)
			motor.C1 = scaleCFramePosition(normalData.C1, part1Scale)
		end
	end
end

local function prepareCharacter(character)
	if preparedCharacters[character] then
		return
	end
	preparedCharacters[character] = true

	local humanoid = character:WaitForChild("Humanoid")
	if character ~= player.Character or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end

	local partData = {}
	for partName in PART_SCALE_KEYS do
		local part = character:WaitForChild(partName)
		if character ~= player.Character or not part:IsA("BasePart") then
			return
		end

		local attachments = {}
		for _, child in part:GetChildren() do
			if child:IsA("Attachment") then
				attachments[child] = child.Position
			end
		end

		partData[partName] = {
			Part = part,
			Size = part.Size,
			Attachments = attachments,
		}
	end

	local motorData = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			local part0 = descendant.Part0
			local part1 = descendant.Part1
			if (part0 and PART_SCALE_KEYS[part0.Name]) or (part1 and PART_SCALE_KEYS[part1.Name]) then
				motorData[descendant] = {
					C0 = descendant.C0,
					C1 = descendant.C1,
					Part0Name = part0 and part0.Name,
					Part1Name = part1 and part1.Name,
				}
			end
		end
	end

	activeCharacter = character
	activeHumanoid = humanoid
	normalHipHeight = humanoid.HipHeight
	normalParts = partData
	normalMotors = motorData
	applyCurrentStrength()
end

player:GetAttributeChangedSignal("Strength"):Connect(applyCurrentStrength)
player.CharacterAdded:Connect(function(character)
	task.defer(prepareCharacter, character)
end)

if player.Character then
	task.defer(prepareCharacter, player.Character)
end
