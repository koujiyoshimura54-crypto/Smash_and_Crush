-- Reuse the purchased close artwork; this module never requests a purchase.
local M={PixelSize=48,Padding=4}
function M.Fit(close,scale)
 scale=math.max(tonumber(scale) or 1,.01)
 close.Size=UDim2.fromOffset(math.ceil(M.PixelSize/scale),math.ceil(M.PixelSize/scale))
 close.Position=UDim2.new(1,-M.Padding/scale,0,M.Padding/scale)
end
function M.Mount(parent,janitor,onClose)
 local donor=game:GetService("StarterGui").ScreenGui.Menus.Inventory.Exit
 local close=donor:Clone()
 close.Name="EggSheetClose"
 for _,x in close:GetDescendants() do
  if x:IsA("LuaSourceContainer") then x:Destroy()
  elseif x:IsA("GuiObject") then x.Active=false;x.ZIndex=200+x.ZIndex end
 end
 close.AnchorPoint=Vector2.new(1,0);close.Visible=true;close.ZIndex=200
 local aspect=close:FindFirstChildOfClass("UIAspectRatioConstraint")
 if aspect then aspect.AspectRatio=1 end
 local button=close.Button
 button.Active=true;button.Interactable=true;button.Selectable=true
 M.Fit(close,1)
 close.Parent=parent
 janitor:Add(close,"Destroy")
 janitor:Add(button.Activated:Connect(onClose))
 return close
end
return table.freeze(M)
