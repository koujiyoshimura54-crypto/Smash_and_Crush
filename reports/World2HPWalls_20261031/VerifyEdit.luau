-- Final live Edit verification. Requires the in-session baseline captured before editing.
assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
assert(not _G.HPWallsRunning,"Native Play still active")
local baseline=assert(_G.World2WallsBaseline)
local changes=assert(_G.World2WallsImplementation)
local result={PlaceId=game.PlaceId,LoadedVersion=game.PlaceVersion,Sources={},Stages={},UnchangedGeometry=0}
local count=0
for _,obj in game:GetDescendants() do
 if obj:IsA("LuaSourceContainer") then
  local path=obj:GetFullName();local original=assert(baseline.sources[path],"Unexpected Source "..path)
  local expected=changes[path] and changes[path].after or original.source
  assert(obj.Source==expected,"Final Source mismatch "..path)
  assert((not obj:IsA("BaseScript")) or obj.Disabled==(original.disabled==true),"Enabled flag changed "..path)
  result.Sources[path]={Changed=changes[path]~=nil,Source=obj.Source}
  count+=1
 end
end
result.SourceCount=count
local cfg=require(game.ReplicatedStorage.Config.World2Config)
local boss=require(game.ReplicatedStorage.Config.World2BossConfig)
local total=0
local byPath,used={},{}
for _,obj in workspace.World2Map.BattleCorridor:GetDescendants() do
 local path=obj:GetFullName();byPath[path]=byPath[path] or {};table.insert(byPath[path],obj)
end
for n,oldStage in ipairs(baseline.geometry) do
 local stage=workspace.World2Map.BattleCorridor[("Stage%02d"):format(n)]
 local entry=cfg.Stages[n];local row={BossHP=boss.GetMaxHP(n),RequiredStrength=boss.GetRequiredStrength(n),Count=#entry.Walls,Walls={}}
 assert(row.RequiredStrength==row.BossHP/5)
 local seen={};local sectionCount=0
 for _,child in stage:GetChildren() do
  assert(not seen[child.Name],"Duplicate Stage child name");seen[child.Name]=true
  if child:GetAttribute("SectionType")=="Wall" then sectionCount+=1 end
 end
 assert(sectionCount==row.Count)
 local first,last
 for i,hp in ipairs(entry.Walls) do
  local model=assert(stage:FindFirstChild(("Stage%d.%d"):format(n,i)))
  assert(model:GetAttribute("SectionType")=="Wall" and model:GetAttribute("WallIndex")==i and model:GetAttribute("SubStageIndex")==i)
  assert(model.Wall:GetAttribute("WallIndex")==i and model.CombatZone:GetAttribute("WallIndex")==i)
  assert(model.Wall:GetAttribute("HPConfig")=="ReplicatedStorage.Config.World2Config")
  assert(model.Wall.CanCollide and not model.Floor.CanCollide and not model.CombatZone.CanCollide)
  assert(model.Wall.Size==Vector3.new(98.33999633789062,27,1.2000000476837158))
  first=first or model.Wall.Position;last=model.Wall.Position
  row.Walls[i]={HP=hp,Position={model.Wall.Position.X,model.Wall.Position.Y,model.Wall.Position.Z},Label=model.Wall.SurfaceGui.Health.Amount.Text}
  total+=1
 end
 local spacing=(last-first).Magnitude/(row.Count-1)
 for i=2,row.Count do assert(math.abs((Vector3.new(table.unpack(row.Walls[i].Position))-Vector3.new(table.unpack(row.Walls[i-1].Position))).Magnitude-spacing)<.001) end
 row.Spacing=spacing;row.BodyGap=spacing-1.2000000476837158
 local bossSection=assert(stage:FindFirstChild(("Stage%d.Boss"):format(n)))
 assert(bossSection:GetAttribute("SubStageIndex")==row.Count+1 and bossSection:GetAttribute("SectionType")=="MiniBoss")
 -- Stage floor, Boss/Trophy markers, exterior/decoration remain physically identical.
 for _,old in ipairs(oldStage.objects) do
  local prefix=oldStage.path..".Stage"..n.."."
  local suffix=old.path:sub(#prefix+1)
  local wallIndex=old.path:sub(1,#prefix)==prefix and tonumber(suffix:match("^(%d+)")) or nil
  if wallIndex and wallIndex<=4 then continue end
  local path=old.path
  if old.path:sub(1,#prefix+1)==prefix.."5" then path=oldStage.path..".Stage"..n..".Boss"..old.path:sub(#prefix+2) end
  local current
  -- Authored decoration may legitimately repeat sibling names. Match the full multiset.
  for _,candidate in byPath[path] or {} do
   if used[candidate] or candidate.ClassName~=old.class then continue end
   if old.pivot and candidate:GetPivot()~=CFrame.new(table.unpack(old.pivot)) then continue end
   if old.size and candidate:IsA("BasePart") and candidate.Size~=Vector3.new(table.unpack(old.size)) then continue end
   if old.collide~=nil and candidate.CanCollide~=old.collide then continue end
   if old.transparency~=nil and candidate.Transparency~=old.transparency then continue end
   current=candidate;break
  end
  assert(current,"Unrelated geometry changed: "..path);used[current]=true
  result.UnchangedGeometry+=1
 end
 result.Stages[n]=row
end
assert(total==55)
result.TotalWalls=total
local cam=baseline.camera;local current=workspace.CurrentCamera
assert(current.CFrame==CFrame.new(table.unpack(cam.cf)) and current.Focus==CFrame.new(table.unpack(cam.focus)))
assert(current.FieldOfView==cam.fov and current.CameraType.Name==cam.type and game.StarterGui.ShowDevelopmentGui==cam.showGui)
result.CameraPreserved=true;result.TemporaryFixtures=0;result.Saved=false;result.Published=false
return result
