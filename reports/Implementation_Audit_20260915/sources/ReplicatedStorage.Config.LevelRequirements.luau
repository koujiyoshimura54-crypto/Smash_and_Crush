local LevelRequirements = {}

local FIXED_STRENGTH = table.freeze({
	[1] = 0,
	[2] = 20,
	[3] = 40,
	[4] = 60,
	[5] = 80,
	[6] = 115,
	[7] = 145,
	[8] = 180,
	[9] = 225,
	[10] = 280,

	[11] = 320,
	[12] = 365,
	[13] = 410,
	[14] = 460,
	[15] = 525,
	[16] = 600,
	[17] = 750,
	[18] = 1100,
	[19] = 1350,
	[20] = 1500,
	[21] = 1750,
	[22] = 2000,
	[23] = 2500,
	[24] = 3000,
	[25] = 3500,
	[26] = 4000,
	[27] = 5000,
	[28] = 6000,
	[29] = 7500,
	[30] = 9000,
	[31] = 11000,
	[32] = 14000,
	[33] = 17000,
	[34] = 21000,
	[35] = 25000,
	[36] = 30000,
	[37] = 36000,
	[38] = 43000,
	[39] = 51000,
	[40] = 60000,
	[41] = 72000,
	[42] = 85000,
	[43] = 98000,
	[44] = 114000,
	[45] = 130000,
	[46] = 150000,
	[47] = 172000,
	[48] = 196000,
	[49] = 222000,
	[50] = 250000,
})

LevelRequirements.FixedStrength = FIXED_STRENGTH
LevelRequirements.MaxFixedLevel = 50

function LevelRequirements.GetRequiredStrength(level)
	level = math.max(1, math.floor(tonumber(level) or 1))

	local fixed = FIXED_STRENGTH[level]

	if fixed ~= nil then
		return fixed
	end

	-- Continue the existing quadratic curve, anchored at the Lv50 threshold.
	local lastLevel = LevelRequirements.MaxFixedLevel
	return FIXED_STRENGTH[lastLevel] + 10 * ((level - 1)^2 - (lastLevel - 1)^2)
end

function LevelRequirements.CalculateLevel(strength)
	local value = math.max(0, tonumber(strength) or 0)
	local level = 1

	for candidate = 2, LevelRequirements.MaxFixedLevel do
		if value < FIXED_STRENGTH[candidate] then
			return level
		end

		level = candidate
	end

	while value >= LevelRequirements.GetRequiredStrength(level + 1) do
		level += 1
	end

	return level
end

return table.freeze(LevelRequirements)
