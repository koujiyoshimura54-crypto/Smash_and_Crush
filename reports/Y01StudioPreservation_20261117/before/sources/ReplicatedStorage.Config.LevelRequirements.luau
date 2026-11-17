local LevelRequirements = {}

-- Q(L) is the gain FROM L to L+1. Versions retain their distinct early curves.
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
-- Freeze the original thresholds for profiles that never saved Level.
-- Normal progression must not change that historical reconstruction.
local HISTORICAL_STRENGTH=table.freeze(approved)
-- Approved 2026-11-17 CSV is authoritative for every Q(51..200).
-- Reference old CSV blob: 4b8b68ddf17cf22da30f6fc3d1ca4a0ebb969ecf.
-- Keep these exact multiples of 10; do not regenerate with floating powers.
local APPROVED_HIGH_REQUIREMENTS=table.freeze({
 [51]=319880,
 [52]=468010,
 [53]=687220,
 [54]=971840,
 [55]=1317250,
 [56]=1719370,
 [57]=2175290,
 [58]=2678400,
 [59]=3226880,
 [60]=3811730,
 [61]=4457370,
 [62]=5201900,
 [63]=6058080,
 [64]=7037110,
 [65]=8157730,
 [66]=9434110,
 [67]=10886900,
 [68]=12537000,
 [69]=14404970,
 [70]=16514810,
 [71]=18892130,
 [72]=21563930,
 [73]=24558440,
 [74]=27901760,
 [75]=31622780,
 [76]=35723030,
 [77]=40217200,
 [78]=45138790,
 [79]=50542830,
 [80]=56477070,
 [81]=62991800,
 [82]=70149490,
 [83]=78005720,
 [84]=86622200,
 [85]=96054930,
 [86]=106370010,
 [87]=117624700,
 [88]=129855800,
 [89]=143110570,
 [90]=157409160,
 [91]=173262790,
 [92]=191113300,
 [93]=210860030,
 [94]=232316630,
 [95]=255223130,
 [96]=279264270,
 [97]=304034400,
 [98]=329060960,
 [99]=353834050,
 [100]=377780000,
 [101]=404842890,
 [102]=440049590,
 [103]=484672860,
 [104]=540395720,
 [105]=609407100,
 [106]=695378820,
 [107]=803145280,
 [108]=937910040,
 [109]=1106282540,
 [110]=1316638110,
 [111]=1579569890,
 [112]=1908399740,
 [113]=2319807880,
 [114]=2834500650,
 [115]=3478172630,
 [116]=4282412760,
 [117]=5285675060,
 [118]=6534495750,
 [119]=8084194040,
 [120]=10000000000,
 [121]=12347949510,
 [122]=15200745170,
 [123]=18648246440,
 [124]=22789122140,
 [125]=27727429120,
 [126]=33570395820,
 [127]=40421257660,
 [128]=48373525920,
 [129]=57500061930,
 [130]=67842854710,
 [131]=79398615430,
 [132]=92104693460,
 [133]=105824087530,
 [134]=120334796730,
 [135]=135318411990,
 [136]=150359438580,
 [137]=164952329340,
 [138]=178511343360,
 [139]=190407409080,
 [140]=200000000000,
 [141]=209441000000,
 [142]=221171000000,
 [143]=235012000000,
 [144]=250782000000,
 [145]=268301000000,
 [146]=287388000000,
 [147]=307864000000,
 [148]=329548000000,
 [149]=352259000000,
 [150]=375817000000,
 [151]=400042000000,
 [152]=424753000000,
 [153]=449770000000,
 [154]=474912000000,
 [155]=500000000000,
 [156]=525383000000,
 [157]=551580000000,
 [158]=578667000000,
 [159]=606716000000,
 [160]=635802000000,
 [161]=666000000000,
 [162]=697383000000,
 [163]=730025000000,
 [164]=764000000000,
 [165]=799383000000,
 [166]=836247000000,
 [167]=874667000000,
 [168]=914716000000,
 [169]=956469000000,
 [170]=1000000000000,
 [171]=1045235000000,
 [172]=1092247000000,
 [173]=1141333000000,
 [174]=1192790000000,
 [175]=1246914000000,
 [176]=1304000000000,
 [177]=1364346000000,
 [178]=1428247000000,
 [179]=1496000000000,
 [180]=1567901000000,
 [181]=1644247000000,
 [182]=1725333000000,
 [183]=1811457000000,
 [184]=1902914000000,
 [185]=2000000000000,
 [186]=2109778000000,
 [187]=2238222000000,
 [188]=2384000000000,
 [189]=2545778000000,
 [190]=2722222000000,
 [191]=2912000000000,
 [192]=3113778000000,
 [193]=3326222000000,
 [194]=3548000000000,
 [195]=3777778000000,
 [196]=4014222000000,
 [197]=4256000000000,
 [198]=4501778000000,
 [199]=4750222000000,
 [200]=5000000000000,
})
local progression=table.clone(HISTORICAL_STRENGTH)
for level,cost in pairs(APPROVED_HIGH_REQUIREMENTS) do
 progression[level]=cost
end
local LEGACY_STRENGTH=table.freeze(progression)
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
-- Historical reconstruction only; live progression continues +5% after LV200.
LevelRequirements.Post200StrengthPerLevel = 250000000
local post200={}
local previous=FIXED_STRENGTH[200]
for level=201,LevelRequirements.MaxLevel do
 previous=math.ceil(previous*1.05/10)*10
 post200[level]=previous
end
table.freeze(post200)

function LevelRequirements.GetRequiredStrength(level,curveVersion)
 local curve,reason=LevelRequirements.NormalizeCurveVersion(curveVersion)
 assert(curve,reason)
 local costs=curve==1 and LEGACY_STRENGTH or FIXED_STRENGTH
 local value = tonumber(level) or 1
 if value ~= value then value = 1 end
 value = math.clamp(math.floor(value), 1, LevelRequirements.MaxLevel)
 local fixed = costs[value]
 if fixed ~= nil then return fixed end
 return post200[value]
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
 return LEGACY_EARLY_REQUIREMENTS[level] or HISTORICAL_STRENGTH[level]
  or HISTORICAL_STRENGTH[200] + (level-200)*LevelRequirements.Post200StrengthPerLevel
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
