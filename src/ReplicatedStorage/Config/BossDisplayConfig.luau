-- World1 presentation only. These values never feed Combat or Balance.
local Config = {
 Transparency = 0.5,
 SurfaceOffset = 0.5, -- Gap from the wall's player-side face to the surface rear, studs.
 Thickness = 0.05,
 Color = Color3.fromRGB(210, 220, 235),
 VerticalOffset = 2, -- HP bar center above the rendered Boss visual top, studs.
 StageOverrides = {},
}

function Config.Get(stage)
 local settings = {}
 for key, value in pairs(Config) do
  if key ~= "StageOverrides" and key ~= "Get" then settings[key] = value end
 end
 for key, value in pairs(Config.StageOverrides[stage] or {}) do settings[key] = value end
 return settings
end

return Config
