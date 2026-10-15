local Config = {}

Config.ShopShake = {
	everySeconds = 5,
	angle = 20,
	swings = 4,
	swingSeconds = 0.09,
}

Config.Menu = {
	seconds = 0.2,
	blurSize = 30,
	margin = 0.05,
}

Config.Button = {
	hoverScale = 0.9,
	pressScale = 0.8,
	seconds = 0.1,
}

Config.Music = {
	gapSeconds = 2,

	loadSeconds = 10,
}

Config.Egg = {
	rise = 0.6,
	seconds = 4,

	reach = 15,

	openSeconds = 0.2,

	tie = math.rad(5),

	width = 0.48,

	margin = 0.02,

	catchUp = 6,

	cardWidth = 0.2,
	cardHeight = 0.204,
}

Config.Eggs = {
	percentFormat = "%g%%",

	titleFormat = "%s Egg",

	shortText = "Not Enough Wins!",

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	Buttons = {
		Open1 = 1,
		Open3 = 3,
		Open8 = 8,
	},

	Eggs = {
		Basic = {
			wins = 15,

			Pets = {
				["Camel"] = 3,
				["Bear"] = 7,
				["Sheep"] = 10,
				["Pink Bunny"] = 15,
				["Grey Cat"] = 25,
				["Dog"] = 40,
			},
		},

		Rare = {
			wins = 100,

			Pets = {
				["Bat"] = 3,
				["Spider"] = 7,
				["Lizard"] = 10,
				["Lion"] = 15,
				["Giraffe"] = 25,
				["Cow"] = 40,
			},
		},

		Legendary = {
			wins = 300,

			Pets = {
				["Shark"] = 3,
				["Octopus"] = 7,
				["Crocodile"] = 10,
				["Penguin"] = 15,
				["Mammoth"] = 25,
				["Elephant"] = 40,
			},
		},

		Mythic = {
			wins = 1_000,

			Pets = {
				["Evil Dragon"] = 3,
				["Scorpion"] = 7,
				["Dino"] = 10,
				["Anglerfish"] = 15,
				["Alien"] = 25,
				["Turtle"] = 40,
			},
		},
	},
}

Config.Speed = {
	tickSeconds = 0.25,

	flushSeconds = 1,

	minSpeed = 10,
	maxSpeed = 100,
	minCooldown = 0.1,
	maxCooldown = 0.2,

	baseWalkSpeed = 25,
	perLevel = 2,
	maxWalkSpeed = 200,
}

Config.Collision = {
	group = "Characters",

	tolerance = 1.5,

	riseCeiling = 100,
}

Config.Treadmills = {
	Normal = { multiplier = 1, rebirth = 0 },
	Iron = { multiplier = 25, rebirth = 1 },
	Gold = { multiplier = 100, rebirth = 3 },
	Diamond = { multiplier = 250, rebirth = 6 },
	Emerald = { multiplier = 500, rebirth = 9 },
	Candy = { multiplier = 1_000, rebirth = 12 },
	Devil = { multiplier = 2_000, rebirth = 16 },
}

Config.Belt = {
	tickSeconds = 0.25,

	fadeSeconds = 0.15,

	authoredSpeed = 16,
	maxRate = 2.5,
}

Config.Event = {
	model = "EventTreadmil",

	everySeconds = 15 * 60,
	liveSeconds = 3 * 60,

	tickSeconds = 0.25,

	multiplier = 2,

	multiplierFormat = "x%g Speed",
	timerFormat = "%dm %ds",

	scrollSeconds = 2,

	multiplierColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 170, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(0, 170, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
	}),

	notifyFormat = "A x%g Treadmill Spawned At Spawn!",
	waitFormat = "It Is Only Here For %g Minutes!",

	from = Color3.fromRGB(255, 255, 255),
	to = Color3.fromRGB(0, 161, 220),
}

Config.Multipliers = {
	{ perStep = 1, wins = 0 },
	{ perStep = 3, wins = 5 },
	{ perStep = 10, wins = 25 },
	{ perStep = 50, wins = 300 },

	{ perStep = 100, wins = 3_000 },
	{ perStep = 500, wins = 50_000 },
	{ perStep = 2500, wins = 300_000 },
	{ perStep = 10000, wins = 5_000_000 },

	{ perStep = 15_000, wins = 10_000_000 },
	{ perStep = 25_000, wins = 25_000_000 },
	{ perStep = 50_000, wins = 50_000_000 },
	{ perStep = 67_000, wins = 67_000_000 },
}

Config.PerStep = {
	shortFormat = "You need %s more wins!",
	orderText = "Buy the previous upgrade first!",

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),
}

Config.Float = {
	studs = 0.75,

	seconds = 2.5,
}

Config.SpeedProducts = {
	percentFrom = 10_000_000,

	priceFormat = "\u{E002}%d",

	Buttons = {
		Buy1 = { product = "Speed100K", amount = 100_000, percent = 0.1 },
		Buy2 = { product = "Speed1M", amount = 1_000_000, percent = 0.5 },
		Buy3 = { product = "Speed10M", amount = 10_000_000, percent = 1 },
	},
}

Config.Rebirths = {
	{ level = 4, multiplier = 5 },
	{ level = 15, multiplier = 10 },
	{ level = 30, multiplier = 16 },
	{ level = 45, multiplier = 24 },
	{ level = 58, multiplier = 34 },
	{ level = 71, multiplier = 46 },

	{ level = 86, multiplier = 60 },
	{ level = 100, multiplier = 76 },
	{ level = 113, multiplier = 95 },
	{ level = 122, multiplier = 116 },
	{ level = 130, multiplier = 140 },
	{ level = 139, multiplier = 168 },

	{ level = 148, multiplier = 200 },
	{ level = 158, multiplier = 280 },
	{ level = 169, multiplier = 400 },
	{ level = 181, multiplier = 560 },
	{ level = 194, multiplier = 780 },
	{ level = 208, multiplier = 1_100 },
	{ level = 223, multiplier = 1_500 },
	{ level = 239, multiplier = 2_100 },
}

Config.Rebirth = {
	takenFormat = "Rebirth %d (x%.1f) > Rebirth %d (x%.1f)",

	soundPath = { "UI", "Success" },

	from = Color3.fromRGB(235, 180, 255),
	to = Color3.fromRGB(150, 0, 255),
}

Config.Levels = {
	base = 100,
	growth = 1.16,
}

Config.SpeedPop = {
	width = 4.5,
	height = 1.5,
	spreadX = 4,
	riseMin = 3,
	riseMax = 5,
	spreadZ = 2,
	punchSeconds = 0.4,
	throwSeconds = 0.6,
	holdSeconds = 0.5,
	fadeSeconds = 0.3,
}

