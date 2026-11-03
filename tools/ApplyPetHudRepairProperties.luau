-- Scoped reproduction of the authored GUI delta from PetHudRepair_20261103.
-- Do not replace models or import older Source. Run only in the canonical Edit session.
assert(game.PlaceId == 126576845524886, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Edit only")
local hud = game:GetService("StarterGui"):WaitForChild("StrengthGui"):WaitForChild("HUD")
-- Keep the bag hidden until the runtime client has valid quantities and a battle area.
hud.RunInventoryIcon.Visible = false
hud.RunInventoryLabel.Visible = false
-- These are counters, not the separate left-menu Rebirth action.
for _, name in { "WinAmount", "RebirthAmount" } do
	local button = hud[name]:WaitForChild("Button")
	button.Active = false
	button.Interactable = false
	button.Selectable = false
	button.AutoButtonColor = false
end
