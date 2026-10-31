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
local winRefreshBusy=setmetatable({}, {__mode="k"})
local winPromptLocks=setmetatable({}, {__mode="k"})
local winLastRequest=setmetatable({}, {__mode="k"})
local winRecovery=setmetatable({}, {__mode="k"})
local trophyPurchases=setmetatable({}, {__mode="k"})
local function currentWorld()
 return Config.GetWorld(game.PlaceId)
end
function M.GetWorld() return currentWorld() end
function M.IsWorld1() return currentWorld()=="World1" end
local function mirrorWinPasses(player,entry)
 player:SetAttribute("HasWorld1DoubleWin",entry.Double or entry.Triple)
 player:SetAttribute("HasWorld1TripleWin",entry.Triple)
 player:SetAttribute("World1WinMultiplier",Config.GetOwnedWinMultiplier(currentWorld(),entry.Double,entry.Triple))
 player:SetAttribute("WinPassOwnershipVerified",entry.Verified)
end
function M.Refresh(player)
 local previous=cache[player] or {Double=false,Triple=false,Verified=false}
 if winRefreshBusy[player] then return previous.Double or previous.Triple,"Pending" end
 if not M.IsWorld1() then
  cache[player]={Double=false,Triple=false,Verified=false}
  mirrorWinPasses(player,cache[player])
  return false,"UnavailableWorld"
 end
 winRefreshBusy[player]=true
 local entry={Double=previous.Double,Triple=previous.Triple,Verified=true}
 for _,tier in ipairs({{Key="Double",Id=Config.GetDoubleWinPassId("World1")},{Key="Triple",Id=Config.GetTripleWinPassId("World1")}}) do
  local ok,owned=pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId,tier.Id) end)
  if ok then entry[tier.Key]=owned==true else entry.Verified=false end
  -- Deliver this receipt immediately after Double ownership is confirmed; do not
  -- wait for the unrelated Triple ownership request or a persistence operation.
  local purchase=trophyPurchases[player]
  if tier.Key=="Double" and entry.Double and purchase and player.Parent==Players then
   cache[player]=entry
   trophyPurchases[player]=nil
   task.spawn(purchase.OnOwned)
  end
 end
 winRefreshBusy[player]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 cache[player]=entry
 mirrorWinPasses(player,entry)
 return entry.Double or entry.Triple,entry.Verified and "Verified" or "OwnershipUnavailable"
end
local function scheduleWinOwnershipRefresh(player,expectedPassId)
 local existing=winRecovery[player]
 if existing then
  if expectedPassId then existing.PassId=expectedPassId end
  return
 end
 local retry={PassId=expectedPassId}
 winRecovery[player]=retry
 task.spawn(function()
  while player.Parent==Players do
   task.wait(15)
   local _,status=M.Refresh(player)
   local entry=cache[player]
   local owned=entry and (retry.PassId==Config.GetTripleWinPassId("World1") and entry.Triple or retry.PassId==Config.GetDoubleWinPassId("World1") and entry.Double)
   if status=="UnavailableWorld" or (status=="Verified" and (not retry.PassId or owned)) then break end
  end
  if winRecovery[player]==retry then winRecovery[player]=nil end
 end)
end
function M.HasWorld1DoubleWin(player)
 if not M.IsWorld1() then return false end
 if not cache[player] then M.Refresh(player) end
 local entry=cache[player]
 return entry~=nil and (entry.Double or entry.Triple)==true
end
function M.GetNextWinPassId(player)
 if not M.IsWorld1() then return nil end
 if not cache[player] then M.Refresh(player) end
 local entry=cache[player]
 if not entry or not entry.Verified then return nil end
 return Config.GetNextWinPassId(currentWorld(),entry.Double,entry.Triple)
end
function M.GetWinMultiplier(player)
 if not M.IsWorld1() or not M.AreEffectsEnabled(player) then return 1 end
 if not cache[player] then M.Refresh(player) end
 local entry=cache[player]
 return entry and Config.GetOwnedWinMultiplier(currentWorld(),entry.Double,entry.Triple) or 1
end
function M.GetWinReward(player,baseReward,worldId)
 if worldId==2 then return math.floor(tonumber(baseReward) or 0) end -- No configured World2 Win pass; never borrow World1 IDs.
 return math.floor((tonumber(baseReward) or 0)*M.GetWinMultiplier(player))