Config.Leaderboard = {
	refreshSeconds = 300,
	slots = 50,
	timerFormat = "Refresh In: %dm %ds",
	emptyName = "Empty",
	emptyAmount = "0",

	Boards = {
		Wins = { field = "wins" },
		Speed = { field = "speed" },
		Rebirths = { field = "rebirth" },

		Playtime = { field = "playtime", format = "clock" },

		Robux = { field = "robux", format = "commas" },
	},
}

Config.SpeedHud = {
	catchUp = 12,
	barCatchUp = 8,

	multiplierFormat = "Multiplier x%s",
	exactFormat = "%g",
	exactBelow = 1000,

	stackTitle = "Multipliers",

	stackFormat = "%s +%s",
	stackFinalFormat = "%s x%s",

	stackPercentFormat = "%s +%d%%",

	stackNone = "Nothing Yet!",

	cardWidth = 0.74,
	cardRow = 0.185,
	cardTitleShare = 1,
	cardPadShare = 0.24,
	cardPadX = 0.07,
	cardPadY = 0.28,
	cardGap = 0.025,
	cardZIndex = 12,

	cardTextShare = 0.8,
	cardTitleTextShare = 0.8,
	cardIconShare = 1,

	cardStrokeShare = 0.85,

	Stack = {
		{ key = "treadmill", title = "Treadmill" },
		{ key = "rebirth", title = "Rebirths", icon = "Rebirth" },
		{ key = "pet", title = "Pet" },
		{ key = "trail", title = "Trail" },
		{ key = "boost", title = "Potion", icon = "BluePotion", final = true },
		{ key = "pass", title = "Speed Pass", icon = "Shoe", final = true },
		{ key = "friends", title = "Friends", icon = "Friends", final = true, percent = true },
		{ key = "premium", title = "Premium", icon = "Premium", final = true, percent = true },
		{ key = "time", title = "Time Played", icon = "Hourglass", final = true, percent = true },

		{ key = "streak", title = "Daily Streak", icon = "Fire", final = true, percent = true },

		{ key = "items", title = "Items", icon = "Inventory", final = true, percent = true },

		{ key = "weather", title = "Event", icon = "Star", final = true },
	},
}

Config.Remind = {
	minSeconds = 20,
	maxSeconds = 30,

	Sources = {
		{ key = "rebirth", text = "Your Rebirth Is Ready!", from = Color3.fromRGB(215, 180, 255), to = Color3.fromRGB(140, 0, 255) },
		{ key = "daily", text = "Your Daily Reward Is Ready!", from = Color3.fromRGB(190, 255, 170), to = Color3.fromRGB(0, 170, 60) },
		{ key = "playtime", text = "A Playtime Reward Is Ready!", from = Color3.fromRGB(255, 255, 130), to = Color3.fromRGB(0, 200, 60) },
		{ key = "quests", text = "A Quest Is Ready To Claim!", from = Color3.fromRGB(190, 255, 170), to = Color3.fromRGB(0, 170, 60) },

		{ key = "codes", format = "Use Code %s For %s!", atJoin = true, from = Color3.fromRGB(140, 225, 255), to = Color3.fromRGB(0, 110, 255) },
	},
}

Config.Notify = {
	middle = 0.17,

	width = 1,

	lineHeight = 0.036,
	lineWidth = 0.72,

	linePadding = 0.02,

	shadeRotation = 0,
	shadeMargin = 0.015,

	shadePad = 0.035,

	shadeScale = 1.1,
	textScale = 1.25,

	Shade = { 0, 0.125, 0.375, 0.5 },

	seconds = 3,
	openSeconds = 0.25,
	closeSeconds = 0.2,

	maxStanding = 3,
	maxWaiting = 6,

	strokeShare = 0.0021,
}

Config.LevelUp = {
	levelFormat = "Level Up! (%s > %s)",
	walkFormat = "New Walk Speed: %s > %s",

	from = Color3.fromRGB(140, 225, 255),
	to = Color3.fromRGB(0, 110, 255),
}

Config.Boosts = {
	seconds = 10 * 60,
	maxSeconds = 4 * 60 * 60,
	tickSeconds = 1,

	useFormat = "Use (%s)",

	activatedFormat = "%s Activated (%d Minutes)",

	shortFormat = "%02d:%02d",
	longFormat = "%d:%02d:%02d",

	multiplierFormat = "x%.2f",

	Kinds = {
		["2xPerStep"] = { field = "speed", multiplier = 2, icon = "BluePotion", from = Color3.fromRGB(140, 225, 255), to = Color3.fromRGB(0, 110, 255) },
		["2xPerWin"] = { field = "wins", multiplier = 2, icon = "YellowPotion", hoverIcon = "Trophy", from = Color3.fromRGB(255, 240, 130), to = Color3.fromRGB(255, 140, 0) },
	},
}

Config.Bonuses = {
	perFriend = 0.1,
	maxFriends = 3,
	premium = 0.1,

	perTime = 0.05,
	timeSeconds = 5 * 60,
	maxTimeSteps = 4,

	recheckSeconds = 10,

	recheckPlayers = 8,

	friendsFrame = "Friends",
	premiumFrame = "Premium",
	timeFrame = "Time",

	speedDescription = "SpeedDescription",
	trophyDescription = "TrophyDescription",

	percentFormat = "%d%%",
}

Config.TrailWear = {
	side = 0,
	drop = 1,
	back = 0,
}

Config.Trails = {
	Rainbow = {
		multiplier = 600,
		wins = 3_000_000,
		pass = 1966230808,
		Colors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 170, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 170, 255),
			Color3.fromRGB(255, 0, 255),
		},
	},

	Candy = {
		multiplier = 400,
		wins = 1_500_000,
		pass = 1962216994,
		Colors = {
			Color3.fromRGB(255, 170, 255),
			Color3.fromRGB(255, 0, 170),
		},
	},

	Fire = {
		multiplier = 260,
		wins = 600_000,
		pass = 1963585042,
		Colors = {
			Color3.fromRGB(255, 230, 0),
			Color3.fromRGB(255, 60, 0),
		},
	},

	Chocolate = {
		multiplier = 150,
		wins = 250_000,
		pass = 1965619029,
		Colors = {
			Color3.fromRGB(170, 120, 80),
			Color3.fromRGB(80, 45, 20),
		},
	},

	Toxic = {
		multiplier = 80,
		wins = 100_000,
		pass = 1965331050,
		Colors = {
			Color3.fromRGB(190, 255, 0),
			Color3.fromRGB(30, 140, 0),
		},
	},

	Diamond = {
		multiplier = 35,
		wins = 20_000,
		pass = 1962403067,
		Colors = {
			Color3.fromRGB(200, 255, 255),
			Color3.fromRGB(0, 145, 255),
		},
	},

	Iron = {
		multiplier = 10,
		wins = 2_000,
		pass = 1962925060,
		Colors = {
			Color3.fromRGB(220, 220, 220),
			Color3.fromRGB(90, 90, 90),
		},
	},
}

