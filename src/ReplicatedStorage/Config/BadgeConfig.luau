local Config = {}

Config.Badges = table.freeze({
 FirstSmash = 133584961163786,
 FirstRebirth = 550217286582115,
 FirstLegendary = 4387545691338666,
 World1Complete = 2118618041135837,
 IntoWorld2 = 3295862437341420,
})

function Config.GetBadgeId(key)
 return typeof(key)=="string" and Config.Badges[key] or nil
end

return table.freeze(Config)
