local SCP049=script.Parent;
local SCP049Humanoid = SCP049:FindFirstChild("Humanoid");
local SCP049WalkAnimation = SCP049Humanoid:LoadAnimation(SCP049.WalkAnim);
repeat Wait(0.5) until SCP049Humanoid ~= nil
function SCP049Walk(WalkSpeed)
if WalkSpeed>0.05 then
SCP049WalkAnimation:Play()
else
SCP049WalkAnimation:Stop()
end
end
SCP049Humanoid.Running:connect(SCP049Walk)