-- World1 normal Wall .1-.4 presentation only. These values never feed Combat or Balance.
local Config = {
 WallUI = {
  Scale = 0.8,
  StageGap = 0.4, -- Visual gap from the StageNumber lower edge to the HP gauge upper edge, studs.
 },
}

function Config.Get()
 local settings = Config.WallUI
 assert(typeof(settings.Scale) == "number" and settings.Scale > 0, "WallDisplayConfig.WallUI.Scale must be positive")
 assert(typeof(settings.StageGap) == "number" and settings.StageGap >= 0, "WallDisplayConfig.WallUI.StageGap must be non-negative")
 return settings
end

return Config
