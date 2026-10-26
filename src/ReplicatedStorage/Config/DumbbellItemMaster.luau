-- Shared purchase, ore-forging and resale definitions. Dumbbells are not merge materials.
local items = {}
local definitions = {
 {ItemId="NORMAL_01", Name="Normal Dumbbell 1", Grade=1, PriceWin=7, MergePoints=5, SellWin=3, StrengthBonus=3, ImageAssetId=131314372434925},
 {ItemId="NORMAL_02", Name="Normal Dumbbell 2", Grade=2, PriceWin=20, MergePoints=20, SellWin=10, StrengthBonus=5, ImageAssetId=126019719977317},
 {ItemId="NORMAL_03", Name="Normal Dumbbell 3", Grade=3, PriceWin=50, MergePoints=40, SellWin=25, StrengthBonus=9, ImageAssetId=96428309215438},
 {ItemId="NORMAL_04", Name="Normal Dumbbell 4", Grade=4, PriceWin=130, MergePoints=70, SellWin=65, StrengthBonus=15, ImageAssetId=77317637436768},
 {ItemId="NORMAL_05", Name="Normal Dumbbell 5", Grade=5, PriceWin=250, MergePoints=110, SellWin=125, StrengthBonus=25, ImageAssetId=134662273184560},
 {ItemId="NORMAL_06", Name="Normal Dumbbell 6", Grade=6, PriceWin=500, MergePoints=160, SellWin=250, StrengthBonus=45, ImageAssetId=92138447886967}, -- Owner's W1-5D belongs to slot 6, not slot 5.
 {ItemId="NORMAL_07", Name="Normal Dumbbell 7", Grade=7, PriceWin=1000, MergePoints=220, SellWin=500, StrengthBonus=75, ImageAssetId=79967244610623},
 {ItemId="NORMAL_08", Name="Normal Dumbbell 8", Grade=8, PriceWin=1500, MergePoints=290, SellWin=750, StrengthBonus=120, ImageAssetId=110171141876908},
 {ItemId="NORMAL_09", Name="Normal Dumbbell 9", Grade=9, PriceWin=2500, MergePoints=370, SellWin=1250, StrengthBonus=180, ImageAssetId=129522181601539},
 {ItemId="NORMAL_10", Name="Normal Dumbbell 10", Grade=10, PriceWin=4500, MergePoints=450, SellWin=2250, StrengthBonus=280, ImageAssetId=92929093922544},
 {ItemId="NORMAL_11", Name="Normal Dumbbell 11", Grade=11, PriceWin=8000, MergePoints=530, SellWin=4000, StrengthBonus=450, ImageAssetId=89748292939648},
 {ItemId="NORMAL_12", Name="Normal Dumbbell 12", Grade=12, PriceWin=13000, MergePoints=650, SellWin=6500, StrengthBonus=700, ImageAssetId=121194224737958},
}
local World2=require(script.Parent.World2GameplayConfig)
for index,row in ipairs(World2.Dumbbells) do
 table.insert(definitions,{ItemId=string.format("W2_NORMAL_%02d",index),Name="World 2 Dumbbell "..index,
  WorldId=2,Grade=index,PriceWin=row.PriceWin,StrengthBonus=row.StrengthBonus,ImageAssetId=World2.DumbbellImages[index]})
end
for _, item in ipairs(definitions) do
 item.Category = "Dumbbell"
 item.SeriesId = item.WorldId==2 and "WORLD2" or "NORMAL"
 item.ElementId = "NORMAL"
 item.SourceType = "Earned"
 item.Mergeable = true
 item.Image = "rbxassetid://" .. tostring(item.ImageAssetId)
 -- ModelId intentionally absent until a 3D asset is selected.
 items[item.ItemId] = table.freeze(item)
end
table.freeze(items)
local M = {}
function M.Get(itemId)
 if typeof(itemId) ~= "string" then return nil end
 return items[itemId]
end
-- Read-only dictionary keyed by ItemId, including read-only definitions.
function M.GetAll()
 return items
end
-- Ordered definitions are shared by inventory, shop and notifications.
local sorted={}
for _,item in pairs(items) do table.insert(sorted,item) end
table.sort(sorted,function(a,b)
 if (a.WorldId or 1)~=(b.WorldId or 1) then return (a.WorldId or 1)<(b.WorldId or 1) end
 if a.Grade~=b.Grade then return a.Grade<b.Grade end
 return a.ItemId<b.ItemId
end)
table.freeze(sorted)
function M.GetSorted(worldId)
 if worldId==nil then return sorted end
 local result={}
 for _,item in ipairs(sorted) do if (item.WorldId or 1)==worldId then table.insert(result,item) end end
 return result
end
return table.freeze(M)
