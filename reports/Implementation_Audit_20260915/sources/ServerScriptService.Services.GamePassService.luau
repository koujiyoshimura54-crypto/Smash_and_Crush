local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local StudioDebugConfig=RunService:IsStudio() and require(game.ServerScriptService.Config:WaitForChild("StudioDebugConfig")) or nil
local Config=require(game.ReplicatedStorage.Config:WaitForChild("WorldPassConfig"))

local M={}
-- Ownership remains verified; only benefit application is gated in Studio.
function M.AreEffectsEnabled()
 return not RunService:IsStudio() or StudioDebugConfig.GamePassEffectsEnabled~=false
end
local cache=setmetatable({}, {__mode="k"})

local function currentWorld()
	return Config.GetWorld(game.PlaceId)
end

function M.GetWorld()
	return currentWorld()
end

function M.IsWorld1()
	return currentWorld()=="World1"
end

function M.Refresh(player)
	local passId=Config.GetDoubleWinPassId(currentWorld())
	local owned=false

	if passId then
		local ok,result=pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
		end)

		if ok then
			owned=(result==true)
		else
			warn("Game Pass ownership check failed for "..player.Name)
		end
	end

	cache[player]=owned
	player:SetAttribute("HasWorld1DoubleWin",owned)

	return owned
end

function M.HasWorld1DoubleWin(player)
	if currentWorld()~="World1" then
		return false
	end

	if cache[player]==nil then
		M.Refresh(player)
	end

	return cache[player]==true
end

function M.GetWinMultiplier(player)
	return M.AreEffectsEnabled() and M.HasWorld1DoubleWin(player) and Config.GetWinMultiplier(currentWorld()) or 1
end

function M.GetWinReward(player,baseReward)
	return math.floor((tonumber(baseReward) or 0)*M.GetWinMultiplier(player))
end

function M.Prompt(player)
	if not M.IsWorld1() then
		return false,"Unavailable in this World"
	end

	if M.HasWorld1DoubleWin(player) then
		return false,"Already owned"
	end

	local passId=Config.GetDoubleWinPassId("World1")

	if not passId then
		return false,"Unavailable"
	end

	local ok=pcall(function()
		MarketplaceService:PromptGamePassPurchase(player,passId)
	end)

	return ok,ok and "Prompted" or "Purchase prompt unavailable"
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
	local world=currentWorld()

	if world=="World1"
		and passId==Config.GetDoubleWinPassId("World1")
		and purchased then

		local ok,owned=pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
		end)

		if ok and owned then
			cache[player]=true
			player:SetAttribute("HasWorld1DoubleWin",true)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cache[player]=nil
end)

-- Dedicated treadmill entitlement; independent of the existing Double Win cache.
local TreadmillConfig=require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
local premiumCache=setmetatable({}, {__mode="k"})
function M.HasPremiumTreadmill(player)
 local passId=TreadmillConfig.PremiumTreadmillPassId
 if typeof(passId)~="number" or passId<=0 or passId%1~=0 or passId==math.huge then return false end
 local entry=premiumCache[player]
 if not entry or entry.PassId~=passId or (not entry.Owned and not entry.Pending and os.clock()>=entry.RetryAt) then
  entry={PassId=passId,Owned=false,Pending=true,RetryAt=0}
  premiumCache[player]=entry
  task.spawn(function()
   local ok,owned=pcall(function()
    return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
   end)
   if premiumCache[player]~=entry then return end
   entry.Owned=ok and owned==true
   entry.Pending=false
   entry.RetryAt=os.clock()+(ok and 30 or 5)
  end)
 end
 return entry.Owned==true
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
 if purchased and passId==TreadmillConfig.PremiumTreadmillPassId then
  premiumCache[player]=nil
  M.HasPremiumTreadmill(player) -- Verify ownership; do not trust purchase prompt completion alone.
 end
end)
Players.PlayerRemoving:Connect(function(player) premiumCache[player]=nil end)

-- Speed entitlement is verified independently of other Game Passes.
local SpeedConfig=require(game.ReplicatedStorage.Config:WaitForChild("SpeedConfig"))
local function forceSpeedPremiumUnowned()
 return RunService:IsStudio() and StudioDebugConfig~=nil and StudioDebugConfig.ForceSpeedPremiumUnowned==true
end
local speedCache=setmetatable({}, {__mode="k"})
local speedBusy=setmetatable({}, {__mode="k"})
function M.HasPremiumSpeed(player)
 if forceSpeedPremiumUnowned() then return false end
 return speedCache[player]==true
end
function M.RefreshPremiumSpeed(player)
 if forceSpeedPremiumUnowned() then
  player:SetAttribute("HasPremiumSpeed",false)
  return false,"Verified"
 end
 if speedBusy[player] then return M.HasPremiumSpeed(player),"Pending" end
 speedBusy[player]=true
 local ok,owned=pcall(function()
  return MarketplaceService:UserOwnsGamePassAsync(player.UserId,SpeedConfig.Premium.GamePassId)
 end)
 speedBusy[player]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 if not ok then return M.HasPremiumSpeed(player),"OwnershipUnavailable" end
 speedCache[player]=owned==true
 local effectiveOwned=M.HasPremiumSpeed(player)
 player:SetAttribute("HasPremiumSpeed",effectiveOwned)
 return effectiveOwned,"Verified"
end
function M.PromptPremiumSpeed(player)
 local owned,status=M.RefreshPremiumSpeed(player)
 if owned then return false,"AlreadyOwned" end
 if status~="Verified" then return false,status end
 local ok=pcall(function()
  MarketplaceService:PromptGamePassPurchase(player,SpeedConfig.Premium.GamePassId)
 end)
 return ok,ok and "Prompted" or "PromptUnavailable"
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
 if id~=SpeedConfig.Premium.GamePassId or not purchased then return end
 task.spawn(function()
  for attempt=1,5 do
   if player.Parent~=Players then return end
   local owned=M.RefreshPremiumSpeed(player)
   if owned then return end
   task.wait(attempt)
  end
 end)
end)
Players.PlayerRemoving:Connect(function(player) speedCache[player]=nil;speedBusy[player]=nil end)

-- Verified Shop entitlements. Attribute mirrors never authorize a benefit.
local ShopConfig=require(game.ReplicatedStorage.Config.ShopProductConfig)
local shopCache=setmetatable({}, {__mode="k"})
local shopBusy=setmetatable({}, {__mode="k"})
function M.HasShopPass(player,key)
 local entries=shopCache[player]
 return entries~=nil and entries[key]==true
end
function M.RefreshShopPass(player,key)
 local product=ShopConfig.Get(key)
 if not product or product.Kind~="GamePass" then return false,"InvalidProduct" end
 local locks=shopBusy[player] or {};shopBusy[player]=locks
 if locks[key] then return M.HasShopPass(player,key),"Pending" end
 locks[key]=true
 local ok,owned=pcall(function()return MarketplaceService:UserOwnsGamePassAsync(player.UserId,product.PassId)end)
 locks[key]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 if not ok then return M.HasShopPass(player,key),"OwnershipUnavailable" end
 local entries=shopCache[player] or {};shopCache[player]=entries;entries[key]=owned==true
 player:SetAttribute("HasShop"..key,owned==true)
 return owned==true,"Verified"
end
function M.GetVIPStrengthMultiplier(player)
 return M.AreEffectsEnabled() and M.HasShopPass(player,"VIP") and ShopConfig.Get("VIP").StrengthMultiplier or 1
end
Players.PlayerRemoving:Connect(function(player) shopCache[player]=nil;shopBusy[player]=nil end)

return M
