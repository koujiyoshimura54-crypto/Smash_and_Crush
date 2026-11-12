-- Native route observer: no progression grants, teleports, combat calls or clock edits.
local Players=game:GetService("Players")
local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local T=require(game.ServerScriptService.Services.TimeRewardService)
local config=require(RS.Config.World1BossConfig)
local folder=RS.__EarlyQARoute
local A=require(game.ServerScriptService.Services.FirstPlayAnalyticsTransport)
local reports={};local startAt
local function snapshot(p)
 local s=D.Get(p);if not s or not s.Loaded then return {Loaded=false}end
 local d=s.Data;local ps=E.GetPlayerState(p)
 return {Loaded=true,Strength=d.Strength,Level=d.Level,Progress=d.LevelProgress,Win=d.Win,Rebirth=d.RebirthCount,
 EquippedDumbbell=d.EquippedDumbbell,EquippedItems=table.clone(d.EquippedItems),EquippedAura=d.EquippedAura,
 Ores=table.clone(d.OwnedOres),Dumbbells=table.clone(d.OwnedDumbbells),Bag=p:GetAttribute("RunInventoryCount"),
 Pending=s.PendingItemMutation~=nil,Stage=p:GetAttribute("CurrentStage"),Defeated=ps and table.clone(ps.Defeated)or{},
 Walls={W.GetSnapshotForStage(p,1),W.GetSnapshotForStage(p,2)},TimeRewards=T.GetState(p),
 Health=p.Character and p.Character:FindFirstChildOfClass("Humanoid")and p.Character.Humanoid.Health}
end
local function record(p,kind,details)
 local report=reports[p];if not report then return end
 local now=workspace:GetServerTimeNow()
 local snap=snapshot(p);snap.Walls=nil;snap.Defeated=nil;snap.Dumbbells=nil
 if snap.TimeRewards then snap.TimeRewards={ElapsedSeconds=snap.TimeRewards.ElapsedSeconds,ClaimedRewards=snap.TimeRewards.ClaimedRewards}end
 table.insert(report.Events,{Kind=kind,Time=now,Seconds=startAt and now-startAt,Details=details,State=snap})
 print("[EARLY_QA] "..report.Mode.." "..kind.." "..string.format("%.2f",startAt and now-startAt or 0))
end
local function assign()
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 if #players<folder:GetAttribute("ExpectedPlayers")then return false end
 for _,p in players do
  if not D.IsLoaded(p)or not p.Character or not p.Character:GetAttribute("MuscleScaleReady")then return false end
  local ready=false;for _,event in A.StudioRecords()do if event.UserId==p.UserId and event.Name=="MTF_Entry_v1"and event.Step==3 then ready=true end end
  if not ready then return false end
 end
 for i,p in players do
  if not reports[p]then
   local s=D.Get(p)
   assert(s.Data.Strength==0 and s.Data.Level==1 and s.Data.LevelProgress==0,"not fresh")
   reports[p]={Mode=({"Auto","Manual","Mixed"})[i],Variant=folder:GetAttribute("Variant"),Repetition=folder:GetAttribute("Repetition"),Events={}}
   p:GetAttributeChangedSignal("Level"):Connect(function()record(p,"Level"..tostring(p:GetAttribute("Level")))end)
   p.CharacterRemoving:Connect(function()record(p,"CharacterRemoving")end)
  end
 end
 return true
end
folder.State.OnServerInvoke=function(p,action)
 if action=="Hello"then
  if not assign()then return {Waiting=true}end
  local r=reports[p];r.ReadyAt=r.ReadyAt or workspace:GetServerTimeNow()
  local allReady=true;for _,v in reports do if not v.ReadyAt then allReady=false end end
  if allReady and not startAt then startAt=workspace:GetServerTimeNow()+1 end
  return {Waiting=not startAt,StartAt=startAt,Mode=r.Mode,Targets={math.max(math.ceil(config.GetMaxHP(1)/4),(function()local r=require(RS.Config.LevelRequirements);return r.GetRequiredStrength(1)+r.GetRequiredStrength(2)+r.GetRequiredStrength(3)end)()),math.ceil(config.GetMaxHP(2)/4)}}
 end
 return snapshot(p)
end
folder.Report.OnServerEvent:Connect(function(p,kind,details)
 record(p,kind,details)
 if kind=="Complete"or kind=="Failed"then reports[p].Finished=true;reports[p].Success=kind=="Complete"end
 local all=#Players:GetPlayers()>=folder:GetAttribute("ExpectedPlayers")
 for _,v in reports do if not v.Finished then all=false end end
 if all and not folder:GetAttribute("ResultsReady")then
  folder:SetAttribute("ResultsReady",true)
  local result={Variant=folder:GetAttribute("Variant"),Started=startAt,Runs={},Analytics=A.StudioRecords()}
  for p,v in reports do v.UserId=p.UserId;table.insert(result.Runs,v)end
  local checks={};result.Checks=checks
  for p,v in reports do
   for name,total in {MTF_Entry_v1=3,MTF_FirstCombat_v1=6,MTF_FirstOreMerge_v1=5}do
    local steps={};for _,event in result.Analytics do if event.UserId==p.UserId and event.Name==name then table.insert(steps,event.Step)end end
    local pass=#steps==total;for i,n in steps do pass=pass and i==n end
    table.insert(checks,{UserId=p.UserId,Funnel=name,Passed=pass,Steps=steps})
   end
  end
  local text=game.HttpService:JSONEncode(result)
  local out=Instance.new("StringValue");out.Name="Result";out.Value=text;out.Parent=folder
  print("[EARLY_QA] all finished")
  if folder:GetAttribute("Multiplayer")and not folder:GetAttribute("HoldOnComplete")then game:GetService("StudioTestService"):EndTest(text)end
 end
end)
local api=Instance.new("BindableFunction");api.Name="ServerState";api.Parent=folder
api.OnInvoke=function()
 local rows={};for p,r in reports do rows[r.Mode]={Events=#r.Events,Last=r.Events[#r.Events],Finished=r.Finished,State=snapshot(p),Position=p.Character and tostring(p.Character:GetPivot().Position)}end
 return rows
end

local fault=Instance.new("BindableFunction");fault.Name="FaultControl";fault.Parent=folder
fault.OnInvoke=function(action,value)
 local m=require(RS.__EarlyQAMemory)
 if action=="HoldWrites"then m.HoldWrites=value;return m.BlockedWrites end
 if action=="FailAfter"then m.FailAfter=value;return true end
 if action=="Snapshot"then local out={};for p,r in reports do out[r.Mode]={Data=snapshot(p),Enemy=E.GetPlayerState(p).RunInventoryId,Bag=p:GetAttribute("RunInventoryId"),Active=p:GetAttribute("RunInventoryActive")}end;return out end
 if action=="Events"then local out={};for _,r in reports do out[r.Mode]=r.Events end;return out end
 error("unknown fault control")
end
