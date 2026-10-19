-- Actual code runs only in this memory fixture, never in Studio or against DSS.
local count=0
local function check(v,label)count+=1;assert(v,label or ('assertion '..count))end
local function equal(a,b,label)check(a==b,(label or 'value')..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,label)check(math.abs(a-b)<1e-8*math.max(1,math.abs(b)),label)end
local function copy(x)if type(x)~='table'then return x end;local r={};for k,v in pairs(x)do r[k]=copy(v)end;return r end
local function signal()
 local s={listeners={}}
 function s:Connect(f)local c={Connected=true};function c:Disconnect()self.Connected=false end;table.insert(self.listeners,{c,f});return c end
 function s:Once(f)local connection;connection=self:Connect(function(...)connection:Disconnect();f(...)end);return connection end
 function s:Fire(...)for _,e in ipairs(table.clone(self.listeners))do if e[1].Connected then e[2](...)end end end
 return s
end
local builtinTypeof=typeof
local function typeof(x)return type(x)=='table'and x.__instance and 'Instance'or builtinTypeof(x)end
local function node(name,class)
 local n={Name=name,ClassName=class or 'Folder',__instance=true,children={},attributes={},AncestryChanged=signal(),ChildAdded=signal()}
 function n:IsA(kind)return self.ClassName==kind or kind=='BasePart'and(self.ClassName=='Part'or self.ClassName=='MeshPart')end
 function n:FindFirstChild(k)return self.children[k]end
 function n:WaitForChild(k)return assert(self.children[k],self.Name..'.'..k)end
 function n:GetChildren()local out={};for _,c in pairs(self.children)do table.insert(out,c)end;return out end
 function n:GetFullName()return self.Parent and self.Parent:GetFullName()..'.'..self.Name or self.Name end
 function n:IsDescendantOf(parent)local c=self.Parent;while c do if c==parent then return true end;c=c.Parent end;return false end
 function n:GetAttribute(k)return self.attributes[k]end
 function n:GetAttributeChangedSignal(k)self.signals=self.signals or {};self.signals[k]=self.signals[k]or signal();return self.signals[k]end
 function n:SetAttribute(k,v)local old=self.attributes[k];self.attributes[k]=v;if old~=v and self.signals and self.signals[k]then self.signals[k]:Fire()end end
 function n:GetPropertyChangedSignal(k)self.props=self.props or {};self.props[k]=self.props[k]or signal();return self.props[k]end
 function n:FindFirstChildOfClass(kind)for _,c in pairs(self.children)do if c:IsA(kind)then return c end end end
 function n:Destroy()if self.Parent then self.Parent.children[self.Name]=nil end;self.Parent=nil end
 return setmetatable(n,{__index=function(t,k)return rawget(t,'children')[k]end})
end
local function attach(parent,name,class)local n=node(name,class);n.Parent=parent;parent.children[name]=n;return n end
local V={}
local vmt={__index=function(t,k)if k=='Magnitude'then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z)end end,
 __add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end,__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,
 __div=function(a,b)return V.new(a.X/b,a.Y/b,a.Z/b)end,__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return V.new(a.X*b,a.Y*b,a.Z*b)end}
function V.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vmt)end
V.zero=V.new();V.yAxis=V.new(0,1,0)
local CF={}
function CF.new(x,y,z)
 local p=type(x)=='table'and x or V.new(x,y,z)
 return setmetatable({Position=p,PointToObjectSpace=function(_,v)return v-p end}, {__mul=function(a,b)return CF.new(a.Position+b.Position)end})
end
CF.Angles=function()return CF.new()end;CF.identity=CF.new()
local clock=100
local jobs={}
local task={}
function task.spawn(fn,...)local co=coroutine.create(fn);local ok,why=coroutine.resume(co,...);assert(ok,why);if coroutine.status(co)~='dead'then table.insert(jobs,co)end;return co end
task.defer=task.spawn
function task.wait()return coroutine.yield()end
function task.delay(_,fn,...)return task.spawn(fn,...)end
local function tick()
 clock+=1
 for _,co in ipairs(table.clone(jobs))do
  if coroutine.status(co)~='dead'then local ok,why=coroutine.resume(co);assert(ok,why)end
 end
end
local generated=1000
local function guid()generated+=1;return string.format('00000000-0000-0000-0000-%012x',generated)end
local random={NextNumber=function()return .01 end,NextInteger=function(_,a)return a end}
local Http={GenerateGUID=function()return guid()end}
local Players=node('Players','Players');Players.PlayerAdded=signal();Players.PlayerRemoving=signal()
local W=node('Workspace','Workspace')
local RS=node('ReplicatedStorage');local ConfigFolder=attach(RS,'Config');local ModuleFolder=attach(RS,'Modules');local Remotes=attach(RS,'Remotes')
local SSS=node('ServerScriptService');local Services=attach(SSS,'Services');local World=attach(SSS,'World')
local root={ReplicatedStorage=RS,ServerScriptService=SSS,Players=Players,PlaceId=126576845524886}
local runService={Heartbeat=signal(),IsStudio=function()return false end}
local tagged={}
local collection={GetTagged=function()return tagged end,HasTag=function(_,model)return table.find(tagged,model)~=nil end,
 GetInstanceAddedSignal=function()return signal()end,GetInstanceRemovedSignal=function()return signal()end}
