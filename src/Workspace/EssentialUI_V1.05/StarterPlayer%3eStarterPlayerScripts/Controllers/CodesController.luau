local CodesController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Packets = require(ReplicatedStorage.Utils.Packets)
local Frames = require(script.Parent.UiController.Frames)
local NotificationController = require(script.Parent.NotificationController)
local GlobalSignals = require(script.Parent.Parent.Utils.GlobalSignals)
local GlobalFunctions = require(ReplicatedStorage.Utils.GlobalFunctions)

local CodesFrame = Frames.Codes
local CodeInput = CodesFrame.TextCode
local RedeemBtn = CodesFrame.Redeem

function CodesController:init()
	RedeemBtn.MouseButton1Click:Connect(function ()
		local code = CodeInput.Text
		local response
		
		RedeemBtn.Interactable = false
		local text = RedeemBtn.Text
		RedeemBtn.Text = "..."
		
		local success, err = pcall(function ()
			if code == "" then response = {"Error", "Enter Code First"} return end
			
			local data = Packets.Codes.RedeemCode:Fire(code)
			response = data
		end)
		
		RedeemBtn.Text = text
		RedeemBtn.Interactable = true
		
		if success and response then
			NotificationController:Prompt(response[1], response[2])
		else
			NotificationController:Prompt("Error", "Something wrong happend")
		end
	end)
end

return CodesController
