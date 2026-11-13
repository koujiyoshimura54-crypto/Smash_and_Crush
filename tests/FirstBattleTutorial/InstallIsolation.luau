assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
assert(not game.ServerStorage:FindFirstChild("__FirstBattleBackup"))
local backup=Instance.new("Folder");backup.Name="__FirstBattleBackup";backup.Parent=game.ServerStorage
local mem=Instance.new("ModuleScript");mem.Name="__FirstBattleMemory";mem.Source="local M={Stores={},Writes=0,FailBefore=0,FailAfter=0,HoldWrites=false,BlockedWrites=0,Delay=0}\nlocal function copy(x) if type(x)~=\"table\" then return x end local y={} for k,v in x do y[k]=copy(v) end return y end\nlocal function store(name)\n if M.Stores[name] then return M.Stores[name] end\n local values,metadata,users,versions={},{},{},{}\n local function info(k)\n  local m,u,v=copy(metadata[k] or {}),copy(users[k] or {}),versions[k] or 0\n  return {Version=tostring(v),GetMetadata=function()return copy(m)end,GetUserIds=function()return copy(u)end}\n end\n local s={}\n function s:GetAsync(k) if M.FailRead and M.FailRead>0 then M.FailRead-=1;error(\"isolated read failure\") end return copy(values[k]),info(k) end\n function s:UpdateAsync(k,fn)\n  if M.HoldWrites and (not M.TargetKey or M.TargetKey==k) then M.BlockedWrites+=1;repeat task.wait(.05) until not M.HoldWrites end\n  if M.Delay>0 and (not M.TargetKey or M.TargetKey==k) then task.wait(M.Delay) end\n  if M.FailBefore>0 and (not M.TargetKey or M.TargetKey==k) then M.FailBefore-=1;error(\"isolated precommit failure\") end\n  local v,u,m=fn(copy(values[k]),info(k))\n  if v~=nil then values[k]=copy(v);metadata[k]=copy(m or metadata[k] or {});users[k]=copy(u or users[k] or {});versions[k]=(versions[k] or 0)+1;M.Writes+=1 end\n  if M.FailAfter>0 and (not M.TargetKey or M.TargetKey==k) then M.FailAfter-=1;error(\"isolated acknowledgement loss\") end\n  return copy(values[k]),info(k)\n end\n function s:SetAsync(k,v) values[k]=copy(v);M.Writes+=1 end\n function s:RemoveAsync(k) values[k]=nil;M.Writes+=1 end\n function s:GetSortedAsync() return {GetCurrentPage=function()return {} end,IsFinished=true} end\n M.Stores[name]=s;return s\nend\nM.DataStoreService={GetDataStore=function(_,name)return store(name)end,GetOrderedDataStore=function(_,name)return store(name)end,GetRequestBudgetForRequestType=function()return 1000 end}\nlocal function signal()return Instance.new(\"BindableEvent\").Event end\nM.MarketplaceService=setmetatable({PromptProductPurchaseFinished=signal(),PromptGamePassPurchaseFinished=signal(),\n UserOwnsGamePassAsync=function()return false end,GetProductInfo=function()return {PriceInRobux=99,IsForSale=true}end,\n PromptProductPurchase=function()error(\"Real payments blocked\")end,PromptGamePassPurchase=function()error(\"Real payments blocked\")end,\n},{__index=function(_,k) if k:find(\"Finished\") then return signal() end end})\nM.MarketplaceService.GetProductInfoAsync=M.MarketplaceService.GetProductInfo\nM.BadgeService={UserHasBadgeAsync=function()return false end,AwardBadge=function()return false end}\nM.MessagingService={PublishAsync=function()end,SubscribeAsync=function()return {Disconnect=function()end}end}\nM.PolicyService={GetPolicyInfoForPlayerAsync=function()return {ArePaidRandomItemsRestricted=false,IsPaidItemTradingAllowed=true}end}\nreturn M";mem.Parent=game.ReplicatedStorage
local count=0
for _,v in game:GetDescendants() do
 if v:IsA("LuaSourceContainer") and v~=mem then
  local before=v.Source;local after=before
  for _,name in {"DataStoreService","MarketplaceService","BadgeService","MessagingService","PolicyService"} do
   after=after:gsub("game:GetService%(%\""..name.."%\"%)","require(game.ReplicatedStorage.__FirstBattleMemory)."..name)
   after=after:gsub("game:GetService%('%s*"..name.."%s*'%)","require(game.ReplicatedStorage.__FirstBattleMemory)."..name)
  end
  if after~=before then
   local b=Instance.new("Folder");b.Name=tostring(count+1)
   local ref=Instance.new("ObjectValue");ref.Name="Target";ref.Value=v;ref.Parent=b
   local old=Instance.new("StringValue");old.Name="Before";old.Value=before;old.Parent=b
   local new=Instance.new("StringValue");new.Name="After";new.Value=after;new.Parent=b
   b.Parent=backup;v.Source=after;count+=1
  end
 end
end
return {Redirected=count,PlaceId=game.PlaceId}
