local LevelRequirements = {}

-- Q(L) is the gain FROM L to L+1. Version1 retains the current pre-change cycle.
-- The historical threshold migration is independent of both progression curves.
local LEGACY_EARLY_REQUIREMENTS = table.freeze({10,30,50,70,90,125,155})
local FIXED_STRENGTH = table.freeze({
	[1] = 7,
	[2] = 20,
	[3] = 33,
	[4] = 60,
	[5] = 95,
	[6] = 145,
	[7] = 170,
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

})
-- Q(L) is the cost FROM L, never the player's accumulated Strength.
local approved=table.clone(FIXED_STRENGTH)
for level=51,200 do
 local rate=0.20+(level-51)*0.0007
 approved[level]=math.ceil(approved[level-1]*(1+rate)/10)*10
end
FIXED_STRENGTH=table.freeze(approved)

local LEGACY_STRENGTH=FIXED_STRENGTH
local current=table.clone(LEGACY_STRENGTH)
local early={5,12,23,45,60,90,125,145,170,195,225,260,300,345,400,480,580,700,840,1100,1400,1800,2200,2500,3200,4000,4750,5400,5965}
for level,cost in ipairs(early) do current[level]=cost end
FIXED_STRENGTH=table.freeze(current)
LevelRequirements.LegacyCurveVersion=1
LevelRequirements.CurrentCurveVersion=2
LevelRequirements.LegacyStrength=LEGACY_STRENGTH
-- Missing saved markers always mean an existing legacy cycle, never a new profile.
function LevelRequirements.NormalizeCurveVersion(version)
 if version==nil then return LevelRequirements.LegacyCurveVersion end
 if version==1 or version==2 then return version end
 return nil,"Unsupported LevelCurveVersion"
end
LevelRequirements.FixedStrength = FIXED_STRENGTH
LevelRequirements.LevelStrengthRequirements = FIXED_STRENGTH
LevelRequirements.MaxFixedLevel = 200
LevelRequirements.MaxLevel = 10000
-- Preserve the existing linear extension from the newly approved Q(200).
LevelRequirements.Post200StrengthPerLevel = 250000000

function LevelRequirements.GetRequiredStrength(level,curveVersion)
 local curve,reason=LevelRequirements.NormalizeCurveVersion(curveVersion)
 assert(curve,reason)
 local costs=curve==1 and LEGACY_STRENGTH or FIXED_STRENGTH
 local value = tonumber(level) or 1
 if value ~= value then value = 1 end
 value = math.clamp(math.floor(value), 1, LevelRequirements.MaxLevel)
 local fixed = costs[value]
 if fixed ~= nil then return fixed end
 return FIXED_STRENGTH[200] + (value - 200) * LevelRequirements.Post200StrengthPerLevel
end

function LevelRequirements.GetCumulativeStrength(level,curveVersion)
 local total=0
 for currentLevel=1,math.clamp(math.floor(level),1,LevelRequirements.MaxLevel)-1 do
  total+=LevelRequirements.GetRequiredStrength(currentLevel,curveVersion)
 end
 return total
end

-- Keep the historical threshold lookup stable for unversioned saved profiles.
-- These are costs from a level, not cumulative thresholds for live progression.
local function getLegacyRequiredStrength(level)
 return LEGACY_EARLY_REQUIREMENTS[level] or LevelRequirements.GetRequiredStrength(level,1)
end

-- Legacy migration lookup ONLY (and archived tests). Never use for live Level.
-- New progression consumes each current-level requirement in LevelProgression.
function LevelRequirements.CalculateLevel(strength)
 local value = tonumber(strength) or 0
 if value ~= value or value <= 0 then return 1 end
 local low, high = 1, LevelRequirements.MaxLevel
 while low < high do
  local middle = math.floor((low + high + 1) / 2)
  if value >= getLegacyRequiredStrength(middle) then
   low = middle
  else
   high = middle - 1
  end
 end
 return low
end

return table.freeze(LevelRequirements)
