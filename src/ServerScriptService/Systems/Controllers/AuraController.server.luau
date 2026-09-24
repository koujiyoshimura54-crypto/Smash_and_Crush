local Players=game:GetService("Players")
local Marketplace=game:GetService("MarketplaceService")
local RS=game:GetService("ReplicatedStorage")
local Aura=require(game.ServerScriptService.Services:WaitForChild("AuraService"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Config=require(RS.Config:WaitForChild("AuraConfig"))
local stateRemote=RS.Remotes:WaitForChild("AuraInventoryState")
local purchaseRemote=RS.Remotes:WaitForChild("AuraPurchaseRequest")
local equipRemote=RS.Remotes:WaitForChild("AuraEquipRequest")
local Effects=require(game.ServerScriptService.Services:WaitForChild("AuraCharacterEffects"))
local last=setmetatable({}, {__mode="k"})
local function state(player)
 local owned=Aura.GetOwnedAuras(player)
 return {Loaded=owned~=nil,OwnedAuras=owned or {},EquippedAura=Aura.GetEquippedAura(player) or "",Win=player:GetAttribute("Win") or 0}
end
local function refresh(player,force)
 Aura.RefreshRedOwnership(player,force)
 if player.Parent==Players then purchaseRemote:FireClient(player,{State=state(player)}) end
end
stateRemote.OnServerInvoke=function(player)
 local result=state(player)
 if result.Loaded then task.defer(refresh,player,false) end
 return result
end
local function handle(remote,player,id,action)
 local now=os.clock()
 if last[player] and now-last[player]<.2 then
  remote:FireClient(player,{Success=false,Code="RequestInProgress",State=state(player)})
  return
 end
 last[player]=now
 local success,code=action(player,id)
 if player.Parent==Players then
  remote:FireClient(player,{Success=success,Code=code,State=state(player)})
 end
end
purchaseRemote.OnServerEvent:Connect(function(player,id) handle(purchaseRemote,player,id,Aura.PurchaseAura) end)
equipRemote.OnServerEvent:Connect(function(player,id)
 handle(equipRemote,player,id,function(p,value)
  if value=="" then return Aura.UnequipAura(p) end
  return Aura.EquipAura(p,value)
 end)
end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
 if id==Config.Get("Red").GamePassId and purchased then
  task.spawn(function()
   for attempt=1,3 do
    local success,code=Aura.CompleteRedPurchase(player)
    if player.Parent~=Players then return end
    if success or attempt==3 or code=="SavePending" then
     purchaseRemote:FireClient(player,{Success=success,Code=code,State=state(player)})
     return
    end
    task.wait(attempt)
   end
  end)
 end
end)
local function added(player)
 Effects.Bind(player)
 task.spawn(function()
  while player.Parent==Players and not Data.IsLoaded(player) do task.wait(.25) end
  if player.Parent==Players then Effects.Sync(player);refresh(player,false) end
 end)
end
Players.PlayerAdded:Connect(added)
for _,p in ipairs(Players:GetPlayers()) do added(p) end
Players.PlayerRemoving:Connect(function(p) last[p]=nil;Effects.Unbind(p) end)