Config.Cheap = {
	everySeconds = 2,
	grow = 1.1,
	shrink = 0.9,
	beats = 4,
	beatSeconds = 0.1,

	priceFormat = "ONLY %d!",

	Tiles = {
		speed = {
			frame = "SpeedCheap",
			Tiers = {
				{ field = "speed", multiplier = 2, title = "2x Speed" },
				{ field = "speed3", multiplier = 3, title = "3x Speed" },
				{ field = "speed4", multiplier = 4, title = "4x Speed" },
				{ field = "speed5", multiplier = 5, title = "5x Speed" },
				{ field = "speed6", multiplier = 6, title = "6x Speed" },
				{ field = "speed7", multiplier = 7, title = "7x Speed" },
				{ field = "speed8", multiplier = 8, title = "8x Speed" },
			},
		},

		wins = {
			frame = "WinsCheap",
			Tiers = {
				{ field = "wins", multiplier = 2, title = "2x Wins" },
				{ field = "wins3", multiplier = 3, title = "3x Wins" },
			},
		},
	},

	Trophy = {
		tile = "wins",

		model = "Trophy",
		press = "Buy",
		board = "BillboardGui",

		adornee = "PartMain",
	},
}

Config.Limited = {
	frame = "Limited",

	menu = "Shop",
	scroll = 200,

	everySeconds = 5,
	shrink = 0.85,
	grow = 1.1,
	beatSeconds = 0.15,

	spin = 180,
	spinSeconds = 6,

	tilt = 5,
	tiltSeconds = 1.2,
}

Config.Leave = {
	frame = "Offline",

	seconds = 2,

	speed = 20_000,

	doubleFrom = 20_000,

	amountFormat = "+%s",
}

Config.Leaderstats = {
	{ name = "Level", source = "level", exact = true },
	{ name = "Speed", source = "speed", exact = false },
	{ name = "Wins", source = "wins", exact = false },
}

Config.Stand = {
	name = "Chill Octopus",
	priceFormat = "ONLY %d",
	scrollSeconds = 2,
}

Config.Gift = {
	name = "Gift",

	scrollSeconds = 2,
}

Config.WinsGift = {
	model = "WinsGift",
	frame = "FreeWins",

	scrollSeconds = 2,

	field = "winsGift",
	claimedField = "winsGiftClaimed",

	waitSeconds = 25 * 60,

	tickSeconds = 1,

	bankSeconds = 10,

	share = 0.5,
	minimum = 25_000,

	prizeFormat = "+%s Wins",
	amountFormat = "%d/%d",
	claimedText = "Claimed",

	grantedStatus = "granted",
	waitingStatus = "waiting",
	claimedStatus = "claimed",

	tookText = "Free Wins Claimed!",
	tookFormat = "+%s Wins",

	waitingFormat = "Play %d More Minutes First!",
	notReadyText = "Not Ready Yet!",
	doneText = "You Already Claimed This!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	Claimed = {
		border = Color3.fromRGB(118, 0, 0),
		borderLine = Color3.fromRGB(64, 0, 0),

		faceFrom = Color3.fromRGB(255, 137, 137),
		faceTo = Color3.fromRGB(255, 0, 0),

		edgeFrom = Color3.fromRGB(255, 199, 199),
		edgeTo = Color3.fromRGB(255, 35, 35),
	},
}

Config.WinButtons = {
	tag = "WinButton",

	premiumTag = "WinButtonPremium",
	product = "WinButtonPremium",

	tickSeconds = 0.2,
	reach = 6,
	defaultAmount = 1,
	amountFormat = "+%s Wins",

	wonFormat = "+%s Wins",
	from = Color3.fromRGB(255, 240, 130),
	to = Color3.fromRGB(255, 140, 0),

	menu = "Shop",
	scroll = 694.32,

	Stages = {

		["1"] = { amount = 33, premium = 66 },
		["2"] = { amount = 66, premium = 132 },
		["3"] = { amount = 137, premium = 274 },
		["4"] = { amount = 273, premium = 546 },
		["5"] = { amount = 481, premium = 962 },
		["6"] = { amount = 765, premium = 1_530 },
		["7"] = { amount = 1_090, premium = 2_180 },

		["8"] = { amount = 1_790, premium = 3_580 },
		["9"] = { amount = 2_390, premium = 4_780 },
		["10"] = { amount = 3_200, premium = 6_400 },

		["11"] = { amount = 3_920, premium = 7_840 },
		["12"] = { amount = 4_770, premium = 9_540 },
		["13"] = { amount = 5_810, premium = 11_620 },
		["14"] = { amount = 7_120, premium = 14_240 },
		["15"] = { amount = 8_690, premium = 17_380 },
		["16"] = { amount = 10_600, premium = 21_200 },
		["17"] = { amount = 12_900, premium = 25_800 },
		["18"] = { amount = 15_800, premium = 31_600 },
		["19"] = { amount = 19_300, premium = 38_600 },

		["20"] = { amount = 23_500, premium = 47_000 },

		["21"] = { amount = 29_300, premium = 58_600 },
		["22"] = { amount = 35_700, premium = 71_400 },
		["23"] = { amount = 43_600, premium = 87_200 },
		["24"] = { amount = 53_200, premium = 106_400 },
		["25"] = { amount = 64_900, premium = 129_800 },
		["26"] = { amount = 79_200, premium = 158_400 },
		["27"] = { amount = 96_700, premium = 193_400 },
		["28"] = { amount = 118_000, premium = 236_000 },
		["29"] = { amount = 144_000, premium = 288_000 },
		["30"] = { amount = 176_000, premium = 352_000 },
		["31"] = { amount = 215_000, premium = 430_000 },
		["32"] = { amount = 261_000, premium = 522_000 },

		["33"] = { amount = 321_000, premium = 642_000 },
		["34"] = { amount = 392_000, premium = 784_000 },
		["35"] = { amount = 478_000, premium = 956_000 },
		["36"] = { amount = 582_000, premium = 1_164_000 },
		["37"] = { amount = 711_000, premium = 1_422_000 },
		["38"] = { amount = 867_000, premium = 1_734_000 },
		["39"] = { amount = 1_060_000, premium = 2_120_000 },
		["40"] = { amount = 1_290_000, premium = 2_580_000 },
	},
}

