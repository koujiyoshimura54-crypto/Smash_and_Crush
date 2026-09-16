-- Single source for treadmill tiers, access requirements and model assignments.
local Config = {}
Config.PremiumTreadmillPassId = 0 -- Set the dedicated Game Pass ID; 0 disables Premium.
Config.Types = {
 Normal = {Multiplier=1, RequiredRebirth=0},
 Rebirth3 = {Multiplier=3, RequiredRebirth=3},
 Rebirth7 = {Multiplier=5, RequiredRebirth=5},
 Premium = {Multiplier=20, RequiresPremium=true},
}
-- Viewed from the Spawn side toward -X: back row left-to-right is 05,04,03,02,01.
Config.Assignments = {
 Tredmill01="Premium", Tredmill02="Rebirth7", Tredmill03="Rebirth7",
 Tredmill04="Rebirth3", Tredmill05="Rebirth3",
 Tredmill06="Normal", Tredmill07="Normal", Tredmill08="Normal",
 Tredmill09="Normal", Tredmill10="Normal",
}
function Config.Get(modelName)
 local kind=Config.Assignments[modelName]
 return kind and Config.Types[kind],kind
end
function Config.GetDisplayText(modelName)
 local entry,kind=Config.Get(modelName)
 if not entry then return "Unavailable" end
 local title=kind=="Premium" and "PREMIUM" or (kind=="Normal" and "NORMAL" or "TRAINING")
 local requirement=entry.RequiredRebirth and entry.RequiredRebirth>0
  and ("\nRebirth "..entry.RequiredRebirth.." Required") or ""
 return title.."\n×"..tostring(entry.Multiplier)..requirement
end
return Config

