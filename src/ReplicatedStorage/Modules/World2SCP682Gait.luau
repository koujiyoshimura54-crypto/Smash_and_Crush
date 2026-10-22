-- Cosmetic skin deformation only. Four cached two-link legs, in mesh-local space.
-- Authored Bone.CFrames and mesh/skin data are never edited.
local M={}
local function rotate(a,b)
 a=a.Unit;b=b.Unit
 local axis=a:Cross(b);local n=axis.Magnitude
 if n<1e-7 then return CFrame.identity end
 return CFrame.fromAxisAngle(axis/n,math.atan2(n,math.clamp(a:Dot(b),-1,1)))
end
function M.Compile(model,settings)
 local mesh=assert(model:FindFirstChild("scp_crock_reference"),"682 skin not replicated")
 assert(mesh:IsA("MeshPart"),"682 requires its audited skinned mesh")
 local r={Skinned682=true,Settings=settings,Clock=0,Blend=0,Mesh=mesh,Bones={},Rest={},Pose={},Legs={}}
 local names={}
 for _,b in mesh:GetDescendants() do
  if b:IsA("Bone") then
   table.insert(r.Bones,b);names[b.Name]=b
   r.Rest[b]=mesh.CFrame:ToObjectSpace(b.WorldCFrame)
  end
 end
 assert(#r.Bones==32,"682 skeleton not replicated")
 for _,spec in {{"R","UpperArm","Forearm","Hand",0},{"L","UpperArm","Forearm","Hand",.5},
  {"R","Thigh","Calf","Foot",.5},{"L","Thigh","Calf","Foot",0}} do
  local prefix="Bip01_"..spec[1].."_"
  local h=assert(names[prefix..spec[2]]);local k=assert(names[prefix..spec[3]]);local a=assert(names[prefix..spec[4]])
  assert(k.Parent==h and a.Parent==k,"682 leg chain mismatch")
  local H,K,A=r.Rest[h].Position,r.Rest[k].Position,r.Rest[a].Position
  table.insert(r.Legs,{Hip=h,Knee=k,Ankle=a,H=H,K=K,A=A,L1=(K-H).Magnitude,L2=(A-K).Magnitude,Phase=spec[5]})
 end
 r.Scale=mesh.Size.Y/12.53523063659668
 r.Tail={names.BN_Tail_01,names.BN_Tail_02,names.BN_Tail_03}
 return r
end
local function put(r,b,pose)
 local parent=r.Pose[b.Parent] or r.Rest[b.Parent] or CFrame.identity
 b.Transform=b.CFrame:Inverse()*parent:Inverse()*pose
 r.Pose[b]=pose
end
local function legPose(r,leg,phase)
 local s=r.Settings;phase=(phase+leg.Phase)%1
 local forward,lift,roll
 if phase<s.Stance then
  forward=1-2*phase/s.Stance;lift=0;roll=0
 else
  local t=(phase-s.Stance)/(1-s.Stance)
  forward=-math.cos(t*math.pi);lift=math.sin(t*math.pi);roll=.10*math.sin(t*math.pi*2)
 end
 local target=leg.A+Vector3.new(0,lift*s.Lift*r.Scale,-forward*s.Stride*r.Scale)
 local delta=target-leg.H
 local d=math.clamp(delta.Magnitude,math.abs(leg.L1-leg.L2)+.001,leg.L1+leg.L2-.001)
 local direction=delta.Unit;target=leg.H+direction*d
 local along=(leg.L1^2-leg.L2^2+d*d)/(2*d)
 local bend=leg.K-leg.H;local normal=bend-direction*bend:Dot(direction)
 local knee=leg.H+direction*along+normal.Unit*math.sqrt(math.max(0,leg.L1^2-along^2))
 local upper=CFrame.new(leg.H)*rotate(leg.K-leg.H,knee-leg.H)*CFrame.new(-leg.H)*r.Rest[leg.Hip]
 local lower=CFrame.new(knee)*rotate(leg.A-leg.K,target-knee)*CFrame.new(-leg.K)*r.Rest[leg.Knee]
 put(r,leg.Hip,upper);put(r,leg.Knee,lower)
 -- Keep the planted foot's authored orientation, instead of rotating it into the floor.
 put(r,leg.Ankle,CFrame.new(target)*CFrame.Angles(roll,0,0)*r.Rest[leg.Ankle].Rotation)
end
function M.Update(r,dt,speed)
 local s=r.Settings;local moving=speed>.15
 r.Blend=math.clamp(r.Blend+(moving and 1 or -1)*dt/.16,0,1)
 if moving then r.Clock=(r.Clock+dt*math.clamp(speed/s.ReferenceSpeed,0,2)/s.Period)%1 end
 table.clear(r.Pose)
 for _,b in r.Bones do b.Transform=CFrame.identity end
 if r.Blend==0 then return end
 for _,leg in r.Legs do legPose(r,leg,r.Clock) end
 for index,b in r.Tail do
  local axis=r.Rest[b]:VectorToObjectSpace(Vector3.yAxis)
  b.Transform=CFrame.fromAxisAngle(axis,math.sin(r.Clock*math.pi*2-index*.45)*.025)
 end
 for _,b in r.Bones do b.Transform=CFrame.identity:Lerp(b.Transform,r.Blend) end
end
function M.Reset(r)
 for _,b in r.Bones do if b.Parent then b.Transform=CFrame.identity end end
 r.Blend=0;table.clear(r.Pose)
end
return M