function root:GetService(name)return assert(({Players=Players,Workspace=W,ReplicatedStorage=RS,RunService=runService,HttpService=Http,CollectionService=collection,MarketplaceService={}})[name],name)end
local loaded={}
local env
local requireModule
local function moduleNode(path)
 local steps=string.split(path,'.');local current=({ReplicatedStorage=RS,ServerScriptService=SSS})[steps[1]]
 if not current then return node(path,'ModuleScript')end
 for i=2,#steps do current=current.children[steps[i]]or attach(current,steps[i],i==#steps and 'ModuleScript'or 'Folder')end
 current.path=path;return current
end
for path in pairs(SOURCES)do if not path:match('^Test%.')then moduleNode(path)end end
requireModule=function(value)
 local path=value.path
 if value.stub then return value.stub end
 if loaded[path]then return loaded[path]end
 assert(SOURCES[path],'Missing fixture source '..tostring(path))
 local f,why=loadstring(SOURCES[path],path);assert(f,why)
 local moduleEnv=setmetatable({script=value},{__index=env});setfenv(f,moduleEnv)
 local result=f();loaded[path]=result;return result
end
local function color(...)return {...}end
env={game=root,workspace=W,require=requireModule,typeof=typeof,task=task,
 Color3={new=color,fromRGB=color},Vector3=V,Vector2={new=function(x,y)return {X=x,Y=y}end},CFrame=CF,
 ColorSequence={new=color},ColorSequenceKeypoint={new=color},NumberSequence={new=color},NumberRange={new=color},
 UDim2={fromScale=color,fromOffset=color,new=color},UDim={new=color},Enum={HumanoidStateType={Running=1,RunningNoPhysics=2},Material={SmoothPlastic=1}},
 Random={new=function()return random end},warn=function()end,os=setmetatable({clock=function()return clock end},{__index=os}),
 print=print,Instance={new=function(class)return node(class,class)end}}
setmetatable(env,{__index=getfenv()})
local function get(path)return requireModule(moduleNode(path))end
local C=get('ReplicatedStorage.Config.World2GameplayConfig')
local Master=get('ReplicatedStorage.Config.ItemMaster')
local Dumbbells=get('ReplicatedStorage.Config.DumbbellItemMaster')
local Auras=get('ReplicatedStorage.Config.AuraConfig')
local Effects=get('ReplicatedStorage.Config.ItemMultiplierConfig')
local Egg=get('ReplicatedStorage.Modules.Egg')
local Pet=get('ReplicatedStorage.Modules.Pet')
local Progression=get('ReplicatedStorage.Modules.LevelProgression')
local Requirements=get('ReplicatedStorage.Config.LevelRequirements')
local MergeConfig=get('ReplicatedStorage.Config.ItemMergeConfig')
local Rewards=get('ReplicatedStorage.Config.TrophyRewardConfig')
local Rebirth=get('ReplicatedStorage.Config.RebirthConfig')
local RebirthMultiplier=get('ReplicatedStorage.Config.RebirthMultiplierConfig')

-- Every independent Excel row is checked once against its actual public API.
local World2Boss=get('ReplicatedStorage.Config.World2BossConfig')
local World2=get('ReplicatedStorage.Config.World2Config')
for i,row in ipairs(EXPECTED.Stages)do
 equal(World2Boss.GetMaxHP(i),row.BossMaxHP,'Boss '..i)
 equal(Rewards.GetBaseReward(i,2),row.WinReward,'Win '..i)
 for j,hp in ipairs(row.Walls)do equal(World2.GetStageConfig(i).Walls[j],hp,'wall '..i..'.'..j)end
end
for i=1,10 do
 local row=EXPECTED.Rebirth[tostring(i)]or EXPECTED.Rebirth[i]
 equal(Rebirth.GetRequiredLevel(i-1),row.Level,'Rebirth LV')
 equal(RebirthMultiplier.GetMultiplier(i),row.Multiplier,'Rebirth factor')
 local sum=0;for level=1,row.Level-1 do sum+=Requirements.GetRequiredStrength(level)end
 equal(sum,row.ReferenceStrength,'Reference cumulative curve')
