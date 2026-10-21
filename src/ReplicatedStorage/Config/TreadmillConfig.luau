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

-- Only the seven existing, exact World2 roots authorize World2 training.
local World2=require(script.Parent.World2GameplayConfig)
local stationTypes={1,1,2,2,3,3,4}
function Config.GetPremiumTreadmillPassId(world)
 return world==2 and World2.Treadmills[4].GamePassId or Config.PremiumTreadmillPassId
end
function Config.WorldForModel(model)
 if not model then return nil end
 if model.Parent==workspace:FindFirstChild("Treadmills") and Config.Get(model.Name) then return 1 end
 local map=workspace:FindFirstChild("World2Map")
 local area=map and map:FindFirstChild("TrainingArea")
 local folder=area and area:FindFirstChild("TreadmillDisplays")
 local index=tonumber(model.Name)
 if folder and model.Parent==folder and index and model.Name==string.format("%02d",index) and stationTypes[index] then return 2 end
end
function Config.GetForModel(model)
 local world=Config.WorldForModel(model)
 if world==1 then return Config.Get(model.Name) end
 if world==2 then
  local index=stationTypes[tonumber(model.Name)]
  return World2.Treadmills[index],"World2_"..index
 end
end
return Config
