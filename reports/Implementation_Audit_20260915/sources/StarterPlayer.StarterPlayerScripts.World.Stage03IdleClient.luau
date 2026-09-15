-- Idle follows the same personal defeat state as CombatClient.
-- Action-priority attacks override Idle without changing their timing.
local remote=game:GetService("ReplicatedStorage").Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local rig,idle,destroyConnection
local hidden=false
local function release()
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 rig=nil
end
local function refresh()
 local enemies=workspace:FindFirstChild("Enemies")
 local enemy=enemies and enemies:FindFirstChild("Stage03_Enemy")
 local current=enemy and enemy:FindFirstChild("TungTungSahurRig")
 if current~=rig then release()end
 if hidden then
  if idle then idle:Stop(0)end
  return
 end
 if not current then return end
 if not idle then
  local humanoid=current:FindFirstChildOfClass("Humanoid")
  local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
  local animation=current:FindFirstChild("Stage03Idle")
  if not animator or not animation then return end
  local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
  if not ok then warn("Stage03 idle animation could not load: "..tostring(result));return end
  rig=current
  idle=result
  idle.Priority=Enum.AnimationPriority.Idle
  idle.Looped=true
  destroyConnection=rig.Destroying:Connect(release)
 end
 if not idle.IsPlaying then idle:Play(0.15,1,1)end
end
remote.OnClientEvent:Connect(function(d)
 if d.Type=="Initialize" then
  hidden=(d.Cleared and d.Cleared[3])==true or (d.Skipped and d.Skipped[3])==true
  refresh()
 elseif d.Type=="EnemyDefeated" and d.Stage==3 then
  hidden=true
  refresh()
 end
end)
workspace.DescendantAdded:Connect(function(d)
 if d.Name=="TungTungSahurRig" or d.Name=="Stage03Idle" or d:IsA("Animator") then
  task.defer(refresh)
 end
end)
script.Destroying:Connect(release)
refresh()
-- Also covers joining after CombatClient's initial snapshot request.
remote:FireServer({Type="RequestState"})

