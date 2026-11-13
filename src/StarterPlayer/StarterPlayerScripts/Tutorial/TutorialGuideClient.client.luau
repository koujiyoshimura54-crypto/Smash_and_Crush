local treadmillFolder=workspace:WaitForChild("Treadmills")
-- Local-only floor navigation; progression and completion use existing server state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local IntroBalance=require(RS.Config:WaitForChild("World1BossConfig"))
local RunService=game:GetService("RunService")
local FirstBattle=require(RS.Modules.FirstBattleTutorialState)
local Coordinator=require(RS.Modules.TutorialPresentationCoordinator)
local wallCount=#IntroBalance.GetWallConfig(1).Walls
local player=Players.LocalPlayer
local wallPrompt=require(RS.Modules:WaitForChild("Stage1WallPrompt")).Mount(player)
local trained=false
local enteredWall=false -- Monotonic Step2 completion: Wall clear, never combat entry.
local trophy
local wallIndex=1
local stage1Defeated=false
local resetSequence=player:GetAttribute("TutorialResetSequence")
local connections={}
local remoteConnection
local route
local pool={}
-- Remove only a prior local guide with this script's ownership metadata.
-- A restarted LocalScript must not leave a second guide that blocks itself.
for _,previous in workspace:GetChildren() do
 if previous:IsA("Folder") and previous.Name=="TutorialFloorGuide"
  and previous:GetAttribute("ChevronCount")~=nil then previous:Destroy() end
end
local SPACING=3.5
local MAX_CHEVRONS=160
local UPDATE_INTERVAL=.2
local floorParts={}
local floorSet={}
local carpetSet={}
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.IgnoreWater=true
local CELL=16
local records,dirty,noQueryGrid,noQueryMoving,noQueryLarge={},{},{},{},{}
local cacheConnections={}
local activeCache=false
local floorsDirty=true
local sceneRevision=0
local localGrid,localLarge={},{}
local previousCandidates={}
local lastRouteState
local tickConnection
local updateScheduler
local characterConnections={}
local function assign(object,key,value)
 if object[key]~=value then object[key]=value end
end
local function attribute(object,key,value)
 if object:GetAttribute(key)~=value then object:SetAttribute(key,value) end
end
local function clear()
 if route then route:Destroy();route=nil end
 table.clear(pool)
 lastRouteState=nil
end
local function hide()
 if route then attribute(route,"Target","") end
 for _,pair in ipairs(pool) do for _,part in ipairs(pair) do assign(part,"Transparency",1) end end
 lastRouteState=nil
