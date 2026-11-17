-- Shared geometry and bounded longitudinal motion. No progression writes.
local Config=require(game.ReplicatedStorage.Config.World1WalkwayConfig)
local ArrowGeometry=require(script.Parent.FloorArrowGeometry)
local arrowHalfWidth=ArrowGeometry.Dimensions(Config.WidthMultiplier).Width/2
local M={}
function M.Bounds(route,character)
 return Config.StartDistance,M.EndDistance(route,character)-Config.EndpointTolerance,arrowHalfWidth
end
function M.Contains(route,along,side,bodyEnd)
 local first,last,halfWidth=M.Bounds(route)
 if bodyEnd then last=math.min(last,bodyEnd-Config.EndpointTolerance) end
 return along>=first and along<last and math.abs(side)<=halfWidth
end
function M.new()
 local owner,stageOwner,sectionOwner,floorOwner
 local wallLocal,wallSize
 return function()
  local map=workspace:FindFirstChild("GeneratedMap")
  local lobby=map and map:FindFirstChild("TrainingArea")
  local spawn=lobby and lobby:FindFirstChild("SpawnLocation")
  local floor=lobby and lobby:FindFirstChild("Floor")
  local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage01")
  local section=stage and stage:FindFirstChild("Stage1.1")
  if map~=owner or stage~=stageOwner or section~=sectionOwner or floor~=floorOwner then
   owner,stageOwner,sectionOwner,floorOwner=map,stage,section,floor
   wallLocal,wallSize=nil,nil
  end
  if not spawn or not spawn:IsA("BasePart") or not floor or not floor:IsA("BasePart")
   or not floor.Anchored or not floor.CanCollide or not stage or not section then return end
  local wall=section:FindFirstChild("Wall")
  if wall and wall:IsA("BasePart") then
   wallLocal=floor.CFrame:ToObjectSpace(wall.CFrame);wallSize=wall.Size
  end
  -- The first wall's structural reference survives personal wall destruction.
  if not wallLocal then return end
  local cf=floor.CFrame*wallLocal
  local delta=Vector3.new(cf.X-spawn.Position.X,0,cf.Z-spawn.Position.Z)
  if delta.Magnitude<.01 then return end
  local direction=delta.Unit
  local localDirection=cf:VectorToObjectSpace(direction)
  local face=math.huge
  for _,axis in {"X","Y","Z"} do
   if math.abs(localDirection[axis])>1e-5 then face=math.min(face,wallSize[axis]/(2*math.abs(localDirection[axis]))) end
  end
  return {Origin=spawn.Position,Direction=direction,Side=direction:Cross(Vector3.yAxis),
   WallDistance=delta.Magnitude-face,Map=map,Lobby=lobby,Stage=stage,Section=section,Floor=floor}
 end
end
function M.IsFloor(part,route)
 if not part or not part:IsA("BasePart") or not part.Anchored or not part.CanCollide then return false end
 if part==route.Floor then return true end
 local parent=part.Parent
 if parent==route.Map:FindFirstChild("LobbyCorridorConnector") then return part.Name=="ConnectorFloor" end
 if part.Name=="Floor" and (parent==route.Stage or parent==route.Section or parent==route.Stage:FindFirstChild("WalkableGeometry")) then return true end
 if part.Name~="Upper" and part.Name~="Lower" then return false end
 local entrance=route.Lobby:FindFirstChild("EntranceCarpets")
 if parent==entrance then return true end
 if parent and (parent.Name=="Path" or parent.Name=="PathToRun") then
  return parent.Parent==entrance or parent.Parent==route.Stage:FindFirstChild("WalkableGeometry") or parent.Parent==route.Section
 end
 return false
end
function M.Coordinates(route,position)
 local delta=position-route.Origin
 return delta:Dot(route.Direction),delta:Dot(route.Side)
end
function M.TransportVelocity(walkSpeed,input,remaining,dt)
 -- Input is only the wall-axis projection of normal movement (-1..1).
 -- Recompute from intent every step; never add to last frame's velocity.
 local walking=walkSpeed*math.clamp(input,-1,1)
 local stoppingSpeed=math.max(0,remaining/math.max(dt*2,.08))
 local velocity=math.min(Config.TransportSpeed+walking,stoppingSpeed)
 return velocity,math.max(0,velocity-walking)
end
function M.EndDistance(route,character)
 -- Stop the physical body before the wall even for large/custom body sizes.
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local extent=0
 if root then for _,part in character:GetChildren() do
  if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
   local cf=part.CFrame;local half=part.Size/2;local d=route.Direction
   extent=math.max(extent,(part.Position-root.Position):Dot(d)+math.abs(cf.RightVector:Dot(d))*half.X
    +math.abs(cf.UpVector:Dot(d))*half.Y+math.abs(cf.LookVector:Dot(d))*half.Z)
  end
 end end
 return route.WallDistance-math.max(Config.EndClearance,extent+.5)
end
function M.Grounded(character,humanoid,root,route,params)
 local state=humanoid:GetState()
 if humanoid.Health<=0 or root.Anchored or humanoid.Sit or humanoid.PlatformStand or humanoid.Jump
  or (state~=Enum.HumanoidStateType.Running and state~=Enum.HumanoidStateType.RunningNoPhysics and state~=Enum.HumanoidStateType.Landed)
  or math.abs(root.AssemblyLinearVelocity.Y)>3 then return false end
 local standing=humanoid.HipHeight+root.Size.Y/2
 if humanoid.RigType==Enum.HumanoidRigType.R6 then
  local leg=character:FindFirstChild("Left Leg");standing+=leg and leg.Size.Y or 0
 end
 -- First actual collision below the character must be an authored walking floor.
 -- FloorMaterial is not authoritative on a server with client-owned avatars.
 local hit=workspace:Raycast(root.Position,Vector3.new(0,-standing-Config.GroundTolerance,0),params)
 if not hit or not M.IsFloor(hit.Instance,route) or hit.Normal.Y<.7 then return false end
 if math.abs(hit.Distance-standing)<=Config.GroundTolerance then return true end
 -- Also inspect real foot soles: custom scaled rigs need not have a fixed Root Y.
 for _,name in {"LeftFoot","RightFoot","Left Leg","Right Leg"} do
  local foot=character:FindFirstChild(name)
  if foot and foot:IsA("BasePart") then
   local cf=foot.CFrame
   local halfY=(math.abs(cf.RightVector.Y)*foot.Size.X+math.abs(cf.UpVector.Y)*foot.Size.Y+math.abs(cf.LookVector.Y)*foot.Size.Z)/2
   local sole=foot.Position-Vector3.yAxis*halfY
   local footHit=workspace:Raycast(sole+Vector3.yAxis*.1,-Vector3.yAxis*(Config.GroundTolerance+.1),params)
   if footHit and M.IsFloor(footHit.Instance,route) and footHit.Normal.Y>=.7 then return true end
  end
 end
 return false
end
return M
