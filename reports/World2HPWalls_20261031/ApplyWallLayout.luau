-- Scoped Edit migration from the four authored walls in the current World2 map.
-- Does not save/publish or rebuild a map. Run only after inspecting the live model.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
local corridor=workspace.World2Map.BattleCorridor
local config=require(game.ReplicatedStorage.Config.World2Config)
local format=require(game.ReplicatedStorage.Modules.NumberFormat)
local plans={}
-- Validate every Stage before changing any object.
for n=1,10 do
 local stage=assert(corridor:FindFirstChild(("Stage%02d"):format(n)))
 local count=#config.GetStageConfig(n).Walls
 local boss=assert(stage:FindFirstChild(("Stage%d.5"):format(n)))
 assert(boss:GetAttribute("SectionType")=="MiniBoss")
 assert(not stage:FindFirstChild(("Stage%d.Boss"):format(n)))
 local walls={}
 for i=1,4 do
  local wall=assert(stage:FindFirstChild(("Stage%d.%d"):format(n,i)))
  assert(wall:GetAttribute("SectionType")=="Wall" and wall.Wall:IsA("BasePart"))
  assert(wall.CombatZone and wall.Floor and wall.Wall.SurfaceGui.Health.Amount)
  walls[i]=wall
 end
 local first,last=walls[1]:GetPivot(),walls[4]:GetPivot()
 assert((last.Position-first.Position).Magnitude>0)
 plans[n]={Stage=stage,Count=count,Boss=boss,Walls=walls,First=first,Last=last}
end
local manifest={PlaceId=game.PlaceId,LoadedVersion=game.PlaceVersion,Stages={},Added=0}
for n,plan in ipairs(plans) do
 local stage,count,walls=plan.Stage,plan.Count,plan.Walls
 local row={Stage=stage:GetFullName(),Count=count,Spacing=(plan.Last.Position-plan.First.Position).Magnitude/(count-1),Walls={}}
 local bossBefore=plan.Boss:GetFullName()
 plan.Boss.Name=("Stage%d.Boss"):format(n)
 plan.Boss:SetAttribute("SubStageIndex",count+1)
 row.BossRename={Before=bossBefore,After=plan.Boss:GetFullName(),Pivot={plan.Boss:GetPivot():GetComponents()}}
 -- Preserve the original first and last physical models and their endpoints.
 local originalLast=walls[4]
 originalLast.Name=("Stage%d.%d"):format(n,count)
 walls[4]=nil
 walls[count]=originalLast
 for i=4,count-1 do
  local clone=walls[3]:Clone()
  clone.Name=("Stage%d.%d"):format(n,i)
  clone.Parent=stage
  walls[i]=clone
  manifest.Added+=1
 end
 for i=1,count do
  local model=walls[i]
  local before=model:GetPivot()
  local target=plan.First:Lerp(plan.Last,(i-1)/(count-1))
  model:PivotTo(target)
  model:SetAttribute("WallIndex",i);model:SetAttribute("SubStageIndex",i)
  model.CombatZone:SetAttribute("WallIndex",i)
  model.Wall:SetAttribute("WallIndex",i)
  model.Wall:SetAttribute("HPConfig","ReplicatedStorage.Config.World2Config")
  local hp=config.GetStageConfig(n).Walls[i]
  local surface=model.Wall.SurfaceGui
  surface.Stage.Text=("Stage %d-%d"):format(n,i)
  surface.Health.Amount.Text=string.format(require(game.ReplicatedStorage.Modules.Config).Stages.Health.format,format.Format(hp),format.Format(hp))
  row.Walls[i]={Path=model:GetFullName(),Added=i>=4 and i<count,HP=hp,
   Before={before:GetComponents()},After={model:GetPivot():GetComponents()},
   WallCFrame={model.Wall.CFrame:GetComponents()},WallSize={model.Wall.Size.X,model.Wall.Size.Y,model.Wall.Size.Z},
   Descendants=#model:GetDescendants(),Template=i>=4 and i<count and ("Stage%d.3"):format(n) or nil}
 end
 stage:SetAttribute("WallCount",count)
 table.insert(manifest.Stages,row)
 task.wait()
end
assert(manifest.Added==15)
return manifest
