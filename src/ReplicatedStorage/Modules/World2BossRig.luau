-- Clone-only corrections, shared by live actors and the optional Studio preview.
local Config=require(game.ReplicatedStorage.Config.World2BossAnimationConfig)
local M={}
function M.Prepare(model,stage)
 local entry=Config.Stages[stage]
 if not entry or model:GetAttribute("World2RigVersion")==1 then return end
 if entry.Gait then require(script.Parent.World2BossGaitRig).Build(model,stage) end
 if entry.Rig=="SCP096" then
  local torso=model:FindFirstChild("Torso")
  for _,joint in torso:GetChildren() do
   if not joint:IsA("Motor6D") or not joint.Part0 or not joint.Part1 then continue end
   if joint.Name:find("Shoulder") and joint.Part1==torso then
    joint.Part0,joint.Part1=joint.Part1,joint.Part0
    joint.C0,joint.C1=joint.C1,joint.C0
   end
   if joint.Name:find("Hip") or joint.Name:find("Shoulder") or joint.Name=="RootJoint" or joint.Name=="Neck" then
    local limb=joint.Part1
    -- The imported long legs pivoted halfway down the thigh on R6's rotated axis.
    -- Use the existing limb's top as the joint, retaining its exact rest CFrame.
    local position
    if joint.Name:find("Hip") then position=(limb.CFrame*CFrame.new(0,limb.Size.Y/2,0)).Position
    elseif joint.Name:find("Shoulder") then
     local localPosition=torso.CFrame:PointToObjectSpace(limb.Position)
     position=torso.CFrame:PointToWorldSpace(Vector3.new(localPosition.X,torso.Size.Y/2,localPosition.Z))
    else position=(joint.Part0.CFrame*joint.C0).Position end
    local attachment=CFrame.new(position)*torso.CFrame.Rotation
    joint.C0=joint.Part0.CFrame:ToObjectSpace(attachment)
    joint.C1=limb.CFrame:ToObjectSpace(attachment)
   end
  end
 elseif entry.Rig=="SCP049" then
  -- Both upper legs and all fifteen R15 motors exist. The imported rig hid the
  -- thighs while the intact single coat mesh covered them in the static pose.
  for _,side in {"Left","Right"} do
   local thigh=model:FindFirstChild(side.."UpperLeg")
   local foot=model:FindFirstChild(side.."Foot")
   local boot=foot and foot:FindFirstChildWhichIsA("BasePart")
   if thigh and boot then thigh.Transparency=0;thigh.Color=Color3.new(0,0,0)
    -- The hidden avatar carrier had a pale skin texture, unrelated to the coat.
    if thigh:IsA("MeshPart") then
     thigh.TextureID=""
     -- The avatar carrier still rendered pale with Color/TextureID alone.
     -- Override only these two existing thighs, without changing their geometry.
     local surface=thigh:FindFirstChild("SCP049BlackThigh")
     if not surface then surface=Instance.new("SurfaceAppearance");surface.Name="SCP049BlackThigh";surface.Parent=thigh end
     surface.Color=Color3.new(0,0,0)
    end end
  end
 end
 local connected={}
 local roots={}
 for _,x in model:GetDescendants() do
  if x:IsA("BasePart") then connected[x]={}
   if x.Name=="HumanoidRootPart" or x.Name=="DisplayRoot" then roots[x]=true end
  end
 end
 for _,x in model:GetDescendants() do
  if (x:IsA("JointInstance") or x:IsA("WeldConstraint")) and connected[x.Part0] and connected[x.Part1] then
   table.insert(connected[x.Part0],x.Part1);table.insert(connected[x.Part1],x.Part0)
  end
 end
 local reached={}
 local function visit(p)
  if reached[p] then return end;reached[p]=true
  for _,other in connected[p] do visit(other) end
 end
 for p in roots do visit(p) end
 for part in connected do
  part.Anchored=roots[part]==true or not reached[part]
  part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
 end
 for _,x in model:GetDescendants() do
  if x:IsA("Humanoid") then
   x.EvaluateStateMachine=false;x.BreakJointsOnDeath=false;x.RequiresNeck=false
   if not x:FindFirstChildOfClass("Animator") then Instance.new("Animator",x) end
  end
 end
 model:SetAttribute("World2RigVersion",1)
end
function M.Intro(model,stage)
 local entry=Config.Stages[stage]
 local clip=model
 if not entry or not entry.IntroPath then return nil end
 for _,name in entry.IntroPath do clip=clip and clip:FindFirstChild(name) end
 return clip and clip:IsA("KeyframeSequence") and clip or nil
end
function M.Duration(sequence)
 local duration=0
 for _,frame in sequence:GetKeyframes() do duration=math.max(duration,frame.Time) end
 return duration
end
function M.LegLength(model,retarget)
 local a=model:FindFirstChild("LeftUpperLeg",true)
 local b=model:FindFirstChild("LeftLowerLeg",true)
 local foot=model:FindFirstChild("LeftFoot",true)
 if a and b then return a.Size.Y+b.Size.Y+(foot and foot.Size.Y or 0) end
 local leg=model:FindFirstChild("Left Leg",true)
 return leg and leg.Size.Y*(retarget and 1 or 2) or Config.ReferenceLegLength
end
return M
