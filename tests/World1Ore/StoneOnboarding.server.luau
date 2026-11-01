-- Temporary native two-client harness. Install only with all DataStores replaced by Memory.
local Players=game.Players
local RS=game.ReplicatedStorage
local S=game.ServerScriptService.Services
local Data=require(S.PlayerDataService)
local Time=require(S.TimeRewardService)
local Forge=require(S.ForgeService)
local Drops=require(S.EnemyDropGachaService)
local Run=require(S.RunInventoryService)
local Memory=require(RS.__StoneMemory)
local Enemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local report={Checks={},Kind="Native two-client test; memory persistence; scripted combat"}
local function check(ok,label) assert(ok,label);table.insert(report.Checks,label) end
local function waitFor(fn,seconds)
 local untilTime=os.clock()+seconds
 repeat local result=fn();if result then return result end;task.wait(.1) until os.clock()>untilTime
end
local function session(p) return assert(Data.Get(p)) end
local function ores(p) return session(p).Data.OwnedOres.ORE_001 or 0 end
local function reload(p)
 session(p).Dirty=true;assert(Data.Save(p))
 Data.Release(p);assert(Data.Load(p))
end
local function fresh(p)
 assert(Data.Reset(p));Data.Release(p);assert(Data.Load(p));Data.SetAutoTapEnabled(p,false)
 p:SetAttribute("CurrentWorld",1)
end
local function combat(p)
 Data.SetCurrentStrength(p,1000000000)
 p:SetAttribute("CurrentWorld",1);Enemy.StartRun(p,1)
 Wall.ApplyDamageForStage(p,1,1000000000)
 local actor=assert(waitFor(function()return Enemy.GetEnemy(1,p)end,10),"personal boss ready")
 local root=p.Character.HumanoidRootPart;root.Anchored=true;root.CFrame=actor.CombatZone.CFrame
 task.wait(.35)
 local accepted,reason=Enemy.TryManualAttack(p);assert(accepted,tostring(reason))
 assert(waitFor(function()return Enemy.GetPlayerState(p).Defeated[1]end,8),"boss defeat")
 root.Anchored=false
 return Enemy.GetPlayerState(p)
end
local ended=false
local function finish()
 if ended then return end;ended=true
 game:GetService("StudioTestService"):EndTest(report)
