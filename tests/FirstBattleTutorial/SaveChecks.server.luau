-- Fault injection against the exact production services, with memory stores only.
assert(game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local RS=game.ReplicatedStorage;local q=RS.__FirstBattleQA
local D=require(game.ServerScriptService.Services.PlayerDataService)
local F=require(game.ServerScriptService.Services.ForgeService)
local T=require(game.ServerScriptService.Services.TimeRewardService)
local Memory=require(RS.__FirstBattleMemory)
local store=Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName('PlayerData_v1'))
local report={Kind='Native services with injected memory-store failures and profiles',Checks=0,Cases={}}
local function eq(a,b,label)report.Checks+=1;assert(a==b,(label or '')..': '..tostring(a)..' ~= '..tostring(b))end
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 15)
 repeat if fn()then return end;task.wait(.05)until os.clock()>deadline
 error('Save check timeout')
end
local function clearFaults() Memory.HoldWrites=false;Memory.FailBefore=0;Memory.FailAfter=0;Memory.FailRead=0;Memory.Delay=0 end
local function run(name,fn)
 clearFaults();local ok,result=xpcall(fn,debug.traceback)
 report.Cases[#report.Cases+1]={Name=name,Passed=ok,Result=ok and result or nil,Error=not ok and result or nil}
 clearFaults();print('[FirstBattle save]',name,ok)
end
local function settled(p)
 waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and not s.PendingItemMutation and not s.FirstBattleSaveScheduled end,30)
end
local function key(p)return 'Player_'..p.UserId end
local function reset(p)
 settled(p);assert(D.Reset(p));settled(p);return D.Get(p).Data
end
local function request(p,action,materials)
 local s=F.State(p)
 return {Action=action,Materials=materials,Id=game.HttpService:GenerateGUID(false),Sequence=s.Sequence+1,Token=s.Token,Generation=s.Generation}
end
local function reload(p,raw)
 settled(p);D.Release(p)
 if raw then store:SetAsync(key(p),raw)end
 assert(D.Load(p));return D.Get(p).Data
end
local function save(p)
 settled(p);D.Get(p).Dirty=true;assert(D.Save(p));return store:GetAsync(key(p))
