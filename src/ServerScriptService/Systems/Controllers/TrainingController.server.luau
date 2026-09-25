local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local TrainingManager=require(game.ServerScriptService.Services:WaitForChild("TrainingManager"))
local initializing,registryDirty=false,true
local TREADMILL_TAG="TrainingTreadmill"
local elapsed=0


local AutoTap=require(game.ServerScriptService.Services:WaitForChild("AutoTapService"))
local AutoTapConfig=require(game.ReplicatedStorage.Config:WaitForChild("AutoTapConfig"))
local WalkStepInterval=AutoTapConfig.AutoInterval
local walkState=setmetatable({}, {__mode="k"})
local function walkingState(player)
 local x=walkState[player]
 if not x then x={Elapsed=0}; walkState[player]=x end
 return x
end
local function isGroundedWalking(humanoid,root)
 local st=humanoid:GetState()
 if st~=Enum.HumanoidStateType.Running and st~=Enum.HumanoidStateType.RunningNoPhysics then return false end
 return humanoid.MoveDirection.Magnitude>0.05 or Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude>0.5
end
local function updateWalkingSteps(dt)
 for _,player in Players:GetPlayers() do
  local x=walkingState(player)
  local c=player.Character
  local h=c and c:FindFirstChildOfClass("Humanoid")
  local r=c and c:FindFirstChild("HumanoidRootPart")
  if not AutoTap.CanAutoTrain(player) then x.Elapsed=0
  elseif isGroundedWalking(h,r) then
   x.Elapsed+=dt
   local n=math.floor(x.Elapsed/WalkStepInterval)
   if n>0 then x.Elapsed-=n*WalkStepInterval; AutoTap.AwardNormalTraining(player,n) end
  else x.Elapsed=0 end
 end
end
local function initialize()
 if initializing then return end
 if #CollectionService:GetTagged(TREADMILL_TAG)==0 then return end
 initializing=true
 local ok,err=pcall(TrainingManager.Initialize)
 initializing=false
 script:SetAttribute("Initialized",ok)
 script:SetAttribute("LastInitializeError",ok and "" or tostring(err))
 if ok then registryDirty=false else warn("Training initialization failed: "..tostring(err)) end
end
local function setup(p)
 p:SetAttribute("IsTraining",false)
 p:GetAttributeChangedSignal("AutoTapEnabled"):Connect(function() walkState[p]=nil end)
 walkState[p]=nil p.CharacterAdded:Connect(function() TrainingManager.StopTraining(p) end)
end
Players.PlayerAdded:Connect(setup)
for _,p in Players:GetPlayers() do setup(p) end
Players.PlayerRemoving:Connect(function(p) TrainingManager.StopTraining(p); walkState[p]=nil end)
CollectionService:GetInstanceAddedSignal(TREADMILL_TAG):Connect(function() registryDirty=true end)
CollectionService:GetInstanceRemovedSignal(TREADMILL_TAG):Connect(function() registryDirty=true end)
script:SetAttribute("Initialized",false)
script:SetAttribute("ZoneScanCount",0)
RunService.Heartbeat:Connect(function(dt)
	updateWalkingSteps(dt)

	elapsed += dt
	if elapsed < 0.2 then
		return
	end
	elapsed %= 0.2

	local treadmill = TrainingManager.GetTreadmill()

	if registryDirty or #TrainingManager.GetTreadmills()~=#CollectionService:GetTagged(TREADMILL_TAG)
		or (treadmill and not treadmill:IsDescendantOf(Workspace)) then
		initialize()
	end

	treadmill = TrainingManager.GetTreadmill()

	if treadmill and treadmill:IsDescendantOf(Workspace) then
		TrainingManager.UpdateZoneOccupants()
		script:SetAttribute(
			"ZoneScanCount",
			(script:GetAttribute("ZoneScanCount") or 0) + 1
		)
	end
end)
