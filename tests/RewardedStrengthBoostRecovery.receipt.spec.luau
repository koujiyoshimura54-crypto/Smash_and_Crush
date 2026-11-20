return function(s)
 local checks=0;local cases={}
 local function eq(a,b,label)checks+=1;assert(a==b,(label or "check")..": "..tostring(a).." ~= "..tostring(b))end
 local function load(source,env)local f=assert(loadstring(source));setfenv(f,setmetatable(env or {},{__index=getfenv()}));return f()end
 local Config=load(s.Config);local State=load(s.State)
 local Persistence=load(s.Persistence,{script={Parent={RewardedStrengthBoostState="State"}},require=function()return State end})
 local Owned=load("local M={}\n"..s.OwnedUpdate.."\nreturn M")
 local function fixture(controllerSource)
  local f={Clock=0,Queue={},Writes=0,Commits=0,Results={},Deliveries=0,Mode="ok",Stopping=false,Order=0}
  local function schedule(co,delay)f.Order+=1;table.insert(f.Queue,{Thread=co,At=f.Clock+delay,Order=f.Order})end
  function f.Spawn(fn)schedule(coroutine.create(fn),0)end
  function f.Advance(target)
   local iterations=0
   while true do
    table.sort(f.Queue,function(a,b)return a.At==b.At and a.Order<b.Order or a.At<b.At end)
    local next=f.Queue[1];if not next or next.At>target then break end
    table.remove(f.Queue,1);f.Clock=next.At;iterations+=1;assert(iterations<10000,"runaway scheduler")
    local ok,delay=coroutine.resume(next.Thread);assert(ok,delay)
    if coroutine.status(next.Thread)~="dead" then schedule(next.Thread,assert(delay))end
   end
   f.Clock=target
  end
  local taskFake={delay=function(delay,fn)schedule(coroutine.create(fn),delay)end}
  local players={};local player={UserId=123,Parent=players,Attributes={}}
  function player:SetAttribute(k,v)self.Attributes[k]=v end
  local session={Loaded=true,OwnerToken="owner-a",Data={StrengthBoost=State.Normalize(nil),Strength=71}}
  local sessions={[player]=session};local pd={}
  local disk={SessionOwnerToken="owner-a",StrengthBoost=State.Normalize(nil),Strength=71}
  local store={}
  function store:UpdateAsync(_,fn)
   f.Writes+=1
   if f.Mode=="before" then error("synthetic failure before write")end
   local value=fn(disk,nil);if value then disk=value end
   if f.Mode=="lost" then error("synthetic acknowledgement loss")end
   return value
  end
  local retry=load(s.ScheduleRetry.."\nreturn scheduleItemMutationRetry",{task=taskFake,Players=players,sessions=sessions,PlayerDataService=pd})
  function pd.ResolveItemMutation(p)
   local current=sessions[p];local op=current and current.PendingItemMutation
   if not op then return false,"NoPendingMutation" end
   return Persistence.Resolve(p,current,op,{
    Update=function(fn)return Owned.Update(store,"fixture",current,fn,function()return sessions[p]==current and p.Parent==players end)end,
    Current=function()return sessions[p]==current and current.Loaded and not current.OwnershipLost and current.PendingItemMutation==op end,
    ResetToken=function(v)return v.ResetToken end,Metadata=function()return {},{}end,
    Now=function()return 1000+f.Clock end,Retry=function()retry(p,current,op)end,
   })
  end
  load(s.Commit,{PlayerDataService=pd,sessions=sessions,BoostState=State,BoostConfig=Config,os={time=function()return 1000+f.Clock end}})
  local Controller=load(controllerSource)
  local api=Controller.New({Config=Config,IsStudio=function()return false end,
   Monotonic=function()return f.Clock end,Wait=function(t)coroutine.yield(t)end,
   Player=function(id)return id==123 and player.Parent==players and player or nil end,
   Session=function(p)return sessions[p]end,
   Commit=function(p,r)f.Commits+=1;return pd.CommitStrengthBoostReceipt(p,r)end})
  function f.Deliver(id,channel)
   f.Deliveries+=1;local key=f.Deliveries
   f.Spawn(function()f.Results[key]=api.Receipt({ProductId=Config.ProductId,PlayerId=123,PurchaseId=id,ProductPurchaseChannel=channel or Enum.ProductPurchaseChannel.AdReward})end)
   return key
  end
  function f.Later(delay,fn)taskFake.delay(delay,fn)end
  function f.Disk()return disk end
  f.Session=session;f.Player=player;f.Sessions=sessions;f.Api=api;f.Players=players
  return f
 end
 local granted=Enum.ProductPurchaseDecision.PurchaseGranted
 local pending=Enum.ProductPurchaseDecision.NotProcessedYet
 for _,kind in {"Saving","OtherMutation"}do
  local old=fixture(s.BeforeController)
  if kind=="Saving" then old.Session.Saving=true else old.Session.PendingItemMutation={Id="other"}end
  old.Deliver("one");old.Later(3,function()old.Session.Saving=false;old.Session.PendingItemMutation=nil end);old.Advance(40)
  eq(old.Deliveries,1);eq(old.Writes,0);eq(old.Results[1],pending,"before loses same-session recovery: "..kind)
  local new=fixture(s.Controller)
  if kind=="Saving" then new.Session.Saving=true else new.Session.PendingItemMutation={Id="other"}end
  new.Deliver("one");new.Advance(2);eq(new.Results[1],nil,"no acknowledgement before commit")
  eq(new.Writes,0,"no writes while blocked")
  new.Later(1,function()new.Session.Saving=false;new.Session.PendingItemMutation=nil end);new.Advance(40)
  eq(new.Deliveries,1,"no test redelivery");eq(new.Results[1],granted);eq(new.Writes,1)
  local durable=new.Disk().StrengthBoost
  eq(durable.ExpiresAt-durable.Receipts.one.GrantedAt,300)
  eq(durable.Receipts.one.GrantedAt>=1003 and durable.Receipts.one.GrantedAt<=1004,true,"recovers within one memory wait")
  eq(new.Disk().Strength,71)
  cases[kind]={Before="NotProcessedYet; zero writes after conflict cleared",After="single original delivery granted once after conflict cleared"}
 end
 local f=fixture(s.Controller);f.Session.Saving=true
 for _=1,3 do f.Deliver("same")end
 f.Deliver("other",Enum.ProductPurchaseChannel.InExperience)
 f.Later(2,function()f.Session.Saving=false end);f.Advance(40)
 for i=1,4 do eq(f.Results[i],granted)end
 eq(f.Writes,2);eq(f.Disk().StrengthBoost.ExpiresAt,1602)
 eq(f.Disk().StrengthBoost.Receipts.other.Channel,"InExperience")
 eq(f.Disk().StrengthBoost.Receipts.same.Channel,"AdReward")
 cases.ParallelAndDistinct=true
 for _,mode in {"before","lost"}do
  f=fixture(s.Controller);f.Mode=mode;f.Deliver("failure")
  f.Later(6,function()f.Mode="ok"end);f.Advance(40)
  eq(f.Deliveries,1);eq(f.Results[1],granted);eq(f.Disk().StrengthBoost.ExpiresAt,mode=="lost" and 1300 or 1307)
  eq(f.Writes,4,"existing initial + 1/2/4 retries only")
 end
 f=fixture(s.Controller);f.Mode="before";f.Deliver("long-failure")
 f.Later(80,function()f.Mode="ok"end);f.Advance(100)
 eq(f.Results[1],granted);eq(f.Deliveries,1);eq(f.Writes,8,"0/1/3/7/15 then 30/60/90")
 eq(f.Disk().StrengthBoost.ExpiresAt,1390);cases.SaveFailureRecovery=true
 for _,ending in {"Leave","OwnershipLost","Closing","Shutdown","ReplacedSession"}do
  f=fixture(s.Controller);f.Session.Saving=true;f.Deliver("cancel")
  f.Later(2,function()
   if ending=="Leave" then f.Player.Parent=nil;f.Api.Forget(f.Player)
   elseif ending=="OwnershipLost" then f.Session.OwnershipLost=true
   elseif ending=="Closing" then f.Session.StrengthClosing=true
   elseif ending=="Shutdown" then f.Api.Shutdown()
   else f.Sessions[f.Player]=nil end
  end)
  f.Advance(100);eq(f.Results[1],pending,ending);eq(f.Writes,0);eq(#f.Queue,0,"no residual receipt waits")
 end
 f=fixture(s.Controller);f.Deliver("durable");f.Advance(0);eq(f.Results[1],granted)
 f.Api.Forget(f.Player)
 f.Sessions[f.Player]={Loaded=true,OwnerToken="owner-a",Data={StrengthBoost=State.Normalize(f.Disk().StrengthBoost)}}
 f.Deliver("durable");f.Advance(10);eq(f.Results[2],granted);eq(f.Writes,1,"rejoin duplicate no write/extension")
 cases.LifecycleAndRejoin=true
 return {Assertions=checks,Cases=cases,Mode="isolated actual receipt controller/Commit/persistence/ownership + virtual saves and clock; no real receipts"}
end
