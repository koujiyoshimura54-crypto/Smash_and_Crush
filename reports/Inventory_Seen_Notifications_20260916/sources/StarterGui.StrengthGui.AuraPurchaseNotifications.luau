-- Presentation only. Callers supply replicated server Win and server inventory state.
local Config=require(game.ReplicatedStorage.Config:WaitForChild("AuraConfig"))
local Badges=require(game.ReplicatedStorage.Modules:WaitForChild("BadgeRenderer"))
local NotificationState=require(game.ReplicatedStorage.Modules:WaitForChild("InventoryNotificationState"))
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
 local available=M.Evaluate(loaded,owned,win)
 local any=false
 local inventory=gui.InventoryPanel
 for _,card in ipairs(inventory.Content.Aura.AuraList:GetChildren()) do
  local button=card:FindFirstChild("BuyButton")
  local badge=button and button:FindFirstChild("AuraPurchaseBadge")
  if badge then
   local id=card.Name:gsub("AuraCard$","")
   local isNew=available[id]==true and not NotificationState.IsSeen("Aura",id)
   any=any or isNew
   Badges.SetVisible(badge,isNew)
  end
 end
 Badges.SetVisible(inventory.Tabs.Aura.AuraPurchaseBadge,any)
 gui.LeftMenu.InventoryButton:SetAttribute("AuraPurchaseAvailable",any)
end
function M.MarkSeen(loaded,owned,win)
 local available=M.Evaluate(loaded,owned,win)
 local ids={}
 for id,value in pairs(available) do if value then table.insert(ids,id) end end
 NotificationState.MarkSeen("Aura",ids)
end
M.Changed=NotificationState.Changed
return M

