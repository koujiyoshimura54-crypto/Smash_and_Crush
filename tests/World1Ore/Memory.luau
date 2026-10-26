-- Temporary Studio QA dependency only; never installed in the shipped DataModel.
local M={Stores={},Writes=0,FailBefore=0,FailAfter=0}
local function copy(x) if type(x)~="table" then return x end local y={} for k,v in x do y[k]=copy(v) end return y end
local function store(name)
 if M.Stores[name] then return M.Stores[name] end
 local values,metadata,users,versions={},{},{},{}
 local function info(k)
  local m,u,v=copy(metadata[k] or {}),copy(users[k] or {}),versions[k] or 0
  return {Version=tostring(v),GetMetadata=function()return copy(m)end,GetUserIds=function()return copy(u)end}
 end
 local s={}
 function s:GetAsync(k) return copy(values[k]),info(k) end
 function s:UpdateAsync(k,fn)
  if M.FailBefore>0 then M.FailBefore-=1;error("isolated precommit failure") end
  local v,u,m=fn(copy(values[k]),info(k))
  if v~=nil then values[k]=copy(v);metadata[k]=copy(m or metadata[k] or {});users[k]=copy(u or users[k] or {});versions[k]=(versions[k] or 0)+1;M.Writes+=1 end
  if M.FailAfter>0 then M.FailAfter-=1;error("isolated acknowledgement loss") end
  return copy(values[k]),info(k)
 end
 function s:SetAsync(k,v) values[k]=copy(v);M.Writes+=1 end
 function s:RemoveAsync(k) values[k]=nil;M.Writes+=1 end
 function s:GetSortedAsync() return {GetCurrentPage=function()return {} end,IsFinished=true} end
 M.Stores[name]=s;return s
end
M.DataStoreService={GetDataStore=function(_,name)return store(name)end,GetOrderedDataStore=function(_,name)return store(name)end}
local function signal()return Instance.new("BindableEvent").Event end
M.MarketplaceService=setmetatable({PromptProductPurchaseFinished=signal(),PromptGamePassPurchaseFinished=signal(),
 UserOwnsGamePassAsync=function()return false end,GetProductInfo=function()return {PriceInRobux=99,IsForSale=true}end,
 PromptProductPurchase=function()error("Real payments blocked")end,PromptGamePassPurchase=function()error("Real payments blocked")end,
},{__index=function(_,k) if k:find("Finished") then return signal() end end})
M.BadgeService={UserHasBadgeAsync=function()return true end,AwardBadge=function()return false end}
return M
