-- Applied to canonical Edit; replay only these scoped authored GUI properties.
local label=game.StarterGui.StrengthGui.RebirthPanel.RebirthProgress
label.Font=Enum.Font.FredokaOne
label.Text="Required Level: 25"
label.TextSize=32
label.Size=UDim2.fromScale(.9,.09)
local limit=label:FindFirstChild("RequiredLevelTextSize") or Instance.new("UITextSizeConstraint")
limit.Name="RequiredLevelTextSize";limit.MinTextSize=18;limit.MaxTextSize=32;limit.Parent=label
local message=game.StarterGui.DeathGui.Overlay.Message
local detail=message.Parent:FindFirstChild("LootLoss") or message:Clone()
detail.Name="LootLoss";detail.Text="You lost your loot."
detail.Size=UDim2.fromScale(.75,.04);detail.Position=UDim2.fromScale(.5,.63);detail.Visible=false
local size=detail:FindFirstChildOfClass("UITextSizeConstraint")
if size then size.MinTextSize=16;size.MaxTextSize=26 end
detail.Parent=message.Parent
