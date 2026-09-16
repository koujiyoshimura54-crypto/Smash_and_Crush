-- Edit-time UI metadata only. Run once when restoring this source snapshot to the baseline map.
local count=0
for _,surface in ipairs(workspace.GeneratedMap.BattleCorridor:GetDescendants()) do
 if surface:IsA("SurfaceGui") and surface.Name=="StageSurface" and surface.Parent.Name=="Wall" then
  if surface:GetAttribute("HPGaugeBottomStuds")==nil then
   local bar=surface.Panel.HPBar
   local h=surface.Parent.Size.Y
   local pixels=surface.CanvasSize.Y
   surface:SetAttribute("HPGaugeBottomStuds",h*(1-bar.Position.Y.Scale-bar.Size.Y.Scale)-(bar.Position.Y.Offset+bar.Size.Y.Offset)*h/pixels)
   surface:SetAttribute("HPGaugeHeightStuds",h*bar.Size.Y.Scale+bar.Size.Y.Offset*h/pixels)
  end
  count+=1
 end
end
assert(count==40,"Expected World1's 40 enemy Wall UI surfaces")

