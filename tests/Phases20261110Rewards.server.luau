-- Install only after all persistence/payment handles are redirected to __PhaseTaskMemory.
local RS=game.ReplicatedStorage
local Memory=require(RS.__PhaseTaskMemory)
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService)
local T=require(S.TimeRewardService)
local P=require(S.PotionService)
local report={Checks={}}
local function check(value,label) assert(value,label);table.insert(report.Checks,label) end
local function waitFor(fn)
 local deadline=os.clock()+40
 repeat local result=fn();if result then return result end;task.wait(.1) until os.clock()>deadline
 error('Phase reward test timeout')
end
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function session()return D.Get(p)end
local function ready()return waitFor(function()local s=session();return s and s.Loaded and not s.Saving and not s.PendingItemMutation and s end)end
local function reload()ready();session().Dirty=true;assert(D.Save(p));D.Release(p);assert(D.Load(p));D.SetAutoTapEnabled(p,false)end
local function fresh()
 ready();if session().StudioStartOverride then D.RestoreStudioStartOverride(p)end
 assert(D.Reset(p));D.SetAutoTapEnabled(p,false);D.SetWin(p,0);assert(D.Save(p))
 session().Data.TimeRewards.ElapsedSeconds=2700;session().TimeRewardClock=os.clock()
end
local ok,err=xpcall(function()
 fresh()
 local cfg=require(RS.Config.TimeRewardConfig)
 local expected={60,120,180,300,420,600,900,1800,2700}
 for i,r in ipairs(cfg.Rewards)do check(r.ClaimOrder==i and r.RequiredSeconds==expected[i],'Schedule slot '..i)end
 local ore=require(RS.Modules.OreMerge).Evaluate({ORE_003=2},{ORE_003=2},false)
 check(ore.Total==26 and ore.Outcomes[1].Id=='NORMAL_02' and math.abs(ore.Outcomes[1].Probability-.7)<1e-12 and ore.Outcomes[2].Id=='NORMAL_03' and math.abs(ore.Outcomes[2].Probability-.3)<1e-12,'Iron26 ordinary adjacent draw70/30')
 check(T.Claim(p,'StoneIntro01') and session().Data.OwnedOres.ORE_001==2,'Stone2 actual direct grant')
 check(not T.Claim(p,'StoneIntro01') and session().Data.OwnedOres.ORE_001==2,'Stone replay no grant')
 Memory.FailAfter=1
 local success,code=T.Claim(p,'IronIntro01')
 check(not success and code=='Pending','Iron ambiguous acknowledgement retained')
 check(not T.Claim(p,'IronIntro01'),'Pending Iron replay blocked')
 assert(D.ResolveItemMutation(p))
 check(session().Data.OwnedOres.ORE_003==2,'Iron retry exactly2')
 check(not T.Claim(p,'IronIntro01') and session().Data.OwnedOres.ORE_003==2,'Iron confirmed replay blocked')
 check(T.Claim(p,'Reward03') and p:GetAttribute('Win')==3,'Win3 actual grant')
 check(not T.Claim(p,'Reward03') and p:GetAttribute('Win')==3,'Win replay no grant')
 local bag=require(S.RunInventoryService).GetSnapshot(p);check(bag==nil or bag.Count==0,'TimeReward ores bypass Battle Bag')
 check(T.Claim(p,'Reward02') and P.GetRemaining(p,'Training')>58 and P.GetRemaining(p,'Training')<=60,'Treadmill60 keeps Training internal ID')
 check(P.GetTrainingBonus(p)==1,'Treadmill additive bonus1 unchanged')
 check(T.Claim(p,'Reward04') and P.GetRemaining(p,'Strength')>178 and P.GetStrengthMultiplier(p)==1.5,'Strength180 effect unchanged')
 local before=P.GetRemaining(p,'Training')
 Memory.FailBefore=1
 success,code=T.Claim(p,'Reward07');check(not success and code=='Pending','Potion prewrite failure retained')
 assert(D.ResolveItemMutation(p))
 check(P.GetRemaining(p,'Training')>before+178 and P.GetRemaining(p,'Training')<=before+180,'Treadmill180 added once after retry')
 before=P.GetRemaining(p,'Training');check(not T.Claim(p,'Reward07') and P.GetRemaining(p,'Training')<=before,'Potion replay adds no duration')
 session().Data.TimeRewards.Claimed.Reward01=true;session().Data.TimeRewards.Claimed.Reward06=true
 reload()
 local state=T.GetState(p)
 check(state.States.Reward03=='Claimed' and state.States.Reward02=='Claimed' and state.States.Reward07=='Claimed','Moved reward IDs survive save reload')
 check(state.States.Reward05=='Ready' and state.States.Reward08=='Ready','Unclaimed moved rewards remain available')
 check(state.States.Reward01==nil and state.States.Reward06==nil and session().Data.TimeRewards.Claimed.Reward01 and session().Data.TimeRewards.Claimed.Reward06,'Retired claims retained but never applied to different slots')
 check(session().Data.OwnedOres.ORE_001==2 and session().Data.OwnedOres.ORE_003==2 and p:GetAttribute('Win')==3,'Grant and history persist together')
 fresh();session().Data.TimeRewards.Claimed={Reward01=true,Reward02=true,Reward03=true,Reward04=true,Reward05=true,Reward06=true,Reward07=true,Reward08=true,Reward09=true,StoneIntro01=true};reload()
 state=T.GetState(p)
 check(state.States.IronIntro01=='Ready' and state.States.Reward03=='Claimed','Legacy slot2 cannot mark new Iron claimed')
 fresh();report.Passed=true
end,debug.traceback)
if not ok then report.Passed=false;report.Error=err end
local result=Instance.new('StringValue');result.Name='__PhaseRewardsResult';result.Value=game.HttpService:JSONEncode(report);result.Parent=game.ServerStorage
print('[PhaseRewards]',report.Passed,report.Error or #report.Checks)
