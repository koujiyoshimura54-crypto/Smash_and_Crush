-- Run in Studio Edit, on the current imported model. No game/asset code runs.
assert(not game:GetService("RunService"):IsRunning(), "Edit only")
local model = assert(workspace:FindFirstChild("SCP 096"))
local skin = assert(model:FindFirstChild("FBXImportGeneric"))
local mesh = assert(skin:FindFirstChild("Body.LP"))

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

-- The existing Walk is preserved byte-for-byte. This converter adds missing
-- clips only; re-running it never destroys or overwrites user-edited saves.
local slot=assert(game.ServerStorage.RBX_ANIMSAVES:FindFirstChild("SCP096_VisibleBody"))
assert(slot:IsA("ObjectValue") and slot.Value==skin,"Wrong editor rig")
assert(skin.AnimSaves.Value==slot,"Wrong editor save link")
assert(slot:FindFirstChild("Walk_BodyBones"),"Restore the recorded Walk separately if absent")
local channelFor={Hips="Torso",head="Head",["Face.Jaw"]="Jaw"}
for _,c in chains do channelFor[c[1]]=c[4];channelFor[c[2]]=c[5];channelFor[c[3]]=c[6] end
local originals={}
for _,d in model.AnimSaves:GetDescendants() do
 if d:IsA("KeyframeSequence") then table.insert(originals,d) end
