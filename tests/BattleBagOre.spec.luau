-- Pure journal checks; no DataStore or player data writes.
return function(R,F,First)
 local checks={}
 local function check(v,n)assert(v,n);table.insert(checks,n)end
 local base={SessionOwnerToken="A",OwnedItems={item=3},OwnedOres={ORE_001=4},Win=9}
 local op={Id="r1",OwnerToken="A",Sequence=1,RunId="run",CreatedAt=1,Deltas={item=2},OreDeltas={ORE_001=1,ORE_002=1}}
 local pending=assert(R.Transition(base,op,"Prepare"))
 check(pending.OwnedItems.item==3 and pending.OwnedOres.ORE_001==4,"Prepare owns neither category")
 local granted=assert(R.Transition(pending,op,"Grant"))
 check(granted.OwnedItems.item==5 and granted.OwnedOres.ORE_001==5 and granted.OwnedOres.ORE_002==1,"Mixed grant atomic")
 check(R.Transition(granted,op,"Grant")==granted,"Grant replay unchanged")
 check(R.Transition(granted,op,"Cancel")==granted,"Death after committed grant never subtracts")
 local cancelled=assert(R.Transition(pending,op,"Cancel"))
 check(cancelled.OwnedItems.item==3 and cancelled.OwnedOres.ORE_001==4 and not cancelled.OwnedOres.ORE_002,"Cancellation owns neither")
 check(R.Transition(cancelled,op,"Grant")==cancelled,"Cancelled run cannot later grant")
 local recovery=table.clone(pending);R.Recover(recovery)
 check(recovery.RunOreReturnJournal.State=="Cancelled" and recovery.OwnedOres.ORE_001==4,"Join cancels abandoned pending return")
 local changed=table.clone(op);changed.OreDeltas={ORE_001=2}
 check(R.Transition(pending,changed,"Grant")==nil,"Ore signature mismatch rejected")
 local oreOnly=table.clone(op);oreOnly.Deltas={}
 local orePending=assert(R.Transition(base,oreOnly,"Prepare"));local oreGrant=assert(R.Transition(orePending,oreOnly,"Grant"))
 check(oreGrant.OwnedItems.item==3 and oreGrant.OwnedOres.ORE_001==5,"Ore-only return")
 local legacy=table.clone(pending);legacy.RunReturnJournal=table.clone(pending.RunOreReturnJournal);legacy.RunOreReturnJournal=nil;legacy.RunReturnJournal.OreDelta=nil
 local legacyOp=table.clone(op);legacyOp.OreDeltas=nil
 check(R.ValidateJournal(legacy.RunReturnJournal),"Legacy Item journal accepted")
 local legacyGrant=assert(R.Transition(legacy,legacyOp,"Grant"))
 check(legacyGrant.OwnedItems.item==5 and legacyGrant.OwnedOres.ORE_001==4,"Legacy Item return does not add Ore")
 local overflow=table.clone(base);overflow.OwnedOres={ORE_001=9007199254740991}
 local overflowPending=assert(R.Transition(overflow,op,"Prepare"))
 check(R.Transition(overflowPending,op,"Grant")==nil and overflow.OwnedItems.item==3,"Ore overflow cannot partially grant Items")
 local d={OwnedOres={},OwnedDumbbells={},Win=0,FirstStage1Reward=First.Normalize(nil,true),ForgeJournal={Sequence=0}}
 local firstOp={Id="first",Sequence=1,Action="FirstStage1Defeat",Delivery="BattleBag",ResultId="ORE_001",Signature="first|bag"}
 local first=assert(F.Apply(d,firstOp))
 check(first.FirstStage1Reward.Consumed and first.FirstStage1Reward.BagEligible and not next(first.OwnedOres),"First guarantee consumes eligibility without permanent Ore")
 check(First.Normalize(first.FirstStage1Reward,false).Delivery=="BattleBag","First state survives normalization")
 local discarded=table.clone(firstOp);discarded.ResultId="";discarded.Signature="first|discard"
 local full=assert(F.Apply(d,discarded))
 check(full.FirstStage1Reward.Consumed and not full.FirstStage1Reward.BagEligible and not next(full.OwnedOres),"Full bag consumes first defeat without Ore")
 check(First.Normalize(nil,false).Consumed,"Existing records excluded")
 local oldFirst=First.Normalize({Version=1,Consumed=true,DefeatId="legacy",OreGranted=true},false)
 check(oldFirst.OreGranted and oldFirst.Delivery==nil,"Previously direct Stone remains legacy committed")
 check(granted.RunReturnJournal==nil and granted.RunOreReturnJournal.State=="Granted","Ore journal does not write an unreadable legacy Item journal")
 local newerItem=table.clone(op);newerItem.Id="r2";newerItem.Sequence=2;newerItem.OreDeltas=nil
 local itemPending=assert(R.Transition(granted,newerItem,"Prepare"));local itemGranted=assert(R.Transition(itemPending,newerItem,"Grant"))
 check(itemGranted.RunOreReturnJournal.State=="Granted" and itemGranted.RunReturnJournal.State=="Granted","Mixed then Item-only journals coexist")
 local stale=table.clone(op);stale.Id="stale";stale.Sequence=1
 check(R.Transition(itemGranted,stale,"Prepare")==nil,"Cross-category sequence fence")
 return {Passed=#checks,Checks=checks}
end
