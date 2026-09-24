-- Phase 7.2.1: definitions only; merge flags are not applied yet.
local items = {}
local definitions = {
 {ItemId="NORMAL_01", Name="Normal Dumbbell 1", Grade=1, PriceWin=1, StrengthMultiplier=2},
 {ItemId="NORMAL_02", Name="Normal Dumbbell 2", Grade=2, PriceWin=3, StrengthMultiplier=5},
 {ItemId="NORMAL_03", Name="Normal Dumbbell 3", Grade=3, PriceWin=5, StrengthMultiplier=10},
 {ItemId="NORMAL_04", Name="Normal Dumbbell 4", Grade=4, PriceWin=10, StrengthMultiplier=25},
 {ItemId="NORMAL_05", Name="Normal Dumbbell 5", Grade=5, PriceWin=20, StrengthMultiplier=50},
}
for _, item in ipairs(definitions) do
 item.Category = "Dumbbell"
 item.SeriesId = "NORMAL"
 item.ElementId = "NORMAL"
 item.SourceType = "Earned"
 item.Mergeable = true
 item.ImageAssetId = 89307391617240
 item.Image = "rbxassetid://89307391617240"
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
return table.freeze(M)
