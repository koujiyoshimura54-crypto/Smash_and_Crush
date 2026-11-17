-- Extracted from TutorialGuideClient: pooled two-Part white Neon chevrons,
-- exact authored walking surfaces, and an event-maintained spatial blocker cache.
-- Each owner has independent lifetime, settings and pool. No progression writes.
local M={}
local ArrowGeometry=require(script.Parent.FloorArrowGeometry)
local owners={}
function M.new(options)
 assert(type(options.Name)=="string","Floor guide needs an owner name")
 if owners[options.Name] then owners[options.Name]:Destroy() end
 local self={Controller=options.Owner};owners[options.Name]=self
 local destroyed=false
 local dimensions=ArrowGeometry.Dimensions(options.WidthMultiplier)
 local halfWidth,halfDepth=dimensions.HalfWidth,dimensions.HalfDepth
 local radius=options.Fixed and math.sqrt(halfWidth^2+halfDepth^2)+.34 or 1.5
 local margin=options.Fixed and radius or 2
local route
local pool={}
local flow,flowConnection
local flowSpeed=options.Fixed and tonumber(options.FlowSpeed) or 0
local flowing=flowSpeed and flowSpeed>0
local SPACING=3.5
local MAX_CHEVRONS=160
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
local function assign(object,key,value)
 if object[key]~=value then object[key]=value end
end
local function attribute(object,key,value)
 if object:GetAttribute(key)~=value then object:SetAttribute(key,value) end
end
local function isGuide(part)
 local parent=part.Parent
 return parent and parent:IsA("Folder") and
  (parent:GetAttribute("FloorGuideOwned")==true or
   (parent.Name=="TutorialFloorGuide" and parent:GetAttribute("ChevronCount")~=nil))
end
local function isCharacter(part)
 if not options.Fixed then return false end
 local ancestor=part.Parent
 while ancestor and ancestor~=workspace do
  if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then return true end
  ancestor=ancestor.Parent
 end
 return false
end
local function clear()
 flow=nil
 if route then route:Destroy();route=nil end
 table.clear(pool)
 lastRouteState=nil
end
local function hide()
 flow=nil
 if route then attribute(route,"Target","") end
 for _,pair in ipairs(pool) do for _,part in ipairs(pair) do assign(part,"Transparency",1) end end
 lastRouteState=nil
