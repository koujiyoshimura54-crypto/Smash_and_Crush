-- Executed with the actual Config/Wall/Boss Sources and small service adapters.
-- The supplied progression Source is separately identified by the runner.
local checks=0
local function ok(value,label)
 checks+=1
 assert(value,label or "check failed")
end
local function eq(a,b,label) ok(a==b,(label or "value")..": "..tostring(a).." != "..tostring(b)) end
local function near(a,b,label) ok(math.abs(a-b)<=1e-8,(label or "near")..": "..tostring(a).." != "..tostring(b)) end
local function prefix(r,level)
 local total=0
 for previous=1,level-1 do total+=r.GetRequiredStrength(previous) end
 return total
end
local before=MakeProgression(BeforeRequirements)
local after=MakeProgression(AfterRequirements)
local checkpoints={{1,0,0},{2,10,7},{3,40,27},{4,90,60},{5,160,120},{6,250,215},{7,375,360},{8,530,530},{9,720,720},{10,955,955},{11,1245,1245}}
for _,row in checkpoints do
 eq(prefix(BeforeRequirements,row[1]),row[2],"old prefix")
 eq(prefix(AfterRequirements,row[1]),row[3],"new prefix")
 local l,p=after.Advance(1,0,row[3])
 eq(l,row[1],"exact new boundary");eq(p,0,"exact new carry")
 if row[3]>0 then
  l,p=after.Advance(1,0,row[3]-.25)
  eq(l,row[1]-1,"below new boundary")
  l,p=after.Advance(1,0,row[3]+.25)
  eq(l,row[1],"above new boundary");near(p,.25,"fractional carry")
 end
end
local prior=0
for level=1,AfterRequirements.MaxLevel do
 local cost=AfterRequirements.GetRequiredStrength(level)
 ok(cost==cost and cost<math.huge and cost>prior,"finite increasing requirement "..level)
 if level>=8 then eq(cost,BeforeRequirements.GetRequiredStrength(level),"later requirement unchanged") end
 prior=cost
end
-- Rebirth thresholds and both cumulative anchor values remain unchanged.
eq(Rebirth.GetRequiredLevel(0),10)
for count=0,#Rebirth.RebirthRequiredLevels-1 do
 local level=Rebirth.GetRequiredLevel(count)
 eq(prefix(AfterRequirements,level),prefix(BeforeRequirements,level),"rebirth cumulative requirement")
end
-- Preserve the old one-time lookup for unversioned saves, including boundaries.
for strength=0,2000,.25 do
 eq(AfterRequirements.CalculateLevel(strength),BeforeRequirements.CalculateLevel(strength),"legacy lookup")
end
for _,strength in {1e6,1e12,1e20,1e24,1e100,1e300} do
 eq(AfterRequirements.CalculateLevel(strength),BeforeRequirements.CalculateLevel(strength),"large legacy lookup")
end
-- Loading preserves saved LV/progress; it never derives live LV from Strength.
-- Positive gains consume carry against the new cost. No migration/version bump.
for level=1,12 do
 local oldCost=BeforeRequirements.GetRequiredStrength(level)
 for progress=0,oldCost+.5,.25 do
  local raw={Level=level,LevelProgress=progress,LevelProgressVersion=1,Strength=987654.5}
  local l,p=after.Normalize(raw)
  eq(l,level,"saved level unchanged");eq(p,progress,"saved progress unchanged")
  local l0,p0=after.Advance(l,p,0)
  eq(l0,l,"zero gain level");eq(p0,p,"zero gain progress")
  for _,gain in {.25,1,19.5,530,955} do
   local s,l1,p1=after.ApplyGain(raw,gain)
   near(s,raw.Strength+gain,"Strength delta")
   ok(l1>=level,"no level loss")
   near(prefix(AfterRequirements,l1)+p1,prefix(AfterRequirements,level)+progress+gain,"progress conservation")
   ok(p1>=0 and p1<AfterRequirements.GetRequiredStrength(l1),"carry within current cost")
  end
  eq(raw.Level,level,"input level immutable");eq(raw.LevelProgress,progress,"input progress immutable")
  eq(raw.Strength,987654.5,"input Strength immutable")
  local saved={Level=l,LevelProgress=p,LevelProgressVersion=after.Version,Strength=raw.Strength}
  local l2,p2=after.Normalize(saved)
  eq(l2,l,"reload level");eq(p2,p,"reload progress")
 end
