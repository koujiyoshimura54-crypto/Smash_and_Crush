-- Shared Wall progression for Stage1-10; keep this module name for existing callers.
local M={}
local states=setmetatable({}, {__mode="k"})
M.Config={
 [1]={Walls={100,125,150,200}},
 [2]={Walls={300,325,350,425}},
 [3]={Walls={600,750,900,1200}},
 [4]={Walls={3000,3750,4500,6000}},
 [5]={Walls={7000,8750,10500,14000}},
 [6]={Walls={4205,8410,12615,16820}},
 [7]={Walls={5780,11560,17340,23120}},
 [8]={Walls={7605,15210,22815,30420}},
 [9]={Walls={9680,19360,29040,38720}},
 [10]={Walls={12005,24010,36015,48020}},
}
local BossConfig=require(game.ReplicatedStorage.Config.World1BossConfig)
for stage,entry in pairs(M.Config) do entry.BossMaxHP=BossConfig.GetMaxHP(stage) end
local function fresh(major)
 local cfg=M.Config[major] or M.Config[1]; local s={Current=1,Cleared={},Gauges={}}
 for i,hp in ipairs(cfg.Walls) do s.Gauges[i]=hp end
 return s
end
function M.InitializePlayer(p,targetStage)
 targetStage=targetStage or 1
 local s={Stages={}}
 for major in pairs(M.Config) do
  local stage=fresh(major)
  if major<targetStage then
   stage.Current=5
   stage.Skipped=true
   for i=1,4 do stage.Cleared[i]=true stage.Gauges[i]=0 end
  end
  s.Stages[major]=stage
 end
 states[p]=s
 for major,stage in s.Stages do p:SetAttribute(("Stage%dSubStage"):format(major),stage.Current) end
 return s
end
function M.GetState(p) local s=states[p]; if not s then s=M.InitializePlayer(p) end; return s end
function M.GetStageState(p,major) local s=M.GetState(p); if not s.Stages[major] then s.Stages[major]=fresh(major) end; return s.Stages[major] end
function M.GetCurrentIndexForStage(p,major) return M.GetStageState(p,major).Current end
function M.GetCurrentWallForStage(p,major)
 local s=M.GetStageState(p,major); if s.Current>4 then return nil end
 local map=workspace:FindFirstChild("GeneratedMap"); local bc=map and map:FindFirstChild("BattleCorridor"); local st=bc and bc:FindFirstChild(("Stage%02d"):format(major)); return st and st:FindFirstChild(("Stage%d.%d"):format(major,s.Current))
end
function M.IsBossUnlockedForStage(p,major) return M.GetStageState(p,major).Current>=5 end
function M.GetGaugeForStage(p,major,i) return M.GetStageState(p,major).Gauges[i] end
function M.ApplyDamageForStage(p,major,amount)
 local s=M.GetStageState(p,major); local remaining=math.max(0,tonumber(amount) or 0); local cleared={}
 while remaining>0 and s.Current<=4 do
  local i=s.Current; local applied=math.min(s.Gauges[i],remaining); s.Gauges[i]-=applied; remaining-=applied
  if s.Gauges[i]<=0 then s.Cleared[i]=true; cleared[#cleared+1]=i; s.Current=i+1; p:SetAttribute(("Stage%dSubStage"):format(major),s.Current) end
 end
 return cleared,s.Current,remaining
end
function M.GetSnapshotForStage(p,major)
 local s=M.GetStageState(p,major); local gauges,cleared={},{}; for i=1,4 do gauges[i]=s.Gauges[i]; if s.Cleared[i] then cleared[i]=true end end
 local cfg=M.Config[major] or M.Config[1]; local maxes={}; for i,hp in ipairs(cfg.Walls) do maxes[i]=hp end
 return {MajorStage=major,Current=s.Current,Cleared=cleared,Skipped=s.Skipped==true,Gauges=gauges,Maxes=maxes,BossMaxHP=cfg.BossMaxHP}
end
function M.GetCurrentIndex(p) return M.GetCurrentIndexForStage(p,1) end
function M.GetCurrentWall(p) return M.GetCurrentWallForStage(p,1) end
function M.IsBossUnlocked(p) return M.IsBossUnlockedForStage(p,1) end
function M.GetGauge(p,i) return M.GetGaugeForStage(p,1,i) end
function M.ApplyDamage(p,a) return M.ApplyDamageForStage(p,1,a) end
function M.GetSnapshot(p) return M.GetSnapshotForStage(p,1) end
return M

