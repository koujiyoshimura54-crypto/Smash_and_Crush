-- The entire panel, input handling and model lifetime are limited to Studio Play.
local Run = game:GetService("RunService")
if not Run:IsStudio() then return end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local assets = RS:WaitForChild("StudioBossAnimationPreview", 15)
if not assets then warn("[BossAnimationPreview] Studio preview service unavailable"); return end
local remote = assets:WaitForChild("Request")
local gui = Instance.new("ScreenGui")
gui.Name = "StudioBossAnimationPreviewGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function create(class, name, parent, properties)
	local object = Instance.new(class)
	object.Name = name
	for key, value in properties do object[key] = value end
	object.Parent = parent
	return object
end
local function label(name, parent, text, position, size)
	return create("TextLabel", name, parent, {Text = text, Position = position, Size = size,
		BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235, 240, 247), Font = Enum.Font.Gotham,
		TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
end
local callbacks = {}
local function button(name, parent, text, position, size, callback)
	local b = create("TextButton", name, parent, {Text = text, Position = position, Size = size,
		BackgroundColor3 = Color3.fromRGB(48, 62, 82), TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = true})
	create("UICorner", "Corner", b, {CornerRadius = UDim.new(0, 5)})
	b.MouseButton1Down:Connect(function() b.BackgroundTransparency = .2 end)
	b.MouseButton1Up:Connect(function() b.BackgroundTransparency = 0 end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency = 0 end)
	callbacks[b] = callback
	b.Destroying:Once(function() callbacks[b] = nil end)
	return b
end

local panel = create("Frame", "Panel", gui, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromScale(.97, .95), BackgroundColor3 = Color3.fromRGB(22, 28, 39), Visible = false, Active = true})
create("UICorner", "Corner", panel, {CornerRadius = UDim.new(0, 9)})
label("Title", panel, "World2 Boss Animation Preview  |  STUDIO ONLY", UDim2.fromOffset(12, 5), UDim2.new(1, -90, 0, 30))
local view = create("ViewportFrame", "View", panel, {Position = UDim2.fromOffset(202, 42), Size = UDim2.new(1, -214, 1, -186),
	BackgroundColor3 = Color3.fromRGB(45, 50, 59), Ambient = Color3.fromRGB(180, 180, 180), LightColor = Color3.new(1, 1, 1),
	LightDirection = Vector3.new(-1, -1, -1), Active = true})
