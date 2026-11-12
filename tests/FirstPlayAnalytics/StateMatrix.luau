-- Controlled service-state simulations. Not a substitute for native walking/GUI routes.
-- Run in an isolated native Script with Context and a dependency-injected service copy.
return function(A,F,T)
 local result={Checks={},Cases={}}
 local nextId=-1000
 local function check(name,ok)
  table.insert(result.Checks,{Name=name,Passed=not not ok});assert(ok,name)
 end
 local function player(kind)
  nextId-=1
  local attrs,signals={},{}
  local p={UserId=nextId,Parent=F.Players,AtMerge=true}
  function p:GetAttribute(k)return attrs[k]end
  function p:SetAttribute(k,v)attrs[k]=v;if signals[k]then signals[k]:Fire()end end
  function p:GetAttributeChangedSignal(k)signals[k]=signals[k]or Instance.new('BindableEvent');return signals[k].Event end
  p.CharacterAdded=Instance.new('BindableEvent').Event
  local dead=Instance.new('BindableEvent')
  local h={Health=100,Died=dead.Event}
  local c={HumanoidRootPart={Anchored=false},Attrs={SpawnPlacementRevision=1,SpawnEngineReady=true,MuscleScaleReady=true,LobbySpawnPlaced=true}}
  function c:FindFirstChildOfClass()return h end
  function c:FindFirstChild(k)return self[k]end
  function c:WaitForChild()return h end
  function c:GetAttribute(k)return self.Attrs[k]end
  p.Character=c;p.Death=dead
  p.State={Loaded=true,ForgeToken='token',PetViewGeneration=0,Data={OwnedOres={}}}
  A.Join(p);if kind then A.Loaded(p,p.State.Data,kind)end
  A.Placed(p,c,1)
  table.insert(result.Cases,{Id=p.UserId,Kind=kind or 'LoadFailed'})
  return p
 end
 local function events(p,name,detail)
  task.wait();local rows={}
  for _,e in T.StudioRecords()do if e.UserId==p.UserId and (not name or e.Name==name)and(not detail or e.Fields.CustomField03==detail)then table.insert(rows,e)end end
  return rows
 end
 local function steps(p,name,n)
  local rows=events(p,name);if #rows~=n then return false end
  for i,e in rows do if e.Step~=i then return false end end;return true
 end
 local function ready(p)A.Playable(p,p.Character,1)end
 local function view(p,sequence,open,materials)
  return {Session=p:GetAttribute('MTFSession'),Character=p.Character,Sequence=sequence or 1,Open=open~=false,
   Token='token',Generation=0,Materials=materials or {ORE_001=2}}
 end
 local function eligible(p)p.State.Data.OwnedOres={ORE_001=2};A.CheckOre(p)end
 for _,kind in {'New','Existing','Unknown'}do
  local p=player(kind);ready(p);ready(p);eligible(p)
  for i=2,6 do A.Combat(p,1,1,i);A.Combat(p,1,1,i)end
  check(kind..' Entry exactly once',steps(p,'MTF_Entry_v1',3))
  check(kind..' Combat cohort',steps(p,'MTF_FirstCombat_v1',kind=='New'and 6 or 0))
  check(kind..' Ore cohort',steps(p,'MTF_FirstOreMerge_v1',kind=='New'and 1 or 0))
  A.Leaving(p)
 end
 for stop=1,3 do
  local p=player(stop>=2 and 'New' or nil);if stop==3 then ready(p)end
  if stop==1 then A.LoadFailed(p)end
  A.Leaving(p);A.Loaded(p,p.State.Data,'New');ready(p)
  check('Entry exit after '..stop,steps(p,'MTF_Entry_v1',stop))
 end
 for stop=1,6 do
  local p=player('New');ready(p)
  for i=2,stop do A.Combat(p,1,1,i)end
  A.Leaving(p);A.Combat(p,1,1,6)
  check('Combat exit after '..stop,steps(p,'MTF_FirstCombat_v1',stop))
 end
 for stop=1,5 do
  local p=player('New');ready(p);eligible(p)
  if stop>=2 then A.OreView(p,view(p,1,true,{}))end
  if stop>=3 then A.OreView(p,view(p,2))end
  local op={Action='MergeOre',Id='merge',Materials={ORE_001=2},AnalyticsContext=view(p,3)}
  if stop>=4 then A.OreRequested(p,op)end
  if stop>=5 then A.OreCommitted(p,op)end
  A.Leaving(p);A.OreCommitted(p,op)
  check('Ore exit after '..stop,steps(p,'MTF_FirstOreMerge_v1',stop))
 end
 do
  local p=player('New');ready(p);A.OreView(p,view(p));check('Early view creates no eligibility',steps(p,'MTF_FirstOreMerge_v1',0))
  eligible(p);A.OreView(p,view(p,2));local op={Action='MergeOre',Id='early',Materials={ORE_001=2},AnalyticsContext=view(p,3)}
  A.OreRequested(p,op);A.OreRequested(p,op);check('Request not commit',steps(p,'MTF_FirstOreMerge_v1',4))
  A.OreCommitted(p,op);A.OreCommitted(p,op);check('Early-open refresh + duplicate exact five',steps(p,'MTF_FirstOreMerge_v1',5));A.Leaving(p)
 end
 do
  local p=player('New');ready(p);eligible(p)
  local op={Action='MergeOre',Id='request-first',Materials={ORE_001=2},AnalyticsContext=view(p,4)}
  A.OreView(p,view(p,5,false));A.OreRequested(p,op);A.OreCommitted(p,op)
  check('Captured visible request before delayed Remote',steps(p,'MTF_FirstOreMerge_v1',5));A.Leaving(p)
 end
 do
  local p=player('New');ready(p);eligible(p)
  local invalid=view(p);invalid.Session='wrong';A.OreView(p,invalid)
  invalid=view(p);invalid.Token='wrong';A.OreView(p,invalid)
  invalid=view(p);invalid.Character={};A.OreView(p,invalid)
  invalid=view(p);invalid.Generation=20;A.OreView(p,invalid)
  p.AtMerge=false;A.OreView(p,view(p));p.AtMerge=true
  check('Invalid session/data/character/generation/location refused',steps(p,'MTF_FirstOreMerge_v1',1))
  A.OreRequested(p,{Action='MergeOre',Id='missing',Materials={ORE_001=2}});A.OreCommitted(p,{Action='MergeOre',Id='missing'})
  check('Missing view never fabricates steps',steps(p,'MTF_FirstOreMerge_v1',1));A.Leaving(p)
 end
 do
  local p=player('New');ready(p);A.Combat(p,1,1,2);A.Skipped(p);A.Combat(p,1,1,6)
  check('StageSkip independent, no auto-completed wall steps',steps(p,'MTF_FirstCombat_v1',2)and #events(p,nil,'StageSkip')==1)
  A.Leaving(p)
  p=player('New');ready(p);A.Combat(p,1,1,6);check('Out-of-order no synthetic clear',steps(p,'MTF_FirstCombat_v1',1));A.Leaving(p)
 end
 do
  local p=player('New');ready(p);task.wait();p.Death:Fire();p.Death:Fire();task.wait()
  A.Combat(p,1,1,2);A.Combat(p,1,1,2)
  check('Death duplicates / rematch same funnel',#events(p,nil,'Death:Combat:Playable')==1 and steps(p,'MTF_FirstCombat_v1',2))
  A.Reset(p);eligible(p);A.Combat(p,1,1,3);A.Strength(p,'Manual');check('Reset never becomes New',steps(p,'MTF_FirstCombat_v1',2)and steps(p,'MTF_FirstOreMerge_v1',0));A.Leaving(p)
 end
 for _,firstSave in {false,true}do
  local p=player('New');ready(p);A.ReturnAccepted(p,'first');A.ReturnAccepted(p,'second')
  if firstSave then A.ReturnCommitted(p,'first',false)end
  p.Character.Attrs.SpawnPlacementRevision=2;A.Placed(p,p.Character,2)
  A.ReturnCommitted(p,'second',false);A.ReturnCommitted(p,'first',false);A.ReturnCommitted(p,'first',false);A.Placed(p,p.Character,2)
  check('Return order '..tostring(firstSave),#events(p,nil,'ReturnAccepted')==1 and #events(p,nil,'ReturnLobbyArrived')==1 and #events(p,nil,'ReturnLootSaved')==1)
  A.Leaving(p)
 end
 do
  local p=player('New');ready(p);for _=1,10 do A.Strength(p,'Manual');A.AutoOn(p);A.Equipped(p,'NORMAL_01')end
  check('First action once',#events(p,nil,'Strength:Manual')==1 and #events(p,nil,'UserAutoOn')==1 and #events(p,nil,'DumbbellEquipped')==1);A.Leaving(p)
 end
 do
  T.StudioFailNext(1);local p=player('New');ready(p);task.wait()
  check('Failed first funnel send suppresses later Entry steps',steps(p,'MTF_Entry_v1',0))
  check('Failure does not stop service',steps(p,'MTF_FirstCombat_v1',1));A.Leaving(p)
 end
 result.Events=T.StudioRecords();result.Passed=true
 return result
end
