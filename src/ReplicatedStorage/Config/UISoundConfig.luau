local Config = {}

Config.CoinCollect = table.freeze({
	SoundId = "rbxassetid://101429032102613",
	Volume = 0.55,
	PlaybackSpeed = 1,
})

-- Added feedback only. Existing CoinCollect and SoundService objects stay unchanged.
Config.Added = table.freeze({
 Hover={Sound="Hover",Volume=0.22,Speed=1,Interval=0.09},
 Click={Sound="Click",Volume=0.65,Speed=1,Interval=0.035},
 Rebirth={Sound="Winner",Volume=1,Speed=1,Interval=0.15},
 Offline={Sound="Success",Volume=1,Speed=1,Interval=0.12},
 Merge={Sound="Success",Volume=1,Speed=1,Interval=0.12},
 Sale={Sound="Cash",Volume=1,Speed=1,Interval=0.12},
 Purchase={Sound="Success",Volume=1,Speed=1,Interval=0.12},
 WinReward={Sound="Cash",Volume=1,Speed=1,Interval=0.12},
 Reward={Sound="Success",Volume=1,Speed=1,Interval=0.12},
 Denied={Sound="Error",Volume=0.8,Speed=1,Interval=0.3},
 Level={Sound="Notification",Volume=0.8,Speed=1,Interval=0.15},
})

return table.freeze(Config)
