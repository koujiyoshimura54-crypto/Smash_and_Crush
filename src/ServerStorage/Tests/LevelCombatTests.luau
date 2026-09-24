local T={}
function T.Run()
 local results={}
 local function check(name,fn) fn();table.insert(results,"PASS "..name) end
 local source=game.ServerScriptService.World.BossCombatService.Source
 source=source:gsub("require%(script.Parent.StrengthManager%)","{CalculateLevel=require(game.ReplicatedStorage.Config.LevelRequirements).CalculateLevel}")
 source=source:gsub("local rng=Random.new%(%)","local rng=Rng")
 local factory=assert(loadstring("return function(Rng) "..source.." end"))()
 local draws=0;local roll=.99
 local rng={NextNumber=function() draws+=1;return roll end}
 local function service() return factory(rng) end
 local function player(strength) return {GetAttribute=function(_,name) assert(name=="Strength");return strength end} end
 local walls=assert(loadstring(game.ServerScriptService.World.Stage1WallManager.Source))()
 local hp={475,1800,9800,18050,28800,42050,57800,76050,96800,120050}
 local wallHP={800,4050,9800,18050,28800,42050,57800,76050,96800,120050}
 check("All 10 Level / RequiredStrength / MaxHP definitions match; equal-level wins without RNG in exactly 5 attacks",function()
  local b=service();local before=draws
  for stage=1,10 do
   local c=b.GetStageConfig(stage);assert(c.RecommendedLevel==stage*5 and c.RequiredStrength==require(game.ReplicatedStorage.Config.LevelRequirements).GetRequiredStrength(stage*5) and c.MaxHP==hp[stage])
   assert(walls.Config[stage].BossMaxHP==wallHP[stage])
   local p=player(c.RequiredStrength);local s=b.Begin(p,{},stage)
   assert(s.PlayerLevel==stage*5 and s.Route=="LEVEL_DAMAGE" and s.Attacks==0)
   for i=1,5 do local status=b.Attack(p);assert(status==(i==5 and "Win" or "Active"));assert(s.Attacks==i) end
   assert(b.Attack(p)=="Complete" and s.Attacks==5)
  end
  assert(draws==before)
 end)
 check("Below-level chances 80/60/40/20 and 0; boundary rolls and zero chance avoid extra draws",function()
  for gap=1,4 do
   local level=10-gap;local strength=require(game.ReplicatedStorage.Config.LevelRequirements).GetRequiredStrength(level)
   local b=service();local expected=({.8,.6,.4,.2})[gap]
   assert(math.abs(b.GetWinChance(level,10)-expected)<1e-12)
   roll=expected-.000001;local before=draws
   assert(b.Begin(player(strength),{},2).Route=="LOTTERY_WIN" and draws==before+1)
   roll=expected;assert(b.Begin(player(strength),{},2).Route=="LOTTERY_MISS" and draws==before+2)
  end
  local b=service();local before=draws
  assert(b.Begin(player(95),{},2).Route=="LOTTERY_MISS" and draws==before)
 end)
 check("A Stage1 exact 95/120/238/475 => 5/4/2/1 attacks, no random draw or HP floor",function()
  local b=service();local before=draws
  for _,case in ipairs({{95,5},{120,4},{238,2},{475,1},{1000000,1}}) do
   local p=player(case[1]);local s=b.Begin(p,{},1)
   assert(s.Route=="LEVEL_DAMAGE" and s.Roll==nil)
   for i=1,case[2] do
    assert(b.Attack(p)==(i==case[2] and "Win" or "Active"))
    assert(s.HP==math.max(0,475-case[1]*i))
   end
   assert(s.Attacks==case[2])
  end
  assert(draws==before)
 end)
 check("B Lv4 lottery win requires 5 attacks, even with carry reducing HP to zero",function()
  roll=0
  for _,carry in ipairs({0,1000000}) do
   local b=service();local p=player(90);local enemy={}
   b.QueueDamage(p,enemy,1,475,carry)
   local s=b.Begin(p,enemy,1)
   assert(s.PlayerLevel==4 and s.Route=="LOTTERY_WIN" and s.LossPlanned==false and s.HP>=1 and not s.Completed)
   for i=1,4 do assert(b.Attack(p)=="Active" and s.HP>=1) end
   assert(b.Attack(p)=="Win" and s.HP==0 and s.Attacks==5)
  end
 end)
 check("C Lv4 lottery miss: untouched HP loses at5; carry allows earned win on attacks1-5",function()
  roll=.99
  local b=service();local p=player(90);local s=b.Begin(p,{},1)
  assert(s.Route=="LOTTERY_MISS" and s.LossPlanned==true)
  for _=1,4 do assert(b.Attack(p)=="Active") end
  assert(b.Attack(p)=="Lose" and s.HP==25)
  for finish=1,5 do
   b=service();p=player(90);local enemy={}
   b.QueueDamage(p,enemy,1,475,475-finish*90)
   s=b.Begin(p,enemy,1);assert(s.Route=="LOTTERY_MISS")
   for i=1,finish do assert(b.Attack(p)==(i==finish and "Win" or "Active")) end
   assert(s.HP==0)
  end
 end)
 check("Failed lottery: HP remaining after attack5 loses; zero Strength also loses at5",function()
  roll=.99;local b=service()
  for _,damage in ipairs({280,0}) do
   local p=player(damage);local s=b.Begin(p,{},2)
   assert(s.Route=="LOTTERY_MISS")
   for i=1,4 do assert(b.Attack(p)=="Active" and s.HP==1800-i*damage) end
   assert(b.Attack(p)=="Lose" and s.HP>0 and s.Attacks==5)
   assert(b.Attack(p)=="Complete" and s.Attacks==5)
  end
 end)
 check("Failed lottery: carry permits earned win on attacks1-5; HP zero checked before fifth-attack loss",function()
  roll=.99
  for finish=1,5 do
   local b=service();local p=player(280);local enemy={}
   b.QueueDamage(p,enemy,2,1800,1800-finish*280)
   local s=b.Begin(p,enemy,2);assert(s.Route=="LOTTERY_MISS")
   for i=1,finish do assert(b.Attack(p)==(i==finish and "Win" or "Active")) end
   assert(s.HP==0 and s.Attacks==finish)
  end
 end)
 check("Re-entry preserves decision, HP, Strength and attacks; another enemy independent; Reset permits new run",function()
  roll=.99;local b=service();local value=280;local p={GetAttribute=function() return value end};local enemy={}
  local before=draws;local s=b.Begin(p,enemy,2);b.Attack(p)
  b.Cancel(p);value=1000000;roll=0
  local same=b.Begin(p,enemy,2);assert(same==s and draws==before+1 and same.Attacks==1 and same.HP==1520 and same.Strength==280)
  b.End(p);assert(b.Begin(p,enemy,2)==s and draws==before+1)
  assert(b.Begin(p,{},2)~=s)
  b.Reset(p);assert(b.Begin(p,enemy,2)~=s)
 end)
 check("Intentional Wall carry unchanged, including remaining Boss carry",function()
  local p={SetAttribute=function() end}
  local cleared,nextIndex,remaining=walls.ApplyDamageForStage(p,1,378)
  assert(#cleared==4 and nextIndex==5 and remaining==178)
  roll=.99;local b=service();local q=player(90);local enemy={}
  b.QueueDamage(q,enemy,1,475,575);local s=b.Begin(q,enemy,1)
  assert(s.Route=="LOTTERY_MISS" and s.HP==0 and not s.Completed)
  assert(b.Attack(q)=="Win" and s.Attacks==1)
 end)
 return table.concat(results,"\n")
end
return T