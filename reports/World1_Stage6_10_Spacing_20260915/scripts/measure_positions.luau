local H=game:GetService("HttpService")
local function vec(v)return {v.X,v.Y,v.Z}end
local function bounds(cf,size)
 local lo=Vector3.new(math.huge,math.huge,math.huge) local hi=-lo
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do local p=cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2) lo=lo:Min(p) hi=hi:Max(p) end end end
 return lo,hi
end
local function part(p)
 local lo,hi=bounds(p.CFrame,p.Size)
 return {Path=p:GetFullName(),Position=vec(p.Position),CFrame={p.CFrame:GetComponents()},Size=vec(p.Size),Min=vec(lo),Max=vec(hi),CanCollide=p.CanCollide}
end
local o={}
for n=6,10 do
 local stage=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(n)]
 local bossArea=stage[("Stage%d.5"):format(n)]
 local floor=stage.Floor local w=stage[("Stage%d.4"):format(n)].Wall
 local enemy=workspace.Enemies[("Stage%02d_Enemy"):format(n)]
 local visual for _,c in enemy:GetChildren() do if c:IsA("Model") then visual=c break end end
 local cf,size=visual:GetBoundingBox() local lo,hi=bounds(cf,size)
 local r={Stage=n,Wall=part(w),Spawn=part(bossArea.EnemySpawn),Floor=part(floor),BossAreaFloor=part(bossArea.Floor),Root=part(enemy.HumanoidRootPart),Collider=part(enemy.MiniBossCollider),Zone=part(enemy.CombatZone),Reference=part(game.ServerStorage.EnemyTemplates[("Stage%02dBoss"):format(n)].CollisionReference),Visual={Name=visual.Name,Scale=visual:GetScale(),CFrame={cf:GetComponents()},Size=vec(size),Min=vec(lo),Max=vec(hi)}}
 r.ColliderGap=r.Collider.Min[3]-r.Wall.Max[3] r.VisualGap=r.Visual.Min[3]-r.Wall.Max[3]
 r.RearSpace=r.Floor.Max[3]-math.max(r.Visual.Max[3],r.Collider.Max[3],r.Zone.Max[3])
 table.insert(o,r)
end
return H:JSONEncode(o)
