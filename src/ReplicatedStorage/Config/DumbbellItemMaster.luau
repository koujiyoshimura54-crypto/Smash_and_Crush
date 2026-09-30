-- Phase 7.2.1: definitions only; merge flags are not applied yet.
local items = {}
local definitions = {
 {ItemId="NORMAL_01", Name="Normal Dumbbell 1", Grade=1, PriceWin=5, StrengthBonus=2, ImageAssetId=131314372434925},
 {ItemId="NORMAL_02", Name="Normal Dumbbell 2", Grade=2, PriceWin=15, StrengthBonus=5, ImageAssetId=126019719977317},
 {ItemId="NORMAL_03", Name="Normal Dumbbell 3", Grade=3, PriceWin=30, StrengthBonus=10, ImageAssetId=96428309215438},
 {ItemId="NORMAL_04", Name="Normal Dumbbell 4", Grade=4, PriceWin=75, StrengthBonus=30, ImageAssetId=77317637436768},
 {ItemId="NORMAL_05", Name="Normal Dumbbell 5", Grade=5, PriceWin=150, StrengthBonus=50, ImageAssetId=134662273184560},
	{ItemId="NORMAL_06", Name="Normal Dumbbell 6", Grade=6, PriceWin=1000, StrengthBonus=125, ImageAssetId=74657955424795},
	{ItemId="NORMAL_07", Name="Normal Dumbbell 7", Grade=7, PriceWin=4500, StrengthBonus=300, ImageAssetId=79967244610623},
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
