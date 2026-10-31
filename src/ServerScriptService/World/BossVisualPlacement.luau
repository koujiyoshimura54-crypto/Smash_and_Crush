-- World2 geometry adapter; shared World services own combat and progression.
local SS=game:GetService("ServerStorage")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config.World2BossVisualConfig)
local Balance=require(RS.Config.World2BossConfig)
local M={}
local function bounds(model)
 local low=Vector3.new(math.huge,math.huge,math.huge)
 local high=-low
 for _,part in model:GetDescendants() do
  if part:IsA("BasePart") and part.Transparency<1 and part.Name~="HumanoidRootPart" and part.Name~="DisplayRoot" then
   local mesh=part:FindFirstChildOfClass("SpecialMesh")
   local meshSize=mesh and Config.FileMeshSizes[mesh.MeshId]
   local size=meshSize and meshSize*mesh.Scale or part.Size
   local offset=meshSize and mesh.Offset or Vector3.zero
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    local p=part.CFrame:PointToWorldSpace(offset+size*Vector3.new(x,y,z)/2)
    low=low:Min(p);high=high:Max(p)
   end end end
  end
 end
 assert(low.Y<math.huge,"SCP visual has no visible geometry")
 return low,high
end
M.GetVisibleBounds=bounds
function M.Build(map,stageNumber,generation)
 local entry=assert(Config.Stages[stageNumber],"Unapproved World2 boss stage")
 local stage=assert(map.BattleCorridor:FindFirstChild(("Stage%02d"):format(stageNumber)))
 local area=assert(stage:FindFirstChild(("Stage%d.Boss"):format(stageNumber)))
 local marker=assert(area:FindFirstChild("EnemySpawn"))
 local floor=assert(area:FindFirstChild("Floor"))
 local template=assert(SS.EnemyTemplates.World2SCPDisplays:FindFirstChild(entry.Template))
 -- Keep authored placeholder models intact, but out of the live boss area.
 local placeholder=area:FindFirstChild(("EnemyPlaceholder_Stage%02d"):format(stageNumber))
 if placeholder then
  local archive=SS.World2SCPAssets:FindFirstChild("ReservedPlaceholders")
  if not archive then archive=Instance.new("Folder");archive.Name="ReservedPlaceholders";archive.Parent=SS.World2SCPAssets end
  placeholder.Parent=archive
 end
 local enemy=Instance.new("Model")
 enemy.Name=("Stage%02d_Enemy"):format(stageNumber)
 enemy:SetAttribute("ManagedBy","EnemyManager")
 enemy:SetAttribute("WorldId",2)
 enemy:SetAttribute("StageNumber",stageNumber)
 enemy:SetAttribute("SCPNumber",entry.SCP)
 enemy:SetAttribute("SpawnGeneration",generation or 1)
 enemy:SetAttribute("BossMaxHP",Balance.GetMaxHP(stageNumber))
 enemy:SetAttribute("MaxGauge",Balance.GetMaxHP(stageNumber))
 enemy:SetAttribute("RecommendedLevel",Balance.GetRecommendedLevel(stageNumber))
 enemy:SetAttribute("RequiredStrength",Balance.GetRequiredStrength(stageNumber))
 enemy:SetAttribute("RewardStatus",Config.RewardStatus)
 local root=Instance.new("Part")
 root.Name="HumanoidRootPart";root.Size=Vector3.one
 root.Transparency=1;root.Anchored=true
 root.CanCollide=false;root.CanTouch=false;root.CanQuery=false
 root.CFrame=marker.CFrame;root.Parent=enemy;enemy.PrimaryPart=root
 local visual=template:Clone()
 visual.Name=entry.SCP
 -- Absolute from the unmodified template, never from a previous live clone.
 visual:ScaleTo(template:GetScale()*entry.VisualScale)
 enemy:SetAttribute("VisualScale",entry.VisualScale)
 -- Audited display templates contain no executable scripts. Fail closed if one is added.
 for _,x in visual:GetDescendants() do
  if x:IsA("BaseScript") then x.Disabled=true
  elseif x:IsA("BasePart") then
   x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Massless=true
   -- Humanoid initialization may restore torso collisions after parenting.
   -- Event-driven guard affects only this cosmetic clone, never the collider.
   x:GetPropertyChangedSignal("CanCollide"):Connect(function()
    if x.CanCollide then x.CanCollide=false end
   end)
  elseif x:IsA("Sound") then x.Playing=false;x.PlayOnRemove=false
  elseif x:IsA("Humanoid") then x.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;x.EvaluateStateMachine=false
  end
 end
 visual:PivotTo(marker.CFrame*CFrame.Angles(0,math.rad(entry.FacingYaw or 0),0))
 local low,high=bounds(visual)
 local floorTop=floor.Position.Y+floor.Size.Y/2
 local center=(low+high)/2
 visual:PivotTo(visual:GetPivot()+Vector3.new(marker.Position.X-center.X,floorTop-low.Y,marker.Position.Z-center.Z))
 visual.Parent=enemy
 low,high=bounds(visual)
 enemy:SetAttribute("BossDisplayBottomY",low.Y)
 enemy:SetAttribute("BossDisplayBaseY",low.Y)
 enemy:SetAttribute("BossDisplayTopY",high.Y)
 enemy:SetAttribute("BossDisplayHeight",high.Y-low.Y)
 local extent=Instance.new("Part")
 extent.Name="BossVisualBounds";extent.Size=high-low;extent.CFrame=CFrame.new((low+high)/2)
 extent.Transparency=1;extent.Anchored=true;extent.CanCollide=false;extent.CanTouch=false;extent.CanQuery=false;extent.Parent=enemy
 local collider=Instance.new("Part")
 collider.Name="MiniBossCollider"
 local displaySize=high-low
 collider.Size=entry.ColliderSize or displaySize*entry.BodyRatio
 local bodyCenter=(low+high)/2+(entry.ColliderOffset or displaySize*(entry.BodyOffset or Vector3.zero))
 collider.CFrame=CFrame.new(bodyCenter)
 collider.Transparency=1;collider.Anchored=true
 collider.CanCollide=false;collider.CanTouch=false;collider.CanQuery=false
 collider.Parent=enemy
 local zone=Instance.new("Part")
 zone.Name="CombatZone";zone.Size=Vector3.new(collider.Size.X+10,math.max(14,collider.Size.Y),collider.Size.Z+10)
 zone.CFrame=CFrame.new(collider.Position.X,floorTop+zone.Size.Y/2,collider.Position.Z)
 zone.Transparency=1;zone.Anchored=true;zone.CanCollide=false;zone.CanTouch=true;zone.CanQuery=false;zone.Parent=enemy
 -- Keep the complete rendered footprint inside the current floor. Markers and
 -- map geometry stay authored; only this personal actor's home is fitted.
 local mainFloor=stage:FindFirstChild("Floor")
 local minX=mainFloor.Position.X-mainFloor.Size.X/2+.25
 local maxX=mainFloor.Position.X+mainFloor.Size.X/2-.25
 local minZ=mainFloor.Position.Z-mainFloor.Size.Z/2+.25
 local maxZ=mainFloor.Position.Z+mainFloor.Size.Z/2-.25
 local wall=stage:FindFirstChild(("Stage%d.%d"):format(stageNumber,require(RS.Config.World2Config).GetWallCount(stageNumber)))
 wall=wall and wall:FindFirstChild("Wall")
 if wall and wall:IsA("BasePart") then minZ=math.max(minZ,wall.Position.Z+wall.Size.Z/2+.25) end
 assert(high.X-low.X<=maxX-minX and high.Z-low.Z<=maxZ-minZ,"Boss cannot fit arena")
 local shift=Vector3.new(math.clamp(0,minX-low.X,maxX-high.X),0,math.clamp(0,minZ-low.Z,maxZ-high.Z))
 enemy:PivotTo(enemy:GetPivot()+shift)
 require(RS.Modules.World2BossRig).Prepare(visual,stageNumber)
 return enemy
end
return M
