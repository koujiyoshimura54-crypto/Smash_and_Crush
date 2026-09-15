-- Display-only cache. Purchases and entitlements remain server-authoritative.
local Marketplace=game:GetService("MarketplaceService")
local cache={}
local M={}
function M.Format(price,suffix)
 return price~=nil and tostring(price)..(suffix or "") or "..."
end
function M.Apply(label,price,source,suffix)
 label.Text=M.Format(price,suffix)
 label:SetAttribute("PriceSource",source)
end
function M.Get(id,infoType,fallback)
 if typeof(id)~="number" or id<=0 then return fallback,"ConfigFallback" end
 local key=tostring(infoType)..":"..tostring(id)
 local saved=cache[key]
 if saved and os.clock()-saved.Time<60 then return saved.Price,"Marketplace" end
 local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(id,infoType) end)
 if ok and typeof(info)=="table" and typeof(info.PriceInRobux)=="number" then
  cache[key]={Time=os.clock(),Price=info.PriceInRobux}
  return info.PriceInRobux,"Marketplace"
 end
 return fallback,"ConfigFallback"
end
return M

