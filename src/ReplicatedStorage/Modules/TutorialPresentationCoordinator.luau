-- Client-local presentation ownership. Never grants rewards or changes tutorial progress.
local owner
local M={}
function M.Acquire(key)
 if owner and owner~=key then return false end
 owner=key;return true
end
function M.Release(key) if owner==key then owner=nil end end
function M.Owner() return owner end
return M
