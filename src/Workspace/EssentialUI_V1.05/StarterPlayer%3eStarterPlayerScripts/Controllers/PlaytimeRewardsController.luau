local PlaytimeRewardsController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Confg  = ReplicatedStorage.Configuration

local PlaytimeRewardsConfg = require(Confg.PlaytimeRewards)
local Packets = require(ReplicatedStorage.Utils.Packets)
local Frames = require(script.Parent.UiController.Frames)
local ReplicationController = require(script.Parent.ReplicationController)
local NotificationController = require(script.Parent.NotificationController)
local GlobalSignals = require(script.Parent.Parent.Utils.GlobalSignals)
local GlobalFunctions = require(ReplicatedStorage.Utils.GlobalFunctions)

local PlaytimeRewardFrame = Frames.PlaytimeRewards
local Container = PlaytimeRewardFrame.Holder

local Data = {} :: {
	OnSendPlayTime:number,
	OnSendTimestamp:number,
	RewardsPlaytime:number,
	ResetTimestamp:number,
	ClaimedRewards:{},
}

function UpdateUi()
	if not Data or not Data.RewardsPlaytime then return end

	local now = os.time()
	local currentPlaytime = (now - Data.OnSendTimestamp) + Data.OnSendPlayTime
	local rewardsPlaytime = currentPlaytime - Data.RewardsPlaytime

	for index, info in PlaytimeRewardsConfg.Rewards do
		local ui = Container:FindFirstChild(index)
		local claimed = Data.ClaimedRewards[index]
		if claimed then
			ui.Locked.Visible = false
			ui.Redeem.Visible = true
			ui.Redeem.TextLabel.Text = "CLAIMED"
			ui.Countdown.Visible = false
			continue
		end

		local leftTime = info.Duration - rewardsPlaytime 

		if leftTime > 0 then
			local timeFormat = GlobalFunctions.FormatTime(leftTime)
			ui.Locked.Visible = true
			ui.Redeem.Visible = false
			ui.Countdown.Text = timeFormat
			ui.Countdown.Visible = true
		else
			ui.Redeem.TextLabel.Text = "CLAIM"
			ui.Redeem.Visible = true
			ui.Locked.Visible = false
			ui.Countdown.Text = "READY"
		end
	end

	--PlaytimeRewardFrame.Reset.Text = "Reset in " .. GlobalFunctions.FormatTime(Data.ResetTimestamp - now)
end

function PlaytimeRewardsController:init()
	Data = ReplicationController.Subscribe(`{Player.UserId}_PlaytimeRewards`)
	ReplicationController.GetSignal(`{Player.UserId}_PlaytimeRewards`):Connect(function (data)
		Data = data
		UpdateUi()
	end)
	
	for index, _ in PlaytimeRewardsConfg.Rewards do
		local ui = Container:FindFirstChild(index)
		ui.Redeem.MouseButton1Click:Connect(function ()
			Packets.PlaytimeRewards.ClaimReward:Fire(index)
		end)
	end
end

function PlaytimeRewardsController:start()
	while task.wait(1) do
		UpdateUi()
	end
end

return PlaytimeRewardsController
