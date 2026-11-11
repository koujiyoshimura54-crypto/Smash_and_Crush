-- Isolated save/profile fault checks. Never install without __EarlyQAMemory.
local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local Memory=require(RS.__EarlyQAMemory)
local E=require(game.ServerScriptService.World.EnemyManager)
local Progress=require(RS.Modules.LevelProgression)
local T=require(game.ServerScriptService.Services.TimeRewardService)
local qa=RS.__EarlyQABoundary
local records={}
local store=Memory.DataStoreService:GetDataStore("PlayerData_v1_Studio")
local function key(p)return "Player_"..p.UserId end
local function snap(p)
 local s=D.Get(p);local d=s and s.Data
 if not d then return {Loaded=false}end
 return {Strength=d.Strength,Level=d.Level,Progress=d.LevelProgress,Rebirth=d.RebirthCount,
  Ores=table.clone(d.OwnedOres),Win=d.Win,Claimed=table.clone(d.TimeRewards.Claimed),Saving=s.Saving,Pending=s.PendingItemMutation~=nil}
end
local function settled(p)
 local untilTime=os.clock()+20
 while D.IsSaving(p)or D.Get(p).PendingItemMutation do assert(os.clock()<untilTime,"save stalled");task.wait(.1)end
end
qa.Request.OnServerInvoke=function(p,action,data)
 assert(game.PlaceId==126576845524886 and game:GetService("RunService"):IsStudio())
 while not D.IsLoaded(p)do task.wait(.1)end
 if action=="Ready"then D.SetAutoTapEnabled(p,false);return snap(p)end
 if action=="Seed"then
  settled(p);assert(D.Save(p))
  local raw=store:GetAsync(key(p))
  raw.Level,raw.LevelProgress,raw.Strength=data.Level,data.Progress,data.Strength
  raw.LevelProgressVersion=1;raw.RebirthCount=data.Rebirth or 0;raw.AutoTapEnabled=false
  D.Release(p);store:SetAsync(key(p),raw);assert(D.Load(p))
  local s=snap(p);local l,progress=Progress.Normalize(raw)
  assert(s.Strength==raw.Strength and s.Level==l and s.Progress==progress,"normalize")
  records[#records+1]={Case=data,Normalized=s}
  return s
 end
 if action=="State"then return snap(p)end
 if action=="Roundtrip"then
  settled(p)
  local before=snap(p);local s=D.Get(p);s.Dirty=true
  Memory.FailBefore=1;local failed=D.Save(p);Memory.FailBefore=0
  assert(not failed,"failure not exercised")
  assert(snap(p).Strength==before.Strength,"failed save altered Strength")
  Memory.Delay=.2;assert(D.Save(p));Memory.Delay=0
  local stored=store:GetAsync(key(p))
  assert(stored.Level==before.Level and stored.LevelProgress==before.Progress and stored.Strength==before.Strength,"durable mismatch")
  D.Release(p);assert(D.Load(p));local after=snap(p)
  assert(after.Level==before.Level and after.Progress==before.Progress and after.Strength==before.Strength,"reload repeated carry")
  records[#records].Roundtrip={Before=before,Stored={Level=stored.Level,Progress=stored.LevelProgress,Strength=stored.Strength},After=after}
  return after
 end
 if action=="ZeroGain"then
  local s=D.Get(p);s.Data.Level=2;s.Data.LevelProgress=29
  local before=s.Data.Strength;assert(D.AddStrengthGain(p,0)==before)
  local after=snap(p);assert(after.Level==3 and after.Progress==9 and after.Strength==before,"zero gain publish")
  return after
 end
 if action=="Records"then return records end
 error("unknown action")
end
