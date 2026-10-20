-- One owner for character loading and lobby placement. No saved player state.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local M = {}
local requests = setmetatable({}, {__mode = "k"})
local loading = setmetatable({}, {__mode = "k"})
local bound = setmetatable({}, {__mode = "k"})
local characterRequests = setmetatable({}, {__mode = "k"})
local spawned = Instance.new("BindableEvent")
M.Spawned = spawned.Event
local started = false
local remotes = RS:WaitForChild("Remotes")
local placementReady = remotes:FindFirstChild("LobbySpawnReady") or Instance.new("RemoteEvent")
placementReady.Name = "LobbySpawnReady"
placementReady.Parent = remotes

function M.WorldFor(player)
	return player:GetAttribute("CurrentWorld") == 2 and 2 or 1
end

function M.GetLobby(worldId)
	local map = Workspace:FindFirstChild(worldId == 2 and "World2Map" or "GeneratedMap")
	local area = map and map:FindFirstChild("TrainingArea")
	local marker = area and area:FindFirstChild(worldId == 2 and "World2LobbySpawn" or "SpawnLocation")
	local floor = area and area:FindFirstChild("Floor")
	if not marker or not marker:IsA("BasePart") or not floor or not floor:IsA("BasePart")
		or not floor.Anchored or not floor.CanCollide then return nil end
	return marker, floor, map
end

function M.ConfigureRespawn(player, worldId)
	local marker = M.GetLobby(worldId)
	if not marker then return false end
	local spawn = marker
	if not marker:IsA("SpawnLocation") then
		-- World2's authored marker is a Part. Keep it and all lobby geometry intact.
		spawn = marker:FindFirstChild("RuntimeRespawn")
		if not spawn then
			spawn = Instance.new("SpawnLocation")
			spawn.Name = "RuntimeRespawn"
			spawn.Enabled = false
			spawn.Neutral = true
			spawn.AllowTeamChangeOnTouch = false
			spawn.Anchored = true
			spawn.CanCollide = false
			spawn.CanTouch = false
			spawn.CanQuery = false
			spawn.Transparency = 1
			spawn.Duration = 0
			spawn.Size = marker.Size
			spawn.CFrame = marker.CFrame
			spawn.Parent = marker
		end
	end
	player.RespawnLocation = spawn
	spawn.Enabled = true
	return true
end

function M.CancelPending(player)
	local old = requests[player]
	if old and old.Root and old.Root.Parent then old.Root.Anchored = old.Anchored end
	local request = {Character = player.Character, World = M.WorldFor(player)}
	requests[player] = request
	return request
end

function M.IsCurrent(player, request)
	return request ~= nil and requests[player] == request and player.Parent == Players
		and player.Character == request.Character and M.WorldFor(player) == request.World
end

