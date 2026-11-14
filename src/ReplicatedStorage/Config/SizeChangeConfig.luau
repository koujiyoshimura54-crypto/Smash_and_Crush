local M={}
M.RequiredRebirth=5
M.PaymentMode="WIN"
M.WinPrice=500
M.DeveloperProductId=0
M.MinTier=0
M.MaxTier=10
-- Legacy persisted ordinals are different from newly accepted requests.
function M.NormalizeSavedTier(value)
 if value==nil then return 0 end
 if typeof(value)~="number" or value~=value or value%1~=0 or value<0 or value>13 then
  return nil,"Invalid SelectedSizeTier"
 end
 return math.min(value,M.MaxTier)
end
return M
