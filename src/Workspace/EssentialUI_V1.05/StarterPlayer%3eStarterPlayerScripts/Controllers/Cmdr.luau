local Players = game:GetService("Players")
local Rep = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local GeneralConfig = require(Rep.Configuration.General)

local m = {}
function m:start()
	local IsAdmin = table.find(GeneralConfig.Admins, Player.UserId)
	if not IsAdmin then return end

	local Cmdr = require(Rep:WaitForChild("CmdrClient"))
	Cmdr:SetActivationKeys({Enum.KeyCode.F2})
end
return m


