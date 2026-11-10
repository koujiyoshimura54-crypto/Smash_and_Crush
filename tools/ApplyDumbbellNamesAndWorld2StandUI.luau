-- Edit-only installer. Uses the canonical World1 GUI; never moves a stand or copies W1 balance.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local RS=game.ReplicatedStorage
-- Edit tools can retain a pre-edit require cache. Read a temporary fresh instance.
local fresh=RS.Config.DumbbellItemMaster:Clone();fresh.Name="__DumbbellNameCatalog";fresh.Parent=RS.Config
local ok,Master=pcall(require,fresh);fresh:Destroy();assert(ok,Master)
local Style=require(RS.Modules.DumbbellStandPresentation)
local Format=require(RS.Modules.NumberFormat)
local template=RS:FindFirstChild("DumbbellStandBillboardTemplate")
if not template then
 template=workspace.PerStepButtons["1"].BillboardGui:Clone()
 template.Name="DumbbellStandBillboardTemplate";template.Adornee=nil;template.Parent=RS
end
local changed={}
for _,item in ipairs(Master.GetSorted(2)) do
 local model=workspace.World2Map.TrainingArea.DumbbellDisplays.PerStepButtons[tostring(item.Grade)]
 local board=Style.Ensure(model);board.Adornee=model.Press
 board.ItemIcon.Image=item.Image
 board.Price.Text="+"..tostring(item.StrengthBonus).." Strength"
 board.Amount.Main.Text=Format.Price(item.PriceWin)
 board.Status.Text="Step to buy"
 table.insert(changed,board:GetFullName())
end
local label=game.StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells.Equipped.ItemName
local number=label.Text:match("^Normal Dumbbell (%d+)$") or label.Text:match("^通常ダンベル%s*(%d+)$")
if number then label.Text=assert(Master.Get(string.format("NORMAL_%02d",tonumber(number)))).Name end
label.AutoLocalize=false
return changed
