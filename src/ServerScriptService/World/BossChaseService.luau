local contexts={}
local function forWorld(worldId)
 assert(worldId==1 or worldId==2,"Unsupported world")
 if contexts[worldId] then return contexts[worldId] end
-- Shared locomotion, isolated by World. Damage and outcomes remain in EnemyManager.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local M = {}
local World2Movement=worldId==2 and require(game.ReplicatedStorage.Config.World2BossMovementConfig)
local Animation=worldId==2 and require(script.Parent.World2BossAnimationService)
local CHASE_SPEED = 16 -- studs/second; shared by all World1 bosses
local TURN_RESPONSE = 4 -- exponential visual smoothing, not a gameplay turn limit
local CONTACT_GAP = 0.8
local EDGE_MARGIN = 0.25
local STUCK_WINDOW = 1.25
local records = {}
local targetProvider
local connection

local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function yawOf(cf)
 local v = cf.LookVector
 return math.atan2(-v.X, -v.Z)
end
local function angleDelta(a, b) return math.atan2(math.sin(b-a), math.cos(b-a)) end
local function stepToward(a, b, distance)
 local d = b-a
 return d.Magnitude <= distance and b or a+d.Unit*distance
end
local function isInside(r, position)
 local p = r.Floor.CFrame:PointToObjectSpace(position)
 return p.X >= r.MinX and p.X <= r.MaxX and p.Z >= r.MinZ and p.Z <= r.MaxZ
end
function M.ContainsPlayer(enemy, position)
 local r = records[enemy]
 return r ~= nil and isInside(r, position)
end
local function boundsAt(r, rotation)
 local lowX, highX, lowZ, highZ = math.huge, -math.huge, math.huge, -math.huge
 for _,point in r.Footprint do
  local v = r.Floor.CFrame:VectorToObjectSpace(rotation:VectorToWorldSpace(point))
  lowX=math.min(lowX,v.X); highX=math.max(highX,v.X)
  lowZ=math.min(lowZ,v.Z); highZ=math.max(highZ,v.Z)
 end
 return r.MinX-lowX, r.MaxX-highX, r.MinZ-lowZ, r.MaxZ-highZ
end
local function clampGoal(r, worldPosition, rotation)
 local minX,maxX,minZ,maxZ = boundsAt(r,rotation)
 if minX>maxX or minZ>maxZ then return nil end
 local p=r.Floor.CFrame:PointToObjectSpace(worldPosition)
 local world=r.Floor.CFrame:PointToWorldSpace(Vector3.new(math.clamp(p.X,minX,maxX),p.Y,math.clamp(p.Z,minZ,maxZ)))
 return Vector3.new(world.X,r.Home.Position.Y,world.Z)
end
local function boundaryOverhang(r, position, rotation)
 local minX,maxX,minZ,maxZ=boundsAt(r,rotation)
 local p=r.Floor.CFrame:PointToObjectSpace(position)
 return math.max(0,minX-p.X)+math.max(0,p.X-maxX)+math.max(0,minZ-p.Z)+math.max(0,p.Z-maxZ)
end
local function setMode(r, mode, player)
 if r.Mode~=mode then r.Mode=mode;r.Enemy:SetAttribute("ChaseState",mode) end
 local id=player and player.UserId or 0
 if r.TargetId~=id then r.TargetId=id;r.Enemy:SetAttribute("ChaseTargetUserId",id) end
end
local function contactDistance(r, direction, rotation, root)
 local cf=rotation*r.ColliderLocal.Rotation
 local d=cf:VectorToObjectSpace(direction)
 local half=r.ColliderSize/2
 local tx=math.abs(d.X)>0.0001 and half.X/math.abs(d.X) or math.huge
 local tz=math.abs(d.Z)>0.0001 and half.Z/math.abs(d.Z) or math.huge
 return math.min(tx,tz)+math.max(root.Size.X,root.Size.Z)/2+CONTACT_GAP
end
local function pickTarget(r)
 local candidates=targetProvider and targetProvider(r.Stage,r.Enemy) or {}
 local selected
 for _,p in candidates do
  if p==r.Target then return p end -- one shared Boss: keep its current eligible target
  if not selected or p.UserId<selected.UserId then selected=p end
 end
 return selected
