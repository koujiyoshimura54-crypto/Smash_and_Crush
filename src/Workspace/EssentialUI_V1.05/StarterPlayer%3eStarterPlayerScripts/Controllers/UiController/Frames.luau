local Player = game.Players.LocalPlayer
local ScreenGui = Player.PlayerGui:WaitForChild("Main")
local Frames = ScreenGui.Frames

return {
	["Shop"] = Frames.Shop,
	["GiftPlayerChoose"] = Frames.Gifting,
	["GiftConfirm"] = Frames.Confirm,
	["PlaytimeRewards"] = Frames.TimeRewards,
	["DailyRewards"] = Frames.DailyRewards,
	["Codes"] = Frames.Codes,
	["GroupReward"] = Frames.Group,
	["WheelSpin"] = Frames.Wheel,
	["Settings"] = Frames.Settings,
	["FriendInvite"] = Frames.Friends
}