Config.Stages = {
	resetName = "Reset",
	titleFormat = "Stage %s",
	reach = 2,

	bump = 6,

	spawnOffset = 5,

	streamSeconds = 3,

	product = "StageSkip",

	leastDamage = 1,

	hitSeconds = 0.15,

	bounceStuds = 10,
	bounceSeconds = 0.35,
	bounceLead = 0.4,

	bounceEase = 2,

	autoRunHits = 10,

	Skip = {
		folder = "WinButtons",
		model = "SkipStage",
		press = "Press",

		reach = 6,
	},

	Health = {
		frame = "Health",
		amount = "Amount",
		Bar = { "Separate", "Bar" },
		gradient = "UIGradient",
		format = "%s/%s",

		halfBelow = 2 / 3,
		lowBelow = 1 / 3,

		Full = { from = Color3.fromRGB(255, 255, 0), to = Color3.fromRGB(0, 255, 0) },
		Half = { from = Color3.fromRGB(255, 240, 130), to = Color3.fromRGB(255, 140, 0) },
		Low = { from = Color3.fromRGB(255, 164, 164), to = Color3.fromRGB(255, 0, 0) },
	},

	Hit = {
		width = 50,
		height = 6,

		spreadX = 3,
		riseMin = 4,
		riseMax = 6,

		punchSeconds = 0.25,
		throwSeconds = 0.6,
		holdSeconds = 0.5,
		fadeSeconds = 0.3,

		format = "-%s",
		color = Color3.fromRGB(255, 255, 255),
		thickness = 3,
	},

	Knock = {
		volume = 0.75,

		flash = 0.35,

		camera = 0.3,

		dust = 0.3,
	},

	Walls = {
		["1"] = { health = 10 },

		["2"] = { health = 260 },
		["3"] = { health = 1_500 },
		["4"] = { health = 50_000 },
		["5"] = { health = 150_000 },

		["6"] = { health = 1_000_000 },
		["7"] = { health = 5_000_000 },
		["8"] = { health = 16_500_000 },
		["9"] = { health = 30_000_000 },
		["10"] = { health = 66_000_000 },

		["11"] = { health = 120_000_000 },
		["12"] = { health = 270_000_000 },

		["13"] = { health = 495_000_000 },
		["14"] = { health = 1_110_000_000 },
		["15"] = { health = 1_950_000_000 },
		["16"] = { health = 3_000_000_000 },
		["17"] = { health = 4_800_000_000 },
		["18"] = { health = 9_000_000_000 },
		["19"] = { health = 14_100_000_000 },
		["20"] = { health = 33_000_000_000 },

		["21"] = { health = 76_000_000_000 },
		["22"] = { health = 125_000_000_000 },
		["23"] = { health = 192_000_000_000 },
		["24"] = { health = 338_000_000_000 },
		["25"] = { health = 540_000_000_000 },
		["26"] = { health = 1_000_000_000_000 },
		["27"] = { health = 1_620_000_000_000 },
		["28"] = { health = 2_590_000_000_000 },
		["29"] = { health = 4_190_000_000_000 },
		["30"] = { health = 6_750_000_000_000 },
		["31"] = { health = 10_800_000_000_000 },
		["32"] = { health = 17_300_000_000_000 },

		["33"] = { health = 30_300_000_000_000 },
		["34"] = { health = 53_000_000_000_000 },
		["35"] = { health = 92_800_000_000_000 },
		["36"] = { health = 162_000_000_000_000 },
		["37"] = { health = 284_000_000_000_000 },
		["38"] = { health = 497_000_000_000_000 },
		["39"] = { health = 870_000_000_000_000 },
		["40"] = { health = 1_520_000_000_000_000 },
	}
}

Config.StageBreak = {
	columns = 8,
	rows = 4,

	forward = 45,
	up = 50,
	spread = 22,
	spin = 720,

	burst = 95,
	burstFalloff = 30,
	least = 0.45,

	seconds = 1,
	shrinkSeconds = 0.6,

	dustSeconds = 1.6,

	Flash = {
		color = Color3.fromRGB(255, 240, 200),
		thickness = 1,
		transparency = 0.5,

		from = 0.9,
		grow = 1.2,

		riseSeconds = 0.1,
		seconds = 0.5,

		brightness = 1,
		range = 30,
	},

	Shockwave = {
		color = Color3.fromRGB(255, 255, 255),
		size = 6,
		radius = 55,
		transparency = 0.55,
		seconds = 0.35,
	},

	Dust = {
		texture = "rbxasset://textures/particles/smoke_main.dds",
		color = Color3.fromRGB(220, 214, 200),
		count = 70,
		size = 16,
		transparency = 0.25,
		life = NumberRange.new(0.5, 1.2),
		speed = NumberRange.new(25, 75),
		spread = 55,
		spin = 90,
		drag = 2.5,
		gravity = 40,
		light = 0,
	},

	Sparks = {
		texture = "rbxasset://textures/particles/sparkles_main.dds",
		color = Color3.fromRGB(255, 235, 150),
		count = 50,
		size = 3,
		transparency = 0,
		life = NumberRange.new(0.3, 0.8),
		speed = NumberRange.new(60, 150),
		spread = 40,
		spin = 0,
		drag = 1,
		gravity = 90,
		light = 1,
	},

	Camera = {
		strength = 1.2,
		maxStrength = 3,
		angle = 2.5,
		seconds = 0.65,
		fade = 1.4,

		fieldOfView = 8,
		fieldSeconds = 0.65,
	},

	Sound = {
		volume = 1.15,
		pitch = 0.06,

		comboSeconds = 3,
		comboStep = 0.06,
		comboSteps = 10,

		lifeSeconds = 5,
	},
}

Config.Rarities = {
	Common = { Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 150) } },
	Uncommon = { Colors = { Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0) } },
	Rare = { Colors = { Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 145, 255) } },
	Epic = { Colors = { Color3.fromRGB(255, 170, 255), Color3.fromRGB(255, 0, 255) } },
	Legendary = { Colors = { Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 170, 0) } },
	Mythic = { Colors = { Color3.fromRGB(255, 191, 0), Color3.fromRGB(255, 0, 0) } },

	Rainbow = {
		rotation = 0,
		trail = "Rainbow",

		Colors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 170, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 170, 255),
			Color3.fromRGB(255, 0, 255),
		},
	},
}

Config.Pets = {
	["Chill Octopus"] = { percent = 200, rarity = "Rainbow" },

	["Poseidon"] = { percent = 150, rarity = "Rainbow" },
	["Crystal Unicorn"] = { percent = 125, rarity = "Rainbow" },
	["Pharaoh"] = { percent = 50, rarity = "Rainbow" },
	["Metal Dominus"] = { percent = 75, rarity = "Rainbow" },

	["Chimpanzini Bananini"] = { percent = 100, rarity = "Rainbow" },
	["Ninja"] = { percent = 75, rarity = "Rainbow" },

	["Shroom"] = { percent = 75, rarity = "Rainbow" },

	["Inferno Axolotl"] = { percent = 75, rarity = "Rainbow" },

	["Slime"] = { percent = 25, rarity = "Rainbow" },

	["Evil Dragon"] = { multiplier = 500, rarity = "Mythic" },
	["Scorpion"] = { multiplier = 450, rarity = "Mythic" },
	["Dino"] = { multiplier = 400, rarity = "Mythic" },
	["Anglerfish"] = { multiplier = 350, rarity = "Mythic" },
	["Alien"] = { multiplier = 300, rarity = "Mythic" },
	["Turtle"] = { multiplier = 250, rarity = "Mythic" },

	["Shark"] = { multiplier = 200, rarity = "Legendary" },
	["Octopus"] = { multiplier = 180, rarity = "Legendary" },
	["Crocodile"] = { multiplier = 160, rarity = "Legendary" },
	["Penguin"] = { multiplier = 140, rarity = "Legendary" },
	["Mammoth"] = { multiplier = 120, rarity = "Legendary" },
	["Elephant"] = { multiplier = 100, rarity = "Legendary" },

	["Bat"] = { multiplier = 80, rarity = "Epic" },
	["Spider"] = { multiplier = 65, rarity = "Epic" },
	["Lizard"] = { multiplier = 52, rarity = "Epic" },

	["Lion"] = { multiplier = 40, rarity = "Rare" },
	["Giraffe"] = { multiplier = 32, rarity = "Rare" },
	["Cow"] = { multiplier = 25, rarity = "Rare" },

	["Camel"] = { multiplier = 18, rarity = "Uncommon" },
	["Bear"] = { multiplier = 13, rarity = "Uncommon" },
	["Sheep"] = { multiplier = 9, rarity = "Uncommon" },

	["Pink Bunny"] = { multiplier = 6, rarity = "Common" },
	["Grey Cat"] = { multiplier = 4, rarity = "Common" },
	["Dog"] = { multiplier = 2, rarity = "Common" },
}

