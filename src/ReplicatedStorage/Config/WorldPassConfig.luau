local Config={}
-- Existing Creator Hub pass. Adds to the training source multiplier, not the final gain.
-- Edit in Studio, then restart Play (ModuleScripts are cached per session).
Config.StrengthPass={GamePassId=2089895831,AdditiveMultiplier=1}
Config.WorldPasses={
 World1={DoubleWinPassId=1970515086,TripleWinPassId=2005353724,Multiplier=2},
 World2={DoubleWinPassId=nil},
}
Config.PlaceWorldMap={
 [101572058398926]="World1",
 [126576845524886]="World1",
}
function Config.GetWorld(placeId)
 return Config.PlaceWorldMap[placeId]
end
function Config.GetDoubleWinPassId(world)
 local entry=Config.WorldPasses[world]
 return entry and entry.DoubleWinPassId
end
function Config.GetTripleWinPassId(world)
 local entry=Config.WorldPasses[world]
 return entry and entry.TripleWinPassId
end
function Config.GetWinMultiplier(world)
 local entry=Config.WorldPasses[world]
 return entry and entry.Multiplier or 1
end
function Config.GetNextWinPassId(world,doubleOwned,tripleOwned)
 if world~="World1" or tripleOwned then return nil end
 return doubleOwned and Config.GetTripleWinPassId(world) or Config.GetDoubleWinPassId(world)
end
function Config.GetOwnedWinMultiplier(world,doubleOwned,tripleOwned)
 if world~="World1" then return 1 end
 return tripleOwned and 3 or doubleOwned and 2 or 1
end
return Config
