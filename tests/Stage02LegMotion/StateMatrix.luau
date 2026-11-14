-- Exact production Source; fake frame signals with real temporary Instances.
return function(source,config)
 local count=0
 local function check(ok,reason)count+=1;assert(ok,reason)end
 local function signal()
  local s={Connections={}}
  function s:Connect(fn)local c={Fn=fn,Connected=true};function c:Disconnect()self.Connected=false end;table.insert(self.Connections,c);return c end
  function s:Fire()for _,c in self.Connections do if c.Connected then c.Fn()end end end
  function s:Count()local n=0;for _,c in self.Connections do if c.Connected then n+=1 end end;return n end
  return s
 end
 local run={PreAnimation=signal(),PreSimulation=signal()}
 local settings=table.clone(config)
 local fakeGame={ReplicatedStorage={Config={Stage02LegMotionConfig="Config"}}}
 function fakeGame:GetService(name)assert(name=="RunService");return run end
 local fn=assert(loadstring(source))
 setfenv(fn,setmetatable({game=fakeGame,require=function(k)assert(k=="Config");return settings end},{__index=getfenv()}))
 local motion=fn()
 local function near(a,b)local aa={a:GetComponents()};local bb={b:GetComponents()};for i=1,12 do if math.abs(aa[i]-bb[i])>1e-5 then return false end end;return true end
 local enemy=Instance.new("Model");enemy:SetAttribute("WorldId",1);enemy:SetAttribute("StageNumber",2)
 local rig=Instance.new("Model");rig.Name=config.RigName;rig.Parent=enemy
 local fake=Instance.new("Part");fake.Name="FakeRootPart";fake.Parent=rig
 local root=Instance.new("Part");root.Name="RootPart";root.Parent=rig
 local weld=Instance.new("Weld");weld.Name="Stage02VisualRootWeld";weld.C0=CFrame.new(0,.412,0)*CFrame.Angles(0,.52,0);weld.Parent=root
 local originalWeld=weld.C0
 local bones={}
 for _,j in config.Joints do
  local b=fake
  for _,name in j.Path do local next=b:FindFirstChild(name);if not next then next=Instance.new("Bone");next.Name=name;next.Parent=b end;b=next end
  bones[j.Path[#j.Path]]=b
  local raw=j.Center*CFrame.new(.02,.01,-.03)*CFrame.Angles(.13,-.08,.05)
  check(near(motion.Amplify(j.Center,j.Center,1.5,j.Translate),j.Center),"Fixed center preserved")
  check(near(motion.Amplify(raw,j.Center,1,j.Translate),raw),"1.0 is original")
  local expected=j.Center.Position+(raw.Position-j.Center.Position)*1.5
  local result=motion.Amplify(raw,j.Center,1.5,j.Translate)
  check((result.Position-(j.Translate and expected or raw.Position)).Magnitude<1e-5,"Only selected cyclic translations scaled")
  local _,a=j.Center.Rotation:ToObjectSpace(raw.Rotation):ToAxisAngle()
  local _,bAngle=j.Center.Rotation:ToObjectSpace(result.Rotation):ToAxisAngle()
  check(math.abs(bAngle-a*1.5)<1e-5,"Local rotation delta 1.5x")
  b.Transform=raw
 end
 local torso=fake.UpTorso;torso.Transform=CFrame.new(.03,.01,0)*CFrame.Angles(0,.05,0)
 local head=Instance.new("Bone");head.Name="Head";head.Parent=torso;head.Transform=CFrame.Angles(.04,0,0)
 local torsoRaw,headRaw=torso.Transform,head.Transform
 local raw={};for n,b in bones do raw[n]=b.Transform end
 local track={Animation={AnimationId=config.WalkAnimationId},IsPlaying=true,WeightCurrent=1,Length=1.05}
 local remove,valid=motion.Mount(rig,track);check(remove~=nil and valid(),"Mount ready")
 run.PreSimulation:Fire()
 local once={};for n,b in bones do once[n]=b.Transform end
 for i=1,600 do run.PreAnimation:Fire();run.PreSimulation:Fire()end
 for n,b in bones do check(near(b.Transform,once[n]),"No accumulated pose: "..n)end
 check(near(weld.C0,originalWeld),"Float weld never touched")
 check(near(root.CFrame,CFrame.identity),"Root unchanged")
 check(near(torso.Transform,torsoRaw)and near(head.Transform,headRaw),"Non-leg poses unchanged")
 check(run.PreAnimation:Count()==1 and run.PreSimulation:Count()==1,"Only one correction connection pair")
 settings.Amplitude=1;run.PreAnimation:Fire();run.PreSimulation:Fire()
 for n,b in bones do check(near(b.Transform,raw[n]),"Live 1.0 restoration: "..n)end
 settings.Amplitude=1.5;track.WeightCurrent=.5;run.PreAnimation:Fire();run.PreSimulation:Fire()
 for n,b in bones do check(near(b.Transform,raw[n]),"Fade does not amplify mixed pose: "..n)end
 track.WeightCurrent=1
 local missing=bones["Arms.L.002"];missing.Parent=nil
 check(not valid(),"Missing mounted Bone invalidates mount")
 remove();remove()
 check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"Cleanup idempotently disconnects")
 check(motion.Mount(rig,track)==nil,"Partial rig waits")
 missing.Parent=fake;remove,valid=motion.Mount(rig,track)
 check(remove~=nil and valid(),"Bone arrival mounts again");remove()
 check(near(weld.C0,originalWeld),"Cleanup leaves floating weld alone")
 for _,case in {{2,2,config.RigName,config.WalkAnimationId},{1,1,config.RigName,config.WalkAnimationId},{1,2,"OtherRig",config.WalkAnimationId},{1,2,config.RigName,"OtherClip"}}do
  enemy:SetAttribute("WorldId",case[1]);enemy:SetAttribute("StageNumber",case[2]);rig.Name=case[3];track.Animation.AnimationId=case[4]
  check(motion.Mount(rig,track)==nil,"Wrong world/stage/rig/clip excluded")
 end
 check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"Exclusions create no connections")
 enemy:Destroy()
 return {Passed=true,Assertions=count,Kind="Simulated frames, real temporary Instances, exact Source"}
end
