-- Run in Studio Edit with the exact module Source and Config; fake frame signals only.
return function(source,config)
 local checks=0
 local function check(ok,why) checks+=1;assert(ok,why)end
 local function signal()
  local s={Connections={}}
  function s:Connect(fn)local c={Fn=fn,Connected=true};function c:Disconnect()self.Connected=false end;table.insert(self.Connections,c);return c end
  function s:Fire()for _,c in self.Connections do if c.Connected then c.Fn()end end end
  function s:Count()local n=0;for _,c in self.Connections do if c.Connected then n+=1 end end;return n end
  return s
 end
 local run={PreAnimation=signal(),PreSimulation=signal()}
 local actual=game
 local fakeGame={ReplicatedStorage={Config={Stage01MotionConfig='Config'}}}
 function fakeGame:GetService(name)return name=='RunService'and run or actual:GetService(name)end
 local settings=table.clone(config);settings.GroundFit=false
 local fn=assert(loadstring(source));setfenv(fn,setmetatable({game=fakeGame,require=function(k)assert(k=='Config');return settings end},{__index=getfenv()}))
 local motion=fn()
 local enemy=Instance.new('Model');enemy:SetAttribute('WorldId',1);enemy:SetAttribute('StageNumber',1)
 local actor=Instance.new('Part');actor.Name='HumanoidRootPart';actor.Parent=enemy
 local rig=Instance.new('Model');rig.Name='BallerinaCappuccinaRig';rig.Parent=enemy
 local root=Instance.new('Part');root.Name='RootPart';root.Parent=rig
 local fake=Instance.new('Part');fake.Name='FakeRootPart';fake.Parent=rig
 local weld=Instance.new('Weld');weld.Name='Stage01VisualRootWeld';weld.Part0=actor;weld.Part1=root;weld.C0=CFrame.new(0,2,0);weld.Parent=root
 local bones={}
 for name in config.Centers do local b=Instance.new('Bone');b.Name=name;b.Parent=fake;bones[name]=b end
 for _,name in {'Leg.L.003','Leg.R.003'}do local b=Instance.new('Bone');b.Name=name;b.Parent=fake;bones[name]=b end
 local track={Animation={AnimationId=config.WalkAnimationId},IsPlaying=true,WeightCurrent=1,Length=1.15}
 local function near(a,b)local d=a:ToObjectSpace(b);local _,angle=d:ToAxisAngle();return d.Position.Magnitude<1e-5 and math.abs(angle)<.001 end
 for _,amount in {1,2}do for _,center in config.Centers do
  local raw=center*CFrame.Angles(.13,-.08,.05)
  check(near(motion.Amplify(center,center,amount,true),center),'Fixed center unchanged')
  if amount==1 then check(near(motion.Amplify(raw,center,1,true),raw),'1.0 restores raw pose')
  else local _,a=center.Rotation:ToObjectSpace(raw.Rotation):ToAxisAngle();local _,b=center.Rotation:ToObjectSpace(motion.Amplify(raw,center,2,false).Rotation):ToAxisAngle();check(math.abs(b-2*a)<.00001,'Rotation excursion doubled')end
 end end
 local original=weld.C0;local raw=config.Centers.Torso*CFrame.new(0,.02,0)*CFrame.Angles(0,.02,0)
 bones.Torso.Transform=raw;local remove=assert(motion.Mount(rig,track));run.PreSimulation:Fire()
 local expected=bones.Torso.Transform
 for i=1,600 do run.PreAnimation:Fire();run.PreSimulation:Fire()end
 check(near(bones.Torso.Transform,expected),'600 throttled frames cannot accumulate correction')
 check(near(weld.C0,original),'GroundFit false leaves visual weld unchanged')
 check(near(actor.CFrame,CFrame.identity),'Actor root unchanged')
 check(run.PreAnimation:Count()==1 and run.PreSimulation:Count()==1,'One frame pair per mount')
 settings.Amplitude=1;run.PreAnimation:Fire();run.PreSimulation:Fire()
 check(near(bones.Torso.Transform,raw),'Live 1.0 switch removes amplitude correction')
 remove();remove()
 check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,'Idempotent cleanup disconnects both')
 check(near(bones.Torso.Transform,raw)and near(weld.C0,original),'Cleanup restores raw pose and original weld')
 enemy:SetAttribute('WorldId',2);check(motion.Mount(rig,track)==nil,'World2 excluded')
 enemy:SetAttribute('WorldId',1);enemy:SetAttribute('StageNumber',2);check(motion.Mount(rig,track)==nil,'Other Stage excluded')
 enemy:SetAttribute('StageNumber',1);track.Animation.AnimationId='unreviewed';check(motion.Mount(rig,track)==nil,'Different clip not corrected using old centers')
 track.Animation.AnimationId=config.WalkAnimationId;bones.Head:Destroy();check(motion.Mount(rig,track)==nil,'Partial streamed rig waits')
 enemy:Destroy()
 return {Passed=true,Assertions=checks,Kind='Exact module, fake frame signals; no rendering or real streaming'}
end
