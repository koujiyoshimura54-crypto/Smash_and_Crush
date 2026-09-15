local Config={}
Config.WorldPasses={
 World1={DoubleWinPassId=1970515086,Multiplier=2},
 World2={DoubleWinPassId=nil},
}
Config.PlaceWorldMap={
 [101572058398926]="World1",
}
function Config.GetWorld(placeId)
 return Config.PlaceWorldMap[placeId]
end
function Config.GetDoubleWinPassId(world)
 local entry=Config.WorldPasses[world]
 return entry and entry.DoubleWinPassId
end
function Config.GetWinMultiplier(world)
 local entry=Config.WorldPasses[world]
 return entry and entry.Multiplier or 1
end
return Config

