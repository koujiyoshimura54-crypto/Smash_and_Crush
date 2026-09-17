local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local StrengthManager=require(game.ServerScriptService.Services:WaitForChild("StrengthManager"))
local TreadmillConfig=require(game.ReplicatedStorage.Config:WaitForChild("TreadmillConfig"))
local GamePass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local ItemService=require(game.ServerScriptService.Services:WaitForChild("ItemService"))
local PotionService=require(game.ServerScriptService.Services:WaitForChild("PotionService"))
local treadmillFolder=Workspace:WaitForChild("Treadmill")
local TrainingConfig=require(game.ReplicatedStorage.Config:WaitForChild("TrainingConfig"))
local TreadmillVisuals=require(game.ServerScriptService.Services:WaitForChild("TreadmillVisualService"))
local TrainingManager={}
local activeSessions={}
local animationTracks=setmetatable({}, {__mode='k'})
local currentTreadmills={}
local premiumEntries=setmetatable({}, {__mode="k"})

local function finitePositive(v)
 return typeof(v)=="number" and v==v and v~=math.huge and v~=-math.huge and v>0
end
local function setFlag(player,value,treadmill)
 if player and player:IsA("Player") then
  -- Display-only mirror of the accepted session; never authorizes training.
  player:SetAttribute("TrainingTreadmill",value and treadmill and treadmill.Name or nil)
  player:SetAttribute("IsTraining",value)
 end
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

local function near(value,target)
 return math.abs(value-target)<.08
end
local function treadmillVisualRole(part)
 local size=part.Size
 if near(size.X,8) and near(size.Y,.98) and near(size.Z,18) then return "Belt" end
 if near(size.X,4) and near(size.Y,.1) and near(size.Z,2.8) then return "ConsoleAccent" end
 -- Authored frame Parts: side rails, uprights, top beam and console surround.
 -- Exclude TrainingZone, invisible UI surfaces and any later accessories.
 if part.Name=="Part" and part.Transparency==0 and part.Parent:IsA("Model") then return "Frame" end
 return nil
end
local function applyStrengthColor(treadmill,config)
 local colors=TreadmillConfig.StrengthColors[config.Multiplier]
 if not colors then return end
 for _,part in treadmill:GetDescendants() do
  if part:IsA("BasePart") then
   local role=treadmillVisualRole(part)
   if role then
    part.Color=role=="Belt" and colors.BeltColor or colors.FrameColor
    part:SetAttribute("TreadmillVisualRole",role)
   end
  end
 end
end

-- One visible Part per reward group. Keep authored mats hidden in place so their
-- collision/touch/query properties remain unchanged. New mats are visual only.
local function applyGroupMats(treadmills)
 local map=Workspace:FindFirstChild("GeneratedMap")
 local area=map and map:FindFirstChild("TrainingArea")
 if not area then return end
 local groups={}
 for _,treadmill in ipairs(treadmills) do
  local entry=TreadmillConfig.Get(treadmill.Name)
  local colors=entry and TreadmillConfig.StrengthColors[entry.Multiplier]
  local index=tonumber(treadmill.Name:match("^Tredmill(%d+)$"))
  local mat=index and area:FindFirstChild("TrainingSpace_1_"..index)
  if colors and colors.MatColor and mat and mat:IsA("BasePart") then
   local group=groups[entry.Multiplier] or {}
   groups[entry.Multiplier]=group
   table.insert(group,mat)
  end
 end
 for multiplier,mats in pairs(groups) do
  table.sort(mats,function(a,b) return a.Name<b.Name end)
  if #mats==2 then
   local reference=mats[1]
   local minX,maxX=math.huge,-math.huge
   for _,mat in ipairs(mats) do
    for _,x in ipairs({-1,1}) do
     for _,z in ipairs({-1,1}) do
      local world=mat.CFrame:PointToWorldSpace(Vector3.new(x*mat.Size.X/2,0,z*mat.Size.Z/2))
      local point=reference.CFrame:PointToObjectSpace(world)
      minX=math.min(minX,point.X)
      maxX=math.max(maxX,point.X)
     end
    end
   end
   local name="TreadmillGroupMat_"..multiplier
   local groupMat=area:FindFirstChild(name)
   if not groupMat then
    groupMat=Instance.new("Part")
    groupMat.Name=name
    groupMat.Anchored=true
    groupMat.CanCollide=false
    groupMat.CanTouch=false
    groupMat.CanQuery=false
    groupMat.TopSurface=Enum.SurfaceType.Smooth
    groupMat.BottomSurface=Enum.SurfaceType.Smooth
    groupMat:SetAttribute("ManagedBy","TrainingManager")
    groupMat.Parent=area
   end
   if groupMat:IsA("BasePart") and groupMat:GetAttribute("ManagedBy")=="TrainingManager" then
    groupMat.Size=Vector3.new(maxX-minX,reference.Size.Y,reference.Size.Z)
    groupMat.CFrame=reference.CFrame*CFrame.new((minX+maxX)/2,0,0)
    groupMat.Material=reference.Material
    groupMat.Color=TreadmillConfig.StrengthColors[multiplier].MatColor
    groupMat.Transparency=0
    for _,mat in ipairs(mats) do mat.Transparency=1 end
   end
  end
 end
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
 if config.RequiresPremium then return GamePass.AreEffectsEnabled(player) and GamePass.HasPremiumTreadmill(player),config end
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
 activeSessions[player]=s setFlag(player,true,treadmill) startTrainingAnimation(player)
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
  -- Reuse the actual permission predicate, including Premium ownership.
  for _,treadmill in ipairs(currentTreadmills) do
   local allowed=TrainingManager.CanUseTreadmill(player,treadmill)==true
   local attribute="TreadmillAvailable_"..treadmill.Name
   if player:GetAttribute(attribute)~=allowed then player:SetAttribute(attribute,allowed) end
  end
  local occupiedTreadmill=TrainingManager.GetOccupiedTreadmill(player)
  local config=occupiedTreadmill and TreadmillConfig.Get(occupiedTreadmill.Name)
  if occupiedTreadmill and config and config.RequiresPremium then
   local character=player.Character
   local entry=premiumEntries[player]
   if not entry or entry.Character~=character or entry.Treadmill~=occupiedTreadmill then
    entry={Character=character,Treadmill=occupiedTreadmill}
    premiumEntries[player]=entry -- Latch before ownership verification can yield.
    task.spawn(function()
     GamePass.PromptPremiumTreadmill(player)
    end)
   end
  else
   premiumEntries[player]=nil
  end
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
  local config=assert(TreadmillConfig.Get(name),"Missing treadmill configuration: "..name)
  applyStrengthColor(treadmill,config)
  local visualOK,visualError=TreadmillVisuals.Apply(treadmill,config)
  if not visualOK then warn(visualError) end
  local sign=treadmill.TrainingZone:FindFirstChild("TreadmillInfo")
  local label=sign and sign:FindFirstChild("Info")
  if label then label.Text=TreadmillConfig.GetDisplayText(name) end
  table.insert(treadmills,treadmill)
 end
 applyGroupMats(treadmills)
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
