-- Edit-only creation from the current approved body and five current saved clips.
-- No outer transparent rig, AI, Animator or editor save reference is copied.
return function()
 assert(not game:GetService("RunService"):IsRunning(),"Edit only")
 local root=game.ServerStorage.EnemyTemplates.World2SCPDisplays
 assert(not root:FindFirstChild("SCP096_BodyBones_Display"),"New template already exists; do not overwrite")
 local original=assert(workspace:FindFirstChild("SCP 096"))
 local skin=assert(original:FindFirstChild("FBXImportGeneric"))
 local source=assert(skin:FindFirstChild("Body.LP"));assert(source:IsA("MeshPart"))
 local slot=assert(game.ServerStorage.RBX_ANIMSAVES:FindFirstChild("SCP096_VisibleBody"))
 local names={"GetUp_Panic_BodyBones","Panic_BodyBones","Running_BodyBones","AttackRunStart_BodyBones","AttackRun_BodyBones"}
 for _,name in names do assert(slot:FindFirstChild(name) and slot[name]:IsA("KeyframeSequence"),name) end
 local old=assert(root:FindFirstChild("SCP096_Display"))
 local oldCopy=old:Clone()
 oldCopy:PivotTo(CFrame.identity)
 local bounds=require(game.ServerScriptService.World.BossVisualPlacement).GetVisibleBounds
 local low,high=bounds(oldCopy)
 local oldHeight=high.Y-low.Y
 local entry=require(game.ReplicatedStorage.Config.World2BossVisualConfig).Stages[1]
 oldCopy:ScaleTo(old:GetScale()*entry.VisualScale)
 local oldLow,oldHigh=bounds(oldCopy)
 local oldSize=oldHigh-oldLow
 local collider=entry.ColliderSize or oldSize*entry.BodyRatio
 oldCopy:Destroy()
 local template=Instance.new("Model");template.Name="SCP096_BodyBones_Display"
 local mesh=source:Clone();mesh.Parent=template;template.PrimaryPart=mesh
 mesh.CFrame=CFrame.identity;mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false;mesh.Massless=true
 local bones=0
 for _,d in mesh:GetDescendants() do
  assert(not d:IsA("BaseScript"),"Unexpected executable beneath body mesh")
  if d:IsA("Bone") then d.Transform=CFrame.identity;bones+=1 end
 end
 assert(bones==73,"Unexpected current skin")
 template:ScaleTo(oldHeight/source.Size.Y)
 template:SetAttribute("SourceModel",skin:GetFullName())
 template:SetAttribute("SourceClipFolder",slot:GetFullName())
 template:SetAttribute("AuthoredClipScale",1)
 local folder=Instance.new("Folder");folder.Name="BodyClips";folder.Parent=template
 -- Attach each clip independently to bound insertion work.
 template.Parent=root
 for _,name in names do slot[name]:Clone().Parent=folder;task.wait() end
 return {Template=template:GetFullName(),TemplateScale=template:GetScale(),SpawnScale=entry.VisualScale,
  Height=oldHeight*entry.VisualScale,ColliderSize={collider.X,collider.Y,collider.Z},
  ColliderOffset={0,0,0},Source=source:GetFullName(),BoneCount=bones,ClipNames=names}
end
