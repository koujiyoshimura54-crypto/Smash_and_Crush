-- Presentation only. Callers supply replicated server Win and server inventory state.
local Config=require(game.ReplicatedStorage.Config:WaitForChild("AuraConfig"))
local Badges=require(game.ReplicatedStorage.Modules:WaitForChild("BadgeRenderer"))
local M={}
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
 local available,any=M.Evaluate(loaded,owned,win)
 local inventory=gui.InventoryPanel
 Badges.SetVisible(inventory.Tabs.Aura.AuraPurchaseBadge,any)
 for _,card in ipairs(inventory.Content.Aura.AuraList:GetChildren()) do
  local button=card:FindFirstChild("BuyButton")
  local badge=button and button:FindFirstChild("AuraPurchaseBadge")
  if badge then
   local id=card.Name:gsub("AuraCard$","")
   Badges.SetVisible(badge,available[id]==true)
  end
 end
 -- Existing Inventory notifications retain their own rules and share one badge.
 gui.LeftMenu.InventoryButton:SetAttribute("AuraPurchaseAvailable",any)
end
return M