end
equal(RebirthMultiplier.GetMultiplier(0),1);equal(RebirthMultiplier.GetMultiplier(31),16.5)
check(not Rebirth.IsWorld1Max(5),'Common Rebirth continues beyond old World1 cap')
for i,row in ipairs(EXPECTED.Dumbbells)do local item=Dumbbells.Get(string.format('W2_NORMAL_%02d',i));equal(item.PriceWin,row.PriceWin);equal(item.StrengthBonus,row.StrengthBonus);equal(item.Image,'rbxassetid://'..C.DumbbellImages[i])end
for rarity,row in pairs(EXPECTED.Items)do
 equal(Effects.GetProteinBonus(rarity,2),row.ProteinBonus);equal(Effects.GetGloveBossDamageBonus(rarity,2),row.GloveBossDamageBonus);equal(Effects.GetBeltTreadmillBonus(rarity,2),row.BeltTreadmillBonus)
 local item=Master.Get(Master.Id('Protein',rarity,'Fire',2))
 equal(item.WinPrice,row.PriceWin);equal(item.ShopPurchasable,row.PriceWin~=nil);check(not item.RobuxPurchasable)
end
for i,row in ipairs(EXPECTED.Auras)do local aura=Auras.Get(string.format('W2_AURA_%02d',i));equal(aura.Price,row.PriceWin);equal(aura.StrengthBonus,row.StrengthBonus);check(aura.GamePassId==nil and aura.ProductId==nil)end
for eggIndex,id in ipairs(C.EggIds)do
 local pool=assert(Egg.pets(id));local unique=0;local probability=0
 for name,p in pairs(pool)do unique+=1;probability+=p;near(Pet.StrengthMultiplier({Owned={copy=name},Equipped={'copy'}}),C.Pets[name].Multiplier,'Pet final factor')end
 equal(unique,7);near(probability,100)
 if eggIndex<5 then equal(Egg.price(id),EXPECTED.Eggs[eggIndex].PriceWin)else check(not Egg.purchasable(id));equal(Egg.price(id),0)end
end
for _,entry in pairs(C.PaidOffers)do check(entry.PurchaseEnabled==false and entry.GamePassId==nil and entry.ProductId==nil and entry.Price==nil)end
local Format=get('ReplicatedStorage.Modules.NumberFormat')
for _,pair in ipairs({{350000000,'350M'},{1500000000,'1.5B'},{3500000000000,'3.5T'}})do equal(Format.Format(pair[1]),pair[2])end

-- Memory player and store. No DataStore initialization or real data is executed.
local p=node('OfflineFixture','Player');p.UserId=101;p.Parent=Players;p.CharacterAdded=signal()
local Skip=get('ReplicatedStorage.Config.StageSkipConfig')
p:SetAttribute('CurrentWorld',2);check(not Skip.IsSupportedWorld(p))
p:SetAttribute('CurrentWorld',1);check(Skip.IsSupportedWorld(p))
p:SetAttribute('CurrentWorld',2)
function Players:GetPlayers()return {p}end
local character=attach(p,'Character','Model');p.Character=character
local hum=attach(character,'Humanoid','Humanoid');hum.Health=100;hum.MaxHealth=100;hum.HipHeight=2;hum.Died=signal();hum.RigType=0
local hrp=attach(character,'HumanoidRootPart','Part');hrp.Size=V.new(2,2,1);hrp.Position=V.new(0,5,0)
function character:GetBoundingBox()return CF.new(),V.new(4,6,4)end
function character:GetDescendants()return self:GetChildren()end
local pivots=0
function character:PivotTo(cf)pivots+=1;hrp.Position=cf.Position end
local sessions={[p]={Loaded=true,Data={}}}
local Data={}
function Data.Get(player)return sessions[player]end
function Data.IsLoaded(player)return sessions[player]and sessions[player].Loaded==true end
function Data.IsSaving(player)return sessions[player]and sessions[player].Saving==true end
function Data.RecordStrengthGain(player,gain)local d=sessions[player].Data;d.TotalStrengthEarned+=gain;d.DailyStrengthEarned+=gain end
local stored,storeMeta,storeMode,writes={}, {},nil,0
local function info(meta)return {GetMetadata=function()return copy(meta)end,GetUserIds=function()return {}end}end
local function ownedUpdate(player,session,transform)
 check(player==p and sessions[p]==session,'Memory store session identity')
 if storeMode=='before'then error('offline failure before commit')end
 local next,users,meta=transform(copy(stored),info(storeMeta))
 if next then stored=copy(next);storeMeta=copy(meta or storeMeta);writes+=1 end
 if storeMode=='after'then error('offline acknowledgement lost after commit')end
 return next,info(storeMeta)
end
local dataEnv=setmetatable({PlayerDataService=Data,sessions=sessions,JST_OFFSET=9*3600,
 Pet=Pet,LimitedEgg=get('ReplicatedStorage.Config.LimitedEggConfig'),DumbbellItemMaster=Dumbbells,AuraConfig=Auras,
 CapacityConfig=get('ReplicatedStorage.Config.InventoryCapacityConfig'),LevelProgression=Progression,
 SpeedConfig=get('ReplicatedStorage.Config.SpeedConfig'),DailyRewardConfig=get('ReplicatedStorage.Config.DailyRewardConfig'),
 TimeRewardConfig=get('ReplicatedStorage.Config.TimeRewardConfig'),CommunityConfig=get('ReplicatedStorage.Config.CommunityRewardConfig'),
 ShopConfig=get('ReplicatedStorage.Config.ShopProductConfig'),HttpService=Http,ownedUpdate=ownedUpdate,
 resetToken=function(d)return d and d.ResetToken end,scheduleItemMutationRetry=function()return 1,1 end,
},{__index=env})
local dataChunk=assert(loadstring(SOURCES['Test.DataFunctions']));setfenv(dataChunk,dataEnv)
local hooks=dataChunk()
function Data.Save(player,equipOnSuccess)
 local s=sessions[player];if not s or not s.Loaded then return false,'DataNotLoaded'end
 stored=copy(s.Data)
 if equipOnSuccess then Data.SetEquippedAura(player,equipOnSuccess);stored=copy(s.Data)end
 return true,'SavedInMemory'
