killsounds = {'347611423'}








while script.Parent.Humanoid.Health > 0 do
wait()
for i,v in pairs(workspace:GetChildren()) do
delay(0,function()
if v:findFirstChild("Humanoid") and v:findFirstChild("HumanoidRootPart") and v ~= script.Parent then
if (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude <= 5 and v.Humanoid.Health > 0 then
if v:findFirstChild("Faction") and v.Faction.Value ~= script.Parent.Faction.Value or v:findFirstChild("Faction") == nil then
if script.Parent.Humanoid.Health > 0 and script.Parent.Humanoid.WalkSpeed > 0 then
v.Humanoid:TakeDamage(v.Humanoid.Health)
wait()
if v.Humanoid.Health == 0 then
local kill = Instance.new("Sound")
kill.Name = "Kill"
kill.Parent = script.Parent.HumanoidRootPart
kill.Volume = 1
kill.SoundId = "rbxassetid://"..killsounds[math.random(1,#killsounds)]
kill:Play()
kill.Ended:wait()
kill:Destroy()
end
end
end
end
end
end)
end
end