end
-- Trophy choices suppress only Double Win; the separate Triple tier is retained.
function M.GetTrophyWinReward(player,baseReward,worldId,double)
 local entry=cache[player]
 local other=worldId==1 and M.AreEffectsEnabled(player) and entry and entry.Triple and 3 or 1
 return math.floor((tonumber(baseReward) or 0)*other*(double and 2 or 1))
end
function M.GetTrophyDoubleOwnership(player)
 if not cache[player] then M.Refresh(player) end
 local entry=cache[player]
 return entry~=nil and entry.Double==true,entry and entry.Verified and "Verified" or "OwnershipUnavailable"
end
local function releaseWinPrompt(player,lock)
 if winPromptLocks[player]~=lock then return end
 winPromptLocks[player]=nil
 if player.Parent==Players then player:SetAttribute("WinPassPromptBusy",false) end
end
function M.Prompt(player,trophy)
 if not M.IsWorld1() then return false,"UnavailableWorld" end
 if winPromptLocks[player] then return false,"Pending" end
 local now=os.clock()
 if winLastRequest[player] and now-winLastRequest[player]<1 then return false,"Cooldown" end
 winLastRequest[player]=now
 local lock={}
 winPromptLocks[player]=lock
 player:SetAttribute("WinPassPromptBusy",true)
 local _,status=M.Refresh(player)
 if status~="Verified" then
  releaseWinPrompt(player,lock)
  if status=="OwnershipUnavailable" then
   scheduleWinOwnershipRefresh(player)
  end
  return false,status
 end
 if trophy and not trophy.IsCurrent() then releaseWinPrompt(player,lock);return false,"Expired" end
 local doubleOwned=M.GetTrophyDoubleOwnership(player)
 if trophy and doubleOwned then releaseWinPrompt(player,lock);return false,"AlreadyOwned" end
 local passId=trophy and Config.GetDoubleWinPassId("World1") or M.GetNextWinPassId(player)
 if not passId then releaseWinPrompt(player,lock);return false,"AlreadyOwned" end
 lock.PassId=passId
 lock.Trophy=trophy
 local ok=pcall(function() MarketplaceService:PromptGamePassPurchase(player,passId) end)
 if not ok then releaseWinPrompt(player,lock);return false,"PromptUnavailable" end
 -- Recovery only if Roblox never sends the close event.
 if not trophy then task.delay(120,function() releaseWinPrompt(player,lock) end) end
 return true,"Prompted"
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
 if passId~=Config.GetDoubleWinPassId("World1") and passId~=Config.GetTripleWinPassId("World1") then return end
 local lock=winPromptLocks[player]
 if lock and lock.PassId~=passId then lock=nil end
 if not purchased then
  if lock then releaseWinPrompt(player,lock) end
  return
 end
 if lock and lock.Trophy then trophyPurchases[player]=lock.Trophy end
 task.spawn(function()
  -- A client completion is never sufficient to authorize a multiplier.
  for attempt=1,5 do
   if player.Parent~=Players then break end
   local _,status=M.Refresh(player)
   local entry=cache[player]
   local owned=entry and (passId==Config.GetTripleWinPassId("World1") and entry.Triple or passId==Config.GetDoubleWinPassId("World1") and entry.Double)
   if status=="Verified" and owned then break end
   if attempt<5 then task.wait(attempt) end
  end
  if player.Parent==Players then
   local entry=cache[player]
   local owned=entry and (passId==Config.GetTripleWinPassId("World1") and entry.Triple or passId==Config.GetDoubleWinPassId("World1") and entry.Double)
   if not entry or not entry.Verified or not owned then scheduleWinOwnershipRefresh(player,passId) end
  end
  if lock then releaseWinPrompt(player,lock) end
 end)
end)
Players.PlayerRemoving:Connect(function(player)
 trophyPurchases[player]=nil
 cache[player]=nil;winRefreshBusy[player]=nil;winPromptLocks[player]=nil;winLastRequest[player]=nil;winRecovery[player]=nil
end)

-- Dedicated treadmill entitlement; independent of the existing Double Win cache.
local TreadmillConfig=require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
local premiumCache=setmetatable({}, {__mode="k"})
local premiumBusy=setmetatable({}, {__mode="k"})
local premiumPrompts=setmetatable({}, {__mode="k"})
local function treadmillAttribute(world)
 return world==2 and "HasWorld2PremiumTreadmill" or "HasPremiumTreadmill"
