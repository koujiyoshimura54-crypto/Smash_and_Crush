-- Build only the approved anatomical joints; preserve every authored rest CFrame.
-- Also used to prepare the saved templates. Safe on already prepared clones.
local M={}
local function motor(root,name,a,b,position)
 local joint=Instance.new("Motor6D");joint.Name=name
 local anchor=CFrame.new(position)*root.CFrame.Rotation
 joint.C0=a.CFrame:ToObjectSpace(anchor);joint.C1=b.CFrame:ToObjectSpace(anchor)
 joint.Part0=a;joint.Part1=b;joint.Parent=root
 return joint
end
local function weld(root,a,b)
 local w=Instance.new("WeldConstraint");w.Name="GaitFixed";w.Part0=a;w.Part1=b;w.Parent=root
end
local function endpoints(part)
 local offset=part.CFrame.RightVector*part.Size.X/2
 return part.Position-offset,part.Position+offset
end
function M.Build(model,stage)
 if model:GetAttribute("GaitRigVersion")==1 then return end
 if stage==2 then
  local torso=assert(model:FindFirstChild("Torso"))
  for _,j in torso:GetChildren() do
   if j:IsA("Motor6D") and (j.Name:find("Hip") or j.Name:find("Shoulder")) then
    local limb=assert(j.Part1)
    local anchor=CFrame.new(limb.Position+torso.CFrame.UpVector*limb.Size.Y/2)*torso.CFrame.Rotation
    j.C0=j.Part0.CFrame:ToObjectSpace(anchor);j.C1=limb.CFrame:ToObjectSpace(anchor)
   end
  end
 elseif stage==4 then
  local body=assert(model:FindFirstChild("Body"));local core=assert(body:FindFirstChild("Main"))
  local root=assert(model:FindFirstChild("HumanoidRootPart",true))
  local scale=core.Size.Y/.8450351
  local lower,upper,parts={},{},{}
  for _,p in body:GetChildren() do
   if not p:IsA("BasePart") then continue end
   table.insert(parts,p)
   if p.Size.Y<.25*scale and p.Size.Z<.25*scale then
    if p.Size.X>1.95*scale and p.Size.X<2.05*scale then table.insert(lower,p)
    elseif p.Size.X>.9*scale and p.Size.X<1.9*scale then table.insert(upper,p) end
   end
  end
  assert(#lower==4,"SCP058: expected four existing lower leg rods")
  local moving,used,names={},{},{}
  for _,leg in lower do
   local a,b=endpoints(leg);local knee=a.Y>b.Y and a or b
   local best,tip,distance=nil,nil,math.huge
   for _,candidate in upper do
    if used[candidate] then continue end
    local c,d=endpoints(candidate)
    for _,point in {c,d} do
     local delta=(point-knee).Magnitude
     if delta<distance then best,tip,distance=candidate,point,delta end
    end
   end
   assert(best and distance<.25*scale,"SCP058: leg pairing differs from audited geometry")
   used[best]=true;moving[best]=true;moving[leg]=true
   local c,d=endpoints(best);local hip=(c-tip).Magnitude<(d-tip).Magnitude and d or c
   local localKnee=root.CFrame:PointToObjectSpace(knee)
   local name=(localKnee.Z<0 and "Front" or "Rear")..(localKnee.X<0 and "Left" or "Right")
   assert(not names[name],"SCP058: ambiguous limb quadrant");names[name]=true
   motor(root,"Gait_"..name.."Hip",core,best,hip)
   motor(root,"Gait_"..name.."Knee",best,leg,(knee+tip)/2)
  end
  local fixed={}
  for _,j in model:GetDescendants() do
   if not (j:IsA("JointInstance") or j:IsA("WeldConstraint")) or j:IsA("Motor6D") then continue end
   -- Purchased ManualWelds otherwise pin the new anatomical joints in place.
   if moving[j.Part0] or moving[j.Part1] or (j.Part1==core and not j.Part0:IsDescendantOf(body)) then j:Destroy()
   elseif j.Part0==core then fixed[j.Part1]=true end
  end
  motor(root,"GaitBody",root,core,core.Position)
  for _,p in parts do if p~=core and not moving[p] and not fixed[p] then weld(root,core,p) end end
 elseif stage==6 then
  local root=assert(model:FindFirstChild("DisplayRoot"))
  local core,volume=nil,0
  local parts={}
  for _,p in model:GetChildren() do
   if p:IsA("BasePart") and p~=root then
    table.insert(parts,p)
    local v=p.Size.X*p.Size.Y*p.Size.Z
    if v>volume then core,volume=p,v end
   end
  end
  assert(core,"SCP173: torso missing")
  local groups={LeftArm={},RightArm={},LeftLeg={},RightLeg={}}
  local groupOf={}
  for _,p in parts do
   local v=core.CFrame:PointToObjectSpace(p.Position)
   local side=v.X<0 and "Left" or "Right"
   local name
   if v.Y< -core.Size.Y/2+.03*core.Size.Y then name=side.."Leg"
   elseif math.abs(v.X)>core.Size.X*.55 and v.Y<core.Size.Y*.55 then name=side.."Arm" end
   if name then table.insert(groups[name],p);groupOf[p]=name end
  end
  local anchors={}
  for name,group in groups do
   assert(#group>=5,"SCP173: incomplete anatomical group "..name)
   table.sort(group,function(a,b)return a.Size.X*a.Size.Y*a.Size.Z>b.Size.X*b.Size.Y*b.Size.Z end)
   anchors[name]=group[1]
  end
  -- Replace only cross-group root welds; decorations remain welded within their group.
  for _,w in model:GetDescendants() do
   if not w:IsA("WeldConstraint") then continue end
   assert(w.Part0==root,"SCP173: unexpected authored weld")
   local p=w.Part1;local anchor=anchors[groupOf[p]] or core
   if p==anchor then w:Destroy() else w.Part0=anchor end
  end
  motor(root,"GaitBody",root,core,core.Position)
  for name,anchor in anchors do
   local position
   if name:find("Leg") then
    position=anchor.Position+core.CFrame.UpVector*anchor.Size.Y/2
   else
    local v=core.CFrame:PointToObjectSpace(anchor.Position)
    position=core.CFrame:PointToWorldSpace(Vector3.new(v.X<0 and -core.Size.X/2 or core.Size.X/2,core.Size.Y*.32,0))
   end
   motor(root,"Gait_"..name,core,anchor,position)
  end
 elseif stage~=7 then return end
 model:SetAttribute("GaitRigVersion",1)
end
return M
