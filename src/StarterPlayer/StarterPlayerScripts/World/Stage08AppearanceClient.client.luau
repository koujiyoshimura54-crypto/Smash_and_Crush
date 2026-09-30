-- World1 Stage08 presentation only. Combat root, colliders and server placement stay unchanged.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("GameRemotes"):WaitForChild("CombatState")
local player = Players.LocalPlayer
local FLOAT_AMPLITUDE = 2.0 -- studs above/below the original placement
local FLOAT_PERIOD = 3.6 -- seconds; independent of the published clip
local STAGE = 8
local MODEL_NAME = "Chimpanzini Bananini"

local rig, track, floatWeld, baseC0, combatRoot
local stepConnection, destroyConnection
local visibilityConnections = {}
local originalWelds = {}
local vfx = {}
local hidden = true -- wait for the server's personal combat snapshot
local elapsed = 0

local function stop()
 if stepConnection then stepConnection:Disconnect(); stepConnection = nil end
 if track and track.IsPlaying then track:Stop(0) end
 if floatWeld and floatWeld.Parent then floatWeld.C0 = baseC0 end
 elapsed = 0
end
local function release()
 stop()
 if destroyConnection then destroyConnection:Disconnect(); destroyConnection = nil end
 for _,connection in visibilityConnections do connection:Disconnect() end
 table.clear(visibilityConnections)
 if track then track:Destroy(); track = nil end
 if floatWeld then floatWeld:Destroy(); floatWeld = nil end
 for weld,enabled in originalWelds do if weld.Parent then weld.Enabled = enabled end end
 table.clear(originalWelds)
 table.clear(vfx)
 rig, combatRoot, baseC0 = nil, nil, nil
end
local function isVisible()
 if hidden or player:GetAttribute("CurrentWorld") == 2 or not rig or not rig:IsDescendantOf(workspace) then return false end
 for _,d in rig:GetDescendants() do
  if d:IsA("MeshPart") and d.Transparency < 0.99 and d.LocalTransparencyModifier < 0.99 then return true end
 end
 return false
end
local refresh
local function bind(current, enemy)
 local root = enemy:FindFirstChild("HumanoidRootPart")
 local visualRoot = current:FindFirstChild("FakeRootPart")
 local controller = current:FindFirstChildOfClass("AnimationController")
 local animator = controller and controller:FindFirstChildOfClass("Animator")
 local animation = current:FindFirstChild("Stage08PeelWave")
 if not root or not visualRoot or not animator or not animation then return false end
 -- Only replace EnemyManager's external display welds on THIS client.
 -- The original RootPart weld, Motor6Ds, Bones and meshes are left intact.
 local welds = {}
 for _,d in current:GetDescendants() do
  if d:IsA("WeldConstraint") and d.Name == "StaticVisualWeld" and d.Part0 == root then table.insert(welds,d) end
 end
 if #welds == 0 then return false end
 rig, combatRoot = current, root
 baseC0 = root.CFrame:ToObjectSpace(visualRoot.CFrame)
 for _,weld in welds do originalWelds[weld] = weld.Enabled; weld.Enabled = false end
 floatWeld = Instance.new("Weld")
 floatWeld.Name = "Stage08FloatWeld"
 floatWeld.Part0 = root
 floatWeld.Part1 = visualRoot
 floatWeld.C0 = baseC0
 floatWeld.Parent = visualRoot
 local ok,result = pcall(function() return animator:LoadAnimation(animation) end)
 if not ok then
  warn("Stage08 PeelWave could not load: " .. tostring(result))
  release()
  return false
 end
 track = result
 track.Name = "Stage08PeelWave"
 track.Priority = Enum.AnimationPriority.Idle
 track.Looped = true
 for _,d in rig:GetDescendants() do
  if d:IsA("MeshPart") then
   table.insert(visibilityConnections,d:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function() task.defer(refresh) end))
  elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
   local original = d:GetAttribute("StaticVFXEnabled")
   vfx[d] = if typeof(original) == "boolean" then original else d.Enabled
  end
 end
 destroyConnection = rig.Destroying:Connect(release)
 return true
end
refresh = function()
 local enemies = workspace:FindFirstChild("Enemies")
 local enemy = enemies and enemies:FindFirstChild("Stage08_Enemy")
 local current = enemy and enemy:FindFirstChild(MODEL_NAME)
 if current ~= rig then
  release()
  if current and not bind(current,enemy) then return end
 end
 if not rig then return end
 local visible = isVisible()
 for effect,enabled in vfx do
  if effect.Parent then
   effect.Enabled = visible and enabled
   if not visible and not effect:IsA("Beam") then effect:Clear() end
  end
 end
 if not visible then stop(); return end
 if not track.IsPlaying then track:Play(0.15,1,1) end
 if not stepConnection then
  elapsed = 0
  stepConnection = RunService.PreSimulation:Connect(function(dt)
   if not isVisible() then stop(); return end
   elapsed = (elapsed + dt) % FLOAT_PERIOD
   local yOffset = FLOAT_AMPLITUDE * math.sin(2 * math.pi * elapsed / FLOAT_PERIOD)
   -- Absolute original offset each frame; never accumulate previous displacement.
   floatWeld.C0 = baseC0 + combatRoot.CFrame:VectorToObjectSpace(Vector3.new(0,yOffset,0))
  end)
 end
end
remote.OnClientEvent:Connect(function(data)
 if data.Type == "Initialize" then
  hidden = (data.Cleared and data.Cleared[STAGE]) == true or (data.Skipped and data.Skipped[STAGE]) == true
 elseif data.Stage == STAGE and data.Type == "EnemyDefeated" then
  hidden = true
 elseif data.Stage == STAGE and data.Type == "BossInitialize" then
  hidden = false
 else return end
 task.defer(refresh)
end)
player:GetAttributeChangedSignal("CurrentWorld"):Connect(function() task.defer(refresh) end)
workspace.DescendantAdded:Connect(function(d)
 if d.Name == "Stage08_Enemy" or d.Name == MODEL_NAME or ((d.Name == "Stage08PeelWave" or d.Name == "StaticVisualWeld" or d:IsA("Animator")) and d:FindFirstAncestor(MODEL_NAME)) then task.defer(refresh) end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type="RequestState"})