local function living(player, character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if player.Parent ~= Players or player.Character ~= character or not root or not hum
		or hum.Health <= 0 or not character:IsDescendantOf(Workspace) then return nil end
	return root, hum
end

local function clearance(character, root, hum)
	local height = hum.HipHeight + root.Size.Y / 2
	if hum.RigType == Enum.HumanoidRigType.R6 then
		local leg = character:FindFirstChild("Left Leg")
		height += leg and leg.Size.Y or 2
	end
	-- Body parts only: tools, accessories and welded combat volumes aren't feet.
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			local cf = root.CFrame:ToObjectSpace(part.CFrame)
			local half = (math.abs(cf.RightVector.Y) * part.Size.X
				+ math.abs(cf.UpVector.Y) * part.Size.Y + math.abs(cf.LookVector.Y) * part.Size.Z) / 2
			height = math.max(height, -cf.Y + half)
		end
	end
	return height
end

local function surfaceAt(character, root, floor, position)
	local localPos = floor.CFrame:PointToObjectSpace(position)
	local inset = math.max(root.Size.X, root.Size.Z) / 2 + 0.25
	if math.abs(localPos.X) > floor.Size.X / 2 - inset
		or math.abs(localPos.Z) > floor.Size.Z / 2 - inset then return nil end
	local top = floor.CFrame:PointToWorldSpace(Vector3.new(localPos.X, floor.Size.Y / 2, localPos.Z)).Y
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = {character}
	for _, player in Players:GetPlayers() do
		if player.Character then table.insert(excluded, player.Character) end
	end
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	params.CollisionGroup = root.CollisionGroup
	-- Include purchased carpet surfaces above the structural floor.
	local origin = Vector3.new(position.X, top + math.max(character:GetExtentsSize().Y, 16), position.Z)
	local hit = Workspace:Raycast(origin, Vector3.new(0, top - origin.Y - 0.5, 0), params)
	if not hit or hit.Normal.Y < 0.9 or hit.Position.Y < top - 0.05 then return nil end
	return hit.Position.Y
end

function M.MoveToLobby(player, character, worldId)
	local root, hum = living(player, character)
	local marker, floor, map = M.GetLobby(worldId)
	if not root or not marker or not character:GetAttribute("SpawnEngineReady")
		or not character:GetAttribute("MuscleScaleReady") then return false, "CharacterNotReady" end
	local top = surfaceAt(character, root, floor, marker.Position)
	if not top then return false, "LobbyFloorUnavailable" end
	local request = M.CancelPending(player)
	request.Root, request.Anchored, request.TargetWorld = root, root.Anchored, worldId
	root.Anchored = true
	local position = Vector3.new(marker.Position.X, top + clearance(character, root, hum) + 0.15, marker.Position.Z)
	local corridor = map:FindFirstChild("BattleCorridor")
	local stage = corridor and corridor:FindFirstChild("Stage01")
	local target = stage and stage:GetPivot().Position or position + marker.CFrame.LookVector
	local direction = Vector3.new(target.X - position.X, 0, target.Z - position.Z)
	if direction.Magnitude < 0.01 then direction = Vector3.new(0, 0, 1) end
	local cf = CFrame.lookAt(position, position + direction)
	-- Model pivots need not coincide with HumanoidRootPart after custom scaling.
	character:PivotTo(cf * root.CFrame:ToObjectSpace(character:GetPivot()))
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	M.ConfigureRespawn(player, worldId)
	character:SetAttribute("LobbySpawnPlaced", true)
	character:SetAttribute("SpawnFacingDirection", direction.Unit)
	character:SetAttribute("SpawnFacingRevision", (character:GetAttribute("SpawnFacingRevision") or 0) + 1)
	request.Target = position
	request.Revision = (character:GetAttribute("SpawnPlacementRevision") or 0) + 1
	character:SetAttribute("SpawnPlacementTarget", position)
	character:SetAttribute("SpawnPlacementRevision", request.Revision)
	return true
end

-- Release only after this client has the new pose and a collidable floor.
-- Anchoring prevents old client physics packets from replaying the Trophy pose.
placementReady.OnServerEvent:Connect(function(player, character, revision, position)
	local request = requests[player]
	if not request or request.Character ~= character or player.Character ~= character
		or request.Revision ~= revision or typeof(position) ~= "Vector3"
		or not request.Target or (request.Target - position).Magnitude > 0.5 then return end
	local root, hum = living(player, character)
	if not root or hum.Health <= 0 or request.Root ~= root or (root.Position - request.Target).Magnitude > 0.5 then return end
	root.Anchored = request.Anchored
	request.Root = nil
end)

-- A delayed data load may resize someone who has already left the spawn.
-- Lift only at their CURRENT lobby position; never replay their initial target.
function M.OnScaleApplied(player, character)
	if not character:GetAttribute("LobbySpawnPlaced") then return end
	local root, hum = living(player, character)
	local _, floor = M.GetLobby(M.WorldFor(player))
	if not root or not floor then return end
	local top = surfaceAt(character, root, floor, root.Position)
	if not top then return end
	local minimum = top + hum.HipHeight + root.Size.Y / 2 + 0.15
	if root.Position.Y < minimum then
		character:PivotTo(character:GetPivot() + Vector3.new(0, minimum - root.Position.Y, 0))
		local request = requests[player]
		if request and request.Root == root and request.Target then
			request.Target = root.Position
			request.Revision += 1
			character:SetAttribute("SpawnPlacementTarget", request.Target)
			character:SetAttribute("SpawnPlacementRevision", request.Revision)
		end
	end
end

-- Stream before a yielding travel request; all continuations revalidate identity.
function M.StreamLobby(player, character, worldId)
	local root = living(player, character)
	local marker = M.GetLobby(worldId)
	if not root or not marker then return nil, "CharacterNotReady" end
	local request = M.CancelPending(player)
	request.Root, request.Anchored = root, root.Anchored
	root.Anchored = true
	local ok, err = pcall(function() player:RequestStreamAroundAsync(marker.Position) end)
	if not M.IsCurrent(player, request) then return nil, "StalePlacement" end
	root.Anchored = request.Anchored
	request.Root = nil
	if not ok then return nil, tostring(err) end
	return request
end

function M.LoadCharacter(player, expectedCharacter, expectedRequest)
	if loading[player] or player.Parent ~= Players
		or (expectedCharacter and player.Character ~= expectedCharacter)
		or (expectedRequest and not M.IsCurrent(player, expectedRequest)) then return false end
	if not M.ConfigureRespawn(player, M.WorldFor(player)) then return false end
	local load = {}
	loading[player] = load
	local ok, err = pcall(function() player:LoadCharacterAsync() end)
	loading[player] = nil
	local character = load.Character or player.Character
	if not ok then warn("[LobbySpawn] Character load failed: " .. tostring(err)); return false end
	if not character or player.Character ~= character then return false end
	load.Request = characterRequests[character] or M.CancelPending(player)
	characterRequests[character] = load.Request
	-- The engine's final spawn move has completed. Muscle preparation starts now.
	character:SetAttribute("SpawnEngineReady", true)
	if not character:GetAttribute("MuscleScaleReady") then
		local ready = Instance.new("BindableEvent")
		local connection = character:GetAttributeChangedSignal("MuscleScaleReady"):Connect(function() ready:Fire() end)
		local removed = player.CharacterRemoving:Connect(function(ch) if ch == character then ready:Fire() end end)
		if not character:GetAttribute("MuscleScaleReady") and player.Character == character then ready.Event:Wait() end
		connection:Disconnect(); removed:Disconnect(); ready:Destroy()
	end
	if not living(player, character) or not M.IsCurrent(player, load.Request) then return false end
	local worldId = M.WorldFor(player)
	local request = M.StreamLobby(player, character, worldId)
	if not request or not M.IsCurrent(player, request) then return false end
	local placed, why = M.MoveToLobby(player, character, worldId)
	if not placed then warn("[LobbySpawn] Placement rejected: " .. tostring(why)); return false end
	spawned:Fire(player, character)
	return true
end

function M.Start()
	if started then return end
	started = true
	Players.CharacterAutoLoads = false
	local function bind(player)
		if bound[player] then return end
		bound[player] = true
		M.ConfigureRespawn(player, M.WorldFor(player))
		player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
			local request = requests[player]
			if request and request.Character == player.Character and request.TargetWorld == M.WorldFor(player) then
				request.World = M.WorldFor(player)
			else M.CancelPending(player) end
			M.ConfigureRespawn(player, M.WorldFor(player))
		end)
		player.CharacterAdded:Connect(function(character)
			local request = characterRequests[character] or M.CancelPending(player)
			characterRequests[character] = request
			if loading[player] then loading[player].Character = character; loading[player].Request = request end
			local hum = character:WaitForChild("Humanoid", 10)
			if not hum or player.Character ~= character then return end
			hum.Died:Once(function()
				local request = M.CancelPending(player)
				task.delay(Players.RespawnTime, function()
					if M.IsCurrent(player, request) then M.LoadCharacter(player, character, request) end
				end)
			end)
		end)
		task.spawn(M.LoadCharacter, player)
	end
	Players.PlayerAdded:Connect(bind)
	Players.PlayerRemoving:Connect(function(player)
		M.CancelPending(player)
		requests[player], loading[player], bound[player] = nil, nil, nil
	end)
	for _, player in Players:GetPlayers() do bind(player) end
