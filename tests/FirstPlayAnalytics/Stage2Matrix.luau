-- Native Luau Edit-only dependency simulations. Never starts Play or sends analytics.
-- sources={Service=...,Baseline=...,Transport=...,LegacyMatrix=...}; deps are pure Ore/Merge/Counts.
return function(sources,deps)
 local result={Checks={},Cases={},Kind="Native Luau isolated Edit simulation; no Play/network/data writes"}
 local resources={}
 local function event()local e=Instance.new("BindableEvent");table.insert(resources,e);return e end
 local function check(name,value)assert(value,name);table.insert(result.Checks,{Name=name,Passed=true})end
 local nextId=-4000
 local function factory(serviceSource)
  local clock=1000
  local F={Players={GetPlayers=function()return {}end}}
  local incoming=event()
  local remote={OnServerEvent=incoming.Event,FireClient=function()end}
  local RS={Remotes={FindFirstChild=function()return remote end},Config={OreConfig="Ore"},Modules={OreMerge="Merge",InventoryCounts="Counts"}}
  local config={Enabled=true,QueuePerSession=64,StudioRecordLimit=2048}
  local api=setmetatable({}, {__index=function()return function()error("Unexpected real API")end end})
  local services={Players=F.Players,ReplicatedStorage=RS,HttpService={GenerateGUID=function()nextId-=1;return "isolated-"..nextId end},
   RunService={IsStudio=function()return true end},AnalyticsService=api}
  local fakeGame={PlaceVersion=559,GetService=function(_,name)return assert(services[name],name)end}
  local fakeScript={Parent={Parent={Config={FirstPlayAnalyticsConfig="Config"}},FirstPlayAnalyticsTransport="Transport",PlayerDataService="Data"}}
  local bindings={Config=config,Ore=deps.Ore,Merge=deps.Merge,Counts=deps.Counts,Data={Get=function(p)return p.State end,HasReachedWorld2=function()return false end}}
  local environment=setmetatable({game=fakeGame,script=fakeScript,os={clock=function()return clock end},workspace=workspace,
   require=function(key)return assert(bindings[key],tostring(key))end},{__index=getfenv()})
  local function compile(source)local f=assert(loadstring(source));setfenv(f,environment);return f()end
  local T=compile(sources.Transport);bindings.Transport=T
  -- Existing legacy state matrix uses a logical Merge-location adapter only.
  local first=assert(serviceSource:find("local function atMerge(p)",1,true))
  local last=assert(serviceSource:find("function M.OreView",first,true))
  local testSource=serviceSource:sub(1,first-1).."local function atMerge(p)return p.AtMerge==true end\n"..serviceSource:sub(last)
  local A=compile(testSource)
  F.A=A;F.T=T;F.Remote=remote;F.Incoming=incoming
  function F.Time(t)clock=t end
  function F.Player(kind,ready)
   nextId-=1
   local attrs,signals={},{}
   local p={UserId=nextId,Parent=F.Players,AtMerge=true}
   function p:GetAttribute(k)return attrs[k]end
   function p:SetAttribute(k,v)attrs[k]=v;if signals[k]then signals[k]:Fire()end end
   function p:GetAttributeChangedSignal(k)signals[k]=signals[k]or event();return signals[k].Event end
   p.Characters=event();p.CharacterAdded=p.Characters.Event
   local function character()
    local death=event();local h={Health=100,Died=death.Event}
    local root={Anchored=false,Position=Vector3.new(-10000,10,-10000)}
    local c={HumanoidRootPart=root,Attrs={SpawnPlacementRevision=1,SpawnEngineReady=true,MuscleScaleReady=true,LobbySpawnPlaced=true}}
    function c:FindFirstChildOfClass()return h end
    function c:FindFirstChild(k)return self[k]end
    function c:WaitForChild()return h end
    function c:GetAttribute(k)return self.Attrs[k]end
    return c,h,death
   end
   p.Character,p.Humanoid,p.Death=character()
   function p:Respawn()self.Character,self.Humanoid,self.Death=character();self.Characters:Fire(self.Character)end
   p.State={Loaded=true,ForgeToken="token",PetViewGeneration=0,Data={OwnedOres={}}}
   A.Join(p);if kind then A.Loaded(p,p.State.Data,kind)end
   A.Placed(p,p.Character,1)
   if ready then A.Playable(p,p.Character,1)end
   return p
  end
  function F.Rows(p,name,detail)
   task.wait()
   local rows={}
   for _,row in T.StudioRecords()do if row.UserId==p.UserId and (not name or row.Name==name) and (not detail or row.Fields.CustomField03==detail)then table.insert(rows,row)end end
   return rows
  end
  function F.Sequence(p,name,count)
   local rows=F.Rows(p,name)
   if #rows~=count then return false end
   for i,row in rows do if row.Step~=i then return false end end
   return true
  end
  return F
 end
 local function main()
  -- Run all existing state assertions against both baseline and changed service.
  local legacyChunk=assert(loadstring(sources.LegacyMatrix))
  setfenv(legacyChunk,setmetatable({Instance={new=function(class)assert(class=="BindableEvent");return event()end}},{__index=getfenv()}))
  local legacy=legacyChunk()
  local before=factory(sources.Baseline);local old=legacy(before.A,before,before.T)
  local after=factory(sources.Service);local new=legacy(after.A,after,after.T)
  check("All existing state assertions pass unchanged",old.Passed and new.Passed and #old.Checks==#new.Checks)
  local function normalized(events)
   local rows={}
   for _,e in events do table.insert(rows,{UserId=e.UserId,Kind=e.Kind,Name=e.Name,Step=e.Step,StepName=e.StepName,Value=e.Value,Fields=e.Fields})end
   return game.HttpService:JSONEncode(rows)
  end
  check("Existing three funnels and custom event stream identical",normalized(old.Events)==normalized(new.Events))
  result.LegacyAssertions=#new.Checks
  local F=factory(sources.Service);local A=F.A
  local name="MTF_FirstStage2Combat_v1"
  local stage=workspace.GeneratedMap.BattleCorridor.Stage02
  local floor=stage.WalkableGeometry:FindFirstChild("Floor")
  local entered=floor.CFrame:PointToWorldSpace(Vector3.new(0,floor.Size.Y/2+3,0))
  local function enter(p,world)
   p.Character.HumanoidRootPart.Position=entered
   A.StagePresence(p,world or 1,p.Character.HumanoidRootPart)
  end
  local function finish(p)for index=3,6 do A.Combat(p,1,2,index)end end
  do
   local p=F.Player("New",false);local id=p:GetAttribute("MTFSession")
   check("Stage2 starts neither at join nor load",F.Sequence(p,name,0))
   F.Time(1037);enter(p);enter(p)
   for i=3,6 do F.Time(1035+i);A.Combat(p,1,2,i);A.Combat(p,1,2,i)end
   check("Normal Stage2 five steps once, independent of Merge and Playable",F.Sequence(p,name,5)and F.Sequence(p,"MTF_FirstOreMerge_v1",0)and F.Sequence(p,"MTF_FirstCombat_v1",0))
   local rows=F.Rows(p,name);local expected={"EnteredStage2","ClearedFirstWall","ClearedStage2Walls","DamagedStage2Boss","DefeatedStage2Boss"}
   for i,row in rows do
    check("Stage2 stable step/session "..i,row.StepName==expected[i]and row.Session==id and row.Fields.CustomField02=="NewFirstSession")
    local seconds=F.Rows(p,"MTF_FirstActionSeconds_v1","Stage2:"..expected[i])
    check("Join-origin elapsed seconds "..i,#seconds==1 and seconds[1].Value==(i==1 and 37 or 36+i))
   end
   A.Skipped(p);enter(p);finish(p)
   check("Completed Stage2 reaches are not emitted again after skip",#F.Rows(p,nil,"Observed:Stage2:DefeatedStage2Boss")==0 and F.Sequence(p,name,5))
   result.Cases.Normal={Steps=rows,NoMergeDependency=true}
   A.Leaving(p)
  end
  do
   local p=F.Player("New",true);enter(p);A.Combat(p,1,2,3)
   local id=p:GetAttribute("MTFSession");task.wait();p.Humanoid.Health=0;p.Death:Fire();p:Respawn();task.wait()
   A.Join(p);enter(p);A.Combat(p,1,2,3);finish(p)
   check("Death/respawn/retry retain session and completed steps",F.Sequence(p,name,5)and p:GetAttribute("MTFSession")==id)
   A.Leaving(p)
  end
  do
   local p=F.Player("New",true);enter(p);A.Combat(p,1,2,3);local id=p:GetAttribute("MTFSession")
   A.ReturnAccepted(p,"return");A.ReturnCommitted(p,"return",false)
   p.Character.HumanoidRootPart.Position=Vector3.new(-10000,10,-10000);A.StagePresence(p,1,p.Character.HumanoidRootPart)
   p.Character.Attrs.SpawnPlacementRevision=2;A.Placed(p,p.Character,2)
   enter(p);finish(p)
   check("Return/lobby/re-entry retain same participation",F.Sequence(p,name,5)and p:GetAttribute("MTFSession")==id)
   A.Leaving(p)
  end
  for _,kind in {"Existing","Unknown"}do
   local p=F.Player(kind,true);enter(p);finish(p)
   check(kind.." excluded from Stage2",F.Sequence(p,name,0));A.Leaving(p)
  end
  do
   local p=F.Player(nil,false);enter(p);finish(p);check("Unloaded excluded",F.Sequence(p,name,0));A.Leaving(p)
   p=F.Player("New",true);A.Reset(p);enter(p);finish(p);check("Reset excluded",F.Sequence(p,name,0));A.Leaving(p)
   p=F.Player("New",true);A.Loaded(p,{OwnedOres={}},"New");enter(p);finish(p);check("Reloaded different profile excluded",F.Sequence(p,name,0));A.Leaving(p)
  end
  do
   local p=F.Player("New",true)
   enter(p,2);for i=2,6 do A.Combat(p,2,2,i);A.Combat(p,1,3,i)end
   check("World2 Stage2 and other stages excluded",F.Sequence(p,name,0))
   p.Character.HumanoidRootPart.Position=Vector3.new(-10000,10,-10000)
   A.StagePresence(p,1,p.Character.HumanoidRootPart);check("Stage attribute alone does not prove entry",F.Sequence(p,name,0))
   p.Humanoid.Health=0;enter(p);p.Humanoid.Health=100;p.Character.HumanoidRootPart.Anchored=true;enter(p)
   check("Dead and anchored root rejected for Stage2 entry",F.Sequence(p,name,0))
   p.Character.HumanoidRootPart.Anchored=false;A.StagePresence(p,1,{Position=entered})
   check("Foreign root rejected",F.Sequence(p,name,0))
   F.Incoming:Fire(p,"Stage2",{Session=p:GetAttribute("MTFSession"),Step=5});task.wait()
   check("No client Stage2 step gateway",F.Sequence(p,name,0))
   enter(p);finish(p);check("World exclusion did not poison later World1 flow",F.Sequence(p,name,5));A.Leaving(p)
  end
  for _,skipAfter in {0,1,2,4}do
   local p=F.Player("New",true)
   if skipAfter>0 then enter(p)end
   for i=2,skipAfter do A.Combat(p,1,2,i+1)end
   A.Skipped(p);A.Skipped(p);enter(p);finish(p);finish(p)
   check("Skip keeps only observed normal prefix "..skipAfter,F.Sequence(p,name,skipAfter))
   check("Skip classified once "..skipAfter,#F.Rows(p,nil,"StageSkip")==1)
   for i=skipAfter+1,5 do local label=({"EnteredStage2","ClearedFirstWall","ClearedStage2Walls","DamagedStage2Boss","DefeatedStage2Boss"})[i]
    check("Skipped reach once "..skipAfter..":"..i,#F.Rows(p,nil,"Observed:Stage2:"..label)==1)
   end
   A.Leaving(p)
  end
  for missing=1,4 do
   local p=F.Player("New",true)
   if missing>1 then enter(p)end
   for i=2,missing-1 do A.Combat(p,1,2,i+1)end
   A.Combat(p,1,2,missing+2);enter(p);finish(p)
   check("Missing step never backfilled "..missing,F.Sequence(p,name,missing-1))
   check("Ordering exception once "..missing,#F.Rows(p,nil,"Stage2OutOfOrder")==1)
   A.Leaving(p)
  end
  do
   local p=F.Player("New",true);enter(p);A.Leaving(p);finish(p)
   check("Departure ends observation",F.Sequence(p,name,1))
   p=F.Player("Existing",true);enter(p);finish(p)
   check("Later join does not resume first session",F.Sequence(p,name,0));A.Leaving(p)
  end
  do
   local p=F.Player("New",true);task.wait();F.T.StudioFailNext(1);enter(p);finish(p);task.wait()
   check("Stage2 send failure suppresses later Stage2 sends",F.Sequence(p,name,0))
   p.State.Data.OwnedOres={ORE_001=2};A.CheckOre(p)
   check("Stage2 failure leaves other funnels working",F.Sequence(p,"MTF_FirstOreMerge_v1",1));A.Leaving(p)
  end
  do
   local p=F.Player("New",true)
   for i=2,6 do A.Combat(p,1,1,i)end
   enter(p);finish(p)
   p.State.Data.OwnedOres={ORE_001=2};A.CheckOre(p)
   local context={Session=p:GetAttribute("MTFSession"),Character=p.Character,Sequence=1,Open=true,Token="token",Generation=0,Materials={ORE_001=2}}
   local op={Action="MergeOre",Id="budget",Materials={ORE_001=2},AnalyticsContext=context}
   A.OreView(p,context);A.OreRequested(p,op);A.OreCommitted(p,op)
   A.Strength(p,"Manual");A.AutoOn(p);A.Equipped(p,"NORMAL_02")
   A.ReturnAccepted(p,"budget-return");A.ReturnCommitted(p,"budget-return",false)
   p.Character.Attrs.SpawnPlacementRevision=2;A.Placed(p,p.Character,2)
   task.wait();p.Death:Fire();task.wait()
   local rows=F.Rows(p)
   check("Actual service normal four funnels and auxiliaries total46",#rows==46)
   result.NormalEventBudget={BeforeStage2=36,AfterStage2=#rows,Additional=10,QueueCapacity=64}
   A.Leaving(p)
  end
  do
   local previous=factory(sources.Baseline);local current=factory(sources.Service)
   local floorCount=0
   for _,part in workspace.GeneratedMap.BattleCorridor.Stage01:GetDescendants()do
    if part:IsA("BasePart")and part.Name=="Floor"then
     local a=previous.Player("New",true);local b=current.Player("New",true)
     local position=part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y/2+3,0))
     a.Character.HumanoidRootPart.Position=position;b.Character.HumanoidRootPart.Position=position
     previous.A.StagePresence(a,1,a.Character.HumanoidRootPart);current.A.StagePresence(b,1,b.Character.HumanoidRootPart)
     check("Stage1 physical predicate unchanged "..part:GetFullName(),previous.Sequence(a,"MTF_FirstCombat_v1",2)and current.Sequence(b,"MTF_FirstCombat_v1",2))
     previous.A.Leaving(a);current.A.Leaving(b);floorCount+=1
    end
   end
   result.Stage1FloorParity=floorCount
  end
  -- All three actual Stage02 Floor instances and the Stage01 predicate stay physical.
  local floors=0
  for _,part in stage:GetDescendants()do if part:IsA("BasePart")and part.Name=="Floor"then
   local p=F.Player("New",true);p.Character.HumanoidRootPart.Position=part.CFrame:PointToWorldSpace(Vector3.new(0,part.Size.Y/2+3,0))
   A.StagePresence(p,1,p.Character.HumanoidRootPart);check("Actual floor entry "..part:GetFullName(),F.Sequence(p,name,1));A.Leaving(p);floors+=1
  end end
  result.Geometry={Stage2Floors=floors,Source="Read-only current canonical geometry"}
  result.Passed=true
 end
 local ok,err=xpcall(main,debug.traceback)
 for _,resource in resources do resource:Destroy()end
 if not ok then error(err)end
 return result
end
