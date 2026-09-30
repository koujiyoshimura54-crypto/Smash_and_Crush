-- World1 Boss -> Player attacks only. Chase and Player -> Boss combat remain unchanged.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local M = {}
local BOSS_DAMAGE = 25
local BOSS_ATTACK_INTERVAL = 1
local PLAYER_MAX_HEALTH = 100
local REACH_SCALE = 0.25
local MIN_REACH = 8
local MAX_REACH = 14
local active = {}
local validateSession

function M.GetAttackBounds(enemy, stage)
 local pivot = enemy:GetPivot()
 local low = Vector3.new(math.huge, math.huge, math.huge)
 local high = -low
 local visual = enemy:FindFirstChildOfClass("Model")
 local function include(part)
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
   local point = pivot:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2))
   low=low:Min(point);high=high:Max(point)
  end end end
 end
 if visual then
  for _,part in visual:GetDescendants() do
   if part:IsA("BasePart") and part.Transparency<1 then
    local helper=false
    local node=part
    while node and node~=visual do
     local name=node.Name:lower()
     if name:find("vfx",1,true) or name:find("particle",1,true) then helper=true;break end
     node=node.Parent
    end
    if not helper then include(part) end
   end
  end
 end
 local collider=enemy:FindFirstChild("MiniBossCollider")
 if collider and collider:IsA("BasePart") then include(collider) end
 if low.X==math.huge then return nil end
 local size=high-low
 local reach=math.clamp(math.max(size.X,size.Z)*REACH_SCALE,MIN_REACH,MAX_REACH)
 local map=Workspace:FindFirstChild("GeneratedMap")
 local corridor=map and map:FindFirstChild("BattleCorridor")
 local arena=corridor and corridor:FindFirstChild(("Stage%02d"):format(stage))
 local floor=arena and arena:FindFirstChild("Floor")
 if floor then
  -- A flying visual must still reach a player standing on its arena floor.
  local floorY=pivot:PointToObjectSpace(floor.Position+Vector3.new(0,floor.Size.Y/2,0)).Y
  low=Vector3.new(low.X,math.min(low.Y,floorY),low.Z)
 end
 return {Pivot=pivot,Low=low,High=high,Reach=reach}
end

function M.IsInRange(enemy, stage, humanoid, root)
 local bounds=M.GetAttackBounds(enemy,stage)
 if not bounds then return false,math.huge,0 end
 local point=bounds.Pivot:PointToObjectSpace(root.Position)
 local dx=math.max(bounds.Low.X-point.X,0,point.X-bounds.High.X)
 local dz=math.max(bounds.Low.Z-point.Z,0,point.Z-bounds.High.Z)
 local distance=math.sqrt(dx*dx+dz*dz)
 local playerRadius=math.max(root.Size.X,root.Size.Z)/2
 local bottom=point.Y-humanoid.HipHeight-root.Size.Y/2
 local top=point.Y+root.Size.Y/2
 local vertical=top>=bounds.Low.Y-2 and bottom<=bounds.High.Y+bounds.Reach
 -- No facing cone or raycast: destroyed server walls must not create safe spots.
 return vertical and distance<=bounds.Reach+playerRadius,distance,bounds.Reach+playerRadius
end

function M.Stop(player, heal)
 local r=active[player]
 if not r then return end
 active[player]=nil
 if r.ChildAdded then r.ChildAdded:Disconnect() end
 if r.Died then r.Died:Disconnect() end
 for healthScript,enabled in r.RegenScripts do
  -- Do not restart regeneration on a dead body; respawn receives a fresh standard script.
  if healthScript.Parent and r.Humanoid.Health>0 then healthScript.Enabled=enabled end
 end
 local hum=r.Humanoid
 if heal and hum.Parent and hum.Health>0 and player.Character==r.Character then
  hum.Health=hum.MaxHealth
 end
end

function M.Start(player, enemy, stage, startedAt)
 local character=player.Character
 local hum=character and character:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 then return end
 local previous=active[player]
 if previous and previous.Character==character and previous.Enemy==enemy and previous.Stage==stage then return end
 M.Stop(player,true)
 local r={Player=player,Character=character,Humanoid=hum,Enemy=enemy,Stage=stage,
  StartedAt=startedAt,NextHit=1,RegenScripts={}}
 active[player]=r
 local function pauseRegen(child)
  if child:IsA("Script") and child.Name=="Health" and r.RegenScripts[child]==nil then
   r.RegenScripts[child]=child.Enabled
   child.Enabled=false
  end
 end
 for _,child in character:GetChildren() do pauseRegen(child) end
 r.ChildAdded=character.ChildAdded:Connect(pauseRegen)
 r.Died=hum.Died:Connect(function() M.Stop(player,false) end)
 if hum.MaxHealth~=PLAYER_MAX_HEALTH then hum.MaxHealth=PLAYER_MAX_HEALTH end
 hum.Health=hum.MaxHealth
end

function M.Rebind(player, enemy)
 local r=active[player]
 if r then r.Enemy=enemy end
end
function M.SetSessionValidator(callback) validateSession=callback end
function M.GetState(player) return active[player] end

RunService.Heartbeat:Connect(function()
 local now=Workspace:GetServerTimeNow()
 for player,r in active do
  local root=r.Character:FindFirstChild("HumanoidRootPart")
  local valid=player.Parent==Players and player.Character==r.Character
   and r.Humanoid.Health>0 and root and r.Enemy.Parent
   and validateSession and validateSession(player,r.Enemy,r.Stage,r.Character)
  if not valid then
   M.Stop(player,true)
  else
   local due=math.floor((now-r.StartedAt)/BOSS_ATTACK_INTERVAL)
   if due>=r.NextHit then
    -- Absolute deadlines; missed server frames never generate a burst of catch-up hits.
    r.NextHit=due+1
    local hit,distance,reach=M.IsInRange(r.Enemy,r.Stage,r.Humanoid,root)
    local before=r.Humanoid.Health
    if hit then
     -- Deliberately bypass ForceField only for this formal Boss combat.
     -- The spawn ForceField instance and lobby protection remain intact.
     r.Humanoid.Health=math.max(0,before-BOSS_DAMAGE)
    end
    r.LastAttack={Index=due,ScheduledAt=r.StartedAt+due*BOSS_ATTACK_INTERVAL,
     ActualAt=Workspace:GetServerTimeNow(),Hit=hit,Distance=distance,Reach=reach,
     HealthBefore=before,HealthAfter=r.Humanoid.Health}
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(player) M.Stop(player,false) end)
return M
