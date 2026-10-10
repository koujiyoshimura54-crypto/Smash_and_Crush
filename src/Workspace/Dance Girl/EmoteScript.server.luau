-- Original supplied dance ID (SMARTGAMER0007's EmoteScript); no replacement dance.
local ANIMATION_ID = "rbxassetid://15122972413"
local RUNNING_ATTRIBUTE = "DanceGirlPlaybackRunning"
local model = script.Parent
if model:GetAttribute(RUNNING_ATTRIBUTE) then return end
model:SetAttribute(RUNNING_ATTRIBUTE, true)

local animation, track
local createdAnimation = false
local connections = {}
local finished = false
local function cleanup()
	if finished then return end
	finished = true
	for _, connection in ipairs(connections) do connection:Disconnect() end
	if track then track:Stop(0); track:Destroy() end
	if createdAnimation and animation then animation:Destroy() end
	model:SetAttribute(RUNNING_ATTRIBUTE, nil)
end

table.insert(connections, script.Destroying:Connect(cleanup))
table.insert(connections, script:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not script.Enabled then cleanup() end
end))
table.insert(connections, model.AncestryChanged:Connect(function()
	if not model:IsDescendantOf(workspace) then cleanup() end
end))

local ok, reason = pcall(function()
	local humanoid = model:WaitForChild("Humanoid", 10)
	assert(humanoid and humanoid:IsA("Humanoid"), "Humanoid missing")
	local animator = humanoid:WaitForChild("Animator", 10)
	assert(animator and animator:IsA("Animator"), "Animator missing")
	if finished then return end

	-- The supplied Script had no Animation child and never used its animationid variable.
	animation = script:FindFirstChild("Animation")
	if animation then
		assert(animation:IsA("Animation"), "Animation child has the wrong class")
		assert(animation.AnimationId == "" or animation.AnimationId == ANIMATION_ID,
			"Animation child differs from the supplied dance; refusing to replace it")
	else
		animation = Instance.new("Animation")
		animation.Name = "Animation"
		createdAnimation = true
		animation.Parent = script
	end
	animation.AnimationId = ANIMATION_ID

	-- Reuse an existing copy of this dance and retire only duplicate copies of it.
	for _, existing in ipairs(animator:GetPlayingAnimationTracks()) do
		if existing.Animation and existing.Animation.AnimationId == ANIMATION_ID then
			if not track then track = existing else existing:Stop(0); existing:Destroy() end
		end
	end
	if not track then track = animator:LoadAnimation(animation) end
	if finished then track:Stop(0); track:Destroy(); return end
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Action
	if not track.IsPlaying then track:Play(0.1) end
end)

if not ok then
	cleanup()
	warn("[Dance Girl] Could not start supplied animation " .. ANIMATION_ID .. ": " .. tostring(reason))
end
