-- State/event regression against the actual client tail. No Instances, remotes,
-- DataStore calls, rendering or Play; every service/player/signal below is a table.
return function(source,FirstBattle)
 local start=assert(source:find("local function wallCleared()",1,true))
 local tail=source:sub(start)
 local prefix=[[
return function(e)
 local player,RS,RunService,workspace,script=e.player,e.RS,e.RunService,e.workspace,e.script
 local FirstBattle,Coordinator,IntroBalance=e.FirstBattle,e.Coordinator,e.IntroBalance
 local treadmillFolder,wallPrompt=e.treadmillFolder,e.wallPrompt
 local show,hide,clear,stopCache=e.show,e.hide,e.clear,e.stopCache
 local trained,enteredWall,stage1Defeated=false,false,false
 local trophy,remoteConnection,tickConnection,updateScheduler
 local wallIndex,wallCount,UPDATE_INTERVAL=1,1,.2
 local resetSequence=player:GetAttribute("TutorialResetSequence")
 local connections,characterConnections={},{}
 local task={spawn=function(fn,...) return fn(...) end,defer=function(fn,...)return fn(...)end}
]]
 local factory=assert(loadstring(prefix..tail.."\nreturn {Refresh=refresh,Destroy=function()e.script.Destroying:Fire()end}\nend"))()
 local function signal()
  local handlers={}
  local s={}
  function s:Connect(fn)
   local c={Connected=true}
   function c:Disconnect() self.Connected=false end
   table.insert(handlers,{fn=fn,c=c});return c
  end
  function s:Once(fn) local c;c=self:Connect(function(...)c:Disconnect();fn(...)end);return c end
  function s:Fire(...) for _,h in table.clone(handlers) do if h.c.Connected then h.fn(...) end end end
  return s
 end
 local function node(children)
  local n=children or {}
  function n:FindFirstChild(name)return rawget(self,name)end
  function n:WaitForChild(name)return assert(rawget(self,name),name)end
  return n
 end
 local function fixture(attrs)
  attrs=table.clone(attrs)
  local e={FirstBattle=FirstBattle,Target=nil,Position=nil,attrs=attrs}
  local changes={}
  local p={CharacterAdded=signal(),CharacterRemoving=signal()}
  function p:GetAttribute(name)return attrs[name]end
  function p:GetAttributeChangedSignal(name)changes[name]=changes[name]or signal();return changes[name]end
  function p:SetAttribute(name,value)local old=attrs[name];attrs[name]=value;if old~=value then self:GetAttributeChangedSignal(name):Fire()end end
  local function character()
   local hum={Health=100,Died=signal()}
   local c=node({HumanoidRootPart={Position=Vector3.new(0,8,150)},Humanoid=hum})
   function c:FindFirstChildOfClass(class)return class=="Humanoid" and hum or nil end
   return c
  end
  p.Character=character()
  local gui=node({MergeShopGui=node({MergeShopPanel={Visible=false}})})
  function p:FindFirstChild(name)return name=="PlayerGui" and gui or nil end
  e.player=p
  e.workspace=node({GeneratedMap=node({
   TrainingArea=node({Floor={CFrame=CFrame.new(),Size=Vector3.new(100,8,100)}}),
   BattleCorridor=node({Stage01=node({
    ["Stage1.1"]=node({Wall={Position=Vector3.new(0,4,90)}}),
    ["Stage1.5"]=node({EnemySpawn={Position=Vector3.new(0,4,150)}})
   })})
  })})
  e.treadmillFolder=node({Normal01=node({Area={Position=Vector3.new(0,8,0)}})})
  e.Coordinator={Owner=function()return e.owner end}
  e.IntroBalance={NeedsIntroTraining=function(level,strength,cleared)return not cleared and (level or 1)<2 end}
  e.wallPrompt={SetGuide=function()end,IsVisible=function()return false end,
   Handle=function()end,RequestUsing=function(_,fn)fn()end,Destroy=function()end}
  e.RunService={Heartbeat=signal()}
  e.script={Destroying=signal()}
  local remote={OnClientEvent=signal(),FireServer=function()end}
  e.RS={Remotes=node({GameRemotes=node({CombatState=remote})})}
  function e.show(kind,position)e.Target=kind;e.Position=position end
  function e.hide()e.Target=nil;e.Position=nil end
  e.clear=e.hide;e.stopCache=function()end
  e.client=factory(e)
  function e:Set(name,value)p:SetAttribute(name,value)end
  function e:Event(data)remote.OnClientEvent:Fire(data)end
  function e:Spawn(id,stage)self:Event({Type="TrophySpawn",Stage=stage or 1,Id=id or 7,CFrame=CFrame.new(5,4,150)})end
  function e:Lobby(inside)p.Character.HumanoidRootPart.Position=Vector3.new(0,8,inside and 0 or 150);self.client.Refresh()end
  function e:Respawn()
   local old=p.Character;p.CharacterRemoving:Fire(old);p.Character=character();p.CharacterAdded:Fire(p.Character)
  end
  function e:Expect(target)assert(self.Target==target,("expected %s, got %s"):format(tostring(target),tostring(self.Target)))end
  return e
 end
 local base={TutorialCompleted=false,CurrentWorld=1,Level=4,Strength=40,TutorialResetSequence=0,
  FirstBattleTutorialEligible=true,FirstBattleStarted=true,FirstBattleOutcome="Victory",FirstBattleStage1Defeated=true,
  OreTutorialCompleted=false,DumbbellEquipTutorialInitialCompleted=false}
 local function make(overrides)
  local a=table.clone(base);for k,v in overrides or {} do a[k]=v end;return fixture(a)
 end
 local results={}
 local function case(name,fn)
  local ok,err=pcall(fn);table.insert(results,{Name=name,Passed=ok,Error=not ok and tostring(err) or nil})
 end
 case("first victory, initial Trophy pending",function()local e=make();e:Spawn();e:Expect("Trophy7")end)
 case("loss then merge/equip victory: FirstBattle Complete, Trophy pending",function()
  local e=make({FirstBattleOutcome="Death",OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  assert(FirstBattle.ClientDone(e.player));e:Spawn();e:Expect("Trophy7")
 end)
 case("TrophySpawn then first receipt completion removes guide immediately",function()
  local e=make();e:Spawn();e:Expect("Trophy7");e:Set("TutorialCompleted",true);e:Expect(nil)
 end)
 case("complete cohort retains no Trophy guide on repeat Stage1 defeat",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Event({Type="EnemyDefeated",Stage=1});e:Spawn();e:Expect(nil)
 end)
 case("completion before TrophySpawn",function()
  local e=make({OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Set("TutorialCompleted",true);e:Spawn();e:Expect(nil)
 end)
 case("TrophySpawn before completion while FirstBattle Complete",function()
  local e=make({OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Spawn();e:Expect("Trophy7");e:Set("TutorialCompleted",true);e:Expect(nil);e:Spawn(8);e:Expect(nil)
 end)
 case("legacy initial unreceived Trophy preserved",function()
  local e=make({FirstBattleTutorialEligible=false});e:Spawn();e:Expect("Trophy7")
 end)
 case("legacy complete profile restored and repeated TrophySpawn",function()
  local e=make({FirstBattleTutorialEligible=false,TutorialCompleted=true});e:Spawn();e:Expect(nil)
 end)
 case("new cohort complete profile restored before first event",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true});e:Spawn();e:Expect(nil)
 end)
 case("Stage2 completion before merge/equip prevents later Stage1 guide",function()
  local e=make();e:Set("TutorialCompleted",true);e:Spawn();e:Expect(nil)
 end)
 case("completed death and respawn do not restart guide",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Spawn();e.player.Character.Humanoid.Health=0;e.player.Character.Humanoid.Died:Fire();e:Expect(nil)
  e:Respawn();e:Spawn(8);e:Expect(nil)
 end)
 case("completed World round trip and Initialize do not restart guide",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Spawn();e:Set("CurrentWorld",2);e:Set("CurrentWorld",1);e:Event({Type="Initialize",Cleared={}});e:Spawn(8);e:Expect(nil)
 end)
 case("unknown completion attribute never permits Trophy",function()
  local e=make();e:Set("TutorialCompleted",nil);e:Spawn();e:Expect(nil)
 end)
 case("unknown completion with FirstBattle Complete never permits Trophy",function()
  local e=make({OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Set("TutorialCompleted",nil);e:Spawn();e:Expect(nil)
 end)
 case("completed Battle phase does not fall back to walls",function()
  local e=make({TutorialCompleted=true,FirstBattleStage1Defeated=false,FirstBattleOutcome=false})
  e:Set("FirstBattleOutcome",nil);e:Event({Type="Initialize",Cleared={}});e:Expect(nil)
 end)
 case("completed Train phase does not fall back to treadmill",function()
  local e=make({TutorialCompleted=true,FirstBattleStage1Defeated=false,FirstBattleOutcome=false,Level=1})
  e:Set("FirstBattleOutcome",nil);e:Event({Type="Initialize",Cleared={}});e:Expect(nil)
 end)
 case("completed initial receipt still permits pending Merge",function()
  local e=make({TutorialCompleted=true});e:Set("OreTutorialTarget",Vector3.new(10,4,0));e:Lobby(true);e:Expect("OreMerge")
 end)
 case("completed initial receipt retains Equip branch",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true});e:Lobby(true);e:Expect(nil)
  assert(FirstBattle.Phase(FirstBattle.Read(e.player),{World=1,Alive=true,InLobby=true,Merged=true,Equipped=false})=="Equip")
 end)
 for _,row in {{"EggTutorialTarget","BasicEgg"},{"PetMergeTutorialTarget","PetMerge"},{"OreTutorialTarget","OreMerge"}} do
  case("completed profile preserves later "..row[2],function()
   local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
   e:Set(row[1],Vector3.new(12,4,0));e:Spawn();e:Expect(row[2])
  end)
 end
 case("initial Trophy existing visibility gates remain",function()
  local e=make();e:Spawn();e:Expect("Trophy7");e:Set("RunReturnBusy",true);e:Expect("Trophy7")
  -- Busy is read by the existing periodic refresh, not a dedicated attribute connection.
  e.RunService.Heartbeat:Fire(.2);e:Expect(nil);e:Set("RunReturnBusy",false);e.client.Refresh();e:Expect("Trophy7")
  e:Set("CurrentWorld",2);e:Expect(nil);e:Set("CurrentWorld",1);e:Expect("Trophy7")
  e.owner={Name="OtherTutorial"};e.client.Refresh();e:Expect(nil)
 end)
 case("unmatched or removed Trophy does not create a guide",function()
  local e=make();e:Spawn(7,2);e:Expect(nil);e:Spawn();e:Expect("Trophy7")
  e:Event({Type="TrophyRemoved",Id=7});e:Expect(nil)
 end)
 case("explicit existing reset re-enables initial tutorial",function()
  local e=make({TutorialCompleted=true,OreTutorialCompleted=true,DumbbellEquipTutorialInitialCompleted=true})
  e:Spawn();e:Set("TutorialCompleted",false);e:Set("FirstBattleStage1Defeated",false)
  e:Set("FirstBattleOutcome",nil);e:Set("OreTutorialCompleted",false);e:Set("DumbbellEquipTutorialInitialCompleted",false)
  e:Set("Level",1);e:Set("TutorialResetSequence",1);e:Event({Type="Initialize",Cleared={}});e:Expect("Treadmill")
 end)
 local passed=0;for _,r in results do if r.Passed then passed+=1 end end
 return {Passed=passed,Total=#results,Cases=results,Kind="Mocked client state/events using actual Source tail; not Play or rendered UI"}
end
