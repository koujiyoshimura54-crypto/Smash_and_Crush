local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local DEVELOPER_USER_ID = 7467238848
local ACCESSORY_NAME = "Hisarino_hair"
local WAIT_TIMEOUT = 10
local accessoryTemplate = ServerStorage:WaitForChild(ACCESSORY_NAME)
local attaching = setmetatable({}, { __mode = "k" })

local function attachHisarinoHair(character)
	if attaching[character] then return end
	attaching[character] = true

	local head = character:WaitForChild("Head", WAIT_TIMEOUT)
	local headAttachment = head and head:WaitForChild("HairAttachment", WAIT_TIMEOUT)
	if not head or not headAttachment or not headAttachment:IsA("Attachment") then
		attaching[character] = nil
		return
	end

	local existing = character:FindFirstChild(ACCESSORY_NAME)
	if existing then existing:Destroy() end

	local accessory = accessoryTemplate:Clone()
	local handle = accessory:FindFirstChild("Handle")
	local accessoryAttachment = handle and handle:FindFirstChild("HairAttachment")
	if not handle or not handle:IsA("BasePart")
		or not accessoryAttachment or not accessoryAttachment:IsA("Attachment") then
		accessory:Destroy()
		attaching[character] = nil
		return
	end

	accessory.Parent = character
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle.CFrame = head.CFrame * headAttachment.CFrame * accessoryAttachment.CFrame:Inverse()

	local oldWeld = handle:FindFirstChild("AccessoryWeld")
	if oldWeld then oldWeld:Destroy() end

	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = handle
	weld.Part1 = head
	weld.C0 = accessoryAttachment.CFrame
	weld.C1 = headAttachment.CFrame
	weld.Parent = handle

	attaching[character] = nil
end

local function equipHisarinoBody(character)
	local humanoid = character:WaitForChild("Humanoid", WAIT_TIMEOUT)
	if not humanoid or not humanoid:IsA("Humanoid")
		or humanoid.RigType ~= Enum.HumanoidRigType.R15 or not character.Parent then
		return
	end

	local bodyTemplate = ServerStorage:FindFirstChild("Hisarino_Body")
	local handle = bodyTemplate and bodyTemplate:FindFirstChild("Handle")
	if not bodyTemplate or not bodyTemplate:IsA("Accessory")
		or not handle or not handle:IsA("MeshPart")
		or not handle:FindFirstChildWhichIsA("WrapLayer") then
		return
	end

	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "Hisarino_Body" then child:Destroy() end
	end
	local body = bodyTemplate:Clone()
	humanoid:AddAccessory(body)
end

local hiddenBodyParts = {
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
}

local function hideArmsAndLegs(character)
	for _, partName in ipairs(hiddenBodyParts) do
		local part = character:FindFirstChild(partName)
		if part and part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

local function equipCharacter(character)
	attachHisarinoHair(character)
	equipHisarinoBody(character)
	hideArmsAndLegs(character)
end

local function setupPlayer(player)
	if player.UserId ~= DEVELOPER_USER_ID then return end
	player.CharacterAdded:Connect(function(character)
		task.spawn(equipCharacter, character)
	end)
	if player.Character then task.spawn(equipCharacter, player.Character) end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
