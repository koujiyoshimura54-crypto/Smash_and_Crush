--[[ By: Brutez. ]]--
local FreeSCP096AnimationScript=script;
local FreeSCP096=FreeSCP096AnimationScript.Parent
local FreeSCP096Humanoid=nil;
local FreeSCP096Torso=FreeSCP096:FindFirstChild("Torso")
local RightShoulder=FreeSCP096Torso:FindFirstChild("Right Shoulder")
local LeftShoulder=FreeSCP096Torso:FindFirstChild("Left Shoulder")
local RightHip=FreeSCP096Torso:FindFirstChild("Right Hip")
local LeftHip=FreeSCP096Torso:FindFirstChild("Left Hip")
local Neck=FreeSCP096Torso:FindFirstChild("Neck")
local pose="Standing";
for _,Child in pairs(FreeSCP096:GetChildren())do
if Child.ClassName=="Humanoid"then
FreeSCP096Humanoid=Child;
end
end
function onRunning(speed)
if speed>0.001  then
pose = "Running"
else
pose = "Standing"
end
end
function onDied()
pose = "Dead"
end
function onJumping()
pose = "Jumping"
end
function onClimbing()
pose = "Climbing"
end
function onGettingUp()
pose = "GettingUp"
end
function onFreeFall()
pose = "FreeFall"
end
function onFallingDown()
pose = "FallingDown"
end
function onSeated()
pose = "Seated"
end
function moveJump()
RightShoulder.MaxVelocity = 0.5
LeftShoulder.MaxVelocity = 0.5
RightShoulder.DesiredAngle = 3.14
LeftShoulder.DesiredAngle = -3.14
RightHip.DesiredAngle = 0
LeftHip.DesiredAngle = 0
end
function moveFreeFall()
RightShoulder.MaxVelocity = 1
LeftShoulder.MaxVelocity = 1
RightShoulder.DesiredAngle = 4
LeftShoulder.DesiredAngle = -4
RightHip.DesiredAngle = 1
LeftHip.DesiredAngle = 1
end
function moveSit()
RightShoulder.MaxVelocity = 0.15
LeftShoulder.MaxVelocity = 0.15
RightShoulder.DesiredAngle = 3.14 /2
LeftShoulder.DesiredAngle = -3.14 /2
RightHip.DesiredAngle = 1/2
LeftHip.DesiredAngle = -1/2
end
function move(time)
local amplitude
local frequency
if (pose == "Jumping") then
moveJump()
return
end
if (pose == "FreeFall") then
moveFreeFall()
return
end
if (pose == "Seated") then
moveSit()
return
end
local climbFudge = 0
if (pose == "Running") then
RightShoulder.MaxVelocity = 0.2
LeftShoulder.MaxVelocity = 0.2
RightHip.MaxVelocity = 0.2
LeftHip.MaxVelocity = 0.2
if FreeSCP096Humanoid.WalkSpeed~=35 then
amplitude = 0.4
frequency = 4
else
amplitude = 2
frequency = 12
end
elseif (pose == "Climbing") then
RightShoulder.MaxVelocity = 0.3 
LeftShoulder.MaxVelocity = 0.3
RightHip.MaxVelocity = 1
LeftHip.MaxVelocity = 1
amplitude = 0.4
frequency = 6
climbFudge = 3.14
else
amplitude = 0.1
frequency = 1
end
local desiredAngle=amplitude*math.sin(time*frequency);
if FreeSCP096Humanoid.WalkSpeed==1 then --Panic
RightShoulder.MaxVelocity = 0.05
LeftShoulder.MaxVelocity = 0.05
RightShoulder.DesiredAngle = 3.14
LeftShoulder.DesiredAngle = -3.14
end
if FreeSCP096Humanoid.WalkSpeed>10 then
RightShoulder.MaxVelocity = 5
LeftShoulder.MaxVelocity = 5
RightShoulder.DesiredAngle = -1.57
LeftShoulder.DesiredAngle = 1.57
RightHip.MaxVelocity = 3
LeftHip.MaxVelocity =3
end
if FreeSCP096Humanoid.WalkSpeed~=1 and FreeSCP096Humanoid.WalkSpeed~=35 then
RightShoulder.DesiredAngle=desiredAngle+climbFudge;
LeftShoulder.DesiredAngle=desiredAngle-climbFudge;
end
RightHip.DesiredAngle = -desiredAngle
LeftHip.DesiredAngle = -desiredAngle
end
FreeSCP096Humanoid.Died:connect(onDied)
FreeSCP096Humanoid.Running:connect(onRunning)
FreeSCP096Humanoid.Jumping:connect(onJumping)
FreeSCP096Humanoid.Climbing:connect(onClimbing)
FreeSCP096Humanoid.GettingUp:connect(onGettingUp)
FreeSCP096Humanoid.FreeFalling:connect(onFreeFall)
FreeSCP096Humanoid.FallingDown:connect(onFallingDown)
FreeSCP096Humanoid.Seated:connect(onSeated)
local nextTime=0
local runService=game:service("RunService");
while Wait(0)do
local time=runService.Stepped:wait(0);
if time>nextTime then
move(time);
nextTime=time;
end;
end;
--[[ By: Brutez. ]]--