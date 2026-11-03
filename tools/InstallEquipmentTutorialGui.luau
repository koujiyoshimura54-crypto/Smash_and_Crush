-- Edit-only: clone the current approved Pet template once; retain later owner edits.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning(),"Canonical Edit only")
local paths={}
for _,kind in {"Item","Dumbbell"} do
 local name=kind.."EquipTutorialGui"
 if not game.StarterGui:FindFirstChild(name) then
  local gui=game.StarterGui.EggPetTutorialGui:Clone();gui.Name=name
  gui:SetAttribute("Step",nil);gui:SetAttribute("Target",nil);gui:SetAttribute("TutorialPhase",kind=="Item" and 5 or 6)
  for _,x in gui.Messages:GetChildren() do x:Destroy() end
  for key,value in {OpenInventory="Open your Inventory.",ChooseTab=kind=="Item" and "Choose Items." or "Choose Dumbbells.",
   Equip="Press Best Equip.",Complete=kind=="Item" and "Item equipped!" or "Dumbbell equipped!"} do
   local x=Instance.new("StringValue");x.Name=key;x.Value=value;x.Parent=gui.Messages
  end
  gui.Canvas.Highlight.Visible=false;gui.Canvas.Notification.Visible=false
  gui.Parent=game.StarterGui
 end
 table.insert(paths,"StarterGui."..name)
end
-- The normal inventory controller reuses this authored, separately operable button.
local page=game.StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells
local View=require(game.ReplicatedStorage.Modules.DumbbellInventoryView)
View.StyleEquipped(page)
local best=page.Equipped.BestEquipButton
best.Position=UDim2.fromScale(.04,.84);best.Size=UDim2.fromScale(.92,.12)
View.Skin(best,"Best Equip","Best",true)
return paths
