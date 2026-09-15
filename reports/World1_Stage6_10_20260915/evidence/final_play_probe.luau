-- Temporary automatic Studio Play audit; removed from delivered place.
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local B=require(game.ServerScriptService.World.BossCombatService)
local D=require(game.ServerScriptService.Services.PlayerDataService)
local S=require(game.ServerScriptService.Services.StrengthManager)
local I=require(game.ServerScriptService.Services.ItemService)
local Levels=require(game.ReplicatedStorage.Config.LevelRequirements)
local W2B=require(game.ReplicatedStorage.Config.World2BossConfig)
local W2W=require(game.ServerScriptService.Config.World2WallConfig)
local evidence=Instance.new("Folder") evidence.Name="World1AuditEvidence" evidence.Parent=workspace
local output=Instance.new("StringValue") output.Name="Report" output.Parent=evidence
local report={colliders={},balance={},world2={},status="starting"}
local function vec(v) return {v.X,v.Y,v.Z} end
local function publish(phase) evidence:SetAttribute("Phase",phase) output.Value=Http:JSONEncode(report) end
local function clone(v) if typeof(v)~="table" then return v end local n={} for k,x in pairs(v) do n[k]=clone(x) end return n end
local function waitUntil(fn,timeout)
 local endAt=os.clock()+timeout
 repeat if fn() then return true end task.wait(.05) until os.clock()>endAt
 return false
end
local p
assert(waitUntil(function() p=Players:GetPlayers()[1] return p and p.Character and D.IsLoaded(p) and E.IsReady() end,45),"Player not ready")
local session=D.Get(p)
assert(waitUntil(function() return not session.Saving end,30),"Save busy")
local originalData=clone(session.Data)
local originalAttrs=p:GetAttributes()
local originalDirty=session.Dirty
local originalPivot=p.Character:GetPivot()
local hum=p.Character:FindFirstChildOfClass("Humanoid")
local originalSpeed=hum.WalkSpeed
local root=p.Character.HumanoidRootPart
-- Hold this test session's save lock; production save code/schema is untouched.
session.Saving=true
session.Data.EquippedItems.Glove=""
local function place(position,direction)
 root:SetNetworkOwner(nil)
 p.Character:PivotTo(CFrame.lookAt(position,position+direction))
 root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
 hum.WalkSpeed=16 hum.AutoRotate=true hum:MoveTo(position)
end
local function strength(value)
 p:SetAttribute("Strength",value)
 p:SetAttribute("Level",S.CalculateLevel(value))
end
local function restore()
 if p.Parent and D.Get(p)==session then
  E.StartRun(p,originalAttrs.CurrentStage or 1)
  session.Data=originalData
  for key in pairs(p:GetAttributes()) do if originalAttrs[key]==nil then p:SetAttribute(key,nil) end end
  for key,value in pairs(originalAttrs) do p:SetAttribute(key,value) end
  p.Character:PivotTo(originalPivot)
  root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
  hum.WalkSpeed=originalSpeed hum:MoveTo(root.Position) root:SetNetworkOwnershipAuto()
  session.Dirty=originalDirty session.Saving=false
 end
