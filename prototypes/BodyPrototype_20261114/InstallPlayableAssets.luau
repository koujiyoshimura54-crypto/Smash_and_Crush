-- Edit command for the existing 7fe76dc asset set; never saves or publishes.
-- Import the four files below into this ServerStorage folder (ComparisonClient
-- is a LocalScript template), then apply the two current src controller changes.
-- LobbySpawnService, normal growth config and old reference models stay intact.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886)
assert(game.GameId==10765181857 and not game:GetService("RunService"):IsRunning())
local folder=assert(game.ServerStorage:FindFirstChild("BodyPrototype_20261114"))
for name,class in {PlayableBodyPrototype="ModuleScript",PlayableShapeConfig="ModuleScript",
 PlayableComparisonService="ModuleScript",ComparisonClient="LocalScript"}do
 local source=assert(folder:FindFirstChild(name),"Import "..name.." first")
 assert(source:IsA(class),name.." must be "..class)
end
assert(folder:FindFirstChild("PlayableSourceBody"),"Preserve/import the existing trial donor")
assert(folder:FindFirstChild("CurrentAvatarReference"),"Preserve the existing avatar reference")
assert(not game.StarterPlayer:FindFirstChild("StarterCharacter"),"Inspect existing StarterCharacter; do not replace it")
folder:SetAttribute("Enabled",true)
-- Historical Playable_LV* / ArchivedPreviews are retained, not rebuilt with
-- the current comparison settings. Runtime comparison creates no Edit models.
return {Enabled=true,Path=folder:GetFullName(),NextPlay="Use the Body comparison panel"}