end
local function refreshFloors()
 table.clear(floorParts);table.clear(floorSet);table.clear(carpetSet)
 local function add(part)
  if part and part:IsA("BasePart") then
   floorSet[part]=true;table.insert(floorParts,part)
   if part.Name=="Upper" or part.Name=="Lower" then carpetSet[part]=true end
  end
 end
 local map=workspace:FindFirstChild("GeneratedMap")
 if map then
  local lobby=map:FindFirstChild("TrainingArea")
  add(lobby and lobby:FindFirstChild("Floor"))
  -- Authored World1 walking carpet ONLY. Direct Upper/Lower layers of this
  -- plaza and its branches are walkable; nested equipment stands/mats are not.
  local entrance=lobby and lobby:FindFirstChild("EntranceCarpets")
  if entrance then
   add(entrance:FindFirstChild("Upper"));add(entrance:FindFirstChild("Lower"))
   for _,branch in entrance:GetChildren() do
    if branch.Name=="Path" or branch.Name=="PathToRun" then
     add(branch:FindFirstChild("Upper"));add(branch:FindFirstChild("Lower"))
    end
   end
  end
  local treadPath=lobby and lobby:FindFirstChild("PathToTreadmills")
  if treadPath then add(treadPath:FindFirstChild("Upper"));add(treadPath:FindFirstChild("Lower")) end
  -- Only these exact nested layers form the walkable treadmill carpet.
  local stand=treadPath and treadPath:FindFirstChild("ThreadmillStand")
  if stand then add(stand:FindFirstChild("Upper"));add(stand:FindFirstChild("Lower")) end
  local connector=map:FindFirstChild("LobbyCorridorConnector")
  add(connector and connector:FindFirstChild("ConnectorFloor"))
  local nextArea=map:FindFirstChild("NextWorldArea")
  add(nextArea and nextArea:FindFirstChild("Floor"))
  local corridor=map:FindFirstChild("BattleCorridor")
  if corridor then for major=1,10 do
   local stage=corridor:FindFirstChild(("Stage%02d"):format(major))
   if stage then
    add(stage:FindFirstChild("Floor"))
    local walkable=stage:FindFirstChild("WalkableGeometry")
    local stagePath=walkable and walkable:FindFirstChild("PathToRun")
    if stagePath then add(stagePath:FindFirstChild("Upper"));add(stagePath:FindFirstChild("Lower")) end
    for sub=1,5 do
     local section=stage:FindFirstChild(("Stage%d.%d"):format(major,sub))
     add(section and section:FindFirstChild("Floor"))
     local sectionPath=section and section:FindFirstChild("PathToRun")
     if sectionPath then add(sectionPath:FindFirstChild("Upper"));add(sectionPath:FindFirstChild("Lower")) end
    end
   end
  end end
 end
 -- Optional Merge navigation uses the same floor-only renderer in the second lobby.
 local world2=workspace:FindFirstChild("World2Map")
 local secondLobby=world2 and world2:FindFirstChild("TrainingArea")
 add(secondLobby and secondLobby:FindFirstChild("Floor"))
 rayParams.FilterDescendantsInstances=floorParts
 floorsDirty=false;sceneRevision+=1
end
local function extent(part)
 local cf=part.CFrame;local half=part.Size*.5
 local r,u,b=cf.RightVector,cf.UpVector,cf.LookVector
 local x=math.abs(r.X)*half.X+math.abs(u.X)*half.Y+math.abs(b.X)*half.Z
 local y=math.abs(r.Y)*half.X+math.abs(u.Y)*half.Y+math.abs(b.Y)*half.Z
 local z=math.abs(r.Z)*half.X+math.abs(u.Z)*half.Y+math.abs(b.Z)*half.Z
 local p=cf.Position
 return {part=part,cf=cf,size=part.Size,minX=p.X-x,maxX=p.X+x,minY=p.Y-y,maxY=p.Y+y,minZ=p.Z-z,maxZ=p.Z+z}
end
local function cellsFor(box)
 return math.floor(box.minX/CELL),math.floor(box.maxX/CELL),math.floor(box.minZ/CELL),math.floor(box.maxZ/CELL)
end
local function insert(grid,large,part,box)
 local x0,x1,z0,z1=cellsFor(box)
 local cells={}
 if (x1-x0+1)*(z1-z0+1)>256 then large[part]=box;return cells end
 for x=x0,x1 do for z=z0,z1 do
  local key=x..":"..z;local bucket=grid[key]
  if not bucket then bucket={};grid[key]=bucket end
  bucket[part]=box;table.insert(cells,key)
 end end
 return cells
end
local function unindex(part,record)
 for _,key in record.cells or {} do
  local bucket=noQueryGrid[key]
  if bucket then bucket[part]=nil;if next(bucket)==nil then noQueryGrid[key]=nil end end
 end
 record.cells=nil;noQueryMoving[part]=nil;noQueryLarge[part]=nil
end
local function reindex(part,record)
 unindex(part,record)
 if part:IsDescendantOf(workspace) then
  if part.Anchored then record.cells=insert(noQueryGrid,noQueryLarge,part,extent(part))
  else noQueryMoving[part]=true end
 end
