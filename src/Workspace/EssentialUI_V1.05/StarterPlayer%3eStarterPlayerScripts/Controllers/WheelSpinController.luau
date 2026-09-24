local WheelSpinController = {}
local Player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedUtils = ReplicatedStorage.Utils
local GlobalFunctions = require(ReplicatedUtils.GlobalFunctions)
local Packets = require(ReplicatedUtils.Packets)
local NotificationController = require(script.Parent.NotificationController)
local MarketplaceController = require(script.Parent.MarketplaceController)
local Config = ReplicatedStorage.Configuration
local WheelSpinConfig = require(Config.WheelSpin)
local ReplicationController = require(script.Parent.ReplicationController)
local Frames = require(script.Parent.UiController.Frames)

local WheelSpinFrame = Frames.WheelSpin
local Wheel = WheelSpinFrame.Wheel
local SpinBtn = WheelSpinFrame.Spin
local Pointer = WheelSpinFrame.Pointer
local TickSound: Sound = WheelSpinFrame.Tick
local RewardSound: Sound = WheelSpinFrame.Reward

local SEGMENT_COUNT = #WheelSpinConfig.Rewards
local SEGMENT_ANGLE = 360 / SEGMENT_COUNT
local POINTER_DEFLECT = 22
local POINTER_RETURN = TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)

local isSpinning = false
local pointerTween = nil

local function BouncePointer()
	if pointerTween then pointerTween:Cancel() end
	Pointer.Rotation = POINTER_DEFLECT
	pointerTween = TweenService:Create(Pointer, POINTER_RETURN, { Rotation = 0 })
	pointerTween:Play()
end

local function SpinTheWheel(rewardIndex: number)
	if isSpinning then return end
	isSpinning     = true
	SpinBtn.Active = false
	Wheel.Rotation = 0

	local targetEffective  = (rewardIndex - 1) * SEGMENT_ANGLE + math.random() * SEGMENT_ANGLE

	local currentEffective = (-Wheel.Rotation) % 360

	local delta = (targetEffective - currentEffective + 360) % 360
	if delta == 0 then delta = 360 end 

	local totalAngle     = WheelSpinConfig.NumberOfSpins * 360 + delta
	local targetRotation = Wheel.Rotation - totalAngle

	local tweenInfo = TweenInfo.new(
		WheelSpinConfig.FullSpinDuration,
		Enum.EasingStyle.Circular,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(Wheel, tweenInfo, { Rotation = targetRotation })

	local startAbs     = math.abs(Wheel.Rotation)
	local lastTickCount = 0

	local tickConnection = RunService.Heartbeat:Connect(function()
		local traveled  = math.abs(Wheel.Rotation) - startAbs
		local tickCount = math.floor(traveled / SEGMENT_ANGLE)
		if tickCount > lastTickCount then
			lastTickCount = tickCount
			TickSound:Play()
			BouncePointer()
		end
	end)

	tween:Play()
	tween.Completed:Wait()
	tickConnection:Disconnect()
	RewardSound:Play()
	
	task.wait(2)
	isSpinning     = false
	SpinBtn.Active = true
end

local playerAllowedForRPI = true
local spins

local function UpdateUi()
	WheelSpinFrame.Spin.TextLabel.Text = `SPIN (x{spins.Spins})`
end

function WheelSpinController:init()
	local data
	local success, err = pcall(function ()
		data = PolicyService:GetPolicyInfoForPlayerAsync(game.Players.LocalPlayer)
	end)
	
	playerAllowedForRPI = not data.ArePaidRandomItemsRestricted	
	spins = ReplicationController.Subscribe(`{Player.UserId}_Spins`)
	UpdateUi()
	ReplicationController.GetSignal(`{Player.UserId}_Spins`):Connect(function (data)
		spins = data
		UpdateUi()
	end)
	
	for _, item:Frame in Wheel:GetChildren() do
		local info = WheelSpinConfig.Rewards[tonumber(item.Name)]
		item.ImageLabel.Image = "rbxassetid://" .. info.Icon
		item.TextLabel.Text = info.Text
	end
	
	for _, btn:GuiButton in WheelSpinFrame.Buttons:GetChildren() do
		btn.MouseButton1Click:Connect(function ()
			if not playerAllowedForRPI then
				NotificationController:Prompt("Error", "Youre not eligible for random paid items")
				return
			end
			MarketplaceController:StartProductPrompt(`x{btn.Name} Spins`)
		end)
	end
	
	task.spawn(function ()
		while true do
			if not spins.NextFreeSpin then task.wait(1) continue end
			WheelSpinFrame.FreeSpin.Text = `Next FREE spin in {GlobalFunctions.FormatTime(spins.NextFreeSpin - os.time())}`
			task.wait(1)
		end
	end)
	
	SpinBtn.MouseButton1Click:Connect(function()
		if isSpinning then return end
		local rewardIndex = Packets.WheelSpin.Spin:Fire()
		if rewardIndex > 0 then SpinTheWheel(rewardIndex) end
	end)
	
	game:GetService("RunService").Heartbeat:Connect(function (delta)
		if isSpinning then return end
		WheelSpinFrame.Wheel.Rotation -= 10 * delta
	end)
end

return WheelSpinController