-- Stage10 presentation follows the existing personal combat visibility.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage").Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local rig, track
local hidden = true
local connections = {}
local watchedParts = {}
local refresh
-- One cycle follows the actual WingFlap track, including loop/restart.
local VFX_PERIOD = 3.2
local VFX_LIMITS = {
 body = {0.25, 0.95}, -- large flames, smoke and broad glow
 streak = {0.30, 1.00},
 accent = {0.45, 1.00},
}
local emitters = {}
local pulseConnection
local function watchEmitter(emitter)
 if not emitter:IsA("ParticleEmitter") or emitters[emitter] then return end
 local group = emitter.Name == "specs" and "accent"
  or ((emitter.Name:match("^speed") or emitter.Name:match("^spike")) and "streak" or "body")
 local enabled = emitter:GetAttribute("StaticVFXEnabled")
 emitters[emitter] = {
  rate = emitter.Rate,
  enabled = if typeof(enabled) == "boolean" then enabled else emitter.Enabled,
  limits = VFX_LIMITS[group],
 }
end
local function stopVFX()
 if pulseConnection then pulseConnection:Disconnect(); pulseConnection = nil end
 for emitter in emitters do
  if emitter.Parent then emitter.Enabled = false; emitter:Clear() end
 end
end
local function updateVFX()
 if not track or not track.IsPlaying then stopVFX(); return end
 local period = track.Length > 0 and track.Length or VFX_PERIOD
 local wave = 0.5 - 0.5 * math.cos(2 * math.pi * (track.TimePosition % period) / period)
 for emitter, original in emitters do
  if emitter.Parent then
   emitter.Rate = original.rate * (original.limits[1] + (original.limits[2] - original.limits[1]) * wave)
   emitter.Enabled = original.enabled
  end
 end
end
local function startVFX()
 updateVFX()
 if not pulseConnection then pulseConnection = RunService.Heartbeat:Connect(updateVFX) end
end
local function stopTrack()
 stopVFX()
 if track then track:Stop(0); track:Destroy(); track = nil end
end
local function release()
 for _, connection in connections do connection:Disconnect() end
 table.clear(connections)
 table.clear(watchedParts)
 stopTrack()
 table.clear(emitters)
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
 local enemy = enemies and enemies:FindFirstChild("Stage10_Enemy")
 local current = enemy and enemy:FindFirstChild("Dragon Cannelloni")
 if current ~= rig then
  release()
  rig = current
  if rig then
   table.insert(connections, rig.Destroying:Connect(release))
   table.insert(connections, rig.DescendantAdded:Connect(function(part) watchPart(part); watchEmitter(part); task.defer(refresh) end))
   table.insert(connections, rig.AncestryChanged:Connect(function() task.defer(refresh) end))
   for _, part in rig:GetDescendants() do watchPart(part); watchEmitter(part) end
  end
 end
 if not rig then return end
 local shown = not hidden and (player:GetAttribute("CurrentWorld") or 1) == 1
 local visibleMesh = false
 for _, part in rig:GetDescendants() do
  if part:IsA("MeshPart") and part.Transparency < 1 and part.LocalTransparencyModifier < .99 then visibleMesh = true; break end
 end
 shown = shown and visibleMesh
 if not shown then stopTrack(); return end
 if not track then
  local controller = rig:FindFirstChildOfClass("AnimationController")
  local animator = controller and controller:FindFirstChildOfClass("Animator")
  local asset = rig:FindFirstChild("Stage10WingFlap")
  if not animator or not asset or not asset:IsA("Animation") or asset.AnimationId == "" then return end
  local ok, loaded = pcall(function() return animator:LoadAnimation(asset) end)
  if not ok then warn("Stage10WingFlap load failed: " .. tostring(loaded)); return end
  track = loaded
  track.Name = "Stage10WingFlap"
  track.Looped = true
  track.Priority = Enum.AnimationPriority.Idle
 end
 if not track.IsPlaying then track:Play(.15, 1, 1) end
 startVFX()
end
remote.OnClientEvent:Connect(function(data)
 if data.Type == "Initialize" then
  hidden = (data.Cleared and data.Cleared[10]) == true or (data.Skipped and data.Skipped[10]) == true
 elseif (data.Type == "EnemyDefeated" or data.Type == "StageCleared") and data.Stage == 10 then
  hidden = true
 end
 task.defer(refresh)
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() task.defer(refresh) end)
workspace.DescendantAdded:Connect(function(item)
 if item.Name == "Stage10_Enemy" or item.Name == "Dragon Cannelloni" then task.defer(refresh) end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type = "RequestState"})
