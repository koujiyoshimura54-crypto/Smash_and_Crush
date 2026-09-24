local GroupRewardController = {}

local Player = game:GetService("Players").LocalPlayer

local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedUtils = ReplicatedStorage.Utils
local Config = ReplicatedStorage.Configuration
local GeneralConfig = require(Config.General)
local Packets = require(ReplicatedUtils.Packets)
local ReplicationController = require(script.Parent.ReplicationController)

local Frames = require(script.Parent.UiController.Frames)
local GroupFrame = Frames.GroupReward
local RedeemBtn = GroupFrame.Redeem
local RedeemedBtn = GroupFrame.Redeemed

local InGroup

local function UpdateUi()
	if InGroup[1] then 
		RedeemBtn.Visible = false
		RedeemedBtn.Visible = true
	else
		RedeemBtn.Visible = true
		RedeemedBtn.Visible = false
	end
end

function GroupRewardController:init()
	InGroup = ReplicationController.Subscribe(`{Player.UserId}_GroupReward`)
	ReplicationController.GetSignal(`{Player.UserId}_GroupReward`):Connect(function (data)
		InGroup = data
		UpdateUi()
	end)
	UpdateUi()
	
	RedeemBtn.MouseButton1Click:Connect(function ()
		local res = Packets.GroupReward.ClaimReward:Fire()
		
		if not res then
			GroupService:PromptJoinAsync(GeneralConfig.GroupID)
		end
	end)
	
end

return GroupRewardController
