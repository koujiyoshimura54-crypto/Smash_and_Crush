-- Two independent entry banners. Purchases/entitlements stay server-authorized.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService")
local Config=require(RS.Config.WorldPassConfig)
local Prices=require(RS.Modules.MarketplacePrice)
local Presentation=require(RS.Modules.RightHUDPresentation)
local player=Players.LocalPlayer
local gui=script.Parent
local strengthGui=gui.Parent:WaitForChild("StrengthGui")
local remote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
Presentation.EnsureBanners(gui,strengthGui)
local layout=require(RS.Modules.HUDLayout).Mount(strengthGui)
layout.Refresh()
local alive=true
local connections,workers={},{}
local entries={
 {Button=gui.DoubleWinButton,Id=Config.GetDoubleWinPassId("World1"),Action="DoubleWinOnly",Result="WinPassPromptResult",Owned="HasWorld1DoubleWin",Verified="WinPassOwnershipVerified",Busy="WinPassPromptBusy"},
 {Button=gui.StrengthPassButton,Id=Config.StrengthPass.GamePassId,Action="StrengthPrompt",Result="StrengthPassPromptResult",Owned="HasStrengthPass",Verified="StrengthPassOwnershipStatus",Busy="StrengthPassPromptBusy"},
}
local function render()
 if not alive then return end
 gui.Enabled=Config.GetWorld(game.PlaceId)=="World1"
 local busy=player:GetAttribute("WinPassPromptBusy")==true or player:GetAttribute("StrengthPassPromptBusy")==true
 for _,e in entries do
  local verified=player:GetAttribute(e.Verified)
  Presentation.SetState(e.Button,e.Price,e.PriceSource,player:GetAttribute(e.Owned)==true,
   verified==true or verified=="Verified",busy or e.Asking==true)
 end
end
local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
for _,e in entries do
 connect(e.Button.Activated,function()
  if not e.Button.Active or e.Asking then return end
  e.Asking=true;e.Request=(e.Request or 0)+1
  local request=e.Request;render()
  local ok=pcall(function()remote:FireServer(e.Action)end)
  if not ok then e.Asking=false;render()end
  -- Recover a lost response; server cooldown/lock remains authoritative.
  if e.Timeout and coroutine.status(e.Timeout)~="dead" then task.cancel(e.Timeout) end
  e.Timeout=task.delay(5,function()
   e.Timeout=nil
   if alive and e.Request==request then e.Asking=false;render()end
  end)
 end)
 for _,attribute in {e.Owned,e.Verified,e.Busy} do connect(player:GetAttributeChangedSignal(attribute),render) end
 table.insert(workers,task.spawn(function()
  while alive do
   local price,source=Prices.Get(e.Id,Enum.InfoType.GamePass,nil)
   if not alive then return end
   e.Price,e.PriceSource=price,source;render()
   task.wait(price and 60 or 30)
  end
 end))
end
connect(remote.OnClientEvent,function(action)
 for _,e in entries do if action==e.Result then e.Asking=false end end
 render()
end)
connect(Market.PromptGamePassPurchaseFinished,function(who,id)
 if who~=player then return end
 for _,e in entries do if id==e.Id then e.Asking=false end end
 render() -- Never trust purchase callback as proof of ownership.
end)
connect(script.Destroying,function()
 alive=false
 for _,c in connections do c:Disconnect()end
 for _,e in entries do if e.Timeout and coroutine.status(e.Timeout)~="dead" then task.cancel(e.Timeout)end end
 for _,thread in workers do if coroutine.status(thread)~="dead" then task.cancel(thread)end end
end)
render()
