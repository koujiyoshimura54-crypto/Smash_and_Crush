local LemonSignal = require(game.ReplicatedStorage.Packages.LemonSignal)
return {
	UI = {
		["OpenFrame"] = LemonSignal.new() :: LemonSignal.Signal<string, boolean>,
		["CloseFrame"]= LemonSignal.new() :: LemonSignal.Signal<boolean>,
	}
}