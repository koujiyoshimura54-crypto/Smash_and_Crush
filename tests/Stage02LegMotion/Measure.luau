-- Execute in the isolated Client after native fixtures. Returns JSON, no external writes.
local q=game.ReplicatedStorage.__Stage2MotionQA.Client
local p=game.Players.LocalPlayer;local r=workspace.Enemies['Owner_'..p.UserId].Stage02_Enemy.TralaleroTralalaRig
local cfg=require(game.ReplicatedStorage.Config.Stage02LegMotionConfig)
local function bone(path)local b=r.FakeRootPart;for _,n in path do b=b[n]end;return b end
local changed={};for _,j in cfg.Joints do changed[j.Path[#j.Path]]=true end
local function poses()local t={};for _,b in r.FakeRootPart:GetDescendants()do if b:IsA('Bone')then t[b.Name]=b.Transform end end;return t end
q:Invoke('Phase',.23);q:Invoke('Amplitude',1);task.wait(.1);local before=poses()
q:Invoke('Amplitude',1.5);task.wait(.1);local after=poses()
local untouchedPos,untouchedAngle=0,0
for n,cf in before do if not changed[n]then local d=cf:ToObjectSpace(after[n]);local _,a=d:ToAxisAngle();untouchedPos=math.max(untouchedPos,d.Position.Magnitude);untouchedAngle=math.max(untouchedAngle,math.abs(a))end end
q:Invoke('Amplitude',1);task.wait(.1);local restored=poses();local restorePos,restoreAngle=0,0
for n,cf in before do local d=cf:ToObjectSpace(restored[n]);local _,a=d:ToAxisAngle();restorePos=math.max(restorePos,d.Position.Magnitude);restoreAngle=math.max(restoreAngle,math.abs(a))end
q:Invoke('FloatHold',false);q:Invoke('Run')
local out={Untouched={Position=untouchedPos,Angle=untouchedAngle},Restored={Position=restorePos,Angle=restoreAngle},Runs={}}
for _,amount in {1,1.5}do
 q:Invoke('Amplitude',amount);task.wait(.1)
 local results={};local lo,hi=math.huge,-math.huge;local start=os.clock();local samples=0
 repeat game.RunService.PostSimulation:Wait();samples+=1
  local wy=r.RootPart.Stage02VisualRootWeld.C0.Y;lo=math.min(lo,wy);hi=math.max(hi,wy)
  for _,j in cfg.Joints do
   local b=bone(j.Path);local n=b.Name;local v=r.FakeRootPart.CFrame:PointToObjectSpace(b.TransformedWorldCFrame.Position)
   local _,a=j.Center.Rotation:ToObjectSpace(b.Transform.Rotation):ToAxisAngle()
   local t=results[n]or{Min={v.X,v.Y,v.Z},Max={v.X,v.Y,v.Z},Angle=0}
   t.Angle=math.max(t.Angle,math.deg(math.abs(a)))
   for i,x in {v.X,v.Y,v.Z}do t.Min[i]=math.min(t.Min[i],x);t.Max[i]=math.max(t.Max[i],x)end;results[n]=t
  end
 until os.clock()-start>=3.2
 for _,t in results do t.Range={t.Max[1]-t.Min[1],t.Max[2]-t.Min[2],t.Max[3]-t.Min[3]}end
 out.Runs[tostring(amount)]={Samples=samples,Seconds=os.clock()-start,Joints=results,FloatC0Y={Min=lo,Max=hi,Range=hi-lo},State=q:Invoke('Inspect')}
end
return game.HttpService:JSONEncode(out)
