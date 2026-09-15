-- Manual Studio-only regression tests; fake DataStore, no live player records.
local T={}
function T.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local RS=game.ReplicatedStorage
 local R=require(RS.Config.LevelRequirements)
 local P=require(RS.Modules.LevelProgression)
 local made={}
 local makeData=require(script.DataFactory)
 local makeStrength=require(script.StrengthFactory)
 local function copy(x) if type(x)~="table" then return x end local t={} for k,v in pairs(x)do t[k]=copy(v)end return t end
 local function fixture(raw)
  local f={records={},metadata={}}
  local attributes={}
  local player={UserId=987654321,Name="LevelProgressFixture"}
  function player:SetAttribute(k,v) attributes[k]=v end
  function player:GetAttribute(k) return attributes[k] end
  local key="Player_"..player.UserId
  f.records[key]=copy(raw)
  local store={}
  function store:GetAsync(k)return copy(f.records[k])end
  function store:UpdateAsync(k,fn)
   local meta=copy(f.metadata[k] or {})
   local info={GetUserIds=function()return {}end,GetMetadata=function()return copy(meta)end}
   local nextValue,users,nextMeta=fn(copy(f.records[k]),info)
   if nextValue then f.records[k]=copy(nextValue);f.metadata[k]=copy(nextMeta or meta)end
   if f.hook then local hook=f.hook;f.hook=nil;hook()end
   if f.failAfterCommit then f.failAfterCommit=false;error("Injected ambiguous completion")end
   return copy(f.records[k]),{GetUserIds=function()return {}end,GetMetadata=function()return copy(f.metadata[k] or {})end}
  end
  local dss={GetDataStore=function()return store end,GetOrderedDataStore=function()return {SetAsync=function()end}end}
  local proxy={AddRewardStrength=function(...)return f.strength.AddRewardStrength(...)end}
  f.data=makeData(dss,proxy);f.strength=makeStrength(f.data);f.player=player;f.key=key
  f.loaded,f.loadError=f.data.Load(player)
  return f
 end
 local results={}
 local checks=0
 local function check(v,msg)checks+=1;assert(v,msg or "check failed")end
 local function near(a,b)return math.abs(a-b)<=math.max(1e-7,math.abs(b)*1e-12)end
 local function test(name,fn)local ok,err=pcall(fn);table.insert(results,{name=name,pass=ok,error=not ok and tostring(err) or nil})end
 test("Requirement boundaries and carry for every level",function()
  for level=2,R.MaxLevel-1 do
   local req=R.GetRequiredStrength(level)
   local a,b=P.Advance(level,0,req-.5);check(a==level and b==req-.5,"below "..level)
   a,b=P.Advance(level,0,req);check(a==level+1 and b==0,"equal "..level)
   a,b=P.Advance(level,0,req+.5);check(a==level+1 and b==.5,"carry "..level)
  end
 end)
 test("Zero-cost Lv1 and max-level are bounded",function()
  local a,b=P.Advance(1,0,0);check(a==1 and b==0)
  a,b=P.Advance(1,0,1);check(a==2 and b==1)
  a,b=P.Advance(1,0,1e17);check(a==R.MaxLevel and b>=0)
  a,b=P.Advance(R.MaxLevel,123,7);check(a==R.MaxLevel and b==130)
  check(P.Advance(2,0,math.huge)==nil)
  check(P.Advance(2,0,0/0)==nil)
 end)
 test("Legacy and explicit Level migration, unrelated data preserved",function()
  local raw={Strength=3000000,Win=77,RebirthCount=3,HighestUnlockedWorld=2,OwnedItems={PROTEIN_COMMON_FIRE=4},TotalStrengthEarned=9000000}
  local f=fixture(raw);check(f.loaded);local d=f.data.Get(f.player).Data
  check(d.Level==60 and d.LevelProgress==0 and d.LevelProgressVersion==1)
  check(d.Strength==raw.Strength and d.Win==77 and d.RebirthCount==3 and d.HighestUnlockedWorld==2)
  check(d.OwnedItems.PROTEIN_COMMON_FIRE==4 and d.TotalStrengthEarned==9000000)
  raw.Level=77;local g=fixture(raw);check(g.loaded and g.player:GetAttribute("Level")==77 and g.player:GetAttribute("LevelProgress")==0)
  local fresh=fixture(nil);check(fresh.loaded and fresh.player:GetAttribute("Level")==1 and fresh.player:GetAttribute("LevelProgress")==0)
 end)
 test("Malformed/future progress rejects load without overwrite",function()
  for _,raw in {{Strength=100,Level=2,LevelProgress=-1},{Strength=100,Level=2,LevelProgress=0,LevelProgressVersion=2},{Strength=100,LevelProgressVersion=1}} do
   local f=fixture(raw);check(not f.loaded);check(not f.data.Save(f.player));check(f.records[f.key].Strength==100)
  end
 end)
 test("Final walk/training bonuses reach Strength AND progress once",function()
  local f=fixture({Strength=3000000,Level=60,LevelProgress=0,LevelProgressVersion=1,RebirthCount=1})
  check(f.loaded)
  local walk=(1+10+15)*1.5*1.5*1.1
  check(near(f.strength.AddStrength(f.player,1),3000000+walk))
  check(near(f.player:GetAttribute("LevelProgress"),walk))
  local train=(1+3+10+15)*1.5*4.25*1.5*1.1
  check(near(f.strength.AddStrength(f.player,1,1,4.25),3000000+walk+train))
  check(near(f.player:GetAttribute("LevelProgress"),walk+train))
  local before=f.player:GetAttribute("Strength")
  check(near(f.strength.AddRewardStrength(f.player,500),before+500))
  check(near(f.player:GetAttribute("LevelProgress"),walk+train+500))
  check(near(f.data.Get(f.player).Data.TotalStrengthEarned,walk+train+500))
 end)
 test("Multi-level gain and absolute Strength independence",function()
  local f=fixture({Strength=123456789,Level=60,LevelProgress=2800000,LevelProgressVersion=1})
  local amount=200000+R.GetRequiredStrength(61)+R.GetRequiredStrength(62)+123
  check(f.strength.AddRewardStrength(f.player,amount)==123456789+amount)
  check(f.player:GetAttribute("Level")==63 and f.player:GetAttribute("LevelProgress")==123)
  f.strength.SetStrength(f.player,999999999)
  check(f.player:GetAttribute("Level")==63 and f.player:GetAttribute("LevelProgress")==123)
 end)
 test("Save concurrent gain stays dirty; re-load restores exact state",function()
  local f=fixture({Strength=3000000,Level=60,LevelProgress=2900000,LevelProgressVersion=1})
  f.hook=function()check(f.strength.AddRewardStrength(f.player,200000)==3200000)end
  check(f.data.Save(f.player))
  check(f.player:GetAttribute("Level")==61 and f.player:GetAttribute("LevelProgress")==100000)
  check(f.data.Get(f.player).Dirty)
  check(f.data.Save(f.player))
  f.data.Release(f.player);check(f.data.Load(f.player))
  check(f.player:GetAttribute("Strength")==3200000 and f.player:GetAttribute("Level")==61 and f.player:GetAttribute("LevelProgress")==100000)
 end)
 test("Time Strength durable claim + ambiguous retry + concurrent gain",function()
  local f=fixture({Strength=3000000,Level=60,LevelProgress=2800000,LevelProgressVersion=1})
  f.data.Get(f.player).Data.TimeRewards.ElapsedSeconds=2700
  f.failAfterCommit=true
  f.hook=function()check(f.strength.AddRewardStrength(f.player,250000)==3250000)end
  local ok,reason=f.data.ClaimTimeReward(f.player,{Id="Reward06",Result={RewardType="Strength",Amount=500000}})
  check(not ok and reason=="InventorySavePending")
  check(f.records[f.key].Level==61 and f.records[f.key].LevelProgress==300000)
  check(f.data.ResolveItemMutation(f.player))
  check(f.player:GetAttribute("Strength")==3750000 and f.player:GetAttribute("Level")==61 and f.player:GetAttribute("LevelProgress")==550000)
  check(not f.data.ResolveItemMutation(f.player))
  check(not f.data.ClaimTimeReward(f.player,{Id="Reward06",Result={RewardType="Strength",Amount=500000}}))
  check(f.data.Save(f.player));f.data.Release(f.player);check(f.data.Load(f.player))
  check(f.player:GetAttribute("Strength")==3750000 and f.player:GetAttribute("LevelProgress")==550000)
 end)
 test("Rebirth cycle reset preserves Win/items/world and saves",function()
  local f=fixture({Strength=3000000,Level=60,LevelProgress=12345,LevelProgressVersion=1,Win=77,HighestUnlockedWorld=2,OwnedItems={PROTEIN_COMMON_FIRE=4}})
  f.data.SetRebirthCount(f.player,1);check(f.strength.ResetStrength(f.player)==0)
  local d=f.data.Get(f.player).Data
  check(d.Strength==0 and d.Level==1 and d.LevelProgress==0)
  check(d.Win==77 and d.HighestUnlockedWorld==2 and d.OwnedItems.PROTEIN_COMMON_FIRE==4 and d.RebirthCount==1)
  check(f.data.Save(f.player));f.data.Release(f.player);check(f.data.Load(f.player))
  check(f.player:GetAttribute("Level")==1 and f.player:GetAttribute("LevelProgress")==0)
 end)
 for _,m in made do m:Destroy()end
 return {results=results,checks=checks}
end
return T

