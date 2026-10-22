-- Shared production/Preview gait. No asset loading, Studio APIs or combat changes.
local Clip=require(script.Parent.World2BossClip)
local Config=require(game.ReplicatedStorage.Config.World2BossAnimationConfig)
local M={}
local function rotate(a,b)
 a=a.Unit;b=b.Unit
 local axis=a:Cross(b);local length=axis.Magnitude
 if length<1e-7 then return CFrame.identity end
 return CFrame.fromAxisAngle(axis/length,math.atan2(length,math.clamp(a:Dot(b),-1,1)))
end
local function corners(part)
 local out={}
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
  table.insert(out,part.Size*Vector3.new(x,y,z)/2)
 end end end
 return out
end
function M.Compile(model,stage)
 local entry=assert(Config.Stages[stage]);local settings=assert(entry.Gait)
 local root=assert(model:FindFirstChild("HumanoidRootPart",true) or model:FindFirstChild("DisplayRoot"))
 local result={Root=root,Settings=settings,Stage=stage,Clock=0,Blend=0,Edges={},Joints={},ByName={},Feet={},Rest={},Pose={}}
 local children={}
 for _,x in model:GetDescendants() do
  if x:IsA("BasePart") then result.Rest[x]=root.CFrame:ToObjectSpace(x.CFrame)
  elseif (x:IsA("JointInstance") or x:IsA("WeldConstraint")) and x.Part0 and x.Part1 then
   local row={Parent=x.Part0,Child=x.Part1,Joint=x:IsA("Motor6D") and x or nil}
   row.Fixed=x.Part0.CFrame:ToObjectSpace(x.Part1.CFrame)
   children[x.Part0]=children[x.Part0] or {};table.insert(children[x.Part0],row)
   if row.Joint then
    table.insert(result.Joints,x);result.ByName[x.Name]=x
    if x.Part0==root and (x.Name=="GaitBody" or x.Part1.Name=="Torso") then result.Body=x end
   end
  end
 end
 assert(#result.Joints>=entry.MinMotors and result.Body,"Gait joints not replicated yet")
 local visited={}
 local function visit(p)
  visited[p]=true
  for _,row in children[p] or {} do
   if not visited[row.Child] then table.insert(result.Edges,row);visit(row.Child) end
  end
 end
 visit(root)
 local function addFoot(part)
  assert(visited[part],"Visible limb is disconnected")
  table.insert(result.Feet,{Part=part,Points=corners(part)})
 end
 if stage==2 then
  result.Limbs={}
  for name,phase in { ["Left Shoulder"]=0,["Right Shoulder"]=.5,["Left Hip"]=.5,["Right Hip"]=0 } do
   local j=assert(result.ByName[name]);table.insert(result.Limbs,{Joint=j,Phase=phase})
   addFoot(j.Part1)
  end
 elseif stage==6 then
  result.Limbs={}
  for name,phase in {LeftLeg=0,RightLeg=.5,LeftArm=.5,RightArm=0} do
   local j=assert(result.ByName["Gait_"..name])
   table.insert(result.Limbs,{Joint=j,Phase=phase,Arm=name:find("Arm")~=nil})
   if name:find("Leg") then
    addFoot(j.Part1)
    for _,row in children[j.Part1] or {} do addFoot(row.Child) end
   end
  end
 elseif stage==4 then
  result.Legs={}
  for name,phase in {FrontLeft=0,RearRight=0,FrontRight=.5,RearLeft=.5} do
   local hip=assert(result.ByName["Gait_"..name.."Hip"])
   local knee=assert(result.ByName["Gait_"..name.."Knee"])
   local h=(result.Rest[hip.Part0]*hip.C0).Position
   local k=(result.Rest[knee.Part0]*knee.C0).Position
   local part=knee.Part1;local a=result.Rest[part]:PointToWorldSpace(Vector3.new(-part.Size.X/2,0,0))
   local b=result.Rest[part]:PointToWorldSpace(Vector3.new(part.Size.X/2,0,0))
   local foot=(a-k).Magnitude>(b-k).Magnitude and a or b
   table.insert(result.Legs,{Hip=hip,Knee=knee,H=h,K=k,Foot=foot,L1=(k-h).Magnitude,L2=(foot-k).Magnitude,Phase=phase})
   addFoot(part)
  end
 elseif stage==7 then
  local sequence=model;for _,name in settings.ClipPath do sequence=assert(sequence:FindFirstChild(name)) end
  result.Clip=Clip.Compile(sequence,model)
  for _,name in {"Left Arm","Right Arm","Left Leg","Right Leg"} do addFoot(assert(model:FindFirstChild(name))) end
 end
 result.Scale=model:GetScale()
 result.RestBottom=math.huge
 for _,foot in result.Feet do for _,point in foot.Points do
  result.RestBottom=math.min(result.RestBottom,result.Rest[foot.Part]:PointToWorldSpace(point).Y)
 end end
 return result
end
local function footCycle(phase,stance)
 phase%=1
 if phase<stance then return 1-2*phase/stance,0 end
 local t=(phase-stance)/(1-stance)
 return -math.cos(t*math.pi),math.sin(t*math.pi)
end
local function solveLeg(r,leg,phase)
 local s=r.Settings;local forward,lift=footCycle(phase+leg.Phase,s.Stance)
 local target=leg.Foot+Vector3.new(0,lift*s.Lift*r.Scale,-forward*s.Stride*r.Scale)
 local delta=target-leg.H;local d=math.clamp(delta.Magnitude,math.abs(leg.L1-leg.L2)+.001,leg.L1+leg.L2-.001)
 local direction=delta.Unit;target=leg.H+direction*d
 local along=(leg.L1*leg.L1-leg.L2*leg.L2+d*d)/(2*d)
 local bend=leg.K-leg.H;local normal=bend-direction*bend:Dot(direction)
 if normal.Magnitude<1e-5 then normal=Vector3.xAxis-direction*direction.X end
 local knee=leg.H+direction*along+normal.Unit*math.sqrt(math.max(0,leg.L1*leg.L1-along*along))
 local upper=CFrame.new(leg.H)*rotate(leg.K-leg.H,knee-leg.H)*CFrame.new(-leg.H)*r.Rest[leg.Hip.Part1]
 local lower=CFrame.new(knee)*rotate(leg.Foot-leg.K,target-knee)*CFrame.new(-leg.K)*r.Rest[leg.Knee.Part1]
 leg.Hip.Transform=leg.Hip.C0:Inverse()*r.Rest[leg.Hip.Part0]:Inverse()*upper*leg.Hip.C1
 leg.Knee.Transform=leg.Knee.C0:Inverse()*upper:Inverse()*lower*leg.Knee.C1
end
local function ground(r)
 local pose=r.Pose;pose[r.Root]=CFrame.identity
 for _,row in r.Edges do
  local j=row.Joint
  pose[row.Child]=pose[row.Parent]*(j and j.C0*j.Transform*j.C1:Inverse() or row.Fixed)
 end
 local bottom=math.huge
 for _,foot in r.Feet do for _,point in foot.Points do bottom=math.min(bottom,pose[foot.Part]:PointToWorldSpace(point).Y) end end
 local offset=math.clamp(r.RestBottom-bottom,-r.Settings.GroundLimit*r.Scale,r.Settings.GroundLimit*r.Scale)
 local body=r.Body
 local up=body.C0:VectorToObjectSpace(Vector3.new(0,offset,0))
 body.Transform=CFrame.new(up)*body.Transform
 r.GroundCorrection=offset
end
function M.Update(r,dt,speed)
 local s=r.Settings;local moving=speed>Config.MoveThreshold
 r.Blend=math.clamp(r.Blend+(moving and 1 or -1)*dt/Config.FadeTime,0,1)
 if moving then r.Clock=(r.Clock+dt*math.clamp(speed/s.ReferenceSpeed,0,2)/s.Period)%1 end
 for _,j in r.Joints do j.Transform=CFrame.identity end
 if r.Blend==0 then return end
 if r.Clip then
  Clip.Sample(r.Clip,r.Clock*r.Clip.Duration)
  for _,binding in r.Clip.Bindings do
   local j=binding.Joint;local axis,angle=j.Transform:ToAxisAngle()
   j.Transform=CFrame.new(j.Transform.Position)*CFrame.fromAxisAngle(axis,angle*s.Amplitude)
  end
 elseif r.Legs then
  for _,leg in r.Legs do solveLeg(r,leg,r.Clock) end
 else
  for _,limb in r.Limbs do
   local forward=footCycle(r.Clock+limb.Phase,s.Stance)
   local amplitude=limb.Arm and s.ArmAmplitude or s.Amplitude
   limb.Joint.Transform=CFrame.Angles(forward*amplitude,0,0)
  end
 end
 ground(r)
 for _,j in r.Joints do j.Transform=CFrame.identity:Lerp(j.Transform,r.Blend) end
end
function M.Reset(r)
 for _,j in r.Joints do if j.Parent then j.Transform=CFrame.identity end end
 r.Blend=0
end
return M
