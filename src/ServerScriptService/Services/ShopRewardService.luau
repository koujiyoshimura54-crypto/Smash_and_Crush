local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local Policy=game:GetService("PolicyService")
local Config=require(game.ReplicatedStorage.Config.ShopProductConfig)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Passes=require(game.ServerScriptService.Services.GamePassService)
local Potions=require(game.ServerScriptService.Services.PotionService)
local Items=require(game.ServerScriptService.Services.ItemService)
local M={}
local busy=setmetatable({}, {__mode="k"})
local policies=setmetatable({}, {__mode="k"})
function M.CanUseSecret(player)
 return policies[player]==true
end
local function updatePolicy(player)
 local ok,value=pcall(function()return Policy:GetPolicyInfoForPlayerAsync(player)end)
 policies[player]=ok and value.ArePaidRandomItemsRestricted==false or nil
 return ok
end
function M.GetState(player)
 local saved=Data.GetShopRewards(player)
 local state={GamePassEffectsEnabled=Passes.AreEffectsEnabled(player),Loaded=saved~=nil,Products={},VIPDaily={Status="Locked"},PaidRandomAllowed=M.CanUseSecret(player)}
 for _,key in ipairs(Config.Order) do
  local p=Config.Get(key)
  local owned=p.Kind=="PremiumSpeed" and Passes.HasPremiumSpeed(player) or Passes.HasShopPass(player,key)
  state.Products[key]={Owned=owned or (p.Once==true and saved~=nil and saved.Claims[key]==true),Granted=saved and saved.Claims[key]==true or false}
 end
 if saved and Passes.AreEffectsEnabled(player) and Passes.HasShopPass(player,"VIP") then
  state.VIPDaily.Status=saved.VIPDailyDateUTC>=os.date("!%Y-%m-%d",os.time()) and "Claimed" or "Ready"
 end
 return state
end
function M.Refresh(player)
 if busy[player] then return false,"Pending" end
 if not Data.IsLoaded(player) then return false,"DataNotLoaded" end
 busy[player]=true
 local ok,err=pcall(function()
  updatePolicy(player)
  for _,key in ipairs({"StarterPack","VIP","SecretPack"}) do
   if player.Parent~=Players then return end
   local owned=Passes.RefreshShopPass(player,key)
   if owned and Passes.AreEffectsEnabled(player) and (key~="SecretPack" or M.CanUseSecret(player)) then
    local granted,_,reward=Data.ClaimShopReward(player,key)
    if granted and reward and reward.ItemId then Items.NotifyRegularItemGranted(player,reward.ItemId) end
   end
  end
  local saved=Data.GetShopRewards(player)
  if saved and Passes.AreEffectsEnabled(player) then for id,deadline in pairs(saved.PotionExpiresUTC) do Potions.EnsureExpiresAt(player,id,deadline) end end
 end)
 busy[player]=nil
 if not ok then warn("Shop entitlement refresh failed: "..tostring(err));return false,"RefreshFailed" end
 return true
end
function M.ClaimVIPDaily(player)
 if not Passes.AreEffectsEnabled(player) then return false,"GamePassEffectsDisabled" end
 if not Passes.HasShopPass(player,"VIP") then return false,"VIPRequired" end
 return Data.ClaimShopReward(player,"VIPDaily")
end
function M.Prompt(player,key)
 if typeof(key)~="string" or #key>64 then return false,"InvalidProduct" end
 local product=Config.Get(key)
 if product then
  if product.Kind=="PremiumSpeed" then return Passes.PromptPremiumSpeed(player) end
  if product.Kind~="GamePass" then return false,"InvalidProduct" end
  local owned,status=Passes.RefreshShopPass(player,key)
  if status~="Verified" then return false,status end
  if key=="SecretPack" then
   if not updatePolicy(player) or not M.CanUseSecret(player) then return false,"UnavailableForPlayer" end
  end
  if owned then M.Refresh(player);return false,"AlreadyOwned" end
  local ok=pcall(function()Marketplace:PromptGamePassPurchase(player,product.PassId)end)
  return ok,ok and "Prompted" or "PromptUnavailable"
 end
 local win=Config.GetWinProduct(key)
 if not win or Config.ForWinProduct(win.ProductId)~=win then return false,"ProductNotConfigured" end
 if not Data.IsLoaded(player) then return false,"DataNotLoaded" end
 local ok=pcall(function()Marketplace:PromptProductPurchase(player,win.ProductId)end)
 return ok,ok and "Prompted" or "PromptUnavailable"
end
-- ProcessReceipt supplies the identity; no Remote accepts a receipt or amount.
function M.ProcessWinReceipt(receipt)
 local product=Config.ForWinProduct(receipt.ProductId)
 if not product then return nil end
 local player=Players:GetPlayerByUserId(receipt.PlayerId)
 if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local ok,code=Data.ClaimShopReward(player,product.Key,receipt)
 return (ok or code=="AlreadyClaimed") and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
end
Players.PlayerRemoving:Connect(function(player) busy[player]=nil;policies[player]=nil end)
return M
