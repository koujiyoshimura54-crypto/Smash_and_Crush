-- Run in Studio Edit, on the current imported model. No game/asset code runs.
assert(not game:GetService("RunService"):IsRunning(), "Edit only")
local model = assert(workspace:FindFirstChild("SCP 096"))
local skin = assert(model:FindFirstChild("FBXImportGeneric"))
local mesh = assert(skin:FindFirstChild("Body.LP"))
local original = assert(model.AnimSaves:FindFirstChild("Walk"))
local bones, ordered, motors, parts, rest, children = {}, {}, {}, {}, {}, {}
for _,d in model:GetDescendants() do
 if d:IsA("BasePart") then parts[d.Name]=d;rest[d.Name]=d.CFrame end
 if d:IsA("Motor6D") and d.Part0 and d.Part1 then
  motors[d.Part1.Name]=d;children[d.Part0.Name]=children[d.Part0.Name] or {};table.insert(children[d.Part0.Name],d)
 end
end
local function visit(parent)
 for _,b in parent:GetChildren() do if b:IsA("Bone") then
  assert(not bones[b.Name], "Ambiguous Bone name");bones[b.Name]=b;table.insert(ordered,b);visit(b)
 end end
end
visit(mesh);assert(#ordered==73,"Unexpected skin")
-- Reconstruct bind space from serialized CFrames only. Editor preview poses
-- must never become the baseline of a later conversion.
local bind={}
for _,b in ordered do bind[b]=(bind[b.Parent] or mesh.CFrame)*b.CFrame end
local function basis(normal,direction)
 local y=direction.Unit;local x=(normal-y*normal:Dot(y)).Unit
 assert(x.X==x.X,"Degenerate anatomical basis")
 return CFrame.fromMatrix(Vector3.zero,x,y,x:Cross(y))
end
local chains={
 {"L.Thiegh","L.Calf","L.Foot","Left Leg","Left Foot","LeftFoot",true},
 {"R.Thiegh","R.Calf","R.Foot","Right Leg","Right Foot","RightFeet",true},
 {"L.Arm_U","L.Arm_L","L.Hand","Left Arm","Leftt Whrist","Left Hand",false},
 {"R.Arm_U","R.Arm_L","R.Hand","Right Arm","Right Whrist","Right Hand",false},
}
for _,c in chains do
 local a,b,d=bind[bones[c[1]]],bind[bones[c[2]]],bind[bones[c[3]]]
 local u,v=b.Position-a.Position,d.Position-b.Position
 local n=u:Cross(v).Unit
 c.localUpper=a.Rotation:Inverse()*basis(n,u)
 c.localLower=b.Rotation:Inverse()*basis(n,v)
 c.endRest=d.Rotation
 c.lowerRest=b.Rotation
 c.sourceEndRest=rest[c[6]].Rotation
 c.sourceLowerRest=rest[c[5]].Rotation
 local function jointPoint(name) local j=motors[name];return (rest[j.Part0.Name]*j.C0).Position end
 local su=jointPoint(c[5])-jointPoint(c[4]);local sv=jointPoint(c[6])-jointPoint(c[5])
 c.sourceNormal=rest[c[4]].Rotation:VectorToObjectSpace(su:Cross(sv).Unit)
 c.sourceLocalLower=c.sourceLowerRest:Inverse()*basis(su:Cross(sv),sv)
 if c[7] then
  local toe=bones[c[1]:sub(1,1)..".Toes"]
  c.localFoot=d.Rotation:Inverse()*basis(mesh.CFrame.RightVector,bind[toe].Position-d.Position)
 end
end
local function sourcePose(frame)
 local transforms={}
 local function scan(p) transforms[(p.Parent:IsA("Pose") and p.Parent.Name or "").."/"..p.Name]=p.CFrame
  for _,child in p:GetSubPoses() do scan(child) end
 end
 for _,p in frame:GetPoses() do scan(p) end
 local world={HumanoidRootPart=rest.HumanoidRootPart};local jointPos={}
 local function descend(name)
  for _,j in children[name] or {} do
   local t=transforms[name.."/"..j.Part1.Name] or CFrame.identity
   local origin=world[name]*j.C0*t;jointPos[j.Part1.Name]=origin.Position
   world[j.Part1.Name]=origin*j.C1:Inverse();descend(j.Part1.Name)
  end
 end
 descend("HumanoidRootPart");return world,jointPos
end
local clip=Instance.new("KeyframeSequence");clip.Name="Walk_BodyBones";clip.Loop=original.Loop;clip.Priority=original.Priority
clip:SetAttribute("SourceClip",original:GetFullName());clip:SetAttribute("Conversion","Anatomical limb frames; preserved bind CFrames; 2 second original Walk")
local frames=original:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
for _,frame in frames do
 local world,joints=sourcePose(frame);local desired={}
 local torsoDelta=world.Torso.Rotation*rest.Torso.Rotation:Inverse()
 desired.Hips=torsoDelta*bind[bones.Hips].Rotation
 desired.head=(world.Head.Rotation*rest.Head.Rotation:Inverse())*bind[bones.head].Rotation
 for _,c in chains do
  local u=joints[c[5]]-joints[c[4]];local v=joints[c[6]]-joints[c[5]]
  -- Transport the source's reference bend plane with its upper limb.
  -- Recomputing a cross product at each key flips 180 degrees at a straight
  -- knee. This basis remains continuous without changing the source swing.
  local n=world[c[4]].Rotation:VectorToWorldSpace(c.sourceNormal)
  desired[c[1]]=basis(n,u)*c.localUpper:Inverse()
  desired[c[2]]=basis(n,v)*c.localLower:Inverse()
  if c[7] then
   -- Use the authored source foot's forward/up orientation, not the bent
   -- imported skin's asymmetric ankle bind pose as an animated world pose.
   local foot=world[c[6]]
   desired[c[3]]=basis(foot.RightVector,foot.LookVector)*c.localFoot:Inverse()
  else
   -- Wrist motion is relative to its forearm. Convert that relative delta
   -- through the anatomical bases; never copy a world-space hand rotation.
   local relative=world[c[5]].Rotation:Inverse()*world[c[6]].Rotation
   local relativeRest=c.sourceLowerRest:Inverse()*c.sourceEndRest
   local change=relative*relativeRest:Inverse()
   local map=c.localLower*c.sourceLocalLower:Inverse()
   desired[c[3]]=desired[c[2]]*map*change*map:Inverse()*c.lowerRest:Inverse()*c.endRest
  end
 end
 local k=Instance.new("Keyframe");k.Name=frame.Name;k.Time=frame.Time;k.Parent=clip
 local root=Instance.new("Pose");root.Name=mesh.Name;root.CFrame=CFrame.identity;root.Parent=k
 local poses={};local targetWorld={}
 for _,b in ordered do
  local parentWorld=b.Parent:IsA("Bone") and targetWorld[b.Parent] or mesh.CFrame
  local base=parentWorld*b.CFrame
  local transform=desired[b.Name] and base.Rotation:Inverse()*desired[b.Name] or CFrame.identity
  local p=Instance.new("Pose");p.Name=b.Name;p.CFrame=transform;p.Weight=1
  p.EasingStyle=Enum.PoseEasingStyle.Linear;p.EasingDirection=Enum.PoseEasingDirection.InOut
  p.Parent=poses[b.Parent] or root;poses[b]=p;targetWorld[b]=base*transform
 end
end
-- Keep the source controller and all imported scripts untouched. The existing
-- nested skin model gets a separate editor rig, with no runtime helper Script.
local controller=skin:FindFirstChild("BoneWalkController")
if not controller then controller=Instance.new("AnimationController");controller.Name="BoneWalkController"
 Instance.new("Animator",controller);controller.Parent=skin end
local saves=game.ServerStorage:FindFirstChild("RBX_ANIMSAVES")
if not saves then saves=Instance.new("Folder");saves.Name="RBX_ANIMSAVES";saves.Parent=game.ServerStorage end
local slot=saves:FindFirstChild("SCP096_VisibleBody")
if not slot then slot=Instance.new("ObjectValue");slot.Name="SCP096_VisibleBody";slot.Value=skin;slot.Parent=saves end
assert(slot:IsA("ObjectValue") and slot.Value==skin,"Editor slot belongs to another rig")
local previous=slot:FindFirstChild(clip.Name)
if previous then assert(previous:GetAttribute("SourceClip")==original:GetFullName(),"Unrelated clip");previous:Destroy() end
clip.Parent=slot
local link=skin:FindFirstChild("AnimSaves")
if link then assert(link:IsA("ObjectValue") and link.Value==slot,"Different editor saves")
else link=Instance.new("ObjectValue");link.Name="AnimSaves";link.Value=slot;link.Parent=skin end
game:GetService("Selection"):Set({skin})
return {Clip=clip:GetFullName(),Rig=skin:GetFullName(),Frames=#frames,Bones=#ordered}
