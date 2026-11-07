-- Existing PlayerData SetWin normalization, shared with quoted unit amounts.
local M={}
function M.Normalize(value)
 return math.max(0,math.floor(value))
end
return table.freeze(M)
