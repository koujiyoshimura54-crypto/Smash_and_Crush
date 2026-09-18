-- Presentation only. Callers supply replicated server Win and server inventory state.
local Config=require(game.ReplicatedStorage.Config:WaitForChild("AuraConfig"))
local Badges=require(game.ReplicatedStorage.Modules:WaitForChild("BadgeRenderer"))
local NotificationState=require(game.ReplicatedStorage.Modules:WaitForChild("InventoryNotificationState"))
local Exposure=require(game.ReplicatedStorage.Modules:WaitForChild("InventoryNotificationExposure"))
local M={}
local exposure
function M.Evaluate(loaded,owned,win)
 local result={}
 local any=false
 if loaded and typeof(owned)=="table" and typeof(win)=="number" and win==win then
  for _,id in ipairs(Config.Order) do
   local aura=Config.Get(id)
   -- Robux products never contribute, including an unowned Red Aura.
   if id~="Red" and aura.PurchaseType=="Win" then
    local can=owned[id]~=true and win>=aura.Price
    result[id]=can
    any=any or can
   end
  end
 end
 return result,any
end
function M.Render(gui,loaded,owned,win)
 local available=M.Evaluate(loaded,owned,win)
 local inventory=gui.InventoryPanel
 local page=inventory.Content.Aura
 exposure=exposure or Exposure.new({Gui=gui,Panel=inventory,Page=page,List=page.AuraList,Category="Aura",CardCategory="Aura",TabPrefix="Tab:"})
 local targets={}
 for _,card in ipairs(page.AuraList:GetChildren()) do
  if card:FindFirstChild("BuyButton") then targets[card.Name:gsub("AuraCard$","")]=card.BuyButton end
 end
 exposure:Update(available,targets)
 for _,card in ipairs(inventory.Content.Aura.AuraList:GetChildren()) do
  local button=card:FindFirstChild("BuyButton")
  local badge=button and button:FindFirstChild("AuraPurchaseBadge")
  if badge then
   local id=card.Name:gsub("AuraCard$","")
   local isNew=exposure:CardUnseen(id)
   Badges.SetVisible(badge,isNew)
  end
 end
 Badges.SetVisible(inventory.Tabs.Aura.AuraPurchaseBadge,exposure:HasTab())
 gui.LeftMenu.InventoryButton:SetAttribute("AuraPurchaseAvailable",exposure:HasInventory())
end
M.Changed=NotificationState.Changed
return M
