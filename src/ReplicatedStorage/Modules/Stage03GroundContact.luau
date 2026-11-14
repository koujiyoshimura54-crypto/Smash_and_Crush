-- Stage3 R15 cosmetic grounding; leaves actor, weld, hitboxes and animation tracks alone.
local Run=game:GetService("RunService")
local M={Enabled=true}
local function bottom(cf,size)
 return cf.Y-(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
end
M.Bottom=bottom

function M.Mount(rig)
 local enemy=rig.Parent
 if rig.Name~="TungTungSahurRig" or not enemy or enemy:GetAttribute("WorldId")~=1
  or enemy:GetAttribute("StageNumber")~=3 then return nil end
 local root=rig:FindFirstChild("HumanoidRootPart")
 local torso=rig:FindFirstChild("LowerTorso")
 local joint=torso and torso:FindFirstChild("Root")
 if not root or not joint or not joint:IsA("Motor6D")or joint.Part0~=root or joint.Part1~=torso then return nil end
 local legs={}
 for _,side in {"Left","Right"}do
  local chain={};local parent=torso
  for _,entry in {{side.."UpperLeg",side.."Hip"},{side.."LowerLeg",side.."Knee"},{side.."Foot",side.."Ankle"}}do
   local part=rig:FindFirstChild(entry[1]);local motor=part and part:FindFirstChild(entry[2])
   if not motor or not motor:IsA("Motor6D")or motor.Part0~=parent or motor.Part1~=part then return nil end
   table.insert(chain,motor);parent=part
  end
  table.insert(legs,{Foot=parent,Chain=chain})
 end
 local original=joint.C0
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 local disposed=false
 local function valid()
  if disposed or not rig.Parent or root.Parent~=rig or joint.Parent~=torso then return false end
  for _,leg in legs do for _,motor in leg.Chain do
   if not motor.Parent or not motor.Part0 or not motor.Part1 or motor.Part1.Parent~=rig then return false end
  end end
  return true
 end
 local connection=Run.PreSimulation:Connect(function()
  if not valid()then return end
  local lift=0
  local map=workspace:FindFirstChild("GeneratedMap");local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage03")
  if M.Enabled and stage then
   -- Use actual walkable parts, not the hidden layout Floor or nearby scenery.
   local surfaces={};local walkable=stage:FindFirstChild("WalkableGeometry")
   if walkable then table.insert(surfaces,walkable)end
   local arena=stage:FindFirstChild("Stage3.5")
   if arena then for _,name in {"Floor","PathToRun"}do local v=arena:FindFirstChild(name);if v then table.insert(surfaces,v)end end end
   params.FilterDescendantsInstances=surfaces
   -- Predict this frame from Animator transforms; Part.CFrame still has last frame's pose.
   -- Always start at the unmodified C0, never the previous lift.
   local base=root.CFrame*original*joint.Transform*joint.C1:Inverse()
   local reach=math.max(4,root.Size.Y*2)
   for _,leg in legs do
    local cf=base
    for _,motor in leg.Chain do cf=cf*motor.C0*motor.Transform*motor.C1:Inverse()end
    local hit=workspace:Raycast(cf.Position+Vector3.new(0,reach,0),Vector3.new(0,-2*reach,0),params)
    if hit and hit.Normal.Y>.9 then lift=math.max(lift,hit.Position.Y-bottom(cf,leg.Foot.Size))end
   end
  end
  joint.C0=original+root.CFrame:VectorToObjectSpace(Vector3.new(0,lift,0))
 end)
 local function remove()
  if disposed then return end;disposed=true;connection:Disconnect()
  if joint.Parent then joint.C0=original end
 end
 return remove,valid
end
return M
