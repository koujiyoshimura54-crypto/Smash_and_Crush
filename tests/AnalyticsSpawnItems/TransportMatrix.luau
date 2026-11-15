-- Deterministic adapters; no live Analytics API and no Play claim.
return function(source)
 local checks=0
 local function check(ok,label)checks+=1;assert(ok,label)end
 for _,studio in {true,false}do
  local pending,records,warnings={},{},{}
  local config={Enabled=true,QueuePerSession=64,StudioRecordLimit=2048}
  local fail=false
  local api={}
  function api:LogCustomEvent(p,name,value,fields)
   if fail then fail=false;error("Injected API failure")end
   table.insert(records,{Name=name,Fields=fields})
  end
  function api:LogFunnelStepEvent(p,name,id,step,stepName,fields)
   if fail then fail=false;error("Injected API failure")end
   table.insert(records,{Name=name,Fields=fields,Step=step})
  end
  local env=setmetatable({game={GetService=function(_,name)
   if name=="RunService"then return {IsStudio=function()return studio end}
   elseif name=="Players"then return {GetPlayers=function()return {}end}
   elseif name=="AnalyticsService"then return api end
  end},script={Parent={Parent={Config={FirstPlayAnalyticsConfig=true}}}},require=function()return config end,
   warn=function(message)table.insert(warnings,message)end,
   task={defer=function(fn)table.insert(pending,fn)end,wait=function()error("Unexpected pacing")end},
  },{__index=getfenv()})
  local fn=assert(loadstring(source));setfenv(fn,env);local T=fn()
  local function flush()while #pending>0 do table.remove(pending,1)()end end
  local function rows()return studio and T.StudioRecords()or records end
  local function state()return {Queue={},SendBroken={},Dropped=0,Failed=0}end
  local p={UserId=-1}
  for _,key in {"CustomField01","CustomField02","CustomField03"}do
   local s=state();local before=#rows()
   T.Enqueue(p,s,{Kind="Custom",Name="Boundary50",Fields={[key]=string.rep("a",50)}})
   T.Enqueue(p,s,{Kind="Custom",Name="Boundary51",Fields={[key]=string.rep("b",51)}})
   flush()
   check(#rows()==before+1 and s.Dropped==1,"50 accepted, 51 rejected "..key)
   check(warnings[#warnings]:find(key,1,true)and warnings[#warnings]:find("Boundary51",1,true),"Diagnostic identifies event and field")
  end
  for _,bad in {true,22,string.char(255)}do
   local s=state();local before=#rows()
   T.Enqueue(p,s,{Kind="Custom",Name="BadType",Fields={CustomField03=bad}});flush()
   check(#rows()==before and s.Dropped==1,"Bad type/UTF8 rejected")
  end
  do
   local s=state();local before=#rows()
   T.Enqueue(p,s,{Kind="Funnel",Name="Broken",Step=1,Fields={CustomField03=string.rep("x",51)}})
   T.Enqueue(p,s,{Kind="Funnel",Name="Broken",Step=2,Fields={}})
   T.Enqueue(p,s,{Kind="Funnel",Name="Independent",Step=1,Fields={}})
   flush();check(#rows()==before+1 and rows()[#rows()].Name=="Independent" and s.SendBroken.Broken,"Invalid prefix fences only that funnel")
  end
  do
   local s=state();local e={Kind="Custom",Name="Snapshot",Fields={CustomField03="safe"}}
   T.Enqueue(p,s,e);e.Fields.CustomField03=string.rep("x",80);e.Name="mutated";flush()
   check(rows()[#rows()].Fields.CustomField03=="safe"and rows()[#rows()].Name=="Snapshot","Queued snapshot immutable to caller edits")
  end
  do
   local s=state();local before=#rows()
   if studio then T.StudioFailNext(1)else fail=true end
   for i=1,5 do T.Enqueue(p,s,{Kind="Funnel",Name="Failure",Step=i,Fields={}})end
   T.Enqueue(p,s,{Kind="Custom",Name="StillAlive",Fields={}});flush()
   check(s.Failed==1 and #rows()==before+1 and rows()[#rows()].Name=="StillAlive","Send failure no retry/downstream, independent event continues")
  end
  do
   local s=state();for i=1,64 do T.Enqueue(p,s,{Kind="Custom",Name="Fill",Fields={}})end
   T.Enqueue(p,s,{Kind="Funnel",Name="Full",Step=1,Fields={}})
   T.Enqueue(p,s,{Kind="Funnel",Name="Full",Step=2,Fields={}})
   check(#s.Queue==64 and s.Dropped==1 and s.SendBroken.Full,"Bounded queue fences missing prefix")
   -- Do not flush this saturated queue: pacing is covered by the existing Stage2Transport matrix.
  end
 end
 return {Passed=true,Assertions=checks,Kind="Simulated Studio and published transport branches"}
end
