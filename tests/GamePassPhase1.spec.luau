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
 local function resume(co,...)
  local ok,delay=coroutine.resume(co,...);assert(ok,delay)
  if coroutine.status(co)~="dead"then table.insert(queue,{co,now+(delay or 0)})end
 end
 local fakeTask={spawn=function(f,...)local co=coroutine.create(f);resume(co,...);return co end,wait=function(t)return coroutine.yield(t or .01)end}
 fakeTask.defer=fakeTask.spawn
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
 function market:UserOwnsGamePassAsync(id,pass)
  requests+=1;if failures then error("simulated API failure")end
  return ownership[id]and ownership[id][pass]==true or false
 end
 local isStudio=true;local run={IsStudio=function()return isStudio end}
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
   typeof=typeofProxy,require=function(ref)return loadModule(ref.Path)end,os={clock=function()return now end,time=function()return 0 end}}, {__index=getfenv()})
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
  function p.Character:FindFirstChildOfClass(c)return c=="Humanoid"and h or nil end
  local root=node(p.Character.Path..".HumanoidRootPart");root.AssemblyLinearVelocity=Vector3.zero
  p:SetAttribute("RebirthCount",0);p:SetAttribute("CurrentWorld",1);p:SetAttribute("Strength",0)
  sessions[p]={Loaded=true,Data={Strength=0,Level=1,LevelProgress=0,LevelCurveVersion=2,TotalStrengthEarned=0,DailyStrengthEarned=0,DailyDate="fixture-day"}}
  table.insert(playerList,p);return p,h
 end
 local p,h=player(1001);ownership[p.UserId]={}
 local pass=loadModule("ServerScriptService.Services.GamePassService")
 local strength=loadModule("ServerScriptService.Services.StrengthManager")
 local training=loadModule("ServerScriptService.Services.TrainingManager")
 -- Occupancy is an explicit fixture input. This does NOT test physics/grounding.
 training.IsPlayerInsideZone=function()return controls.Grounded end
 local auto=loadModule("ServerScriptService.Services.AutoTapService")
 local config=loadModule("ReplicatedStorage.Config.WorldPassConfig")
 local id=config.StrengthPass.GamePassId
 check(id==2089895831 and config.StrengthPass.AdditiveMultiplier==1,"pass config")
 local remote=node("ReplicatedStorage.Remotes.World1DoubleWinPrompt");remote.OnServerEvent=signal()
 function remote:FireClient()end
 local gainRemote=node("ReplicatedStorage.Remotes.StrengthGain")
 function gainRemote:FireClient(target,amount)target.LastGainMessage=amount end
 -- Source controller, including PlayerAdded and pre-existing Players startup.
 runSource("ServerScriptService.Systems.Controllers.GamePassController",Sources["ServerScriptService.Systems.Controllers.GamePassController"])
 check(p:GetAttribute("StrengthPassOwnershipStatus")=="Verified","join verified")
 check(pass.GetStrengthPassBonus(p)==0,"unowned")
 p:SetAttribute("HasStrengthPass",true);check(pass.GetStrengthPassBonus(p)==0,"attribute cannot grant")
 failures=true;pass.RefreshStrengthPass(p);check(pass.GetStrengthPassBonus(p)==0,"failure does not grant")
 failures=false;ownership[p.UserId][id]=true
 market.PromptGamePassPurchaseFinished:Fire(p,id,true)
 check(pass.GetStrengthPassBonus(p)==1,"purchase reverified")
 for _=1,3 do market.PromptGamePassPurchaseFinished:Fire(p,id,true)end
 check(pass.GetStrengthPassBonus(p)==1,"purchase duplicates cannot stack")
 failures=true;pass.RefreshStrengthPass(p);check(pass.GetStrengthPassBonus(p)==1,"verified entitlement survives transient failure");failures=false
 debugConfig.GamePassEffectsEnabled=false;check(pass.GetStrengthPassBonus(p)==0,"Studio effects gate");debugConfig.GamePassEffectsEnabled=true
 isStudio=false;local creator=player(7467238848);ownership[creator.UserId]={[id]=true};pass.RefreshStrengthPass(creator)
 check(pass.GetStrengthPassBonus(creator)==0,"creator effects gate");check(pass.GetStrengthPassBonus(p)==1,"ordinary production player");isStudio=true
 local q=player(1002);ownership[q.UserId]={[id]=false};failures=true
 players.PlayerAdded:Fire(q);local beforeRequests=requests
 for _=1,3 do pass.ScheduleStrengthPassRefresh(q,true)end
 check(requests==beforeRequests,"one pending recovery worker")
 failures=false;ownership[q.UserId][id]=true;advance(1)
 check(pass.GetStrengthPassBonus(q)==1,"recovery after unavailable ownership")
 ownership[q.UserId][id]=false;market.PromptGamePassPurchaseFinished:Fire(q,id,false)
 check(pass.GetStrengthPassBonus(q)==1,"cancel ignored")
 players.PlayerRemoving:Fire(q);q.Parent=nil;check(pass.GetStrengthPassBonus(q)==0,"leave clears entitlement")
 advance(16);q.Parent=players;ownership[q.UserId][id]=true;players.PlayerAdded:Fire(q)
 check(pass.GetStrengthPassBonus(q)==1,"rejoin revalidates once")
 local tc=loadModule("ReplicatedStorage.Config.TreadmillConfig")
 local w2=loadModule("ReplicatedStorage.Config.World2GameplayConfig")
 local tr=loadModule("ReplicatedStorage.Config.TrainingConfig")
 check(tc.Types.Premium.Multiplier==7 and w2.Treadmills[4].Multiplier==15,"premium config")
 check(tc.Types.Normal.Multiplier==1 and tc.Types.Rebirth3.Multiplier==2 and tc.Types.Rebirth7.Multiplier==3,"W1 other tiers")
 check(w2.Treadmills[1].Multiplier==5 and w2.Treadmills[2].Multiplier==7 and w2.Treadmills[3].Multiplier==12,"W2 other tiers")
 check(tr.TrainingInterval==.5 and tr.WalkInterval==.5,"intervals unchanged")
 local function machine(path)
  local m=node(path);m.Class="Model";m.Tagged=true;m.AncestryChanged=signal();local z=node(path..".Area");z.Class="Part";return m
 end
 local machines={machine("Workspace.Treadmills.Normal01"),machine("Workspace.Treadmills.Diamond01"),
  machine("Workspace.World2Map.TrainingArea.TreadmillDisplays.01"),machine("Workspace.World2Map.TrainingArea.TreadmillDisplays.07")}
 ownership[p.UserId][1982996954]=true;ownership[p.UserId][2044250678]=true
 pass.RefreshPremiumTreadmill(p,1);pass.RefreshPremiumTreadmill(p,2)
 local function delta(f)
  local before=sessions[p].Data.Strength;assert(f()~=false);local value=sessions[p].Data.Strength-before
  if value>0 then near(p.LastGainMessage,value,"gain presentation matches commit")end
  near(p:GetAttribute("Strength"),sessions[p].Data.Strength,"attribute and memory agree")
  near(sessions[p].Data.TotalStrengthEarned,sessions[p].Data.Strength,"earned accounting");return value
 end
 for _,owned in{false,true}do
  ownership[p.UserId][id]=owned;pass.RefreshStrengthPass(p)
  p:SetAttribute("CurrentWorld",1)
  local walking=delta(function()return auto.TryAutomatic(p)end);near(walking,owned and 2 or 1,"walk gain")
  table.insert(results.Gains,{Case="Walking",Owned=owned,Delta=walking})
  local manual=delta(function()return auto.HandleTap(p)end);near(manual,1,"manual tap unchanged")
  controls.Walkway=true;local before=sessions[p].Data.Strength;check(not auto.TryAutomatic(p),"passive walkway not walking");near(sessions[p].Data.Strength,before,"passive walkway unchanged");controls.Walkway=false
  for i,m in machines do
   p:SetAttribute("CurrentWorld",i<=2 and 1 or 2)
   local expected=({1,7,5,15})[i]+(owned and 1 or 0)
   check(training.StartTraining(p,m),"session accepted")
   for tick=1,3 do
    local got=delta(function()advance(.5)end);near(got,expected,"training gain")
    table.insert(results.Gains,{Case=m.Path,Owned=owned,Tick=tick,Delta=got})
   end
   training.StopTraining(p)
  end
 end
 -- Representative modifier combination uses existing VIP=1.10, potion=1.5,
 -- Training potion=+1, Rebirth count2=2. Equipment/Pet values are fixed inputs.
 controls.Dumbbell=10;controls.Aura=3;controls.Protein=2;controls.Belt=2
 controls.TrainingPotion=1;controls.StrengthPotion=1.5;controls.Pet=1.25
 p:SetAttribute("RebirthCount",2);p:SetAttribute("CurrentWorld",1)
 ownership[p.UserId][1977128286]=true;pass.RefreshShopPass(p,"VIP")
 for _,owned in{false,true}do
  ownership[p.UserId][id]=owned;pass.RefreshStrengthPass(p)
  local expected=16*2*(7+2+1+(owned and 1 or 0))*1.5*1.1*1.25
  training.StartTraining(p,machines[2]);local got=delta(function()advance(.5)end);training.StopTraining(p)
  near(got,expected,"combined modifiers and fractional gain");table.insert(results.Gains,{Case="W1Premium combined",Owned=owned,Delta=got})
  near(delta(function()return strength.AddRewardStrength(p,7)end),7,"fixed reward unchanged")
  near(strength.GetNormalTrainingGain(p,1),32,"normal reference unchanged")
 end
 local function noTick(reason,change)
  controls.Grounded=true;p:SetAttribute("CurrentWorld",1);h.Health=100
  check(training.StartTraining(p,machines[2]),reason.." start")
  local before=sessions[p].Data.Strength;change();advance(.5)
  near(sessions[p].Data.Strength,before,reason.." stops gains");check(training.GetActiveSessionCount()==0,reason.." clears session")
 end
 noTick("exit/air predicate",function()controls.Grounded=false end)
 noTick("world change",function()p:SetAttribute("CurrentWorld",2)end)
 noTick("death",function()h.Health=0;h.Died:Fire()end)
 noTick("premium ownership lost",function()ownership[p.UserId][1982996954]=false;pass.RefreshPremiumTreadmill(p,1)end)
 ownership[p.UserId][1982996954]=true;pass.RefreshPremiumTreadmill(p,1);h.Health=100;controls.Grounded=true
 check(training.StartTraining(p,machines[2]),"re-entry/revival fixture")
 check(delta(function()advance(.5)end)>0,"resumes after restored prerequisites");training.StopTraining(p)
 check(pass.GetStrengthPassBonus(p)==1,"death does not stack ownership")
 for _,v in playerList do players.PlayerRemoving:Fire(v);v.Parent=nil end
 advance(20);check(#queue==0,"workers drained on leaving")
 results.MarketplaceCalls=requests;results.LiveExternalCalls=0
 return results
end
