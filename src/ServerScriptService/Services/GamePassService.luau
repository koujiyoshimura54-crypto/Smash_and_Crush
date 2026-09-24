local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local StudioDebugConfig=require(game.ServerScriptService.Config:WaitForChild("StudioDebugConfig"))
local Config=require(game.ReplicatedStorage.Config:WaitForChild("WorldPassConfig"))

local M={}
-- Ownership remains verified; only benefit application is gated in Studio.
function M.AreEffectsEnabled(player)
 if RunService:IsStudio() then
  return StudioDebugConfig.GamePassEffectsEnabled~=false
 end
 local creatorIds=StudioDebugConfig.ProductionCreatorUserIds
 local isCreator=typeof(player)=="Instance" and player:IsA("Player")
  and typeof(creatorIds)=="table" and creatorIds[player.UserId]==true
 if isCreator then
  return StudioDebugConfig.ProductionCreatorGamePassEffectsEnabled~=false
 end
 return true
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
	return M.AreEffectsEnabled(player) and M.HasWorld1DoubleWin(player) and Config.GetWinMultiplier(currentWorld()) or 1
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
local premiumBusy=setmetatable({}, {__mode="k"})
function M.HasPremiumTreadmill(player)
 local entry=premiumCache[player]
 return entry~=nil and entry.PassId==TreadmillConfig.PremiumTreadmillPassId and entry.Owned==true
end
function M.RefreshPremiumTreadmill(player)
 local passId=TreadmillConfig.PremiumTreadmillPassId
 if typeof(passId)~="number" or passId<=0 or passId%1~=0 or passId==math.huge then
  player:SetAttribute("HasPremiumTreadmill",false)
  return false,"Unavailable"
 end
 if premiumBusy[player] then return M.HasPremiumTreadmill(player),"Pending" end
 premiumBusy[player]=true
 local ok,owned=pcall(function()
  return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId)
 end)
 premiumBusy[player]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 if not ok then return M.HasPremiumTreadmill(player),"OwnershipUnavailable" end
 premiumCache[player]={PassId=passId,Owned=owned==true}
 player:SetAttribute("HasPremiumTreadmill",owned==true)
 return owned==true,"Verified"
end
function M.PromptPremiumTreadmill(player)
 local owned,status=M.RefreshPremiumTreadmill(player)
 if owned then return false,"AlreadyOwned" end
 if status~="Verified" then return false,status end
 local ok=pcall(function()
  MarketplaceService:PromptGamePassPurchase(player,TreadmillConfig.PremiumTreadmillPassId)
 end)
 return ok,ok and "Prompted" or "PromptUnavailable"
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
 if passId~=TreadmillConfig.PremiumTreadmillPassId or not purchased then return end
 premiumCache[player]=nil
 task.spawn(function()
  for attempt=1,5 do
   if player.Parent~=Players then return end
   local owned=M.RefreshPremiumTreadmill(player)
   if owned then return end
   task.wait(attempt)
  end
 end)
end)
Players.PlayerRemoving:Connect(function(player)
 premiumCache[player]=nil
 premiumBusy[player]=nil
end)

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

-- Slap entitlement is verified independently. The mirrored Attribute drives presentation only.
local SlapConfig=require(game.ReplicatedStorage.Config:WaitForChild("SlapPassConfig"))
local slapCache=setmetatable({}, {__mode="k"})
local slapBusy=setmetatable({}, {__mode="k"})
function M.HasSlapPass(player)
 return slapCache[player]==true
end
function M.CanUseSlapPass(player)
 return M.AreEffectsEnabled(player) and M.HasSlapPass(player)
end
function M.RefreshSlapPass(player)
 if slapBusy[player] then return M.HasSlapPass(player),"Pending" end
 slapBusy[player]=true
 local ok,owned=pcall(function()
  return MarketplaceService:UserOwnsGamePassAsync(player.UserId,SlapConfig.GamePassId)
 end)
 slapBusy[player]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 if not ok then return M.HasSlapPass(player),"OwnershipUnavailable" end
 slapCache[player]=owned==true
 player:SetAttribute("HasSlapPass",owned==true)
 return owned==true,"Verified"
end
function M.PromptSlapPass(player)
 if M.HasSlapPass(player) then return false,"AlreadyOwned" end
 local ok=pcall(function()
  MarketplaceService:PromptGamePassPurchase(player,SlapConfig.GamePassId)
 end)
 return ok,ok and "Prompted" or "PromptUnavailable"
end
Players.PlayerRemoving:Connect(function(player) slapCache[player]=nil;slapBusy[player]=nil end)

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
 return M.AreEffectsEnabled(player) and M.HasShopPass(player,"VIP") and ShopConfig.Get("VIP").StrengthMultiplier or 1
end
Players.PlayerRemoving:Connect(function(player) shopCache[player]=nil;shopBusy[player]=nil end)

return M

