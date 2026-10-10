-- Immutable paid pool; retain old versions when introducing a future pool.
local entries = {
 {Name="Pet_042", Percent=25, Yaw=0},
 {Name="Pet_064", Percent=25, Yaw=0},
 {Name="Pet_081", Percent=25, Yaw=0},
 {Name="Pet_086", Percent=15, Yaw=0},
 {Name="Pet_094", Percent=6.5, Yaw=0},
 {Name="Pet_135", Percent=0.5, Yaw=0},
 {Name="Pet_024", Percent=3, Yaw=0},
}
local byName = {}
for _, entry in entries do table.freeze(entry); byName[entry.Name]=entry end
local function validResult(result,version)
 if version~=1 or type(result)~="table" or type(result.id)~="string"
  or not result.id:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then return false end
 local entry=byName[result.pet]
 return entry~=nil and result.percent==entry.Percent
end
return table.freeze({
 Name="Limited Egg 01", Entrance="Chill Octopus", ProductId=3717610547,
 BasePrice=149, Count=1, PurchaseEnabled=true, UniverseId=10765181857,
 RollVersion=1, ValidateResult=validResult,
 ModelsFolder="LimitedEgg01Pets", FutureHatchTemplate="RGBEgg",
 Entries=table.freeze(entries), ByName=table.freeze(byName),
})
