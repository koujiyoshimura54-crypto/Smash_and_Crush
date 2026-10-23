local M={}
local stores={}
local function copy(x) if type(x)~="table" then return x end local y={} for k,v in x do y[k]=copy(v) end return y end
local function store(name)
 if stores[name] then return stores[name] end
 local data={}
 local info={Version="isolated",GetMetadata=function()return {} end,GetUserIds=function()return {} end}
 local s={}
 function s:GetAsync(k) return copy(data[k]),info end
 function s:UpdateAsync(k,fn) local v=fn(copy(data[k]),info);if v~=nil then data[k]=copy(v) end;return copy(data[k]),info end
 function s:SetAsync(k,v) data[k]=copy(v) end
 function s:RemoveAsync(k) data[k]=nil end
 function s:GetSortedAsync() return {GetCurrentPage=function()return {} end,IsFinished=true} end
 stores[name]=s;return s
end
M.DataStoreService={GetDataStore=function(_,name)return store(name)end,GetOrderedDataStore=function(_,name)return store(name)end}
local function signal()return Instance.new("BindableEvent").Event end
M.MarketplaceService=setmetatable({
 PromptProductPurchaseFinished=signal(),PromptGamePassPurchaseFinished=signal(),
 UserOwnsGamePassAsync=function()return false end,GetProductInfo=function()return {PriceInRobux=99,IsForSale=true}end,
 PromptProductPurchase=function()error("Real payments blocked")end,PromptGamePassPurchase=function()error("Real payments blocked")end,
},{__index=function(_,k) if k:find("Finished") then return signal() end end})
M.BadgeService={UserHasBadgeAsync=function()return true end,AwardBadge=function()return false end}
return M