Config.Inventory = {
	multiplierFormat = "x%.2f",

	percentFormat = "Always %g%% better than best pet!",

	percentHeight = 0.3,
	hoverOffsetX = 0.012,
	hoverOffsetY = 0.02,
	gradientRotation = 90,
	tileLighten = 0.5,
	tileDarken = 0.5,
}

Config.Restock = {
	model = "RestockShop",
	frame = "RestockShop",

	everySeconds = 5 * 60,

	timerFormat = "New Items In %dm %ds",

	stockFormat = "%d/%d",

	shopPercentFormat = "+%g%% Speed",
	percentFormat = "+%g%%",

	restockedText = "The Restock Shop Has New Items!",
	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	boughtFormat = "Bought %s!",

	poorText = "Not Enough Wins!",

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	maxEquipped = 10,

	menu = "Inventory",
	tab = "Items",
	panel = "ItemsTab",
	list = "Items",

	equippedFormat = "Equipped (%d/%d)",
	ownedFormat = "Owned (%d)",

	Items = {
		apple = {
			rarity = "Common",
			title = "Apple",
			template = "Apple",
			percent = 3,
			price = 5_000,
			stock = 3,
			product = "RestockCommon",
		},

		carrot = {
			rarity = "Uncommon",
			title = "Carrot",
			template = "Carrot",
			percent = 5,
			price = 10_000,
			stock = 3,
			product = "RestockUncommon",
		},

		magnet = {
			rarity = "Rare",
			title = "Magnet",
			template = "Magnet",
			percent = 10,
			price = 50_000,
			stock = 2,
			product = "RestockRare",
		},

		heart = {
			rarity = "Legendary",
			title = "Heart",
			template = "Angel Heart",
			percent = 25,
			price = 100_000,
			stock = 1,
			product = "RestockLegendary",
		},
	},
}

Config.PetFollow = {
	height = 3,
	yaw = 0,

	back = 4,
	side = 2.5,
	up = 0,

	Sides = { 1, -1 },

	catchUp = 1.2,
	floor = 14,
	arrive = 0.5,
	teleport = 60,
	turn = 10,
	crawl = 1.5,

	hopSeconds = 0.42,
	rise = 0.7,
	pitch = 14,
	bob = 0.15,
	bobRate = 2.5,
}

Config.Hatch = {
	clicks = 4,

	duplicateSpeed = 100,
	duplicatePercent = 0.01,

	shade = 0.65,

	openShade = 0.45,
	shadeSeconds = 0.35,

	spread = 0.92,
	tall = 0.74,
	middle = 0.45,

	width = 0.22,
	height = 0.56,
	gap = 0.02,
	rowGap = 0.03,
	wave = 0.05,

	nameHeight = 0.16,
	rarityHeight = 0.12,
	bonusHeight = 0.18,
	labelWidth = 1.35,
	strokeShare = 0.004,

	shakeAngle = 12,
	shakeSeconds = 0.05,
	shakeSwings = 4,
	punch = 1.08,

	popSeconds = 0.3,
	revealSeconds = 0.45,
	stagger = 0.12,
	spinSeconds = 8,

	zoom = 1.05,
	eggZoom = 1.35,
	fieldOfView = 40,

	nameFormat = "%s [%g%%]",

	bonusFormat = "Already owned\n+%s Speed instead",
	clickHint = "Click the egg!",
	closeHint = "Click to continue",

	Idle = {
		bob = 0.035,
		bobSeconds = 1.7,
		sway = 3.5,
		swaySeconds = 2.6,
		phase = 0.4,

		hintPulse = 0.06,
		hintSeconds = 0.9,
	},

	Knock = {
		grow = 0.3,

		color = Color3.fromRGB(255, 245, 205),

		ringFrom = 0.04,
		ringTo = 0.18,
		ringSeconds = 0.35,
		ringThickness = 0.004,
		ringTransparency = 0.35,

		flecks = 4,

		shake = 0.005,
		shakeSeconds = 0.22,
		fade = 1.4,
	},

	Charge = {
		seconds = 0.55,
		angle = 22,
		swingSeconds = 0.05,
		scale = 1.18,
		shake = 0.009,
	},

	Burst = {
		rings = 2,
		ringGap = 0.08,
		ringFrom = 0.05,
		ringTo = 0.34,
		ringSeconds = 0.55,
		ringThickness = 0.006,
		ringTransparency = 0.15,

		flecks = 18,
		fleckSize = 0.014,
		fleckVary = 0.45,
		fleckCorner = 0.35,

		speed = 0.6,
		least = 0.35,
		spin = 320,
		gravity = 0.9,
		drag = 1.6,
		life = 0.9,
		lifeVary = 0.4,
		fade = 0.35,

		glowTexture = "rbxasset://textures/particles/sparkles_main.dds",
		glowSize = 1.35,
		glowTransparency = 0.45,
		glowSeconds = 0.5,
		glowSpin = 25,

		flashTransparency = 0.55,
		flashRiseSeconds = 0.08,
		flashSeconds = 0.7,
	},

	Pop = {
		from = 0.6,
		seconds = 0.35,
	},

	Sounds = {
		knockPath = { "UI", "Click" },
		crackPath = { "UI", "Success" },
		rarePath = { "UI", "Winner" },
		duplicatePath = { "UI", "Cash" },

		knockVolume = 1,
		knockPitch = 0.85,
		knockStep = 0.14,

		chargeVolume = 0.9,
		chargePitch = 1.45,

		crackVolume = 1,
		crackPitch = 0.95,
		crackStep = 0.05,

		rareVolume = 1.15,

		duplicateVolume = 0.9,
		duplicatePitch = 1.1,

		lifeSeconds = 5,
	},

	Fanfare = {
		Epic = true,
		Legendary = true,
		Rainbow = true,
	},
}

