-- Deterministic transport tests: copied production Source, fake API/clock/scheduler.
-- No Roblox Analytics calls, DataStores, Play changes or game-state writes.
return function(source)
 local result={Checks={},Cases={}}
 local function check(name,ok)assert(ok,name);table.insert(result.Checks,{Name=name,Passed=true})end
 local function fixture(ccu)
  local now=0;local pending,records={},{}
  local fail=false
  local players=table.create(ccu,true)
  local config={Enabled=true,QueuePerSession=64,StudioRecordLimit=2048}
  local api={}
  local function send(kind,p,name,step)
   if fail then fail=false;error("isolated send failure")end
   table.insert(records,{At=now,Kind=kind,Name=name,Step=step})
  end
  function api:LogCustomEvent(p,name)send("Custom",p,name)end
  function api:LogFunnelStepEvent(p,name,session,step)send("Funnel",p,name,step)end
  local fakeTask={defer=function(fn)table.insert(pending,fn)end,wait=function(dt)now+=math.max(dt or .01,.001)end}
  local env=setmetatable({game={GetService=function(_,name)
   if name=="Players"then return {GetPlayers=function()return players end}
   elseif name=="RunService"then return {IsStudio=function()return false end}
   elseif name=="AnalyticsService"then return api end
  end},script={Parent={Parent={Config={FirstPlayAnalyticsConfig=true}}}},
   require=function()return config end,task=fakeTask,os={clock=function()return now end}},{__index=getfenv()})
  local f=assert(loadstring(source));setfenv(f,env);local T=f()
  local F={T=T,Records=records,Config=config}
  function F.Flush()while #pending>0 do table.remove(pending,1)()end end
  function F.Fail()fail=true end
  function F.Time()return now end
  function F.State()return {Queue={},SendBroken={},Failed=0,Dropped=0}end
  function F.Custom(s)T.Enqueue({},s,{Kind="Custom",Name="Isolated",Value=0,Fields={}})end
  function F.Step(s,index,name)T.Enqueue({},s,{Kind="Funnel",Name=name or "MTF_FirstStage2BossDeath_v1",Session="isolated",Step=index,StepName="Step"..index,Fields={}})end
  return F
 end
 do
  local F=fixture(1);local s=F.State()
  for _=1,50 do F.Custom(s)end
  check("50-event full normal participation fits existing 64 queue",#s.Queue==50 and s.Dropped==0)
  check("Enqueue is deferred and non-blocking",#F.Records==0)
  F.Flush()
  check("Normal burst delivers without drops",#F.Records==50 and s.Dropped==0 and s.Failed==0)
  result.Cases.Normal={Events=#F.Records,QueueCapacity=64}
 end
 do
  local F=fixture(1);local s=F.State()
  for _=1,64 do F.Custom(s)end
  F.Step(s,1);F.Step(s,2)
  check("Overflow capped, first missing funnel fenced",#s.Queue==64 and s.Dropped==1 and s.SendBroken.MTF_FirstStage2BossDeath_v1==true)
  F.Flush();F.Step(s,1,"MTF_Entry_v1");F.Flush()
  check("Overflow does not block other funnels",#F.Records==65 and F.Records[65].Name=="MTF_Entry_v1"and not s.Draining)
  result.Cases.Overflow={Dropped=s.Dropped,LaterOtherFunnelDelivered=true}
 end
 do
  local F=fixture(1);local s=F.State()
  F.Fail();for i=1,5 do F.Step(s,i)end
  F.Step(s,1,"MTF_FirstOreMerge_v1");F.Flush()
  check("Thrown send is caught once without retry",s.Failed==1 and #F.Records==1)
  check("Failed Stage2 suppresses later steps, Ore still sends",F.Records[1].Name=="MTF_FirstOreMerge_v1")
  result.Cases.Failure={Failed=s.Failed,Retries=0}
 end
 for _,perPlayer in {46,50}do
  local F=fixture(20);local states={}
  for i=1,20 do local s=F.State();states[i]=s;for _=1,perPlayer do F.Custom(s)end end
  local maxQueue=0;for _,s in states do maxQueue=math.max(maxQueue,#s.Queue)end
  F.Flush()
  local dropped=0;for _,s in states do dropped+=s.Dropped;check("Stress queue drains ".._,#s.Queue==0 and not s.Draining)end
  check("Saturated shared budget uses bounded wait/drop",F.Time()>=30 and F.Time()<31 and dropped>0 and maxQueue<=64)
  check("Every stress row either sent or locally dropped",#F.Records+dropped==20*perPlayer)
  result.Cases[perPlayer==50 and "Saturation" or "BaselineSaturation"]={Players=20,Events=20*perPlayer,Sent=#F.Records,Dropped=dropped,SimulatedSeconds=F.Time(),MaxQueue=maxQueue,RatePerMinute=520}
 end
 do
  local F=fixture(1);local s=F.State();F.Config.Enabled=false;F.Custom(s);F.Step(s,1);F.Flush()
  check("Disabled analytics queues nothing",#s.Queue==0 and #F.Records==0)
 end

 for _,name in {"MTF_FirstStage2BossDeath_v1","MTF_FirstStage2BossBack_v1"}do
  local F=fixture(1);local s=F.State();F.Fail();F.Step(s,1,name);F.Step(s,2,name);F.Flush()
  check(name.." failed first step fences terminal",#F.Records==0 and s.Failed==1 and s.SendBroken[name])
  F=fixture(1);s=F.State();F.Step(s,1,name);F.Flush();F.Fail();F.Step(s,2,name);F.Flush();F.Step(s,2,name);F.Flush()
  check(name.." failed terminal is not retried",#F.Records==1 and s.Failed==1)
  F=fixture(1);s=F.State();for _=1,64 do F.Custom(s)end;F.Step(s,1,name);F.Flush();F.Step(s,2,name);F.Flush()
  check(name.." missing queued first step never backfills",#F.Records==64 and s.SendBroken[name] and s.Dropped==1)
 end
 do
  local F=fixture(1);local s=F.State();F.Fail()
  F.Step(s,1,"MTF_FirstStage2BossDeath_v1");F.Step(s,1,"MTF_FirstStage2BossBack_v1")
  F.Step(s,2,"MTF_FirstStage2BossDeath_v1");F.Step(s,2,"MTF_FirstStage2BossBack_v1");F.Flush()
  check("One new funnel failure does not poison the other",#F.Records==2 and F.Records[1].Name=="MTF_FirstStage2BossBack_v1"and F.Records[1].Step==1 and F.Records[2].Step==2)
 end
 result.Passed=true
 return result
end