end
moduleNode('ServerScriptService.Services.PlayerDataService').stub=Data
local pass={AreEffectsEnabled=function()return true end,HasPremiumTreadmill=function()return true end,
 HasShopPass=function()return false end,GetVIPStrengthMultiplier=function()return 1 end,PromptPremiumTreadmill=function()error('No prompt expected')end}
moduleNode('ServerScriptService.Services.GamePassService').stub=pass
moduleNode('ServerScriptService.Services.BadgeAwardService').stub={Award=function()end}
moduleNode('ServerScriptService.Services.PotionService').stub={GetStrengthMultiplier=function()return 1 end,GetTrainingBonus=function()return 0 end}
moduleNode('ServerScriptService.Services.AutoTapService').stub={CanAutoTrain=function()return false end}
local function remote(name)
 local r=attach(Remotes,name,'RemoteEvent');r.OnServerEvent=signal();r.events={}
 function r:FireClient(_,...)table.insert(self.events,{...})end
 return r
end
remote('StrengthGain');local rebirthRemote=remote('RebirthRequest')
local function resetData(win)
 local d=hooks.Defaults();d.ResetToken='memory-fixture';d.Win=win or 5000000
 sessions[p]={Loaded=true,Data=d};stored=copy(d);storeMeta={};storeMode=nil
 for k,v in pairs({Win=d.Win,Strength=0,Level=1,LevelProgress=0,RebirthCount=0,CurrentWorld=2})do p:SetAttribute(k,v)end
 return sessions[p]
end
local session=resetData()
local DB=get('ServerScriptService.Services.DumbbellService')
local Items=get('ServerScriptService.Services.ItemService')
local Merge=get('ServerScriptService.Services.ItemMergeService')
local Aura=get('ServerScriptService.Services.AuraService')
local Pets=get('ServerScriptService.Services.PetServer')
check(next(session.Data.OwnedDumbbells)==nil and next(session.Data.OwnedItems)==nil and next(session.Data.Pets.Owned)==nil,'No initial W2 ownership')
equal(DB.PurchaseDumbbell(p,'W2_NORMAL_01'),true);equal(session.Data.Win,4997000)
equal(DB.EquipDumbbell(p,'W2_NORMAL_01'),true);equal(DB.GetStrengthBonus(p),800)
local before=session.Data.Win
equal(select(2,DB.PurchaseDumbbell(p,'W2_NORMAL_01')),'AlreadyOwned');equal(session.Data.Win,before)
Data.SetWin(p,1);equal(select(2,DB.PurchaseDumbbell(p,'W2_NORMAL_02')),'NotEnoughWin')
Data.SetWin(p,5000000)
equal(DB.PurchaseDumbbell(p,'NORMAL_01'),true);equal(DB.EquipDumbbell(p,'NORMAL_01'),true);equal(DB.GetStrengthBonus(p),3,'W1 purchase/equip regression')
equal(DB.EquipDumbbell(p,'W2_NORMAL_01'),true)
equal(Aura.PurchaseAura(p,'W2_AURA_01'),true);equal(Aura.GetStrengthBonus(p),200)
equal(select(2,Aura.PurchaseAura(p,'W2_AURA_06')),'InvalidPurchaseType')
check(not Aura.GetOwnedAuras(p).W2_AURA_06,'Paid Aura never granted')
for _,kind in ipairs({'Protein','Glove','TrainingBelt'})do
 local id=Master.Id(kind,'Common','Fire',2)
 equal(Items.PurchaseItemWithWin(p,id),true);equal(Items.EquipItem(p,id),true)
