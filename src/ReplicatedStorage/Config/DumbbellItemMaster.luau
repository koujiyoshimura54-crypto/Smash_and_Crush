-- Phase 7.2.1: definitions only; merge flags are not applied yet.
local items = {}
local definitions = {
 {ItemId="NORMAL_01", Name="Normal Dumbbell 1", Grade=1, PriceWin=5, StrengthBonus=3, ImageAssetId=131314372434925},
 {ItemId="NORMAL_02", Name="Normal Dumbbell 2", Grade=2, PriceWin=15, StrengthBonus=5, ImageAssetId=126019719977317},
 {ItemId="NORMAL_03", Name="Normal Dumbbell 3", Grade=3, PriceWin=40, StrengthBonus=9, ImageAssetId=96428309215438},
 {ItemId="NORMAL_04", Name="Normal Dumbbell 4", Grade=4, PriceWin=100, StrengthBonus=15, ImageAssetId=77317637436768},
 {ItemId="NORMAL_05", Name="Normal Dumbbell 5", Grade=5, PriceWin=200, StrengthBonus=25, ImageAssetId=134662273184560},
 {ItemId="NORMAL_06", Name="Normal Dumbbell 6", Grade=6, PriceWin=400, StrengthBonus=45, ImageAssetId=92138447886967}, -- Owner's W1-5D belongs to slot 6, not slot 5.
 {ItemId="NORMAL_07", Name="Normal Dumbbell 7", Grade=7, PriceWin=750, StrengthBonus=75, ImageAssetId=79967244610623},
	{ItemId="NORMAL_08", Name="Normal Dumbbell 8", Grade=8, PriceWin=1250, StrengthBonus=120, ImageAssetId=110171141876908},
 {ItemId="NORMAL_09", Name="Normal Dumbbell 9", Grade=9, PriceWin=2000, StrengthBonus=180, ImageAssetId=129522181601539},
 {ItemId="NORMAL_10", Name="Normal Dumbbell 10", Grade=10, PriceWin=3500, StrengthBonus=280, ImageAssetId=92929093922544},
 {ItemId="NORMAL_11", Name="Normal Dumbbell 11", Grade=11, PriceWin=6000, StrengthBonus=450, ImageAssetId=89748292939648},
 {ItemId="NORMAL_12", Name="Normal Dumbbell 12", Grade=12, PriceWin=10000, StrengthBonus=700, ImageAssetId=121194224737958},
}
for _, item in ipairs(definitions) do
 item.Category = "Dumbbell"
 item.SeriesId = "NORMAL"
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
 if a.Grade~=b.Grade then return a.Grade<b.Grade end
 return a.ItemId<b.ItemId
end)
table.freeze(sorted)
function M.GetSorted() return sorted end
return table.freeze(M)
