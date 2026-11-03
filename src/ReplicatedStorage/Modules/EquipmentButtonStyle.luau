-- Both Best Equip controls share the CURRENT authored green Equipped badge.
local M={}
function M.Gradient()
 return game.StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells.Equipped.EquippedBadge.UIGradient.Color
end
function M.Apply(button)
 local visual=button:FindFirstChild("PurchasedButtonVisual")
 local body=visual and visual:FindFirstChild("Main") or button
 local gradient=body:FindFirstChildOfClass("UIGradient")
 if gradient then gradient.Color=M.Gradient();gradient.Rotation=90;gradient.Enabled=true end
 body.BackgroundColor3=Color3.new(1,1,1)
 for _,name in {"OuterUIStroke","InnerUIStroke"} do
  local stroke=button:FindFirstChild(name);if stroke then stroke.Color=Color3.new() end
 end
 local label=visual and body:FindFirstChild("Amount") or button:FindFirstChild("Label")
 if label then
  label.TextColor3=Color3.new(1,1,1)
  for _,s in label:GetChildren() do if s:IsA("UIStroke") then s.Color=Color3.new();s.Enabled=true end end
 end
end
return table.freeze(M)
