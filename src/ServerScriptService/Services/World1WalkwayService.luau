local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(game.ReplicatedStorage.Config.World1WalkwayConfig)
local Geometry=require(game.ReplicatedStorage.Modules.World1WalkwayGeometry)
local Speed=require(script.Parent.SpeedService)
local M={}
local states={}
local resolve=Geometry.new()
local route,refreshAt
local started=false
local INPUT_TIMEOUT=.35
local MIN_INPUT_INTERVAL=1/30
local function release(player,s)
 if s.Constraint then s.Constraint:Destroy();s.Constraint=nil end
 if s.Attachment then s.Attachment:Destroy();s.Attachment=nil end
 s.Riding=false
 if player.Parent then player:SetAttribute("World1WalkwayRiding",nil) end
end
local function step(player,s,dt,now)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local revision=character and character:GetAttribute("SpawnPlacementRevision")
 if character~=s.Character or revision~=s.Revision then
  release(player,s);s.Character=character;s.Revision=revision;s.LastPosition=nil;s.Ended=false
  s.Input=0;s.InputAt=nil
  s.Params=RaycastParams.new();s.Params.FilterType=Enum.RaycastFilterType.Exclude
  s.Params.FilterDescendantsInstances=character and {character} or {};s.Params.RespectCanCollide=true
 end
 if not route or not humanoid or not root
  or (player:GetAttribute("CurrentWorld") or 1)~=1 or player:GetAttribute("IsTraining")==true
  or character:GetAttribute("LobbySpawnPlaced")==false then release(player,s);return end
 local along,side=Geometry.Coordinates(route,root.Position)
 local ending=Geometry.EndDistance(route,character)
 if along<ending-Config.ExitRearmDistance then s.Ended=false end
 if not s.SpeedAt or now>=s.SpeedAt then
  local speedState=Speed.GetState(player)
  s.Loaded=speedState.Loaded;s.SpeedAt=now+Config.RefreshInterval
 end
 -- Server-applied speed includes existing authorized transient boosts.
 -- Clients cannot supply WalkSpeed, target velocity or position to this service.
 s.Speed=s.Loaded and humanoid.WalkSpeed or nil
 local teleported=s.LastPosition and (root.Position-s.LastPosition).Magnitude>math.max(8,((s.Speed or 0)+Config.TransportSpeed)*dt*3)
 s.LastPosition=root.Position
 if teleported then s.Input=0;s.InputAt=nil end
 if not s.Speed or teleported or s.Ended or along<Config.StartDistance or along>=ending-Config.EndpointTolerance
  or math.abs(side)>Config.TransportWidth/2 or not Geometry.Grounded(character,humanoid,root,route,s.Params) then
  if s.Riding and along>=ending-Config.EndpointTolerance then
   s.Ended=true
   local velocity=root.AssemblyLinearVelocity
   local input=s.InputAt and now-s.InputAt<=INPUT_TIMEOUT and s.Input or 0
   local walking=(s.Speed or 0)*input
   root.AssemblyLinearVelocity=velocity+route.Direction*(walking-velocity:Dot(route.Direction))
  end
  release(player,s);return
 end
 if not s.Constraint then
  local attachment=Instance.new("Attachment");attachment.Name="World1WalkwayAttachment";attachment.Parent=root
  local constraint=Instance.new("LinearVelocity");constraint.Name="World1WalkwayVelocity"
  constraint.Attachment0=attachment;constraint.RelativeTo=Enum.ActuatorRelativeTo.World
  constraint.VelocityConstraintMode=Enum.VelocityConstraintMode.Line
  constraint.ForceLimitsEnabled=false
  constraint.LineDirection=route.Direction
  constraint.LineVelocity=0
  constraint.Parent=root
  s.Constraint=constraint;s.Attachment=attachment
 end
 -- One axis only: native Humanoid still owns lateral motion and jumping.
 -- Signed/analog input preserves reverse and diagonal intent.
 s.Constraint.LineDirection=route.Direction
 local input=s.InputAt and now-s.InputAt<=INPUT_TIMEOUT and s.Input or 0
 s.Constraint.LineVelocity=Geometry.TransportVelocity(s.Speed,input,ending-along,dt)
 s.Constraint:SetAttribute("WalkSpeed",s.Speed)
 s.Riding=true
 if player:GetAttribute("World1WalkwayRiding")~=true then player:SetAttribute("World1WalkwayRiding",true) end
end
function M.IsRiding(player)
 local s=states[player]
 return s~=nil and s.Riding==true
end
function M.Start()
 if started then return end
 started=true
 local remote=Instance.new("RemoteEvent");remote.Name="World1WalkwayInput";remote.Parent=RS
 remote.OnServerEvent:Connect(function(player,character,input)
  local s=states[player]
  -- MoveDirection is not replicated. Accept only a finite normalized axis
  -- intent for this player's current, already server-approved ride.
  if not s or not s.Riding or character~=player.Character or character~=s.Character
   or typeof(input)~="number" or input~=input or math.abs(input)>1
   or (player:GetAttribute("CurrentWorld") or 1)~=1 then return end
  local now=os.clock()
  if s.InputAt and now-s.InputAt<MIN_INPUT_INTERVAL then return end
  s.Input=input;s.InputAt=now
 end)
 RunService.PreSimulation:Connect(function(dt)
  local now=os.clock()
  if not refreshAt or now>=refreshAt then route=resolve();refreshAt=now+Config.RefreshInterval end
  for _,player in Players:GetPlayers() do
   local s=states[player]
   if not s then s={};states[player]=s end
   step(player,s,dt,now)
  end
 end)
 Players.PlayerRemoving:Connect(function(player)
  local s=states[player];if s then release(player,s);states[player]=nil end
 end)
end
return M
