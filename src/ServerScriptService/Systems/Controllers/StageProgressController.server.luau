local Players=game:GetService("Players")
local W=game:GetService("Workspace")
local E=require(game.ServerScriptService.World.EnemyManager)
local current
local initializing=false

local function tryInit(m)
 if initializing or current==m or m~=W:FindFirstChild("GeneratedMap") then return false end
 local bc=m:FindFirstChild("BattleCorridor")
 local stage10=bc and bc:FindFirstChild("Stage10")
 if not stage10 then return false end
 initializing=true
 local ok,err=pcall(function() E.Initialize(m) end)
 initializing=false
 if ok then
  current=m
  return true
 end
 warn("StageProgressController initialization failed: "..tostring(err))
 return false
end

Players.PlayerAdded:Connect(function(p)
 task.defer(function()
  if current then E.InitializePlayer(p) end
 end)
end)

task.spawn(function()
 while not current do
  local m=W:FindFirstChild("GeneratedMap")
  if m then tryInit(m) end
  task.wait(0.25)
 end
end)

W.ChildAdded:Connect(function(c)
 if c.Name=="GeneratedMap" then
  task.spawn(function()
   while c.Parent and not current do
    if tryInit(c) then break end
    task.wait(0.25)
   end
  end)
 end
end)

-- World travel request: server-authoritative, whitelisted gate routes only.
do
 local RS=game:GetService("ReplicatedStorage")
 local Config=require(RS:WaitForChild("Config"):WaitForChild("WorldGateConfig"))
 local Badges=require(game.ServerScriptService.Services:WaitForChild("BadgeAwardService"))
 local remote=RS:WaitForChild("Remotes"):WaitForChild("WorldTravelRequest")
 local travelBusy=setmetatable({}, {__mode="k"})

 local function insideTrigger(trigger,root)
  local p=trigger.CFrame:PointToObjectSpace(root.Position)
  local half=trigger.Size*.5
  return math.abs(p.X)<=half.X+2 and math.abs(p.Y)<=half.Y+2 and math.abs(p.Z)<=half.Z+2
 end
 local function arrivalCFrame(spawn,humanoid,root)
  return spawn.CFrame*CFrame.new(0,spawn.Size.Y*.5+humanoid.HipHeight+root.Size.Y*.5+0.1,0)
 end
 local function route(action,player)
  if action=="ToWorld2" then
   local highest=player:GetAttribute("HighestUnlockedWorld")
   if typeof(highest)~="number" or highest<Config.RequiredWorld or player:GetAttribute("CurrentWorld")==2 then return end
   local gate=W:FindFirstChild(Config.GateName)
   local trigger=gate and gate:FindFirstChild("WorldGateTrigger")
   local world2=W:FindFirstChild("World2Map")
   local training=world2 and world2:FindFirstChild("TrainingArea")
   return trigger,training and training:FindFirstChild("World2LobbySpawn"),2
  end
  if action=="ReturnWorld1" then
   if player:GetAttribute("CurrentWorld")~=2 then return end
   local world2=W:FindFirstChild("World2Map")
   local training2=world2 and world2:FindFirstChild("TrainingArea")
   local gate=training2 and training2:FindFirstChild("World1ReturnGate")
   local trigger=gate and gate:FindFirstChild("WorldGateTrigger")
   local world1=W:FindFirstChild("GeneratedMap")
   local training1=world1 and world1:FindFirstChild("TrainingArea")
   return trigger,training1 and training1:FindFirstChild("SpawnLocation"),1
  end
 end

 remote.OnServerEvent:Connect(function(player,action)
  if travelBusy[player] or (action~="ToWorld2" and action~="ReturnWorld1") then return end
  travelBusy[player]=true
  local ok,err=pcall(function()
   local character=player.Character
   local root=character and character:FindFirstChild("HumanoidRootPart")
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if not root or not humanoid or humanoid.Health<=0 then return end
   local trigger,spawn,targetWorld=route(action,player)
   if not trigger or not trigger:IsA("BasePart") or not spawn or not spawn:IsA("BasePart") then return end
   if not insideTrigger(trigger,root) then return end
   character:PivotTo(arrivalCFrame(spawn,humanoid,root))
   for _,part in character:GetDescendants() do
    if part:IsA("BasePart") then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end
   end
   player:SetAttribute("CurrentWorld",targetWorld)
   if targetWorld==2 then Badges.Award(player,"IntoWorld2") end
  end)
  if not ok then warn("[WorldTravel] Request failed for "..player.Name..": "..tostring(err)) end
  task.delay(1,function() travelBusy[player]=nil end)
 end)
 Players.PlayerRemoving:Connect(function(player) travelBusy[player]=nil end)
end
