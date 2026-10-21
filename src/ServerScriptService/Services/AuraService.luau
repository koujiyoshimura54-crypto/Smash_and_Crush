local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local Config=require(game.ReplicatedStorage.Config:WaitForChild("AuraConfig"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Passes=require(game.ServerScriptService.Services.GamePassService)
local M={}
local busy=setmetatable({}, {__mode="k"})
local pass=setmetatable({}, {__mode="k"})
local function sessionFor(player)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return nil,"InvalidPlayer" end
 local s=Data.Get(player)
 if not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 return s
end
function M.RefreshPassOwnership(player,id,force)
 local aura=Config.Get(id)
 if not aura or aura.PurchaseType~="GamePass" then return false,"InvalidAuraId" end
 local s,code=sessionFor(player)
 if not s then return false,code end
 local entries=pass[player] or {};pass[player]=entries
 local cached=entries[id]
 if cached and not force and os.clock()-cached.time<60 then return cached.owned,"Verified" end
 if busy[player] then return cached and cached.owned==true or false,"RequestInProgress" end
 busy[player]=true
 local ok,owned=pcall(function() return Marketplace:UserOwnsGamePassAsync(player.UserId,aura.GamePassId) end)
 busy[player]=nil
 if not ok then return cached and cached.owned==true or false,"OwnershipUnavailable" end
 if Data.Get(player)~=s then return false,"DataNotLoaded" end
 entries[id]={owned=owned==true,time=os.clock()}
 -- The saved flag is only a cache. Gameplay also requires this verified session.
 if not s.Saving then
  local value=owned and true or nil
  if s.Data.OwnedAuras[id]~=value then s.Data.OwnedAuras[id]=value;s.Dirty=true end
 end
 return owned==true,"Verified"
end
function M.RefreshRedOwnership(player,force) return M.RefreshPassOwnership(player,"Red",force) end
function M.GetOwnedAuras(player)
 local s,code=sessionFor(player)
 if not s then return nil,code end
 local out={}
 for _,id in ipairs(Config.Order) do
  if Config.Get(id).PurchaseEnabled==false then out[id]=false
  elseif Config.Get(id).PurchaseType=="GamePass" then out[id]=pass[player]~=nil and pass[player][id]~=nil and pass[player][id].owned==true
  elseif id=="VIP" then out[id]=s.Data.OwnedAuras[id]==true and Passes.HasShopPass(player,"VIP")
  else out[id]=s.Data.OwnedAuras[id]==true end
 end
 return out
end
function M.GetEquippedAura(player)
 local s=sessionFor(player)
 if not s then return nil end
 local id=s.Data.EquippedAura
 local owned=M.GetOwnedAuras(player)
 return Config.Get(id) and owned[id]==true and id or nil
end
M.GetSelectedAura=M.GetEquippedAura -- compatibility for existing server callers
function M.GetStrengthBonus(player)
 local aura=Config.Get(M.GetEquippedAura(player))
 if aura and (aura.PurchaseType=="GamePass" or aura.PurchaseType=="Entitlement") and not Passes.AreEffectsEnabled(player) then return 0 end
 return aura and aura.StrengthBonus or 0
end
local function mutate(player,callback,persist,equipAuraOnSuccess)
 local s,code=sessionFor(player)
 if not s then return false,code end
 if busy[player] then return false,"RequestInProgress" end
 if s.Saving or s.PendingItemMutation then return false,"DataSaving" end
 busy[player]=true
 local ok,success,result=pcall(function()
  local changed,reason=callback(s)
  if not changed then return false,reason end
  s.Dirty=true
  if persist then
   local saved,err=Data.Save(player,equipAuraOnSuccess)
   if not saved then
    s.Dirty=true
    return false,err=="SaveSupersededByReset" and err or "SavePending"
   end
  end
  return true,reason
 end)
 busy[player]=nil
 if not ok then warn("Aura request failed: "..tostring(success));return false,"RequestFailed" end
 return success,result
end
function M.PurchaseAura(player,id)
 local aura=Config.Get(id)
 if not aura then return false,"InvalidAuraId" end
 if aura.PurchaseType~="Win" then return false,"InvalidPurchaseType" end
 return mutate(player,function(s)
  if s.Data.OwnedAuras[id]==true then return false,"AlreadyOwned" end
  local win=s.Data.Win
  if typeof(win)~="number" or win~=win or win==math.huge or win<0 or win%1~=0 then return false,"InvalidWin" end
  if win<aura.Price then return false,"NotEnoughWin" end
  -- No yield between balance validation, debit, and permanent ownership.
  if not Data.SetWin(player,win-aura.Price) then return false,"DataNotLoaded" end
  s.Data.OwnedAuras[id]=true
  return true,"Purchased"
 end,true,id)
end
function M.EquipAura(player,id)
 local aura=Config.Get(id)
 if not aura then return false,"InvalidAuraId" end
 if aura.PurchaseType=="Entitlement" and M.GetOwnedAuras(player)[id]~=true then return false,"NotOwned" end
 if aura.PurchaseType=="GamePass" then
  local owned,code=M.RefreshPassOwnership(player,id,false)
  if not owned then return false,code=="Verified" and "NotOwned" or code end
 end
 return mutate(player,function(s)
  if aura.PurchaseType=="GamePass" then s.Data.OwnedAuras[id]=true end
  return Data.SetEquippedAura(player,id)
 end,false)
end
-- Only the server's successful pass-purchase event calls this entry point.
function M.CompleteRedPurchase(player)
 local owned,code=M.RefreshRedOwnership(player,true)
 if not owned then return false,code=="Verified" and "NotOwned" or code end
 return mutate(player,function(s)
  s.Data.OwnedAuras.Red=true
  return true,"Purchased"
 end,true,"Red")
end
function M.CompletePassPurchase(player,id)
 if id=="Red" then return M.CompleteRedPurchase(player) end
 local owned,code=M.RefreshPassOwnership(player,id,true)
 if not owned then return false,code=="Verified" and "NotOwned" or code end
 -- Pass ownership is durable on Roblox; selecting this Aura remains explicit.
 return true,"Purchased"
end
function M.UnequipAura(player)
 return mutate(player,function() return Data.SetEquippedAura(player,"") end,false)
end
return M