local camera = Instance.new("Camera")
camera.FieldOfView = 35
camera.Parent = view
view.CurrentCamera = camera
local source = label("Source", panel, "Select a Boss and an existing animation.", UDim2.new(0, 202, 1, -102), UDim2.new(1, -214, 0, 49))
source.TextSize = 12
source.TextYAlignment = Enum.TextYAlignment.Top
local status = label("Status", panel, "No game data or combat state is changed.", UDim2.new(0, 12, 1, -48), UDim2.new(1, -24, 0, 42))
local list = create("ScrollingFrame", "Animations", panel, {Position = UDim2.fromOffset(12, 308), Size = UDim2.new(0, 178, 1, -366),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y})
create("UIListLayout", "Layout", list, {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
label("AnimationsTitle", panel, "Existing animations", UDim2.fromOffset(12, 281), UDim2.fromOffset(178, 23))

local epoch, playEpoch, speed = 0, 0, 1
local template, model, world, track, metadata, selected, monitor, logConnection
local stageSelected = 1
local angle = "Front"
local basis, center, radius = CFrame.new(), Vector3.zero, 4
local previewCorners = {}
local bossButtons, candidateButtons, speedButtons = {}, {}, {}
local launch
local function message(text, failed)
	status.Text = text
	status.TextColor3 = failed and Color3.fromRGB(255, 176, 151) or Color3.fromRGB(188, 239, 205)
end
local function cleanModel()
	playEpoch += 1
	if monitor then monitor:Disconnect(); monitor = nil end
	if logConnection then logConnection:Disconnect(); logConnection = nil end
	if track then pcall(function() track:Stop(0); track:Destroy() end); track = nil end
	if world then world:Destroy(); world = nil end
	model = nil
end
local function aim()
	local direction = angle == "Side" and basis.RightVector or (angle == "Back" and -basis.LookVector or basis.LookVector)
	local aspect = math.max(.25, view.AbsoluteSize.X / math.max(1, view.AbsoluteSize.Y))
	local halfFov = math.atan(math.tan(math.rad(camera.FieldOfView / 2)) * math.min(1, aspect))
	local distance = radius / math.sin(halfFov) * 1.12
	if stageSelected == "New682" then
		-- Fit the imported long tail in each view instead of shrinking its frontal legs.
		local orientation = CFrame.lookAt(center + direction, center)
		local tanY = math.tan(math.rad(camera.FieldOfView / 2))
		distance = 1
		for _, corner in previewCorners do
			local offset = corner - center
			local depth = offset:Dot(direction)
			distance = math.max(distance, depth + math.abs(offset:Dot(orientation.RightVector)) / (tanY * aspect) * 1.15,
				depth + math.abs(offset:Dot(orientation.UpVector)) / tanY * 1.15)
		end
	end
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
end
local function rebuild()
	cleanModel()
	if not template or not template.Parent then message("Preview template unavailable. Select the Boss again.", true); return false end
	model = template:Clone()
	world = Instance.new("WorldModel")
	world.Name = "PreviewWorld"
	world.Parent = view
	local min, max = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	table.clear(previewCorners)
	for _, item in model:GetDescendants() do
		if item:IsA("LuaSourceContainer") or item:IsA("Sound") then item:Destroy()
		elseif item:IsA("BasePart") then
			-- Imported loose eye decorations stay anchored; do not weld its hidden limbs solid.
			item.Anchored = item.Name == "HumanoidRootPart" or item.Name == "DisplayRoot"
				or (stageSelected == "New682" and item.Anchored)
			item.CanCollide = false; item.CanTouch = false; item.CanQuery = false
		elseif item:IsA("Humanoid") then
			item.EvaluateStateMachine = false; item.BreakJointsOnDeath = false; item.RequiresNeck = false
		end
	end
	model:PivotTo(CFrame.new())
	model.Parent = world
	local root = model:FindFirstChild("HumanoidRootPart", true)
	basis = root and root.CFrame.Rotation or CFrame.new()
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") or part.Transparency >= .99 then continue end
		local mesh=part:FindFirstChildOfClass("SpecialMesh")
  local meshSize=mesh and require(RS.Config.World2BossVisualConfig).FileMeshSizes[mesh.MeshId]
  local extent=meshSize and meshSize*mesh.Scale or part.Size
  local offset=meshSize and mesh.Offset or Vector3.zero
  for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local corner = part.CFrame:PointToWorldSpace(offset+extent * Vector3.new(x, y, z) / 2)
			table.insert(previewCorners, corner)
			min = min:Min(corner); max = max:Max(corner)
		end end end
	end
	if min.X == math.huge then message("No visible parts found in the current template.", true); return false end
	center = (min + max) / 2; radius = math.max(1, (max - min).Magnitude / 2)
 if stageSelected==2 or stageSelected==4 or stageSelected==6 or stageSelected==7 or stageSelected==9 or stageSelected=="New682" then
  local floor=Instance.new("Part");floor.Name="PreviewFloorGuide";floor.Anchored=true;floor.CanCollide=false
  floor.Size=Vector3.new((max.X-min.X)*1.5,.02,(max.Z-min.Z)*1.5)
  floor.CFrame=CFrame.new(center.X,min.Y-.01,center.Z);floor.Color=Color3.fromRGB(95,100,110);floor.Transparency=.65;floor.Parent=world
 end
	aim()
	return true
end
local function findRelative(path)
	local object = model
	for _, name in path do object = object and object:FindFirstChild(name) end
	return object
end
local function describe(candidate)
	return candidate.Name .. "  |  " .. (candidate.Id or "saved KeyframeSequence") .. "\n" .. candidate.Source
end
local function jointPose()
	local result = {}
	for _, motor in model:GetDescendants() do
		if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			local visible=motor.Part1.Transparency<.99
   for _,child in motor.Part1:GetDescendants() do if child:IsA("BasePart") and child.Transparency<.99 then visible=true end end
   if visible then result[motor] = motor.Part0.CFrame:ToObjectSpace(motor.Part1.CFrame) end
		end
	end
	return result
end
local function changed(a, b)
	local n = 0
	for motor, cf in a do
		local other = b[motor]
		if other then local delta = cf:ToObjectSpace(other); local _, rotation = delta:ToAxisAngle()
			if delta.Position.Magnitude > .0001 or math.abs(rotation) > .001 then n += 1 end
		end
	end
	return n
end
local function savedPose(clip)
	-- Identical/one-keyframe editor saves are poses, not invented moving animations.
	local poses = {}
	for _, pose in clip:GetKeyframes()[1]:GetDescendants() do
		if pose:IsA("Pose") and pose.Weight > 0 then poses[pose.Name] = pose.CFrame end
	end
	for _, motor in model:GetDescendants() do
		if motor:IsA("Motor6D") and motor.Part1 and poses[motor.Part1.Name] then motor.Transform = poses[motor.Part1.Name] end
	end
end
local function play()
	if not selected or not metadata then message("No existing animation selected.", true); return end
	if not rebuild() then return end
	local candidate = selected
	local token = playEpoch
	source.Text = describe(candidate)
	message("Loading " .. candidate.Name .. " ...")
	task.spawn(function()
		if candidate.Kind=="ProductionGait" then
   local shared=require(RS.Modules.World2BossGait)
   local ok,gait=pcall(shared.Compile,model,stageSelected)
   if not ok then message("Production gait not ready: "..tostring(gait),true);return end
   monitor=Run.PreSimulation:Connect(function(dt) shared.Update(gait,dt,gait.Settings.ReferenceSpeed*speed) end)
   message("Production Walk: shared joint motion, amplitude, cadence and ground correction.")
   return
  end
		if candidate.Kind=="Procedural" then
   local torso=model:FindFirstChild("Torso")
   local joints={}
   for _,name in {"Right Hip","Left Hip","Right Shoulder","Left Shoulder"} do
    local j=torso and torso:FindFirstChild(name)
    if j and j.Part0 and j.Part1 then table.insert(joints,j) end
   end
   if #joints~=4 then message("Recovered gait requires the four existing 023 limb motors.",true);return end
   local elapsed=0
   monitor=Run.PreSimulation:Connect(function(dt)
    elapsed+=dt*speed
    local a=math.sin(elapsed*(candidate.Procedure=="Legacy023" and 9 or 6))* (candidate.Procedure=="Legacy023" and 1 or .8)
    for _,j in joints do
     local direction=j.Name:find("Hip") and -1 or 1
     if candidate.Procedure=="Legacy023" then j.MaxVelocity=.1;j.DesiredAngle=a*direction
     else
      local axis=(j.Part0.CFrame*j.C0):VectorToObjectSpace(torso.CFrame.RightVector)
      j.Transform=CFrame.fromAxisAngle(axis,a*direction)
     end
    end
   end)
   message("Preview-only recovered joint gait; inspect four visible legs, axes and floor clearance.")
   return
  end
  local object = findRelative(candidate.Path)
		local humanoid = model and model:FindFirstChildWhichIsA("Humanoid", true)
		if not object or not humanoid then message("Animation or compatible Humanoid is missing.", true); return end
		local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoid)
		local before = jointPose()
		if candidate.Kind == "KeyframeSequence" and candidate.Static then
			savedPose(object)
			Run.RenderStepped:Wait(); Run.RenderStepped:Wait()
			if token == playEpoch then message(changed(before, jointPose()) > 0 and "Saved static pose applied; no timed motion (speed has no effect)." or "Pose did not move the visible rig; inspect joint compatibility.", changed(before, jointPose()) == 0) end
			return
		end
		if stageSelected==1 and candidate.Id=="rbxassetid://507777826" then
			local clipModule=require(game.ReplicatedStorage.Modules.World2BossClip)
			local ok,clip=pcall(function()
				local sequence=game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(candidate.Id)
    return clipModule.Compile(sequence,model,true,require(RS.Config.World2BossAnimationConfig).Stages[1].RetargetWeight)
			end)
			if token~=playEpoch then return end
			if not ok then message("Cannot retarget approved Walk: "..tostring(clip),true);return end
			local elapsed=0
			monitor=Run.PreSimulation:Connect(function(dt)
				if token~=playEpoch or not model then return end
				elapsed=(elapsed+dt*speed)%clip.Duration
				clipModule.Sample(clip,elapsed)
			end)
			message("Approved R15 Walk retargeted onto corrected existing SCP-096 joints.")
			return
		end
		if candidate.Amplitude then
   local module=require(RS.Modules.World2BossClip)
   local ok,clip=pcall(module.Compile,object,model)
   if not ok then message("Saved clip joint mismatch: "..tostring(clip),true);return end
   local elapsed=0
   monitor=Run.PreSimulation:Connect(function(dt)
    elapsed=(elapsed+dt*speed)%clip.Duration;module.Sample(clip,elapsed)
    for _,binding in clip.Bindings do
     local j=binding.Joint;local axis,a=j.Transform:ToAxisAngle()
     j.Transform=CFrame.new(j.Transform.Position)*CFrame.fromAxisAngle(axis,a*candidate.Amplitude)
    end
   end)
   message("Saved 939walk, 1.35x rotational swing; preview only. Inspect feet at the floor guide.")
   return
  end
  local animation = Instance.new("Animation")
		animation.Name = "PreviewAnimation"
		animation.Parent = model
		local loadedTrack
		local ok, why = pcall(function()
			animation.AnimationId = candidate.Kind == "KeyframeSequence" and game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(object) or candidate.Id
			loadedTrack = animator:LoadAnimation(animation)
		end)
		if token ~= playEpoch then if loadedTrack then loadedTrack:Destroy() end; return end
		if not ok then message("Cannot load: " .. tostring(why):sub(1, 190), true); return end
		track = loadedTrack
		track.Looped = candidate.Kind == "Asset" or candidate.Loop == true
		track:Play(.05, 1, speed)
		local elapsed, last, moving, failed, sampled = 0, before, false, false, 0
		logConnection = game:GetService("LogService").MessageOut:Connect(function(text, kind)
			local id = candidate.Id and candidate.Id:match("%d+")
			if id and kind == Enum.MessageType.MessageError and text:find(id, 1, true) then
				failed = true; message("Asset load/permission failure: " .. candidate.Id .. " (see Output)", true)
			end
		end)
		monitor = Run.RenderStepped:Connect(function(dt)
			if token ~= playEpoch or not model or not track then return end
			elapsed += dt; sampled += dt
			if sampled < .12 then return end
			sampled = 0
			local now = jointPose()
			if elapsed > .15 and changed(last, now) > 0 then moving = true end
			last = now
			if failed then return end
			if not track.IsPlaying and track.Length > 0 then message("Finished " .. candidate.Name .. ". Press Play to replay."); return end
			if stageSelected == "New682" and track.Length > 0 then
				message(string.format("Loaded %s | %.1fx | Animal legs are one rigid mesh, not articulated. Inspect the front/side view.", candidate.Name, speed))
			elseif moving then message(string.format("Playing %s  |  %.1fx  |  visible joints moved", candidate.Name, speed))
			elseif elapsed > 6 and track.Length == 0 then message("Load failed/timed out. Check asset permission and Output.", true)
			elseif elapsed > 1.5 then message("No changing joint pose observed: static clip or rig mismatch. Inspect the model/Output.", true) end
		end)
	end)
end

local function selectBoss(stage)
	epoch += 1
	local token = epoch
	stageSelected = stage; selected = nil; template = nil; metadata = nil
	cleanModel()
	for _, item in candidateButtons do item:Destroy() end
	table.clear(candidateButtons)
	for n, b in bossButtons do b.BackgroundColor3 = n == stage and Color3.fromRGB(49, 113, 101) or Color3.fromRGB(48, 62, 82) end
	message("Loading current Boss template ...")
	source.Text = "Current templates; recovered candidates identify their archived source."
	task.spawn(function()
		local ok, response = pcall(function() return remote:InvokeServer("Select", token, stage) end)
		if token ~= epoch or not panel.Visible then return end
		if not ok or type(response) ~= "table" or response.Error then message(tostring(type(response) == "table" and response.Error or response), true); return end
		local folder = assets:WaitForChild(response.Container, 5)
		local nextTemplate = folder and folder:WaitForChild("Template", 5)
		if token ~= epoch or not panel.Visible then return end
		if not nextTemplate then message("Preview model replication timed out. Select the Boss again.", true); return end
		template = nextTemplate; metadata = response
		if not rebuild() then return end
		source.Text = response.Template
		message(#response.Candidates == 0 and "No existing animation found. " .. response.Note or response.Note, #response.Candidates == 0)
		for index, candidate in response.Candidates do
			local text = candidate.Name .. (candidate.Static and " [saved pose]" or candidate.Kind == "KeyframeSequence" and " [saved clip]" or "")
			local b
			b = button("Candidate" .. index, list, text, UDim2.new(), UDim2.new(1, -8, 0, 35), function()
				selected = candidate
				rebuild()
				for _, other in candidateButtons do other.BackgroundColor3 = other == b and Color3.fromRGB(49, 113, 101) or Color3.fromRGB(48, 62, 82) end
				source.Text = describe(candidate)
				message(candidate.Name == "Animation" and "Original object name: Animation; intended use is unverified. Press Play to inspect." or "Selected " .. candidate.Name .. ". Press Play.")
			end)
			b.TextWrapped=true;b.TextSize=12
			b.LayoutOrder = index
			table.insert(candidateButtons, b)
		end
	end)
end
local function close()
	panel.Visible = false
	if launch then launch.Visible = true end
	epoch += 1
	local token = epoch
	cleanModel(); template = nil; metadata = nil; selected = nil
	task.spawn(function() pcall(function() remote:InvokeServer("Close", token) end) end)
end
button("Close", panel, "Close", UDim2.new(1, -72, 0, 7), UDim2.fromOffset(60, 28), close)
local bosses = {{1,"SCP-096"},{2,"SCP-023"},{3,"SCP-035"},{4,"SCP-058"},{5,"SCP-049"},{6,"SCP-173"},{7,"SCP-939"},{8,"SCP-106"},{9,"SCP-682"},{10,"SCP-323"}}
for index, boss in bosses do
	bossButtons[boss[1]] = button("Stage" .. boss[1], panel, "Stage " .. boss[1] .. "\n" .. boss[2], UDim2.fromOffset(12 + (index - 1) % 2 * 91, 42 + math.floor((index - 1) / 2) * 39), UDim2.fromOffset(87, 34), function() selectBoss(boss[1]) end)
end
bossButtons.New682 = button("New682", panel, "NEW SCP-682 (Workspace)", UDim2.fromOffset(12, 237), UDim2.fromOffset(178, 34), function() selectBoss("New682") end)
button("Play", panel, "Play", UDim2.new(0, 202, 1, -135), UDim2.fromOffset(64, 28), play)
button("Stop", panel, "Stop", UDim2.new(0, 272, 1, -135), UDim2.fromOffset(64, 28), function() if rebuild() then message("Stopped. Original template pose restored.") end end)
for index, value in {.5, 1, 1.5} do
	speedButtons[value] = button("Speed" .. index, panel, tostring(value) .. "x", UDim2.new(0, 345 + (index - 1) * 56, 1, -135), UDim2.fromOffset(50, 28), function()
		speed = value
		if track then track:AdjustSpeed(speed) end
		for rate, b in speedButtons do b.BackgroundColor3 = rate == speed and Color3.fromRGB(49, 113, 101) or Color3.fromRGB(48, 62, 82) end
	end)
end
speedButtons[1].BackgroundColor3 = Color3.fromRGB(49, 113, 101)
for index, direction in {"Front", "Side", "Back"} do
	button(direction, view, direction, UDim2.new(1, -190 + (index - 1) * 62, 0, 7), UDim2.fromOffset(57, 27), function() angle = direction; aim() end)
end
view:GetPropertyChangedSignal("AbsoluteSize"):Connect(aim)
launch = button("Open", gui, "Boss Anim Preview (Studio)", UDim2.new(1, -238, 0, 8), UDim2.fromOffset(230, 32), function()
	if panel.Visible then close() else launch.Visible = false; panel.Visible = true; selectBoss(stageSelected) end
end)
-- Studio's top-bar inset can offset synthetic button activation. Use actual UI hits;
-- never consume or dispatch clicks that do not hit this tool's registered buttons.
local input = game:GetService("UserInputService").InputBegan:Connect(function(event)
	if event.UserInputType ~= Enum.UserInputType.MouseButton1 and event.UserInputType ~= Enum.UserInputType.Touch then return end
	for _, object in player.PlayerGui:GetGuiObjectsAtPosition(event.Position.X, event.Position.Y) do
		local callback = callbacks[object]
		if callback then callback(); return end
		if object:IsDescendantOf(gui) then return end
	end
end)
script.Destroying:Connect(function() input:Disconnect(); close(); gui:Destroy() end)
