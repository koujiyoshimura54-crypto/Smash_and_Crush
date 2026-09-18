local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Presentation=require(RS.Modules:WaitForChild("InventoryPresentation"))
local Marketplace=game:GetService("MarketplaceService")
local player=Players.LocalPlayer
local Config=require(RS.Config:WaitForChild("AuraConfig"))
local MarketplacePrice=require(RS.Modules:WaitForChild("MarketplacePrice"))
local gui=script.Parent
local shell=gui:WaitForChild("InventoryPanel")
local panel=shell.Content.Aura
local list=panel:WaitForChild("AuraList")
local purchase=RS.Remotes:WaitForChild("AuraPurchaseRequest")
local equip=RS.Remotes:WaitForChild("AuraEquipRequest")
local remote=RS.Remotes:WaitForChild("AuraInventoryState")
local shopRequest=RS.Remotes:WaitForChild("ShopPurchaseRequest")
-- Entitlement cards reuse the authored Aura template and existing equip renderer.
for _,id in ipairs(Config.Order) do
 if not list:FindFirstChild(id.."AuraCard") then
  local card=list.PinkAuraCard:Clone()
  card.Name=id.."AuraCard";card.LayoutOrder=Config.Get(id).Order
  card.Parent=list
 end
end
local owned={}
local equipped=""
local loaded=false
local pending=false
local redPurchasePending=false
local notice={}
local green=list.PinkAuraCard.BuyButton.UIGradient.Color
-- Match existing inventory equip / equipped colors without rebuilding cards.
local equipColor=ColorSequence.new(Color3.fromRGB(75,136,213),Color3.fromRGB(47,91,151))
local equippedColor=ColorSequence.new(Color3.fromRGB(111,120,137),Color3.fromRGB(70,76,88))
local AuraNotifications=require(gui:WaitForChild("AuraPurchaseNotifications"))
local redDisplayPrice=Config.Get("Red").DisplayPriceFallback
local function render()
 AuraNotifications.Render(gui,loaded,owned,player:GetAttribute("Win"))
 for _,id in ipairs(Config.Order) do
  local aura=Config.Get(id)
  local card=list[id.."AuraCard"]
  Presentation.SetIdentity(card.AuraName,card.AuraIcon,aura.Name,aura.Icon)
  local b=card.BuyButton
  local isEquipped=equipped==id
  b.Label.Text=notice[id] or (isEquipped and "EQUIPPED" or owned[id] and "EQUIP" or aura.PurchaseType=="Entitlement" and "VIEW PACK" or "BUY")
  b.UIGradient.Color=isEquipped and equippedColor or owned[id] and equipColor or green
  Presentation.SetButtonEnabled(b,loaded and not pending)
  card.Price.Amount.Text=aura.PurchaseType=="Entitlement" and (aura.Entitlement=="VIP" and "VIP" or "PACK") or tostring(aura.PurchaseType=="Win" and aura.Price or redDisplayPrice)
  card.StrengthBonus.Text=aura.PurchaseType=="Entitlement" and "Exclusive Aura" or "+"..aura.StrengthBonus.." Strength"
 end
end
local function apply(state)
 if typeof(state)~="table" or not state.Loaded then return end
 loaded=true
 owned=state.OwnedAuras
 equipped=state.EquippedAura or ""
 render()
end
local function refresh()
 local ok,state=pcall(function() return remote:InvokeServer() end)
 if ok and not redPurchasePending then apply(state) end
end
local activeId
local function result(message)
 if typeof(message)~="table" then return end
 if message.Success~=nil then redPurchasePending=false end
 if not redPurchasePending then apply(message.State) end
 if message.Success~=nil then
  pending=false
  if message.Success==false and activeId then
   local id=activeId
   local texts={NotEnoughWin="NEED WIN",SavePending="SAVE PENDING",DataSaving="TRY AGAIN",RequestInProgress="TRY AGAIN",OwnershipUnavailable="TRY AGAIN"}
   notice[id]=texts[message.Code] or "TRY AGAIN"
   task.delay(2,function() notice[id]=nil;render() end)
  end
  activeId=nil
 end
 render()
end
purchase.OnClientEvent:Connect(result)
equip.OnClientEvent:Connect(result)
for _,id in ipairs(Config.Order) do
 Responsive.ConnectActivation(list[id.."AuraCard"].BuyButton,function()
  if not loaded or pending then return end
  notice[id]=nil
  if owned[id] then
   pending=true;activeId=id;render()
   equip:FireServer(equipped==id and "" or id)
  elseif Config.Get(id).PurchaseType=="Entitlement" then
   shell.Visible=false;gui.ShopPanel.Visible=true
   gui.ShopPanel:SetAttribute("FocusProduct",Config.Get(id).Entitlement)
  elseif Config.Get(id).PurchaseType=="GamePass" then
   pending=true;redPurchasePending=true;render()
   local ok=pcall(function() Marketplace:PromptGamePassPurchase(player,Config.Get(id).GamePassId) end)
   if not ok then pending=false;redPurchasePending=false;render() end
  else
   pending=true;activeId=id;render()
   purchase:FireServer(id)
  end
 end)
end
Marketplace.PromptGamePassPurchaseFinished:Connect(function(who,id,purchased)
 if who==player and id==Config.Get("Red").GamePassId then
  if not purchased then pending=false;redPurchasePending=false;render();refresh() end
  -- On success keep the current button until the server verifies, saves and replies.
 end
end)
local function opened()
 if shell.Visible and panel.Visible then
  refresh()

 end
end
shell:GetPropertyChangedSignal("Visible"):Connect(opened)
panel:GetPropertyChangedSignal("Visible"):Connect(opened)
AuraNotifications.Changed:Connect(render)
render()
task.spawn(function()
 while script.Parent and not require(RS.Modules:WaitForChild("InventoryNotificationState")).Load() do task.wait(2) end
 refresh()
end)
-- Display only: obtain the platform's current pass price without blocking UI.
task.spawn(function()
 local source
 redDisplayPrice,source=MarketplacePrice.Get(Config.Get("Red").GamePassId,Enum.InfoType.GamePass,Config.Get("Red").DisplayPriceFallback)
 list.RedAuraCard.Price:SetAttribute("PriceSource",source)
 render()
end)
-- A Win change can add or remove eligibility without opening Inventory.
player:GetAttributeChangedSignal("Win"):Connect(function()
 AuraNotifications.Render(gui,loaded,owned,player:GetAttribute("Win"))
end)
-- Handle UI starting before PlayerData has finished loading.
task.spawn(function()
 while script.Parent and not loaded do
  refresh()
  if not loaded then task.wait(2) end
 end
end)
