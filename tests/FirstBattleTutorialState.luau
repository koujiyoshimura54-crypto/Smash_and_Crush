-- Pure progression checks; run with run_first_battle.py or native module arguments.
return function(S,R,C)
local checks=0
local function eq(a,b) checks+=1;assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local old=S.Normalize(nil,false);eq(old.Eligible,false)
local fresh=S.Normalize(nil,true);eq(fresh.Eligible,true)
local context={World=1,Alive=true,InLobby=true,Level=1,Merged=false,Equipped=false}
local function phase(s) return S.Phase(s or fresh,context) end
eq(phase(old),'Legacy');eq(phase(),'Train')
context.Level=2;eq(phase(),'Battle');eq(C.NeedsIntroTraining(2,5,false),false)
context.Level=20;eq(phase(),'Battle')
context.MergeOpen=true;eq(phase(),'Merge')
context.Merged=true;eq(phase(),'Equip')
context.Equipped=true;eq(phase(),'Battle') -- voluntary merge never skips first battle
context.Level=1;eq(phase(),'Train')
context.Level=2;context.MergeOpen=false;context.Merged=false;context.Equipped=false
local pre,changed=S.Record(fresh,'Death');eq(changed,false);eq(pre.FirstOutcome,nil)
pre,changed=S.Record(fresh,'Back');eq(changed,false)
local started=S.Record(fresh,'Started');eq(started.FirstOutcome,nil);eq(phase(started),'Battle')
for _,result in {'Death','Back','Victory'} do
 local facts=S.Record(started,result);eq(facts.FirstOutcome,result)
 eq(phase(facts),'Merge')
 context.InLobby=false;eq(phase(facts),result=='Victory' and 'Reward' or 'Waiting')
 context.InLobby=true;context.Merged=true;eq(phase(facts),'Equip')
 context.Equipped=true;eq(phase(facts),result=='Victory' and 'Complete' or 'Train')
 context.Level=4;eq(phase(facts),result=='Victory' and 'Complete' or 'Battle')
 context.Level=40;eq(phase(facts),result=='Victory' and 'Complete' or 'Battle')
 local again=S.Record(facts,'Death');eq(again.FirstOutcome,result)
 local won=S.Record(facts,'Victory');eq(won.Stage1Defeated,true);eq(won.FirstOutcome,result)
 local stale=S.Merge(won,fresh);eq(stale.Stage1Defeated,true);eq(stale.FirstOutcome,result)
 eq(S.Normalize(stale,false).Stage1Defeated,true)
 context.Level=2;context.Merged=false;context.Equipped=false
end
context.World=2;eq(phase(),'Waiting');context.World=1;context.Alive=false;eq(phase(),'Waiting')
eq(S.StoneProtected({FirstBattleTutorial=old}),false)
eq(S.StoneProtected({FirstBattleTutorial=fresh}),true)
eq(S.StoneProtected({FirstBattleTutorial=fresh,OreMergeTutorial={Completed=true}}),false)
eq(S.Merge(old,fresh).Eligible,false)
eq(S.Normalize({Version=1,Eligible=true,BattleStarted=false,Stage1Defeated=true}),nil)
local attrs={TutorialCompleted=true,FirstBattleTutorialEligible=false}
local player={GetAttribute=function(_,name)return attrs[name]end}
eq(S.AllowLaterGuides(player),true) -- Existing completed players retain later guides.
attrs.TutorialCompleted=false;eq(S.AllowLaterGuides(player),false)
attrs.FirstBattleTutorialEligible=true;attrs.TutorialCompleted=true
eq(S.AllowLaterGuides(player),false) -- A Trophy alone must not interrupt merge/equip.
attrs.FirstBattleStage1Defeated=true;attrs.OreTutorialCompleted=true
eq(S.AllowLaterGuides(player),false)
attrs.DumbbellEquipTutorialInitialCompleted=true;eq(S.AllowLaterGuides(player),true)
for _,id in {'StoneIntro01','Reward01','IntroWin02'} do
 eq(R.IsClaimed({[id]=true},'IntroWin02'),true)
 eq(R.IsClaimed({[id]=true},'IronIntro01'),false)
end
eq(R.IsClaimed({},'IntroWin02'),false)
eq(R.Rewards[1].RequiredSeconds,60);eq(R.Rewards[1].RewardType,'Win');eq(R.Rewards[1].Amount,1)
eq(#C.GetWallConfig(1).Walls,1);eq(C.GetWallConfig(1).Walls[1],50);eq(C.GetMaxHP(1),200)
eq(#C.GetWallConfig(2).Walls,4);eq(C.GetWallConfig(2).Walls[1],275)
print('FirstBattleTutorialState: '..checks..' assertions passed')
return checks
end
