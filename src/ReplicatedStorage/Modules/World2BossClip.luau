-- Evaluate the real saved KeyframeSequence without Studio-only temporary IDs.
-- Also retarget only SCP-096's approved R15 Walk onto its existing six-part rig.
local Tween=game:GetService("TweenService")
local M={}
local aliases={Torso="LowerTorso",["Left Leg"]="LeftUpperLeg",["Right Leg"]="RightUpperLeg",
 ["Left Arm"]="LeftUpperArm",["Right Arm"]="RightUpperArm",Head="Head"}
function M.Compile(sequence,model,retarget,weight)
 local rows={}
 local duration=0
 for _,frame in sequence:GetKeyframes() do
  duration=math.max(duration,frame.Time)
  for _,pose in frame:GetDescendants() do
   if pose:IsA("Pose") and pose.Weight>0 then
    local parent=pose.Parent
    local key=(parent:IsA("Pose") and parent.Name or "").."/"..pose.Name
    rows[key]=rows[key] or {}
    table.insert(rows[key],{Time=frame.Time,Value=pose.CFrame,Style=pose.EasingStyle,Direction=pose.EasingDirection})
   end
  end
 end
 local bindings={}
 for _,joint in model:GetDescendants() do
  if not joint:IsA("Motor6D") or not joint.Part0 or not joint.Part1 then continue end
  local child=retarget and aliases[joint.Part1.Name] or joint.Part1.Name
  local parent=retarget and aliases[joint.Part0.Name] or joint.Part0.Name
  local samples=rows[(parent or "").."/"..(child or "")]
  if retarget and joint.Part1.Name=="Torso" then samples=rows["HumanoidRootPart/LowerTorso"] end
  if retarget and joint.Part1.Name=="Head" then samples=rows["UpperTorso/Head"] end
  if retarget and joint.Part1.Name:find("Arm") then samples=rows["UpperTorso/"..child] end
  if samples then
   table.sort(samples,function(a,b) return a.Time<b.Time end)
   local body=joint.Part1.Name=="Torso" or joint.Part1.Name=="Head"
   table.insert(bindings,{Joint=joint,Samples=samples,Weight=retarget and (weight or .5)*(body and .5 or 1) or 1})
  end
 end
 assert(duration>0 and #bindings>0,"Clip has no duration or compatible joints")
 return {Duration=duration,Bindings=bindings}
end
local styles={Linear=Enum.EasingStyle.Linear,Constant=Enum.EasingStyle.Linear,
 Cubic=Enum.EasingStyle.Cubic,Elastic=Enum.EasingStyle.Elastic,Bounce=Enum.EasingStyle.Bounce}
function M.Sample(clip,time)
 for _,binding in clip.Bindings do
  local samples=binding.Samples
  local a,b=samples[1],samples[#samples]
  for i=2,#samples do if samples[i].Time>=time then a,b=samples[i-1],samples[i];break end end
  local alpha=b.Time>a.Time and math.clamp((time-a.Time)/(b.Time-a.Time),0,1) or 0
  if a.Style==Enum.PoseEasingStyle.Constant then alpha=0
  else alpha=Tween:GetValue(alpha,styles[a.Style.Name] or Enum.EasingStyle.Linear,
   Enum.EasingDirection[a.Direction.Name] or Enum.EasingDirection.InOut) end
  if binding.Joint.Parent then binding.Joint.Transform=CFrame.identity:Lerp(a.Value:Lerp(b.Value,alpha),binding.Weight) end
 end
end
function M.Reset(clip)
 for _,binding in clip.Bindings do if binding.Joint.Parent then binding.Joint.Transform=CFrame.identity end end
end
return M
