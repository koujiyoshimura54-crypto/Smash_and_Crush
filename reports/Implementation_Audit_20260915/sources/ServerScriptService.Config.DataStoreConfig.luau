-- Names only; production schema and keys are unchanged.
local Studio=game:GetService("RunService"):IsStudio()
local M={}
function M.GetName(productionName)
 return productionName..(Studio and "_Studio" or "")
end
return table.freeze(M)

