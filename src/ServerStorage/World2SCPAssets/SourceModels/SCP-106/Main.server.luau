



while true do
wait()
if script.Parent.Mode.Value == 2 then
local mindist = math.huge
local target = nil
for i,v in pairs(workspace:GetChildren()) do
if v:findFirstChild("Humanoid") and v:findFirstChild("HumanoidRootPart") then
if v:findFirstChild("Faction") and v.Faction.Value ~= script.Parent.Faction.Value or v:findFirstChild("Faction") == nil then
if (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude <= mindist and v.Humanoid.Health > 0 then
if game.Players:findFirstChild(""..v.Name) == nil and script.Parent.HostileToPlayers.Value == false or script.Parent.HostileToPlayers.Value == true then
target = v
mindist = (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude
end
end
end
end
end
if target then
script.Parent.Humanoid.WalkSpeed = 8
script.Parent.HumanoidRootPart.CFrame = (script.Parent.HumanoidRootPart.CFrame + script.Parent.HumanoidRootPart.CFrame.lookVector * (script.Parent.Humanoid.WalkSpeed / 100))
script.Parent.HumanoidRootPart.CFrame = CFrame.new(script.Parent.HumanoidRootPart.Position,target.HumanoidRootPart.Position)
script.Parent.Humanoid:MoveTo(target.HumanoidRootPart.Position)
end
end
end