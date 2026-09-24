local TopbarController = {}


local Icon = require(game:GetService("ReplicatedStorage").Packages.Icon)
local UiCon = require(script.Parent.UiController)

function TopbarController:init()
	Icon.new()
		:setImage(106769461169677)
		:setImageScale(.8)
		:setImageRatio(1)
		:align("Right")
		:bindEvent("toggled", function ()
			UiCon:OpenFrame("Settings")
		end)

end

return TopbarController
