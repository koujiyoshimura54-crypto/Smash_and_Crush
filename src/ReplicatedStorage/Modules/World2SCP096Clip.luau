-- Sample approved saved Bone poses in production; no asset upload/temporary IDs.
local Tween=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.Config.World2SCP096Config)
local M={}
local easing={Linear=Enum.EasingStyle.Linear,Cubic=Enum.EasingStyle.Cubic,
 Elastic=Enum.EasingStyle.Elastic,Bounce=Enum.EasingStyle.Bounce}
function M.Compile(model)
 local mesh=assert(model:FindFirstChild("Body.LP"),"096 body mesh missing")
 local bones,bindings={},{}
 for _,bone in mesh:GetDescendants() do if bone:IsA("Bone") then
  assert(not bones[bone.Name],"Duplicate body Bone name")
  bones[bone.Name]=bone
  table.insert(bindings,{Bone=bone,Root=bone.Name=="Hips" or not bone.Parent:IsA("Bone"),
   PositionBasis=mesh.CFrame.Rotation:Inverse()*bone.WorldCFrame.Rotation})
 end end
 assert(#bindings==Config.BoneCount,"Incomplete replicated096 body")
 local result={Model=model,Bindings=bindings,Clips={},Scale=model:GetScale(),LastPhase=nil,LastRevision=nil}
 local folder=assert(model:FindFirstChild(Config.Folder),"096 body clip folder missing")
 for name,entry in Config.Clips do
  local sequence=assert(folder:FindFirstChild(entry.Name),"Missing exact body clip: "..entry.Name)
  assert(sequence:IsA("KeyframeSequence"))
  local rows,duration={},0
  for _,frame in sequence:GetKeyframes() do
   duration=math.max(duration,frame.Time)
   for _,pose in frame:GetDescendants() do if pose:IsA("Pose") and pose.Weight>0 and bones[pose.Name] then
    local bone=bones[pose.Name]
    assert(pose.Parent.Name==bone.Parent.Name,"Body clip hierarchy mismatch: "..pose.Name)
    rows[pose.Name]=rows[pose.Name] or {}
    table.insert(rows[pose.Name],{Time=frame.Time,Value=pose.CFrame,Style=pose.EasingStyle.Name,Direction=pose.EasingDirection.Name})
   end end
  end
  assert(duration>0,"Empty body clip")
  for _,binding in bindings do
   local row=assert(rows[binding.Bone.Name],"Body clip channel missing")
   table.sort(row,function(a,b)return a.Time<b.Time end)
  end
  result.Clips[name]={Rows=rows,Duration=duration,Entry=entry}
 end
 return result
end
local function sample(rows,time)
 if time<=rows[1].Time then return rows[1].Value end
 if time>=rows[#rows].Time then return rows[#rows].Value end
 local a,b=rows[1],rows[#rows]
 for i=2,#rows do if rows[i].Time>=time then a,b=rows[i-1],rows[i];break end end
 local alpha=math.clamp((time-a.Time)/(b.Time-a.Time),0,1)
 if a.Style=="Constant" then alpha=0
 else alpha=Tween:GetValue(alpha,easing[a.Style] or Enum.EasingStyle.Linear,Enum.EasingDirection[a.Direction]) end
 return a.Value:Lerp(b.Value,alpha)
end
function M.Sample(r,name,time)
 local clip=assert(r.Clips[name],"Unknown body action")
 time=math.clamp(time,0,clip.Duration)
 for _,binding in r.Bindings do
  local value=sample(clip.Rows[binding.Bone.Name],time)
  local position=value.Position*r.Scale
  if binding.Root and Config.RemovePlanarRootMotion then
   local p=binding.PositionBasis:VectorToWorldSpace(position)
   position=binding.PositionBasis:VectorToObjectSpace(Vector3.new(0,p.Y,0))
  end
  if binding.Bone.Parent then binding.Bone.Transform=CFrame.new(position)*value.Rotation end
 end
end
function M.Update(r,phase,started,now,moving,revision)
 if phase=="Cancelled" or phase=="Failed" then M.Reset(r);return end
 local name=phase=="Waiting" and "GetUp_Panic" or phase
 local clip=r.Clips[name]
 if not clip then return end
 local elapsed=math.max(0,now-started)
 local time=elapsed*clip.Entry.Speed
 if phase=="Waiting" then time=0
 elseif clip.Entry.Looped then time%=clip.Duration end
 -- Freeze locomotion when actual travel stops; attacking/intro keep playing.
 if phase=="Running" then
  if r.LastPhase==phase and r.LastRevision==revision then
   time=((r.LastTime or 0)+(moving and math.max(0,now-(r.LastNow or now))*clip.Entry.Speed or 0))%clip.Duration
  elseif not moving then time=0 end
 end
 M.Sample(r,name,time)
 r.LastTime=time;r.LastPhase=phase;r.LastRevision=revision;r.LastNow=now
end
function M.Reset(r)
 for _,binding in r.Bindings do if binding.Bone.Parent then binding.Bone.Transform=CFrame.identity end end
 r.LastPhase=nil;r.LastRevision=nil;r.LastTime=nil
end
return M
