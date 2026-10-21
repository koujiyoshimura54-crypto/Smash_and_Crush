-- Explicit World2 boss allowlist. SourceModels are archival, never auto-enumerated.
local stages = {
 [1] = {SCP="SCP-096", Template="SCP096_Display", VisualScale=2.25, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [2] = {SCP="SCP-023", Template="SCP023_Display", VisualScale=3.6, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.85)},
 [3] = {SCP="SCP-035", Template="SCP035_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [4] = {SCP="SCP-058", Template="SCP058_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.75,.85,.7)},
 [5] = {SCP="SCP-049", Template="SCP049_Display", VisualScale=2.7, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [6] = {SCP="SCP-173", Template="SCP173_Display", VisualScale=1.75, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [7] = {SCP="SCP-939", Template="SCP939_Display", VisualScale=2.5, FacingYaw=0, BodyRatio=Vector3.new(.8,1,.85)},
 [8] = {SCP="SCP-106", Template="SCP106_Display", VisualScale=3.0, FacingYaw=0, BodyRatio=Vector3.new(.9,1,.9)},
 [9] = {SCP="SCP-682", Template="SCP682_Display", VisualScale=1.4, FacingYaw=0, BodyRatio=Vector3.new(.85,1,.55), BodyOffset=Vector3.new(0,0,-.18)},
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