Config.Shop = {
	priceFormat = "\u{E002}%d",

	percentFrom = 5_000,

	Items = {
		["Starter Pack"] = {
			kind = "GamePass",
			onceField = "starterPack",
			Buttons = { Buy = "StarterPack" },
			petSlot = "Slot1",

			Grant = {
				pet = "Inferno Axolotl",
				speed = 20_000,
				boosts = { ["2xPerStep"] = 1 },
			},

			Labels = {
				{ path = { "Slot2", "Amount" }, from = "speed", format = "+%s", exact = true },
				{ path = { "Slot3", "Amount" }, from = "boost", boost = "2xPerStep", format = "x%s", exact = true },
			},
		},

		["Boost Potions Bundle"] = {
			kind = "Product",
			Buttons = { Buy = "BoostBundle" },

			Grant = {
				boosts = { ["2xPerStep"] = 1, ["2xPerWin"] = 1 },
			},
		},

		["Small Wins Pack"] = {
			kind = "Product",
			Buttons = { Buy = "WinsSmall" },
			Grant = { wins = 1_000, winsPercent = 0.1 },
			Labels = { { path = { "Amount" }, from = "wins", format = "+%s" } },
		},

		["Medium Wins Pack"] = {
			kind = "Product",
			Buttons = { Buy = "WinsMedium" },
			Grant = { wins = 5_000, winsPercent = 0.5 },
			Labels = { { path = { "Amount" }, from = "wins", format = "+%s" } },
		},

		["Big Wins Pack"] = {
			kind = "Product",
			Buttons = { Buy = "WinsBig" },
			Grant = { wins = 10_000, winsPercent = 1 },
			Labels = { { path = { "Amount" }, from = "wins", format = "+%s" } },
		},

		["Rainbow Egg"] = {
			kind = "Product",
			Buttons = { Buy1 = "RainbowEgg1", Buy3 = "RainbowEgg3", Buy8 = "RainbowEgg8" },
			Hatch = { RainbowEgg1 = 1, RainbowEgg3 = 3, RainbowEgg8 = 8 },
			percentFormat = "%g%%",

			Slots = {
				Slot1 = { pet = "Metal Dominus", percent = 50 },
				Slot2 = { pet = "Pharaoh", percent = 30 },
				Slot3 = { pet = "Crystal Unicorn", percent = 15 },
				Slot4 = { pet = "Poseidon", percent = 5 },
			},
		},
	},
}

Config.Offline = {
	maxSeconds = 60 * 60,

	normalShare = 0.1,
	premiumShare = 1,

	product = "OfflinePremium",

	frame = "OfflineEarnings",
	amountFormat = "+%s",

	priceFormat = "\u{E002}%d",
}

Config.Daily = {
	frame = "Daily",
	tile = "Daily",
	badge = "!",

	waitSeconds = 24 * 60 * 60,
	tickSeconds = 1,

	product = "DaySkip",

	dayFormat = "Day%d",
	amountFormat = "+%s",

	lockedIcon = "Lock",
	waitingIcon = "Hourglass",
	takenIcon = "Checkmark",

	readyFormat = "Day %d Is Ready To Claim!",
	tookFormat = "Day %d Claimed!",
	orderFormat = "Claim Day %d First!",
	doneFormat = "Day %d Is Already Claimed!",
	petFormat = "%s Unlocked!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	Kinds = {
		speed = { field = "speed", icon = "Shoe", wonFormat = "+%s Speed", from = Color3.fromRGB(140, 225, 255), to = Color3.fromRGB(0, 110, 255) },
		wins = { field = "wins", icon = "Trophy", wonFormat = "+%s Wins", from = Color3.fromRGB(255, 240, 130), to = Color3.fromRGB(255, 140, 0) },
	},

	Days = {
		{ kind = "speed", amount = 20_000 },
		{ kind = "pet", pet = "Ninja" },
		{ kind = "speed", amount = 1_500_000_000 },
		{ kind = "wins", amount = 600_000 },
		{ kind = "speed", amount = 5_000_000_000 },
		{ kind = "wins", amount = 1_250_000 },
		{ kind = "pet", pet = "Chimpanzini Bananini" },
	},
}

Config.Streak = {
	frame = "DailyStreak",

	step = 0.1,
	max = 2,

	amountFormat = "x%.1f Speed",

	offlineSeconds = 30,
	tickSeconds = 0.5,
}

Config.Playtime = {
	frame = "Playtime",

	tile = "Playtime",
	badge = "!",

	stepSeconds = 5 * 60,
	skipSeconds = 5 * 60,
	tickSeconds = 1,

	totalField = "playtime",
	bankSeconds = 60,

	product = "PlaytimeRush",

	amountFormat = "+%s",
	timerFormat = "%dh %dm %ds",
	readyText = "Ready!",
	claimedText = "Claimed!",

	readyFrom = Color3.fromRGB(255, 255, 0),
	readyTo = Color3.fromRGB(0, 255, 0),

	claimedFrom = Color3.fromRGB(255, 130, 130),
	claimedTo = Color3.fromRGB(190, 25, 25),

	tookFormat = "Slot %d Claimed!",
	orderFormat = "Claim Slot %d First!",
	doneFormat = "Slot %d Is Already Claimed!",
	rushedFormat = "%d Minutes Off Every Timer!",
	petFormat = "%s Unlocked!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	Kinds = {
		speed = { field = "speed", icon = "Shoe", wonFormat = "+%s Speed", from = Color3.fromRGB(140, 225, 255), to = Color3.fromRGB(0, 110, 255) },
		wins = { field = "wins", icon = "Trophy", wonFormat = "+%s Wins", from = Color3.fromRGB(255, 240, 130), to = Color3.fromRGB(255, 140, 0) },
	},

	Slots = {
		{ kind = "speed", amount = 10_000 },
		{ kind = "wins", amount = 1_000 },
		{ kind = "boost", boost = "2xPerStep", amount = 1 },
		{ kind = "boost", boost = "2xPerWin", amount = 1 },

		{ kind = "speed", amount = 25_000_000 },
		{ kind = "wins", amount = 50_000 },
		{ kind = "boost", boost = "2xPerStep", amount = 1 },
		{ kind = "boost", boost = "2xPerWin", amount = 1 },

		{ kind = "speed", amount = 100_000_000 },
		{ kind = "wins", amount = 100_000 },
		{ kind = "boost", boost = "2xPerStep", amount = 1 },

		{ kind = "pet", pet = "Shroom" },
	},
}