end
local function update(r, dt)
 local enemy=r.Enemy
 if not enemy.Parent or not r.Floor.Parent then M.Unregister(enemy);return end
 if Animation and not Animation.Ready(enemy) then
  enemy:SetAttribute("BossMotionSpeed",0);setMode(r,"Intro",nil);return
 end
 local current=enemy:GetPivot()
 local actualTravel=(current.Position-r.LastPosition).Magnitude
 r.LastPosition=current.Position
 local target=pickTarget(r)
 r.Target=target
 local destination, targetYaw
 local rotation=current.Rotation
 if target then
  local ch=target.Character
  local root=ch and ch:FindFirstChild("HumanoidRootPart")
  local hum=ch and ch:FindFirstChildOfClass("Humanoid")
  if not root or not hum or hum.Health<=0 or target.Parent~=Players then return end
  local center=current:PointToWorldSpace(r.ColliderLocal.Position)
  local delta=flat(root.Position-center)
  local distance=delta.Magnitude
  local direction=distance>0.001 and delta/distance or flat(current.LookVector)
  targetYaw=math.atan2(-direction.X,-direction.Z)
  local yaw=yawOf(current)+angleDelta(yawOf(current),targetYaw)*(1-math.exp(-r.TurnResponse*dt))
  rotation=CFrame.Angles(0,yaw,0)
  local gap=distance-contactDistance(r,direction,rotation,root)
  destination=clampGoal(r,current.Position+direction*math.max(0,gap),rotation)
  if not destination then setMode(r,"BoundsInvalid",nil);return end
  if r.Recovery then
   destination=clampGoal(r,r.Recovery,rotation) or destination
   if (destination-current.Position).Magnitude<0.35 then r.Recovery=nil end
  end
  setMode(r,r.Recovery and "Recovering" or "Chasing",target)
 else
  r.Recovery=nil
  destination=r.Home.Position
  targetYaw=yawOf(r.Home)
  local yaw=yawOf(current)+angleDelta(yawOf(current),targetYaw)*(1-math.exp(-r.TurnResponse*dt))
  rotation=CFrame.Angles(0,yaw,0)
  if (destination-current.Position).Magnitude<0.01 and math.abs(angleDelta(yawOf(current),targetYaw))<0.002 then
   if r.Mode~="Idle" then enemy:PivotTo(r.Home) end
   setMode(r,"Idle",nil)
   if Animation then enemy:SetAttribute("BossMotionSpeed",0) end
   r.Window=0;r.Commanded=0;r.Travel=0
   return
  end
  setMode(r,"Returning",nil)
 end
 local nextPosition=stepToward(current.Position,destination,r.Speed*dt)
 -- Pivot always remains in this Stage. Authored initial visual overhang is
 -- drawn inward at normal speed, rather than snapping at combat start.
 local p=r.Floor.CFrame:PointToObjectSpace(nextPosition)
 p=Vector3.new(math.clamp(p.X,r.MinX,r.MaxX),p.Y,math.clamp(p.Z,r.MinZ,r.MaxZ))
 nextPosition=r.Floor.CFrame:PointToWorldSpace(p)
 -- Turning a long visual next to a wall needs clearance too. Advance the
 -- turn only as far as the footprint allows, while continuing to move inward.
 local allowance=boundaryOverhang(r,current.Position,current.Rotation)+0.0001
 if not target then allowance=math.max(allowance,boundaryOverhang(r,r.Home.Position,r.Home.Rotation)+0.0001) end
 if boundaryOverhang(r,nextPosition,rotation)>allowance then
  local desiredYaw=yawOf(rotation)
  local accepted=false
  for attempt=1,10 do
   local trial=CFrame.Angles(0,yawOf(current)+angleDelta(yawOf(current),desiredYaw)*2^-attempt,0)
   if boundaryOverhang(r,nextPosition,trial)<=allowance then rotation=trial;accepted=true;break end
  end
  if not accepted then
   rotation=current.Rotation
   local safeGoal=clampGoal(r,destination,rotation)
   if safeGoal then nextPosition=stepToward(current.Position,safeGoal,r.Speed*dt) end
  end
 end
 local commanded=(nextPosition-current.Position).Magnitude
 enemy:PivotTo(CFrame.new(nextPosition)*rotation)
 if Animation then enemy:SetAttribute("BossMotionSpeed",commanded/math.max(dt,.001)) end
 if target then
  r.Window+=dt;r.Commanded+=commanded;r.Travel+=actualTravel
  if r.Window>=STUCK_WINDOW then
   -- A stationary in-range Boss, a clamped goal and rotation-only motion
   -- are not stalls: recovery requires commanded translational movement.
   if r.Commanded>2 and r.Travel<0.25 and (destination-current.Position).Magnitude>1 then
    local center=r.Floor.CFrame:PointToWorldSpace(Vector3.new((r.MinX+r.MaxX)/2,0,(r.MinZ+r.MaxZ)/2))
    r.Recovery=clampGoal(r,stepToward(current.Position,Vector3.new(center.X,r.Home.Position.Y,center.Z),6),rotation)
    r.Recoveries+=1
    enemy:SetAttribute("ChaseRecoveryCount",r.Recoveries)
   end
   r.Window=0;r.Commanded=0;r.Travel=0
  end
 else r.Window=0;r.Commanded=0;r.Travel=0 end
