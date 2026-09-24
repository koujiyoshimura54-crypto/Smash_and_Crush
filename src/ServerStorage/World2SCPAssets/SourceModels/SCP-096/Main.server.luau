--[[ By: Brutez. ]]--
local FreeSCP096Script=script;
local FreeSCP096=FreeSCP096Script.Parent;
local FreeSCP096Humanoid=nil;
local FreeSCP096Head=FreeSCP096:FindFirstChild("Head");
local FreeSCP096Idle=FreeSCP096Head:FindFirstChild("Idle");
local FreeSCP096Panic=FreeSCP096Head:FindFirstChild("Panic");
local FreeSCP096Scream=FreeSCP096Head:FindFirstChild("Scream");
local FreeSCP096Kill=FreeSCP096Head:FindFirstChild("Damage5");
local FreeSCP096Torso=FreeSCP096:FindFirstChild("Torso");
for _,Child in pairs(FreeSCP096:GetChildren())do
if Child.ClassName=="Humanoid"then
FreeSCP096Humanoid=Child;
end
end
local NoticeDistanceTime=0;
local Noticed=false;
function findNearestTorso(pos)
local NoticeDistance=250;
local torso=nil;
for _,TargetModel in pairs(Game:GetService("Workspace"):GetChildren())do
if TargetModel.className=="Model"and TargetModel~=FreeSCP096 and TargetModel:FindFirstChild("HumanoidRootPart")and TargetModel:FindFirstChild("Head")then
local TargetPart=TargetModel:FindFirstChild("HumanoidRootPart")
local FoundHumanoid=nil;
for _,Child in pairs(TargetModel:GetChildren())do
if Child.ClassName=="Humanoid"then
FoundHumanoid=Child;
end
end
if TargetPart and FoundHumanoid and FoundHumanoid.Health>0 and(TargetPart.Position-pos).magnitude<NoticeDistance then
if not Noticed and TargetPart and FoundHumanoid and FoundHumanoid.Health>0 and(TargetPart.Position-pos).magnitude<20 then
if FreeSCP096Idle.IsPlaying then
FreeSCP096Idle:Stop()
end
if FreeSCP096Scream.IsPlaying then
FreeSCP096Scream:Stop()
end
FreeSCP096Panic:Play()
FreeSCP096Humanoid.WalkSpeed=1;
Wait(30.5)
Noticed=true
end
if Noticed then
torso=TargetPart;
NoticeDistance=(TargetPart.Position-pos).magnitude;
end;
end;
if TargetPart and FoundHumanoid and FoundHumanoid.Health>0 and(TargetPart.Position-pos).magnitude<6 then
FreeSCP096Kill:Play()
FoundHumanoid:TakeDamage(99999e99999)
end
end
end
return torso
end
while Wait(0)do
FreeSCP096Humanoid.MaxHealth=99999e99999
FreeSCP096Humanoid.Health=99999e99999
if FreeSCP096Humanoid and not FreeSCP096Humanoid.AutoJumpEnabled then
FreeSCP096Humanoid.AutoJumpEnabled=true;
end
if FreeSCP096Humanoid and not FreeSCP096Humanoid.AutoRotate then
FreeSCP096Humanoid.AutoRotate=true;
end
if FreeSCP096Humanoid and FreeSCP096Humanoid.PlatformStand then
FreeSCP096Humanoid.PlatformStand=false;
end
if FreeSCP096Humanoid and FreeSCP096Humanoid.Sit then
FreeSCP096Humanoid.Sit=false;
end
if Noticed then
NoticeDistanceTime=NoticeDistanceTime+1
if NoticeDistanceTime==500 or NoticeDistanceTime>500 then
Noticed=false;
NoticeDistanceTime=0
end
end
local TargetPart=findNearestTorso(FreeSCP096Torso.Position);
if TargetPart then
if TargetPart and (TargetPart.Position-FreeSCP096Torso.Position).magnitude<50 and NoticeDistanceTime>0 then
NoticeDistanceTime=NoticeDistanceTime-2
end
if FreeSCP096Idle.IsPlaying then
FreeSCP096Idle:Stop()
end
if not FreeSCP096Scream.IsPlaying then
FreeSCP096Scream:Play()
end
FreeSCP096Humanoid.WalkSpeed=35;
FreeSCP096Humanoid:MoveTo(TargetPart.Position+Vector3.new(math.random(-4,4),TargetPart.Position.Y,math.random(-4,4)),TargetPart);
else
if not FreeSCP096Idle.IsPlaying then
FreeSCP096Idle:Play()
end
if FreeSCP096Scream.IsPlaying then
FreeSCP096Scream:Stop()
end
FreeSCP096Humanoid.WalkSpeed=10;
local WanderChance=math.random(1,50);
local JumpChance=math.random(1,100);
if WanderChance==10 then
local randompos=FreeSCP096Torso.Position+((Vector3.new(1,0,1)*math.random()-Vector3.new(.5,0,.5))*40);
FreeSCP096Humanoid:MoveTo(randompos,game.Workspace.Terrain);
end
if JumpChance==10 then
FreeSCP096Humanoid.Jump=true;
end
end
end
--[[ By: Brutez. ]]--