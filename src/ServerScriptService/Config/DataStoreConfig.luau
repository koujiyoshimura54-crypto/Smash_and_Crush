-- Names only; production schema and keys are unchanged.
local Studio=game:GetService("RunService"):IsStudio()
local M={}
-- Developer preview: every Studio Play starts with World2 purchases locked.
-- Only the session's effective arrival changes; saved arrival/ownership is retained.
M.ResetWorld2ArrivalOnStudioPlay=true
function M.GetName(productionName)
 return productionName..(Studio and "_Studio" or "")
end
return table.freeze(M)
