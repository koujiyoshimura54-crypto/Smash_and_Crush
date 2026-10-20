-- Shared between Worlds; no World-specific Config dependencies.
local Config={}
Config.World1MaxRebirth=5 -- Compatibility metadata only, not the active cap.
-- Indexed by the resulting Rebirth count; legacy entries11..30 are preserved.
Config.RebirthRequiredLevels={10,15,22,30,45,70,90,110,140,160,45,50,300,400,500,600,750,900,1000,1250,1500,2000,2500,3000,4000,5000,6000,7500,9000,10000}
-- Informational cumulative Strength references, never eligibility conditions.
Config.ReferenceStrengths={955,2840,10485,37315,462965,61420025,314953025,1073937025,4677580025,12226986025}
Config.BaseMultiplier=1
Config.MultiplierPerRebirth=0.5
-- These getters take the CURRENT count; requirement/reference describes the next.
function Config.GetRequiredLevel(rebirthCount)
 return Config.RebirthRequiredLevels[(tonumber(rebirthCount) or 0)+1]
end
function Config.GetReferenceStrength(rebirthCount)
 return Config.ReferenceStrengths[(tonumber(rebirthCount) or 0)+1]
end
function Config.IsWorld1Max(rebirthCount)
 return Config.GetRequiredLevel(rebirthCount)==nil -- Legacy name; shared cap.
end
function Config.GetMultiplier(rebirthCount)
 local count=tonumber(rebirthCount)
 if not count or count~=count or count==math.huge or count==-math.huge then return 1 end
 return Config.BaseMultiplier+math.max(0,math.floor(count))*Config.MultiplierPerRebirth
end
-- Preserve the old multiplier Config's public0..30 lookup, including count0.
Config.Multipliers={}
for count=0,#Config.RebirthRequiredLevels do Config.Multipliers[count]=Config.GetMultiplier(count) end
return Config
