-- Permanent World1 navigation. Independent of Character/HUD/tutorial readiness.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local SETTINGS=require(RS:WaitForChild("Config"):WaitForChild("World1WalkwayConfig"))
local Geometry=require(RS.Modules:WaitForChild("World1WalkwayGeometry"))
local resolve=Geometry.new()
local renderer=require(RS.Modules:WaitForChild("FloorGuideRenderer")).new({
 Name="World1PermanentFloorGuide",Fixed=true,Owner=script,
 WidthMultiplier=SETTINGS.WidthMultiplier,Transparency=SETTINGS.Transparency,
 FlowSpeed=SETTINGS.ArrowSpeed,Spacing=SETTINGS.ArrowSpacing,SurfaceSampleStep=SETTINGS.SurfaceSampleStep,
})
local pending
local connections={}
local function refresh()
 if not renderer:IsAlive() then return end
 if (player:GetAttribute("CurrentWorld") or 1)~=1 then
  renderer:Hide();renderer:StopCache();return
 end
 local route=resolve()
 if not route then renderer:Hide();return end
 renderer:Show("World1SpawnToFirstWall",route.Origin,
  route.Origin+route.Direction*(route.WallDistance-SETTINGS.VisualWallClearance))
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