end
local function count(t)local n=0 for _,v in t do n+=v end return n end
local function execute(p)
 settled(p)
 local root=p.Character.HumanoidRootPart;root.Anchored=true
 local original=save(p)
 Memory.TargetKey=key(p)
 run('New acquisition atomically commits Stone and cohort before ordinary save',function()
  D.Release(p);store:RemoveAsync(key(p));assert(D.Load(p))
  local raw=store:GetAsync(key(p));eq(raw.OwnedOres.ORE_001,2);eq(raw.FirstBattleTutorial.Eligible,true)
  eq(D.Get(p).Data.AutoTapEnabled,false);eq(F.State(p).StoneSellLocked,true)
  local r=request(p,'MergeOre',{ORE_001=2});local result=F.Request(p,r);eq(result.Success,true)
  raw=store:GetAsync(key(p));eq(raw.OwnedOres.ORE_001,nil);eq(raw.OreMergeTutorial.Completed,true);eq(count(raw.OwnedDumbbells),1)
  -- Immediate departure: no ordinary save before acquiring the durable Forge result again.
  D.Release(p);assert(D.Load(p));eq(D.Get(p).Data.OwnedOres.ORE_001,nil);eq(count(D.Get(p).Data.OwnedDumbbells),1)
  eq(D.Get(p).Data.OreMergeTutorial.Completed,true)
  save(p);eq(store:GetAsync(key(p)).OwnedOres.ORE_001,nil)
 end)
 run('Read failure is not a new profile; ambiguous acquisition retries once',function()
  reset(p);D.Release(p);local writes=Memory.Writes;Memory.FailRead=1
  eq(D.Load(p),false);eq(D.IsLoaded(p),false);eq(Memory.Writes,writes)
  assert(D.Load(p));eq(D.Get(p).Data.OwnedOres.ORE_001,2)
  D.Release(p);store:RemoveAsync(key(p));Memory.FailAfter=1
  eq(D.Load(p),false);eq(D.IsLoaded(p),false);assert(D.Load(p))
  eq(store:GetAsync(key(p)).OwnedOres.ORE_001,2);eq(D.Get(p).Data.OwnedOres.ORE_001,2)
 end)
 run('Single/bulk/mixed/direct Stone sale rejected atomically; other ores remain sellable',function()
  reset(p);assert(F.GrantOre(p,'ORE_003',game.HttpService:GenerateGUID(false)))
  for _,selection in {{ORE_001=1},{ORE_001=2},{ORE_001=2,ORE_003=1}}do
   local before=F.State(p);local result=F.Request(p,request(p,'SellOre',selection))
   eq(result.Success,false);eq(result.Code,'StoneTutorialLocked');eq(F.State(p).Win,before.Win)
   eq(F.State(p).Sequence,before.Sequence);eq(F.State(p).Ores.ORE_001,2);eq(F.State(p).Ores.ORE_003,1)
  end
  eq(F.Request(p,request(p,'SellOre',{ORE_003=1})).Success,true)
  eq(F.State(p).Ores.ORE_001,2)
 end)
 run('Forge precommit failure retains protection; retry/duplicates create only once',function()
  reset(p);local r=request(p,'MergeOre',{ORE_001=2});Memory.FailBefore=1
  local result=F.Request(p,r);eq(result.Success,false);eq(F.State(p).StoneSellLocked,true)
  eq(D.Get(p).Data.OreMergeTutorial.Completed,false);eq(store:GetAsync(key(p)).OwnedOres.ORE_001,2)
  clearFaults();eq(F.Request(p,r).Success,true);eq(F.Request(p,r).Success,true)
  eq(count(D.Get(p).Data.OwnedDumbbells),1);eq(F.State(p).StoneSellLocked,false)
  assert(F.GrantOre(p,'ORE_001',game.HttpService:GenerateGUID(false)))
  eq(F.Request(p,request(p,'SellOre',{ORE_001=1})).Success,true)
  eq(reload(p).OreMergeTutorial.Completed,true)
 end)
 run('Forge acknowledgement loss, disconnect and rejoin preserve one durable result',function()
  reset(p);local r=request(p,'MergeOre',{ORE_001=2});Memory.FailAfter=1
  eq(F.Request(p,r).Success,false);local raw=store:GetAsync(key(p))
  eq(raw.OwnedOres.ORE_001,nil);eq(raw.OreMergeTutorial.Completed,true);eq(count(raw.OwnedDumbbells),1)
  eq(F.State(p).StoneSellLocked,true) -- Unconfirmed client/session stays locked.
  D.Release(p);assert(D.Load(p));eq(F.State(p).StoneSellLocked,false);eq(count(D.Get(p).Data.OwnedDumbbells),1)
  eq(F.Request(p,r).Success,false) -- Old session token cannot consume twice.
  save(p);eq(store:GetAsync(key(p)).OwnedOres.ORE_001,nil)
 end)
 run('Held Forge write rejects spam; disconnect while yielding cannot roll back new owner',function()
  reset(p);local r=request(p,'MergeOre',{ORE_001=2});Memory.HoldWrites=true;local done=false
  task.spawn(function()F.Request(p,r);done=true end)
  waitFor(function()return D.IsSaving(p)end)
  local duplicate=F.Request(p,r);eq(duplicate.Success,false);eq(F.State(p).StoneSellLocked,true)
  D.Release(p);Memory.HoldWrites=false;waitFor(function()return done end)
  assert(D.Load(p));eq(D.Get(p).Data.OwnedOres.ORE_001,2);eq(count(D.Get(p).Data.OwnedDumbbells),0)
  eq(F.Request(p,request(p,'MergeOre',{ORE_001=2})).Success,true)
  eq(count(D.Get(p).Data.OwnedDumbbells),1)
 end)
 run('Normal save retries cannot resurrect consumed initial Stone',function()
  reset(p);eq(F.Request(p,request(p,'MergeOre',{ORE_001=2})).Success,true)
  Memory.FailBefore=1;eq(D.Save(p),false);clearFaults();assert(D.Save(p))
  Memory.FailAfter=1;D.Get(p).Dirty=true;eq(D.Save(p),false);clearFaults();assert(D.Save(p))
  eq(reload(p).OwnedOres.ORE_001,nil);eq(count(D.Get(p).Data.OwnedDumbbells),1)
 end)
 run('Existing missing-cohort records preserve ores and have no new lock',function()
  reset(p);local raw=save(p);raw.FirstBattleTutorial=nil;raw.OwnedOres={ORE_001=7,ORE_003=3}
  raw.OreMergeTutorial={Version=1,Eligible=true,Completed=false}
  local d=reload(p,raw);eq(d.FirstBattleTutorial.Eligible,false);eq(d.OwnedOres.ORE_001,7);eq(F.State(p).StoneSellLocked,false)
  eq(F.Request(p,request(p,'SellOre',{ORE_001=2})).Success,true);eq(reload(p).OwnedOres.ORE_001,5)
 end)
 run('First reward 59/60s, held retry, acknowledgement loss, exactly one Win',function()
  reset(p);local s=D.Get(p);s.Data.TimeRewards.ElapsedSeconds=59;s.TimeRewardClock=os.clock()
  eq(T.Claim(p,'IntroWin02'),false);eq(s.Data.Win,0)
  s.Data.TimeRewards.ElapsedSeconds=60;s.TimeRewardClock=os.clock();Memory.FailAfter=1
  eq(T.Claim(p,'IntroWin02'),false)
  local raw=store:GetAsync(key(p));eq(raw.Win,1);eq(raw.TimeRewards.Claimed.IntroWin02,true);eq(raw.OwnedOres.ORE_001,2)
  clearFaults();assert(D.ResolveItemMutation(p));eq(s.Data.Win,1)
  eq(T.Claim(p,'IntroWin02'),false);eq(reload(p).Win,1)
 end)
 run('Both verified old first-slot IDs stay claimed after reload',function()
  for _,id in {'Reward01','StoneIntro01'}do
   reset(p);local raw=save(p);raw.TimeRewards={ElapsedSeconds=61,Claimed={[id]=true}};reload(p,raw)
   eq(T.GetState(p).States.IntroWin02,'Claimed');eq(T.Claim(p,'IntroWin02'),false)
   eq(D.Get(p).Data.Win,0);eq(D.Get(p).Data.OwnedOres.ORE_001,2)
   eq(save(p).TimeRewards.Claimed[id],true)
  end
 end)
 run('Accepted reward contents frozen through precommit retry',function()
  reset(p);local s=D.Get(p);s.Data.TimeRewards.ElapsedSeconds=60;s.TimeRewardClock=os.clock()
  local context={Id='IntroWin02',Result={RewardType='Win',Amount=1}}
  Memory.FailBefore=1;eq(D.ClaimTimeReward(p,context),false)
  context.Result.Amount=999;context.Id='Reward03';clearFaults();assert(D.ResolveItemMutation(p))
  eq(D.Get(p).Data.Win,1);eq(store:GetAsync(key(p)).TimeRewards.Claimed.IntroWin02,true)
 end)
 run('Accepted old Stone operation retains its contents across config replacement',function()
  reset(p);local s=D.Get(p);s.Data.TimeRewards.ElapsedSeconds=60;s.TimeRewardClock=os.clock()
  local config=require(RS.Config.TimeRewardConfig);local current=config.Rewards[1]
  config.Rewards[1]={Id='StoneIntro01',RequiredSeconds=60,RewardType='Ore',OreId='ORE_001',Amount=2,ClaimOrder=1}
  Memory.FailBefore=1
  local ok,result=pcall(D.ClaimTimeReward,p,{Id='StoneIntro01',Result={RewardType='Ore',OreId='ORE_001',Amount=2}})
  config.Rewards[1]=current
  assert(ok);eq(result,false);clearFaults();assert(D.ResolveItemMutation(p))
  eq(D.Get(p).Data.OwnedOres.ORE_001,4);eq(D.Get(p).Data.Win,0)
  eq(T.Claim(p,'IntroWin02'),false);eq(reload(p).TimeRewards.Claimed.StoneIntro01,true)
 end)
 run('Started without outcome survives rejoin; Back/Death/Victory are monotonic',function()
  for _,outcome in {'Death','Back','Victory'}do
   reset(p);assert(D.RecordFirstBattleFact(p,'Started'));settled(p)
   eq(reload(p).FirstBattleTutorial.FirstOutcome,nil)
   assert(D.RecordFirstBattleFact(p,outcome));settled(p)
   eq(reload(p).FirstBattleTutorial.FirstOutcome,outcome)
   assert(D.RecordFirstBattleFact(p,'Victory'));settled(p)
   local d=reload(p);eq(d.FirstBattleTutorial.FirstOutcome,outcome);eq(d.FirstBattleTutorial.Stage1Defeated,true)
  end
 end)
 run('Existing best dumbbell satisfies equipment without downgrade; facts survive retraining reload',function()
  reset(p);local raw=save(p);raw.OwnedDumbbells.NORMAL_02=1;raw.EquippedDumbbell='NORMAL_02';reload(p,raw)
  eq(F.Request(p,request(p,'MergeOre',{ORE_001=2})).Success,true)
  eq(D.Get(p).Data.EquippedDumbbell,'NORMAL_02');eq(D.Get(p).Data.EquipmentTutorial.DumbbellCompleted,true)
  assert(D.RecordFirstBattleFact(p,'Started'));assert(D.RecordFirstBattleFact(p,'Death'));settled(p)
  local d=reload(p);eq(d.OreMergeTutorial.Completed,true);eq(d.EquipmentTutorial.DumbbellCompleted,true);eq(d.FirstBattleTutorial.FirstOutcome,'Death')
 end)
 clearFaults();settled(p);reload(p,original);root.Anchored=false
 report.Finished=true;q:SetAttribute('SaveChecksDone',true)
 local out=Instance.new('StringValue');out.Name='SaveChecksResult';out.Value=game.HttpService:JSONEncode(report);out.Parent=q
end
local call=Instance.new('BindableFunction');call.Name='SaveChecks';call.Parent=q
call.OnInvoke=function()
 task.spawn(function()
  local ok,err=xpcall(function()execute(assert(game.Players:GetPlayers()[1]))end,debug.traceback)
  if not ok then clearFaults();q:SetAttribute('SaveChecksFatal',err);warn(err)end
 end)
 return 'Started memory persistence checks'
end