end
table.sort(originals,function(a,b)return a:GetFullName()<b:GetFullName()end)
local created,kept=0,0
for _,original in originals do
 local outputName=(original.Name=="Test" and "ExportAnim_Test" or original.Name).."_BodyBones"
 local existing=slot:FindFirstChild(outputName)
 if existing then
  assert(existing:IsA("KeyframeSequence"),"Save name collision")
  assert(existing:GetAttribute("SourceClip")==original:GetFullName(),"Unrelated existing clip")
  kept+=1;print("SCP096_CLIP_KEPT "..existing:GetFullName())
  continue
 end
 local frames=original:GetKeyframes();table.sort(frames,function(a,b)return a.Time<b.Time end)
 local tracks={}
 for _,frame in frames do
  local seen={}
  local function scan(p)
   -- Legacy saves sometimes put a partial limb at the top of a keyframe.
   -- Names are unique in the carrier; resolve against its actual Motor6Ds.
   assert(not seen[p.Name],"Duplicate source pose in one keyframe")
   seen[p.Name]=true
   if p.Name=="LowerTorso" then
    assert(p.Weight==0 and p.CFrame==CFrame.identity,"Nontrivial missing LowerTorso requires review")
   elseif motors[p.Name] and p.Weight>0 then
    tracks[p.Name]=tracks[p.Name] or {}
    table.insert(tracks[p.Name],{Time=frame.Time,Pose=p})
   elseif motors[p.Name] then
    -- Weight-zero identity containers only preserve child hierarchy; they
    -- are not authored keys and must not reset a sparse parent channel.
    assert(p.Weight==0 and p.CFrame==CFrame.identity,"Nontrivial zero-weight pose needs review")
   else
    assert(p.Name=="HumanoidRootPart" and p.Weight==0,"Unmapped active source pose: "..p.Name)
   end
   for _,child in p:GetSubPoses() do scan(child) end
  end
  for _,p in frame:GetPoses() do scan(p) end
 end
 local function sample(name,time)
  local track=tracks[name]
  if not track or #track==0 then return CFrame.identity,nil end
  local a,b=track[1],track[#track]
  for i,key in track do
   if key.Time<=time then a=key end
   if key.Time>=time then b=key;break end
  end
  if time<=track[1].Time then a=track[1];b=a end
  if time>=track[#track].Time then a=track[#track];b=a end
  local alpha=(b.Time>a.Time) and math.clamp((time-a.Time)/(b.Time-a.Time),0,1) or 0
  local p=a.Pose
  assert(p.EasingStyle==Enum.PoseEasingStyle.Linear or p.EasingStyle==Enum.PoseEasingStyle.Constant,"Unsupported source easing")
  if p.EasingStyle==Enum.PoseEasingStyle.Constant then alpha=0 end
  local ac=p.Weight==0 and CFrame.identity or p.CFrame
  local bc=b.Pose.Weight==0 and CFrame.identity or b.Pose.CFrame
  return ac:Lerp(bc,alpha),p
 end
 local function sourcePose(time)
  local world={HumanoidRootPart=rest.HumanoidRootPart};local joints={};local metadata={}
  local function descend(name)
   for _,j in children[name] or {} do
    local t,p=sample(j.Part1.Name,time);metadata[j.Part1.Name]=p
    local origin=world[name]*j.C0*t;joints[j.Part1.Name]=origin.Position
    world[j.Part1.Name]=origin*j.C1:Inverse();descend(j.Part1.Name)
   end
  end
  descend("HumanoidRootPart");return world,joints,metadata
 end
 local clip=Instance.new("KeyframeSequence");clip.Name=outputName;clip.Loop=original.Loop;clip.Priority=original.Priority
 clip:SetAttribute("SourceClip",original:GetFullName())
 clip:SetAttribute("Conversion","Anatomical limb frames; sparse active source channels interpolated; pelvis displacement and jaw retained; v2")
 for _,frame in frames do
  local world,joints,metadata=sourcePose(frame.Time);local desired={}
  local torsoDelta=world.Torso*rest.Torso:Inverse()
  desired.Hips=torsoDelta.Rotation*bind[bones.Hips].Rotation
  local hipPosition=torsoDelta:PointToWorldSpace(bind[bones.Hips].Position)
  desired.head=(world.Head.Rotation*rest.Head.Rotation:Inverse())*bind[bones.head].Rotation
  for _,c in chains do
   local u=joints[c[5]]-joints[c[4]];local v=joints[c[6]]-joints[c[5]]
   local n=world[c[4]].Rotation:VectorToWorldSpace(c.sourceNormal)
   desired[c[1]]=basis(n,u)*c.localUpper:Inverse()
   desired[c[2]]=basis(n,v)*c.localLower:Inverse()
   if c[7] then
    local foot=world[c[6]]
    desired[c[3]]=basis(foot.RightVector,foot.LookVector)*c.localFoot:Inverse()
   else
    local relative=world[c[5]].Rotation:Inverse()*world[c[6]].Rotation
    local relativeRest=c.sourceLowerRest:Inverse()*c.sourceEndRest
    local change=relative*relativeRest:Inverse()
    local map=c.localLower*c.sourceLocalLower:Inverse()
    desired[c[3]]=desired[c[2]]*map*change*map:Inverse()*c.lowerRest:Inverse()*c.endRest
   end
  end
  if tracks.Jaw then
   local relative=world.Head.Rotation:Inverse()*world.Jaw.Rotation
   local relativeRest=rest.Head.Rotation:Inverse()*rest.Jaw.Rotation
   local map=bind[bones.head].Rotation:Inverse()*rest.Head.Rotation
   desired["Face.Jaw"]=desired.head*map*(relative*relativeRest:Inverse())*map:Inverse()*bind[bones.head].Rotation:Inverse()*bind[bones["Face.Jaw"]].Rotation
  end
  local k=Instance.new("Keyframe");k.Name=frame.Name;k.Time=frame.Time;k.Parent=clip
  for _,marker in frame:GetMarkers() do marker:Clone().Parent=k end
  local root=Instance.new("Pose");root.Name=mesh.Name;root.CFrame=CFrame.identity;root.Parent=k
  local poses,targetWorld={},{}
  for _,b in ordered do
   local parentWorld=b.Parent:IsA("Bone") and targetWorld[b.Parent] or mesh.CFrame
   local base=parentWorld*b.CFrame
   local transform=desired[b.Name] and base.Rotation:Inverse()*desired[b.Name] or CFrame.identity
   if b.Name=="Hips" then transform=CFrame.new(base:PointToObjectSpace(hipPosition))*transform end
   local p=Instance.new("Pose");p.Name=b.Name;p.CFrame=transform;p.Weight=1
   local m=metadata[channelFor[b.Name]]
   p.EasingStyle=m and m.EasingStyle or Enum.PoseEasingStyle.Linear
   p.EasingDirection=m and m.EasingDirection or Enum.PoseEasingDirection.Out
   p.Parent=poses[b.Parent] or root;poses[b]=p;targetWorld[b]=base*transform
  end
 end
 clip.Parent=slot;created+=1
 print("SCP096_CLIP_CREATED "..clip:GetFullName().." frames="..#frames.." length="..frames[#frames].Time)
end
game:GetService("Selection"):Set({skin})
print("SCP096_ALL_BUILD_DONE created="..created.." kept="..kept)
