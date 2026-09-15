local Responsive=require(game.ReplicatedStorage.Modules.ResponsivePanels)
local gui=script.Parent
local panel=gui:WaitForChild("InventoryPanel")
local menu=gui:WaitForChild("LeftMenu")
local tabs=panel:WaitForChild("Tabs")
local content=panel:WaitForChild("Content")
local names={"Dumbbells","Items","Merge","Aura","Speed"}
local function selectTab(name)
 panel:SetAttribute("SelectedTab",name)
 for _,tabName in ipairs(names) do
  local selected=tabName==name
  content[tabName].Visible=selected
  local button=tabs[tabName]
  button.BackgroundColor3=selected and Color3.fromRGB(182,93,248) or Color3.fromRGB(113,36,169)
  button.UIStroke.Color=selected and Color3.new(1,1,1) or Color3.fromRGB(42,14,56)
  button.UIStroke.Thickness=selected and 3 or 2
 end
end
local function layout()
 require(game.ReplicatedStorage.Modules.ResponsivePanels).Fit(panel,gui)
end
for _,name in ipairs(names) do Responsive.ConnectActivation(tabs[name],function() selectTab(name) end) end
local function openInventory(tab)
 selectTab(tab or "Dumbbells")
 panel.Visible=true
 for _,name in ipairs({"ShopPanel","RebirthPanel","MergePanel"}) do
  local other=gui:FindFirstChild(name)
  if other then other.Visible=false end
 end
 local skip=gui.Parent:FindFirstChild("StageSkipGui")
 if skip and skip:FindFirstChild("Panel") then skip.Panel.Visible=false end
end
menu.InventoryButton.Activated:Connect(function()
 if panel.Visible then panel.Visible=false else openInventory("Dumbbells") end
end)
-- Compatibility entry point; the legacy menu button is retired after Play verification.
menu.MergeButton.Activated:Connect(function() openInventory("Merge") end)
Responsive.ConnectActivation(panel.CloseButton,function() panel.Visible=false end)
for _,name in ipairs({"ShopButton","RebirthButton","SkipButton"}) do
 menu[name].Activated:Connect(function() panel.Visible=false end)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
selectTab("Dumbbells")
layout()
-- Keep the Inventory shell above the separate right-side menu overlay.
local previousDisplayOrder=gui.DisplayOrder
panel:GetPropertyChangedSignal("Visible"):Connect(function()
 if panel.Visible then
  previousDisplayOrder=gui.DisplayOrder
  gui.DisplayOrder=math.max(previousDisplayOrder,35)
 elseif gui.DisplayOrder==35 then
  gui.DisplayOrder=previousDisplayOrder
 end
end)

