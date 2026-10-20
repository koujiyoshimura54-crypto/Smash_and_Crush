"""Build the single tutorial Source change from actual CurrentCloud, never old src."""
import hashlib,json,sys
from pathlib import Path
from rbxl_rows import Editor,string
ROOT=Path(__file__).resolve().parents[1]
PLACE=Path(r'C:\Users\kouji\MergeToForge_CurrentCloud.rbxl')
FULL='StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient'

CACHE=r'''local floorParts={}
local floorSet={}
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
 table.clear(floorParts);table.clear(floorSet)
 local function add(part)
  if part and part:IsA("BasePart") then floorSet[part]=true;table.insert(floorParts,part) end
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
'''

def build(raw):
 e=Editor(raw);r=e.find(FULL);original=string(e.get(r,'Source'),0)[0].decode();s=original.replace('\r\n','\n')
 start=s.index('local floorParts={}');end=s.index('-- Intersect a vertical segment',start)
 s=s[:start]+CACHE+s[end:]
 s=s.replace('local pool={}\n','''local pool={}
-- Remove only a prior local guide with this script's ownership metadata.
-- A restarted LocalScript must not leave a second guide that blocks itself.
for _,previous in workspace:GetChildren() do
 if previous:IsA("Folder") and previous.Name=="TutorialFloorGuide"
  and previous:GetAttribute("ChevronCount")~=nil then previous:Destroy() end
end
''',1)
 start=s.index(' local candidates={}\n for _,part in blockers do',s.index('local function floorOnly'))
 end=s.index(' local points={hit.Position}',start)
 s=s[:start]+' local candidates=nearCandidates(hit.Position,top)\n'+s[end:]
 old=' if os.clock()-floorRefresh>2 then floorRefresh=os.clock();refreshFloors() end'
 assert s.count(old)==1
 s=s.replace(old,''' local castTop=math.max(root.Position.Y,target.Y)+10
 prepareCandidates(root.Position,target,castTop)
 local state={key=key,origin=root.Position,target=target,revision=sceneRevision,top=castTop}
 if lastRouteState and lastRouteState.key==key and lastRouteState.origin==state.origin
  and lastRouteState.target==target and lastRouteState.revision==sceneRevision and lastRouteState.top==castTop then return end
 lastRouteState=state''')
 s=s.replace('  local castTop=math.max(root.Position.Y,target.Y)+10\n','')
 s=s.replace(' route:SetAttribute("Target",key)',' attribute(route,"Target",key)')
 for key in ['ChevronCount','Step1Completed','Step2Completed']:
  s=s.replace(f' route:SetAttribute("{key}",',f' attribute(route,"{key}",')
 s=s.replace('    pair[armIndex].Size=Vector3.new(.34,.045,length)','    assign(pair[armIndex],"Size",Vector3.new(.34,.045,length))')
 s=s.replace('    pair[armIndex].CFrame=CFrame.lookAt((tip+tail)/2,tip,normal)','    assign(pair[armIndex],"CFrame",CFrame.lookAt((tip+tail)/2,tip,normal))')
 s=s.replace('    pair[armIndex].Transparency=0','    assign(pair[armIndex],"Transparency",0)')
 s=s.replace('   pair[1].Transparency=1 pair[2].Transparency=1','   assign(pair[1],"Transparency",1);assign(pair[2],"Transparency",1)')
 s=s.replace(' for index=count+1,#pool do pool[index][1].Transparency=1 pool[index][2].Transparency=1 end',' for index=count+1,#pool do assign(pool[index][1],"Transparency",1);assign(pool[index][2],"Transparency",1) end')
 old=''' if player:GetAttribute("TutorialCompleted")~=false then clear();return end
 if not humanoid or humanoid.Health<=0 then hide();return end'''
 new=''' if updateScheduler then updateScheduler() end
 if player:GetAttribute("TutorialCompleted")~=false then clear();stopCache();return end
 if (player:GetAttribute("CurrentWorld") or 1)~=1 then hide();stopCache();return end
 if not humanoid or humanoid.Health<=0 then hide();stopCache();return end'''
 assert old in s;s=s.replace(old,new)
 old='''table.insert(connections,player.CharacterRemoving:Connect(hide))
table.insert(connections,player.CharacterAdded:Connect(function() task.defer(refresh) end))
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<UPDATE_INTERVAL then return end
 elapsed=0 refresh()
end))'''
 new='''local elapsed=0
updateScheduler=function()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local enabled=player:GetAttribute("TutorialCompleted")==false and (player:GetAttribute("CurrentWorld") or 1)==1
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
if player.Character then bindCharacter(player.Character) end'''
 assert old in s;s=s.replace(old,new)
 s=s.replace('script.Destroying:Once(function()\n clear()','script.Destroying:Once(function()\n clear();stopCache()\n if tickConnection then tickConnection:Disconnect();tickConnection=nil end\n for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)')
 assert s[s.index('local function wallCleared()'):s.index('local function refresh()')]==original.replace('\r\n','\n')[original.replace('\r\n','\n').index('local function wallCleared()'):original.replace('\r\n','\n').index('local function refresh()')]
 return original,s

if __name__=='__main__':
 original,source=build(PLACE.read_bytes())
 path=ROOT/'src/StarterPlayer/StarterPlayerScripts/Tutorial/TutorialGuideClient.client.luau'
 path.write_bytes(source.encode())
 print(json.dumps({'inputSourceSha256':hashlib.sha256(original.encode()).hexdigest(),'outputSourceSha256':hashlib.sha256(source.encode()).hexdigest(),'lines':len(source.splitlines())}))
