local checks=0
local function eq(actual,expected,label)
 checks+=1
 assert(actual==expected,(label or "value")..": "..tostring(actual).." != "..tostring(expected))
end
local function load(name,extra)
 local fn=assert(loadstring(sources[name],name))
 setfenv(fn,setmetatable(extra or {},{__index=getfenv()}))
 return fn()
end
local C,Before,W2,N=load("Config"),load("Before"),load("World2"),load("NumberFormat")
local modules={World1BossConfig=C,World2Config=W2,CombatConfig=load("Combat"),
 StrengthManager={GetLevel=function() return 50 end},
 ItemService={GetGloveBossDamageBonus=function(p) return p.glove or 0 end}}
local refs=setmetatable({WaitForChild=function(_,name) return name end},{__index=function(_,k) return k end})
local game={ReplicatedStorage={Config=refs},ServerScriptService={Services=refs}}
function game:GetService(name) return self[name] end
local env={game=game,require=function(name) return assert(modules[name],name) end,
 script={Parent=refs},Random={new=function() return {NextNumber=function() return 0.99 end} end}}
modules.World2BossConfig=load("World2Boss",env)
local Wall,Boss=load("Wall",env),load("Boss",env)
local function player(strength,glove)
 local p={attrs={Strength=strength},glove=glove}
 function p:SetAttribute(k,v) self.attrs[k]=v end
 function p:GetAttribute(k) return self.attrs[k] end
 return p
