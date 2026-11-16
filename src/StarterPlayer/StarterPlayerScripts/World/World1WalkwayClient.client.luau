-- The server alone grants a ride. Predict only its bounded axis target locally.
-- GetMoveVelocity preserves analog magnitude as well as world-space direction.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local Config=require(RS.Config.World1WalkwayConfig)
local Geometry=require(RS.Modules.World1WalkwayGeometry)
local Locomotion=require(RS.Modules.World1WalkwayLocomotion)
local remote=RS:WaitForChild("World1WalkwayInput")
local resolve=Geometry.new()
local route,character,params,previous,locomotion
local refreshAt,lastSend=0,0
local carry=0
local riding=false
local function clearCarry(root,direction)
 if carry>0 and root and root.Parent then
  -- Remove our previous offset once; preserve native signed walking and jump.
  local humanoid=root.Parent:FindFirstChildOfClass("Humanoid")
  local walking=humanoid and humanoid:GetMoveVelocity():Dot(direction) or 0
  local velocity=root.AssemblyLinearVelocity
  local residual=math.clamp(velocity:Dot(direction)-walking,0,carry)
  root.AssemblyLinearVelocity=velocity-direction*residual
 end
 carry=0
end
local connection=RunService.PreSimulation:Connect(function(dt)
 local now=os.clock()
 if now>=refreshAt then route=resolve();refreshAt=now+Config.RefreshInterval end
 if player.Character~=character then
  if locomotion then locomotion:Destroy();locomotion=nil end
  character=player.Character;previous=nil;carry=0;riding=false
  params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances=character and {character} or {};params.RespectCanCollide=true
 end
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local constraint=root and root:FindFirstChild("World1WalkwayVelocity")
 local allowed=false
 local remaining=0
 if constraint and humanoid and route and (player:GetAttribute("CurrentWorld") or 1)==1
  and player:GetAttribute("IsTraining")~=true then
  local along,side=Geometry.Coordinates(route,root.Position)
  remaining=Geometry.EndDistance(route,character)-along
  allowed=along>=Config.StartDistance and remaining>Config.EndpointTolerance
   and math.abs(side)<=Config.TransportWidth/2 and humanoid.FloorMaterial~=Enum.Material.Air
   and Geometry.Grounded(character,humanoid,root,route,params)
 end
 if constraint then constraint.Enabled=allowed end
 if allowed then
  local input=humanoid.WalkSpeed>0 and math.clamp(humanoid:GetMoveVelocity():Dot(route.Direction)/humanoid.WalkSpeed,-1,1) or 0
  local speed=constraint:GetAttribute("WalkSpeed")
  if typeof(speed)=="number" and speed>=0 then
   constraint.LineVelocity,carry=Geometry.TransportVelocity(speed,input,remaining,dt)
   if constraint~=previous or now-lastSend>=.05 then
    remote:FireServer(character,input);lastSend=now
   end
  end
 elseif previous and route then
  clearCarry(root,previous.LineDirection)
 end
 riding=allowed
 previous=allowed and constraint or nil
 if humanoid and not locomotion then locomotion=Locomotion.new(character,humanoid) end
end)
local animation=RunService.PreAnimation:Connect(function()
 if locomotion then
  local ordinary=player:GetAttribute("IsTraining")~=true and player:GetAttribute("IsFighting")~=true
  locomotion:Update(riding and ordinary,not riding and ordinary)
 end
end)
script.Destroying:Once(function()
 connection:Disconnect();animation:Disconnect()
 if previous then previous.Enabled=false;clearCarry(previous.Parent,previous.LineDirection) end
 if locomotion then locomotion:Destroy() end
end)
