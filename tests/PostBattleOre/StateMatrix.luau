-- Exact service/transport Sources with deterministic, isolated dependencies.
return function(sources,deps)
 local checks=0
 local function check(ok,label) checks+=1;assert(ok,label) end
 local function signal()
  local s={Fns={}}
  function s:Connect(fn)local c={Connected=true,Fn=fn};function c:Disconnect()self.Connected=false end;table.insert(self.Fns,c);return c end
  function s:Fire(...)for _,c in self.Fns do if c.Connected then c.Fn(...)end end end
  return s
 end
 local function fixture(source)
  local F={Clock=0,Serial=0,Pending={},API={},Studio=true}
  local remote={OnServerEvent=signal(),FireClient=function()end}
  local players={GetPlayers=function()return {}end}
  local config={Enabled=true,QueuePerSession=64,StudioRecordLimit=2048}
  local bindings={Config=config,Ore=deps.Ore,Merge=deps.Merge,Counts=deps.Counts}
  local folder={Parent={Config={FirstPlayAnalyticsConfig='Config'}},FirstPlayAnalyticsTransport='Transport',PlayerDataService='Data'}
  local rs={Config={OreConfig='Ore'},Modules={OreMerge='Merge',InventoryCounts='Counts'},Remotes={FindFirstChild=function()return remote end}}
  local api={LogFunnelStepEvent=function(_,p,name,id,n,step,fields)table.insert(F.API,{Name=name,Step=n,StepName=step,Fields=fields})end,LogCustomEvent=function()end}
  local services={Players=players,ReplicatedStorage=rs,AnalyticsService=api,
   HttpService={GenerateGUID=function()F.Serial+=1;return 'fixture-'..F.Serial end},RunService={IsStudio=function()return F.Studio end}}
  local fake={PlaceVersion=627,GetService=function(_,k)return assert(services[k],k)end}
  local tasks={spawn=function(fn,...)fn(...)end,defer=function(fn,...)table.insert(F.Pending,{fn,table.pack(...)})end,wait=function(n)F.Clock+=n or .01 end}
  local env=setmetatable({game=fake,task=tasks,os={clock=function()return F.Clock end},script={Parent=folder},
   require=function(k)return assert(bindings[k],tostring(k))end},{__index=getfenv()})
  local function compile(s)local f=assert(loadstring(s));setfenv(f,env);return f()end
  bindings.Data={Get=function(p)return p.State end,HasReachedWorld2=function()return false end}
  F.T=compile(sources.Transport);bindings.Transport=F.T
  -- Only geometry is replaced; cohort/placement/character/view/sequence gates are real.
  local a=assert(source:find('local function atMerge(p)',1,true));local b=assert(source:find('function M.OreView',a,true))
  if source:find('local function inLobby(p)',a,true)then
   b=assert(source:find('local function inLobby(p)',a,true))
   source=source:sub(1,a-1)..'local function atMerge(p)return p.AtMerge and p.Character.Humanoid.Health>0 and not p.Character.HumanoidRootPart.Anchored end\n'..source:sub(b)
   a=assert(source:find('local function inLobby(p)',1,true));b=assert(source:find('-- Called only after',a,true))
   source=source:sub(1,a-1)..'local function inLobby(p)return p.InLobby and (p:GetAttribute("CurrentWorld")or 1)==1 and p.Character.Humanoid.Health>0 and not p.Character.HumanoidRootPart.Anchored and not p:GetAttribute("RunReturnBusy")end\n'..source:sub(b)
  else source=source:sub(1,a-1)..'local function atMerge(p)return p.AtMerge end\n'..source:sub(b)end
  F.A=compile(source);F.Config=config;F.Remote=remote
  function F.Flush()while #F.Pending>0 do local row=table.remove(F.Pending,1);row[1](table.unpack(row[2],1,row[2].n))end end
  function F.Character(p)
   local c={HumanoidRootPart={Anchored=false},Humanoid={Health=100,Died=signal()},Attrs={SpawnPlacementRevision=1,SpawnEngineReady=true,MuscleScaleReady=true,LobbySpawnPlaced=true}}
   function c:FindFirstChild(k)return self[k]end
   function c:FindFirstChildOfClass()return self.Humanoid end
   function c:WaitForChild()return self.Humanoid end
   function c:GetAttribute(k)return self.Attrs[k]end
   return c
  end
  function F.Player(kind)
   F.Serial+=1;local p={UserId=-F.Serial,Parent=players,CharacterAdded=signal(),Attrs={CurrentWorld=1,CurrentStage=1},Signals={},AtMerge=true,InLobby=true,Sequence=0}
   function p:GetAttribute(k)return self.Attrs[k]end
   function p:SetAttribute(k,v)self.Attrs[k]=v;if self.Signals[k]then self.Signals[k]:Fire()end end
   function p:GetAttributeChangedSignal(k)self.Signals[k]=self.Signals[k]or signal();return self.Signals[k]end
   p.Character=F.Character(p)
   p.State={Loaded=true,ForgeToken='token',PetViewGeneration=0,Data={OwnedOres={ORE_001=2},OreMergeTutorial={Eligible=true,Completed=false},
    FirstBattleTutorial={Eligible=true,BattleStarted=false,Stage1Defeated=false}}}
   F.A.Join(p);F.A.Loaded(p,p.State.Data,kind or 'New');F.A.Placed(p,p.Character,1);F.A.Playable(p,p.Character,1);F.Flush()
   return p
  end
  function F.End(p,outcome)
   p.InLobby=false;local d=p.State.Data.FirstBattleTutorial;d.BattleStarted=true;d.FirstOutcome=d.FirstOutcome or outcome;d.Stage1Defeated=outcome=='Victory'
   if outcome=='Death'then p.Character.Humanoid.Health=0 end
   F.A.FirstBattleEnded(p,outcome);F.Flush()
  end
  function F.Return(p)
   if p.Character.Humanoid.Health<=0 then p.Character=F.Character(p);p.CharacterAdded:Fire(p.Character)end
   p.InLobby=true;p.Character.Attrs.SpawnPlacementRevision+=1
   F.A.Placed(p,p.Character,p.Character.Attrs.SpawnPlacementRevision)
  end
  function F.Payload(p,changes)
   p.Sequence+=1
   local t={Session=p:GetAttribute('MTFSession'),PostBattleToken=p:GetAttribute('MTFPostBattleToken'),Character=p.Character,Sequence=p.Sequence,
    Token='token',Generation=0,ViewRevision=1,Rendered=true,Open=false,Tab='Ore',Selling=false,GuideShown=false,Ready=true,
    HUDReady=true,ControlsReady=true,LoadingGone=true,Revision=p.Character:GetAttribute('SpawnPlacementRevision'),Materials={ORE_001=2}}
   for k,v in changes or {}do t[k]=v end
   return t
  end
  function F.View(p,changes)local v=F.Payload(p,changes);F.A.OreView(p,v);return v end
  function F.Request(p,v,id)local op={Action='MergeOre',Id=id or 'merge',Materials={ORE_001=2},AnalyticsContext=v};F.A.OreRequested(p,op);return op end
  function F.Commit(p,op)p.State.Data.OreMergeTutorial.Completed=true;F.A.OreCommitted(p,op)end
  function F.Rows(p,name)
   F.Flush();local out={}for _,e in F.T.StudioRecords()do if e.UserId==p.UserId and(not name or e.Name==name)then table.insert(out,e)end end return out
  end
  function F.Count(p)return #F.Rows(p,'MTF_FirstOreMerge_v1')end
  return F
 end
 local function fresh()local f=fixture(sources.Service);return f,f.Player()end
 local expected={'FirstBattleEnded','LobbyPlayableAfterFirstBattle','MergeGuideShown','OreViewOpened','MergeCommitted'}
 for _,outcome in {'Victory','Death','Back'}do
  local f,p=fresh();check(f.Count(p)==0,'Initial Stone alone excluded')
  f.Clock=10;f.End(p,outcome);check(f.Count(p)==1,outcome..' begins once')
  f.View(p,{GuideShown=true,Open=true});check(f.Count(p)==1,'No Lobby while fighting/dead')
  f.Return(p);f.Clock=20;f.View(p);check(f.Count(p)==2,'Fresh Lobby readiness')
  f.View(p,{GuideShown=true});check(f.Count(p)==3,'Actual guide observation')
  local v=f.View(p,{GuideShown=true,Open=true});check(f.Count(p)==4,'Ore view')
  local op=f.Request(p,v);f.Request(p,v);check(f.Count(p)==4,'Acceptance/wait/failure is not commit')
  f.Clock=30;f.Commit(p,op);f.Commit(p,op);f.A.FirstBattleEnded(p,'Victory');f.Return(p);f.View(p,{GuideShown=true,Open=true})
  local rows=f.Rows(p,'MTF_FirstOreMerge_v1');check(#rows==5,'Duplicate/respawn/rematch bounded')
  for i,e in rows do check(e.Step==i and e.StepName==expected[i],outcome..' exact order '..i)
   check(e.Fields.CustomField03=='PostFirstBattle_v2:'..outcome and e.Fields.CustomField01=='PlaceVersion:627' and e.Fields.CustomField02=='NewFirstSession','Fixed classification')end
  for _,e in f.Rows(p)do if e.Kind=='Custom'and e.Fields.CustomField03:find('PostFirstBattle_v2:',1,true)then check(e.Value>=10,'Join-relative durations')end end
 end
 for _,kind in {'Existing','Unknown','Reset','EarlyMerge','OldTutorial','Skip','Override','Rejoin','OtherWorld','NoAuthority'}do
  local f,p=fresh()
  if kind=='Existing'or kind=='Unknown'then f.A.Leaving(p);f.A.Join(p);f.A.Loaded(p,p.State.Data,kind)
  elseif kind=='Reset'then f.A.Reset(p)
  elseif kind=='EarlyMerge'then f.Commit(p,{Action='MergeOre',Id='early'})
  elseif kind=='OldTutorial'then p.State.Data.FirstBattleTutorial.Eligible=false
  elseif kind=='Skip'then f.A.Skipped(p)
  elseif kind=='Override'then p.State.StudioStartOverride=true
  elseif kind=='Rejoin'then f.A.Leaving(p);f.A.Join(p);f.A.Loaded(p,p.State.Data,'Existing')
  elseif kind=='OtherWorld'then p:SetAttribute('CurrentWorld',2)end
  if kind=='NoAuthority'then f.A.FirstBattleEnded(p,'Death')else f.End(p,'Death')end
  check(f.Count(p)==0,kind..' excluded')
 end
 do local f,p=fresh();f.End(p,'Victory');p:SetAttribute('CurrentStage',2);f.View(p,{GuideShown=true,Open=true})
  check(f.Count(p)==1,'Stage2 direct has no Lobby event or departure inference');f.Return(p);f.View(p);check(f.Count(p)==2,'Later Lobby allowed')end
 do local f,p=fresh();local old=f.Payload(p);f.End(p,'Back');p.InLobby=true;f.A.Playable(p,p.Character,1);f.A.OreView(p,old)
  check(f.Count(p)==1,'Initial ClientPlayable/pre-outcome snapshot cannot satisfy Step2')
  f.Return(p);f.View(p,{Ready=false});check(f.Count(p)==1,'Controls not ready');f.View(p);check(f.Count(p)==2,'Ready after placement')end
 do local f,p=fresh();f.End(p,'Victory');p.InLobby=true;f.View(p)
  check(f.Count(p)==2,'Fresh post-outcome rendered readiness also accepts a living walk back into Lobby')end
 for _,hidden in {'OtherMenu','GuideCompetition','NoRenderedGuide'}do local f,p=fresh();f.End(p,'Death');f.Return(p);f.View(p)
  check(f.Count(p)==2,hidden..' no Step3')end
 for _,tab in {'Item','Pet','OreSale'}do local f,p=fresh();f.End(p,'Back');f.Return(p);f.View(p,{GuideShown=true})
  f.View(p,{Open=true,Tab=tab=='OreSale'and'Ore'or tab,Selling=tab=='OreSale'});check(f.Count(p)==3,tab..' not Ore merge view')end
 for _,where in {'BeforeGuide','BeforeReady','NoView'}do
  local f,p=fresh();f.End(p,'Victory');f.Return(p)
  local v=f.View(p,{Open=where~='NoView',Ready=where~='BeforeReady'})
  local op=f.Request(p,v);f.View(p,{Open=true,GuideShown=true});f.Commit(p,op)
  check(f.Count(p)==(where=='BeforeReady'and 1 or 2),'Bypass never repairs prefix '..where)
  local seen=false;for _,e in f.Rows(p)do if e.Kind=='Custom'and e.Fields.CustomField03=='PostFirstBattle_v2:Victory:Bypass:MergeCommitted'then seen=true end end
  check(seen,'Bypass committed visible in existing custom event')
 end
 for _,field in {'Session','PostBattleToken','Character','Token','Generation','Sequence','ViewRevision','Rendered','Revision'}do
  local f,p=fresh();f.End(p,'Back');f.Return(p)
  local change={Session='old',PostBattleToken='old',Character={},Token='old',Generation=9,Sequence=0,ViewRevision=-1,Rendered=false,Revision=0}
  f.View(p,{[field]=change[field]});check(f.Count(p)==1,'Reject stale '..field)
 end
 do local f,p=fresh();f.End(p,'Back');f.Return(p);local old=f.View(p,{GuideShown=true,Open=true})
  f.View(p,{ViewRevision=2,Open=false});local op=f.Request(p,old);f.Commit(p,op);check(f.Count(p)==4,'Old closed-view context cannot commit funnel')end
 do local f,p=fresh();f.End(p,'Back');f.Return(p);local v=f.View(p,{GuideShown=true,Open=true})
  f.A.Skipped(p);local op=f.Request(p,v);f.Commit(p,op);check(f.Count(p)==4,'StageSkip blocks remaining Ore progression')end
 do local f,p=fresh();f.T.StudioFailNext(1);f.End(p,'Back');f.Return(p);local v=f.View(p,{GuideShown=true,Open=true});f.Commit(p,f.Request(p,v))
  check(f.Count(p)==0,'Failed first send prevents every downstream Ore send');check(p.State.Data.OreMergeTutorial.Completed,'Analytics failure cannot stop fixture commit')end
 do local f,p=fresh();f.Config.QueuePerSession=2
  p.State.Data.FirstBattleTutorial={Eligible=true,BattleStarted=true,FirstOutcome='Back'};f.A.FirstBattleEnded(p,'Back');f.Return(p)
  local v=f.View(p,{GuideShown=true,Open=true});f.Commit(p,f.Request(p,v));check(f.Count(p)==0,'Queue overflow fences unsent prefix')end
 do local f,p=fresh();f.Studio=false;f.Config.QueuePerSession=1024
  local session={Queue={},SendBroken={},Dropped=0,Failed=0}
  for i=1,1000 do f.T.Enqueue(p,session,{Kind='Custom',Name='fill',Fields={}})end
  for i=1,5 do f.T.Enqueue(p,session,{Kind='Funnel',Name='MTF_FirstOreMerge_v1',Step=i,StepName=expected[i],Fields={}})end
  f.Flush();check(session.SendBroken.MTF_FirstOreMerge_v1==true and #f.API==0,'Budget expiry prevents trailing-only funnel API calls')end
 -- Compare the other five funnels byte-for-byte (same synthetic identities/clock).
 local function regression(source)
  local f=fixture(source);local p=f.Player();for i=2,6 do f.A.Combat(p,1,1,i)end
  p:SetAttribute('CurrentStage',2);p:SetAttribute('RunInventoryId','run')
  for i=2,5 do f.A.Combat(p,1,2,i)end
  local c=p.Character;local h=c.Humanoid;h.Parent=c;h.Health=0
  f.A.Stage2BossHit(p,1,{Stage=2,Character=c,Humanoid=h,Enemy={},Behavior={Damage=25}},25,0)
  h.Health=100;local witness=f.A.CaptureStage2Back(p,1,2,c,'run',{})
  p:SetAttribute('RunInventoryId','returned');c.Attrs.SpawnPlacementRevision=2
  f.A.Stage2BackPlaced(p,witness,{RunId='run',Character=c,Accepted=true},'returned');f.A.Placed(p,c,2)
  f.A.Combat(p,1,2,6)
  local out={}for _,e in f.Rows(p)do if e.Kind=='Funnel'and e.Name~='MTF_FirstOreMerge_v1'then table.insert(out,e)end end return out
 end
 local before,after=regression(sources.Before),regression(sources.Service)
 check(#before==#after and #after==18,'Other five funnel count unchanged')
 for i,a in after do local b=before[i];check(a.Name==b.Name and a.Step==b.Step and a.StepName==b.StepName and a.Session==b.Session,'Other funnel identity/order')
  for k,v in a.Fields do check(b.Fields[k]==v,'Other funnel field unchanged')end end
 return {Passed=true,Assertions=checks,OtherFunnelRows=#after,Kind='Dependency-injected exact production service/transport; geometry mocked, not Play or Hub'}
end