end
local expected={
 {75,100,125,150,200,375},{450,300,325,350,425,2250},
 {2500,600,750,900,1200,12500},{6000,3000,3750,4500,6000,30000},
 {20000,40000,50000,60000,80000,100000},
 {100000,200000,250000,300000,400000,500000},
 {700000,1400000,1750000,2100000,2800000,3500000},
 {3000000,6000000,7500000,9000000,12000000,15000000},
 {15000000,30000000,37500000,45000000,60000000,75000000},
 {50000000,100000000,125000000,150000000,200000000,250000000},
}
eq(C.StageCount,10);eq(C.HPPerRequiredStrength,5);eq(Boss.MaxAttackCount,nil)
local stamp=load("SpawnAttributes",{Boss=Boss})
local state=load("InitialGauges",{Boss=Boss,states={}})
local initial=state(player(1))
for stage,row in ipairs(expected) do
 local required,bossHP=row[1],row[6]
 eq(C.GetRequiredStrength(stage),required);eq(C.GetMaxHP(stage),bossHP)
 eq(C.GetRecommendedLevel(stage),Before.GetRecommendedLevel(stage))
 eq(Boss.GetStageConfig(stage).MaxHP,bossHP)
 eq(Boss.GetStageConfig(stage).RequiredStrength,required)
 eq(initial.Gauges[stage],bossHP)
 local object=player(1);stamp(object,stage)
 eq(object:GetAttribute("MaxGauge"),bossHP);eq(object:GetAttribute("BossMaxHP"),bossHP)
 eq(object:GetAttribute("RequiredStrength"),required)
 if stage<=4 then
  eq(C.GetMaxHP(stage),Before.GetMaxHP(stage))
  for i=1,4 do eq(C.GetWallConfig(stage).Walls[i],Before.GetWallConfig(stage).Walls[i]) end
 end
 local p=player(required)
 for cycle=1,2 do -- first generation, then reset/retry after partial damage
  Wall.InitializePlayer(p)
  local snapshot=Wall.GetSnapshotForStage(p,stage)
  eq(snapshot.BossMaxHP,bossHP)
  for i=1,4 do
   eq(snapshot.Maxes[i],row[i+1]);eq(snapshot.Gauges[i],row[i+1])
  end
  Wall.ApplyDamageForStage(p,stage,row[2]+1)
  eq(Wall.GetGaugeForStage(p,stage,1),0);eq(Wall.GetGaugeForStage(p,stage,2),row[3]-1)
 end
 Wall.InitializePlayer(p,stage)
 local cleared,index,surplus=Wall.ApplyDamageForStage(p,stage,row[2]+row[3]+row[4]+row[5]+required)
 eq(#cleared,4);eq(index,5);eq(surplus,required)
 eq(Boss.Begin(p,{},stage).HP,bossHP) -- actual EnemyManager does not queue wall surplus
 for hit=1,5 do
  local outcome,s=Boss.Attack(p)
  eq(s.HP,bossHP-hit*required);eq(outcome,hit==5 and "Win" or "Active")
 end
 eq(Boss.ResetEncounterForHeal(p,stage),nil) -- never resurrect a completed boss
 Boss.Reset(p);Boss.Begin(p,{},stage);Boss.Attack(p)
 eq(Boss.ResetEncounterForHeal(p,stage),bossHP)
 eq(Boss.Begin(p,{},stage).HP,bossHP)
 Boss.Cancel(p);eq(Boss.Begin(p,{},stage).MaxHP,bossHP)
 Boss.Reset(p)
 local half=player(required/2)
 Boss.Begin(half,{},stage)
 for hit=1,10 do local outcome=Boss.Attack(half);eq(outcome,hit==10 and "Win" or "Active") end
 local glove=player(required,1)
 Boss.Begin(glove,{},stage)
 for hit=1,3 do local outcome=Boss.Attack(glove);eq(outcome,hit==3 and "Win" or "Active") end
 local w2=Wall.ForWorld(2).GetSnapshotForStage(p,stage)
 eq(w2.BossMaxHP,W2.GetStageConfig(stage).BossMaxHP)
 eq(Boss.ForWorld(2).GetStageConfig(stage).MaxHP,W2.GetStageConfig(stage).BossMaxHP)
 for i=1,4 do eq(w2.Maxes[i],W2.GetStageConfig(stage).Walls[i]) end
end
for _,pair in ipairs({{100000,"100K"},{500000,"500K"},{3500000,"3.5M"},
 {15000000,"15M"},{75000000,"75M"},{250000000,"250M"},{37500000,"37.5M"},{125000000,"125M"}}) do
 eq(N.Format(pair[1]),pair[2])
end
-- Execute the saved purchased-wall renderer using synthetic GUI objects.
if sources.WallGauge~="" then
 local function node(t) t.FindFirstChild=function(self,k) return self[k] end;return t end
 local amount,fill=node({}),nil
 fill=node({Size={Y={Scale=1,Offset=0}}})
 local stageLabel=node({})
 local wall=node({SurfaceGui=node({Stage=stageLabel,Health=node({Amount=amount,Separate=node({Bar=fill})})})})
 local render=load("WallGauge",{worldId=1,NumberFormat=N,wallGauges={},
  PurchasedWallHealth={format="%s / %s"},wallModel=function() return {} end,
  wallSurface=function() return wall,nil end,
  UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}})
 for stage=5,10 do for i=1,4 do
  local max=C.GetWallConfig(stage).Walls[i]
  for _,fraction in ipairs({1,.5,0}) do
   render(stage,i,max*fraction,max)
   eq(fill.Size.X.Scale,fraction)
   eq(amount.Text,N.Format(max*fraction).." / "..N.Format(max))
   eq(stageLabel.Text,("Stage %d-%d"):format(stage,i))
  end
 end end
end
local fills={}
local bossRender=load("BossGauge",{fills=fills,NumberFormat=N,
 UDim2={fromScale=function(x,y) return {X={Scale=x},Y={Scale=y}} end}})
for stage=5,10 do
 local max=C.GetMaxHP(stage)
 fills[stage]={Fill={},HP={}}
 for _,fraction in ipairs({1,.8,0}) do
  bossRender({Stage=stage,Current=max*fraction,Max=max})
  eq(fills[stage].Current,max*fraction);eq(fills[stage].Max,max)
  eq(fills[stage].Fill.Size.X.Scale,fraction)
  eq(fills[stage].HP.Text,N.Format(max*fraction).." / "..N.Format(max))
 end
end
print("WORLD1_BOSS_BALANCE_OFFLINE_PASS",checks)