end
local function register(part)
 if not part:IsA("BasePart") or part==workspace.Terrain or records[part]
  or (route and part:IsDescendantOf(route)) then return end
 local record={};records[part]=record;reindex(part,record)
 -- Static OBBs are indexed once, independently of query/collision flags.
 -- Moving parts are read from their small live set on each route refresh.
 record.connection=part.Changed:Connect(function(property)
  if property=="Anchored" or ((property=="CFrame" or property=="Size") and part.Anchored) then dirty[part]=true end
  if floorSet[part] and (property=="CFrame" or property=="Size" or property=="CanQuery") then sceneRevision+=1 end
  if property=="Name" or property=="Parent" then floorsDirty=true end
 end)
end
local function release(part)
 local record=records[part]
 if record then unindex(part,record);record.connection:Disconnect();records[part]=nil;dirty[part]=nil end
end
local function stopCache()
 if not activeCache then return end
 activeCache=false
 for _,c in cacheConnections do c:Disconnect() end;table.clear(cacheConnections)
 for part,record in pairs(records) do record.connection:Disconnect();records[part]=nil end
 table.clear(dirty);table.clear(noQueryGrid);table.clear(noQueryMoving);table.clear(noQueryLarge)
 table.clear(localGrid);table.clear(localLarge);table.clear(previousCandidates)
 table.clear(floorParts);table.clear(floorSet);rayParams.FilterDescendantsInstances={}
 floorsDirty=true;lastRouteState=nil
end
local function startCache()
 if activeCache then return end
 activeCache=true
 table.insert(cacheConnections,workspace.DescendantAdded:Connect(function(part)
  if part:IsA("BasePart") and not (route and part:IsDescendantOf(route)) then register(part);floorsDirty=true end
 end))
 table.insert(cacheConnections,workspace.DescendantRemoving:Connect(function(part)
  if records[part] then release(part);floorsDirty=true end
 end))
 -- One initial enumeration per active tutorial lifetime, never per arrow.
 for _,part in workspace:GetDescendants() do register(part) end
 refreshFloors()
end
local function overlaps(box,x0,x1,z0,z1,bottom,top)
 return box.maxX>=x0 and box.minX<=x1 and box.maxZ>=z0 and box.minZ<=z1
  and box.maxY>=bottom+.01 and box.minY<=top
end
local function prepareCandidates(origin,target,top)
 startCache()
 if floorsDirty then refreshFloors() end
 for part in pairs(dirty) do local record=records[part];if record then reindex(part,record) end;dirty[part]=nil end
 local x0,x1=math.min(origin.X,target.X)-2,math.max(origin.X,target.X)+2
 local z0,z1=math.min(origin.Z,target.Z)-2,math.max(origin.Z,target.Z)+2
 local bottom=top-256
 local selected={}
 local function add(part,box)
  if selected[part] or not part.Parent or floorSet[part] or part.Transparency>=1 or part.LocalTransparencyModifier>=.99
   or (route and part:IsDescendantOf(route)) then return end
  box=box or extent(part)
  if overlaps(box,x0,x1,z0,z1,bottom,top) then selected[part]=table.clone(box) end
 end
 -- Query the cached static cells once for the straight route, not all parts
 -- per arrow. This includes CanQuery=false and every collision group.
 local cx0,cx1=math.floor(x0/CELL),math.floor(x1/CELL)
 local cz0,cz1=math.floor(z0/CELL),math.floor(z1/CELL)
 for x=cx0,cx1 do for z=cz0,cz1 do
  for part,box in noQueryGrid[x..":"..z] or {} do add(part,box) end
 end end
 for part,box in noQueryLarge do add(part,box) end
 for part in noQueryMoving do if part.Parent then add(part) end end
 local changed=false
 for part,box in selected do
  box.transparency=part.Transparency;box.localTransparency=part.LocalTransparencyModifier
  local old=previousCandidates[part]
  if not old or old.cf~=box.cf or old.size~=box.size or old.transparency~=box.transparency
   or old.localTransparency~=box.localTransparency then changed=true end
 end
 for part in previousCandidates do if not selected[part] then changed=true;break end end
 previousCandidates=selected
 if changed then sceneRevision+=1 end
 table.clear(localGrid);table.clear(localLarge)
 for part,box in selected do insert(localGrid,localLarge,part,box) end
