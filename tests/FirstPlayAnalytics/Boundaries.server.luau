-- Injected data/fault boundaries in native Play, separate from ordinary earned routes.
local RS=game.ReplicatedStorage
local q=RS.__EarlyQARoute
local S=game.ServerScriptService.Services
local Data=require(S.PlayerDataService)
local Forge=require(S.ForgeService)
local A=require(S.FirstPlayAnalyticsService)
local T=require(S.FirstPlayAnalyticsTransport)
local Memory=require(RS.__EarlyQAMemory)
local report={Checks={},Method='Native client UI and real runtime services, injected memory-store faults/materials'}
local function waitFor(fn,t)
 local limit=os.clock()+(t or 15);repeat local v=fn();if v then return v end;task.wait(.04)until os.clock()>limit;error('Boundary timeout')
end
local function check(name,ok,details)table.insert(report.Checks,{Name=name,Passed=not not ok,Details=details});assert(ok,name)end
local function records(p,name,detail)
 local out={};for _,e in T.StudioRecords()do if e.UserId==p.UserId and (not name or name==e.Name)and(not detail or e.Fields.CustomField03==detail)then table.insert(out,e)end end;return out
end
local function ask(p,action)local r=q.Call:InvokeClient(p,action);assert(r.OK,r.Error);return r.Value end
local function settled(p)return waitFor(function()local c=p.Character;return Data.IsLoaded(p)and c and c:GetAttribute('LobbySpawnPlaced')and not c.HumanoidRootPart.Anchored end,45)end
local function saved(p)
 return Memory.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName('PlayerData_v1')):GetAsync('Player_'..p.UserId)
