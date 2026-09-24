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
 local expected={40,160,300,2500,6000,20000,70000,200000,600000,2000000}
 local src=game.ServerScriptService.World.BossCombatService.Source
 src=replace(src,"require(script.Parent.StrengthManager)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 src=replace(src,"require(script.Parent.ItemService)","{GetGloveBossDamageBonus=function(p) return p.Bonus or 0 end}")
 src=replace(src,"local rng=Random.new()","local rng=Deps.Rng")
 local make=compile("BossFactory","return function(Deps) "..src.." end")
 local draws,roll=0,0
 local b=make({Rng={NextNumber=function() draws+=1;return roll end}})
 local cases={{.75,.5},{.5999,0},{.6,.25},{.6999,.25},{.7,.5},{.7999,.5},{.8,.8},{.8499,.8},{.85,.85},{.8999,.85},{.9,.9},{.9499,.9},{.95,.95},{.9999,.95},{1,0}}
 local wall=compile("Wall",game.ServerScriptService.World.Stage1WallManager.Source)
 for stage,required in ipairs(expected) do
  assert(cfg.GetRequiredStrength(stage)==required and cfg.GetMaxHP(stage)==required*5)
  assert(b.GetStageConfig(stage).RecommendedLevel==(stage==1 and 8 or stage*5) and wall.Config[stage].BossMaxHP==required*5)
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

check("Boss","Recommended Level is presentation only; specified early-strength routes",function()
 local C=require(game.ReplicatedStorage.Config.World1BossConfig)
 local source=game.ServerScriptService.World.BossCombatService.Source
 source=replace(source,"require(script.Parent.StrengthManager)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 source=replace(source,"require(script.Parent.ItemService)","{GetGloveBossDamageBonus=function() return 0 end}")
 source=replace(source,'require(game:GetService("ReplicatedStorage").Config:WaitForChild("World1BossConfig"))','Deps.Config')
 source=replace(source,"local rng=Random.new()","local rng={NextNumber=function() return .1 end}")
 local factory=compile("DisplayIndependence","return function(Deps) "..source.." end")
 local variant=table.clone(C);variant.GetRecommendedLevel=function() return 99 end
 local original,changed=factory({Config=C}),factory({Config=variant})
 local cases={{1,30,.75,.5,"LOTTERY_WIN"},{1,40,1,0,"LEVEL_DAMAGE"},
 {2,120,.75,.5,"LOTTERY_WIN"},{2,152,.95,.95,"LOTTERY_WIN"},{2,160,1,0,"LEVEL_DAMAGE"},
 {3,225,.75,.5,"LOTTERY_WIN"},{3,285,.95,.95,"LOTTERY_WIN"},{3,300,1,0,"LEVEL_DAMAGE"}}
 for _,c in ipairs(cases) do
  local p=fakePlayer();p:SetAttribute("Strength",c[2])
  local a=original.Begin(p,{},c[1]);local b=changed.Begin(p,{},c[1])
  assert(a.StrengthRatio==c[3] and a.Chance==c[4] and a.Route==c[5])
  assert(b.RecommendedLevel==99 and a.RecommendedLevel==({8,10,15})[c[1]])
  for _,field in ipairs({"HP","MaxHP","RequiredStrength","BattleDamage","Chance","Route","PlayerLevel"}) do assert(a[field]==b[field],field) end
 end
 for stage,v in pairs({[4]=2500,[5]=6000,[6]=20000,[7]=70000,[8]=200000,[9]=600000,[10]=2000000}) do
  assert(C.GetRequiredStrength(stage)==v and C.GetMaxHP(stage)==v*5)
 end
end)
check("Economy","All Stage Trophy rewards, double Win, overlap collection, reset and duplicate rejection",function()
 local C=require(game.ReplicatedStorage.Config.TrophyRewardConfig)
 local expected={1,3,5,10,30,75,150,300,750,1000}
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
 Players=players,RunService={Heartbeat=heartbeat,IsStudio=function() return true end},Folder=folder,
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
 local counts=V.GetStudioCollectionCounts(p);assert(counts.Total==20)
 for stage=1,10 do assert(counts.ByStage[stage]==2) end
 V.Clear(p);assert(V.GetStudioCollectionCounts(p).Total==20)
end)
 end,debug.traceback)
 folder:Destroy()
 if not ok then table.insert(results,{Group="Harness",Name="Unexpected error",Pass=false,Error=unexpected}) end
 local count=0
 for _,r in ipairs(results) do if r.Pass then count+=1 else warn("[V5 FAIL] "..r.Name..": "..tostring(r.Error)) end end
 return {Passed=count,Failed=#results-count,Results=results}
end
return T
