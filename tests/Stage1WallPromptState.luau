-- Standalone Luau runner: luau tests/Stage1WallPromptState.luau
local State=require("../src/ReplicatedStorage/Modules/Stage1WallPromptState")
local checks=0
local function check(value,message) checks+=1;assert(value,message) end
local character={}
local function setup()
 local s=State.new(42,0,false);local seq=0
 local function send(d)
  seq+=1;d.OwnerUserId=d.OwnerUserId or 42;d.WorldId=d.WorldId or 1
  d.RunRevision=d.RunRevision or 1;d.MessageSequence=d.MessageSequence or seq
  d.TutorialResetSequence=d.TutorialResetSequence or 0
  return s:Handle(d,character),d
 end
 send({Type="Initialize",Character=character,CurrentStage=1})
 send({Type="WallInitialize",State={MajorStage=1,Current=1,Skipped=false,Cleared={},Gauges={50,75,100,135}}})
 send({Type="Fighting",Active=true,CombatType="Wall",Stage=1,WallIndex=1})
 return s,send
end
local good={GuideIndex=1,TutorialCompleted=false,World=1,Stage=1,AutoTap=false,Alive=true,
 Training=false,Blocked=false,TargetLoaded=true,Contact=true}
local s,send=setup()
check(s:CanShow(good),"fresh confirmed wall combat")
for key,values in {GuideIndex={0,2},TutorialCompleted={true},World={2},Stage={2},AutoTap={true},Alive={false},Training={true},Blocked={true},TargetLoaded={false},Contact={false}} do
 for _,value in values do local c=table.clone(good);c[key]=value;check(not s:CanShow(c),key) end
end
for _,key in {"GuideIndex","TutorialCompleted","World","Stage","AutoTap","Alive","TargetLoaded","Contact"} do
 local c=table.clone(good);c[key]=nil;check(not s:CanShow(c),"unknown "..key)
end
check(State.Label("Touch")=="Tap","touch label")
check(State.Label("KeyboardAndMouse")=="Click","hybrid uses current input")
check(State.Label("Gamepad")==nil,"unsupported action hidden")
check(State.Label(nil)==nil,"unknown input hidden")
for _,bad in {
 {Type="InputBegan"},{Type="TouchTapInWorld"},{Type="WallGauge",MajorStage=1,Index=1,Current=49},
 {Type="CombatAttack",Manual=false,CombatType="Wall",Stage=1,WallIndex=1},
 {Type="CombatAttack",Manual=true,CombatType="MiniBoss",Stage=1,WallIndex=1},
 {Type="CombatAttack",Manual=true,Stage=1,WallIndex=1},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=2,WallIndex=1},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=2},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=1,OwnerUserId=99},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=1,WorldId=2},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=1,RunRevision=2},
 {Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=1,TutorialResetSequence=1},
} do
 local test,emit=setup();emit(bad);check(not test.Completed,"false completion: "..bad.Type)
end
local hit={Type="CombatAttack",Manual=true,CombatType="Wall",Stage=1,WallIndex=1}
send(table.clone(hit));check(s.Completed and not s:CanShow(good),"valid manual hit completes")
s:Invalidate();check(s.Completed,"death preserves completion")
send({Type="Initialize",Character=character,CurrentStage=1,RunRevision=2});check(s.Completed,"new run preserves completion")
s:Reset(1);check(not s.Completed and not s.Ready,"explicit reset")
check(not send(table.clone(hit)) and not s.Completed,"old reset packet rejected")
send({Type="Initialize",Character=character,CurrentStage=1,RunRevision=3,TutorialResetSequence=1})
send({Type="WallInitialize",RunRevision=3,TutorialResetSequence=1,State={MajorStage=1,Current=1,Skipped=false,Cleared={},Gauges={50}}})
send({Type="Fighting",RunRevision=3,TutorialResetSequence=1,Active=true,CombatType="Wall",Stage=1,WallIndex=1})
local nextHit=table.clone(hit);nextHit.RunRevision=3;nextHit.TutorialResetSequence=1;send(nextHit)
check(s.Completed,"new reset manual completion")
local t,emit=setup();emit({Type="Fighting",Active=false});emit(table.clone(hit));check(not t.Completed,"no owned contact session")
t,emit=setup();emit({Type="WallCleared",MajorStage=1,State={Current=2,Skipped=false,Cleared={[1]=true},Gauges={0,75}}});emit(table.clone(hit));check(not t.Completed,"clear is not manual proof")
t,emit=setup();local _,packet=emit({Type="Fighting",Active=false});local stale=table.clone(hit);stale.MessageSequence=packet.MessageSequence;check(not emit(stale) and not t.Completed,"replay rejected")
t,emit=setup();check(not emit({Type="Initialize",Character={},CurrentStage=1}),"old character rejected")
t,emit=setup();emit({Type="WallInitialize",State={MajorStage=1,Current=1,Skipped=true,Cleared={},Gauges={50}}});check(not t:CanShow(good),"skipped stage excluded")
t,emit=setup();emit({Type="Initialize",Character=character,CurrentStage=1,ActiveCombat={Active=true,CombatType="Wall",Stage=1,WallIndex=1}})
check(not t:CanShow(good),"await snapshot after repeated RequestState")
emit({Type="WallInitialize",State={MajorStage=1,Current=1,Skipped=false,Cleared={},Gauges={50}}})
check(t:CanShow(good),"RequestState restores current combat without recontact")
t,emit=setup();emit({Type="Fighting",Active=true,CombatType="MiniBoss",Stage=1})
check(not t:CanShow(good),"Boss session excluded")
t,emit=setup();emit({Type="WallInitialize",State={MajorStage=1,Current=5,Skipped=false,Cleared={true,true,true,true},Gauges={0,0,0,0}}})
check(not t:CanShow(good),"all walls cleared / Boss guide excluded")
t,emit=setup();emit({Type="WallGauge",MajorStage=1,Index=1,Current=0})
check(not t:CanShow(good),"zero HP excluded")
local remounted=State.new(42,0,true)
check(remounted.Completed and not remounted:CanShow(good),"same session controller replacement preserves latch")
print("Stage1WallPromptState: "..checks.." assertions passed")