end
local ok,err=xpcall(function()
 waitFor(function()return #game.Players:GetPlayers()==3 end,60)
 local p=game.Players:GetPlayerByUserId(-1);local existing=game.Players:GetPlayerByUserId(-2);local failed=game.Players:GetPlayerByUserId(-3)
 settled(p);settled(existing)
 waitFor(function()return #records(p,'MTF_Entry_v1')==3 and #records(existing,'MTF_Entry_v1')==3 and #records(failed,nil,'LoadFailed')==1 end,40)
 check('New from actual profile creation',p:GetAttribute('MTFNewFirstSession')==true)
 check('Existing LV1/Strength0 not New',existing:GetAttribute('MTFNewFirstSession')==false and #records(existing,'MTF_FirstCombat_v1')==0)
 check('Failed load keeps Entry denominator',#records(failed,'MTF_Entry_v1')==1 and failed:GetAttribute('MTFNewFirstSession')~=true)
 check('Auto initial OFF retained',ask(p,'Status').Auto==false and ask(existing,'Status').Auto==false)
 -- UI is genuinely open while no owned Ore exists. Bag-only material must not qualify.
 ask(p,'Open');local Run=require(S.RunInventoryService)
 local id=p:GetAttribute('RunInventoryId')
 for _=1,2 do assert(Run.TryAddOreDrop(p,id,game.HttpService:GenerateGUID(false),'ORE_001'))end
 A.CheckOre(p);task.wait(.3)
 local before=#records(p,'MTF_FirstOreMerge_v1')
 check('Early-open and Bag-only Ore do not invent Eligible',before==0 and Run.GetSnapshot(p).Count==2)
 -- Inject owned materials through the ordinary durable grant; these are not earned-route timings.
 for _=1,2 do assert(Forge.GrantOre(p,'ORE_001',game.HttpService:GenerateGUID(false)))end
 waitFor(function()return #records(p,'MTF_FirstOreMerge_v1')>=2 end)
 local snapshot=ask(p,'Select');ask(p,'Duplicates');task.wait(.5)
 check('Current early-open view reobserved after eligibility',#records(p,'MTF_FirstOreMerge_v1')==3)
 Memory.HoldWrites=true
 ask(p,'Submit')
 waitFor(function()return Data.Get(p).PendingItemMutation~=nil end)
 local op=Data.Get(p).PendingItemMutation
 task.wait(1)
 check('Held save no committed step',#records(p,'MTF_FirstOreMerge_v1')==4 and next(Data.Get(p).Data.OwnedDumbbells)==nil)
 Memory.FailAfter=1;Memory.HoldWrites=false
 -- The first write commits in the adapter then loses acknowledgement; the existing retry confirms it.
 waitFor(function()return Data.Get(p).PendingItemMutation==nil end,25)
 waitFor(function()return #records(p,'MTF_FirstOreMerge_v1')==5 end)
 local request={Action='MergeOre',Id=op.Id,Sequence=op.Sequence,Token=Data.Get(p).ForgeToken,Generation=Data.Get(p).PetViewGeneration or 0,Materials={ORE_001=2},AnalyticsContext=snapshot}
 for _=1,8 do local r=Forge.Request(p,request);assert(r.Success)end
 local raw=saved(p);local count=0;for _,n in Data.Get(p).Data.OwnedDumbbells do count+=n end
 check('Acknowledgement loss/replay exactly one grant and commit',count==1 and raw.ForgeJournal.Id==op.Id and #records(p,'MTF_FirstOreMerge_v1')==5,{Result=op.ResultId,Journal=raw.ForgeJournal})
 -- Fail-before boundary: a second ordinary request cannot produce another first-session completion.
 assert(Forge.GrantOre(p,'ORE_001',game.HttpService:GenerateGUID(false)));assert(Forge.GrantOre(p,'ORE_001',game.HttpService:GenerateGUID(false)))
 local s=Data.Get(p);local retry={Action='MergeOre',Id=game.HttpService:GenerateGUID(false),Sequence=s.Data.ForgeJournal.Sequence+1,Token=s.ForgeToken,Generation=s.PetViewGeneration or 0,Materials={ORE_001=2}}
 Memory.FailBefore=1;local first=Forge.Request(p,retry)
 check('Precommit failure stays pending',not first.Success and first.Code=='InventorySavePending')
 waitFor(function()return Data.Get(p).PendingItemMutation==nil end,25)
 check('Later merge not another first completion',#records(p,'MTF_FirstOreMerge_v1')==5)
 local old=p.Character;old.Humanoid.Health=0
 waitFor(function()return p.Character~=old end,20);settled(p);task.wait(.7)
 check('Actual death/respawn keeps same funnel',#records(p,'MTF_Entry_v1')==3 and #records(p,'MTF_FirstCombat_v1')==1)
 local deaths=0;for _,e in records(p)do if e.Fields.CustomField03:sub(1,6)=='Death:'then deaths+=1 end end
 check('First actual death once',deaths==1)
 -- Analytics send failure must not change an ordinary Strength gain.
 T.StudioFailNext(1);local strength=p:GetAttribute('Strength');ask(p,'Tap');task.wait(.7)
 check('Analytics failure leaves training success intact',p:GetAttribute('Strength')==strength+1)
 -- Actual reset is isolated. Its new default-looking data must not re-enter the cohort.
 Data.WaitForSave(p,10);assert(Data.Reset(p));task.wait(.5)
 check('Actual debug reset excluded',p:GetAttribute('MTFNewFirstSession')==false)
 Data.WaitForSave(existing,10);assert(Data.Save(existing));local firstSession=existing:GetAttribute('MTFSession')
 Data.Release(existing);assert(Data.Load(existing));task.wait(.3)
 check('Saved reload stays Existing and Entry does not restart',existing:GetAttribute('MTFNewFirstSession')==false and existing:GetAttribute('MTFSession')==firstSession and #records(existing,'MTF_Entry_v1')==3)
 report.SavedExisting=saved(existing)
end,debug.traceback)
Memory.HoldWrites=false;Memory.FailBefore=0;Memory.FailAfter=0
report.Passed=ok;report.Error=not ok and err or nil;report.Events=T.StudioRecords()
q:SetAttribute('BoundaryResult',game.HttpService:JSONEncode(report));q:SetAttribute('BoundaryDone',true)
print('[Analytics boundaries] '..(ok and 'PASS' or tostring(err)))
