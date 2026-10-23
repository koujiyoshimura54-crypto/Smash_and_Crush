assert(not game:GetService('RunService'):IsRunning(),'Edit preflight only')
local State=require(game.ReplicatedStorage.Modules.World2SCP096State)
local Clip=require(game.ReplicatedStorage.Modules.World2SCP096Clip)
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
check(State.Ready(a,12.5) and a.Phase=='Running','Intro ends at2.5 seconds')
State.SetAttack(a,true,12.6);check(a.Phase=='AttackRunStart','Attack entry')
State.SetAttack(a,false,12.8);check(a.Phase=='Running','Start interrupted on exit')
State.SetAttack(a,true,12.9);check(a.Phase=='AttackRunStart' and a.StartedAt==12.9,'Re-entry restarts')
check(State.Update(a,13.49)=='AttackRunStart','Start clip at1x')
check(State.Update(a,13.50001)=='AttackRun','Start transitions to loop')
State.SetAttack(a,true,20);check(a.Phase=='AttackRun','Attack loop not periodically restarted')
State.SetAttack(a,false,20.1);check(a.Phase=='Running','Attack exit')
check(not State.Begin(a,20.2),'No repeated intro during the encounter')
check(b.Phase=='Waiting' and not b.Used,'Independent actor unaffected')
State.Cancel(a);State.SetAttack(a,true,21);check(a.Phase=='Cancelled','Old actor cannot restart')
check(not State.Begin(a,22),'Cancelled actor remains retired')
local retry=State.Create(durations);check(State.Begin(retry,30),'Fresh encounter restarts intro')
State.Cancel(retry);check(State.Update(retry,40)=='Cancelled','Interrupted intro never completes late')
local skipped=State.Create(durations);State.Begin(skipped,50)
check(State.Update(skipped,60)=='Running' and skipped.StartedAt==52.5,'Delayed frame preserves exact boundaries')
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
Clip.Update(body,'Running',100,100.1,true,1)
Clip.Update(body,'Running',100,100.2,false,1);local frozen=body.LastTime
Clip.Update(body,'Running',100,105,false,1);check(body.LastTime==frozen,'Contact stop freezes Running')
Clip.Update(body,'Running',100,105.1,true,1)
check(math.abs(body.LastTime-((frozen+.1)%durations.Running))<.0001,'Running resumes at1x without jumping clock')
Clip.Reset(body)
for _,binding in body.Bindings do check(binding.Bone.Transform==CFrame.identity,'Reset Bone') end
clone:Destroy()
return game:GetService('HttpService'):JSONEncode({Checks=checks,Durations=durations,
 IntroSeconds=2.5,SampledBoneChanges=movement,Mode='Native Edit unit checks, not Play or visual acceptance'})
