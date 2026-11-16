-- Permanent World1 navigation. Independent of Character/HUD/tutorial readiness.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
-- These settings apply ONLY to the permanent route.
local SETTINGS={
 WidthMultiplier=3,
 Transparency=0.3, -- 70% opacity, NOT Transparency=0.7.
 WallClearance=1.5,
 RefreshInterval=0.2,
}
local renderer=require(RS:WaitForChild("Modules"):WaitForChild("FloorGuideRenderer")).new({
 Name="World1PermanentFloorGuide",Fixed=true,Owner=script,
 WidthMultiplier=SETTINGS.WidthMultiplier,Transparency=SETTINGS.Transparency,
})
local mapOwner,stageOwner,sectionOwner,floorOwner
local wallLocal,wallSize
local pending
local connections={}
local function resolve()
 local map=workspace:FindFirstChild("GeneratedMap")
 local lobby=map and map:FindFirstChild("TrainingArea")
 local spawn=lobby and lobby:FindFirstChild("SpawnLocation")
 local floor=lobby and lobby:FindFirstChild("Floor")
 local corridor=map and map:FindFirstChild("BattleCorridor")
 local stage=corridor and corridor:FindFirstChild("Stage01")
 local section=stage and stage:FindFirstChild("Stage1.1")
 if map~=mapOwner or stage~=stageOwner or section~=sectionOwner or floor~=floorOwner then
  mapOwner,stageOwner,sectionOwner,floorOwner=map,stage,section,floor
  wallLocal,wallSize=nil,nil
 end
 if not spawn or not spawn:IsA("BasePart") or not floor or not floor:IsA("BasePart")
  or not floor.Anchored or not floor.CanCollide or not stage or not section then return end
 local wall=section:FindFirstChild("Wall")
 if wall and wall:IsA("BasePart") then
  wallLocal=floor.CFrame:ToObjectSpace(wall.CFrame);wallSize=wall.Size
 end
 -- Keep the measured first-wall pose if its personal visual disappears.
 -- Use the structural lobby floor, not a Model pivot that can shift when a wall
 -- is removed. Drop it when its owning map/stage/section/floor is replaced.
 if not wallLocal then return end
 local cf=floor.CFrame*wallLocal
 local origin=spawn.Position
 local delta=Vector3.new(cf.X-origin.X,0,cf.Z-origin.Z)
 if delta.Magnitude<.01 then return end
 local direction=delta.Unit
 local localDirection=cf:VectorToObjectSpace(direction)
 local faceDistance=math.huge
 for _,axis in {"X","Y","Z"} do
  if math.abs(localDirection[axis])>1e-5 then
   faceDistance=math.min(faceDistance,wallSize[axis]/(2*math.abs(localDirection[axis])))
  end
 end
 local endpoint=cf.Position-direction*(faceDistance+SETTINGS.WallClearance)
 return origin,Vector3.new(endpoint.X,origin.Y,endpoint.Z)
end
local function refresh()
 if not renderer:IsAlive() then return end
 if (player:GetAttribute("CurrentWorld") or 1)~=1 then
  renderer:Hide();renderer:StopCache();return
 end
 local origin,endpoint=resolve()
 if not origin then renderer:Hide();return end
 renderer:Show("World1SpawnToFirstWall",origin,endpoint)
end
local function tick()
 pending=nil
 if not renderer:IsAlive() then return end
 refresh()
 pending=task.delay(SETTINGS.RefreshInterval,tick)
end
renderer.OnDestroy=function()
 if pending then task.cancel(pending);pending=nil end
 for _,connection in connections do connection:Disconnect() end
 table.clear(connections)
end
table.insert(connections,player:GetAttributeChangedSignal("CurrentWorld"):Connect(refresh))
table.insert(connections,script.Destroying:Once(function() renderer:Destroy() end))
-- Deferred work cannot hold up character loading, movement or another LocalScript.
pending=task.defer(tick)
