-- Immutable paid pool; retain old versions when introducing a future pool.
local entries = {
 {Name="Pet_042", Percent=25, StrengthPercent=90, Yaw=0},
 {Name="Pet_064", Percent=25, StrengthPercent=90, Yaw=0},
 {Name="Pet_081", Percent=25, StrengthPercent=90, Yaw=0},
 {Name="Pet_086", Percent=15, StrengthPercent=110, Yaw=0},
 {Name="Pet_094", Percent=6.5, StrengthPercent=130, Yaw=0},
 {Name="Pet_135", Percent=0.5, StrengthPercent=200, Yaw=0},
 {Name="Pet_024", Percent=3, StrengthPercent=160, Yaw=0},
}
local byName = {}
for _, entry in entries do table.freeze(entry); byName[entry.Name]=entry end
local function validResult(result,version)
 if version~=1 or type(result)~="table" or type(result.id)~="string"
  or not result.id:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then return false end
 local entry=byName[result.pet]
 return entry~=nil and result.percent==entry.Percent
end
local World1=table.freeze({
 Name="Limited Egg 01", WorldId=1, Entrance="Chill Octopus", ProductId=3717610547,
 BasePrice=149, Count=1, PurchaseEnabled=true, UniverseId=10765181857,
 RollVersion=1, ValidateResult=validResult,
 ModelsFolder="LimitedEgg01Pets", FutureHatchTemplate="RGBEgg",
 Entries=table.freeze(entries), ByName=table.freeze(byName),
})

-- World2 keeps its existing candidate order, odds, effects and visual templates.
local World2=require(script.Parent.World2GameplayConfig)
local offer=World2.PaidOffers.LimitedEgg
local secondEntries,secondByName={},{}
for _,source in ipairs(World2.PetSources[5]) do
 local name="W2 "..source
 local pet=World2.Pets[name]
 local entry=table.freeze({Name=name,Percent=pet.Percent,StrengthPercent=(pet.Multiplier-1)*100,Yaw=0})
 table.insert(secondEntries,entry);secondByName[name]=entry
end
local function validSecond(result,version)
 if version~=1 or type(result)~="table" or type(result.id)~="string"
  or not result.id:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") then return false end
 local entry=secondByName[result.pet]
 return entry~=nil and result.percent==entry.Percent
end
local second=table.freeze({Name="Limited Egg 02",WorldId=2,EggId=offer.EggId,
 ProductId=offer.ProductId,BasePrice=offer.BasePrice,Count=offer.Count,Button=offer.Button,
 PurchaseEnabled=offer.PurchaseEnabled,UniverseId=World1.UniverseId,RollVersion=1,
 ValidateResult=validSecond,Entries=table.freeze(secondEntries),ByName=table.freeze(secondByName)})
local catalog=table.clone(World1)
catalog.World2=second
function catalog.ForProduct(id)
 if id==World1.ProductId then return World1 end
 if id==second.ProductId then return second end
end
function catalog.ValidateResult(result,version,productId)
 local product=catalog.ForProduct(productId or World1.ProductId)
 return product~=nil and product.ValidateResult(result,version)
end
return table.freeze(catalog)
