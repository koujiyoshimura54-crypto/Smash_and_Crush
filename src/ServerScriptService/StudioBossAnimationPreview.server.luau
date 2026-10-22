-- A Studio-only inspection tool. Never runs an imported script or a combat service.
if not game:GetService("RunService"):IsStudio() then return end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local templates = game:GetService("ServerStorage"):WaitForChild("EnemyTemplates"):WaitForChild("World2SCPDisplays")
local stages = {
	[1] = {"SCP-096", "SCP096_Display", "MainAnimation is absent from this file's template."},
	[3] = {"SCP-035", "SCP035_Display", "Animate and its child Animation overrides are absent from this template."},
	[5] = {"SCP-049", "SCP049_Display", "Only the Animation objects and saved clips present in this template are listed."},
	[6] = {"SCP-173", "SCP173_Display", "No Animation, Humanoid or Motor6D exists in this static template."},
	[8] = {"SCP-106", "SCP106_Display", "Humanoid exists; no Animation or joint-animation script is present."},
	[10] = {"SCP-323", "SCP323_Display", "Animate and Stunned are absent from this file's template."},
}

local root = Instance.new("Folder")
root.Name = "StudioBossAnimationPreview"
root.Parent = RS
local request = Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = root
local sessions = {}

local function relative(instance, ancestor)
	local path = {}
	while instance ~= ancestor do
		table.insert(path, 1, instance.Name)
		instance = instance.Parent
	end
	return path
end

local function removeModel(session)
	if session.Container then session.Container:Destroy(); session.Container = nil end
end

local function staticClip(frames)
	local reference
	for _, frame in frames do
		local poses = {}
		for _, pose in frame:GetDescendants() do
			if pose:IsA("Pose") and pose.Weight > 0 then
				local components = {pose.CFrame:GetComponents()}
				for i, value in components do components[i] = string.format("%.6f", value) end
				table.insert(poses, table.concat(relative(pose, frame), "/") .. ":" .. pose.Weight .. ":" .. table.concat(components, ","))
			end
		end
		table.sort(poses)
		local signature = table.concat(poses, "|")
		if reference and reference ~= signature then return false end
		reference = signature
	end
	return #frames > 0
end

request.OnServerInvoke = function(player, action, epoch, stage)
	if not game:GetService("RunService"):IsStudio() or player.Parent ~= Players then return {Error = "Studio only"} end
	if type(epoch) ~= "number" or epoch % 1 ~= 0 or epoch < 1 or epoch > 1e9 then return {Error = "Invalid preview request"} end
	local session = sessions[player] or {Epoch = 0}
	sessions[player] = session
	if epoch <= session.Epoch then return {Error = "Preview request retired"} end
	session.Epoch = epoch
	removeModel(session)
	if action == "Close" then return {Closed = true} end
	local entry = stages[stage]
	if action ~= "Select" or not entry then return {Error = "Unknown preview Boss"} end
	local template = templates:FindFirstChild(entry[2])
	if not template or not template:IsA("Model") then return {Error = "Boss template is missing: " .. entry[2]} end
	local model = template:Clone()
	model.Name = "Template"
	require(RS.Modules.World2BossRig).Prepare(model,stage)
	-- Templates are currently script-free. Defend against later imported additions too.
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("LayerCollector")
			or item:IsA("ProximityPrompt") or item:IsA("ClickDetector") then item:Destroy() end
	end
	-- 確認用の複製にだけWalk候補を追加
	local walkCandidates = {
		{"Walk候補 R15", "rbxassetid://507777826"},
		{"Walk候補 R6", "rbxassetid://125749145"},
	}

	for _, entry in ipairs(walkCandidates) do
		local animation = Instance.new("Animation")
		animation.Name = entry[1]
		animation.AnimationId = entry[2]
		animation.Parent = model
	end

	local candidates, ids = {}, {}
	local motors, humanoids = 0, 0
	for _, item in model:GetDescendants() do
		if item:IsA("Motor6D") and item.Part0 and item.Part1 then motors += 1 end
		if item:IsA("Humanoid") then humanoids += 1 end
		if item:IsA("Animation") or item:IsA("KeyframeSequence") then
			local path = relative(item, model)
			local original = template:GetFullName() .. "." .. table.concat(path, ".")
			if item:IsA("Animation") then
				local id = item.AnimationId:match("%d+")
				if id then
					local previous = ids[id]
					if previous then previous.Name ..= " / " .. item.Name; previous.Source ..= "\n" .. original
					else
						local row = {Name = item.Name, Kind = "Asset", Id = item.AnimationId, Source = original, Path = path}
						ids[id] = row; table.insert(candidates, row)
					end
				end
			else
				local frames, duration = item:GetKeyframes(), 0
				for _, frame in frames do duration = math.max(duration, frame.Time) end
				table.insert(candidates, {Name = item.Name, Kind = "KeyframeSequence", Source = original,
					Path = path, Frames = #frames, Duration = duration, Loop = item.Loop, Static = staticClip(frames)})
			end
		end
	end
	table.sort(candidates, function(a, b) return a.Name < b.Name end)
	local container = Instance.new("Folder")
	container.Name = tostring(player.UserId)
	model.Parent = container
	container.Parent = root
	session.Container = container
	return {Boss = entry[1], Stage = stage, Note = entry[3], Candidates = candidates,
		Container = container.Name, Motors = motors, Humanoids = humanoids, Template = template:GetFullName()}
end

Players.PlayerRemoving:Connect(function(player)
	local session = sessions[player]
	if session then removeModel(session); sessions[player] = nil end
end)
script.Destroying:Connect(function() root:Destroy() end)
