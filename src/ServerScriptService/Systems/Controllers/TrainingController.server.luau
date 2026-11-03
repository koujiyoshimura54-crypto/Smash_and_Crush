local CollectionService=game:GetService("CollectionService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local TrainingManager=require(game.ServerScriptService.Services:WaitForChild("TrainingManager"))
local initializing,registryDirty=false,true
local TREADMILL_TAG="TrainingTreadmill"
local elapsed=0


local AutoTap=require(game.ServerScriptService.Services:WaitForChild("AutoTapService"))
local function updateAutomaticActions()
 for _,player in Players:GetPlayers() do AutoTap.TryAutomatic(player) end
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
 p:GetAttributeChangedSignal("CurrentWorld"):Connect(function() TrainingManager.StopTraining(p) end)
 p.CharacterAdded:Connect(function() TrainingManager.StopTraining(p) end)
end
Players.PlayerAdded:Connect(setup)
for _,p in Players:GetPlayers() do setup(p) end
Players.PlayerRemoving:Connect(function(p) TrainingManager.StopTraining(p) end)
CollectionService:GetInstanceAddedSignal(TREADMILL_TAG):Connect(function() registryDirty=true end)
CollectionService:GetInstanceRemovedSignal(TREADMILL_TAG):Connect(function() registryDirty=true end)
script:SetAttribute("Initialized",false)
script:SetAttribute("ZoneScanCount",0)
local zoneScanCount=0
RunService.Heartbeat:Connect(function(dt)
 updateAutomaticActions()
 elapsed+=dt
 if elapsed>=0.2 then
  elapsed%=0.2
  local treadmill=TrainingManager.GetTreadmill()
  if registryDirty or #TrainingManager.GetTreadmills()~=#CollectionService:GetTagged(TREADMILL_TAG)
   or (treadmill and not treadmill:IsDescendantOf(Workspace)) then
   initialize()
  end
  if script:GetAttribute("Initialized")==true then
   TrainingManager.UpdateAvailability()
  end
  script:SetAttribute("ZoneScanCount",zoneScanCount)
 end

 -- Only the cached registered treadmills are tested here, never Workspace scans.
 if script:GetAttribute("Initialized")==true then
  TrainingManager.UpdateZoneOccupants()
  zoneScanCount+=1
 end
end)
