-- Current Sources, synthetic timestamps and memory reloads. No real checkout or DataStore.
return function(sources)
 local checks=0
 local function eq(a,b) checks+=1;assert(a==b,tostring(a).." ~= "..tostring(b)) end
 local function near(a,b) checks+=1;assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
 local modules={RunReturn={Recover=function()end},Passes={},Reference={Get=function()return 1000 end}}
 local clock,guid=0,0
 local player,session,durable
 local attrs={}
 local Players={GetPlayerByUserId=function(_,id)if id==1 then return player end end}
 local Http={GenerateGUID=function()guid+=1;return "operation-"..guid end}
 local services={Players=Players,HttpService=Http,MarketplaceService={},RunService={IsStudio=function()return false end}}
 local RS={Config={StrengthRewardConfig="Config",LevelRequirements="Requirements"},Modules={LevelProgression="Progress"}}
 services.ReplicatedStorage=RS
 local gameStub={ReplicatedStorage=RS,PlaceId=126576845524886,GetService=function(_,name)return assert(services[name],name)end}
 local parent={StrengthRewardState="State",PlayerDataService="Data",StrengthReference="Reference",GamePassService="Passes",RunReturnPersistence="RunReturn"}
 local function load(name)
  local fn=assert(loadstring(sources[name],name))
  setfenv(fn,setmetatable({game=gameStub,script={Parent=parent},os=setmetatable({clock=function()return clock end},{__index=os}),require=function(key)return assert(modules[key],key)end},{__index=getfenv()}))
  return fn()
 end
 modules.Config=load("Config");modules.Requirements=load("Requirements");modules.Progress=load("Progress");modules.State=load("State")
 local C,S,P=modules.Config,modules.State,modules.Progress
 local Ownership=load("Ownership");local Persistence=load("Persistence")
 player={UserId=1,Parent=Players,GetAttribute=function(_,k)return attrs[k]end,SetAttribute=function(_,k,v)attrs[k]=v end}
 local failBefore,failAfter=false,false
 local store={GetAsync=function()return S.Copy(durable)end}
 function store:UpdateAsync(_,transform)
  if failBefore then failBefore=false;error("isolated pre-write failure") end
  local nextData=transform(S.Copy(durable))
  if nextData then durable=S.Copy(nextData) end
  if failAfter then failAfter=false;error("isolated lost acknowledgement") end
  return S.Copy(durable)
 end
 local function defaults()return {OwnedItems={},Strength=10.25,Level=1,LevelProgress=.375,TotalStrengthEarned=10.25,DailyStrengthEarned=10.25,DailyDate="2026-11-01"}end
 local function resolve(op)
  local active=session
  return Persistence.Resolve(player,active,op,{
   Update=function(transform)return Ownership.Update(store,"isolated",active,transform,function()return session==active end)end,
   Current=function()return session==active end,ResetToken=function()return nil end,Metadata=function()return {},{}end,
   Retry=function()active.Retry=op end,
   Grant=function(gain)
    active.Data.Strength,active.Data.Level,active.Data.LevelProgress=P.ApplyGain(active.Data,gain)
    active.Data.TotalStrengthEarned+=gain;active.Data.DailyStrengthEarned+=gain
    return active.Data.Strength
   end,
  })
 end
 modules.Data={Get=function(p)if p==player then return session end end}
 function modules.Data.CommitStrengthOperation(_,request)
  if session.PendingItemMutation then
   if session.PendingItemMutation.Id==request.Id then return resolve(session.PendingItemMutation) end
   return false,"InventorySavePending"
  end
  local op=S.Copy(request)
  local probe,_,reason=S.Apply(session.Data.StrengthRewards,op)
  if not probe then return false,reason end
  op.Before=S.Copy(session.Data);session.PendingItemMutation=op
  return resolve(op)
 end
 local Service=load("Service")
 local function login(token,now)
  local saved=Ownership.Acquire(store,"isolated",{Token=token,StrengthNow=now},defaults,function(raw)return raw or defaults()end,function()return true end)
  session={OwnerToken=token,Loaded=true,Data=S.Copy(saved)}
  return Service.View(player).Reward
 end
 local function depart(now,rate)
  durable.StrengthRewards=S.Checkpoint(durable.StrengthRewards,session.OwnerToken,now,rate,true)
  session.Data.StrengthRewards=S.Copy(durable.StrengthRewards)
 end
 local function claim(id)
  clock+=1
  return Service.Request(player,"Claim",id)
 end
 local function commit(op)return modules.Data.CommitStrengthOperation(player,op)end
 local function expectedGain(before,gain)
  local strength,level,progress=P.ApplyGain(before,gain)
  near(session.Data.Strength,strength);eq(session.Data.Level,level);near(session.Data.LevelProgress,progress)
  near(durable.Strength,strength);eq(durable.Level,level);near(durable.LevelProgress,progress)
 end
 local function receipt(id)
  return Service.ProcessReceipt({PlayerId=1,PurchaseId=id,ProductId=C.DoubleOffline.ProductId,PlaceIdWherePurchased=gameStub.PlaceId})
 end
 local function reset()durable=nil;session=nil;failBefore=false;failAfter=false;attrs={} end
 eq(login("first",0),nil)
 depart(100,1000)
 local old=login("thirty",1900);eq(old.Id,"thirty");near(old.Amount,90000)
 for _=1,3 do local view=Service.View(player);eq(view.Reward.Id,old.Id);near(view.Reward.Amount,old.Amount) end
 local same=S.Acquire(durable.StrengthRewards,"thirty",999999);near(same.Rewards.thirty.Amount,90000)
 depart(2000,1000)
 local current=login("ten",2600);eq(current.Id,"ten");near(current.Amount,30000);eq(durable.StrengthRewards.Rewards.thirty,nil)
 local before=S.Copy(session.Data)
 local stale=claim("thirty");eq(stale.Ok,false);eq(stale.Code,"RewardUnavailable");near(session.Data.Strength,before.Strength)
 eq(claim("ten").Ok,true);expectedGain(before,current.Amount)
 local after=session.Data.Strength
 for _=1,3 do eq(claim("ten").Ok,true);near(session.Data.Strength,after) end
 eq(Service.View(player).Reward,nil)
 depart(2700,1000)
 local nextReward=login("after-claimed",3300);near(nextReward.Amount,30000)
 before=S.Copy(session.Data);eq(claim(nextReward.Id).Ok,true);expectedGain(before,nextReward.Amount)
 depart(3400,1000);eq(login("zero",3400),nil);eq(next(durable.StrengthRewards.Rewards),nil)
 depart(3500,1000);near(login("capped",10700).Amount,180000)
 eq(C.Offline.MaxSeconds,3600);near(C.Offline.Efficiency,.05)

 -- Persisted old paid quotes remain recoverable without exposing old free claims.
 for _,normalFirst in ipairs({false,true}) do
  reset();login("seed",0);depart(100,1000);login("old",1900)
  eq(commit({Id="intent",Action="Prepare",ProductId=C.DoubleOffline.ProductId,RewardId="old"}),true)
  eq(commit({Id="cancel",Action="Cancel",ProductId=C.DoubleOffline.ProductId,IntentId="intent"}),true)
  if normalFirst then eq(claim("old").Ok,true) end
  depart(2000,1000);local reward=login("new",2600);eq(reward.Id,"new");near(reward.Amount,30000)
  near(durable.StrengthRewards.Pending[tostring(C.DoubleOffline.ProductId)].Amount,90000)
  eq(claim("old").Ok,false)
  local ok,why=commit({Id="new-intent",Action="Prepare",ProductId=C.DoubleOffline.ProductId,RewardId="new"})
  eq(ok,false);eq(why,"PurchasePending")
  ok,why=commit({Id="old-open",Action="Open",ProductId=C.DoubleOffline.ProductId,IntentId="intent"})
  eq(ok,false)
  before=S.Copy(session.Data)
  eq(receipt("old-paid"),Enum.ProductPurchaseDecision.PurchaseGranted)
  expectedGain(before,normalFirst and 90000 or 180000)
  near(durable.StrengthRewards.Rewards.old.Paid,180000);near(durable.StrengthRewards.Rewards.new.Paid,0)
  eq(Service.View(player).Reward.Id,"new");near(Service.View(player).Reward.Amount,30000)
  after=session.Data.Strength;eq(receipt("old-paid"),Enum.ProductPurchaseDecision.PurchaseGranted);near(session.Data.Strength,after)
  eq(commit({Id="current-intent",Action="Prepare",ProductId=C.DoubleOffline.ProductId,RewardId="new"}),true)
  before=S.Copy(session.Data);eq(receipt("new-paid"),Enum.ProductPurchaseDecision.PurchaseGranted);expectedGain(before,60000)
  after=session.Data.Strength;eq(receipt("old-paid"),Enum.ProductPurchaseDecision.PurchaseGranted);near(session.Data.Strength,after)
  depart(2700,1000);login("later",3300);eq(durable.StrengthRewards.Rewards.old,nil)
  eq(durable.StrengthRewards.Receipts["old-paid"].RewardId,"old")
  after=session.Data.Strength;eq(receipt("old-paid"),Enum.ProductPurchaseDecision.PurchaseGranted);near(session.Data.Strength,after)
 end
 reset();login("seed",0);depart(100,1000);login("paid-old",1900)
 eq(commit({Id="pending-zero",Action="Prepare",ProductId=C.DoubleOffline.ProductId,RewardId="paid-old"}),true)
 depart(2000,1000);eq(login("zero-current",2000),nil)
 eq(claim("paid-old").Ok,false);eq(Service.View(player).Reward,nil)
 before=S.Copy(session.Data);eq(receipt("late-zero"),Enum.ProductPurchaseDecision.PurchaseGranted);expectedGain(before,180000)
 eq(Service.View(player).Reward,nil)

 -- Lost save acknowledgement must neither lose nor repeat the new reward.
 reset();login("seed",0);depart(100,1000);login("save-retry",700)
 before=S.Copy(session.Data);failAfter=true
 local response=claim("save-retry");eq(response.Ok,false);eq(response.Code,"InventorySavePending")
 near(session.Data.Strength,before.Strength);near(durable.Strength,before.Strength+30000)
 eq(resolve(session.PendingItemMutation),true);expectedGain(before,30000)
 after=session.Data.Strength;eq(claim("save-retry").Ok,true);near(session.Data.Strength,after)
 depart(800,1000);local reward=login("after-retry",1400);near(reward.Amount,30000)
 before=S.Copy(session.Data);failBefore=true;eq(claim(reward.Id).Ok,false);near(durable.Strength,before.Strength)
 eq(resolve(session.PendingItemMutation),true);expectedGain(before,30000)

 -- An archived Prepared checkout cannot be opened or rebound to a new reward.
 reset();login("seed",0);depart(100,1000);login("prepared-old",1900)
 eq(commit({Id="prepared",Action="Prepare",ProductId=C.DoubleOffline.ProductId,RewardId="prepared-old"}),true)
 depart(2000,1000);login("prepared-new",2600)
 local ok,why=commit({Id="open-old",Action="Open",ProductId=C.DoubleOffline.ProductId,IntentId="prepared"})
 eq(ok,false);eq(why,"RewardUnavailable")
 eq(durable.StrengthRewards.Pending[tostring(C.DoubleOffline.ProductId)].Id,"prepared")
 return {Checks=checks,Kind="Memory reload and mock receipt dispatch through current Sources; not live rejoin, payment or production storage"}
end