end
equal(Items.GetProteinBonus(p),200);equal(Items.GetGloveBossDamageBonus(p),.6);equal(Items.GetBeltTreadmillBonus(p),3)
equal(select(2,Items.PurchaseItemWithWin(p,'W2_PROTEIN_LEGENDARY_FIRE')),'NotWinPurchasable')
equal(Items.PurchaseItemWithWin(p,'PROTEIN_COMMON_FIRE'),true,'W1 item purchase regression')
equal(Items.EquipItem(p,'PROTEIN_COMMON_FIRE'),true);equal(Items.GetProteinBonus(p),1)
equal(Items.EquipItem(p,'W2_PROTEIN_COMMON_FIRE'),true)
equal(Items.AddItem(p,'TRAININGBELT_LEGENDARY_FIRE',1),true)
equal(Items.EquipItem(p,'TRAININGBELT_LEGENDARY_FIRE'),true)
equal(Items.EquipBestItems(p),true)
equal(session.Data.EquippedItems.TrainingBelt,'W2_TRAININGBELT_COMMON_FIRE','Best Equip compares actual cross-world effect')
Data.SetWin(p,1000000)
for _=1,3 do equal(Items.PurchaseItemWithWin(p,'W2_PROTEIN_EPIC_FIRE'),true)end
equal(session.Data.Win,595000,'Three Epic total cost, not Legendary direct offer')
local mergeState=Merge.GetState(p)
local request={RequestId=guid(),SessionToken=mergeState.SessionToken,Sequence=mergeState.NextSequence,Materials={W2_PROTEIN_EPIC_FIRE=3}}
local ok,reason,result=Merge.MergeItem(p,request)
check(ok and result=='W2_PROTEIN_LEGENDARY_FIRE','W2 merge result identity')
equal(session.Data.OwnedItems.W2_PROTEIN_EPIC_FIRE,nil);equal(session.Data.OwnedItems[result],1)
equal(Merge.MergeItem(p,request),true,'Idempotent merge replay');equal(session.Data.OwnedItems[result],1)
equal(select(2,MergeConfig.Evaluate({PROTEIN_COMMON_FIRE=1,W2_PROTEIN_COMMON_FIRE=1},session.Data.OwnedItems)),'MixedWorldMaterials')
local w1Preview=assert(MergeConfig.Evaluate({PROTEIN_COMMON_FIRE=3}));check(MergeConfig.Sample(w1Preview,function()return .1 end):sub(1,3)~='W2_','W1 materials retain W1 output')
local Roller=get('ServerScriptService.Services.EnemyDropRoller')
local highRoll={NextInteger=function(_,a,b)return b end,NextNumber=function()return .1 end}
equal(Roller.RollRarity(highRoll,4),'Rare');equal(Roller.RollRarity(highRoll,7),'Epic');equal(Roller.RollRarity(highRoll,8),'Legendary')
check(Roller.Roll(highRoll,8,2).ItemId:sub(1,3)=='W2_');check(Roller.Roll(highRoll,8,1).ItemId:sub(1,3)~='W2_')
local noHit={NextNumber=function()return .2 end,NextInteger=function(_,a)return a end}
equal(Roller.Roll(noHit,8,2).Outcome,'MISS','Existing strict 20 percent boundary')

-- Real module/ID resolution, with synthetic visual objects and positions only.
local eggFolder=attach(W,'Eggs');local map1=attach(W,'GeneratedMap','Model');local map2=attach(W,'World2Map','Model')
local lobby1=attach(map1,'TrainingArea','Model');local lobby2=attach(map2,'TrainingArea','Model')
local facility=attach(lobby2,'FacilityDisplays','Model');local eggDisplays=attach(facility,'EggDisplays','Model');local visuals=attach(eggDisplays,'Visuals')
for _,name in ipairs({'Basic','Rare','Legendary','Mythic'})do
 for _,folder in ipairs({eggFolder,visuals})do local part=attach(folder,name,'MeshPart');part.Position=V.new(0,5,0)end
