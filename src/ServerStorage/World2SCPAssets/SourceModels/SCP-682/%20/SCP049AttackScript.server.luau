local SCP049MainScript = script;
local SCP049 = SCP049MainScript.Parent;
local SCP049Humanoid = SCP049:FindFirstChild("Humanoid")
local Head = SCP049:FindFirstChild("Head");
local HumanoidRootPart = SCP049:FindFirstChild("HumanoidRootPart");
local LeftArm = SCP049:FindFirstChild("Left Arm");
local LeftLeg = SCP049:FindFirstChild("Left Leg");
local RightArm = SCP049:FindFirstChild("Right Arm");
local RightLeg = SCP049:FindFirstChild("Right Leg");
local Torso = SCP049:FindFirstChild("Torso");
local NeckSnapAnimation = SCP049Humanoid:LoadAnimation(SCP049.ArmOutAnim);
local SCP049AttackEnable = true;
function FindTargetToTerrorise(TargetPosition)
local PlayerList = Game.Workspace:children();
local TargetTorso = nil;
local VisibleDistance = 5;
local TempTargetModel = nil;
local TargetHumanoid = nil;
local TargetModel = nil;
for Check = 1, #PlayerList do
TargetModel = PlayerList[Check]
if (TargetModel.className == "Model") and (TargetModel ~= SCP049) and (TargetModel.Name ~= SCP049.Name) and (TargetModel.Name ~= "SCP-106") and (TargetModel.Name ~= "SCP-173") and (TargetModel.Name ~= "SCP-096") then
TempTargetModel = TargetModel:findFirstChild("Torso")
TargetHumanoid = TargetModel:findFirstChild("Humanoid")
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
while true do
Wait(0)
local SCP049ChosenTarget = FindTargetToTerrorise(Head.Position);
if SCP049ChosenTarget ~= nil then
if SCP049AttackEnable == false then return end
SCP049AttackEnable = false
local SCP049Damage = 70
local SelectedAttackList = {"NeckSnap1", "NeckSnap2", "NeckSnap3"};
local SelectedAttackSound = Torso[math.random(1, #SelectedAttackList)];
SelectedAttackSound:Play()
SCP049ChosenTarget.Parent.Humanoid:TakeDamage(SCP049Damage)
NeckSnapAnimation:Play()
Wait(0.5)
NeckSnapAnimation:Stop()
SCP049AttackEnable = true
end
end