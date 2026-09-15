local treadmillFolder=workspace:WaitForChild("Treadmill")
-- Local-only floor navigation; progression and completion use existing server state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
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
local SPACING=3.5
local MAX_CHEVRONS=160
local UPDATE_INTERVAL=.2
local floorParts={}
local floorRefresh=0
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.IgnoreWater=true

local function clear()
 if route then route:Destroy();route=nil end
 table.clear(pool)
end
local function hide()
 if route then route:SetAttribute("Target","") end
 for _,pair in ipairs(pool) do for _,part in ipairs(pair) do part.Transparency=1 end end
end
local function refreshFloors()
 floorParts={workspace.Terrain}
 for _,part in ipairs(workspace:GetDescendants()) do
  if part:IsA("BasePart") and (part.Name=="Floor" or part.Name=="Baseplate"
   or part.Name=="Ground" or part.Name=="TrainingZone" or part.Name=="ConnectorFloor") then
   table.insert(floorParts,part)
  end
 end
 rayParams.FilterDescendantsInstances=floorParts
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
 route:SetAttribute("Target",key)
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
 if os.clock()-floorRefresh>2 then floorRefresh=os.clock();refreshFloors() end
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
  local castTop=math.max(root.Position.Y,target.Y)+10
  local hit=workspace:Raycast(Vector3.new(center.X,castTop,center.Z),Vector3.new(0,-256,0),rayParams)
  if hit and hit.Normal.Y>.5 then
   local normal=hit.Normal
   local forward=(direction-normal*direction:Dot(normal)).Unit
   local side=forward:Cross(normal).Unit
   local origin=hit.Position+normal*.055
   local tip=origin+forward*.65
   for armIndex,sign in ipairs({-1,1}) do
    local tail=origin-forward*.65+side*(sign*1.05)
    local length=(tip-tail).Magnitude
    pair[armIndex].Size=Vector3.new(.34,.045,length)
    pair[armIndex].CFrame=CFrame.lookAt((tip+tail)/2,tip,normal)
    pair[armIndex].Transparency=0
   end
  else
   pair[1].Transparency=1 pair[2].Transparency=1
  end
 end
 for index=count+1,#pool do pool[index][1].Transparency=1 pool[index][2].Transparency=1 end
 route:SetAttribute("ChevronCount",count)
 route:SetAttribute("Step1Completed",trained)
 route:SetAttribute("Step2Completed",enteredWall)
end
local function wallCleared()
 trained=true enteredWall=true
end
local function refresh()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if player:GetAttribute("TutorialCompleted")~=false then clear();return end
 if not humanoid or humanoid.Health<=0 then hide();return end
 -- Completion is server-owned. Level, boss defeat and Trophy are separate states.
 if (player:GetAttribute("Level") or 1)<2 then
  local treadmill=treadmillFolder:FindFirstChild("Tredmill01")
  local zone=treadmill and treadmill:FindFirstChild("TrainingZone")
  if zone then show("Treadmill",zone.Position) else hide() end
 elseif stage1Defeated then
  -- Stage advances before the owner-only TrophySpawn arrives. Wait for that
  -- event instead of jumping to a Stage2 target during the spawn delay.
  if trophy then show("Trophy"..trophy.Id,trophy.CFrame.Position) else hide() end
 else
  local map=workspace:FindFirstChild("GeneratedMap")
  local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage01")
  local model=stage and stage:FindFirstChild("Stage1."..wallIndex)
  local target=model and (wallIndex<=4 and model:FindFirstChild("Wall")
   or model:FindFirstChild("EnemySpawn") or model:FindFirstChild("MiniBossSpawn") or model:FindFirstChild("Floor"))
  if target then show(wallIndex<=4 and ("Wall1."..wallIndex) or "Stage1Boss",target.Position) else hide() end
 end
end
local function trainingChanged()
 if player:GetAttribute("TutorialCompleted")==false and player:GetAttribute("IsTraining")==true then trained=true end
 refresh()
end
table.insert(connections,player:GetAttributeChangedSignal("IsTraining"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("Level"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialCompleted"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("TutorialResetSequence"):Connect(function()
 local sequence=player:GetAttribute("TutorialResetSequence")
 if sequence~=resetSequence then
  resetSequence=sequence trained=false enteredWall=false stage1Defeated=false wallIndex=1 trophy=nil clear() refresh()
 end
end))
table.insert(connections,player.CharacterRemoving:Connect(hide))
table.insert(connections,player.CharacterAdded:Connect(function() task.defer(refresh) end))
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<UPDATE_INTERVAL then return end
 elapsed=0 refresh()
end))
trainingChanged()
task.spawn(function()
 local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
 remoteConnection=remote.OnClientEvent:Connect(function(d)
  if typeof(d)~="table" then return end
  if (d.Type=="EnemyDefeated" or d.Type=="StageCleared") and d.Stage==1 then stage1Defeated=true
  elseif d.Type=="Initialize" then
   trophy=nil wallIndex=1
   stage1Defeated=typeof(d.Cleared)=="table" and d.Cleared[1]==true
  elseif d.Type=="WallCleared" and d.MajorStage==1 then
   wallCleared()
   wallIndex=math.clamp(tonumber(d.Next) or (d.Index+1),1,5)
  elseif d.Type=="WallInitialize" and typeof(d.State)=="table" and d.State.MajorStage==1 then
   wallIndex=math.clamp(tonumber(d.State.Current) or 1,1,5)
   if not d.State.Skipped and typeof(d.State.Cleared)=="table" and d.State.Cleared[1]==true then wallCleared() end
  elseif d.Type=="TrophySpawn" and d.Stage==1 and typeof(d.Id)=="number" and typeof(d.CFrame)=="CFrame" then
   -- Owner-only event from TrophyRewardService. Never scan another player's Trophy.
   wallCleared()
   stage1Defeated=true
   trophy={Id=d.Id,CFrame=d.CFrame}
  elseif d.Type=="TrophyRemoved" and trophy and d.Id==trophy.Id then trophy=nil end
  refresh()
 end)
 remote:FireServer({Type="RequestState"})
end)
script.Destroying:Once(function()
 clear()
 if remoteConnection then remoteConnection:Disconnect() end
 for _,connection in ipairs(connections) do connection:Disconnect() end
end)

