-- Add three fresh native profiles AFTER the separate boundary suite has finished.
assert(game:GetService("RunService"):IsStudio() and game.ReplicatedStorage:FindFirstChild("__W1BalanceMemory"))
local q=game.ReplicatedStorage.__W1BalanceBoundary
local S=game.ServerScriptService.Services;local D=require(S.PlayerDataService)
local T=require(S.FirstPlayAnalyticsTransport)
local ready={};q.AnalyticsReady.OnServerEvent:Connect(function(p)ready[p]=true end)
local report={Checks=0,Cases={},Kind="Sequential single-player native profiles; injected starting Strength; ordinary movement/combat/Back/Trophy; no StageSkip or synthetic analytics observations"}
local function eq(a,b,label)report.Checks+=1;assert(a==b,(label or "")..": "..tostring(a).." ~= "..tostring(b))end
local function waitFor(fn,t)
 local stop=os.clock()+(t or 30)
 repeat local v=fn();if v then return v end;task.wait(.05)until os.clock()>stop
 error("Analytics server timeout")
end
local function records(p,name)
 local out={};for _,e in T.StudioRecords()do if e.UserId==p.UserId and e.Kind=="Funnel"and(not name or e.Name==name)then table.insert(out,e)end end;return out
end
local function ask(p,action,value)
 local r=q.AnalyticsCall:InvokeClient(p,action,value);assert(r.OK,r.Value);return r.Value
end
local function complete(p,name,expected)waitFor(function()return #records(p,name)>=expected end,8);eq(#records(p,name),expected,name)end
local deathName="MTF_FirstStage2BossDeath_v1";local backName="MTF_FirstStage2BossBack_v1";local defeatName="MTF_FirstStage2Combat_v1"
for index=1,3 do
 local original={};for _,old in game.Players:GetPlayers()do original[old]=true end
 game:GetService("StudioTestService"):AddPlayers(1)
 local p=waitFor(function()
  for _,candidate in game.Players:GetPlayers()do
   if not original[candidate]and ready[candidate]and D.IsLoaded(candidate)and candidate.Character and candidate.Character:GetAttribute("LobbySpawnPlaced")then return candidate end
  end
 end,80)
 -- Remove only our completed/idle synthetic profiles from this memory-only test.
 -- Their independently owned Boss actors blocked traversal in the unrendered test.
 for old in original do old:Kick("Owned isolated verification profile complete")end
 waitFor(function()return #game.Players:GetPlayers()==1 end,20)
 task.wait(.3)
 local result={UserId=p.UserId,Order=({"DeathThenBack","BackThenDeath","DefeatBeforeLaterOutcomes"})[index],Actions={}}
 local ok,err=xpcall(function()
  eq(ask(p,"Ready").Auto,false);eq(p:GetAttribute("MTFNewFirstSession"),true)
  -- Record the normal readiness prerequisite separately, so an unrendered native
  -- client does not prevent independent Stage2 outcome checks from running.
  -- Never send a synthetic ClientPlayable observation to satisfy this check.
  local entryOK,entryError=pcall(function()complete(p,"MTF_Entry_v1",3)end)
  result.EntryReadiness={Passed=entryOK,Error=not entryOK and entryError or nil,Events=records(p,"MTF_Entry_v1")}
  assert(D.AddStrengthGain(p,40));result.Actions.Stage1Damage=ask(p,"Damage",1)
  result.Actions.Stage1Back=ask(p,"Back") -- earlier ReturnAccepted must not gate Stage2 Back.
  eq(#records(p,deathName),0);eq(#records(p,backName),0)
  assert(D.AddStrengthGain(p,math.max(0,360-D.Get(p).Data.Strength)))
  if index<3 then
   local order=index==1 and{"Death","Back"}or{"Back","Death"}
   for _,action in order do
    result.Actions[action.."Damage"]=ask(p,"Damage",2)
    complete(p,deathName,action=="Back"and index==1 and 2 or 1)
    result.Actions[action]=ask(p,action)
    complete(p,action=="Death"and deathName or backName,2)
   end
   complete(p,deathName,2);complete(p,backName,2)
   result.Actions.Defeat=ask(p,"Defeat",2);complete(p,defeatName,5)
  else
   result.Actions.Defeat=ask(p,"Defeat",2);complete(p,defeatName,5)
   complete(p,deathName,1);complete(p,backName,1)
   ask(p,"Trophy",2)
   ask(p,"Damage",2);result.Actions.LaterDeath=ask(p,"Death")
   ask(p,"Damage",2);result.Actions.LaterBack=ask(p,"Back")
   task.wait(.4);eq(#records(p,deathName),1);eq(#records(p,backName),1)
  end
  -- The first AutoOn send fails; the ordinary toggle still succeeds.
  T.StudioFailNext(1);eq(ask(p,"Auto",true),true);eq(ask(p,"Auto",false),false)
  local autoRows=0
  for _,event in T.StudioRecords()do
   if event.UserId==p.UserId and event.Fields.CustomField03=="UserAutoOn"then autoRows+=1 end
  end
  eq(autoRows,0,"failed AutoOn observation is not fabricated or retried")
  waitFor(function()local session=D.Get(p);return not session.Saving and not session.PendingItemMutation end)
  eq(D.Save(p),true,"ordinary save succeeds after analytics send failure")
  result.Events=records(p)
 end,debug.traceback)
 result.Passed=ok;result.Error=not ok and err or nil;table.insert(report.Cases,result)
 T.StudioFailNext(0)
end
report.Stage2OutcomesPassed=true;report.Passed=true
for _,r in report.Cases do
 if not r.Passed then report.Stage2OutcomesPassed=false;report.Passed=false end
 if r.EntryReadiness and not r.EntryReadiness.Passed then report.Passed=false end
end
local out=Instance.new("StringValue");out.Name="AnalyticsResult";out.Value=game.HttpService:JSONEncode(report);out.Parent=q
q:SetAttribute("AnalyticsDone",true)
