-- Manual V5 regression suite: isolated services and stores; no production player mutations.
local T={}
function T.Run(filter)
 assert(game:GetService("RunService"):IsRunning(),"Run on the Play server")
 local folder=Instance.new("Folder");folder.Name="V5TemporaryTests";folder.Parent=game.ServerStorage
 local results={}
 local function check(group,name,fn)
  if filter and filter~=group then return end
  local ok,err=pcall(fn)
  table.insert(results,{Group=group,Name=name,Pass=ok,Error=not ok and tostring(err) or nil})
 end
 local function replace(source,old,new)
  local a,b=source:find(old,1,true);assert(a,"Missing test seam: "..old)
  return source:sub(1,a-1)..new..source:sub(b+1)
 end
 local function compile(name,source)
  local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=folder
  return require(m)
 end
 local function signal()
  local handlers={}
  return {Connect=function(_,fn) table.insert(handlers,fn);return {Disconnect=function() end} end,
   Fire=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end}
 end
 local function fakePlayer(id)
  local p={TestPlayer=true,UserId=id or 999001,Name="V5Test",Attributes={},CharacterAdded=signal()}
  function p:IsA(kind) return kind=="Player" end
  function p:GetAttribute(k) return self.Attributes[k] end
  function p:SetAttribute(k,v) self.Attributes[k]=v end
  return p
 end
 local shim='local rawTypeof=typeof;local function typeof(v) if type(v)=="table" and v.TestPlayer then return "Instance" end return rawTypeof(v) end\n'
 local ok,unexpected=xpcall(function()
check("Boss","Stages 1-10 HP, ratios, no RNG at >=100%, win/miss and five hits",function()
 local cfg=require(game.ReplicatedStorage.Config.World1BossConfig)
 local expected={100,400,800,2500,6000,20000,70000,200000,600000,2000000}
 local src=game.ServerScriptService.World.BossCombatService.Source
 src=replace(src,"require(script.Parent.StrengthManager)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 src=replace(src,"require(script.Parent.ItemService)","{GetGloveBossDamageBonus=function(p) return p.Bonus or 0 end}")
 src=replace(src,"local rng=Random.new()","local rng=Deps.Rng")
 local make=compile("BossFactory","return function(Deps) "..src.." end")
 local draws,roll=0,0
 local b=make({Rng={NextNumber=function() draws+=1;return roll end}})
 local cases={{.5999,0},{.6,.25},{.6999,.25},{.7,.5},{.7999,.5},{.8,.8},{.8499,.8},{.85,.85},{.8999,.85},{.9,.9},{.9499,.9},{.95,.95},{.9999,.95},{1,0}}
 local wall=compile("Wall",game.ServerScriptService.World.Stage1WallManager.Source)
 for stage,required in ipairs(expected) do
  assert(cfg.GetRequiredStrength(stage)==required and cfg.GetMaxHP(stage)==required*5)
  assert(b.GetStageConfig(stage).RecommendedLevel==stage*5 and wall.Config[stage].BossMaxHP==required*5)
  for _,c in ipairs(cases) do
   assert(b.GetStrengthRatioWinChance(c[1])==c[2])
   local p=fakePlayer();p:SetAttribute("Strength",required*c[1])
   local before=draws;roll=0;local s=b.Begin(p,{},stage)
   assert(s.Chance==c[2])
   assert(s.Route==(c[1]>=1 and "LEVEL_DAMAGE" or c[2]>0 and "LOTTERY_WIN" or "LOTTERY_MISS"))
   assert(draws-before==(c[2]>0 and 1 or 0))
  end
  for _,r in {0,.99} do
   roll=r;local p=fakePlayer();p:SetAttribute("Strength",required*.8)
   local s=b.Begin(p,{},stage)
   for hit=1,5 do assert(b.Attack(p)==(hit<5 and "Active" or r==0 and "Win" or "Lose")) end
   assert(s.Attacks==5)
  end
  local p=fakePlayer();p:SetAttribute("Strength",required);local before=draws
  b.Begin(p,{},stage);for hit=1,5 do assert(b.Attack(p)==(hit==5 and "Win" or "Active")) end
  assert(draws==before)
 end
end)

check("Rebirth","World1 requirements, cap, retained R6+, reset preservation and treadmill values",function()
 local C=require(game.ReplicatedStorage.Config.RebirthConfig)
 local R=require(game.ReplicatedStorage.Config.RebirthMultiplierConfig)
 for n,v in ipairs({10,15,22,30,45}) do assert(C.GetRequiredLevel(n-1)==v) end
 for n,v in ipairs({1,1.5,2,2.5,3,3.5}) do assert(R.GetMultiplier(n-1)==v) end
 assert(C.World1MaxRebirth==5 and C.IsWorld1Max(5) and C.IsWorld1Max(7))
 assert(C.GetRequiredLevel(5)==40 and C.GetRequiredLevel(6)==50 and R.GetMultiplier(7)==4.5)
 local request={OnServerEvent=signal(),FireClient=function(_,p,r) p.Response=r end}
 local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function() return {} end}
 local D={IsLoaded=function() return true end,IsSaving=function() return false end,
 SetRebirthCount=function(p,n) p:SetAttribute("RebirthCount",n) end}
 local S={GetRebirthCount=function(p) return p:GetAttribute("RebirthCount") end,
 GetStrength=function(p) return p:GetAttribute("Strength") end,CalculateLevel=function(v) return v end,
 ResetGainRemainder=function() end,SetStrength=function(p,v) p:SetAttribute("Strength",v);p:SetAttribute("Level",1) end}
 local source=game.ServerScriptService.Systems.Controllers.RebirthService.Source
 source=replace(source,'local Players=game:GetService("Players")','local Players=Deps.Players')
 source=replace(source,'local Strength=require(script.Parent:WaitForChild("StrengthManager"))','local Strength=Deps.Strength')
 source=replace(source,'local PlayerData=require(script.Parent:WaitForChild("PlayerDataService"))','local PlayerData=Deps.Data\n')
 source=replace(source,'local request=RS.Remotes:WaitForChild("RebirthRequest")','local request=Deps.Request')
 compile("RebirthFactory","return function(Deps)\n"..source.."\nend")({Players=players,Strength=S,Data=D,Request=request})
 for count=0,4 do
  local p=fakePlayer();p:SetAttribute("RebirthCount",count);p:SetAttribute("Strength",C.GetRequiredLevel(count)-1)
  p:SetAttribute("Win",4321);p.OwnedSpeeds={Speed1=true};p.Equipment={Dumbbell="NORMAL_07"};p.WalkSpeed=32
  request.OnServerEvent:Fire(p,"Request");assert(p.Response.Type=="Denied" and p:GetAttribute("RebirthCount")==count)
  p:SetAttribute("Strength",C.GetRequiredLevel(count));request.OnServerEvent:Fire(p,"Request")
  assert(p.Response.Type=="Success" and p:GetAttribute("Strength")==0 and p:GetAttribute("Level")==1)
  assert(p:GetAttribute("Win")==4321 and p.OwnedSpeeds.Speed1 and p.Equipment.Dumbbell=="NORMAL_07" and p.WalkSpeed==32)
 end
 for _,n in ipairs({5,7,30}) do
  local p=fakePlayer();p:SetAttribute("RebirthCount",n);p:SetAttribute("Strength",10000)
  request.OnServerEvent:Fire(p,"Request")
  assert(p.Response.Reason=="World1Max" and p:GetAttribute("RebirthCount")==n and p:GetAttribute("Strength")==10000)
 end
 local TC=require(game.ReplicatedStorage.Config.TreadmillConfig)
 assert(TC.Types.Normal.Multiplier==1 and TC.Types.Rebirth3.Multiplier==3 and TC.Types.Rebirth7.Multiplier==5)
 assert(TC.Types.Premium.Multiplier==20 and TC.PremiumTreadmillPassId==0)
 for name in pairs(TC.Assignments) do
  local model=workspace.Treadmill:FindFirstChild(name);assert(model and model:FindFirstChild("TrainingZone"))
  assert(model:GetAttribute("VirtualStepInterval")==0.5)
  assert(TC.GetDisplayText(name):find("×"..TC.Get(name).Multiplier,1,true))
 end
end)
check("Dumbbell","All grades: V5 price, purchase, duplicate rejection, equip and future grade",function()
 local Master=require(game.ReplicatedStorage.Config.DumbbellItemMaster)
 local expectedPrices={5,15,40,100,250,600,1500}
 local expectedBonus={2,4,8,25,60,150,300}
 local session={Loaded=true,Data={OwnedDumbbells={},EquippedDumbbell=""}}
 local D={Get=function() return session end,SetWin=function(p,w) p:SetAttribute("Win",w);return true end,
 SetEquippedDumbbell=function(p,id) if session.Data.OwnedDumbbells[id] then session.Data.EquippedDumbbell=id;return true end return false end}
 local source=replace(game.ServerScriptService.Services.DumbbellService.Source,'local Data = require(script.Parent:WaitForChild("PlayerDataService"))','local Data=Deps.Data')
 local factory=compile("DumbbellFactory","return function(Deps)\n"..shim..source.."\nend")
 local service=factory({Data=D})
 local p=fakePlayer();p.Parent=game.Players
 for i,item in ipairs(Master.GetSorted()) do
  assert(item.Grade==i and item.PriceWin==expectedPrices[i] and item.StrengthBonus==expectedBonus[i])
  p:SetAttribute("Win",item.PriceWin-1);assert(not service.PurchaseDumbbell(p,item.ItemId))
  p:SetAttribute("Win",item.PriceWin);assert(service.PurchaseDumbbell(p,item.ItemId));assert(p:GetAttribute("Win")==0)
  assert(not service.PurchaseDumbbell(p,item.ItemId));assert(p:GetAttribute("Win")==0)
  assert(service.EquipDumbbell(p,item.ItemId));assert(service.GetStrengthBonus(p)==item.StrengthBonus)
  assert(item.Mergeable and item.Image=="rbxassetid://"..item.ImageAssetId)
 end
 assert(#Master.GetSorted()==7)
 local future=replace(game.ReplicatedStorage.Config.DumbbellItemMaster.Source,'for _, item in ipairs(definitions) do','table.insert(definitions,{ItemId="NORMAL_08",Name="Future",Grade=8,PriceWin=12345,StrengthBonus=123,ImageAssetId=1})\nfor _, item in ipairs(definitions) do')
 local M8=compile("FutureMaster",future);assert(#M8.GetSorted()==8 and M8.GetSorted()[8].ItemId=="NORMAL_08")
 local service8=factory({Data=D})
 -- The same actual service accepts a future definition through its Master dependency.
 local dynamic=replace(source,'local Master = require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))','local Master=Deps.Master')
 service8=compile("FutureDumbbellFactory","return function(Deps)\n"..shim..dynamic.."\nend")({Data=D,Master=M8})
 p:SetAttribute("Win",12345);assert(service8.PurchaseDumbbell(p,"NORMAL_08"));assert(service8.EquipDumbbell(p,"NORMAL_08"))
 assert(service8.GetStrengthBonus(p)==123 and p:GetAttribute("Win")==0)
end)
check("Economy","Aura prices, purchase/equip, Robux exclusion and notifications",function()
 local C=require(game.ReplicatedStorage.Config.AuraConfig)
 local p=fakePlayer();p.Parent=game.Players
 local s={Loaded=true,Data={Win=0,OwnedAuras={},EquippedAura=""}}
 local D={Get=function() return s end,SetWin=function(_,v) s.Data.Win=v;return true end,
 Save=function(_,id) if id then s.Data.EquippedAura=id end return true end,
 SetEquippedAura=function(_,id) s.Data.EquippedAura=id;return true end}
 local src=replace(game.ServerScriptService.Services.AuraService.Source,'local Data=require(script.Parent:WaitForChild("PlayerDataService"))','local Data=Deps.Data')
 local A=compile("AuraFactory","return function(Deps)\n"..shim..src.."\nend")({Data=D})
 local N=compile("AuraNotify",game.StarterGui.StrengthGui.AuraPurchaseNotifications.Source)
 local prices={25,75,200,500,1250}
 for i,id in ipairs(C.Order) do if id~="Red" then
  assert(C.Get(id).Price==prices[i])
  s.Data.Win=prices[i]-1;assert(not A.PurchaseAura(p,id))
  s.Data.Win=prices[i];assert(A.PurchaseAura(p,id));assert(s.Data.Win==0)
  assert(not A.PurchaseAura(p,id));assert(A.EquipAura(p,id));assert(A.GetStrengthBonus(p)==C.Get(id).StrengthBonus)
 end end
 assert(C.Get("Red").StrengthBonus==1000 and C.Get("Red").GamePassId==1975173075)
 assert(not A.PurchaseAura(p,"Red"))
 local flags,any=N.Evaluate(true,s.Data.OwnedAuras,100000);assert(not any and flags.Red==nil)
 local _,can=N.Evaluate(true,{},249);assert(not can)
 local _,can2=N.Evaluate(true,{},250);assert(can2)
end)
check("Economy","All Item prices/effects and Win rejection for Epic/Legendary; unchanged gated drops",function()
 local Master=require(game.ReplicatedStorage.Config.ItemMaster)
 local FX=require(game.ReplicatedStorage.Config.ItemMultiplierConfig)
 local p=fakePlayer();p.Parent=game.Players
 local s={Loaded=true,Data={OwnedItems={},EquippedItems={}}}
 local D={Get=function() return s end,ChangeItemCount=function(_,id,n,price)
  s.Data.OwnedItems[id]=(s.Data.OwnedItems[id] or 0)+n;p:SetAttribute("Win",p:GetAttribute("Win")-(price or 0));return true
 end}
 local src=replace(game.ServerScriptService.Services.ItemService.Source,'local Data = require(script.Parent:WaitForChild("PlayerDataService"))','local Data=Deps.Data')
 local I=compile("ItemFactory","return function(Deps)\n"..shim..src.."\nend")({Data=D})
 local prices={Common=75,Uncommon=200,Rare=600}
 for id,item in pairs(Master.GetAll()) do
  local price=prices[item.Rarity]
  if price then
   assert(item.WinPrice==price and item.ShopPurchasable)
   p:SetAttribute("Win",price-1);assert(not I.PurchaseItemWithWin(p,id))
   p:SetAttribute("Win",price);assert(I.PurchaseItemWithWin(p,id));assert(p:GetAttribute("Win")==0)
   assert(I.EquipItem(p,id))
  else
   p:SetAttribute("Win",100000);assert(not I.PurchaseItemWithWin(p,id));assert(p:GetAttribute("Win")==100000 and not item.ShopPurchasable)
  end
 end
 for i,r in ipairs(Master.Rarities) do
  assert(FX.GetProteinBonus(r)==({1,15,30,50,150})[i])
  assert(FX.GetGloveBossDamageBonus(r)==({.05,.1,.2,.35,.5})[i])
  assert(FX.GetBeltTreadmillBonus(r)==({.25,.5,1,1.5,2})[i])
 end
 local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
 assert(Master.DropHitChance==.2)
 for stage=1,10 do
  local total=stage<5 and 97 or (stage<8 and 99 or 100)
  local counts={}
  for n=1,total do
   local r=Roller.RollRarity({NextInteger=function(_,lo,hi) assert(lo==1 and hi==total);return n end},stage)
   counts[r]=(counts[r] or 0)+1
  end
  assert(counts.Common==80 and counts.Uncommon==13 and counts.Rare==4)
  assert((counts.Epic or 0)==(stage>=5 and 2 or 0))
  assert((counts.Legendary or 0)==(stage>=8 and 1 or 0))
 end
end)
check("Economy","All Stage Trophy rewards, double Win, overlap collection, reset and duplicate rejection",function()
 local C=require(game.ReplicatedStorage.Config.TrophyRewardConfig)
 local expected={1,5,15,40,100,250,500,750,1000,5000}
 local heartbeat=signal()
 local players={PlayerRemoving=signal()}
 local p=fakePlayer();p.Parent=players;p:SetAttribute("Win",0)
 local rig=Instance.new("Model");rig.Parent=folder
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Parent=rig
 local hum=Instance.new("Humanoid");hum.Parent=rig
 p.Character=rig
 local resets,multiplier=0,1
 local src=game.ServerScriptService.Services.TrophyRewardService.Source
 src=replace(src,'local Players = game:GetService("Players")','local Players=Deps.Players')
 src=replace(src,'local RunService = game:GetService("RunService")','local RunService=Deps.RunService')
 src=replace(src,'local GamePass = require(game.ServerScriptService.Services:WaitForChild("GamePassService"))','local GamePass=Deps.GamePass')
 src=replace(src,'local PlayerData = require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))','local PlayerData=Deps.Data')
 src=replace(src,'hitboxes.Parent = workspace','hitboxes.Parent = Deps.Folder')
 for _=1,2 do src=replace(src,'workspace:GetPartsInPart(record.Hitbox, params)','Deps.Overlap(record.Hitbox, params)') end
 local V=compile("TrophyFactory","return function(Deps)\n"..src.."\nend")({
 Players=players,RunService={Heartbeat=heartbeat},Folder=folder,
 GamePass={GetWinReward=function(_,base) return base*multiplier end},
 Data={Get=function() return {Loaded=true,Data={OwnedDumbbells={}}} end,CompleteTutorial=function() end},
 Overlap=function() return {root} end})
 local packets={}
 V.Initialize(workspace.GeneratedMap,{FireClient=function(_,_,packet) table.insert(packets,packet) end},function() resets+=1 end,function() return true end)
 for times=1,2 do
  multiplier=times
  for stage,reward in ipairs(expected) do
   assert(C.GetBaseReward(stage)==reward)
   local before=p:GetAttribute("Win")
   assert(V.Spawn(p,stage));assert(not V.Spawn(p,stage))
   local box=folder.PersonalTrophyHitboxes:FindFirstChild("Trophy_"..p.UserId.."_Stage"..stage)
   assert(box and box:GetAttribute("WinReward")==reward)
   heartbeat:Fire(.1);assert(p:GetAttribute("Win")==before+reward*multiplier)
   heartbeat:Fire(.1);assert(p:GetAttribute("Win")==before+reward*multiplier)
   assert(#folder.PersonalTrophyHitboxes:GetChildren()==0)
  end
 end
 assert(resets==20)
end)
check("Progression","V5 walking/training formula, fractions, level and unchanged Potion behavior",function()
 local recorded=0
 local src=game.ServerScriptService.Services.StrengthManager.Source
 for _,name in ipairs({"PlayerDataService","DumbbellService","ItemService","AuraService","PotionService"}) do
  src=replace(src,'require(script.Parent:WaitForChild("'..name..'"))','Deps.'..name)
 end
 local potion=1
 local S=compile("StrengthFactory","return function(Deps)\n"..shim..src.."\nend")({
 PlayerDataService={SetCurrentStrength=function() return true end,RecordStrengthGain=function(_,n) recorded+=n end},
 DumbbellService={GetStrengthBonus=function() return 100 end},AuraService={GetStrengthBonus=function() return 10 end},
 ItemService={GetProteinBonus=function() return 5 end},PotionService={GetStrengthMultiplier=function() return potion end}})
 local p=fakePlayer();p:SetAttribute("RebirthCount",1);p:SetAttribute("Strength",0)
 assert(S.AddStrength(p,1,1)==24) -- (1+10+5)*1.5, no Dumbbell when walking.
 assert(S.AddStrength(p,2,2)==72)
 S.SetStrength(p,0);assert(S.AddStrength(p,1,1,1)==174)
 S.SetStrength(p,0);assert(S.AddStrength(p,1,1,3.25)==565.5)
 potion=2;S.SetStrength(p,0);assert(S.AddStrength(p,1,1,3.25)==1131)
 local L=require(game.ReplicatedStorage.Config.LevelRequirements)
 assert(p:GetAttribute("Level")==L.CalculateLevel(1131))
 assert(recorded>0)
end)
check("Progression","Stage1–10 wall carryover, boss unlock, next Stage, completion and Run Reset",function()
 local Stage=compile("StageState",game.ServerScriptService.World.StageManager.Source)
 local Wall=compile("WallState",game.ServerScriptService.World.Stage1WallManager.Source)
 local p=fakePlayer()
 Stage.InitializePlayer(p);Wall.InitializePlayer(p)
 for n=1,10 do
  assert(Stage.GetCurrentStageNumber(p)==n)
  assert(not Stage.ClearStage(p,n+1))
  assert(not Wall.IsBossUnlockedForStage(p,n))
  local mapStage=workspace.GeneratedMap.BattleCorridor:FindFirstChild(("Stage%02d"):format(n))
  assert(mapStage and mapStage:FindFirstChild(("Stage%d.5"):format(n)))
  local sum=0 for i,hp in ipairs(Wall.Config[n].Walls) do
   assert(mapStage:FindFirstChild(("Stage%d.%d"):format(n,i)));sum+=hp
  end
  local cleared,index,carry=Wall.ApplyDamageForStage(p,n,sum+123)
  assert(#cleared==4 and index==5 and carry==123 and Wall.IsBossUnlockedForStage(p,n))
  assert(Stage.ClearStage(p,n) and Stage.IsStageCleared(p,n))
 end
 assert(Stage.GetState(p).WorldComplete and p:GetAttribute("WorldComplete"))
 Stage.ResetPlayer(p);Wall.InitializePlayer(p)
 assert(Stage.GetCurrentStageNumber(p)==1 and not Stage.GetState(p).WorldComplete)
 for n=1,10 do assert(not Stage.IsStageCleared(p,n) and not Wall.IsBossUnlockedForStage(p,n)) end
end)
check("Progression","PlayerData_v1 legacy defaults and full save/reload without reset, including R7 and unknown IDs",function()
 local Http=game.HttpService
 local function copy(v) return v and Http:JSONDecode(Http:JSONEncode(v)) end
 local raw={Strength=54321,RebirthCount=7,Win=8765,TotalStrengthEarned=99999,
 OwnedDumbbells={NORMAL_07=true,FUTURE_DUMBBELL=true},EquippedDumbbell="NORMAL_07",
 OwnedAuras={Blue=true,Red=true},EquippedAura="Blue",
 OwnedItems={PROTEIN_RARE_FIRE=true,GLOVE_LEGENDARY_ICE=2},EquippedItems={Protein="PROTEIN_RARE_FIRE",Glove="GLOVE_LEGENDARY_ICE"},
 OwnedSpeeds={Speed1=true},TimeRewards={ElapsedSeconds=300,Claimed={V5_TEST=true}},
 DailyRewards={ClaimedDays=2,LastClaimDateUTC="2026-09-01"},CommunityRewards={Claimed=true},
 TutorialCompleted=true,StageProgress={LegacyMarker=10},GamePassCache={Legacy=true},Version=1}
 local records={Player_999001=copy(raw)}
 local writes=0
 local fakeStore={GetAsync=function(_,k) return copy(records[k]) end,
 UpdateAsync=function(_,k,fn) local value=fn(copy(records[k]));if value then records[k]=copy(value);writes+=1 end return copy(records[k]) end}
 local dss={GetDataStore=function(_,name) assert(name=="PlayerData_v1");return fakeStore end,
 GetOrderedDataStore=function() return {SetAsync=function() end} end}
 local src=replace(game.ServerScriptService.Services.PlayerDataService.Source,'local DSS=game:GetService("DataStoreService")','local DSS=Deps')
 local factory=compile("DataFactory","return function(Deps)\n"..src.."\nend")
 local D=factory(dss);local p=fakePlayer()
 assert(D.Load(p));assert(writes==0)
 local d=D.Get(p).Data
 assert(d.RebirthCount==7 and d.OwnedItems.PROTEIN_RARE_FIRE==1 and d.OwnedSpeeds.Speed1)
 assert(D.Save(p));D.Release(p);D=factory(dss);assert(D.Load(p))
 d=D.Get(p).Data
 assert(d.Strength==54321 and d.Win==8765 and d.RebirthCount==7)
 assert(d.OwnedDumbbells.NORMAL_07 and d.OwnedDumbbells.FUTURE_DUMBBELL and d.EquippedDumbbell=="NORMAL_07")
 assert(d.OwnedAuras.Red and d.EquippedAura=="Blue" and d.OwnedItems.GLOVE_LEGENDARY_ICE==2)
 assert(d.EquippedItems.Glove=="GLOVE_LEGENDARY_ICE" and d.EquippedItems.TrainingBelt=="")
 assert(d.OwnedSpeeds.Speed1 and d.TimeRewards.Claimed.V5_TEST and d.DailyRewards.ClaimedDays==2 and d.CommunityRewards.Claimed)
 assert(records.Player_999001.StageProgress.LegacyMarker==10 and records.Player_999001.GamePassCache.Legacy and records.Player_999001.Version==1)
 records.Player_999002={Strength=77,Win=8,RebirthCount=0}
 local q=fakePlayer(999002);assert(D.Load(q));local old=D.Get(q).Data
 assert(old.Strength==77 and old.Win==8 and next(old.OwnedSpeeds)==nil and next(old.OwnedDumbbells)==nil)
 assert(old.TimeRewards.ElapsedSeconds==0 and old.DailyRewards.ClaimedDays==0)
end)
check("Progression","Existing full Speed purchase, save, respawn, controller and fixed walking interval suite",function()
 local results=require(game.ServerStorage.Tests.SpeedFeatureTests).Run()
 for _,result in ipairs(results) do assert(result.Pass,result.Name..": "..tostring(result.Error)) end
 assert(#results>=16)
end)
check("Integration","Glove/carryover and actual Enemy defeat ordering through Stage10",function()
 local src=game.ServerScriptService.World.BossCombatService.Source
 src=replace(src,"require(script.Parent.StrengthManager)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 src=replace(src,"require(script.Parent.ItemService)","{GetGloveBossDamageBonus=function(p) return p.Bonus or 0 end}")
 src=replace(src,"local rng=Random.new()","local rng={NextNumber=function() return 0 end}")
 local B=compile("IntegrationBoss",src)
 local Stage=compile("IntegrationStage",game.ServerScriptService.World.StageManager.Source)
 local C=require(game.ReplicatedStorage.Config.World1BossConfig)
 local p=fakePlayer();p.Parent=game.Players;p.Character={FindFirstChildOfClass=function() return {Health=100} end}
 Stage.InitializePlayer(p)
 local ps={Gauges={},Defeated={}};local enemies={};local sessions={}
 local queue={};local packets={};local trophies,drops,respawns=0,0,0
 local es=game.ServerScriptService.World.EnemyManager.Source
 local a=assert(es:find("local function defeat(p,n)",1,true));local z=assert(es:find("local function monitor()",a,true))
 local part=es:sub(a,z-1)
 local prefix=[[return function(D)
 local enemies,sessions=D.Enemies,D.Sessions
 local Players=game.Players
 local Boss,Stage,Trophy,ItemDrops=D.Boss,D.Stage,D.Trophy,D.Drops
 local state,send,spawnEnemy=D.State,D.Send,D.Spawn
 local map={}
 local task={delay=function(t,fn) table.insert(D.Queue,{Time=t,Run=fn}) end}
 ]]
 local defeat=compile("DefeatFactory",prefix..part.." return defeat end")({
 Enemies=enemies,Sessions=sessions,Boss=B,Stage=Stage,Queue=queue,
 State=function() return ps end,Send=function(_,packet) table.insert(packets,packet) end,
 Trophy={Spawn=function(_,n) assert(Stage.IsStageCleared(p,n));trophies+=1 end},
 Drops={OnEnemyDefeated=function() drops+=1 end},Spawn=function() respawns+=1 end})
 for n=1,10 do
  local boss={};enemies[n]=boss
  p.Bonus=.5;p:SetAttribute("Strength",C.GetRequiredStrength(n))
  B.QueueDamage(p,boss,n,C.GetMaxHP(n),10)
  local s=B.Begin(p,boss,n)
  assert(s.Route=="LEVEL_DAMAGE" and s.HP==s.MaxHP-10 and s.BattleDamage==s.Strength*1.5)
  local outcome
  for _=1,4 do outcome=B.Attack(p) end
  assert(outcome=="Win")
  sessions[p]={};defeat(p,n);defeat(p,n)
  assert(ps.Defeated[n] and sessions[p]==nil and ps.Gauges[n]==0)
  assert(#queue==3 and queue[1].Time==.05 and queue[2].Time==.3 and queue[3].Time==.6)
  for _,v in ipairs(queue) do v.Run() end table.clear(queue)
  assert(Stage.IsStageCleared(p,n))
 end
 assert(Stage.GetState(p).WorldComplete and trophies==10 and drops==10 and respawns==10)
 local q=fakePlayer();q.Bonus=.5;q:SetAttribute("Strength",80)
 local boss={};B.QueueDamage(q,boss,1,500,10000);local s=B.Begin(q,boss,1)
 assert(s.Route=="LOTTERY_WIN" and s.HP==1)
 for hit=1,5 do assert(B.Attack(q)==(hit==5 and "Win" or "Active")) end
end)
check("Integration","Speed UI isolated unowned/owned buttons, dynamic Robux price and affordability notification",function()
 local gui=game.StarterGui.StrengthGui:Clone();gui.Parent=folder
 for _,v in ipairs(gui:GetDescendants()) do if v:IsA("LuaSourceContainer") then v:Destroy() end end
 local p=fakePlayer();p:SetAttribute("Win",499)
 local change=signal();function p:GetAttributeChangedSignal() return change end
 local purchase={OnClientEvent=signal(),FireServer=function() end}
 local prompt={OnClientEvent=signal(),FireServer=function() end}
 local state={Loaded=true,OwnedSpeeds={},PremiumOwned=false}
 local stateRemote={InvokeServer=function() return state end}
 local Config=require(game.ReplicatedStorage.Config.SpeedConfig)
 local market={PromptGamePassPurchaseFinished=signal(),GetProductInfoAsync=function(_,id)
  assert(id==Config.Premium.GamePassId);return {PriceInRobux=137}
 end}
 local src=game.StarterGui.StrengthGui.SpeedInventoryClient.Source
 src=replace(src,'local Players=game:GetService("Players")','local Players=Deps.Players')
 src=replace(src,'local Marketplace=game:GetService("MarketplaceService")','local Marketplace=Deps.Market')
 src=replace(src,'local gui=script.Parent','local gui=Deps.Gui')
 src=replace(src,'local purchase=RS.Remotes:WaitForChild("SpeedPurchaseRequest")','local purchase=Deps.Purchase')
 src=replace(src,'local stateRemote=RS.Remotes:WaitForChild("SpeedInventoryState")','local stateRemote=Deps.State')
 src=replace(src,'local prompt=RS.Remotes:WaitForChild("SpeedPremiumPrompt")','local prompt=Deps.Prompt')
 compile("SpeedUIFactory","return function(Deps)\n local task={spawn=function(fn) fn() end}\n"..src.."\nend")({
 Players={LocalPlayer=p},Market=market,Gui=gui,Purchase=purchase,State=stateRemote,Prompt=prompt})
 local page=gui.InventoryPanel.Content.Speed
 local a,b=page.SpeedList.Speed1,page.SpeedList.Premium
 assert(a.Title.Text=="Speed Boost" and b.Title.Text=="Premium Speed")
 for _,c in ipairs({a,b}) do
  assert(not c:FindFirstChild("SpeedValue") and not c:FindFirstChild("Price"))
  assert(c.BuyButton.Active and c.BuyButton.Label.Text=="" and c.BuyButton.Price.Visible)
  local lim=c.Title:FindFirstChildOfClass("UITextSizeConstraint");assert(lim.MinTextSize==18 and lim.MaxTextSize==26 and c.Title.TextScaled)
 end
 assert(a.BuyButton.Price.Amount.Text=="500" and a.BuyButton.Price.CurrencyIcon.Image==gui.WinLabel.TrophyIcon.Image)
 assert(b.BuyButton.Price.Amount.Text=="137" and b.BuyButton.Price.CurrencyIcon.Image~="")
 assert(not gui.InventoryPanel.Tabs.Speed.SpeedPurchaseBadge.Visible)
 p:SetAttribute("Win",500);change:Fire();assert(gui.InventoryPanel.Tabs.Speed.SpeedPurchaseBadge.Visible)
 purchase.OnClientEvent:Fire({State={Loaded=true,OwnedSpeeds={Speed1=true},PremiumOwned=false}})
 assert(a.BuyButton.Label.Text=="OWNED" and not a.BuyButton.Price.Visible)
 assert(not gui.InventoryPanel.Tabs.Speed.SpeedPurchaseBadge.Visible and not gui.LeftMenu.InventoryButton:GetAttribute("SpeedPurchaseAvailable"))
 purchase.OnClientEvent:Fire({State={Loaded=true,OwnedSpeeds={Speed1=true},PremiumOwned=true}})
 assert(b.BuyButton.Label.Text=="OWNED" and not b.BuyButton.Price.Visible)
 gui:Destroy()
end)
check("Integration","Dumbbell notifications derive all grades and future additions from Master",function()
 local src=game.StarterGui.StrengthGui.InventoryNotificationClient.Source
 local a=assert(src:find("local ids={}",1,true));local z=assert(src:find("local HasUnseenItem",a,true))
 local idSource=src:sub(a,z-1)
 a=assert(src:find("local function render()",1,true));z=assert(src:find("local function applyState",a,true))
 local section=src:sub(a,z-1)
 local prefix=[[return function(Dumbbells,Signal)
 local player={Win=0,GetAttribute=function(self) return self.Win end}
 local parent={GetAttribute=function() return false end,GetAttributeChangedSignal=function() return Signal() end}
 local badge={Parent=parent};local panel={Visible=false}
 local HasUnseenItem=false;local itemTabUnseen=false;local itemTabBadge={}
 local affordable,pending,unseen,badges,connections={},{},{},{},{}
 local owned={}
 ]]
 local factory=compile("NotifyFactory",prefix..idSource..section..[[
 return function(win,inventory)
  player.Win=win;owned=inventory;evaluate()
  return badge.Visible,affordable
 end
 end]])
 local Master=require(game.ReplicatedStorage.Config.DumbbellItemMaster)
 local eval=factory(Master,signal)
 for _,item in ipairs(Master.GetSorted()) do
  local all={} for id in pairs(Master.GetAll()) do all[id]=true end all[item.ItemId]=nil
  local any=eval(item.PriceWin-1,all);assert(not any)
  local yes,available=eval(item.PriceWin,all);assert(yes and available[item.ItemId])
  all[item.ItemId]=true;assert(not eval(item.PriceWin,all))
 end
 local extra={ItemId="NORMAL_08",Grade=8,PriceWin=12345}
 local items=table.clone(Master.GetSorted());table.insert(items,extra)
 local dict=table.clone(Master.GetAll());dict.NORMAL_08=extra
 local future=factory({GetSorted=function() return items end,Get=function(id) return dict[id] end},signal)
 local all={} for id in pairs(Master.GetAll()) do all[id]=true end
 assert(not future(12344,all));assert(future(12345,all));all.NORMAL_08=true;assert(not future(12345,all))
end)
check("Treadmill","Actual tier access and scheduled training ticks retain intervals and additive Belt/Potion",function()
 local Players={GetPlayers=function() return {} end}
 local premium=false
 local recorded={}
 local taskFake={}
 local thread
 function taskFake.spawn(fn) thread=coroutine.create(fn);local ok,err=coroutine.resume(thread);assert(ok,err) end
 function taskFake.wait(interval) assert(interval==.5);coroutine.yield() end
 local src=game.ServerScriptService.Services.TrainingManager.Source
 src=replace(src,'local Players=game:GetService("Players")','local Players=Deps.Players')
 for _,name in ipairs({"StrengthManager","GamePassService","ItemService","PotionService"}) do
  src=replace(src,'require(script.Parent:WaitForChild("'..name..'"))','Deps.'..name)
 end
 local M=compile("TrainingFactory","return function(Deps)\nlocal task=Deps.Task\n"..src.."\nend")({
 Players=Players,Task=taskFake,
 StrengthManager={AddStrength=function(_,base,ticks,multiplier) table.insert(recorded,{base,ticks,multiplier}) end},
 GamePassService={HasPremiumTreadmill=function() return premium end},
 ItemService={GetBeltTreadmillBonus=function() return .25 end},PotionService={GetTrainingBonus=function() return .5 end}})
 local p=fakePlayer()
 local rig=Instance.new("Model");rig.Parent=folder
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.new(2,2,1);root.Parent=rig
 local h=Instance.new("Humanoid");h.HipHeight=2;h.Parent=rig
 p.Character=rig
 local Config=require(game.ReplicatedStorage.Config.TreadmillConfig)
 for _,name in ipairs({"Tredmill06","Tredmill04","Tredmill02","Tredmill01"}) do
  local model=workspace.Treadmill[name];local c=Config.Get(name)
  local count=c.RequiredRebirth or 0
  if count>0 then p:SetAttribute("RebirthCount",count-1);assert(not M.CanUseTreadmill(p,model)) end
  p:SetAttribute("RebirthCount",count)
  if c.RequiresPremium then assert(not M.CanUseTreadmill(p,model));premium=true end
  assert(M.CanUseTreadmill(p,model))
  root.CFrame=model.TrainingZone.CFrame*CFrame.new(0,h.HipHeight+root.Size.Y/2,0)
  assert(M.IsPlayerInsideZone(p,model.TrainingZone))
  assert(M.StartTraining(p,model))
  local ok,err=coroutine.resume(thread);assert(ok,err)
  local tick=recorded[#recorded];assert(tick[1]==model:GetAttribute("VirtualStepReward") and tick[2]==1 and tick[3]==c.Multiplier+.75)
  assert(M.StopTraining(p));assert(p:GetAttribute("IsTraining")==false)
 end
 assert(#recorded==4)
end)
 end,debug.traceback)
 folder:Destroy()
 if not ok then table.insert(results,{Group="Harness",Name="Unexpected error",Pass=false,Error=unexpected}) end
 local count=0
 for _,r in ipairs(results) do if r.Pass then count+=1 else warn("[V5 FAIL] "..r.Name..": "..tostring(r.Error)) end end
 return {Passed=count,Failed=#results-count,Results=results}
end
return T
