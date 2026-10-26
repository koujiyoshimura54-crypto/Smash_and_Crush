-- Idempotent compatibility for legacy boolean ownership and quantity inventories.
local M={Max=9007199254740991}
function M.Count(value)
 if value==nil or value==false then return 0 end
 if value==true then return 1 end
 if typeof(value)=="number" and value==value and value>=0 and value<=M.Max and value%1==0 then return value end
 return nil
end
function M.Normalize(raw)
 if raw~=nil and typeof(raw)~="table" then return nil,"InvalidInventory" end
 local result={}
 for id,value in pairs(raw or {}) do
  local count=M.Count(value)
  if typeof(id)~="string" or id=="" or #id>128 or not count then return nil,"InvalidInventoryEntry" end
  if count>0 then result[id]=count end
 end
 return result
end
function M.Owned(raw)
 local result={}
 for id,count in pairs(raw) do if (M.Count(count) or 0)>0 then result[id]=true end end
 return result
end
return table.freeze(M)