end
local function refreshFloors()
 table.clear(floorParts);table.clear(floorSet);table.clear(carpetSet)
 local function add(part)
  if part and part:IsA("BasePart") and (not options.Fixed or (part.Anchored and part.CanQuery)) then
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
    if options.Fixed then add(walkable and walkable:FindFirstChild("Floor")) end
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
  or isGuide(part) or isCharacter(part) then return end
 local record={};records[part]=record;reindex(part,record)
 -- Static OBBs are indexed once, independently of query/collision flags.
 -- Moving parts are read from their small live set on each route refresh.
 record.connection=part.Changed:Connect(function(property)
  if property=="Anchored" or ((property=="CFrame" or property=="Size") and part.Anchored) then dirty[part]=true end
  if floorSet[part] and (property=="CFrame" or property=="Size" or property=="CanQuery") then sceneRevision+=1;if options.Fixed then floorsDirty=true end end
  if property=="Name" or property=="Parent" or (floorSet[part] and property=="Anchored")
   or (options.Fixed and (property=="CanQuery" or property=="Anchored")) then floorsDirty=true end
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
  if part:IsA("BasePart") and not isGuide(part) then register(part);floorsDirty=true end
  if part:IsA("Model") or part:IsA("Folder") then floorsDirty=true end
 end))
 table.insert(cacheConnections,workspace.DescendantRemoving:Connect(function(part)
  if records[part] then release(part);floorsDirty=true end
  if part:IsA("Model") or part:IsA("Folder") then floorsDirty=true end
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
 local x0,x1=math.min(origin.X,target.X)-margin,math.max(origin.X,target.X)+margin
 local z0,z1=math.min(origin.Z,target.Z)-margin,math.max(origin.Z,target.Z)+margin
 local bottom=top-256
 local selected={}
 local function add(part,box)
  if selected[part] or not part.Parent or floorSet[part] or part.Transparency>=1 or part.LocalTransparencyModifier>=.99
   or isGuide(part) or isCharacter(part) then return end
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
  if not selected[part] and overlaps(box,point.X-radius,point.X+radius,point.Z-radius,point.Z+radius,point.Y,top) then
   selected[part]=true;table.insert(candidates,part)
  end
 end
 for x=math.floor((point.X-radius)/CELL),math.floor((point.X+radius)/CELL) do
  for z=math.floor((point.Z-radius)/CELL),math.floor((point.Z+radius)/CELL) do
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
-- Exact OBB intersection for the expanded arms, including non-query equipment.
local function boxesOverlap(cf,half,part)
 local aa={cf.RightVector,cf.UpVector,cf.LookVector}
 local bb={part.CFrame.RightVector,part.CFrame.UpVector,part.CFrame.LookVector}
 local ah={half.X,half.Y,half.Z};local bh={part.Size.X/2,part.Size.Y/2,part.Size.Z/2}
 local delta=part.Position-cf.Position
 local function separated(axis)
  if axis:Dot(axis)<1e-10 then return false end
  local a,b=0,0
  for i=1,3 do a+=ah[i]*math.abs(axis:Dot(aa[i]));b+=bh[i]*math.abs(axis:Dot(bb[i])) end
  return math.abs(delta:Dot(axis))>a+b
 end
 for i=1,3 do
  if separated(aa[i]) or separated(bb[i]) then return false end
  for j=1,3 do if separated(aa[i]:Cross(bb[j])) then return false end end
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
 local checkedDepth=halfDepth+(flowing and (options.SurfaceSampleStep or .25)/2 or 0)
 local tip=hit.Position+forward*checkedDepth
 for _,sign in {-1,1} do
  local tail=hit.Position-forward*checkedDepth+side*(sign*halfWidth)
  local edge=(tip-tail).Unit:Cross(normal)*.17
  if options.Fixed then
   -- Cover the real expanded arms at <=0.25 studs, including both outer edges.
   local steps=math.ceil((tip-tail).Magnitude/.25)
   for i=0,steps do
    local point=tail:Lerp(tip,i/steps)
    points[#points+1]=point;points[#points+1]=point+edge;points[#points+1]=point-edge
   end
   local center=(tip+tail)/2
   local height=math.max(.045,top-hit.Position.Y-.01)
   local cf=CFrame.lookAt(Vector3.new(center.X,hit.Position.Y+.01+height/2,center.Z),
    Vector3.new(tip.X,hit.Position.Y+.01+height/2,tip.Z))
   for _,part in candidates do
    if boxesOverlap(cf,Vector3.new(.17,height/2,(tip-tail).Magnitude/2),part) then return false end
   end
  else
   for _,point in {tip,tail,(tip+tail)/2} do
    points[#points+1]=point+edge;points[#points+1]=point-edge
   end
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
  for _,part in (options.Fixed and {} or candidates) do
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
-- Only the permanent owner opts into flow. Surface/obstacle sampling happens
-- on scene changes, never in the RenderStepped callback or once per frame.
local function animate()
 local data=flow
 if not data or destroyed then return end
 local phase=(os.clock()*flowSpeed)%data.span
 for index=1,data.count do
  local distance=data.first+((index-1)*data.spacing+phase)%data.span
  local sampleIndex=math.min(#data.samples-1,math.floor(distance/data.step)+1)
  local a,b=data.samples[sampleIndex],data.samples[sampleIndex+1]
  local pair=pool[index]
  if a and b and a.valid and b.valid then
   local fraction=math.clamp((distance-a.distance)/(b.distance-a.distance),0,1)
   local normal=a.normal:Lerp(b.normal,fraction).Unit
   local forward=(data.direction-normal*data.direction:Dot(normal)).Unit
   local side=forward:Cross(normal).Unit
   local point=data.start+data.direction*distance
   -- Max keeps each entire arm above a carpet transition instead of intersecting it.
   local center=Vector3.new(point.X,math.max(a.height,b.height),point.Z)+normal*.055
   local tip=center+forward*halfDepth
   for armIndex,sign in {-1,1} do
    local tail=center-forward*halfDepth+side*(sign*halfWidth)
    assign(pair[armIndex],"Size",Vector3.new(.34,.045,(tip-tail).Magnitude))
    assign(pair[armIndex],"CFrame",CFrame.lookAt((tip+tail)/2,tip,normal))
    assign(pair[armIndex],"Transparency",options.Transparency or 0)
   end
  else
   assign(pair[1],"Transparency",1);assign(pair[2],"Transparency",1)
  end
 end
end
local function buildFlow(start,target,distance,castTop)
 local direction=Vector3.new(target.X-start.X,0,target.Z-start.Z).Unit
 local step=options.SurfaceSampleStep or .25
 local samples={}
 for i=0,math.ceil(distance/step) do
  local d=math.min(distance,i*step)
  local point=start+direction*d
  local hit=workspace:Raycast(Vector3.new(point.X,castTop,point.Z),Vector3.new(0,-256,0),rayParams)
  local supported,height=floorOnly(hit,direction,castTop)
  samples[#samples+1]={distance=d,valid=supported,height=height,normal=hit and hit.Normal}
 end
 local first=halfDepth+.34
 local span=distance-2*first
 local count=math.max(1,math.min(MAX_CHEVRONS,math.floor(span/(options.Spacing or SPACING))))
 for index=1,count do
  if not pool[index] then pool[index]={arm(index,"Left"),arm(index,"Right")} end
 end
 for index=count+1,#pool do assign(pool[index][1],"Transparency",1);assign(pool[index][2],"Transparency",1) end
 flow={start=start,direction=direction,samples=samples,step=step,first=first,span=span,count=count,spacing=span/count}
 attribute(route,"ChevronCount",count)
 attribute(route,"FlowSpeed",flowSpeed)
 attribute(route,"FlowSpan",span)
 attribute(route,"FlowSpacing",span/count)
 attribute(route,"Origin",start);attribute(route,"Destination",target)
 attribute(route,"RenderRevision",(route:GetAttribute("RenderRevision") or 0)+1)
 animate()
 if not flowConnection then flowConnection=game:GetService("RunService").RenderStepped:Connect(animate) end
end
local function show(key,start,target)
 if destroyed then return end
 if not route then
  route=Instance.new("Folder");route.Name=options.Name
  route:SetAttribute("FloorGuideOwned",true);route.Parent=workspace
 end
 attribute(route,"Target",key)
 local nodes={start}
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
 local castTop=math.max(start.Y,target.Y)+10
 prepareCandidates(start,target,castTop)
 local state={key=key,origin=start,target=target,revision=sceneRevision,top=castTop}
 if lastRouteState and lastRouteState.key==key and lastRouteState.origin==state.origin
  and lastRouteState.target==target and lastRouteState.revision==sceneRevision and lastRouteState.top==castTop then return end
 lastRouteState=state
 if flowing then buildFlow(start,target,distance,castTop);return end
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
   local tip=origin+forward*halfDepth
   for armIndex,sign in ipairs({-1,1}) do
    local tail=origin-forward*halfDepth+side*(sign*halfWidth)
    local length=(tip-tail).Magnitude
    assign(pair[armIndex],"Size",Vector3.new(.34,.045,length))
    assign(pair[armIndex],"CFrame",CFrame.lookAt((tip+tail)/2,tip,normal))
    assign(pair[armIndex],"Transparency",options.Transparency or 0)
   end
  else
   assign(pair[1],"Transparency",1);assign(pair[2],"Transparency",1)
  end
 end
 for index=count+1,#pool do assign(pool[index][1],"Transparency",1);assign(pool[index][2],"Transparency",1) end
 attribute(route,"ChevronCount",count)
 attribute(route,"Origin",start)
 attribute(route,"Destination",target)
 attribute(route,"RenderRevision",(route:GetAttribute("RenderRevision") or 0)+1)
end

 function self:Show(key,start,target) show(key,start,target) end
 function self:Hide() hide() end
 function self:Clear() clear() end
 function self:StopCache() stopCache() end
 function self:GetFolder() return route end
 function self:IsAlive() return not destroyed end
 function self:Destroy()
  if destroyed then return end
  destroyed=true;clear();stopCache()
  if flowConnection then flowConnection:Disconnect();flowConnection=nil end
  if owners[options.Name]==self then owners[options.Name]=nil end
  if self.OnDestroy then self.OnDestroy() end
 end
 -- Cleanup an owned folder left by a previous module/script version only.
 for _,previous in workspace:GetChildren() do
  if previous:IsA("Folder") and previous.Name==options.Name and
   (previous:GetAttribute("FloorGuideOwned")==true or previous:GetAttribute("ChevronCount")~=nil) then previous:Destroy() end
 end
 return self
end
-- Run in the ModuleScript's own lifetime: with deferred signals a LocalScript's
-- Destroying callback cannot reliably run after that same script is removed.
-- One small owner check, independent of both rendering loops and character life.
task.spawn(function()
 while script:IsDescendantOf(game) do
  task.wait(.5)
  for _,owner in owners do
   local controller=owner.Controller
   if controller and (not controller:IsDescendantOf(game) or not controller.Enabled) then owner:Destroy() end
  end
 end
end)
return M
