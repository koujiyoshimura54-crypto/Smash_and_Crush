



while true do
wait()
if script.Parent.Mode.Value == 1 then
local mindist = 25
local targetfound = false
for i,v in pairs(workspace:GetChildren()) do
if v:findFirstChild("Humanoid") and v:findFirstChild("HumanoidRootPart") then
if v:findFirstChild("Faction") and v.Faction.Value ~= script.Parent.Faction.Value or v:findFirstChild("Faction") == nil then
if (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude <= mindist and v.Humanoid.Health > 0 then
if game.Players:findFirstChild(""..v.Name) == nil and script.Parent.HostileToPlayers.Value == false or script.Parent.HostileToPlayers.Value == true then
targetfound = true
mindist = (v.HumanoidRootPart.Position - script.Parent.HumanoidRootPart.Position).magnitude
end
end
end
end
end
if targetfound then
script.Parent.Humanoid.WalkSpeed = 0
script.Parent.HumanoidRootPart.CFrame = script.Parent.HumanoidRootPart.CFrame * CFrame.new(0,-5,0)
script.Parent.HumanoidRootPart.Anchored = true
local particle = Instance.new("Part")
particle.Parent = workspace
particle.Name = "Corrosion"
particle.Anchored = true
particle.CanCollide = false
particle.Transparency = 1
particle.TopSurface = "Smooth"
particle.BottomSurface = "Smooth"
particle.Size = Vector3.new(1,0.5,1)
particle.CFrame = script.Parent.HumanoidRootPart.CFrame * CFrame.new(0,2,0)
local particledecal = Instance.new("Decal")
particledecal.Parent = particle
particledecal.Face = "Top"
particledecal.Texture = "http://www.roblox.com/asset/?id=129418678"
local decay = Instance.new("Sound")
decay.Parent = script.Parent.HumanoidRootPart
decay.Volume = 1
decay.SoundId = "rbxassetid://4741993972"
decay.Name = "Decay"
decay:Play()
for i = 1,200 do
wait()
particle.Size = particle.Size + Vector3.new(0.1,0,0.1)
script.Parent.HumanoidRootPart.CFrame = script.Parent.HumanoidRootPart.CFrame * CFrame.new(0,0.025,0)
end
decay:Destroy()
local voice = Instance.new("Sound")
voice.Parent = script.Parent.Head
voice.Volume = 1
voice.SoundId = "rbxassetid://177359995"
voice.Name = "Laugh"
voice:Play()
voice.Ended:wait()
voice:Destroy()
script.Parent.HumanoidRootPart.Anchored = false
local voice = Instance.new("Sound")
voice.Parent = script.Parent.Head
voice.Volume = 1
voice.SoundId = "rbxassetid://2388641039"
voice.Name = "Voice"
voice:Play()
voice.Looped = true
local music = Instance.new("Sound")
music.Parent = script.Parent.HumanoidRootPart
music.Volume = 1
music.SoundId = "rbxassetid://649587991"
music.Name = "Music"
music:Play()
music.Looped = true
script.Parent.Mode.Value = 2
end
end
end