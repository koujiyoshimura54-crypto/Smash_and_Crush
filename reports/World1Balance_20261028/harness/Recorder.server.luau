-- Read-only benchmark telemetry. This script never grants, purchases, attacks or moves.
local Players=game:GetService('Players')
local RS=game.ReplicatedStorage
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local Run=require(game.ServerScriptService.Services.RunInventoryService)
local Pass=require(game.ServerScriptService.Services.GamePassService)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Http=game:GetService('HttpService')
local events={}
local started,finished,lastTick,lastSnapshot
local phase,reason='codex_interruption','Preparation / awaiting input'
local totals={training=0,combat=0,movement=0,operations=0,death=0,codex_interruption=0}
local firstClears,seenDefeats={},{}
local earned,spent,deaths,lastWin=0,0,0,0
local function now()return DateTime.now().UnixTimestampMillis/1000 end
local function copy(value)
 if typeof(value)=='Instance'then return value.Name end
 if typeof(value)=='CFrame'or typeof(value)=='Vector3'then return tostring(value)end
 if type(value)~='table' then return value end
 local out={};for k,v in pairs(value)do if tostring(k):find('UserId')then out[k]='benchmark-player'else out[k]=copy(v)end end;return out
end
local function snapshot()
 local p=Players:GetPlayers()[1];if not p then return {Loaded=false}end
 local s=Data.Get(p);if not s or not s.Loaded then return {Loaded=false}end
 local d=s.Data;local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 local ps=Enemy.GetPlayerState(p)
 return {Loaded=true,UTC=now(),Elapsed=started and now()-started or nil,Strength=p:GetAttribute('Strength'),Level=p:GetAttribute('Level'),
  Rebirth=p:GetAttribute('RebirthCount'),Win=p:GetAttribute('Win'),EarnedWin=earned,SpentWin=spent,Deaths=deaths,
  Stage=p:GetAttribute('CurrentStage'),World=p:GetAttribute('CurrentWorld'),Visited=Data.HasReachedWorld2(p),Override=s.StudioStartOverride~=nil,
  Position=root and {root.Position.X,root.Position.Y,root.Position.Z},Health=h and h.Health,Speed=h and h.WalkSpeed,
  Training=p:GetAttribute('TrainingTreadmill'),Fighting=p:GetAttribute('IsFighting'),Auto=p:GetAttribute('AutoTapEnabled'),
  OwnedDumbbells=copy(d.OwnedDumbbells),EquippedDumbbell=d.EquippedDumbbell,OwnedItems=copy(d.OwnedItems),EquippedItems=copy(d.EquippedItems),
  Pets=copy(d.Pets),Ores=copy(d.OwnedOres),Aura=d.EquippedAura,OwnedAuras=copy(d.OwnedAuras),Capacity=d.InventoryCapacity,
  Bag=Run.GetSnapshot(p),ForgeJournal=copy(d.ForgeJournal),ItemMergeJournal=copy(d.ItemMergeJournal),Defeated=copy(ps.Defeated),
  Walls=Wall.GetSnapshotForStage(p,p:GetAttribute('CurrentStage')or 1),
  NormalTrainingGain=Strength.GetNormalTrainingGain(p,1),
  Multipliers={Win=Pass.GetWinMultiplier(p),VIP=Pass.GetVIPStrengthMultiplier(p),Rebirth=Strength.GetStrengthGainMultiplier(p)}}
end
local function emit(kind,payload)
 table.insert(events,{Index=#events+1,UTC=now(),Elapsed=started and now()-started or nil,Kind=kind,Payload=copy(payload)})
end
local remote=Instance.new('RemoteEvent');remote.Name='__NightMeasure';remote.Parent=RS
remote.OnServerEvent:Connect(function(_,op,a,b)
 if op=='Start' and not started then
  local received=now();started=type(a)=='table'and type(a.ClientUTC)=='number'and math.abs(received-a.ClientUTC)<2 and a.ClientUTC or received
  lastTick=started;lastSnapshot=0;emit('Start',snapshot());emit('Readiness',{ClientUTC=started,ServerReceiptUTC=received})
 elseif op=='Phase' then phase=a;reason=b;emit('Decision',{Phase=a,Reason=b})
 elseif op=='ClientEvent' then emit('ClientEvent',a)end
end)
local bridge=Instance.new('BindableFunction');bridge.Name='__NightRead';bridge.Parent=game.ServerScriptService
bridge.OnInvoke=function(after,limit)
 local rows={};for i=(after or 0)+1,math.min(#events,(after or 0)+(limit or 20))do table.insert(rows,events[i])end
 return {Snapshot=snapshot(),StartUTC=started,FinishUTC=finished,FirstClears=copy(firstClears),Totals=copy(totals),Events=rows,Cursor=(after or 0)+#rows,TotalEvents=#events}
end
local function bind(p)
 p:GetAttributeChangedSignal('Win'):Connect(function()
  local value=p:GetAttribute('Win');if type(value)~='number'then return end
  if lastWin then local delta=value-lastWin;if delta>0 then earned+=delta else spent-=delta end;emit('Win',{Before=lastWin,After=value,Delta=delta})end;lastWin=value
 end)
 p.CharacterAdded:Connect(function(ch)
  local h=ch:WaitForChild('Humanoid');h.Died:Connect(function()deaths+=1;emit('Death',snapshot())end)
 end)
 if p.Character then local h=p.Character:FindFirstChildOfClass('Humanoid');if h then h.Died:Connect(function()deaths+=1;emit('Death',snapshot())end)end end
end
Players.PlayerAdded:Connect(bind);for _,p in Players:GetPlayers()do bind(p)end
task.spawn(function()
 while true do
  task.wait(.25)
  local p=Players:GetPlayers()[1]
  if started and not finished and p and Data.IsLoaded(p)then
   local t=now();local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   local category=(not h or h.Health<=0)and'death' or p:GetAttribute('IsFighting')and'combat'
    or p:GetAttribute('IsTraining')and'training' or r and Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude>.5 and'movement'
    or phase=='operations'and'operations' or'codex_interruption'
   totals[category]+=t-lastTick;lastTick=t
   local state=Enemy.GetPlayerState(p)
   for stage=1,10 do
    if not state.Defeated[stage]then seenDefeats[stage]=false
    elseif not seenDefeats[stage]then seenDefeats[stage]=true;local s=snapshot();emit('Defeat',s);if not firstClears[stage]then firstClears[stage]=s end
     if stage==10 then finished=t;emit('Finished',s)end
    end
   end
   if t-lastSnapshot>=5 then lastSnapshot=t;emit('Snapshot',snapshot())end
  end
 end
end)
