-- Stage07 presentation follows the existing personal combat visibility.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage").Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local rig, track
local hidden = false
local connections = {}
local watchedParts = {}
local refresh
local vfxDefaults = {}
local function setVFXShown(shown)
 local group = rig and rig:FindFirstChild("AgarriniLaPaliniVFX")
 if not group then return end
 for _, item in group:GetDescendants() do
  if item:IsA("ParticleEmitter") then
   if vfxDefaults[item] == nil then
    local authored = item:GetAttribute("StaticVFXEnabled")
    vfxDefaults[item] = authored == nil and item.Enabled or authored
   end
   item.Enabled = shown and vfxDefaults[item]
   if not shown then item:Clear() end
  end
 end
end
local function stopTrack()
 if track then track:Stop(0); track:Destroy(); track = nil end
end
local function release()
 setVFXShown(false)
 table.clear(vfxDefaults)
 for _, connection in connections do connection:Disconnect() end
 table.clear(connections)
 table.clear(watchedParts)
 stopTrack()
 rig = nil
end
local function watchPart(part)
 if not part:IsA("MeshPart") or watchedParts[part] then return end
 watchedParts[part] = true
 table.insert(connections, part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function() task.defer(refresh) end))
 table.insert(connections, part:GetPropertyChangedSignal("Transparency"):Connect(function() task.defer(refresh) end))
end
refresh = function()
 local enemies = workspace:FindFirstChild("Enemies")
 local enemy = enemies and enemies:FindFirstChild("Stage07_Enemy")
 local current = enemy and enemy:FindFirstChild("Trippi Troppi")
 if current ~= rig then
  release()
  rig = current
  if rig then
   table.insert(connections, rig.Destroying:Connect(release))
   table.insert(connections, rig.DescendantAdded:Connect(function(part) watchPart(part); task.defer(refresh) end))
   table.insert(connections, rig.AncestryChanged:Connect(function() task.defer(refresh) end))
   for _, part in rig:GetDescendants() do watchPart(part) end
  end
 end
 if not rig then return end
 local shown = not hidden and (player:GetAttribute("CurrentWorld") or 1) == 1
 local visibleMesh = false
 for _, part in rig:GetDescendants() do
  if part:IsA("MeshPart") and part.Transparency < 1 and part.LocalTransparencyModifier < .99 then visibleMesh = true; break end
 end
 shown = shown and visibleMesh
 setVFXShown(shown)
 if not shown then stopTrack(); return end
 if not track then
  local controller = rig:FindFirstChildOfClass("AnimationController")
  local animator = controller and controller:FindFirstChildOfClass("Animator")
  local asset = rig:FindFirstChild("Stage07Walk")
  if not animator or not asset or not asset:IsA("Animation") or asset.AnimationId == "" then return end
  local ok, loaded = pcall(function() return animator:LoadAnimation(asset) end)
  if not ok then warn("Stage07Walk load failed: " .. tostring(loaded)); return end
  track = loaded
  track.Name = "Stage07Walk"
  track.Looped = true
  track.Priority = Enum.AnimationPriority.Movement
 end
 if not track.IsPlaying then track:Play(.15, 1, 1) end
end
remote.OnClientEvent:Connect(function(data)
 if data.Type == "Initialize" then
  hidden = (data.Cleared and data.Cleared[7]) == true or (data.Skipped and data.Skipped[7]) == true
 elseif (data.Type == "EnemyDefeated" or data.Type == "StageCleared") and data.Stage == 7 then
  hidden = true
 end
 task.defer(refresh)
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() task.defer(refresh) end)
workspace.DescendantAdded:Connect(function(item)
 if item.Name == "Stage07_Enemy" or item.Name == "Trippi Troppi" then task.defer(refresh) end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type = "RequestState"})