end
function M.SetTargetProvider(provider)
 targetProvider=provider
 if not connection then
  connection=RunService.Heartbeat:Connect(function(dt)
   -- Never make a large catch-up jump after a slow frame.
   dt=math.min(dt,0.05)
   for _,r in records do update(r,dt) end
  end)
 end
end
function M.Register(enemy, stage, stageModel)
 local floor=assert(stageModel:FindFirstChild("Floor"),"Stage Floor missing")
 local home=enemy:GetPivot()
 local movement=World2Movement and World2Movement.Get(stage)
 local r={Enemy=enemy,Stage=stage,Floor=floor,Home=home,Footprint={},Mode="Idle",
  Speed=movement and movement.Speed or CHASE_SPEED,
  TurnResponse=movement and movement.TurnResponse or TURN_RESPONSE,
  MinX=-floor.Size.X/2+EDGE_MARGIN,MaxX=floor.Size.X/2-EDGE_MARGIN,
  MinZ=-floor.Size.Z/2+EDGE_MARGIN,MaxZ=floor.Size.Z/2-EDGE_MARGIN,
  LastPosition=home.Position,Window=0,Commanded=0,Travel=0,Recoveries=0}
 if worldId==2 then
  local segment=stageModel:FindFirstChild(("Stage%d.%d"):format(stage,require(game.ReplicatedStorage.Config.World2Config).GetWallCount(stage)))
  local wall=segment and segment:FindFirstChild("Wall")
  if wall and wall:IsA("BasePart") then
   local cf=floor.CFrame:ToObjectSpace(wall.CFrame)
   local half=wall.Size/2
   local zHalf=math.abs(cf.RightVector.Z)*half.X+math.abs(cf.UpVector.Z)*half.Y+math.abs(cf.LookVector.Z)*half.Z
   r.MinZ=math.max(r.MinZ,cf.Position.Z+zHalf+EDGE_MARGIN)
  end
 end
 local left=stageModel:FindFirstChild("LeftWall")
 local right=stageModel:FindFirstChild("RightWall")
 if left then r.MinX=math.max(r.MinX,floor.CFrame:PointToObjectSpace(left.Position).X+left.Size.X/2+EDGE_MARGIN) end
 if right then r.MaxX=math.min(r.MaxX,floor.CFrame:PointToObjectSpace(right.Position).X-right.Size.X/2-EDGE_MARGIN) end
 local endWall=stageModel:FindFirstChild("Stage10BoundaryWall")
 if endWall then r.MaxZ=math.min(r.MaxZ,floor.CFrame:PointToObjectSpace(endWall.Position).Z-endWall.Size.Z/2-EDGE_MARGIN) end
 local collider=assert(enemy:FindFirstChild("MiniBossCollider"),"Boss collider missing")
 r.ColliderLocal=home:ToObjectSpace(collider.CFrame);r.ColliderSize=collider.Size
 for _,part in enemy:GetDescendants() do
  if part:IsA("BasePart") and (part==collider or part.Name=="BossVisualBounds" or part.Transparency<1) then
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    table.insert(r.Footprint,home:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)))
   end end end
  end
 end
 records[enemy]=r
 if Animation then Animation.Register(enemy,stage);enemy:SetAttribute("BossMotionSpeed",0) end
 enemy:SetAttribute("ChaseHomePivot",home)
 enemy:SetAttribute("ChaseSpeed",r.Speed)
 enemy:SetAttribute("ChaseTurnResponse",r.TurnResponse)
 enemy:SetAttribute("ChaseState","Idle")
 enemy:SetAttribute("ChaseTargetUserId",0)
 enemy:SetAttribute("ChaseRecoveryCount",0)
end
function M.Unregister(enemy)
 if Animation then Animation.Unregister(enemy) end
 records[enemy]=nil
end
function M.BeginIntro(enemy)
 if Animation then Animation.BeginIntro(enemy) end
end
 contexts[worldId]=M
 M.ForWorld=forWorld
 return M
end
return forWorld(1)
