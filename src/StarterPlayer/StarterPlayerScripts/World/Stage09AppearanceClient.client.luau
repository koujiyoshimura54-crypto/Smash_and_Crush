-- World1 Stage09 visual only. Published Walk plus Bone-following VFX.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage").Remotes.GameRemotes:WaitForChild("CombatState")
local STAGE = 9
local MODEL_NAME = "Trippa Troppa Tralala Lirilì Rilà TungTung Sahur Boneca TungTung Tralalelo TrippiTroppa Crocodina"
local PART_NAMES = {"tralalafxpart", "tralalafxpart2", "elephantofxpart", "frogfxpart", "sahurfxpart"}

local rig, track, followConnection, destroyConnection
local watched = {}
local follow = {}
local effects = {}
local hidden = true
local refresh

local function stop()
	if followConnection then followConnection:Disconnect(); followConnection = nil end
	if track and track.IsPlaying then track:Stop(0) end
	for emitter in effects do
		if emitter.Parent then emitter.Enabled = false; emitter:Clear() end
	end
end

local function release()
	stop()
	if destroyConnection then destroyConnection:Disconnect(); destroyConnection = nil end
	for _, connection in watched do connection:Disconnect() end
	table.clear(watched)
	if track then track:Destroy(); track = nil end
	for _, item in follow do
		if item.part.Parent then
			item.part.Anchored = item.wasAnchored
			if item.staticWeld and item.staticWeld.Parent then item.staticWeld.Enabled = item.staticWeldEnabled end
			if item.motor and item.motor.Parent then item.motor.Enabled = item.motorEnabled end
		end
	end
	table.clear(follow)
	table.clear(effects)
	rig = nil
end

local function visible()
	if hidden or not rig or not rig:IsDescendantOf(workspace) or (player:GetAttribute("CurrentWorld") or 1) ~= 1 then return false end
	for _, d in rig:GetDescendants() do
		if d:IsA("MeshPart") and d.Transparency < 0.99 and d.LocalTransparencyModifier < 0.99 then return true end
	end
	return false
end

local function bind(current)
	local controller = current:FindFirstChildOfClass("AnimationController")
	local animator = controller and controller:FindFirstChildOfClass("Animator")
	local animation = current:FindFirstChild("Stage09Walk")
	local vfxRoot = current:FindFirstChild("VfxInstance")
	if not animator or not animation or not animation:IsA("Animation") or not vfxRoot then return false end

	local items = {}
	for _, name in PART_NAMES do
		local part
		for _, child in vfxRoot:GetChildren() do
			if child.Name == name and child:IsA("BasePart") then part = child; break end
		end
		local ref = part and part:FindFirstChild("Stage09FollowBone")
		local bone = ref and ref:IsA("ObjectValue") and ref.Value
		local staticWeld = part and part:FindFirstChild("StaticVisualWeld")
		local motor
		for _, child in vfxRoot:GetChildren() do
			if child.Name == name and child:IsA("Motor6D") then motor = child; break end
		end
		if not part or not bone or not bone:IsA("Bone") or not bone:IsDescendantOf(current)
			or not staticWeld or not staticWeld:IsA("WeldConstraint") or not motor then return false end
		table.insert(items, {
			part = part, bone = bone,
			restOffset = bone.WorldCFrame:ToObjectSpace(part.CFrame),
			staticWeld = staticWeld, staticWeldEnabled = staticWeld.Enabled,
			motor = motor, motorEnabled = motor.Enabled, wasAnchored = part.Anchored,
		})
	end

	local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
	if not ok then warn("Stage09Walk load failed: " .. tostring(loaded)); return false end
	track = loaded
	track.Name = "Stage09Walk"
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement
	rig = current

	for _, item in items do
		-- Only detach Stage09's five effect holders on this client.
		-- The invisible VfxInstance and the remaining combat model keep their server welds.
		item.staticWeld.Enabled = false
		item.motor.Enabled = false
		item.part.Anchored = true
		table.insert(follow, item)
		for _, d in item.part:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				local original = d:GetAttribute("StaticVFXEnabled")
				effects[d] = if typeof(original) == "boolean" then original else d.Enabled
			end
		end
	end
	for _, d in current:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(watched, d:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function() task.defer(refresh) end))
			table.insert(watched, d:GetPropertyChangedSignal("Transparency"):Connect(function() task.defer(refresh) end))
		end
	end
	destroyConnection = current.Destroying:Connect(release)
	return true
end

refresh = function()
	local enemies = workspace:FindFirstChild("Enemies")
	local enemy = enemies and enemies:FindFirstChild("Stage09_Enemy")
	local current = enemy and enemy:FindFirstChild(MODEL_NAME)
	if current ~= rig then
		release()
		if current and not bind(current) then return end
	end
	if not rig then return end
	local shown = visible()
	for emitter, originalEnabled in effects do
		if emitter.Parent then
			emitter.Enabled = shown and originalEnabled
			if not shown then emitter:Clear() end
		end
	end
	if not shown then stop(); return end
	if not track.IsPlaying then track:Play(0.15, 1, 1) end
	if not followConnection then
		followConnection = RunService.PreRender:Connect(function()
			if not visible() then stop(); return end
			for _, item in follow do
				if item.part.Parent and item.bone.Parent then
					item.part.CFrame = item.bone.TransformedWorldCFrame * item.restOffset
				end
			end
		end)
	end
end

remote.OnClientEvent:Connect(function(data)
	if data.Type == "Initialize" then
		hidden = (data.Cleared and data.Cleared[STAGE]) == true or (data.Skipped and data.Skipped[STAGE]) == true
	elseif data.Stage == STAGE and data.Type == "BossInitialize" then
		hidden = false
	elseif data.Stage == STAGE and (data.Type == "EnemyDefeated" or data.Type == "StageCleared") then
		hidden = true
	else
		return
	end
	task.defer(refresh)
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() task.defer(refresh) end)
workspace.DescendantAdded:Connect(function(d)
	if d.Name == "Stage09_Enemy" or d.Name == MODEL_NAME or d.Name == "Stage09Walk" then task.defer(refresh) end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type = "RequestState"})
