local NotificationController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedUtils = ReplicatedStorage.Utils
local Packets = require(ReplicatedUtils.Packets)
local SoundService = game:GetService("SoundService")
local SfxGroup = SoundService:WaitForChild("SFX")
local Player = game:GetService("Players").LocalPlayer
local NotificationsUi = Player.PlayerGui:WaitForChild("Main").HUD.Notifications
local Template = NotificationsUi.Template
Template.Parent = nil

NotificationController.Types = {
	["Success"] = {
		Background = Color3.fromRGB(0, 170, 0),
		Stroke = Color3.fromRGB(0, 106, 0),
		Sound = 124743961969068,
	},
	["Error"] = {
		Background = Color3.fromRGB(230, 0, 0),
		Stroke = Color3.fromRGB(170, 0, 0),
		Sound = 137500936341394,
	},
	["Info"] = {
		Background = Color3.fromRGB(0, 170, 255),
		Stroke = Color3.fromRGB(0, 90, 135),
		Sound = 74379627889513,
	},
}
type NotificationType = keyof <typeof(NotificationController.Types)>

-- value = { clone, count, dismissThread }
local activeNotifications = {}
local layoutOrder = 0

local function playSound(name)
	SoundService:FindFirstChild("Notifications"):FindFirstChild(name):Play()
end

local function dismissNotification(key, clone)
	clone:TweenSize(UDim2.fromScale(0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, false, function()
		clone:Destroy()
		activeNotifications[key] = nil
	end)
end

function NotificationController:Prompt(typeName: NotificationType, message: string)
	local typeData = NotificationController.Types[typeName]
	if not typeData then return end

	local key = typeName .. "|" .. message

	if activeNotifications[key] then
		local entry = activeNotifications[key]

		entry.count += 1
		entry.clone.Message.Text = message .. " (x" .. entry.count .. ")"

		task.cancel(entry.dismissThread)
		entry.dismissThread = task.delay(5, function()
			dismissNotification(key, entry.clone)
		end)

		layoutOrder -= 1
		entry.clone.LayoutOrder = layoutOrder
	else
		local clone = Template:Clone()
		clone.BackgroundColor3 = typeData.Background
		clone.Message.Text = message
		clone.Message.UIStroke.Color = typeData.Stroke
		clone.Size = UDim2.fromScale(0, 0)

		layoutOrder -= 1
		clone.LayoutOrder = layoutOrder
		clone.Parent = NotificationsUi
		clone:TweenSize(UDim2.fromScale(0, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)

		local entry = { clone = clone, count = 1, dismissThread = nil }
		entry.dismissThread = task.delay(5, function()
			dismissNotification(key, clone)
		end)

		activeNotifications[key] = entry
	end

	playSound(typeName)
end

function NotificationController:init()
	local notf = Instance.new("Folder")
	notf.Name = "Notifications"
	notf.Parent = SoundService
	for name, data in NotificationController.Types do
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. data.Sound
		sound.Volume = 1
		sound.SoundGroup = SfxGroup
		sound.Name = name
		sound.Parent = notf
	end
	Packets.Notification.Prompt.OnClientEvent:Connect(function(typeName, message)
		NotificationController:Prompt(typeName, message)
	end)
end

return NotificationController