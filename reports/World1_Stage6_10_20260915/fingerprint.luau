local function hash(s)
 local h=5381
 for i=1,#s do h=(h*33+s:byte(i))%4294967296 end
 return string.format('%08x',h)
end
local function canonical(v)
 if typeof(v)=='table' then
  local keys={} for k in pairs(v) do table.insert(keys,k) end
  table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
  local out={} for _,k in keys do table.insert(out,tostring(k)..'='..canonical(v[k])) end
  return '{'..table.concat(out,';')..'}'
 elseif typeof(v)=='CFrame' then return canonical({v:GetComponents()})
 elseif typeof(v)=='Instance' then return v:GetFullName()
 else return typeof(v)..':'..tostring(v) end
end
local function tree(root,ignoreWallHP)
 local rows={} local list={root};for _,d in root:GetDescendants() do table.insert(list,d) end
 for _,d in list do
  local a=d:GetAttributes()
  if ignoreWallHP and d:GetFullName():match('BattleCorridor.Stage0[6-9]%.') or ignoreWallHP and d:GetFullName():match('BattleCorridor.Stage10%.') then a.MaxGauge=nil end
  local x={name=d:GetFullName(),class=d.ClassName,attributes=a}
  if d:IsA('BasePart') then
   for _,p in {'Size','CFrame','Anchored','CanCollide','CanTouch','CanQuery','Transparency','Color','Material','CollisionGroup'} do x[p]=d[p] end
   if d:IsA('MeshPart') then x.MeshId=d.MeshId;x.TextureID=d.TextureID end
  elseif d:IsA('Model') then x.pivot=d:GetPivot();x.scale=d:GetScale()
  elseif d:IsA('LuaSourceContainer') then x.source=d.Source
  elseif d:IsA('ValueBase') then x.value=d.Value
  end
  table.insert(rows,canonical(x))
 end
 table.sort(rows);return {count=#rows,hash=hash(table.concat(rows,'\n'))}
end
local result={scopes={},scripts={}}
result.scopes.World2Map=tree(workspace.World2Map)
result.scopes.World2Gate=tree(workspace.World2Gate)
for _,p in {'World2Config','World2BossConfig','WorldGateConfig','LevelRequirements'} do result.scopes[p]=tree(game.ReplicatedStorage.Config[p]) end
result.scopes.World2WallConfig=tree(game.ServerScriptService.Config.World2WallConfig)
result.scopes.MapExceptLateWallHP=tree(workspace.GeneratedMap,true)
for i=1,5 do
 result.scopes['Stage'..i]=tree(workspace.GeneratedMap.BattleCorridor[('Stage%02d'):format(i)])
 result.scopes['Template'..i]=tree(game.ServerStorage.EnemyTemplates[('Stage%02dBoss'):format(i)])
end
for i=6,10 do
 for _,m in game.ServerStorage.EnemyTemplates[('Stage%02dBoss'):format(i)]:GetChildren() do
  if m:IsA('Model') then result.scopes['Visual'..i]=tree(m) end
 end
end
result.scopes.Stage6Collider=tree(game.ServerStorage.EnemyTemplates.Stage06Boss.CollisionReference)
for _,d in game:GetDescendants() do if d:IsA('LuaSourceContainer') then result.scripts[d:GetFullName()]=hash(d.Source) end end
local w2=require(game.ReplicatedStorage.Config.World2BossConfig)
local walls=require(game.ServerScriptService.Config.World2WallConfig)
result.world2HP={};for i=1,10 do local row={boss=w2.GetMaxHP(i),walls={}} for j=1,4 do row.walls[j]=walls.GetMaxHP(i,j) end result.world2HP[i]=row end
local base=require(game.ReplicatedStorage.Config.World1BossConfig);local w=require(game.ServerScriptService.World.Stage1WallManager)
result.earlyBalance={};for i=1,5 do result.earlyBalance[i]={required=base.GetRequiredStrength(i),level=base.GetRecommendedLevel(i),boss=base.GetMaxHP(i),walls=w.Config[i].Walls} end
return game.HttpService:JSONEncode(result)
