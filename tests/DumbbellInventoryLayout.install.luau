-- Reproduce the authored GUI settings without Save/Publish or sample player data.
assert(not game:GetService("RunService"):IsRunning(),"Edit only")
local source=game.ReplicatedStorage.Modules.DumbbellInventoryView
local fresh=source:Clone();fresh.Name="__DumbbellLayoutInstaller";fresh.Parent=source.Parent
local view=require(fresh)
view.StyleEquipped(game.StarterGui.StrengthGui.InventoryPanel.Content.Dumbbells)
fresh:Destroy()