Config.Free = {
	frame = "Free",

	tile = "Free",
	badge = "!",

	groupId = 393283365,

	speed = 25_000,

	prizeFormat = "+%s",
	claimedText = "Claimed",

	grantedStatus = "granted",
	groupStatus = "group",
	favoriteStatus = "favorite",
	claimedStatus = "claimed",

	tookText = "Free Reward Claimed!",
	tookFormat = "+%s Speed",
	groupText = "Join The Group First!",
	favoriteText = "Favorite The Game First!",
	doneText = "You Already Claimed This!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	Claimed = {
		border = Color3.fromRGB(118, 0, 0),
		borderLine = Color3.fromRGB(64, 0, 0),

		faceFrom = Color3.fromRGB(255, 137, 137),
		faceTo = Color3.fromRGB(255, 0, 0),

		edgeFrom = Color3.fromRGB(255, 199, 199),
		edgeTo = Color3.fromRGB(255, 35, 35),
	},
}

Config.Codes = {
	frame = "Codes",

	Box = { "Main", "Code", "Textbox" },
	Claim = { "Main", "Claim", "Button" },

	placeholder = "Enter Code...",

	grantedStatus = "granted",
	unknownStatus = "unknown",
	usedStatus = "used",
	failedStatus = "failed",

	speedFormat = "You Got %s Speed (+%s%%)",
	winsFormat = "You Got %s Wins (+%s%%)",
	petFormat = "You Got The %s Pet!",
	boostFormat = "You Got x%s %s For %s!",

	remindSpeedFormat = "+%s Speed (+%s%%)",
	remindWinsFormat = "+%s Wins (+%s%%)",
	remindPetFormat = "The %s Pet",
	remindBoostFormat = "x%s %s For %s",

	remindText = "A Free Reward",

	speedWord = "Speed",
	winsWord = "Wins",

	minutesFormat = "%d %s",
	minuteWord = "Minute",
	minutesWord = "Minutes",

	emptyText = "Type A Code First!",
	unknownText = "That Code Does Not Exist!",
	usedText = "You Already Used This Code!",
	failedText = "Try That Again In A Moment!",

	from = Color3.fromRGB(140, 225, 255),
	to = Color3.fromRGB(0, 110, 255),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),
}

Config.Quests = {
	frame = "Quests",

	tile = "Quests",
	badge = "!",

	tickSeconds = 1,

	daySeconds = 12 * 60 * 60,

	bankSeconds = 5,

	studTeleport = 200,

	timerFormat = "Reset in %dh %dm %ds",

	prizeFormat = "+%s %s (%s%%)",
	amountFormat = "%s / %s",

	speedWord = "Speed",
	winsWord = "Wins",

	claimText = "Claim",
	claimedText = "Claimed",

	ClaimReady = {
		shadow = Color3.fromRGB(16, 119, 0),

		from = Color3.fromRGB(255, 255, 118),
		to = Color3.fromRGB(60, 255, 43),

		strokeFrom = Color3.fromRGB(251, 251, 205),
		strokeTo = Color3.fromRGB(127, 250, 117),
	},

	ClaimOff = {
		shadow = Color3.fromRGB(108, 0, 0),

		from = Color3.fromRGB(254, 164, 164),
		to = Color3.fromRGB(255, 27, 31),

		strokeFrom = Color3.fromRGB(255, 208, 208),
		strokeTo = Color3.fromRGB(255, 69, 72),
	},

	priceFormat = "\u{E002}%d",

	readyText = "A Quest Is Ready To Claim!",
	tookFormat = "%s Quest Claimed!",
	wonFormat = "+%s %s",
	shortText = "Finish The Quest First!",
	doneText = "Quest Already Claimed!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),

	speedFrom = Color3.fromRGB(140, 225, 255),
	speedTo = Color3.fromRGB(0, 110, 255),

	winsFrom = Color3.fromRGB(255, 240, 130),
	winsTo = Color3.fromRGB(255, 140, 0),

	order = { "easy", "medium", "hard" },

	Difficulties = {
		easy = { label = "EASY", frame = "Easy", percent = 0.10, product = "QuestSkipEasy" },
		medium = { label = "MEDIUM", frame = "Medium", percent = 0.25, product = "QuestSkipMedium" },
		hard = { label = "HARD", frame = "Hard", percent = 0.50, product = "QuestSkipHard" },
	},

	Types = {
		walls = {
			questFormat = "Break %s Walls",
			Ranges = { easy = { 10, 10 }, medium = { 100, 100 }, hard = { 1000, 1000 } },
		},

		playMinutes = {
			questFormat = "Play %s Minutes",
			Ranges = { easy = { 5, 5 }, medium = { 15, 15 }, hard = { 30, 30 } },
		},

		eggs = {
			questFormat = "Open %s Eggs",
			Ranges = { easy = { 5, 5 }, medium = { 25, 25 }, hard = { 50, 50 } },
		},

		studs = {
			questFormat = "Run %s Studs",
			Ranges = { easy = { 1000, 1000 }, medium = { 10000, 10000 }, hard = { 100000, 100000 } },
		},

		friendMinutes = {
			questFormat = "Play %s Minutes With A Friend",
			Ranges = { easy = { 5, 5 }, medium = { 15, 15 }, hard = { 30, 30 } },
		},
	},
}

Config.Slime = {
	frame = "SlimePet",

	pet = "Slime",

	field = "slimePetReward",

	waitSeconds = 15 * 60,
	tickSeconds = 1,

	timerFormat = "%dm %ds",

	tookFormat = "%s Unlocked!",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	everySeconds = 5,
	shrink = 0.85,
	grow = 1.1,
	beatSeconds = 0.15,

	spin = 180,
	spinSeconds = 6,

	tilt = 5,
	tiltSeconds = 1.2,
}

Config.AutoRun = {
	frame = "AutoRun",

	timer = "Timer",
	button = "Button",

	unlockSeconds = 10 * 60,

	field = "autoRunUnlocked",

	tickSeconds = 1,
	stepSeconds = 0.1,

	lockedFormat = "Unlocks in %d:%02d",
	onText = "ON",
	offText = "OFF",

	lockedFormatNotify = "Auto Run Unlocks In %d:%02d!",
	onNotify = "Auto Run On!",
	offNotify = "Auto Run Off!",

	On = {
		border = Color3.fromRGB(0, 104, 0),
		borderLine = Color3.fromRGB(0, 50, 0),

		faceFrom = Color3.fromRGB(255, 255, 0),
		faceTo = Color3.fromRGB(0, 255, 0),

		edgeFrom = Color3.fromRGB(255, 255, 115),
		edgeTo = Color3.fromRGB(69, 255, 69),

		timerFrom = Color3.fromRGB(255, 255, 0),
		timerTo = Color3.fromRGB(0, 255, 0),
	},

	Off = {
		border = Color3.fromRGB(104, 0, 0),
		borderLine = Color3.fromRGB(50, 0, 0),

		faceFrom = Color3.fromRGB(255, 116, 116),
		faceTo = Color3.fromRGB(255, 29, 29),

		edgeFrom = Color3.fromRGB(255, 179, 179),
		edgeTo = Color3.fromRGB(255, 90, 90),

		timerFrom = Color3.fromRGB(255, 164, 164),
		timerTo = Color3.fromRGB(255, 0, 0),
	},

	folder = "WinButtons",
	press = "Press",

	paths = "AutoRunPaths",

	turnIn = 20,

	laneTolerance = 6,

	brakeSpeed = 8,

	brakeLead = 0.2,

	brakeSeconds = 1.5,
}

