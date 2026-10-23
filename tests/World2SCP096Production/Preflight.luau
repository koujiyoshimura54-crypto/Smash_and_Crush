assert(not game:GetService('RunService'):IsRunning(),'Edit preflight only')
-- Fresh detached ModuleScripts avoid an earlier Edit inspection's require cache.
local stateModule=game.ReplicatedStorage.Modules.World2SCP096State:Clone()
local clipModule=game.ReplicatedStorage.Modules.World2SCP096Clip:Clone()
local State=require(stateModule)
local Clip=require(clipModule)
local Config=require(game.ReplicatedStorage.Config.World2SCP096Config)
local checks=0
local function check(condition,message) assert(condition,message);checks+=1 end
local template=game.ServerStorage.EnemyTemplates.World2SCPDisplays.SCP096_BodyBones_Display
local clone=template:Clone();clone:ScaleTo(template:GetScale()*2.25)
local body=Clip.Compile(clone)
local durations={};for name,row in body.Clips do durations[name]=row.Duration end
check(Config.Clips.GetUp_Panic.Speed==2 and Config.Clips.Panic.Speed==2,'Intro rates')
for _,name in {'Running','AttackRunStart','AttackRun'} do check(Config.Clips[name].Speed==1,'Body rate '..name) end
check(#body.Bindings==73,'All body Bone channels bound')
local a,b=State.Create(durations),State.Create(durations)
check(not State.Ready(a,0),'No pre-wall chase')
State.SetAttack(a,true,0);check(a.Phase=='Waiting','No pre-wall attack')
check(State.Begin(a,10),'First wall4 begin')
check(not State.Begin(a,10.2),'Duplicate wall4 ignored')
check(a.Intervals.GetUp_Panic==1.5 and a.Intervals.Panic==1,'Actual clip lengths / rates')
check(State.Update(a,11.49)=='GetUp_Panic','GetUp boundary')
State.SetAttack(a,true,11.49);check(a.Phase=='GetUp_Panic','Intro blocks attack')
check(State.Update(a,11.5)=='Panic','Panic starts without extra delay')
check(not State.Ready(a,12.499),'Panic is once despite source Loop=true')
check(State.Ready(a,12.5) and a.Phase=='AttackRunStart','Intro immediately starts forward pursuit at2.5 seconds')
State.SetAttack(a,true,12.6);check(a.Phase=='AttackRunStart' and a.AttackEligible,'Close combat eligibility')
State.SetAttack(a,false,12.8);check(a.Phase=='AttackRunStart' and not a.AttackEligible,'Range exit cannot interrupt forward start')
State.SetAttack(a,true,12.9);check(a.Phase=='AttackRunStart' and a.StartedAt==12.5,'Range re-entry cannot restart start clip')
check(State.Update(a,13.09)=='AttackRunStart','Start clip at1x')
check(State.Update(a,13.10001)=='AttackRun','Start transitions to forward loop')
State.SetAttack(a,true,20);check(a.Phase=='AttackRun','Attack loop not periodically restarted')
State.SetAttack(a,false,20.1);check(a.Phase=='AttackRun' and not a.AttackEligible,'Range exit preserves forward loop')
check(not State.Begin(a,20.2),'No repeated intro during the encounter')
check(b.Phase=='Waiting' and not b.Used,'Independent actor unaffected')
State.Cancel(a);State.SetAttack(a,true,21);check(a.Phase=='Cancelled','Old actor cannot restart')
check(not State.Begin(a,22),'Cancelled actor remains retired')
local retry=State.Create(durations);check(State.Begin(retry,30),'Fresh encounter restarts intro')
State.Cancel(retry);check(State.Update(retry,40)=='Cancelled','Interrupted intro never completes late')
local skipped=State.Create(durations);State.Begin(skipped,50)
check(State.Update(skipped,60)=='AttackRun' and math.abs(skipped.StartedAt-53.1)<.0001,'Delayed frame preserves exact boundaries')
local pivot=clone:GetPivot()
local movement={}
for name,row in body.Clips do
 Clip.Sample(body,name,0)
 local transforms={};for _,binding in body.Bindings do transforms[binding.Bone]=binding.Bone.Transform end
 Clip.Sample(body,name,math.min(.2,row.Duration/2))
 local changed=0;for _,binding in body.Bindings do if binding.Bone.Transform~=transforms[binding.Bone] then changed+=1 end end
 movement[name]=changed;check(changed>0,'Actual sampled Bone transforms '..name)
 check(clone:GetPivot()==pivot,'Clip cannot move authoritative root '..name)
end
Clip.Update(body,'AttackRun',100,100.1,true,1)
Clip.Update(body,'AttackRun',100,100.2,false,1);local frozen=body.LastTime
Clip.Update(body,'AttackRun',100,105,false,1);check(body.LastTime==frozen,'Home idle holds forward pose')
Clip.Update(body,'AttackRun',100,105.1,true,1)
check(math.abs(body.LastTime-((frozen+.1)%durations.AttackRun))<.0001,'Forward loop resumes at1x without jumping clock')
for _,side in {'L','R'} do
 local mesh=clone['Body.LP'];local upper=mesh:FindFirstChild(side..'.Arm_U',true);local hand=mesh:FindFirstChild(side..'.Hand',true)
 local direction=mesh.CFrame:VectorToObjectSpace((hand.TransformedWorldCFrame.Position-upper.TransformedWorldCFrame.Position).Unit)
 check(-direction.Z>.9 and math.abs(direction.Y)<.15,'Forward horizontal arm '..side)
end
Clip.Reset(body)
for _,binding in body.Bindings do check(binding.Bone.Transform==CFrame.identity,'Reset Bone') end
clone:Destroy()
stateModule:Destroy();clipModule:Destroy()
return game:GetService('HttpService'):JSONEncode({Checks=checks,Durations=durations,
 IntroSeconds=2.5,SampledBoneChanges=movement,Mode='Native Edit unit checks, not Play or visual acceptance'})
