local Config={}
-- Current game is World1. Future worlds can supply their own server-authoritative cap.
Config.World1MaxRebirth=5
function Config.IsWorld1Max(rebirthCount)
 return Config.GetRequiredLevel(rebirthCount)==nil -- Rebirth is shared; retain legacy R11+ definitions.
end
-- V5: World1 R1–R5; R6+ definitions remain available for future worlds.
Config.RebirthRequiredLevels={10,15,22,30,45,40,50,36,38,40,45,50,300,400,500,600,750,900,1000,1250,1500,2000,2500,3000,4000,5000,6000,7500,9000,10000}
local World2=require(script.Parent.World2GameplayConfig)
for count,row in pairs(World2.Rebirth) do Config.RebirthRequiredLevels[count]=row.Level end
function Config.GetRequiredLevel(rebirthCount)
 return Config.RebirthRequiredLevels[(tonumber(rebirthCount) or 0)+1]
end
return Config
