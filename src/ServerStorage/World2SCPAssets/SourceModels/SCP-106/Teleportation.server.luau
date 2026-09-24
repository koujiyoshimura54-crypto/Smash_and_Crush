



while true do
wait()
local teleportchance = math.random(1,2000)
if teleportchance == 2000 and script.Parent.Mode.Value == 1 then
local teleports = {}
for i,v in pairs(workspace:GetChildren()) do
if v:findFirstChild("Humanoid") and v:findFirstChild("HumanoidRootPart") then
if (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude <= 50 and v.Humanoid.Health > 0 then
if v:findFirstChild("Faction") and v.Faction.Value ~= script.Parent.Faction.Value or v:findFirstChild("Faction") == nil then
if game.Players:findFirstChild(""..v.Name) == nil and script.Parent.HostileToPlayers.Value == false or script.Parent.HostileToPlayers.Value == true then
table.insert(teleports,v.HumanoidRootPart.CFrame)
end
end
end
end
end
if #teleports >= 1 then
local chosenteleport = teleports[math.random(1,#teleports)]
script.Parent.HumanoidRootPart.CFrame = chosenteleport * CFrame.new(math.random(-10,10),0,math.random(-10,10))
end
end
end