end

-- StageSkip extensions. The 36595fe lobby/load/return implementations above are unchanged.
function M.GetRootClearance(player, character)
 local root,hum=living(player,character)
 return root and clearance(character,root,hum) or nil
end
function M.StreamAt(player, character, position)
 local root=living(player,character)
 if not root then return nil,"CharacterNotReady" end
 local request=M.CancelPending(player)
 request.Root,request.Anchored=root,root.Anchored
 root.Anchored=true
 local ok,why=pcall(function()player:RequestStreamAroundAsync(position)end)
 if not M.IsCurrent(player,request) then return nil,"StalePlacement" end
 root.Anchored=request.Anchored;request.Root=nil
 if not ok then return nil,tostring(why) end
 return request
end
function M.MoveToCFrame(player, character, cf)
 local root=living(player,character)
 if not root or not character:GetAttribute("SpawnEngineReady") or not character:GetAttribute("MuscleScaleReady") then return false,"CharacterNotReady" end
 local request=M.CancelPending(player)
 request.Root,request.Anchored,request.TargetWorld=root,root.Anchored,M.WorldFor(player)
 root.Anchored=true
 character:PivotTo(cf*root.CFrame:ToObjectSpace(character:GetPivot()))
 for _,part in character:GetDescendants() do
  if part:IsA("BasePart") then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end
 end
 character:SetAttribute("SpawnFacingDirection",cf.LookVector)
 character:SetAttribute("SpawnFacingRevision",(character:GetAttribute("SpawnFacingRevision") or 0)+1)
 request.Target=cf.Position
 request.Revision=(character:GetAttribute("SpawnPlacementRevision") or 0)+1
 character:SetAttribute("SpawnPlacementTarget",request.Target)
 character:SetAttribute("SpawnPlacementRevision",request.Revision)
 return true,nil,request
end
-- A bounded acknowledgement wait, used only by the requesting StageSkip transaction.
-- A superseding placement retains ownership of its own anchor and position.
function M.AwaitPlacement(player,request,validate)
 local deadline=os.clock()+8
 while true do
  local root=living(player,request and request.Character)
  if not root or not M.IsCurrent(player,request) then return false,"Travel cancelled" end
  if validate and not validate() then return false,"Character or Stage changed; please retry" end
  if not request.Root then
   if root.Anchored or (root.Position-request.Target).Magnitude>0.5 then return false,"Placement not confirmed" end
   return true
  end
  if os.clock()>=deadline then return false,"Placement confirmation timed out; please retry" end
  game:GetService("RunService").Heartbeat:Wait()
 end
end

return M