end
for _,raw in {{Level=0},{Level=1.5},{Level=1,LevelProgress=-1},{Level=1,LevelProgress=math.huge},{Level=1,LevelProgress=0/0},{Level=1,LevelProgressVersion=2,LevelProgress=0},{LevelProgressVersion=1}} do
 local l=after.Normalize(raw);eq(l,nil,"reject malformed or unknown version")
end
for _,gain in {-1,math.huge,0/0} do
 local l=after.Advance(1,0,gain);eq(l,nil,"reject invalid gain")
end
for _,total in {7,27,60,120,215,360,530,955,1245,10000} do
 local l,p=after.Advance(1,0,total)
 local l2,p2=1,0
 for _=1,total do l2,p2=after.Advance(l2,p2,1) end
 eq(l,l2,"batched levels");near(p,p2,"batched progress")
 if total>=530 then
  local oldL,oldP=before.Advance(1,0,total)
  eq(l,oldL,"fresh later level equality");near(p,oldP,"fresh later progress equality")
 end
end
local maxL,maxP=after.Advance(1,0,1e300)
eq(maxL,10000,"large gain terminates");ok(maxP<math.huge,"large carry finite")
-- Real shared wall/encounter modules, no Roblox engine or physical contact claims.
local wall,boss=MakeCombat(AfterBossConfig)
local oldWall,oldBoss=MakeCombat(BeforeBossConfig)
local function player(strength,glove)
 local p={attrs={Strength=strength},glove=glove or 0}
 function p:SetAttribute(k,v) self.attrs[k]=v end
 function p:GetAttribute(k) return self.attrs[k] end
 return p
end
eq(AfterBossConfig.GetMaxHP(1),225);eq(AfterBossConfig.GetRecommendedLevel(1),4)
eq(AfterBossConfig.GetMaxHP(2),2250);eq(AfterBossConfig.GetRecommendedLevel(2),10)
ok(AfterBossConfig.NeedsIntroTraining(1,0,false),"new profile trains")
ok(AfterBossConfig.NeedsIntroTraining(2,7,false),"early LV2 does not lower first-wall Strength")
ok(not AfterBossConfig.NeedsIntroTraining(2,10,false),"old entry Strength proceeds")
ok(not AfterBossConfig.NeedsIntroTraining(2,7,true),"cleared wall/Boss never regresses for the new floor")
ok(AfterBossConfig.NeedsIntroTraining(1,0,true),"existing LV reset behavior retained")
for stage=3,10 do
 eq(AfterBossConfig.GetRequiredStrength(stage),BeforeBossConfig.GetRequiredStrength(stage))
 eq(AfterBossConfig.GetRecommendedLevel(stage),BeforeBossConfig.GetRecommendedLevel(stage))
 eq(AfterBossConfig.GetMaxHP(stage),BeforeBossConfig.GetMaxHP(stage))
 for i=1,4 do eq(AfterBossConfig.GetWallConfig(stage).Walls[i],BeforeBossConfig.GetWallConfig(stage).Walls[i]) end
