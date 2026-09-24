local task=require(script.Parent.Runtime).Task
local Players=require(script.Parent.Runtime).Players
local Workspace=require(script.Parent.Runtime).Workspace
local StrengthManager=require(script.Parent:WaitForChild("StrengthManager"))
local TrainingManager={}
local activeSessions={}
local animationTracks=setmetatable({}, {__mode='k'})
local currentTreadmills={}

local function finitePositive(v)
 return typeof(v)=="number" and v==v and v~=math.huge and v~=-math.huge and v>0
end
local function setFlag(player,value)
 if player and player:IsA("Player") then player:SetAttribute("IsTraining",value) end
end
local function startTrainingAnimation(player)
 local c=player.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local anim=c and c:FindFirstChild("Animate")
 local walk=anim and anim:FindFirstChild("walk")
 local asset=walk and walk:FindFirstChild("WalkAnim")
 if not h or not asset or not asset:IsA("Animation") then return end
 local animator=h:FindFirstChildOfClass("Animator") or Instance.new("Animator")
 animator.Parent=h
 local track=animator:LoadAnimation(asset)
 track.Priority=Enum.AnimationPriority.Movement
 track.Looped=true
 track:Play(0.15,1,1)
 animationTracks[player]=track
end
local function stopTrainingAnimation(player)
 local track=animationTracks[player]
 if track then track:Stop(0.15); animationTracks[player]=nil end
end

local function makePart(parent,name,size,cframe,color,transparency,collide)
 local p=Instance.new("Part")
 p.Name=name p.Size=size p.CFrame=cframe p.Anchored=true p.Material=Enum.Material.SmoothPlastic
 p.Color=color p.Transparency=transparency p.CanCollide=collide p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end

function TrainingManager.CreateTreadmill(area)
 assert(area and area:IsA("Model"),"TrainingArea Model required")
 local old=area:FindFirstChild("Treadmill01")
 if old then
  if old:GetAttribute("ManagedBy")=="TrainingManager" then old:Destroy()
  else error("Unmanaged TrainingArea.Treadmill01 already exists") end
 end
 local floor=assert(area:FindFirstChild("Floor"),"TrainingArea.Floor missing")
 local model=Instance.new("Model")
 model.Name="Treadmill01" model:SetAttribute("ManagedBy","TrainingManager")
 model:SetAttribute("VirtualStepReward",1) model:SetAttribute("VirtualStepInterval",0.5) model.Parent=area
 local top=floor.Position.Y+floor.Size.Y/2
 local center=Vector3.new(floor.Position.X,top,floor.Position.Z+18)
 local base=makePart(model,"Base",Vector3.new(14,1,24),CFrame.new(center+Vector3.new(0,.5,0)),Color3.fromRGB(70,75,82),0,true)
 makePart(model,"Belt",Vector3.new(11,.4,21),CFrame.new(center+Vector3.new(0,1.2,0)),Color3.fromRGB(30,33,38),0,true)
 makePart(model,"TrainingZone",Vector3.new(10,6,20),CFrame.new(center+Vector3.new(0,4.4,0)),Color3.fromRGB(80,200,120),1,false)
 model.PrimaryPart=base return model
end

function TrainingManager.StopTraining(player)
 local s=activeSessions[player]
 if s then
  s.Active=false
  if s.DeathConnection then s.DeathConnection:Disconnect() end
  if s.TreadmillConnection then s.TreadmillConnection:Disconnect() end
  activeSessions[player]=nil
 end
 stopTrainingAnimation(player) setFlag(player,false)
 return s~=nil
end

function TrainingManager.StartTraining(player,treadmill)
 if not player or not player:IsA("Player") then return false,"player must be a Player" end
 if not treadmill or not treadmill:IsA("Model") or not treadmill:IsDescendantOf(Workspace) then return false,"invalid treadmill" end
 local old=activeSessions[player]
 if old and old.Active and old.Treadmill==treadmill then return true,"Already training" end
 TrainingManager.StopTraining(player)
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return false,"Player has no living Character" end
 local gain=treadmill:GetAttribute("VirtualStepReward")
 local interval=treadmill:GetAttribute("VirtualStepInterval")
 if not finitePositive(gain) or not finitePositive(interval) then return false,"Invalid treadmill attributes" end
 local s={Active=true,Treadmill=treadmill}
 activeSessions[player]=s setFlag(player,true) startTrainingAnimation(player)
 s.DeathConnection=humanoid.Died:Connect(function() TrainingManager.StopTraining(player) end)
 s.TreadmillConnection=treadmill.AncestryChanged:Connect(function()
  if not treadmill:IsDescendantOf(Workspace) then TrainingManager.StopTraining(player) end
 end)
 task.spawn(function()
  while s.Active and activeSessions[player]==s do
   task.wait(interval)
   if not s.Active or activeSessions[player]~=s then break end
   StrengthManager.AddStrength(player,gain)
  end
 end)
 return true,"Training started"
end

function TrainingManager.IsPlayerInsideZone(player,zone)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not humanoid or humanoid.Health<=0 or not root then return false end
 local footPosition=root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2,0)
 local rootLocal=zone.CFrame:PointToObjectSpace(root.Position)
 local footLocal=zone.CFrame:PointToObjectSpace(footPosition)
 local h=zone.Size/2
 return math.abs(rootLocal.X)<=h.X and math.abs(footLocal.Y)<=h.Y and math.abs(rootLocal.Z)<=h.Z
end

function TrainingManager.UpdateZoneOccupants()
 for _,player in Players:GetPlayers() do
  local occupiedTreadmill=nil
  for _,treadmill in currentTreadmills do
   local zone=treadmill:IsDescendantOf(Workspace) and treadmill:FindFirstChild("TrainingZone")
   if zone and TrainingManager.IsPlayerInsideZone(player,zone) then
    occupiedTreadmill=treadmill
    break
   end
  end
  if occupiedTreadmill then TrainingManager.StartTraining(player,occupiedTreadmill)
  else TrainingManager.StopTraining(player) end
 end
end

function TrainingManager.Initialize()
 local treadmills={}
 for index=1,10 do
  local name=("Tredmill%02d"):format(index)
  local treadmill=assert(Workspace:FindFirstChild(name),"Workspace."..name.." missing")
  assert(treadmill:IsA("Model"),"Workspace."..name.." must be a Model")
  assert(treadmill:FindFirstChild("TrainingZone"),"Workspace."..name..".TrainingZone missing")
  if treadmill:GetAttribute("VirtualStepReward")==nil then treadmill:SetAttribute("VirtualStepReward",1) end
  if treadmill:GetAttribute("VirtualStepInterval")==nil then treadmill:SetAttribute("VirtualStepInterval",0.5) end
  assert(finitePositive(treadmill:GetAttribute("VirtualStepReward")),"Invalid "..name.." VirtualStepReward")
  assert(finitePositive(treadmill:GetAttribute("VirtualStepInterval")),"Invalid "..name.." VirtualStepInterval")
  table.insert(treadmills,treadmill)
 end
 local list={} for player in activeSessions do table.insert(list,player) end
 for _,player in list do TrainingManager.StopTraining(player) end
 for _,player in Players:GetPlayers() do setFlag(player,false) end
 currentTreadmills=treadmills
 return currentTreadmills
end
function TrainingManager.GetTreadmill() return currentTreadmills[1] end
function TrainingManager.GetTreadmills() return currentTreadmills end
function TrainingManager.GetActiveSessionCount()
 local n=0 for _ in activeSessions do n+=1 end return n
end
return TrainingManager