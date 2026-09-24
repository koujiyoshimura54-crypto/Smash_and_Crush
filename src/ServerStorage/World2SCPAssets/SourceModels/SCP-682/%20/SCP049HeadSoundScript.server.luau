--[[ By: Brutez ]]--
local SCP049 = script.Parent;
local SCP049Head = SCP049:FindFirstChild("Head");
local SelectedSoundID = {187645728, 187645755, 187645778};
local SelectedSounds = {};
local HurtEnable = true;
while true do
Wait(0)
SCP049RandomSound=math.random(1,1000)
if SCP049RandomSound==10 or SCP049RandomSound==20 or SCP049RandomSound==30 then
if HurtEnable==false then return end
HurtEnable = false;
local SCP049HurtSoundList = {"049_1", "049_2", "049_3", "049_4", "049_5", "049_6", "049_7", "049_8"};
local SelectedHurtSound = SCP049Head[math.random(1, #SCP049HurtSoundList)];
SelectedHurtSound:Play()
Wait(4)
HurtEnable = true;
end 
end
--[[ By: Brutez ]]--