end
local ok,err=xpcall(function()
 for n=1,10 do report.world2[n]={Boss=W2B.GetMaxHP(n),Walls={W2W.GetMaxHP(n,1),W2W.GetMaxHP(n,2),W2W.GetMaxHP(n,3),W2W.GetMaxHP(n,4)}} end
 local directions={{"Front",Vector3.new(0,0,1)},{"Left",Vector3.new(1,0,0)},{"Right",Vector3.new(-1,0,0)},{"Back",Vector3.new(0,0,-1)}}
 publish("VisualReview") task.wait(45)
 for n=6,10 do
  report.colliders[n]={directions={}}
  for _,pair in ipairs(directions) do
   local label,dir=pair[1],pair[2]
   E.StartRun(p,n) strength(1)
   W.ApplyDamageForStage(p,n,1000000000) E.SendState(p)
   local e=E.GetEnemy(n) local collider=e.MiniBossCollider
   collider.CanCollide=true
   local center=Vector3.new(collider.Position.X,5,collider.Position.Z)
   local localDir=collider.CFrame:VectorToObjectSpace(dir)
   local radius=math.min(math.abs(localDir.X)>.001 and collider.Size.X/2/math.abs(localDir.X) or math.huge,math.abs(localDir.Z)>.001 and collider.Size.Z/2/math.abs(localDir.Z) or math.huge)
   local start=center-dir*(radius+3)
   evidence:SetAttribute("Stage",n) evidence:SetAttribute("Direction",label)
   publish("Collider")
   place(start,dir)
   task.wait(.25)
   hum:MoveTo(center)
   task.wait(.65)
   local first=root.Position
   task.wait(.35)
   local at=root.Position
   local battle=B.Get(p)
   local row={Direction=label,Position=vec(at),MotionLast035=(at-first).Magnitude,Fighting=p:GetAttribute("IsFighting"),BossEncounter=battle~=nil,Attacks=battle and battle.Attacks,ColliderLocal=vec(collider.CFrame:PointToObjectSpace(at)),RootToCenter=(Vector3.new(at.X,5,at.Z)-center).Magnitude,CenterRayRadius=radius,FootY=at.Y-hum.HipHeight-root.Size.Y/2}
   hum:MoveTo(at-dir*14)
   task.wait(1.6)
   row.ExitNormal=p:GetAttribute("IsFighting")==false
   table.insert(report.colliders[n].directions,row)
   report.colliders[n].Size=vec(collider.Size)
   report.colliders[n].ZoneSize=vec(e.CombatZone.Size)
   report.colliders[n].Bottom=collider.Position.Y-collider.Size.Y/2
   publish("Collider")
  end
 end
 -- Actual automatic combat: only move the real character; never call damage APIs here.
 E.StartRun(p,6)
 for n=6,10 do
  local cfg=B.GetStageConfig(n)
  strength(cfg.RequiredStrength)
  assert(I.GetGloveBossDamageBonus(p)==0,"Glove correction is not zero")
  assert(p:GetAttribute("CurrentStage")==n,"Stage progression failed")
  evidence:SetAttribute("Stage",n)
  local row={Stage=n,RecommendedLevel=cfg.RecommendedLevel,RequiredStrength=cfg.RequiredStrength,ActualLevel=S.CalculateLevel(cfg.RequiredStrength),BossMaxHP=cfg.MaxHP,GloveBonus=I.GetGloveBossDamageBonus(p),InitialWalls=clone(W.GetSnapshotForStage(p,n).Maxes),WallHits=0}
  report.balance[n]=row
  publish("Wall")
  local lastTotal=0 for _,hp in ipairs(W.GetStageState(p,n).Gauges) do lastTotal+=hp end
  local started=os.clock()
  while not W.IsBossUnlockedForStage(p,n) and os.clock()-started<45 do
   local wall=W.GetCurrentWallForStage(p,n)
   local w=wall and wall:FindFirstChild("Wall")
   assert(w,"Current Wall missing")
   local at=Vector3.new(w.Position.X,5,w.Position.Z-5)
   place(at,Vector3.new(0,0,1))
   local initialIndex=W.GetCurrentIndexForStage(p,n)
   repeat
    task.wait(.04)
    local total=0 for _,hp in ipairs(W.GetStageState(p,n).Gauges) do total+=hp end
    if total<lastTotal then row.WallHits+=1 lastTotal=total end
   until W.GetCurrentIndexForStage(p,n)~=initialIndex or os.clock()-started>=45
  end
  assert(row.InitialWalls[1]==cfg.RequiredStrength*2 and row.InitialWalls[2]==cfg.RequiredStrength*2.5 and row.InitialWalls[3]==cfg.RequiredStrength*3 and row.InitialWalls[4]==cfg.RequiredStrength*4,"Incorrect Wall HP")
  row.WallsCleared=W.IsBossUnlockedForStage(p,n)
  assert(row.WallsCleared,"Wall timeout")
  publish("Boss")
  local e=E.GetEnemy(n) local collider=e.MiniBossCollider
  local center=Vector3.new(collider.Position.X,5,collider.Position.Z)
  local localDir=collider.CFrame:VectorToObjectSpace(Vector3.zAxis)
  local radius=math.min(math.abs(localDir.X)>.001 and collider.Size.X/2/math.abs(localDir.X) or math.huge,math.abs(localDir.Z)>.001 and collider.Size.Z/2/math.abs(localDir.Z) or math.huge)
  place(center-Vector3.zAxis*(radius+6),Vector3.zAxis)
  hum:MoveTo(center)
  local battle
  assert(waitUntil(function() battle=B.Get(p) return battle~=nil end,5),"Boss zone unreachable")
  row.BossStartingHP=battle.HP
  row.BossBattleDamage=battle.BattleDamage
  local stopAt=root.Position
  hum:MoveTo(stopAt)
  assert(waitUntil(function() return battle.Completed end,12),"Boss did not complete")
  row.BossHits=battle.Attacks
  row.BossFinalHP=battle.HP
  row.BossWon=battle.HP<=0
  assert(waitUntil(function() return n<10 and p:GetAttribute("CurrentStage")==n+1 or n==10 and p:GetAttribute("WorldComplete")==true end,3),"Progression/WorldComplete missing")
  row.NextStage=p:GetAttribute("CurrentStage")
  row.WorldComplete=p:GetAttribute("WorldComplete")
  row.Duration=os.clock()-started
  publish("StageComplete")
  task.wait(.8)
 end
 report.status="completed"
end,debug.traceback)
if not ok then report.status="failed" report.failure=tostring(err) end
restore()
report.ProfileRestored=p:GetAttribute("Strength")==originalAttrs.Strength and p:GetAttribute("Win")==originalAttrs.Win and session.Data.EquippedItems.Glove==originalData.EquippedItems.Glove
publish("Finished")

