-- World2 visual adapter for EnemyManager. No combat, progression or reward loop.
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
   for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
    local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
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
 local area=assert(stage:FindFirstChild(("Stage%d.5"):format(stageNumber)))
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
 visual:PivotTo(marker.CFrame)
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
 local collider=Instance.new("Part")
 collider.Name="MiniBossCollider"
 collider.Size=high-low
 collider.CFrame=CFrame.new((low+high)/2)
 collider.Transparency=1;collider.Anchored=true
 collider.CanCollide=false;collider.CanTouch=false;collider.CanQuery=false
 collider.Parent=enemy
 local zone=Instance.new("Part")
 zone.Name="CombatZone";zone.Size=Vector3.new(collider.Size.X+10,math.max(14,collider.Size.Y),collider.Size.Z+10)
 zone.CFrame=CFrame.new(collider.Position.X,floorTop+zone.Size.Y/2,collider.Position.Z)
 zone.Transparency=1;zone.Anchored=true;zone.CanCollide=false;zone.CanTouch=true;zone.CanQuery=false;zone.Parent=enemy
 return enemy
end
return M
