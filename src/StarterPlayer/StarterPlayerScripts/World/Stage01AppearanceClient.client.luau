-- Personal visual state follows the server's existing combat snapshots.
local RS=game:GetService("ReplicatedStorage")
local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local rig,idle,animation,walk,destroyConnection
local hidden=false
local originals={}
local missingIdWarned=false
local function release()
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 if animation then animation:Destroy();animation=nil end
 if walk then walk:Stop(0);walk:Destroy();walk=nil end
 rig=nil
 originals={}
end
local function refresh()
 local enemies=workspace:FindFirstChild("Enemies")
 local enemy=enemies and enemies:FindFirstChild("Stage01_Enemy")
 local current=enemy and enemy:FindFirstChild("BallerinaCappuccinaRig")
 if current~=rig then
  release()
  rig=current
  if rig then destroyConnection=rig.Destroying:Connect(release)end
 end
 if not rig then return end
 for _,d in rig:GetDescendants()do
  if d:IsA("ParticleEmitter")or d:IsA("Trail")or d:IsA("Beam")then
   if originals[d]==nil then originals[d]=d.Enabled end
   d.Enabled=not hidden and originals[d]
   if hidden and not d:IsA("Beam")then d:Clear()end
  end
 end
 if hidden then
  if idle then idle:Stop(0)end
  if walk then walk:Stop(0)end
  return
 end
 if not idle then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage01Idle")
  if not animator or not asset then return end
  local id=asset.AnimationId
  if id=="" then
   if not missingIdWarned then warn("Stage01 Idle_Arms_Ballerina requires a published AnimationId");missingIdWarned=true end
   return
  end
  animation=Instance.new("Animation")
  animation.AnimationId=id
  local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
  if not ok then animation:Destroy();animation=nil;warn("Stage01 idle could not load: "..tostring(result));return end
  idle=result
  idle.Priority=Enum.AnimationPriority.Idle
  idle.Looped=true
 end
 if not idle.IsPlaying then idle:Play(.15,1,1)end
 -- The fixed Stage01 boss walks while visible, using its existing Animator.
 if not walk then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage01Walk")
  if not animator or not asset or not asset:IsA("Animation") or asset.AnimationId=="" then return end
  local ok,result=pcall(function()return animator:LoadAnimation(asset)end)
  if not ok then warn("Stage01 walk could not load: "..tostring(result));return end
  walk=result
  walk.Name="Stage01Walk"
  walk.Priority=Enum.AnimationPriority.Movement
  walk.Looped=true
 end
 if not walk.IsPlaying then walk:Play(.35,1,1)end
end
remote.OnClientEvent:Connect(function(d)
 if d.Type=="Initialize"then
  hidden=(d.Cleared and d.Cleared[1])==true or (d.Skipped and d.Skipped[1])==true
  refresh()
 elseif d.Type=="EnemyDefeated"and d.Stage==1 then
  hidden=true
  refresh()
 end
end)
workspace.DescendantAdded:Connect(function(d)
 if d.Name=="BallerinaCappuccinaRig"or d.Name=="Stage01Idle"or d.Name=="Stage01Walk"or d:IsA("Animator")or d:IsA("ParticleEmitter")or d:IsA("Trail")or d:IsA("Beam")then
  task.defer(refresh)
 end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type="RequestState"})
