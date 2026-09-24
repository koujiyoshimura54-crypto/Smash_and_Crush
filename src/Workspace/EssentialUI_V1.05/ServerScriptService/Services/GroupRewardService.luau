local GroupRewardService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedUtils = ReplicatedStorage.Utils
local GlobalFunctions = require(ReplicatedUtils.GlobalFunctions)
local GeneralConfig = require(ReplicatedStorage.Configuration.General)
local DataService = require(script.Parent.DataService)
local ReplicationService = require(script.Parent.ReplicationService)
local Packets = require(ReplicatedUtils.Packets)
local GlobalSignals = require(ServerScriptService.Utils.GlobalSignals)

local REWARD_RETRIES = 3

local function RewardPlayer(player:Player)
	print("Group Reward")
end

local RedeemingPlayers = {}

function GroupRewardService:init()
	GlobalSignals.DataService.PlayerProfileLoaded:Connect(function (player:Player, profile)
		ReplicationService.new(`{player.UserId}_GroupReward`, {profile.GroupReward}, false, {player})
	end)
	
	Packets.GroupReward.ClaimReward.OnServerInvoke = function (player:Player)
		if RedeemingPlayers[player] then
			return false
		end

		RedeemingPlayers[player] = true

		local response
		local success, err = pcall(function()
			local claimed = DataService:Get(player, "GroupReward")
			if claimed then
				Packets.Notification.Prompt:FireClient(player, "Error", "Already Claimed")
				response = true
				return 
			end
			local success, isInGroup = pcall(function ()
				return player:IsInGroupAsync(GeneralConfig.GroupID)
			end)

			if not success then
				Packets.Notification.Prompt:FireClient(player, "Error", "Something wrong happend, try again later")
				response = false
				return 
			end

			if isInGroup then
				local success, _ = GlobalFunctions.Retry(function () RewardPlayer(player) end, REWARD_RETRIES)

				if success then
					DataService:Set(player, "GroupReward", true)
					Packets.Notification.Prompt:FireClient(player, "Success", "Claimed Successfully 🎊")
					response = true
					local entry = ReplicationService.new(`{player.UserId}_GroupReward`)
					entry.Data = {true}
					entry:PushData()
					return
				end
				Packets.Notification.Prompt:FireClient(player, "Error", "Something wrong happend, try again later")
				response = true
				return
			end

			Packets.Notification.Prompt:FireClient(player, "Error", "You must join the group first")
			response = false
		end)
		
		RedeemingPlayers[player] = nil

		if not success then
			warn(err)
			return false
		end

		return response
	end
end

return GroupRewardService
