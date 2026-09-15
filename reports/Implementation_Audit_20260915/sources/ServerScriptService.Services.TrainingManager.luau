local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local StrengthManager=require(game.ServerScriptService.Services:WaitForChild("StrengthManager"))
local TreadmillConfig=require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
local GamePass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local ItemService=require(game.ServerScriptService.Services:WaitForChild("ItemService"))
local PotionService=require(game.ServerScriptService.Services:WaitForChild("PotionService"))
local treadmillFolder=Workspace:WaitForChild("Treadmill")
local TrainingConfig=require(game.ReplicatedStorage.Config:WaitForChild("TrainingConfig"))
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
 model.Parent=area -- Legacy gain Attributes are not read; TrainingConfig is authoritative.
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

function TrainingManager.CanUseTreadmill(player,treadmill)
 if not treadmill or treadmill.Parent~=treadmillFolder then return false end
 local config=TreadmillConfig.Get(treadmill.Name)
 if not config or not finitePositive(config.Multiplier) then return false end
 if config.RequiresPremium then return GamePass.AreEffectsEnabled() and GamePass.HasPremiumTreadmill(player),config end
 local count=tonumber(player:GetAttribute("RebirthCount")) or 0
 return count>=(config.RequiredRebirth or 0),config
end

function TrainingManager.GetOccupiedTreadmill(player)
 for _,treadmill in ipairs(currentTreadmills) do
  local zone=treadmill:IsDescendantOf(Workspace) and treadmill:FindFirstChild("TrainingZone")
  if zone and TrainingManager.IsPlayerInsideZone(player,zone) then return treadmill end
 end
 return nil
end

function TrainingManager.StartTraining(player,treadmill)
 if not player or not player:IsA("Player") then return false,"player must be a Player" end
 if not treadmill or not treadmill:IsA("Model") or not treadmill:IsDescendantOf(Workspace) then return false,"invalid treadmill" end
 local allowed=TrainingManager.CanUseTreadmill(player,treadmill)
 local zone=treadmill:FindFirstChild("TrainingZone")
 if not allowed or not zone or not TrainingManager.IsPlayerInsideZone(player,zone) then
  TrainingManager.StopTraining(player)
  return false,"TreadmillUnavailable"
 end
 local old=activeSessions[player]
 if old and old.Active and old.Treadmill==treadmill then return true,"Already training" end
 TrainingManager.StopTraining(player)
 local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return false,"Player has no living Character" end
 local gain=TrainingConfig.BaseGain
 local interval=TrainingConfig.TrainingInterval
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
   local canUse,config=TrainingManager.CanUseTreadmill(player,treadmill)
   if not canUse or not TrainingManager.IsPlayerInsideZone(player,zone) then
    TrainingManager.StopTraining(player)
    break
   end
   local effectiveMultiplier=config.Multiplier+ItemService.GetBeltTreadmillBonus(player)+PotionService.GetTrainingBonus(player)
   StrengthManager.AddStrength(player,gain,1,effectiveMultiplier)
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
  local occupiedTreadmill=TrainingManager.GetOccupiedTreadmill(player)
  if occupiedTreadmill then TrainingManager.StartTraining(player,occupiedTreadmill)
  else TrainingManager.StopTraining(player) end
 end
end

function TrainingManager.Initialize()
 local treadmills={}
 for index=1,10 do
  local name=("Tredmill%02d"):format(index)
  local treadmill=assert(treadmillFolder:FindFirstChild(name),"Workspace.Treadmill."..name.." missing")
  assert(treadmill:IsA("Model"),"Workspace.Treadmill."..name.." must be a Model")
  assert(treadmill:FindFirstChild("TrainingZone"),"Workspace.Treadmill."..name..".TrainingZone missing")
  -- StrengthPerTick/TickInterval and VirtualStep* Attributes are legacy, not inputs.
  assert(finitePositive(TrainingConfig.BaseGain),"Invalid TrainingConfig.BaseGain")
  assert(finitePositive(TrainingConfig.TrainingInterval),"Invalid TrainingConfig.TrainingInterval")
  assert(TreadmillConfig.Get(name),"Missing treadmill configuration: "..name)
  local sign=treadmill.TrainingZone:FindFirstChild("TreadmillInfo")
  local label=sign and sign:FindFirstChild("Info")
  if label then label.Text=TreadmillConfig.GetDisplayText(name) end
  table.insert(treadmills,treadmill)
 end
 local list={} for player in activeSessions do table.insert(list,player) end
 for _,player in list do TrainingManager.StopTraining(player) end
 for _,player in Players:GetPlayers() do setFlag(player,false) end
 currentTreadmills=treadmills
 return currentTreadmills
end
-- Reference only: rewards ignore tier multipliers and use a real Normal machine tick.
function TrainingManager.GetNormalTrainingReference()
 for _,model in ipairs(currentTreadmills) do
  local _,kind=TreadmillConfig.Get(model.Name)
  if kind=="Normal" then return TrainingConfig.BaseGain,TrainingConfig.TrainingInterval end
 end
 return nil,nil
end
function TrainingManager.GetTreadmill() return currentTreadmills[1] end
function TrainingManager.GetTreadmills() return currentTreadmills end
function TrainingManager.GetActiveSessionCount()
 local n=0 for _ in activeSessions do n+=1 end return n
end
return TrainingManager
