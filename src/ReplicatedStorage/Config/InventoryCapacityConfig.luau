-- Authoritative upgrade catalogue. Add another entry keyed by current capacity
-- to expose the next tier without changing purchase or UI code.
local M = {
	DefaultCapacity = 5,
	Upgrades = {
		[5] = {NextCapacity = 6, PriceWin = 5},
		[6] = {NextCapacity = 7, PriceWin = 15},
		[7] = {NextCapacity = 8, PriceWin = 30},
		[8] = {NextCapacity = 9, PriceWin = 75},
		[9] = {NextCapacity = 10, PriceWin = 150},
		[10] = {NextCapacity = 11, PriceWin = 1000},
		[11] = {NextCapacity = 12, PriceWin = 4500},
	},
}
function M.Normalize(value)
	if value == nil then return M.DefaultCapacity end
	if typeof(value) ~= "number" or value ~= value or value % 1 ~= 0
		or value < M.DefaultCapacity or value > 9007199254740991 then
		return nil, "Invalid InventoryCapacity"
	end
	return value
end
return M
