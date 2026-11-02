-- Run in Edit after installing the matching Sources. Never saves or publishes.
-- Existing card geometry, colors, strokes and localization settings are preserved.
local RS=game:GetService("ReplicatedStorage")
local config=require(RS.Config.AuraConfig)
local style=require(RS.Config.StrengthHUDStyle)
local list=game.StarterGui.StrengthGui.InventoryPanel.Content.Aura.AuraList
for _,id in ipairs(config.Order) do
 local aura=config.Get(id)
 local card=list:FindFirstChild(id.."AuraCard")
 -- VIP / Secret continue through their existing runtime entitlement-card path.
 if not card and id=="W2_AURA_06" then
  card=list.RedAuraCard:Clone();card.Name=id.."AuraCard";card.LayoutOrder=aura.Order
  card.Visible=false;card.Parent=list
 end
 if card then
  card.AuraName.Text=aura.Name;card.AuraIcon.Image=aura.Icon
  card.StrengthBonus.Text=aura.PurchaseType=="Entitlement" and "Exclusive Aura" or "+"..aura.StrengthBonus.." Strength"
  if aura.PurchaseType=="Win" then card.Price.Amount.Text=tostring(aura.Price)
  elseif id=="W2_AURA_06" then card.Price.Amount.Text="..." end
  for _,text in ipairs(card:GetDescendants()) do
   if text:IsA("TextLabel") or text:IsA("TextButton") or text:IsA("TextBox") then text.FontFace=Font.fromEnum(style.Font) end
  end
 end
end
for _,card in ipairs(list:GetChildren()) do
 local id=card.Name:match("^(.*)AuraCard$")
 if id and config.Get(id) and config.Get(id).Listed==false then card.Visible=false end
end
return "Aura Edit cards updated; no Save / Publish"
