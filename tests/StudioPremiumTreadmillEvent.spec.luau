-- Explicit Edit-mode simulation. No live require, Player, DataStore, Marketplace,
-- physics, UI or external service calls. The runner supplies exact current sources.
return function(Sources)
 local results={Kind="Edit isolated simulation (not Play)",Assertions=0,Gains={}}
 local function check(v,message) results.Assertions+=1;assert(v,message)end
 local function near(a,b,message)check(math.abs(a-b)<1e-7,message..": "..tostring(a).." / "..tostring(b))end
 local function signal()
  local callbacks={}
  return {Connect=function(_,f)local c={Connected=true};function c:Disconnect()self.Connected=false end;table.insert(callbacks,{f,c});return c end,
   Fire=function(_,...)for _,pair in callbacks do if pair[2].Connected then pair[1](...)end end end}
 end
 local now,queue=0,{}
 local eventOffset=0
 local function setEventTime(t) eventOffset=t-now end
 local function resume(co,...)
  local ok,delay=coroutine.resume(co,...);assert(ok,delay)
  if coroutine.status(co)~="dead"then table.insert(queue,{co,now+(delay or 0)})end
 end
 local fakeTask={spawn=function(f,...)local co=coroutine.create(f);resume(co,...);return co end,wait=function(t)return coroutine.yield(t or .01)end}
 fakeTask.defer=fakeTask.spawn
 fakeTask.delay=function(delay,f,...)local args=table.pack(...);return fakeTask.spawn(function()fakeTask.wait(delay);f(table.unpack(args,1,args.n))end)end
 local function advance(seconds)
  local stop=now+seconds
  for _=1,1000 do
   table.sort(queue,function(a,b)return a[2]<b[2]end)
   if not queue[1]or queue[1][2]>stop then now=stop;return end
   local job=table.remove(queue,1);now=job[2];resume(job[1])
  end
  error("fixture runaway scheduler")
 end
 local nodes={}
 local function node(path)
  if nodes[path]then return nodes[path]end
  local n={Path=path,Name=path:match("[^.]+$"),Attributes={}}
  nodes[path]=n
  local parent=path:match("^(.*)%.[^.]+$");if parent then n.Parent=node(parent)end
  function n:WaitForChild(name)return node(path.."."..name)end
  function n:FindFirstChild(name)return nodes[path.."."..name]end
  function n:GetFullName()return path end
  function n:GetAttribute(k)return self.Attributes[k]end
  function n:SetAttribute(k,v)self.Attributes[k]=v end
  function n:IsA(k)return self.Class==k or(k=="BasePart"and self.Class=="Part")end
  function n:IsDescendantOf(p)local a=self.Parent;while a do if a==p then return true end;a=a.Parent end;return false end
  setmetatable(n,{__index=function(_,k)return node(path.."."..k)end})
  return n
 end
 local players=node("Players");players.PlayerAdded=signal();players.PlayerRemoving=signal();local playerList={}
 function players:GetPlayers()return playerList end
 local market=node("MarketplaceService");market.PromptGamePassPurchaseFinished=signal()
 local ownership,requests,failures={},0,false
 local ownershipHook
 local prompts={};local promptFailure=false
 function market:PromptGamePassPurchase(p,id)
  if promptFailure then error("simulated prompt failure")end
  table.insert(prompts,{Player=p,Id=id})
 end
 function market:UserOwnsGamePassAsync(id,pass)
  requests+=1;if ownershipHook then ownershipHook() end;if failures then error("simulated API failure")end
  return ownership[id]and ownership[id][pass]==true or false
 end
 local isStudio,isServer,isRunning=true,true,true
 local run={IsStudio=function()return isStudio end,IsServer=function()return isServer end,IsRunning=function()return isRunning end}
 local ws=node("Workspace");node("Workspace.Treadmills")
 local collection={HasTag=function(_,m)return m.Tagged==true end}
 local services={Players=players,MarketplaceService=market,RunService=run,Workspace=ws,CollectionService=collection,
  ReplicatedStorage=node("ReplicatedStorage"),ServerScriptService=node("ServerScriptService")}
 local gameProxy={PlaceId=126576845524886,GameId=10765181857}
 function gameProxy:GetService(name)return assert(services[name],"Forbidden service: "..name)end
 setmetatable(gameProxy,{__index=function(_,k)return services[k]end})
 local debugConfig={GamePassEffectsEnabled=true,ProductionCreatorGamePassEffectsEnabled=false,ProductionCreatorUserIds={[7467238848]=true}}
 local controls={Dumbbell=0,Aura=0,Protein=0,Belt=0,StrengthPotion=1,TrainingPotion=0,Pet=1,Lobby=true,Grounded=true}
 local sessions={};local mockModules={}
 mockModules["ServerScriptService.Config.StudioDebugConfig"]=debugConfig
 mockModules["ReplicatedStorage.Config.ShopProductConfig"]={Get=function(key)return key=="VIP"and{Kind="GamePass",PassId=1977128286,StrengthMultiplier=1.1}or nil end}
 mockModules["ServerScriptService.Services.FirstPlayAnalyticsService"]={Strength=function()end}
 mockModules["ServerScriptService.Services.DumbbellService"]={GetStrengthBonus=function()return controls.Dumbbell end}
 mockModules["ServerScriptService.Services.AuraService"]={GetStrengthBonus=function()return controls.Aura end}
 mockModules["ServerScriptService.Services.ItemService"]={GetProteinBonus=function()return controls.Protein end,GetBeltTreadmillBonus=function()return controls.Belt end}
 mockModules["ServerScriptService.Services.TrainingLobbyAreaService"]={IsInTrainingLobby=function()return controls.Lobby end}
 mockModules["ServerScriptService.Services.PotionService"]={GetStrengthMultiplier=function()return controls.StrengthPotion end,GetTrainingBonus=function()return controls.TrainingPotion end}
 mockModules["ServerScriptService.Services.PetServer"]={GetStrengthMultiplier=function()return controls.Pet end}
 mockModules["ServerScriptService.Services.PlayerActionTiming"]={CanAct=function()return true end,RecordSuccess=function()end}
 mockModules["ServerScriptService.Services.World1WalkwayService"]={IsRiding=function()return controls.Walkway==true end}
 mockModules["ServerScriptService.World.EnemyManager"]={TryAutomaticAttack=function()return false,"NoCombat"end,TryManualAttack=function()return false,"NoCombat"end}
 local function typeofProxy(x)return type(x)=="table"and rawget(x,"Class")=="Player"and"Instance"or typeof(x)end
 local modules={};local loadModule
 local function runSource(path,source,extra)
  local f=assert(loadstring(source,"="..path));local env=setmetatable({game=gameProxy,workspace=ws,script=node(path),task=fakeTask,
   typeof=typeofProxy,require=function(ref)return loadModule(ref.Path)end,os={clock=function()return now end,time=function()return 0 end},time=function()return now+eventOffset end}, {__index={
   assert=assert,error=error,pcall=pcall,xpcall=xpcall,type=type,tonumber=tonumber,tostring=tostring,
   pairs=pairs,ipairs=ipairs,next=next,select=select,rawget=rawget,rawset=rawset,
   setmetatable=setmetatable,getmetatable=getmetatable,math=math,table=table,string=string,
   Enum=Enum,Vector3=Vector3,Vector2=Vector2,Color3=Color3,CFrame=CFrame,UDim2=UDim2,UDim=UDim,
   NumberSequence=NumberSequence,NumberSequenceKeypoint=NumberSequenceKeypoint,NumberRange=NumberRange,
   ColorSequence=ColorSequence,ColorSequenceKeypoint=ColorSequenceKeypoint,
  }})
  for k,v in pairs(extra or{})do env[k]=v end
  setfenv(f,env);return f()
 end
 loadModule=function(path)
  if mockModules[path]then return mockModules[path]end
  if modules[path]then return modules[path]end
  modules[path]=runSource(path,(assert(Sources[path],"Unlisted module: "..path)));return modules[path]
 end
 local progression=loadModule("ReplicatedStorage.Modules.LevelProgression")
 local data={}
 function data.Get(p)return sessions[p]end
 function data.IsLoaded(p)return sessions[p]and sessions[p].Loaded end
 function data.IsAutoTapEnabled()return true end
 function data.GetLevelState(p)local d=sessions[p].Data;return d.Level,d.LevelProgress,d.LevelCurveVersion end
 -- Exact AddStrengthGain and RecordStrengthGain bodies from PlayerDataService.
 runSource("MemoryAdapter",Sources.MemoryMethods,{PlayerDataService=data,sessions=sessions,LevelProgression=progression,today=function()return"fixture-day"end})
 mockModules["ServerScriptService.Services.PlayerDataService"]=data
 local function player(id)
  local p=node("TestPlayers."..id);p.Class="Player";p.UserId=id;p.Parent=players
  p.Character=node("Characters."..id);local h={Health=100,MoveDirection=Vector3.new(1,0,0),Died=signal(),GetState=function()return Enum.HumanoidStateType.Running end}
  p.CharacterAdded=signal();p.CharacterRemoving=signal()
  function p:GetAttributeChangedSignal()return signal()end
  function p.Character:FindFirstChildOfClass(c)return c=="Humanoid"and h or nil end
  local root=node(p.Character.Path..".HumanoidRootPart");root.AssemblyLinearVelocity=Vector3.zero
  p:SetAttribute("RebirthCount",0);p:SetAttribute("CurrentWorld",1);p:SetAttribute("Strength",0)
  sessions[p]={Loaded=true,Data={Strength=0,Level=1,LevelProgress=0,LevelCurveVersion=2,TotalStrengthEarned=0,DailyStrengthEarned=0,DailyDate="fixture-day"}}
  table.insert(playerList,p);return p,h
 end
 local p,h=player(1001);ownership[p.UserId]={}
 local eventConfigPath="ServerScriptService.Config.World1PremiumTreadmillEventConfig"
 local eventPath="ServerScriptService.Services.World1PremiumTreadmillEvent"
 local eventConfig=table.clone(runSource(eventConfigPath,Sources[eventConfigPath]))
 mockModules[eventConfigPath]=eventConfig -- Fixture-local copy; no live Config edits.
 local event=loadModule(eventPath)
 local pass=loadModule("ServerScriptService.Services.GamePassService")
 local strength=loadModule("ServerScriptService.Services.StrengthManager")
 local training=loadModule("ServerScriptService.Services.TrainingManager")
 -- Occupancy is an explicit fixture input. This does NOT test physics/grounding.
 local occupied={}
 training.IsPlayerInsideZone=function(who,zone)
  local hum=who.Character and who.Character:FindFirstChildOfClass("Humanoid")
  return controls.Grounded and occupied[who]==zone.Parent and hum~=nil and hum.Health>0
 end
 local auto=loadModule("ServerScriptService.Services.AutoTapService")

 local schedule=loadModule("ServerScriptService.Services.World1PremiumTreadmillEventSchedule")
 check(eventConfig.Enabled and eventConfig.StartIntervalSeconds==1800 and eventConfig.OpenDurationSeconds==180 and eventConfig.SessionDurationSeconds==86400,"final prototype values")
 for cycle=0,47 do
  local start=cycle*1800
  check(schedule.At(eventConfig,true,start).Open,"open at start "..cycle)
  check(schedule.At(eventConfig,true,start+179.999).Open,"open before end "..cycle)
  check(schedule.At(eventConfig,true,start+180).State=="Waiting","closed exactly at end "..cycle)
  check(not schedule.At(eventConfig,true,start+1799.999).Open,"27-minute wait "..cycle)
 end
 check(schedule.At(eventConfig,true,86400).State=="Ended","hard cutoff")
 check(schedule.At(eventConfig,true,90000).State=="Ended","no next-day reopening")
 near(schedule.At(eventConfig,true,179.9).RemainingSeconds,.1,"fractional remaining")
 check(schedule.At(eventConfig,true,86399).NextStartAt==nil,"no next start after cutoff")
 check(not schedule.At(eventConfig,false,0).Open,"non-Studio guard")
 for _,bad in {0,-1,math.huge,0/0,"180"} do
  local c=table.clone(eventConfig);c.OpenDurationSeconds=bad
  check(not schedule.At(c,true,0).Open,"invalid config fail closed")
 end
 local bad=table.clone(eventConfig);bad.OpenDurationSeconds=1801
 check(not schedule.At(bad,true,0).Open,"duration exceeds period")
 for _,t in {-1,math.huge,0/0,"0"} do check(not schedule.At(eventConfig,true,t).Open,"invalid time fail closed") end
 local tc=loadModule("ReplicatedStorage.Config.TreadmillConfig")
 local tr=loadModule("ReplicatedStorage.Config.TrainingConfig")
 local function machine(path)
  local m=node(path);m.Class="Model";m.Tagged=true;m.AncestryChanged=signal()
  local z=node(path..".Area");z.Class="Part";return m
 end
 local machines={machine("Workspace.Treadmills.Normal01"),machine("Workspace.Treadmills.Diamond01"),
  machine("Workspace.World2Map.TrainingArea.TreadmillDisplays.01"),machine("Workspace.World2Map.TrainingArea.TreadmillDisplays.07")}
 function collection:GetTagged()return machines end
 training.Initialize()
 local premium=machines[2]
 local gainRemote=node("ReplicatedStorage.Remotes.StrengthGain")
 function gainRemote:FireClient(target,amount) target.LastGainMessage=amount end
 local function tick(who)
  local before=sessions[who].Data.Strength
  advance(.5)
  local d=sessions[who].Data
  near(d.Strength,who:GetAttribute("Strength"),"memory and attribute agree")
  near(d.Strength,d.TotalStrengthEarned,"earned accounting agrees")
  return d.Strength-before
 end
 -- Real CanUse/UpdateZoneOccupants/StartTraining -> StrengthManager -> exact memory update bodies.
 debugConfig.GamePassEffectsEnabled=false
 occupied[p]=premium
 training.UpdateZoneOccupants();training.UpdateAvailability()
 local allowed,_,why=training.CanUseTreadmill(p,premium)
 check(allowed and why=="StudioEvent","unowned usable from first open window")
 check(p:GetAttribute("TreadmillAvailable_Diamond01")==true,"existing availability UI mirror")
 check(p:GetAttribute("IsTraining")==true and training.GetActiveSessionCount()==1,"one existing loop")
 for _=1,10 do training.UpdateZoneOccupants() end
 check(#prompts==0 and requests==0,"no ownership API or purchase request during free entry")
 check(not pass.HasPremiumTreadmill(p,1) and p:GetAttribute("HasPremiumTreadmill")==nil,"no ownership/cache rewrite")
 local tapBefore=sessions[p].Data.Strength
 check(not auto.HandleTap(p) and not auto.TryAutomatic(p),"no manual/walking duplicate while riding")
 near(sessions[p].Data.Strength,tapBefore,"duplicate routes add nothing")
 local first=tick(p);near(first,7,"unowned actual memory gain")
 table.insert(results.Gains,{Case="Free; Studio effects OFF",Delta=first})
 setEventTime(179.5);near(tick(p),0,"exact 180-second award denied")
 check(not p:GetAttribute("IsTraining") and training.GetActiveSessionCount()==0,"expiry clears training loop")
 training.UpdateZoneOccupants()
 check(#prompts==1,"denied rider re-enters existing prompt path after end")
 for _=1,5 do training.UpdateZoneOccupants() end
 check(#prompts==1,"no prompt spam while still inside")
 market.PromptGamePassPurchaseFinished:Fire(p,1982996954,false)
 setEventTime(1800);training.UpdateZoneOccupants()
 check(training.GetActiveSessionCount()==1,"same standing rider resumes next window")
 near(tick(p),7,"next window uses same gain")
 local beforeFreePrompts=#prompts
 check(not pass.PromptPremiumTreadmill(p,1),"explicit access prompt suppressed during open")
 check(#prompts==beforeFreePrompts,"no explicit prompt created")
 -- Late joining/independent Player and death do not restart the server clock.
 setEventTime(1900)
 local q,qh=player(1002);ownership[q.UserId]={};occupied[q]=premium
 training.UpdateZoneOccupants();check(training.GetActiveSessionCount()==2,"two independent sessions")
 near(event.GetStatus().RemainingSeconds,80,"late join shares remaining time")
 h.Health=0;h.Died:Fire();occupied[p]=nil
 check(training.GetActiveSessionCount()==1,"death only clears that player")
 near(event.GetStatus().RemainingSeconds,80,"death does not reset clock")
 h.Health=100;occupied[p]=premium;training.UpdateZoneOccupants()
 check(training.GetActiveSessionCount()==2,"revival/re-entry resumes")
 training.StopTraining(q);occupied[q]=nil;q.Parent=nil;players.PlayerRemoving:Fire(q)
 check(training.GetActiveSessionCount()==1,"leave keeps other player active")
 -- Event -> real verified purchase uses the existing cache, never a temporary purchase marker.
 ownership[p.UserId][1982996954]=true
 market.PromptGamePassPurchaseFinished:Fire(p,1982996954,true)
 check(pass.HasPremiumTreadmill(p,1),"purchase during event independently verified")
 debugConfig.GamePassEffectsEnabled=true -- Fixture ONLY: regular authorized comparison.
 setEventTime(1979.5);near(tick(p),7,"qualified owner continues at expiry")
 training.StopTraining(p)
 -- Normal/World2 permissions are unaffected.
 ownership[p.UserId][1982996954]=false;pass.RefreshPremiumTreadmill(p,1)
 setEventTime(0)
 p:SetAttribute("CurrentWorld",2);occupied[p]=machines[4]
 check(not training.CanUseTreadmill(p,machines[4]),"W2 Premium not opened")
 occupied[p]=machines[3];check(training.CanUseTreadmill(p,machines[3]),"W2 normal retained")
 p:SetAttribute("CurrentWorld",1);occupied[p]=machines[1]
 check(training.CanUseTreadmill(p,machines[1]),"W1 normal retained")
 check(not event.IsOpenForTreadmill(machines[1]),"normal machine never event target")
 check(not event.IsOpenForTreadmill(machine("Workspace.Decoy.Diamond01")),"same-name decoy rejected")
 -- Same equipment/bonuses, paid versus temporary access; no final multiplier ceiling.
 controls.Dumbbell=10;controls.Aura=3;controls.Protein=2;controls.Belt=2
 controls.TrainingPotion=1;controls.StrengthPotion=1.5;controls.Pet=1.25
 p:SetAttribute("RebirthCount",2);occupied[p]=premium
 ownership[p.UserId][1977128286]=true;pass.RefreshShopPass(p,"VIP")
 local passId=loadModule("ReplicatedStorage.Config.WorldPassConfig").StrengthPass.GamePassId
 for _,strengthOwned in {false,true} do
  ownership[p.UserId][passId]=strengthOwned;pass.RefreshStrengthPass(p)
  local expected=16*2*(7+2+1+(strengthOwned and 1 or 0))*1.5*1.1*1.25
  local pair={}
  for _,regular in {false,true} do
   setEventTime(regular and 200 or 0)
   ownership[p.UserId][1982996954]=regular;pass.RefreshPremiumTreadmill(p,1)
   check(training.StartTraining(p,premium),"matching conditions allowed")
   local gain=tick(p);near(gain,expected,"unmodified combined calculation")
   table.insert(pair,gain)
   table.insert(results.Gains,{Case=regular and "Owned combined" or "Free combined",StrengthPass=strengthOwned,Delta=gain})
   training.StopTraining(p)
  end
  near(pair[1],pair[2],"paid/free equality")
 end
 -- Raise an existing additive input: must not cap at 7 or 8.
 controls.Belt=20;setEventTime(0);ownership[p.UserId][1982996954]=false;pass.RefreshPremiumTreadmill(p,1)
 training.StartTraining(p,premium)
 near(tick(p),16*2*(7+20+1+1)*1.5*1.1*1.25,"no new cap");training.StopTraining(p)
 -- Status/authorization guards are real service code, not client attributes.
 for _,kind in {"ConfigOff","NotStudio","Client","NotRunning","WholeEventEnded"} do
  eventConfig.Enabled=kind~="ConfigOff";isStudio=kind~="NotStudio";isServer=kind~="Client";isRunning=kind~="NotRunning"
  setEventTime(kind=="WholeEventEnded" and 86400 or 0)
  p:SetAttribute("StudioPremiumEventOpen",true);p:SetAttribute("HasPremiumTreadmill",true)
  check(not event.GetStatus().Open and not training.CanUseTreadmill(p,premium),kind.." cannot grant")
 end
 eventConfig.Enabled=true;isStudio=true;isServer=true;isRunning=true;setEventTime(0)
 check(training.CanUseTreadmill(p,premium),"new Play elapsed zero starts new session")
 debugConfig.GamePassEffectsEnabled=false;setEventTime(200)
 ownership[p.UserId][1982996954]=true;pass.RefreshPremiumTreadmill(p,1)
 check(not training.CanUseTreadmill(p,premium),"existing Studio effects OFF still enforced outside free window")
 -- Request yields from waiting into open: after-await guard prevents a stale purchase prompt.
 ownership[p.UserId][1982996954]=false;pass.RefreshPremiumTreadmill(p,1)
 setEventTime(1799.9);local savedPrompts=#prompts
 ownershipHook=function()setEventTime(1800)end
 local ok,reason=pass.PromptPremiumTreadmill(p,1,function()return true end)
 ownershipHook=nil
 check(not ok and reason=="StudioEventAccess" and #prompts==savedPrompts,"ownership yield boundary no prompt")
 setEventTime(200)
 check(pass.PromptPremiumTreadmill(p,1,function()return true end),"suppressed pending lock released")
 market.PromptGamePassPurchaseFinished:Fire(p,1982996954,false)
 -- Real routing with existing shared clock; walking/manual resumes after leaving.
 controls.Dumbbell=0;controls.Aura=0;controls.Protein=0;controls.Belt=0;controls.TrainingPotion=0
 controls.StrengthPotion=1;controls.Pet=1;p:SetAttribute("RebirthCount",0)
 occupied[p]=nil;training.UpdateZoneOccupants()
 local timing=runSource("ServerScriptService.Services.PlayerActionTiming",Sources["ServerScriptService.Services.PlayerActionTiming"])
 local proxy=mockModules["ServerScriptService.Services.PlayerActionTiming"];proxy.CanAct=timing.CanAct;proxy.RecordSuccess=timing.RecordSuccess
 advance(2);check(auto.HandleTap(p),"manual after exit")
 local afterTap=sessions[p].Data.Strength
 check(not auto.TryAutomatic(p),"manual/walking share cooldown");near(sessions[p].Data.Strength,afterTap,"no double training")
 advance(2);check(auto.TryAutomatic(p),"ordinary walking after cooldown")

 -- Existing qualifications still apply inside a free window.
 setEventTime(0);occupied[p]=premium
 sessions[p].Loaded=false;check(not training.CanUseTreadmill(p,premium),"event cannot bypass data readiness");sessions[p].Loaded=true
 p:SetAttribute("CurrentWorld",2);check(not training.CanUseTreadmill(p,premium),"event cannot bypass current World")
 p:SetAttribute("CurrentWorld",1);premium.Tagged=false;check(not training.CanUseTreadmill(p,premium),"event cannot authorize unregistered equipment");premium.Tagged=true
 controls.Grounded=false;check(not training.StartTraining(p,premium),"event cannot bypass support/occupancy predicate");controls.Grounded=true
 check(training.StartTraining(p,premium),"re-entry after valid conditions")
 p:SetAttribute("CurrentWorld",2);near(tick(p),0,"World exit rejects next award")
 check(training.GetActiveSessionCount()==0,"World exit session removed");p:SetAttribute("CurrentWorld",1)
 local short=table.clone(eventConfig);short.SessionDurationSeconds=90
 check(schedule.At(short,true,89.999).Open and schedule.At(short,true,90).State=="Ended","total cutoff truncates an open window")
 -- World2's purchase route is unchanged even while the World1 event is open.
 occupied[p]=machines[4];p:SetAttribute("CurrentWorld",2)
 local previousPrompts=#prompts
 check(pass.PromptPremiumTreadmill(p,2,function()return true end),"World2 purchase route preserved")
 check(#prompts==previousPrompts+1 and prompts[#prompts].Id==tc.GetPremiumTreadmillPassId(2),"World2 exact pass")
 market.PromptGamePassPurchaseFinished:Fire(p,tc.GetPremiumTreadmillPassId(2),false)
 occupied[p]=nil;p:SetAttribute("CurrentWorld",1)
 -- No pending training workers or modified prototype values at handoff.
 training.StopTraining(p);for _,who in playerList do players.PlayerRemoving:Fire(who);who.Parent=nil end
 advance(5);check(#queue==0,"training workers drained")
 results.LiveExternalCalls=0;results.PurchasePromptsAreMocked=#prompts
 results.ConfigAtEnd={Enabled=eventConfig.Enabled,StartIntervalSeconds=eventConfig.StartIntervalSeconds,OpenDurationSeconds=eventConfig.OpenDurationSeconds,SessionDurationSeconds=eventConfig.SessionDurationSeconds}
 results.Grounding="Mocked occupancy; NOT physical Play verification"
 results.MemoryUpdate="Exact current AddStrengthGain/RecordStrengthGain + LevelProgression in memory only"
 return results
end
