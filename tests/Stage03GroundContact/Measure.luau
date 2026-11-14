-- Execute in isolated Client after native helpers; returns JSON, no external writes.
local q=game.ReplicatedStorage.__Stage3GroundQA.Client
local p=game.Players.LocalPlayer;local r=workspace.Enemies['Owner_'..p.UserId].Stage03_Enemy.TungTungSahurRig
local M=require(game.ReplicatedStorage.Modules.Stage03GroundContact)
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={workspace.GeneratedMap.BattleCorridor}
local function poses()local t={};for _,v in r:GetDescendants()do if v:IsA('Motor6D')then t[v.Name]=v.Transform end end;return t end
q:Invoke('Phase',.15);q:Invoke('Ground',false);task.wait(.1);local before=poses();local base=r.LowerTorso.Root.C0
q:Invoke('Ground',true);task.wait(.1);local after=poses();local diff=0
for name,cf in before do local a={cf:GetComponents()};local b={after[name]:GetComponents()};for i=1,12 do diff=math.max(diff,math.abs(a[i]-b[i]))end end
local out={AnimationTransformDifference=diff,BaseRootC0Y=base.Y,Runs={}}
q:Invoke('Run')
for _,enabled in {false,true}do
 q:Invoke('Ground',enabled);task.wait(.1)
 local result={Samples=0,GapMin=math.huge,SupportGapMax=-math.huge,GapMax=-math.huge,C0Min=math.huge,C0Max=-math.huge,Misses=0}
 local start=os.clock()
 repeat game.RunService.PostSimulation:Wait();result.Samples+=1;local support=math.huge
  for _,n in {'LeftFoot','RightFoot'}do local f=r[n];local hit=workspace:Raycast(f.Position+Vector3.new(0,10,0),Vector3.new(0,-20,0),ray)
   if hit then local gap=M.Bottom(f.CFrame,f.Size)-hit.Position.Y;result.GapMin=math.min(result.GapMin,gap);result.GapMax=math.max(result.GapMax,gap);support=math.min(support,gap)else result.Misses+=1 end
  end
  result.SupportGapMax=math.max(result.SupportGapMax,support)
  result.C0Min=math.min(result.C0Min,r.LowerTorso.Root.C0.Y);result.C0Max=math.max(result.C0Max,r.LowerTorso.Root.C0.Y)
 until os.clock()-start>=3.2
 result.Seconds=os.clock()-start;out.Runs[tostring(enabled)]=result
end
q:Invoke('Phase',.15);task.wait(.1);local initial=r.LowerTorso.Root.C0;q:Invoke('Run');local start=os.clock();task.wait(8.4);out.LoopSeconds=os.clock()-start;q:Invoke('Phase',.15);task.wait(.1)
out.SamePhaseC0Difference=(r.LowerTorso.Root.C0.Position-initial.Position).Magnitude;out.State=q:Invoke('Inspect');q:Invoke('Run')
return game.HttpService:JSONEncode(out)
