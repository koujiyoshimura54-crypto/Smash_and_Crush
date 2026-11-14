-- Cosmetic, local-space correction of the existing Animator result. No new tracks.
local Run=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Config.Stage01MotionConfig)
local M={}

function M.Amplify(raw,center,amount,translate)
 if amount==1 then return raw end
 local axis,angle=center.Rotation:ToObjectSpace(raw.Rotation):ToAxisAngle()
 local position=translate and center.Position+(raw.Position-center.Position)*amount or raw.Position
 return CFrame.new(position)*center.Rotation*CFrame.fromAxisAngle(axis,angle*amount)
end

function M.Mount(rig,walk)
 local enemy=rig.Parent
 if not enemy or enemy:GetAttribute("WorldId")~=1 or enemy:GetAttribute("StageNumber")~=1
  or not walk.Animation or walk.Animation.AnimationId~=Config.WalkAnimationId then return nil end
 local fake=rig:FindFirstChild("FakeRootPart");local root=rig:FindFirstChild("RootPart")
 local weld=root and root:FindFirstChild("Stage01VisualRootWeld")
 if not fake or not weld or not weld.Part0 then return nil end
 local joints={};local feet={};local scale=rig:GetScale()
 for name,center in Config.Centers do
  local bone=fake:FindFirstChild(name,true)
  if not bone or not bone:IsA("Bone")then return nil end
  table.insert(joints,{Bone=bone,Center=CFrame.new(center.Position*scale)*center.Rotation,Translate=name=="Torso"})
 end
 for _,name in {"Leg.L.003","Leg.R.003"}do
  local bone=fake:FindFirstChild(name)
  if not bone or not bone:IsA("Bone")then return nil end
  table.insert(feet,bone)
  table.insert(joints,{Bone=bone,Foot=true})
 end
 local originalC0=weld.C0
 local fakeOffset=root.CFrame:ToObjectSpace(fake.CFrame)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 local disposed=false;local before,after
 local function restore()
  for _,j in joints do if j.Raw and j.Bone.Parent then j.Bone.Transform=j.Raw end end
 end
 before=Run.PreAnimation:Connect(function()
  -- Restore the last *raw* pose even when Animator evaluation is throttled.
  -- The next frame can never amplify our previous corrected output.
  if not disposed then restore()end
 end)
 after=Run.PreSimulation:Connect(function()
  if disposed or not rig.Parent or not root.Parent or not weld.Parent then return end
  local amount=Config.Amplitude
  local ready=walk.IsPlaying and walk.WeightCurrent>=0.999 and walk.Length>0
  for _,j in joints do
   local raw=j.Bone.Transform;j.Raw=raw
   if ready then
    if j.Foot then
     -- Independent foot-control bones: zero is their planted plane.
     -- Scale stride/lift only; never compound their descendant's transform.
     j.Bone.Transform=CFrame.new(raw.Position*amount)*raw.Rotation
    else j.Bone.Transform=M.Amplify(raw,j.Center,amount,j.Translate)end
   end
  end
  local lift=0
  if Config.GroundFit then
   local map=workspace:FindFirstChild("GeneratedMap")
   local corridor=map and map:FindFirstChild("BattleCorridor")
   local stage=corridor and corridor:FindFirstChild("Stage01")
   if stage then
    params.FilterDescendantsInstances={stage}
    -- Derive from the unmodified weld, never last frame's lifted world position.
    local basis=weld.Part0.CFrame*originalC0*weld.C1:Inverse()*fakeOffset
    for _,foot in feet do
     local planted=(basis*foot.CFrame).Position
     local hit=workspace:Raycast(planted+Vector3.new(0,2,0),Vector3.new(0,-4,0),params)
     if hit and hit.Normal.Y>.9 then lift=math.max(lift,hit.Position.Y-planted.Y)end
    end
   end
  end
  -- Move only the local visual weld. Server actor, collider, HP and AI stay put.
  weld.C0=originalC0+weld.Part0.CFrame:VectorToObjectSpace(Vector3.new(0,lift,0))
 end)
 return function()
  if disposed then return end;disposed=true
  before:Disconnect();after:Disconnect();restore()
  if weld.Parent then weld.C0=originalC0 end
 end
end
return M
