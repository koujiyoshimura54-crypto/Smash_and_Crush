-- Idempotent authored additions. Existing manual guide styling is preserved.
assert(game.PlaceId==126576845524886)
local source=assert(workspace:FindFirstChild("Gift")):FindFirstChild("Cube.003")
assert(source and source:IsA("MeshPart"),"Workspace.Gift.Cube.003 must be the authored chest")
-- Keep the existing authored Gift available to the existing hatch viewport renderer.
-- No replacement asset is created; the renderer uses its usual transient display copy.
workspace.Gift.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
local messages=game.StarterGui.OreMergeTutorialGui.Messages
for name,value in {
 HigherGoToMerge="Go to Merge to create a stronger dumbbell!",
 HigherChooseOre="Select Ore.",
 HigherAddOres="Choose 2–5 ores worth at least 20 points.",
 HigherAddAnother="Add another ore to reach 20 points.",
 HigherScrollOres="Scroll to ores worth at least 20 points.",
 HigherMerge="Press Merge to create a stronger dumbbell.",
 HigherSaving="Creating your stronger dumbbell…",
 HigherClearOres="Clear these ores, then choose at least 20 points.",
}do
 if not messages:FindFirstChild(name) then local v=Instance.new("StringValue");v.Name=name;v.Value=value;v.Parent=messages end
end
return {ChestSource=source:GetFullName()}