end
task.delay(150,function()report.Error="Harness timeout";finish()end)
local ok,err=xpcall(function()
 check(waitFor(function()return #Players:GetPlayers()==2 end,40),"Two native clients")
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 local a,b=players[1],players[2]
 for _,p in ipairs(players) do
  assert(waitFor(function()local s=Data.Get(p);return s and s.Loaded and p.Character and p.Character:FindFirstChild("HumanoidRootPart") end,30),"data and character")
  Data.SetAutoTapEnabled(p,false)
  check(not session(p).Data.FirstStage1Reward.Consumed,"New player eligible")
 end
 report.Pure=require(RS.__StonePure)
 local sa=session(a);sa.Data.TimeRewards.ElapsedSeconds=60;sa.TimeRewardClock=os.clock()
 local granted,code,result=Time.Claim(a,"StoneIntro01")
 check(granted and result.RewardType=="Ore" and result.Amount==1 and ores(a)==1,"Time reward grants mergeable Stone")
 check(not Time.Claim(a,"StoneIntro01") and ores(a)==1,"Time claim replay")
 check(ores(b)==0 and not session(b).Data.FirstStage1Reward.Consumed,"Other player unaffected by time claim")
 assert(waitFor(Enemy.IsReady,20))
 local run=combat(a)
 check(waitFor(function()return ores(a)==2 end,8),"Real first Stage1 combat adds one Stone")
 check(session(a).Data.FirstStage1Reward.Consumed and not session(b).Data.FirstStage1Reward.Consumed,"First defeat belongs only to owner")
 local replay,why=Drops.OnEnemyDefeated(a,1,run,1)
 check(not replay and why=="AlreadyProcessed" and ores(a)==2,"Same combat notification cannot grant twice")
 local state=Forge.State(a)
 local request={Action="MergeOre",Materials={ORE_001=2},Id=game.HttpService:GenerateGUID(false),Token=state.Token,Sequence=state.Sequence+1,Generation=state.Generation}
 local merged=Forge.Request(a,request)
 local count=0 for _,n in pairs(session(a).Data.OwnedDumbbells) do count+=n end
 check(merged.Success and ores(a)==0 and count==1,"Time plus boss Stones merge into one dumbbell")
 check(Forge.Request(a,request).Success and ores(a)==0,"Merge replay no additional grant")
 reload(a)
 check(session(a).Data.FirstStage1Reward.Consumed and session(a).Data.TimeRewards.Claimed.StoneIntro01,"First defeat and time claim survive memory save/reload")
 check(not Time.Claim(a,"StoneIntro01") and ores(a)==0,"Reload cannot reclaim Stone")
 combat(b)
 check(waitFor(function()return ores(b)==1 end,8),"Second real player receives own first Stone")
 check(session(a).Data.FirstStage1Reward.Consumed,"Second player cannot reset first player")
 -- Force ITEM only in this private cloned service, proving second kill uses ordinary draw.
 -- Select a real Item ID without depending on map order.
 local itemId=next(require(RS.Config.ItemMaster).GetAll())
 local normal=require(S.__StoneNormalProbe)
 local nextRun={RunInventoryId=Run.Reset(b,true),Defeated={[1]=true}}
 local accepted,outcome=normal.OnEnemyDefeated(b,1,nextRun,1)
 check(accepted and outcome=="ITEM" and Run.GetSnapshot(b).Count==1 and ores(b)==1,"Second Stage1 uses ordinary item path")
 -- Existing content claims follow their IDs, not the new card numbers.
 session(a).Data.TimeRewards.ElapsedSeconds=1800
 session(a).Data.TimeRewards.Claimed.Reward01=true
 session(a).Data.TimeRewards.Claimed.Reward06=true
 reload(a)
 local states=Time.GetState(a)
 check(states.States.Reward01=="Claimed" and states.States.Reward02=="Ready" and states.States.Reward06==nil,"Moved claims preserved; unrelated unclaimed reward available; retired ID inert")
 check(session(a).Data.TimeRewards.ElapsedSeconds>=1800 and session(a).Data.TimeRewards.Claimed.Reward06,"Elapsed and retired history preserved")
 -- Legacy record with no lifetime flag must not receive a retroactive guarantee.
 local storeName=require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1")
 local store=Memory.DataStoreService:GetDataStore(storeName)
 store:UpdateAsync("Player_"..a.UserId,function(raw)raw.FirstStage1Reward=nil;return raw end)
 Data.Release(a);assert(Data.Load(a))
 check(session(a).Data.FirstStage1Reward.Consumed,"Legacy missing flag excluded")
 -- Lost acknowledgements cannot duplicate the new Stone claim.
 fresh(a);session(a).Data.TimeRewards.ElapsedSeconds=60;session(a).TimeRewardClock=os.clock()
 Memory.FailAfter=1
 local claimed,claimCode=Time.Claim(a,"StoneIntro01")
 check(not claimed and claimCode=="Pending","Ambiguous time reward write retained")
 assert(Data.ResolveItemMutation(a))
 check(ores(a)==1 and session(a).Data.TimeRewards.Claimed.StoneIntro01,"Time retry confirms exactly one Stone")
 -- Reserve at defeat; a regular save may resolve it before the drop queue resumes.
 local id=game.HttpService:GenerateGUID(false)
 Run.Reset(a,true);check(Data.ReserveFirstStage1Defeat(a,id,false),"First defeat reservation")
 Memory.FailAfter=1
 local resolved,reason=Data.ResolveFirstStage1Defeat(a,id)
 check(not resolved and reason=="InventorySavePending","Ambiguous boss write retained")
 assert(Data.Save(a))
 local confirmed,confirmation=Data.ResolveFirstStage1Defeat(a,id)
 check(confirmed and confirmation=="Applied" and ores(a)==2,"Save flush plus queue replay confirms one boss Stone")
 reload(a);check(ores(a)==2 and session(a).Data.FirstStage1Reward.Consumed,"Retried awards persist together")
 -- A full Battle Bag keeps the existing discard rule and consumes the first kill.
 fresh(b)
 local bagId=Run.Reset(b,true)
 for i=1,Run.GetCapacity(b) do assert(Run.TryAddDrop(b,bagId,"bag-"..i,itemId)) end
 local fullRun={RunInventoryId=bagId,Defeated={[1]=true}}
 local full,fullCode=Drops.OnEnemyDefeated(b,1,fullRun,1)
 check(full and fullCode=="Discarded","Full bag discards replacement")
 assert(waitFor(function()return session(b).Data.FirstStage1Reward.Consumed end,8))
 check(ores(b)==0 and not session(b).Data.FirstStage1Reward.OreGranted,"No full-bag extra ore")
 Run.Invalidate(b);reload(b)
 check(session(b).Data.FirstStage1Reward.Consumed,"Return/reset cannot restore consumed guarantee")
 report.MemoryWrites=Memory.Writes;report.Passed=true
end,debug.traceback)
if not ok then report.Error=err;report.Passed=false end
finish()