end
for stage=1,10 do
 local c=AfterBossConfig.GetWallConfig(stage)
 local required=AfterBossConfig.GetRequiredStrength(stage)
 for cycle=1,2 do
  local p=player(required)
  wall.InitializePlayer(p,stage)
  local total=0
  for i,hp in c.Walls do
   total+=hp;eq(wall.GetGaugeForStage(p,stage,i),hp,"fresh wall")
  end
  local cleared,current,left=wall.ApplyDamageForStage(p,stage,total+required)
  eq(#cleared,4);eq(current,5);eq(left,required)
  -- Wall surplus is deliberately not submitted to the Boss, matching EnemyManager.
  eq(boss.Begin(p,{},stage).HP,c.BossMaxHP)
  for hit=1,5 do
   local outcome,s=boss.Attack(p)
   eq(s.HP,c.BossMaxHP-hit*required)
   eq(outcome,hit==5 and "Win" or "Active")
  end
  eq(boss.ResetEncounterForHeal(p,stage),nil,"completed boss stays defeated")
  boss.Reset(p);boss.Begin(p,{},stage);boss.Attack(p)
  eq(boss.ResetEncounterForHeal(p,stage),c.BossMaxHP,"unfinished heal")
  eq(boss.Begin(p,{},stage).HP,c.BossMaxHP,"fresh encounter")
 end
end
-- Monotone early wall difficulty; Stage2 walls never overtake Stage3 walls.
for i=1,4 do
 ok(AfterBossConfig.GetWallConfig(1).Walls[i]<AfterBossConfig.GetWallConfig(2).Walls[i],"stage1 < stage2 wall")
 ok(AfterBossConfig.GetWallConfig(2).Walls[i]<AfterBossConfig.GetWallConfig(3).Walls[i],"stage2 < stage3 wall")
end
-- Independent players and reset do not retain the other's partial wall/HP state.
local a,b=player(60),player(100)
wall.InitializePlayer(a);wall.InitializePlayer(b)
wall.ApplyDamageForStage(a,1,50)
eq(wall.GetGaugeForStage(b,1,1),65)
boss.Begin(a,{},1);boss.Begin(b,{},1);boss.Attack(a)
eq(boss.Get(b).HP,225)
boss.Reset(a);eq(boss.Begin(a,{},1).HP,225);eq(boss.Get(b).HP,225)
local glove=player(60,.5)
boss.Begin(glove,{},1);local _,gs=boss.Attack(glove)
eq(gs.HP,135,"unchanged glove multiplier")
-- Conservative ideal-contact timing check: first Auto may wait a full 0.8s.
-- This is arithmetic, NOT an actual engine timing or movement test.
local recommendedStrength=prefix(AfterRequirements,AfterBossConfig.GetRecommendedLevel(1))
local hits=math.ceil(AfterBossConfig.GetMaxHP(1)/recommendedStrength)
local behavior=BossBehavior.Get(1,1)
local lethalAfter=math.ceil(100/behavior.Damage)*behavior.AttackInterval
ok(hits*Auto.CombatAutoInterval<lethalAfter,"recommended LV survives ideal Auto timing, including initial delay")
eq(Auto.CombatAutoInterval,.8);eq(Auto.MinimumInterval,.2);eq(Auto.AfterManualDelay,.5);eq(Auto.AutoInterval,.5)
local function attackCount(config,strength,stage)
 local w,b=MakeCombat(config)
 local p=player(strength)
 w.InitializePlayer(p,stage)
 local wallHits,bossHits=0,0
 while not w.IsBossUnlockedForStage(p,stage) do
  w.ApplyDamageForStage(p,stage,strength);wallHits+=1
  assert(wallHits<1000,"model wall loop bound")
 end
 b.Begin(p,{},stage)
 while true do
  local outcome=b.Attack(p);bossHits+=1
  if outcome=="Win" then break end
  assert(bossHits<1000,"model Boss loop bound")
 end
 return wallHits,bossHits
end
local timing={"stage,strength,oldWallHits,newWallHits,oldBossHits,newBossHits,oldTotal,newTotal,actionCountSpeedRatio"}
for stage=1,2 do
 local powers=stage==1 and {20,30,45,60,75,100} or {300,450,600,955}
 for _,power in powers do
  local ow,ob=attackCount(BeforeBossConfig,power,stage)
  local nw,nb=attackCount(AfterBossConfig,power,stage)
  if stage==1 then ok(nw+nb<ow+ob,"opening uses fewer accepted attacks")
  else ok(nw>ow and nb==ob,"stage2 adds wall actions only") end
  timing[#timing+1]=string.format("%d,%g,%d,%d,%d,%d,%d,%d,%.4f",stage,power,ow,nw,ob,nb,ow+ob,nw+nb,(ow+ob)/(nw+nb))
 end
end
return checks,recommendedStrength,hits,hits*Auto.CombatAutoInterval,lethalAfter,table.concat(timing,"\n")
