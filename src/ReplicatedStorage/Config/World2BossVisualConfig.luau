-- Explicit World2 boss allowlist. SourceModels are archival, never auto-enumerated.
local stages = {
 [1] = {SCP="SCP-096", Template="SCP096_BodyBones_Display", VisualScale=2.25, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9),
  -- Retain the previous096 attack/contact box; the wider skin does not enlarge reach.
  ColliderSize=Vector3.new(6.884978771209717,15.75,2.5559258460998537),ColliderOffset=Vector3.zero},
 [2] = {SCP="SCP-023", Template="SCP023_Display", VisualScale=3.6, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.85)},
 [3] = {SCP="SCP-035", Template="SCP035_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [4] = {SCP="SCP-058", Template="SCP058_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.75,.85,.7)},
 [5] = {SCP="SCP-049", Template="SCP049_Display", VisualScale=2.7, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [6] = {SCP="SCP-173", Template="SCP173_Display", VisualScale=1.75, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [7] = {SCP="SCP-939", Template="SCP939_Display", VisualScale=2.5, FacingYaw=0, BodyRatio=Vector3.new(.8,1,.85)},
 [8] = {SCP="SCP-106", Template="SCP106_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [9] = {SCP="SCP-682", Template="SCP682_Skinned_Display", VisualScale=.75, FacingYaw=0,
  -- Preserve the former Stage9 combat box; skin deformation never resizes it.
  ColliderSize=Vector3.new(10.912297821,9.407477379,21.394394493),
  ColliderOffset=Vector3.new(0,.003027201,-7.001801834)},
 [10] = {SCP="SCP-323", Template="SCP323_Display", VisualScale=1.8, FacingYaw=0, BodyRatio=Vector3.new(.8,.9,.85)},
}
for _,entry in stages do table.freeze(entry) end
return table.freeze({
 Stages=table.freeze(stages),
  -- Intrinsic FileMesh dimensions measured from the existing approved asset.
 -- Part.Size is not its rendered size; scaling its tiny carrier loses feet/tail bounds.
 FileMeshSizes=table.freeze({["rbxassetid://957757849"]=Vector3.new(68.23318481445312,50,206.74534606933594)}),
 RewardStatus="Configured",
})