end
local function nearCandidates(point,top)
 local selected={};local candidates={}
 local function add(part,box)
  if not selected[part] and overlaps(box,point.X-1.5,point.X+1.5,point.Z-1.5,point.Z+1.5,point.Y,top) then
   selected[part]=true;table.insert(candidates,part)
  end
 end
 for x=math.floor((point.X-1.5)/CELL),math.floor((point.X+1.5)/CELL) do
  for z=math.floor((point.Z-1.5)/CELL),math.floor((point.Z+1.5)/CELL) do
   for part,box in localGrid[x..":"..z] or {} do add(part,box) end
  end
 end
 for part,box in localLarge do add(part,box) end
 return candidates
end
-- Intersect a vertical segment with an asset's oriented bounds. This also
-- catches decorative mats with CanQuery=false; never lift an arrow onto them.
local function blocks(part,point,top)
 local a=part.CFrame:PointToObjectSpace(Vector3.new(point.X,top,point.Z))
 local b=part.CFrame:PointToObjectSpace(point+Vector3.new(0,.01,0))
 local delta=b-a
 local half=part.Size/2
 local low,high=0,1
 for _,axis in {"X","Y","Z"} do
  if math.abs(delta[axis])<.00001 then
   if math.abs(a[axis])>half[axis] then return false end
  else
   local first=(-half[axis]-a[axis])/delta[axis]
   local last=(half[axis]-a[axis])/delta[axis]
   if first>last then first,last=last,first end
   low=math.max(low,first);high=math.min(high,last)
   if low>high then return false end
  end
 end
 return true
