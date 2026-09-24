local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ServerStorage = game:GetService("ServerStorage")

local model = script.Parent
local controller = model:WaitForChild("AnimationController")
local animator = controller:WaitForChild("Animator")
local sequence = ServerStorage
	:WaitForChild("RBX_ANIMSAVES")
	:WaitForChild("Cas_Roblox")
	:WaitForChild("rig|Quadruped_Walk_Roblox_24")

local ok, animationId = pcall(function()
	return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
end)
if not ok then
	warn("Embedded quadruped walk registration failed:", animationId)
	return
end

local animation = Instance.new("Animation")
animation.Name = "Quadruped_Walk_Roblox_24_Runtime"
animation.AnimationId = animationId

local track = animator:LoadAnimation(animation)
track.Looped = true
track:Play(0.1, 1, 1)
track:AdjustSpeed(1)
model:SetAttribute("EmbeddedWalkPlaying", true)
model:SetAttribute("EmbeddedWalkAnimation", sequence.Name)