end
local limited=attach(facility,'LimitedEggDisplay','Model');local limitedMesh=attach(limited,'PetMesh','MeshPart');limitedMesh.Position=V.new(0,5,0)
local originalModel=Pet.model
Pet.model=function(name)return node(Pet.VisualName(name),'Model')end -- Geometry checked separately against saved assets.
local Eggs=get('ServerScriptService.Services.EggServer')
Data.SetWin(p,2000000);Data.Save(p)
local totalCost=0
for index,n in ipairs({1,3,8})do
 clock+=1;local id=guid();local revision=session.Data.Pets.Revision
 local reply=Eggs.request(p,'OpenEgg',id,revision,'W2_Basic','Open'..n)
 check(reply.ok,'Egg purchase '..n..' '..tostring(reply.reason));totalCost+=n*1000
 equal(session.Data.Win,2000000-totalCost,'Actual debit '..n)
 equal(#session.Data.Pets.LastResults,n,'Hatch count')
 local copies={};for _,r in ipairs(session.Data.Pets.LastResults)do check(not copies[r.id]and C.Pets[r.pet]~=nil,'Distinct owned copy IDs');copies[r.id]=true end
 local replay=Eggs.request(p,'OpenEgg',id,revision,'W2_Basic','Open'..n);check(replay.ok,'Egg replay');equal(session.Data.Win,2000000-totalCost)
end
clock+=1;local beforePaid=session.Data.Win
check(not Eggs.request(p,'OpenEgg',guid(),session.Data.Pets.Revision,'W2_Limited','Open1').ok,'Limited paid request disabled');equal(session.Data.Win,beforePaid)
p:SetAttribute('CurrentWorld',1);clock+=1
check(not Eggs.request(p,'OpenEgg',guid(),session.Data.Pets.Revision,'W2_Basic','Open1').ok,'Cross-world Egg request rejected')
p:SetAttribute('CurrentWorld',2)
clock+=1;storeMode='after';local paidId=guid();local rev=session.Data.Pets.Revision;local balance=session.Data.Win
check(not Eggs.request(p,'OpenEgg',paidId,rev,'W2_Basic','Open3').ok,'Lost acknowledgement pending')
equal(stored.Win,balance-3000);storeMode=nil;check(Data.ResolveItemMutation(p),'Resolve the original hatch')
equal(session.Data.Win,balance-3000);equal(session.Data.Pets.Revision,rev+1)
clock+=1;check(Eggs.request(p,'OpenEgg',paidId,rev,'W2_Basic','Open3').ok);equal(session.Data.Win,balance-3000,'No second debit')
local petId=session.Data.Pets.LastResults[1].id
check(Pets.equip(p,petId,guid(),session.Data.Pets.Revision),'Equip owned copy')
local factor=Pet.StrengthMultiplier(session.Data.Pets)
near(Pets.GetStrengthMultiplier(p),factor)
p:SetAttribute('CurrentWorld',1);near(Pets.GetStrengthMultiplier(p),factor,'W2 Pet usable in W1');equal(DB.GetStrengthBonus(p),800);equal(Aura.GetStrengthBonus(p),200);equal(Items.GetProteinBonus(p),200)
clock+=1;local w1Reply=Eggs.request(p,'OpenEgg',guid(),session.Data.Pets.Revision,'Basic','Open1');check(w1Reply.ok,'World1 Egg purchase regression')
local w1Pet=session.Data.Pets.LastResults[1].id
check(Pets.equip(p,w1Pet,guid(),session.Data.Pets.Revision))
p:SetAttribute('CurrentWorld',2)
near(Pets.GetStrengthMultiplier(p),1+(Pet.StrengthPercent(session.Data.Pets.Owned[w1Pet])or 0)/100,'World1 Pet usable in World2')
check(Pets.equip(p,petId,guid(),session.Data.Pets.Revision))
p:SetAttribute('CurrentWorld',2)
Data.Save(p);local normalized=assert(hooks.Normalize(copy(stored)))
equal(normalized.EquippedDumbbell,'W2_NORMAL_01');equal(normalized.EquippedAura,'W2_AURA_01');equal(normalized.EquippedItems.Protein,'W2_PROTEIN_COMMON_FIRE');equal(normalized.Pets.Equipped[1],petId)
normalized.RebirthCount=31;equal(assert(hooks.Normalize(normalized)).RebirthCount,31,'Existing higher count is never capped/reset')
Pet.model=originalModel

-- Existing single-session training scheduler, access rules and common Rebirth.
local w1Treads=attach(W,'Treadmills');local w2Treads=attach(lobby2,'TreadmillDisplays','Model')
for _,name in ipairs({'Normal01','Normal02','Iron01','Iron02','Gold01','Gold02','Diamond01'})do local m=attach(w1Treads,name,'Model');attach(m,'Area','Part');table.insert(tagged,m)end
for i=1,7 do local m=attach(w2Treads,string.format('%02d',i),'Model');attach(m,'Area','Part');table.insert(tagged,m)end
local Training=get('ServerScriptService.Services.TrainingManager')
Training.IsPlayerInsideZone=function(player,zone)return player==p and player.fixtureZone==zone and hum.Health>0 end
Training.Initialize()
local treadmillConfig=get('ReplicatedStorage.Config.TreadmillConfig')
equal(#Training.GetTreadmills(),14,'Only original seven plus seven World2 machines')
p:SetAttribute('RebirthCount',6);check(not Training.CanUseTreadmill(p,w2Treads['03']))
p:SetAttribute('RebirthCount',7);check(Training.CanUseTreadmill(p,w2Treads['03']))
p:SetAttribute('RebirthCount',8);check(not Training.CanUseTreadmill(p,w2Treads['05']))
p:SetAttribute('RebirthCount',9);check(Training.CanUseTreadmill(p,w2Treads['05']))
check(not Training.CanUseTreadmill(p,w2Treads['07']),'World1 premium ownership never unlocks World2 paid04')
p:SetAttribute('RebirthCount',0)
local m=w2Treads['01'];p.fixtureZone=m.Area
local baseBefore=p:GetAttribute('Strength')
check(Training.StartTraining(p,m));check(Training.StartTraining(p,m));equal(Training.GetActiveSessionCount(),1,'No duplicate session')
tick()
local expectedGain=(1+800+200+200)*(5+3)*Items.GetElementSetMultiplier(p)*factor
near(p:GetAttribute('Strength')-baseBefore,expectedGain,'Existing additive Band formula with final Pet multiplier')
baseBefore=p:GetAttribute('Strength');p.fixtureZone=nil;tick();equal(Training.GetActiveSessionCount(),0);equal(p:GetAttribute('Strength'),baseBefore,'Exit stops gain')
p.fixtureZone=m.Area;check(Training.StartTraining(p,m));hum.Died:Fire();tick();equal(Training.GetActiveSessionCount(),0,'Death stops session')
get('ServerScriptService.Systems.Controllers.TrainingController')
p.fixtureZone=m.Area;check(Training.StartTraining(p,m));p:SetAttribute('CurrentWorld',1);equal(Training.GetActiveSessionCount(),0,'Actual World-change handler stops training')
check(not Training.CanUseTreadmill(p,m));check(Training.CanUseTreadmill(p,w1Treads.Normal01),'W1 access regression')
p:SetAttribute('CurrentWorld',2)
local preserved={Win=session.Data.Win,Dumbbells=copy(session.Data.OwnedDumbbells),Auras=copy(session.Data.OwnedAuras),Items=copy(session.Data.OwnedItems),Pet=copy(session.Data.Pets)}
session.Data.Level=69;session.Data.Strength=999999999;p:SetAttribute('Level',69);p:SetAttribute('Strength',999999999);session.Data.RebirthCount=5;p:SetAttribute('RebirthCount',5)
get('ServerScriptService.Systems.Controllers.RebirthService')
rebirthRemote.OnServerEvent:Fire(p,'Request');equal(session.Data.RebirthCount,5,'LV required even with huge Strength')
session.Data.Level=70;p:SetAttribute('Level',70)
session.Data.Strength=0;p:SetAttribute('Strength',0)
rebirthRemote.OnServerEvent:Fire(p,'Request');equal(session.Data.RebirthCount,6);equal(session.Data.Strength,0);equal(session.Data.Level,1);equal(session.Data.LevelProgress,0)
equal(session.Data.Win,preserved.Win);check(session.Data.OwnedDumbbells.W2_NORMAL_01 and session.Data.OwnedAuras.W2_AURA_01);equal(session.Data.Pets.Equipped[1],petId);equal(session.Data.EquippedItems.Protein,'W2_PROTEIN_COMMON_FIRE')

-- Boss/Wall reset from the same Excel Config; no new entry requirement.
local Boss=get('ServerScriptService.World.BossCombatService').ForWorld(2)
local Wall=get('ServerScriptService.World.Stage1WallManager').ForWorld(2)
p:SetAttribute('Strength',70000000);session.Data.Strength=70000000
local encounter=Boss.Begin(p,{},1)
equal(encounter.MaxHP,350000000);equal(encounter.GloveBonus,.6)
Boss.Attack(p);near(encounter.HP,350000000-70000000*1.6,'Glove affects Boss only')
Boss.Reset(p);equal(Boss.Begin(p,{},1).HP,350000000,'Retry reset HP')
Wall.InitializePlayer(p,1);local snapshot=Wall.GetSnapshotForStage(p,1);equal(snapshot.Gauges[1],140000000)
Wall.ApplyDamageForStage(p,1,10);equal(Wall.GetGaugeForStage(p,1,1),139999990,'No Glove added to wall')
Wall.InitializePlayer(p,1);equal(Wall.GetGaugeForStage(p,1,1),140000000,'Wall reset uses approved Config')

-- Existing actual collection handler: physical predicate is an explicit adapter.
local M={GetWinMultiplier=function()return 3 end}
local winChunk=assert(loadstring(SOURCES['Test.WinReward']));setfenv(winChunk,setmetatable({M=M},{__index=env}));pass.GetWinReward=winChunk()
equal(pass.GetWinReward(p,3000,2),3000,'No borrowed World1 Win pass');equal(pass.GetWinReward(p,1,1),3,'W1 reward-pass path unchanged')
local record={Owner=p,Stage=1,Id=1,Hitbox=node('Hitbox','Part'),Claiming=false,Collected=false}
local records={[p]={[1]=record}};local resets=0
local trophy={GetLobbySpawn=function()return {CFrame=CF.new(),Size=V.new(5,1,5)}end,Clear=function(player)records[player]=nil end}
function W:GetPartsInPart()return {hrp}end
local collectEnv=setmetatable({M=trophy,records=records,worldId=2,PlayerData=Data,GamePass=pass,
 RewardConfig=Rewards,WorldGateConfig=get('ReplicatedStorage.Config.WorldGateConfig'),Players=Players,RunService=runService,
 isDefeated=function()return true end,remote={FireClient=function()end},resetRun=function()resets+=1 end,
 OverlapParams={new=function()return {}end},Enum={RaycastFilterType={Include=1}},
},{__index=env})
local chunk=assert(loadstring(SOURCES['Test.TrophyCollect']));setfenv(chunk,collectEnv);local collect=chunk()
local beforeReward=session.Data.Win
p:SetAttribute('CurrentWorld',1);collect(p,record,hrp);equal(session.Data.Win,beforeReward,'Old-world pickup ignored')
p:SetAttribute('CurrentWorld',2);collect(p,record,hrp);collect(p,record,hrp)
equal(session.Data.Win,beforeReward+3000,'One pickup credits once');equal(resets,1,'Pickup returns and resets one run')

-- The same Back service selects World2's run identity and never banks/grants twice.
local runState={RunReturnId=guid(),Defeated={}}
local worldInitializations,bankCalls,invalidations=0,0,0
local enemy2={GetPlayerState=function()return runState end,IsReady=function()return true end,
 InitializePlayer=function(player)
  worldInitializations+=1;runState={RunReturnId=guid(),Defeated={}};player:SetAttribute('World2RunId',runState.RunReturnId)
  player:SetAttribute('World2CurrentStage',1);Wall.InitializePlayer(player,1)
 end}
local enemy1={IsReady=function()return true end,InitializePlayer=function()end}
moduleNode('ServerScriptService.World.EnemyManager').stub={ForWorld=function(w)return w==2 and enemy2 or enemy1 end}
moduleNode('ServerScriptService.Services.TrophyRewardService').stub={ForWorld=function()return trophy end}
moduleNode('ServerScriptService.Services.RunInventoryService').stub={Invalidate=function()invalidations+=1 end}
moduleNode('ServerScriptService.Services.RunItemBankService').stub={Commit=function()bankCalls+=1;return true,'Banked',{Character=character}end}
moduleNode('ServerScriptService.Services.SpeedService').stub={GetState=function()return {WalkSpeed=16}end}
local Return=get('ServerScriptService.Services.RunReturnService')
Wall.ApplyDamageForStage(p,1,1e15);p:SetAttribute('World2CurrentStage',1)
local winBeforeReturn=session.Data.Win;local id=runState.RunReturnId
check(Return.Request(p,id),'World2 Back after walls unlock')
equal(worldInitializations,1);equal(bankCalls,0,'World2 already durable drops do not call World1 bag bank')
equal(session.Data.Win,winBeforeReturn,'Back never grants a Win reward')
equal(select(2,Return.Request(p,id)),'StaleRun','Old return replay rejected')
equal(select(2,Return.Request(p,runState.RunReturnId)),'NotReturnable','Fresh locked stage cannot return')
p:SetAttribute('CurrentWorld',1);check(Return.Request(p,'world1-fixture'))
equal(bankCalls,1,'World1 bank path retained');equal(invalidations,1,'World1 run retirement retained')
p:SetAttribute('CurrentWorld',2)
local Stand=get('ReplicatedStorage.Config.DumbbellStandConfig')
equal(Stand.GetItemId(12,2),'W2_NORMAL_12');equal(Stand.GetItemId(12,1),'NORMAL_12');equal(Stand.GetItemId(13,2),nil)
equal(#Dumbbells.GetSorted(1),12);equal(#Dumbbells.GetSorted(2),12)

-- Unchanged World1 definitions in the candidate are compared to the actual input.
if next(BASELINE)then
 local savedSources=SOURCES;local savedLoaded=loaded
 SOURCES=table.clone(savedSources);loaded={}
 for path,source in pairs(BASELINE)do SOURCES[path]=source end
 local originalDumbbells=get('ReplicatedStorage.Config.DumbbellItemMaster')
 for id,item in pairs(originalDumbbells.GetAll())do
  local now=Dumbbells.Get(id)
  for _,field in ipairs({'ItemId','PriceWin','StrengthBonus','Image','Grade'})do equal(now[field],item[field],'W1 Dumbbell '..field)end
 end
 local originalItems=get('ReplicatedStorage.Config.ItemMaster')
 for id,item in pairs(originalItems.GetAll())do local now=Master.Get(id);for _,field in ipairs({'WinPrice','ShopPurchasable','RobuxPurchasable','Image','ItemType','Rarity','Element'})do equal(now[field],item[field],'W1 Item unchanged')end end
 local originalAuras=get('ReplicatedStorage.Config.AuraConfig')
 for id,aura in pairs(originalAuras.GetAll())do local now=Auras.Get(id);for _,field in ipairs({'StrengthBonus','Price','GamePassId','Icon','VisualTemplate'})do equal(now[field],aura[field],'W1 Aura unchanged')end end
 local originalEgg=get('ReplicatedStorage.Modules.Egg');local originalPet=get('ReplicatedStorage.Modules.Pet')
 for _,id in ipairs(originalEgg.NormalOrder)do equal(Egg.price(id),originalEgg.price(id));for name,percent in pairs(originalEgg.pets(id))do equal(Egg.pets(id)[name],percent);equal(Pet.StrengthPercent(name),originalPet.StrengthPercent(name))end end
 local originalRebirth=get('ReplicatedStorage.Config.RebirthConfig')
 for priorCount=10,29 do equal(Rebirth.GetRequiredLevel(priorCount),originalRebirth.GetRequiredLevel(priorCount),'Legacy R11+ levels retained')end
 SOURCES=savedSources;loaded=savedLoaded
end
print('WORLD2_GAMEPLAY_OFFLINE_PASS assertions='..count..' (simulation only)')
