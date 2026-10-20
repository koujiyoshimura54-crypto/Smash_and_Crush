-- Inventory presentation only; SpeedService remains the normal-speed authority.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Marketplace=game:GetService("MarketplaceService")
local Responsive=require(RS.Modules.ResponsivePanels)
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local Config=require(RS.Config:WaitForChild("SpeedConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local player=Players.LocalPlayer
local gui=script.Parent
local shell=gui:WaitForChild("InventoryPanel")
local page=shell.Content:WaitForChild("Speed")
local purchase=RS.Remotes:WaitForChild("SpeedPurchaseRequest") -- existing server state pushes only
local stateRemote=RS.Remotes:WaitForChild("SpeedInventoryState")
local prompt=RS.Remotes:WaitForChild("SpeedPremiumPrompt")
local equip=RS.Remotes:WaitForChild("SpeedEquipRequest")
local view=Presentation.BuildSpeedView(shell,Config)
-- The retired 600-Win offer must not advertise a purchase on this surface.
local badge=shell.Tabs.Speed:FindFirstChild("SpeedPurchaseBadge")
if badge then badge.Visible=false end
gui.LeftMenu.InventoryButton:SetAttribute("SpeedPurchaseAvailable",false)
local state={Loaded=false,OwnedSpeeds={},PremiumOwned=false}
local pending,priceBusy=false,false
local revision=0
local price,priceSource,message=nil,nil,""
local function render() view:SetState(state,pending,price,priceSource,message) end
local function apply(s)
 if typeof(s)~="table" or s.Loaded~=true or typeof(s.OwnedSpeeds)~="table" then return end
 revision+=1;state=s;render()
end
local function refresh()
 local version=revision
 local ok,s=pcall(function() return stateRemote:InvokeServer() end)
 if ok and version==revision then apply(s) end
end
local function refreshPrice()
 if priceBusy or priceSource=="Marketplace" then return end
 priceBusy=true
 task.spawn(function()
  price,priceSource=MarketplacePrice.Get(Config.Premium.GamePassId,Enum.InfoType.GamePass,nil)
  priceBusy=false
  if not shell.Parent then return end
  if priceSource~="Marketplace" and not state.PremiumOwned then message="Price unavailable. Please reopen."
  elseif message=="Price unavailable. Please reopen." then message="" end
  render()
 end)
end
local messages={AlreadyOwned="Already owned",DataNotLoaded="Loading player data...",RequestInProgress="Please wait.",OwnershipUnavailable="Ownership check unavailable. Please try again.",PromptUnavailable="Purchase unavailable."}
Responsive.ConnectActivation(view.BuyButton,function()
 if not view.BuyButton.Active or not view.BuyButton.Interactable then return end
 pending=true;message="";render()
 if state.PremiumOwned then equip:FireServer("Premium")else prompt:FireServer("Prompt")end
end)
Responsive.ConnectActivation(view.NormalButton,function()
 if pending or not state.Loaded or state.EquippedSpeed=="Normal"then return end
 pending=true;message="";render();equip:FireServer("Normal")
end)
equip.OnClientEvent:Connect(function(result)
 pending=false
 if typeof(result)=="table"then apply(result.State);message=result.Success and ""or (messages[result.Code]or "Please try again.")end
 render()
end)
purchase.OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 -- Upgrade results refresh normal Speed without resetting a Premium prompt.
 if result.Success~=nil and result.Action~="Upgrade" then pending=false;message=result.Success and "" or (messages[result.Code] or "Please try again.") end
 apply(result.State);render()
end)
prompt.OnClientEvent:Connect(function(result)
 if typeof(result)=="table" and result.Success~=true then
  pending=false;message=messages[result.Code] or "Please try again.";refresh();render()
 end
end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function(p,id)
 if p==player and id==Config.Premium.GamePassId then
  pending=false;refresh();render() -- ownership is re-read from the server, never granted here
 end
end)
-- Recover the input lock if a response/prompt-close notification is lost.
local pendingVersion=0
local function recoverPending()
 pendingVersion+=1;local version=pendingVersion
 task.delay(15,function()
  if pending and version==pendingVersion and script.Parent then pending=false;message="Please try again.";refresh();render()end
 end)
end
view.BuyButton.Activated:Connect(recoverPending)
view.NormalButton.Activated:Connect(recoverPending)
local function opened()
 if shell.Visible and page.Visible then refreshPrice();refresh() end
end
page:GetPropertyChangedSignal("Visible"):Connect(opened)
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
render();refreshPrice()
task.spawn(function()
 while script.Parent and not state.Loaded do refresh();if not state.Loaded then task.wait(2) end end
 if script.Parent then render() end
end)
