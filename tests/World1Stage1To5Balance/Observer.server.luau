-- Read-only native observation; no grants, forced drops, warps or save changes.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage
local joined={};local readyAt={}
Players.PlayerAdded:Connect(function(p)joined[p]={Time=workspace:GetServerTimeNow(),Late=false}end)
for _,p in Players:GetPlayers()do joined[p]={Time=workspace:GetServerTimeNow(),Late=true}end
local D=require(game.ServerScriptService.Services.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local Rebirth=require(RS.Config.RebirthConfig);local Balance=require(RS.Config.World1BossConfig)
local Analytics=require(game.ServerScriptService.Services.FirstPlayAnalyticsTransport)
local qa=RS.__W1BalanceRoute;local reports={};local startAt
-- Repetitions2/3 share a six-client server, but each profile/route is independent.
-- Before and After use the same cohort sizes. A queued duplicate launcher retires.
if qa:GetAttribute("ExpectedPlayers")==6 and qa:GetAttribute("Repetition")==3 then
 task.delay(3,function()game:GetService("StudioTestService"):EndTest({Skipped="Repetitions2/3 measured together"})end)
 return
end
if qa:GetAttribute("ExpectedPlayers")==6 then game:GetService("StudioTestService"):AddPlayers(3)end
local logs={}
game:GetService("LogService").MessageOut:Connect(function(message,kind)
 if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then
  table.insert(logs,{Message=message,Type=tostring(kind),Time=workspace:GetServerTimeNow()})
 end
end)
local function snapshot(p)
 local s=D.Get(p);if not s or not s.Loaded then return {Loaded=false}end
 local d=s.Data
 return {Loaded=true,Strength=d.Strength,Level=d.Level,Progress=d.LevelProgress,Curve=d.LevelCurveVersion,
  Win=d.Win,Rebirth=d.RebirthCount,RequiredRebirthLevel=Rebirth.GetRequiredLevel(d.RebirthCount,d.LevelCurveVersion),
  EquippedDumbbell=d.EquippedDumbbell,EquippedItems=table.clone(d.EquippedItems),EquippedAura=d.EquippedAura,
  Ores=table.clone(d.OwnedOres),Bag=p:GetAttribute("RunInventoryCount"),Stage=p:GetAttribute("CurrentStage"),
  Pending=s.PendingItemMutation~=nil,Health=p.Character and p.Character:FindFirstChildOfClass("Humanoid")and p.Character.Humanoid.Health}
end
local function record(p,kind,details)
 local r=reports[p];if not r then return end
 local now=workspace:GetServerTimeNow()
 table.insert(r.Events,{Kind=kind,Time=now,Seconds=startAt and now-startAt,Details=details,State=snapshot(p)})
end
local function assign()
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
 if #players<qa:GetAttribute("ExpectedPlayers")then return false end
 for _,p in players do if not D.IsLoaded(p)or not p.Character or not p.Character:GetAttribute("MuscleScaleReady")or not p.Character:GetAttribute("LobbySpawnPlaced")then return false end end
 for i,p in players do if not reports[p]then
  local d=D.Get(p).Data;assert(d.Strength==0 and d.Level==1 and d.LevelProgress==0,"not fresh")
  reports[p]={UserId=p.UserId,Joined=joined[p],FirstReadyAt=readyAt[p],Mode=({"Auto","Manual","Mixed"})[(i-1)%3+1],Variant=qa:GetAttribute("Variant"),Repetition=(qa:GetAttribute("ReportRepetition")or qa:GetAttribute("Repetition"))+math.floor((i-1)/3),Events={},Initial=snapshot(p)}
  p:GetAttributeChangedSignal("Level"):Connect(function()record(p,"Level"..tostring(p:GetAttribute("Level")))end)
  for stage=1,6 do p:GetAttributeChangedSignal("Stage"..stage.."SubStage"):Connect(function()record(p,"WallProgress"..stage,{SubStage=p:GetAttribute("Stage"..stage.."SubStage")})end)end
  p.CharacterRemoving:Connect(function()record(p,"CharacterRemoving")end)
 end end
 return true
end
qa.State.OnServerInvoke=function(p,action)
 if action=="Hello"then
  if D.IsLoaded(p)and p.Character and p.Character:GetAttribute("MuscleScaleReady")and p.Character:GetAttribute("LobbySpawnPlaced")then readyAt[p]=readyAt[p]or workspace:GetServerTimeNow()end
  if not assign()then return {Waiting=true}end
  local r=reports[p];r.ReadyAt=r.ReadyAt or workspace:GetServerTimeNow()
  local ready=true;for _,v in reports do if not v.ReadyAt then ready=false end end
  if ready and not startAt then startAt=workspace:GetServerTimeNow()+1 end
  return {Waiting=not startAt,StartAt=startAt,Mode=r.Mode,Recommended=Balance.RecommendedLevels}
 end
 return snapshot(p)
end
local function result()
 local rows={};for _,r in reports do table.insert(rows,r)end
 return {Variant=qa:GetAttribute("Variant"),Repetition=qa:GetAttribute("Repetition"),Started=startAt,Runs=rows,Logs=logs,Analytics=Analytics.StudioRecords(),Kind="Native multiplayer Play with memory persistence and programmatic ordinary inputs"}
end
qa.Report.OnServerEvent:Connect(function(p,kind,details)
 record(p,kind,details)
 local r=reports[p]
 if r then
  if kind=="TrainStart"then r.Training=true elseif kind=="TrainEnd"then r.Training=false end
  if kind=="MergeStart"then r.Merging=true elseif kind=="MergeEnd"then r.Merging=false end
  if kind=="RebirthRequested"then r.Rebirthing=true elseif kind=="RebirthDeferred"or kind:match("^Rebirth%d+$")then r.Rebirthing=false end
  if kind:match("^TrophyApproach")then r.Returning=true elseif kind:match("^TrophyReturned")then r.Returning=false end
 end
 if r and(kind=="Complete"or kind=="Failed")and r.ActivitySince then
  r.ActivitySeconds[r.Activity]=(r.ActivitySeconds[r.Activity]or 0)+workspace:GetServerTimeNow()-r.ActivitySince
 end
 if kind=="Complete"or kind=="Failed"then reports[p].Finished=true;reports[p].Success=kind=="Complete"end
 local all=#Players:GetPlayers()>=qa:GetAttribute("ExpectedPlayers")
 for _,r in reports do if not r.Finished then all=false end end
 if all and not qa:GetAttribute("ResultsReady")then
  qa:SetAttribute("ResultsReady",true)
  local text=game.HttpService:JSONEncode(result());local chunks={};local start=1
  while start<=#text do
   local stop=math.min(start+150000-1,#text)
   while stop<#text and string.byte(text,stop+1)>=128 and string.byte(text,stop+1)<192 do stop-=1 end
   local chunk=text:sub(start,stop);table.insert(chunks,chunk)
   local out=Instance.new("StringValue");out.Name="ResultChunk"..#chunks;out.Value=chunk;out.Parent=qa
   start=stop+1
  end
  qa:SetAttribute("ResultChunks",#chunks)
  if not qa:GetAttribute("HoldOnComplete")then game:GetService("StudioTestService"):EndTest({Chunks=chunks})end
 end
end)
local api=Instance.new("BindableFunction");api.Name="Inspect";api.Parent=qa
api.OnInvoke=function(full)
 if full then return result()end
 local rows={};for p,r in reports do rows[r.Mode..r.Repetition]={Events=#r.Events,Last=r.Events[#r.Events],Finished=r.Finished,Success=r.Success,State=snapshot(p),Position=p.Character and tostring(p.Character:GetPivot().Position)}end
 return rows
end
local floors={}
for stage=1,6 do
 floors[stage]={}
 for _,o in workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)]:GetDescendants()do
  if o:IsA("BasePart")and o.Name=="Floor"then table.insert(floors[stage],o)end
 end
end
local since=0;local last={}
game:GetService("RunService").Heartbeat:Connect(function(dt)
 since+=dt;if since<.1 then return end;since=0
 for p,r in reports do if not r.Finished then
  local ps=E.GetPlayerState(p);local character=p.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
  if qa:GetAttribute("TrackActivity")then
   local moving=root and Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>.5
   local category=r.Rebirthing and"Rebirth"or r.Merging and"MergeEquip"or r.Training and"Training"or r.Returning and"Return"or p:GetAttribute("IsFighting")and"Combat"or moving and"Movement"or"Idle"
   if category~=r.Activity then
    local now=workspace:GetServerTimeNow();r.ActivitySeconds=r.ActivitySeconds or{}
    if r.ActivitySince then r.ActivitySeconds[r.Activity]=(r.ActivitySeconds[r.Activity]or 0)+now-r.ActivitySince end
    r.Activity=category;r.ActivitySince=now;record(p,"Activity",category)
   end
  end
  local state=last[p]or{};last[p]=state
  if state.Character~=character or state.Run~=ps.RunInventoryId then state.Character=character;state.Run=ps.RunInventoryId;state.Gauges={};state.InStage=nil end
  for stage=1,5 do
   local gauge=ps.Gauges[stage];local before=state.Gauges[stage]
   if gauge and before and gauge<before then record(p,"BossDamage"..stage,{Before=before,After=gauge,Damage=before-gauge})end
   state.Gauges[stage]=gauge
  end
  if root then
   local inside
   for stage=1,6 do
    for _,o in floors[stage]do do
     local v=o.CFrame:PointToObjectSpace(root.Position);local h=o.Size/2
     if math.abs(v.X)<=h.X and math.abs(v.Z)<=h.Z and v.Y>=h.Y-2 and v.Y<=h.Y+35 then inside=stage;break end
    end end
    if inside then break end
   end
   if inside~=state.InStage then state.InStage=inside;if inside then record(p,"EnteredStage"..inside)end end
  end
 end end
end)
