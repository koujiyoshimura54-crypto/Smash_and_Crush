-- Phase 7.2.3.1: shared menu presentation only.
-- Skip and Rebirth are bound by their existing client scripts.
local TweenService=game:GetService("TweenService")
local gui=script.Parent
local menu=gui:WaitForChild("LeftMenu")
local layout=require(game.ReplicatedStorage.Modules:WaitForChild("HUDLayout")).Mount(gui).Refresh
for _,name in ipairs({"SkipButton","InventoryButton","RebirthButton","ShopButton","MergeButton"}) do
 local button=menu:WaitForChild(name)
 local tween
 local function highlight(on)
  if tween then tween:Cancel() end
  tween=TweenService:Create(button,TweenInfo.new(0.12),{
   BackgroundColor3=on and Color3.fromRGB(53,65,89) or Color3.fromRGB(29,35,49),
  })
  tween:Play()
 end
 button.MouseEnter:Connect(function() highlight(button.Active) end)
 button.MouseLeave:Connect(function() highlight(false) end)
 button.SelectionGained:Connect(function() highlight(button.Active) end)
 button.SelectionLost:Connect(function() highlight(false) end)
end
-- Inventory interaction is handled by InventoryPanelClient.


gui.Parent.ChildAdded:Connect(function(child) if child.Name=="World1DoubleWinGui" then task.defer(layout) end end)
task.defer(layout)
