local LevelRequirements = {}

-- Each value is now the gain required to advance FROM that level.
-- Lv1-50 progression requirements are the current approved cumulative-Strength curve.
local FIXED_STRENGTH = table.freeze({
	[1] = 10,
	[2] = 30,
	[3] = 50,
	[4] = 70,
	[5] = 90,
	[6] = 125,
	[7] = 155,
	[8] = 190,
	[9] = 235,
	[10] = 290,

	[11] = 330,
	[12] = 375,
	[13] = 420,
	[14] = 470,
	[15] = 535,
	[16] = 610,
	[17] = 760,
	[18] = 1110,
	[19] = 1360,
	[20] = 1510,
	[21] = 1760,
	[22] = 2010,
	[23] = 2260,
	[24] = 2510,
	[25] = 3010,
	[26] = 3510,
	[27] = 4010,
	[28] = 4510,
	[29] = 5010,
	[30] = 6010,
	[31] = 7510,
	[32] = 9010,
	[33] = 10010,
	[34] = 12010,
	[35] = 15010,
	[36] = 18010,
	[37] = 22010,
	[38] = 27010,
	[39] = 33010,
	[40] = 40010,
	[41] = 45010,
	[42] = 52010,
	[43] = 60010,
	[44] = 69010,
	[45] = 80010,
	[46] = 95010,
	[47] = 105010,
	[48] = 125010,
	[49] = 150010,
	[50] = 200010,

	-- Lv51-200: explicit provisional thresholds, approved anchors 2026-09-15.
	-- Monotone cubic interpolation was done offline; these literals are authoritative.
})
-- Q(L) is the cost FROM L, never the player's accumulated Strength.
local approved=table.clone(FIXED_STRENGTH)
for level=51,200 do
 local rate=0.20+(level-51)*0.0007
 approved[level]=math.ceil(approved[level-1]*(1+rate)/10)*10
end
FIXED_STRENGTH=table.freeze(approved)

LevelRequirements.FixedStrength = FIXED_STRENGTH
LevelRequirements.LevelStrengthRequirements = FIXED_STRENGTH
LevelRequirements.MaxFixedLevel = 200
LevelRequirements.MaxLevel = 10000
-- Preserve the existing linear extension from the newly approved Q(200).
LevelRequirements.Post200StrengthPerLevel = 250000000

function LevelRequirements.GetRequiredStrength(level)
 local value = tonumber(level) or 1
 if value ~= value then value = 1 end
 value = math.clamp(math.floor(value), 1, LevelRequirements.MaxLevel)
 local fixed = FIXED_STRENGTH[value]
 if fixed ~= nil then return fixed end
 return FIXED_STRENGTH[200] + (value - 200) * LevelRequirements.Post200StrengthPerLevel
end

-- Legacy migration lookup ONLY (and archived tests). Never use for live Level.
-- New progression consumes each current-level requirement in LevelProgression.
function LevelRequirements.CalculateLevel(strength)
 local value = tonumber(strength) or 0
 if value ~= value or value <= 0 then return 1 end
 local low, high = 1, LevelRequirements.MaxLevel
 while low < high do
  local middle = math.floor((low + high + 1) / 2)
  if value >= LevelRequirements.GetRequiredStrength(middle) then
   low = middle
  else
   high = middle - 1
  end
 end
 return low
end

return table.freeze(LevelRequirements)
