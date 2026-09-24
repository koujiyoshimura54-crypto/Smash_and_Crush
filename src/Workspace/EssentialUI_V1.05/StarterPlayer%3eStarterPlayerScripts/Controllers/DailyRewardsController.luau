local DailyRewardsController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Confg  = ReplicatedStorage.Configuration

local Packets = require(ReplicatedStorage.Utils.Packets)
local Frames = require(script.Parent.UiController.Frames)
local DailyRewardsConfg = require(Confg.DailyRewards)
local ReplicationController = require(script.Parent.ReplicationController)
local NotificationController = require(script.Parent.NotificationController)
local GlobalSignals = require(script.Parent.Parent.Utils.GlobalSignals)
local GlobalFunctions = require(ReplicatedStorage.Utils.GlobalFunctions)

local DailyRewardsFrame = Frames.DailyRewards
local Container = DailyRewardsFrame.Holder

local Data = {} :: {
	StartTimestamp:number,
	ClaimedRewards:{[number]:boolean}
}

local function UpdateUi()
	if not Data or not Data.StartTimestamp then return end
	
	local now = os.time()
	local totalTime = now - Data.StartTimestamp
	
	for i = 1, 7 do
		local ui = Container:FindFirstChild(i)
		if Data["ClaimedRewards"][i] then
			ui.Locked.Visible = false
			ui.Redeem.TextLabel.Text = "CLAIMED"
			ui.Redeem.Visible = true
			ui.DayText.Text = "Day " .. i
			continue
		end
		
		local leftTime = ((i-1) * 24 * 60 * 60) - totalTime
		if leftTime > 24 * 60 * 60 then
			ui.Redeem.Visible = false
			ui.Locked.Visible = true
			ui.DayText.Text = "Day ".. i
			continue
		elseif leftTime > 0 then
			ui.Redeem.Visible = false
			ui.Locked.Visible = true
			ui.DayText.Text = GlobalFunctions.FormatTime(leftTime)
			continue
		end
		
		
		ui.Redeem.TextLabel.Text = "CLAIM"
		ui.Redeem.Visible = true
		ui.Locked.Visible = false
	end
end

function DailyRewardsController:init()
	Data = ReplicationController.Subscribe(`{Player.UserId}_DailyRewards`)
	ReplicationController.GetSignal(`{Player.UserId}_DailyRewards`):Connect(function (data)
		Data = data
		UpdateUi()
	end)
	
	for _, item:Frame in DailyRewardsFrame.Holder:GetChildren() do
		if not item:IsA("Frame") then continue end
		local info = DailyRewardsConfg[tonumber(item.Name)]
		item.Decor.Icon.Image = "rbxassetid://" .. info.Icon
		item.RewardText.Text = info.Text
	end

	for i = 1, 7 do
		local ui = Container:FindFirstChild(i)
		ui.Redeem.MouseButton1Click:Connect(function ()
			Packets.DailyRewards.ClaimReward:Fire(i)
		end)
	end
end

function DailyRewardsController:start()
	while task.wait(1) do
		UpdateUi()
	end
end

return DailyRewardsController