Config.Tutorial = {
	keep = "Speed",
	leftFrame = "Left",

	Quiet = { "Shop", "Daily", "Playtime", "Free" },
	badge = "!",

	Folder = { "Assets", "Tutorial" },
	near = "TutorialAttachment0",
	far = "TutorialAttachment1",
	beam = "TutorialBeam",
	highlight = "TutorialHighlight",

	Torso = { "UpperTorso", "Torso", "HumanoidRootPart" },

	zIndex = 50,

	worldPadding = 0.012,

	edgeInset = 0.02,

	minSize = 0.05,

	guiGrow = 1.18,

	tileSize = 0.125,
	tileRatio = 1,

	moveSeconds = 0.12,

	tickSeconds = 0.1,

	level = 4,

	runSeconds = 3,

	doneText = "You finished tutorial!",
	soundPath = { "UI", "Winner" },

	from = Color3.fromRGB(255, 240, 170),
	to = Color3.fromRGB(255, 170, 0),

	Stages = {
		{ key = "wall", text = "Break your first wall!", World = { "Stages", "1" } },
		{ key = "wins", text = "Collect your first wins!", World = { "WinButtons", "1", "WinButton", "Press" } },
		{ key = "upgrade1", text = "Buy your first upgrade!", World = { "ShoesModels", "2" }, pad = 2, grow = 2 },
		{ key = "upgrade2", text = "Buy your second upgrade!", World = { "ShoesModels", "3" }, pad = 3, grow = 2 },
		{ key = "belt", text = "Run on the treadmill to reach level 4!", World = { "Treadmills", "Normal" } },

		{ key = "menu", text = "Open the Rebirth menu!", Gui = { "Left", "Rebirth" }, tile = true, left = true },
		{ key = "rebirth", text = "Do your first rebirth!", Gui = { "Menus", "Rebirth", "Main", "Rebirth" } },
		{ key = "exit", text = "Close the menu!", Gui = { "Menus", "Rebirth", "Exit" } },

		{ key = "iron", text = "Step onto the Iron treadmill!", World = { "Treadmills", "Iron" } },

		{ key = "run", text = "Run on the treadmill!", World = { "Treadmills", "Iron" } },

		{ key = "wall1", text = "Break through Stage 1!", World = { "Stages", "1" } },
		{ key = "wall2", text = "Break through Stage 2!", World = { "Stages", "2" } },
		{ key = "wall3", text = "Break through Stage 3!", World = { "Stages", "3" } },

		{ key = "wins3", text = "Collect the wins at Stage 3!", World = { "WinButtons", "3", "WinButton" } },

		{ key = "egg", text = "Go to the Basic Egg!", World = { "Eggs", "Basic" }, grow = 1.6 },

		{
			key = "open",
			text = "Open the egg!",
			Gui = { "Basic", "Opens", "Open1" },
			adorn = true,
			World = { "Eggs", "Basic" },
			grow = 1.6,
		},

		{ key = "inventory", text = "Open your Inventory!", Gui = { "Left", "Inventory" }, tile = true },

		{ key = "equip", text = "Equip your new pet!", Gui = { "Menus", "Inventory", "Main", "Items" }, slot = true },

		{ key = "close", text = "Close the Inventory!", Gui = { "Menus", "Inventory", "Exit" } },
	},
}

Config.Nametag = {
	maxDistance = 100,

	width = 8,
	height = 1.15,
	offset = Vector3.new(0, 2.5, 0),

	alwaysOnTop = false,

	showOwn = true,

	color = Color3.fromRGB(255, 255, 255),

	strokeColor = Color3.fromRGB(0, 0, 0),
	strokeScale = 0.05,
	strokeTransparency = 0,

	icon = "\u{E001}",
	iconColor = Color3.fromRGB(255, 190, 0),

	premiumFormat = "<font color=\"#%s\">%s</font> %s",
}

Config.Weather = {
	everySeconds = 20 * 60,
	liveSeconds = 5 * 60,

	tickSeconds = 1,

	Order = { "Devil", "Candy", "Water" },

	Board = { "EventBoard", "Board", "SurfaceGui" },
	rowFormat = "Event%d",

	nameFormat = "<font color=\"#%s\">%s Event</font>",
	waitFormat = "%s In %02d:%02d",
	activeFormat = "%s Ends In %02d:%02d",

	Lightning = { "Assets", "Lightning" },
	defaultLightning = "Default",

	flashColor = Color3.fromRGB(255, 255, 255),
	flashInSeconds = 0.35,
	flashOutSeconds = 1.1,

	flashOrder = 100,

	zoomField = 22,
	zoomSettleSeconds = 0.7,

	activeFrame = "ActiveBoost",
	Template = { "Assets", "Templates", "ActiveBoost" },
	Icons = { "Assets", "Icons" },
	timerFormat = "%d:%02d",
	cardFormat = "%s Event",

	startFormat = "%s Event Started!",
	effectFormat = "%s For %d Minutes!",

	Events = {
		Devil = {
			icon = "BloodMoon",
			hoverIcon = "Shoe",
			lightning = "Devil",

			speed = 2,
			wins = 2,
			description = "x2 Speed & x2 Wins",

			color = Color3.fromRGB(240, 111, 125),
			from = Color3.fromRGB(255, 190, 195),
			to = Color3.fromRGB(200, 25, 45),
		},

		Candy = {
			icon = "BubbleGum",
			hoverIcon = "Shoe",
			lightning = "Candy",

			speed = 2,
			wins = 1,
			description = "x2 Speed",

			color = Color3.fromRGB(245, 101, 255),
			from = Color3.fromRGB(255, 200, 255),
			to = Color3.fromRGB(200, 0, 230),
		},

		Water = {
			icon = "Water",
			hoverIcon = "Trophy",
			lightning = "Water",

			speed = 1,
			wins = 2,
			description = "x2 Wins",

			color = Color3.fromRGB(0, 234, 255),
			from = Color3.fromRGB(190, 250, 255),
			to = Color3.fromRGB(0, 150, 220),
		},
	},
}

Config.Admin = {
	command = "/resetstats",

	Allowed = {
		[8709680466] = true,
		[494291463] = true,
	},

	Fields = { "speed", "wins", "rebirth", "playtime", "robux" },

	selfText = "Stats Reset!",
	otherFormat = "%s Was Reset!",
	missingFormat = "No Player Named %s",

	from = Color3.fromRGB(190, 255, 170),
	to = Color3.fromRGB(0, 170, 60),

	denyFrom = Color3.fromRGB(255, 190, 190),
	denyTo = Color3.fromRGB(220, 0, 0),
}

return Config
