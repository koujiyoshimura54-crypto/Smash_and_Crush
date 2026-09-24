local Players=require(script.Parent.Runtime).Players
local RunService=require(script.Parent.Runtime).RunService
local Workspace=require(script.Parent.Runtime).Workspace
local TrainingManager=require(script.Parent:WaitForChild("TrainingManager"))
local StrengthManager=require(script.Parent:WaitForChild("StrengthManager"))local watchedTreadmill,initializing=nil,false
local elapsed=0


local walkState=setmetatable({}, {__mode="k"})

local WalkStepInterval=0.5
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
  if not h or h.Health<=0 or not r or player:GetAttribute("IsTraining")==true then x.Elapsed=0
  elseif isGroundedWalking(h,r) then
   x.Elapsed+=dt
   local n=math.floor(x.Elapsed/WalkStepInterval)
   if n>0 then x.Elapsed-=n*WalkStepInterval; StrengthManager.AddStrength(player,n) end
  else x.Elapsed=0 end
 end
end
local function initialize()
 if initializing then return end
 local treadmill=Workspace:FindFirstChild("Tredmill01")
 if not treadmill or not treadmill:FindFirstChild("TrainingZone") then return end
 initializing=true
 local ok,err=pcall(TrainingManager.Initialize)
 initializing=false
 script:SetAttribute("Initialized",ok)
 script:SetAttribute("LastInitializeError",ok and "" or tostring(err))
 if ok then watchedTreadmill=treadmill else warn("Training initialization failed: "..tostring(err)) end
end
local function setup(p)
 p:SetAttribute("IsTraining",false)
 walkState[p]=nil p.CharacterAdded:Connect(function() TrainingManager.StopTraining(p) end)
end
Players.PlayerAdded:Connect(setup)
for _,p in Players:GetPlayers() do setup(p) end
Players.PlayerRemoving:Connect(function(p) TrainingManager.StopTraining(p); walkState[p]=nil end)Workspace.ChildAdded:Connect(function(c) if c.Name:match("^Tredmill%d%d$") then watchedTreadmill=nil end end)
script:SetAttribute("Initialized",false)
script:SetAttribute("ZoneScanCount",0)
RunService.Heartbeat:Connect(function(dt)
	updateWalkingSteps(dt)

	elapsed += dt
	if elapsed < 0.2 then
		return
	end
	elapsed %= 0.2

	local targetTreadmill = Workspace:FindFirstChild("Tredmill01")
	local treadmill = TrainingManager.GetTreadmill()

	if targetTreadmill and (
		targetTreadmill ~= watchedTreadmill
			or treadmill ~= targetTreadmill
			or not treadmill:IsDescendantOf(Workspace)
		) then
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
return true