end
local function floorOnly(hit,direction,top)
 if not hit or not floorSet[hit.Instance] or hit.Normal.Y<=.5 then return false end
 local normal=hit.Normal
 local forward=(direction-normal*direction:Dot(normal)).Unit
 local side=forward:Cross(normal).Unit
 local candidates=nearCandidates(hit.Position,top)
 local points={hit.Position}
 local highest=hit.Position.Y
 local tip=hit.Position+forward*.65
 for _,sign in {-1,1} do
  local tail=hit.Position-forward*.65+side*(sign*1.05)
  local edge=(tip-tail).Unit:Cross(normal)*.17
  for _,point in {tip,tail,(tip+tail)/2} do
   points[#points+1]=point+edge
   points[#points+1]=point-edge
  end
 end
 for _,point in points do
  local floorHit=workspace:Raycast(Vector3.new(point.X,top,point.Z),Vector3.new(0,-256,0),rayParams)
  if not floorHit or not floorSet[floorHit.Instance] or floorHit.Normal.Y<=.5 then return false end
  -- Only registered carpet edges may bridge their measured <=0.4-stud
  -- step to another approved walking surface; equipment remains an occluder.
  local tolerance=(carpetSet[hit.Instance] or carpetSet[floorHit.Instance]) and .45 or .08
  if math.abs(floorHit.Position.Y-point.Y)>tolerance then return false end
  highest=math.max(highest,floorHit.Position.Y)
  for _,part in candidates do
   if part.Parent and part.Transparency<1 and part.LocalTransparencyModifier<.99
    and blocks(part,floorHit.Position,top) then return false end
  end
 end
 return true,highest
end
local function arm(index,side)
 local part=Instance.new("Part")
 part.Name="Chevron"..index.."_"..side
 part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false
 part.CastShadow=false part.Material=Enum.Material.Neon part.Color=Color3.new(1,1,1)
 part.Transparency=1 part.Size=Vector3.new(.34,.045,1)
 part.Parent=route
 return part
end
local function show(key,target)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then hide();return end
 if not route then
  route=Instance.new("Folder") route.Name="TutorialFloorGuide" route.Parent=workspace
 end
 attribute(route,"Target",key)
 local nodes={root.Position}
 local previous=nodes[#nodes]
 if Vector3.new(target.X-previous.X,0,target.Z-previous.Z).Magnitude>.1 then nodes[#nodes+1]=target end
 local segments={}
 local distance=0
 for nodeIndex=1,#nodes-1 do
  local delta=Vector3.new(nodes[nodeIndex+1].X-nodes[nodeIndex].X,0,nodes[nodeIndex+1].Z-nodes[nodeIndex].Z)
  if delta.Magnitude>.1 then
   segments[#segments+1]={Start=nodes[nodeIndex],Direction=delta.Unit,Length=delta.Magnitude}
   distance+=delta.Magnitude
  end
 end
 if distance<2 then hide();return end
 local spacing=math.max(SPACING,distance/MAX_CHEVRONS)
 local count=math.min(MAX_CHEVRONS,math.floor((distance-1)/spacing))
 local castTop=math.max(root.Position.Y,target.Y)+10
 prepareCandidates(root.Position,target,castTop)
 local state={key=key,origin=root.Position,target=target,revision=sceneRevision,top=castTop}
 if lastRouteState and lastRouteState.key==key and lastRouteState.origin==state.origin
  and lastRouteState.target==target and lastRouteState.revision==sceneRevision and lastRouteState.top==castTop then return end
 lastRouteState=state
 local segmentIndex=1
 local segmentStartDistance=0
 for index=1,count do
  local pair=pool[index]
  if not pair then pair={arm(index,"Left"),arm(index,"Right")};pool[index]=pair end
  local routeDistance=index*spacing
  while segmentIndex<#segments and routeDistance>segmentStartDistance+segments[segmentIndex].Length do
   segmentStartDistance+=segments[segmentIndex].Length
   segmentIndex+=1
  end
  local segment=segments[segmentIndex]
  local localDistance=math.clamp(routeDistance-segmentStartDistance,0,segment.Length)
  local direction=segment.Direction
  local center=segment.Start+direction*localDistance
  local hit=workspace:Raycast(Vector3.new(center.X,castTop,center.Z),Vector3.new(0,-256,0),rayParams)
  local supported,height=floorOnly(hit,direction,castTop)
  if supported then
   local normal=hit.Normal
   local forward=(direction-normal*direction:Dot(normal)).Unit
   local side=forward:Cross(normal).Unit
   local origin=Vector3.new(hit.Position.X,height,hit.Position.Z)+normal*.055
   local tip=origin+forward*.65
   for armIndex,sign in ipairs({-1,1}) do
    local tail=origin-forward*.65+side*(sign*1.05)
    local length=(tip-tail).Magnitude
    assign(pair[armIndex],"Size",Vector3.new(.34,.045,length))
    assign(pair[armIndex],"CFrame",CFrame.lookAt((tip+tail)/2,tip,normal))
    assign(pair[armIndex],"Transparency",0)
   end
  else
   assign(pair[1],"Transparency",1);assign(pair[2],"Transparency",1)
  end
 end
 for index=count+1,#pool do assign(pool[index][1],"Transparency",1);assign(pool[index][2],"Transparency",1) end
 attribute(route,"ChevronCount",count)
 attribute(route,"Step1Completed",trained)
 attribute(route,"Step2Completed",enteredWall)
end
local function wallCleared()
 trained=true enteredWall=true
end
local function inLobby(character)
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local map=workspace:FindFirstChild("GeneratedMap")
 local area=map and map:FindFirstChild("TrainingArea")
 local floor=area and area:FindFirstChild("Floor")
 if not root or not floor then return false end
 local p=floor.CFrame:PointToObjectSpace(root.Position)
 return math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 and math.abs(p.Y)<=40
end
local function refresh()
 wallPrompt:SetGuide(nil,nil)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if updateScheduler then updateScheduler() end
 local pg=player:FindFirstChild("PlayerGui")
 local mergeGui=pg and pg:FindFirstChild("MergeShopGui")
 local panel=mergeGui and mergeGui:FindFirstChild("MergeShopPanel")
 local phase=FirstBattle.Phase(FirstBattle.Read(player),{
  -- Existing WorldGate authority represents the initial World1 with a nil attribute.
  World=player:GetAttribute("CurrentWorld") or 1,Alive=humanoid~=nil and humanoid.Health>0,
  InLobby=inLobby(character),MergeOpen=panel~=nil and panel.Visible,
  Merged=player:GetAttribute("OreTutorialCompleted")==true,
  Equipped=player:GetAttribute("DumbbellEquipTutorialInitialCompleted")==true,Level=player:GetAttribute("Level"),
 })
 local target=player:GetAttribute("OreTutorialTarget")
 if phase=="Merge" then
  if typeof(target)=="Vector3" then show("OreMerge",target) else hide() end
  return
 elseif phase=="Equip" or phase=="Waiting" then hide();return end
 local legacy=phase=="Legacy"
 if player:GetAttribute("TutorialCompleted")~=false
  or phase=="Complete" and not (stage1Defeated and trophy) then
  local egg=player:GetAttribute("EggTutorialTarget")
  local pet=player:GetAttribute("PetMergeTutorialTarget")
  target=target or egg or pet
  if FirstBattle.AllowLaterGuides(player) and typeof(target)=="Vector3" and humanoid and humanoid.Health>0 then show(egg and "BasicEgg" or pet and "PetMerge" or "OreMerge",target)
  else clear();stopCache() end
  return
 end
 if (player:GetAttribute("CurrentWorld") or 1)~=1 then hide();stopCache();return end
 if not humanoid or humanoid.Health<=0 then hide();stopCache();return end
 local owner=Coordinator.Owner()
 if owner and owner.Name~="Stage1WallPromptGui" then hide();return end
 if panel and panel.Visible or player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") then hide();return end
 if phase=="Train" or legacy and IntroBalance.NeedsIntroTraining(player:GetAttribute("Level"),player:GetAttribute("Strength"),enteredWall or stage1Defeated) then
  local treadmill=treadmillFolder:FindFirstChild("Normal01")
  local zone=treadmill and treadmill:FindFirstChild("Area")
  if zone then show("Treadmill",zone.Position) else hide() end
 elseif stage1Defeated or phase=="Reward" then
  if trophy then show("Trophy"..trophy.Id,trophy.CFrame.Position) else hide() end
 else
  local map=workspace:FindFirstChild("GeneratedMap")
  local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage01")
  -- Authored boss arena stays Stage1.5 even when only one wall remains.
  local isWall=wallIndex<=wallCount
  local model=stage and stage:FindFirstChild(isWall and "Stage1."..wallIndex or "Stage1.5")
  local destination=model and (isWall and model:FindFirstChild("Wall")
   or model:FindFirstChild("EnemySpawn") or model:FindFirstChild("MiniBossSpawn") or model:FindFirstChild("Floor"))
  if destination then
   if isWall then wallPrompt:SetGuide(wallIndex,destination) end
   if wallPrompt:IsVisible() then hide() else show(isWall and ("Wall1."..wallIndex) or "Stage1Boss",destination.Position) end
  else hide() end
 end
end
local function trainingChanged()
 if player:GetAttribute("TutorialCompleted")==false and player:GetAttribute("IsTraining")==true then trained=true end
 refresh()
end
table.insert(connections,player:GetAttributeChangedSignal("IsTraining"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("Level"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialCompleted"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("OreTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("EggTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("PetMergeTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialResetSequence"):Connect(function()
 local sequence=player:GetAttribute("TutorialResetSequence")
 if sequence~=resetSequence then
  resetSequence=sequence trained=false enteredWall=false stage1Defeated=false wallIndex=1 trophy=nil clear() refresh()
 end
end))
for _,name in {"FirstBattleTutorialEligible","FirstBattleOutcome","FirstBattleStage1Defeated","OreTutorialCompleted","DumbbellEquipTutorialInitialCompleted"} do
 table.insert(connections,player:GetAttributeChangedSignal(name):Connect(refresh))
end
local elapsed=0
updateScheduler=function()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local original=(player:GetAttribute("TutorialCompleted")==false or FirstBattle.Active(player)) and (player:GetAttribute("CurrentWorld") or 1)==1
 local merge=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("OreTutorialTarget"))=="Vector3"
 local egg=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("EggTutorialTarget"))=="Vector3"
 local pet=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("PetMergeTutorialTarget"))=="Vector3"
 local enabled=(original or merge or egg or pet)
  and humanoid and humanoid.Health>0
 if not enabled then
  if tickConnection then tickConnection:Disconnect();tickConnection=nil end
  elapsed=0;return
 end
 if tickConnection then return end
 tickConnection=RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt
  if elapsed<UPDATE_INTERVAL then return end
  elapsed=0;refresh()
 end)
end
local function bindCharacter(character)
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
 task.spawn(function()
  local humanoid=character:WaitForChild("Humanoid",10)
  local root=character:WaitForChild("HumanoidRootPart",10)
  if player.Character~=character or not humanoid or not root then return end
  table.insert(characterConnections,humanoid.Died:Connect(refresh));refresh()
 end)
end
table.insert(connections,player.CharacterRemoving:Connect(function()
 hide();stopCache();if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
end))
table.insert(connections,player.CharacterAdded:Connect(bindCharacter))
table.insert(connections,player:GetAttributeChangedSignal("CurrentWorld"):Connect(refresh))
if player.Character then bindCharacter(player.Character) end
trainingChanged()
task.spawn(function()
 local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
 remoteConnection=remote.OnClientEvent:Connect(function(d)
  if typeof(d)~="table" then return end
  wallPrompt:Handle(d)
  if (d.Type=="EnemyDefeated" or d.Type=="StageCleared") and d.Stage==1 then stage1Defeated=true
  elseif d.Type=="Initialize" then
   trophy=nil wallIndex=1
   stage1Defeated=typeof(d.Cleared)=="table" and d.Cleared[1]==true
  elseif d.Type=="WallCleared" and d.MajorStage==1 then
   wallCleared()
   wallIndex=math.clamp(tonumber(d.Next) or (d.Index+1),1,wallCount+1)
  elseif d.Type=="WallInitialize" and typeof(d.State)=="table" and d.State.MajorStage==1 then
   wallIndex=math.clamp(tonumber(d.State.Current) or 1,1,wallCount+1)
   if not d.State.Skipped and typeof(d.State.Cleared)=="table" and d.State.Cleared[1]==true then wallCleared() end
  elseif d.Type=="TrophySpawn" and d.Stage==1 and typeof(d.Id)=="number" and typeof(d.CFrame)=="CFrame" then
   -- Owner-only event from TrophyRewardService. Never scan another player's Trophy.
   wallCleared()
   stage1Defeated=true
   trophy={Id=d.Id,CFrame=d.CFrame}
  elseif d.Type=="TrophyRemoved" and trophy and d.Id==trophy.Id then trophy=nil end
  refresh()
 end)
 wallPrompt:RequestUsing(function() remote:FireServer({Type="RequestState"}) end)
 remote:FireServer({Type="RequestState"})
end)
script.Destroying:Once(function()
 wallPrompt:Destroy()
 clear();stopCache()
 if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
 if remoteConnection then remoteConnection:Disconnect() end
 for _,connection in ipairs(connections) do connection:Disconnect() end
end)
