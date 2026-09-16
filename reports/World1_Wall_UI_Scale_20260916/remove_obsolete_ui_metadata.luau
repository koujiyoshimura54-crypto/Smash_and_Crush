-- UI-only cleanup accompanying the two client sources; do not resize any Part.
for _,gui in workspace.GeneratedMap.BattleCorridor:GetDescendants() do
 if gui:IsA("SurfaceGui") and gui.Name=="StageSurface" then
  gui:SetAttribute("HPGaugeBottomStuds",nil)
  gui:SetAttribute("HPGaugeHeightStuds",nil)
 end
end

