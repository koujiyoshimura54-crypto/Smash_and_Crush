-- Shared between Worlds; no World-specific Config dependencies.
local Requirements=require(script.Parent.LevelRequirements)
local Config={}
Config.World1MaxRebirth=5 -- Compatibility metadata only, not the active cap.
-- Indexed by the resulting Rebirth count; legacy entries11..30 are preserved.
Config.LegacyRebirthRequiredLevels={10,15,22,30,45,70,90,110,140,160,45,50,300,400,500,600,750,900,1000,1250,1500,2000,2500,3000,4000,5000,6000,7500,9000,10000}
Config.RebirthRequiredLevels=table.clone(Config.LegacyRebirthRequiredLevels)
Config.RebirthRequiredLevels[1]=12
Config.RebirthRequiredLevels[2]=17
Config.RebirthRequiredLevels[3]=24
-- Informational references use the SAME curve and gates as eligibility.
Config.ReferenceStrengths={}
Config.LegacyReferenceStrengths={}
for index,level in ipairs(Config.RebirthRequiredLevels) do
 Config.ReferenceStrengths[index]=Requirements.GetCumulativeStrength(level,2)
 Config.LegacyReferenceStrengths[index]=Requirements.GetCumulativeStrength(Config.LegacyRebirthRequiredLevels[index],1)
end
Config.BaseMultiplier=1
Config.MultiplierPerRebirth=0.5
-- These getters take the CURRENT count; requirement/reference describes the next.
function Config.GetRequiredLevel(rebirthCount,curveVersion)
 local curve,reason=Requirements.NormalizeCurveVersion(curveVersion);assert(curve,reason)
 local levels=curve==1 and Config.LegacyRebirthRequiredLevels or Config.RebirthRequiredLevels
 return levels[(tonumber(rebirthCount) or 0)+1]
end
function Config.GetReferenceStrength(rebirthCount,curveVersion)
 local curve,reason=Requirements.NormalizeCurveVersion(curveVersion);assert(curve,reason)
 local values=curve==1 and Config.LegacyReferenceStrengths or Config.ReferenceStrengths
 return values[(tonumber(rebirthCount) or 0)+1]
end
function Config.IsWorld1Max(rebirthCount,curveVersion)
 return Config.GetRequiredLevel(rebirthCount,curveVersion)==nil -- Legacy name; shared cap.
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
