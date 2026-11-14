-- Execute in the isolated Client after native fixtures; allows 21 seconds of Speed1 playback.
local q=game.ReplicatedStorage.__Stage2MotionQA.Client
local p=game.Players.LocalPlayer;local r=workspace.Enemies['Owner_'..p.UserId].Stage02_Enemy.TralaleroTralalaRig
local function poses()local t={};for _,b in r.FakeRootPart:GetDescendants()do if b:IsA('Bone')then t[b.Name]=b.Transform end end;return t end
q:Invoke('Amplitude',1.5);q:Invoke('FloatHold',false);q:Invoke('Phase',.23);task.wait(.1)
local before=poses();local state=q:Invoke('Inspect');q:Invoke('Run')
local start=os.clock();task.wait(21);local elapsed=os.clock()-start
q:Invoke('Phase',.23);task.wait(.1);local after=poses();local pos,ang,component,selfAngle=0,0,0,0
for n,cf in before do local d=cf:ToObjectSpace(after[n]);local _,a=d:ToAxisAngle();pos=math.max(pos,d.Position.Magnitude);ang=math.max(ang,math.abs(a));local aa={cf:GetComponents()};local bb={after[n]:GetComponents()};for i=1,12 do component=math.max(component,math.abs(aa[i]-bb[i]))end;local _,sa=cf:ToObjectSpace(cf):ToAxisAngle();selfAngle=math.max(selfAngle,math.abs(sa))end
local out={Seconds=elapsed,WalkLoops=elapsed/1.0499999523162842,MaxPositionDrift=pos,MaxAngleDrift=ang,MaxComponentDifference=component,SelfComparisonAngleError=selfAngle,Before=state,After=q:Invoke('Inspect')}
q:Invoke('Run');return game.HttpService:JSONEncode(out)
