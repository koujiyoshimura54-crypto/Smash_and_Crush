local Binding=require(game.ReplicatedStorage.Modules:WaitForChild("World1BossPresentation"))
-- Stage06 presentation follows the existing personal combat visibility.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rig, track
local hidden = false
local connections = {}
local watchedParts = {}
local refresh
local function stopTrack()
 if track then track:Stop(0); track:Destroy(); track = nil end
end
local function release()
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
 local enemy=Binding.Get(6)
 hidden=enemy==nil
 local current = enemy and enemy:FindFirstChild("Pipi_Kiwi")
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
 local vfx = rig:FindFirstChild("GattatinoNeoninoVFX")
 if vfx then
  for _, emitter in vfx:GetDescendants() do
   if emitter:IsA("ParticleEmitter") then
    emitter.Enabled = shown and emitter:GetAttribute("StaticVFXEnabled") ~= false
    if not shown then emitter:Clear() end
   end
  end
 end
 if not shown then stopTrack(); return end
 if not track then
  local controller = rig:FindFirstChildOfClass("AnimationController")
  local animator = controller and controller:FindFirstChildOfClass("Animator")
  local asset = rig:FindFirstChild("Stage06Walk")
  if not animator or not asset or not asset:IsA("Animation") or asset.AnimationId == "" then return end
  local ok, loaded = pcall(function() return animator:LoadAnimation(asset) end)
  if not ok then warn("Stage06Walk load failed: " .. tostring(loaded)); return end
  track = loaded
  track.Name = "Stage06Walk"
  track.Looped = true
  track.Priority = Enum.AnimationPriority.Movement
 end
 if not track.IsPlaying then track:Play(.15, 1, 1) end
end
local disconnect=Binding.Watch(6,refresh)
script.Destroying:Connect(function() disconnect();release() end)
