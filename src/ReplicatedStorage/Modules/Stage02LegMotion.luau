-- Local leg poses only. Stage02AppearanceClient exclusively owns its float weld.
local Run=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Config.Stage02LegMotionConfig)
local M={}

function M.Amplify(raw,center,amount,translate)
 if amount==1 then return raw end
 local axis,angle=center.Rotation:ToObjectSpace(raw.Rotation):ToAxisAngle()
 local position=translate and center.Position+(raw.Position-center.Position)*amount or raw.Position
 return CFrame.new(position)*center.Rotation*CFrame.fromAxisAngle(axis,angle*amount)
end

local function findBone(fake,path)
 local bone=fake
 for _,name in path do bone=bone and bone:FindFirstChild(name)end
 return bone and bone:IsA("Bone")and bone or nil
end

function M.Mount(rig,walk)
 local enemy=rig.Parent
 if rig.Name~=Config.RigName or not enemy or enemy:GetAttribute("WorldId")~=1
  or enemy:GetAttribute("StageNumber")~=2 or not walk.Animation
  or walk.Animation.AnimationId~=Config.WalkAnimationId then return nil end
 local fake=rig:FindFirstChild("FakeRootPart")
 if not fake then return nil end
 local joints={};local scale=rig:GetScale()
 for _,entry in Config.Joints do
  local bone=findBone(fake,entry.Path)
  if not bone then return nil end -- Existing binding retries partial replication.
  table.insert(joints,{Bone=bone,Path=entry.Path,
   Center=CFrame.new(entry.Center.Position*scale)*entry.Center.Rotation,Translate=entry.Translate})
 end
 local disposed=false
 local function restore()
  for _,j in joints do if j.Raw and j.Bone.Parent then j.Bone.Transform=j.Raw end end
 end
 local function valid()
  if disposed or not rig.Parent or fake.Parent~=rig then return false end
  for _,j in joints do if findBone(fake,j.Path)~=j.Bone then return false end end
  return true
 end
 local before=Run.PreAnimation:Connect(function()
  -- Restore unmodified Animator input even when its evaluation is throttled.
  if not disposed then restore()end
 end)
 local after=Run.PreSimulation:Connect(function()
  if not valid()then return end
  local ready=walk.IsPlaying and walk.WeightCurrent>=0.999 and walk.Length>0
  for _,j in joints do
   local raw=j.Bone.Transform;j.Raw=raw
   if ready then j.Bone.Transform=M.Amplify(raw,j.Center,Config.Amplitude,j.Translate)end
  end
 end)
 local function remove()
  if disposed then return end;disposed=true
  before:Disconnect();after:Disconnect();restore()
 end
 return remove,valid
end
return M
