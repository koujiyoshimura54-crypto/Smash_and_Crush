-- Single source for treadmill tiers, access requirements and model assignments.
local Config = {}
Config.PremiumTreadmillPassId = 1982996954 -- Administrator Treadmill
Config.Types = {
 Normal = {Multiplier=1, RequiredRebirth=0, VisualTemplate=""},
	Rebirth3 = {Multiplier=2, RequiredRebirth=3, VisualTemplate="Blue_Aura4"},
	Rebirth7 = {Multiplier=3, RequiredRebirth=5, VisualTemplate="Green_Aura2"},
 Premium = {Multiplier=20, RequiresPremium=true, VisualTemplate="Premium_Fire", VisualInstanceName="PremiumAura"},
}
-- Purchased visual names map to the existing authoritative strength tiers.
Config.Assignments = {
 Normal01="Normal", Normal02="Normal",
 Iron01="Rebirth3", Iron02="Rebirth3",
 Gold01="Rebirth7", Gold02="Rebirth7",
 Diamond01="Premium",
}
-- Presentation uses the same authoritative Multiplier that TrainingManager awards.
Config.StrengthColors = {
 [2] = {
  BeltColor = Color3.fromRGB(55, 145, 255),
  FrameColor = Color3.fromRGB(20, 65, 150),
  MatColor = Color3.fromRGB(8, 25, 65),
 },
 [3] = {
  BeltColor = Color3.fromRGB(70, 200, 110),
  FrameColor = Color3.fromRGB(20, 100, 55),
  MatColor = Color3.fromRGB(8, 40, 22),
 },
}
-- Additional group guidance; existing per-machine signs are independent.
Config.MultiplierBillboard = {
 MaxDistance = 80,
 StudsOffset = Vector3.new(0, 12, 0), -- World-space offset above existing signs.
 Size = Vector2.new(16, 10), -- World-space studs at TextScale=1.
 TextScale = 1.5,
}
-- Stud units; edit in Studio and restart Play to tune the moving chevrons.
Config.Guide = {
 Enabled = true,
 Speed = 4,
 Transparency = 0.15,
 Size = Vector2.new(4, 1.6),
 Spacing = 4,
 Thickness = 0.25,
 NormalColor = Color3.fromRGB(235, 245, 255),
 BlueColor = Color3.fromRGB(205, 240, 255),
 GreenColor = Color3.fromRGB(215, 255, 225),
 PremiumColor = Color3.fromRGB(255, 220, 185),
}
function Config.Get(modelName)
 local kind=Config.Assignments[modelName]
 return kind and Config.Types[kind],kind
end
function Config.GetStrengthColors(modelName)
 local entry=Config.Get(modelName)
 return entry and Config.StrengthColors[entry.Multiplier]
end
function Config.GetStrengthColor(modelName)
 local colors=Config.GetStrengthColors(modelName)
 return colors and colors.BeltColor
end
function Config.GetDisplayText(modelName)
 local entry,kind=Config.Get(modelName)
 if not entry then return "Unavailable" end
 local title=kind=="Premium" and "PREMIUM" or (kind=="Normal" and "NORMAL" or "TRAINING")
 local requirement=entry.RequiredRebirth and entry.RequiredRebirth>0
  and ("\nRebirth "..entry.RequiredRebirth.." Required") or ""
 return title.."\n×"..tostring(entry.Multiplier)..requirement
end

-- Display-only base gain; the award/access configuration above is unchanged.
function Config.GetGainDisplayText(modelName,localeId)
 local entry=Config.Get(modelName)
 if not entry then return nil end
 local training=require(script.Parent:WaitForChild("TrainingConfig"))
 local amount=training.BaseGain*entry.Multiplier
 local japanese=string.sub(string.lower(localeId or ""),1,2)=="ja"
 return string.format(japanese and "+%g \u{7B4B}\u{529B}" or "+%g Strength",amount)
end

return Config
