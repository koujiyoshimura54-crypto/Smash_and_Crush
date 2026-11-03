-- Append to the corresponding native fixture for an isolated two-client run.

task.spawn(function()
 local multi=RS:WaitForChild("__P3QAMulti")
 local ok,result=xpcall(function()
  local states=multi:InvokeServer("Ready")
  local deadline=os.clock()+25
  repeat task.wait(.2)until #followers()==6 or os.clock()>deadline
  local first=followers();assert(#first==6,"Six real client models")
  local counts={}
  for _,f in ipairs(first)do
   counts[f.Owner]=(counts[f.Owner] or 0)+1
   local state=states[f.Owner] or states[tostring(f.Owner)]
   assert(state.Owned[f.Id]==f.Species,"Follower identity")
   local best=0;for _,v in ipairs(Pet.EquippedEntries(state))do best=math.max(best,v.Percent)end
   if f.Side==0 then assert(Pet.StrengthPercent(f.Species)==best,"Strongest center")end
  end
  for _,n in pairs(counts)do assert(n==3,"Owner isolation")end
  remote:InvokeServer("World",2);remote:InvokeServer("World",1)
  remote:InvokeServer("Death")
  task.wait(6);PC.refresh();task.wait(.5)
  assert(#Pet.EquippedEntries(PC.state())==3,"Respawn equipment")
  local endTime=os.clock()+15;repeat task.wait(.2)until #followers()==6 or os.clock()>endTime
  local second=followers();assert(#second==6,"Respawn models")
  multi:InvokeServer("RespawnReady")
  local state=multi:InvokeServer("Reset");task.wait(1);PC.refresh();task.wait(.3)
  assert(next(state.Discovered)==nil and next(PC.state().Discovered)==nil,"Reset discovery in server and client")
  assert(#Pet.EquippedEntries(PC.state())==0,"Reset equipment")
  return {Passed=true,First=first,AfterRespawn=second,WorldRoundTrip=true,ResetViewGeneration=true}
 end,debug.traceback)
 multi:InvokeServer("Report",ok and result or {Passed=false,Error=result})
end)
