local SCP049MainScript = script;
local SCP049 = SCP049MainScript.Parent;
local Head = SCP049:FindFirstChild("Head");
local HumanoidRootPart = SCP049:FindFirstChild("HumanoidRootPart");
local LeftArm = SCP049:FindFirstChild("Left Arm");
local LeftLeg = SCP049:FindFirstChild("Left Leg");
local RightArm = SCP049:FindFirstChild("Right Arm");
local RightLeg = SCP049:FindFirstChild("Right Leg");
local Torso = SCP049:FindFirstChild("Torso");
local SCP049Humanoid = SCP049:FindFirstChild("Humanoid");
local RechargeTime = 0;
for SCP049HealthCheck = 1,5 do
SCP049Humanoid.Health = SCP049Humanoid.MaxHealth
Wait(0)
end
local SpawnForceField = Instance.new("ForceField")
SpawnForceField.Name = "SpawnForceField"
SpawnForceField.Parent = SCP049
function FindTargetToTerrorise(TargetPosition)
local PlayerList = Game.Workspace:children();
local TargetTorso = nil;
local VisibleDistance = 13337777777;
local TempTargetModel = nil;
local TargetHumanoid = nil;
local TargetModel = nil;
for Check = 1, #PlayerList do
TargetModel = PlayerList[Check]
if (TargetModel.className == "Model") and (TargetModel ~= SCP049) and (TargetModel.Name ~= SCP049.Name) and (TargetModel.Name ~= "SCP-106") and (TargetModel.Name ~= "SCP-173") and (TargetModel.Name ~= "SCP-096") then
TempTargetModel = TargetModel:FindFirstChild("Torso")
TargetHumanoid = TargetModel:FindFirstChild("Humanoid")
if (TempTargetModel ~= nil) and (TargetHumanoid ~= nil) and (TargetHumanoid.Health > 0) then
if (TempTargetModel.Position - TargetPosition).magnitude < VisibleDistance then
TargetTorso = TempTargetModel
VisibleDistance = (TempTargetModel.Position - TargetPosition).magnitude
end
end
end
end
return TargetTorso
end
Wait(5)
for SCP049HealthCheck = 1,5 do
SCP049Humanoid.Health = SCP049Humanoid.MaxHealth
Wait(0)
end
HumanoidRootPart.Anchored = false
SpawnForceField:Destroy()
while true do
Wait(0)
if SCP049Humanoid.Health == 0 or SCP049Humanoid.Health < 0 then
SCP049["SCP049AttackScript"].Disabled = true
SCP049["SCP049TargetScript"].Disabled = true
SCP049["SCP049HeadSoundScript"].Disabled = true
Wait(5)
SCP049:Destroy()
end
local SCP049ChosenTarget = FindTargetToTerrorise(Torso.Position);
if SCP049Humanoid.Sit==true then
SCP049Humanoid.Jump=true
end
if SCP049Humanoid.PlatformStand==true then
SCP049Humanoid.Jump=true
end
if SCP049ChosenTarget ~= nil then
SCP049RadiusXAxis = math.random(-2,2)
SCP049RadiusYAxis = math.random(-2,2)
SCP049RadiusZAxis = math.random(-2,2)
SCP049Humanoid:MoveTo(SCP049ChosenTarget.Position+Vector3.new(SCP049RadiusXAxis,SCP049RadiusYAxis,SCP049RadiusZAxis), SCP049ChosenTarget)
end
end