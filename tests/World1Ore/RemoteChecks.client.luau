-- Execute only in the isolated QA Play session. Real RemoteFunction calls, not UI clicks.
local RS=game.ReplicatedStorage
local H=game.HttpService
local forge=RS.Remotes.ForgeRequest
local pet=RS.Remotes.PetRequest
local n=0
local function check(ok,msg) assert(ok,msg);n+=1 end
local function forgeState() task.wait(.15);return forge:InvokeServer({Action="GetState"}).State end
local function send(action,fields,state)
 state=state or forgeState();local op=table.clone(fields or {})
 op.Action=action;op.Id=H:GenerateGUID(false);op.Sequence=state.Sequence+1;op.Token=state.Token;op.Generation=state.Generation
 task.wait(.15);return forge:InvokeServer(op),op
end
local function count(t) local x=0 for _ in pairs(t) do x+=1 end return x end
local initial=forgeState()
local r=send("MergeOre",{Materials={ORE_017=1}})
check(not r.Success,"reserved ore refused")
r=send("MergeOre",{Materials={ORE_001=6}});check(not r.Success,"six refused")
r=send("SellOre",{Materials={ORE_001=999999}});check(not r.Success,"oversale refused")
check(forgeState().Sequence==initial.Sequence,"invalids do not consume")
local before=forgeState()
local forged,op=send("MergeOre",{Materials={ORE_001=1}},before)
check(forged.Success,"single ore merge")
check(forged.State.Ores.ORE_001==before.Ores.ORE_001-1,"single material consumed")
check(forged.State.DumbbellCounts.NORMAL_01==(before.DumbbellCounts.NORMAL_01 or 0)+1,"single bell grant")
task.wait(.15);r=forge:InvokeServer(op)
check(r.Success and r.State.Sequence==forged.State.Sequence,"retry acknowledged once")
check(r.State.DumbbellCounts.NORMAL_01==forged.State.DumbbellCounts.NORMAL_01,"retry no duplicate")
local second=send("MergeOre",{Materials={ORE_001=1}})
check(second.Success and second.State.DumbbellCounts.NORMAL_01==forged.State.DumbbellCounts.NORMAL_01+1,"duplicate ownership")
local sold=send("SellOre",{Materials={ORE_002=8}})
check(sold.Success and sold.State.Ores.ORE_002==nil,"sale over five units")
check(sold.State.Win==before.Win+24,"sale exact Win")
local info=pet:InvokeServer("GetState")
local ids={}
for id,name in pairs(info.state.Owned) do if require(RS.Modules.Egg).mergePet(name) then table.insert(ids,id) end end
table.sort(ids)
local function petSend(action,materials,state,id)
 task.wait(.8);state=state or pet:InvokeServer("GetState")
 return pet:InvokeServer(action,id or H:GenerateGUID(false),state.state.Revision,materials,nil,state.generation)
end
check(#ids>=4,"valid Pet fixture")
local equipped=petSend("Equip",ids[1])
check(equipped.ok,"equip before rejection")
local rejected=petSend("Merge",{ids[1],ids[2]})
check(not rejected.ok and rejected.reason=="PetEquipped","equipped Pet rejected")
check(rejected.state.Owned[ids[1]]~=nil and rejected.state.Owned[ids[2]]~=nil,"invalid merge preserves materials")
check(petSend("Equip",ids[1]).ok,"unequip")
rejected=petSend("Merge",{ids[1],ids[1]})
check(not rejected.ok,"duplicate copy ID refused")
rejected=petSend("Merge",{ids[1]})
check(not rejected.ok,"one Pet refused")
info=pet:InvokeServer("GetState");local request=H:GenerateGUID(false)
local merged=petSend("Merge",{ids[1],ids[2]},info,request)
check(merged.ok,"valid Pet merge")
check(count(merged.state.Owned)==count(info.state.Owned)-1,"consume two create one")
check(not merged.state.Owned[ids[1]] and not merged.state.Owned[ids[2]],"exact IDs consumed")
check(#merged.state.LastResults==1 and merged.state.LastMergeEgg~=nil,"Egg outcome and one hatch saved")
local retried=petSend("Merge",{ids[1],ids[2]},info,request)
check(retried.ok and retried.state.Revision==merged.state.Revision,"Pet retry once")
check(retried.state.LastResults[1].id==merged.state.LastResults[1].id,"Pet retry same individual")
local stale=petSend("Merge",{ids[3],ids[4]},info)
check(not stale.ok,"stale revision refused")
check(forgeState().Win==sold.State.Win,"Pet merge no fee")
return H:JSONEncode({Passed=n,Kind="Actual remotes in isolated Studio Play, not mouse UI",ForgeSequence=forgeState().Sequence,PetRevision=merged.state.Revision})