end
function M.HasPremiumTreadmill(player,world)
 local entries=premiumCache[player]
 return entries~=nil and entries[TreadmillConfig.GetPremiumTreadmillPassId(world)]==true
end
function M.RefreshPremiumTreadmill(player,world)
 local passId=TreadmillConfig.GetPremiumTreadmillPassId(world)
 if typeof(passId)~="number" or passId<=0 or passId%1~=0 or passId==math.huge then return false,"Unavailable" end
 local locks=premiumBusy[player] or {};premiumBusy[player]=locks
 if locks[passId] then return M.HasPremiumTreadmill(player,world),"Pending" end
 locks[passId]=true
 local ok,owned=pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId,passId) end)
 locks[passId]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 -- A failed request never grants access or erases a verified entitlement.
 if not ok then return M.HasPremiumTreadmill(player,world),"OwnershipUnavailable" end
 local entries=premiumCache[player] or {};premiumCache[player]=entries
 entries[passId]=owned==true
 player:SetAttribute(treadmillAttribute(world),owned==true)
 return owned==true,"Verified"
end
function M.PromptPremiumTreadmill(player,world,isCurrent)
 if premiumPrompts[player] then return false,"Pending" end
 local lock={PassId=TreadmillConfig.GetPremiumTreadmillPassId(world)}
 premiumPrompts[player]=lock
 local owned,status=M.RefreshPremiumTreadmill(player,world)
 if owned or status~="Verified" or (isCurrent and not isCurrent()) then
  if premiumPrompts[player]==lock then premiumPrompts[player]=nil end
  return false,owned and "AlreadyOwned" or status~="Verified" and status or "Expired"
 end
 local ok=pcall(function() MarketplaceService:PromptGamePassPurchase(player,lock.PassId) end)
 if not ok and premiumPrompts[player]==lock then premiumPrompts[player]=nil end
 return ok,ok and "Prompted" or "PromptUnavailable"
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
 local world=passId==TreadmillConfig.GetPremiumTreadmillPassId(1) and 1
  or passId==TreadmillConfig.GetPremiumTreadmillPassId(2) and 2
 if not world then return end
 local lock=premiumPrompts[player]
 if lock and lock.PassId==passId then premiumPrompts[player]=nil end
 if not purchased then return end
 task.spawn(function()
  for attempt=1,5 do
   if player.Parent~=Players then return end
   local owned=M.RefreshPremiumTreadmill(player,world)
   if owned then return end -- Existing occupancy loop starts training immediately.
   if attempt<5 then task.wait(attempt) end -- Only retry an unconfirmed request.
  end
 end)
end)
Players.PlayerRemoving:Connect(function(player)
 task.defer(function() premiumCache[player]=nil;premiumBusy[player]=nil;premiumPrompts[player]=nil end)
end)

-- Speed entitlement is verified independently of other Game Passes.
local SpeedConfig=require(game.ReplicatedStorage.Config:WaitForChild("SpeedConfig"))
local speedCache=setmetatable({}, {__mode="k"})
local speedBusy=setmetatable({}, {__mode="k"})
local speedStatus=setmetatable({}, {__mode="k"})
function M.HasPremiumSpeed(player)
 return speedCache[player]==true
end
function M.GetPremiumSpeedOwnershipStatus(player)
 return speedStatus[player] or "Pending"
end
function M.RefreshPremiumSpeed(player)
 if speedBusy[player] then return M.HasPremiumSpeed(player),"Pending" end
 speedBusy[player]=true
 local ok,owned=pcall(function()
  return MarketplaceService:UserOwnsGamePassAsync(player.UserId,SpeedConfig.Premium.GamePassId)
 end)
 speedBusy[player]=nil
 if player.Parent~=Players then return false,"PlayerUnavailable" end
 -- An unavailable check never revokes an entitlement verified this session.
 local status=ok and "Verified" or "OwnershipUnavailable"
 speedStatus[player]=status
 if ok then speedCache[player]=owned==true end
 player:SetAttribute("HasPremiumSpeed",M.HasPremiumSpeed(player))
 player:SetAttribute("PremiumSpeedOwnershipStatus",status)
 return M.HasPremiumSpeed(player),status
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
Players.PlayerRemoving:Connect(function(player) speedCache[player]=nil;speedBusy[player]=nil;speedStatus[player]=nil end)

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
Players.PlayerRemoving:Connect(function(player) task.defer(function() shopCache[player]=nil;shopBusy[player]=nil end) end)

return M
