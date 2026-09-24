-- Personal visual state follows the server's existing combat snapshots.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local FLOAT_AMPLITUDE=0.3
local FLOAT_PERIOD=3
local FLOAT_BASE_LIFT=0.3 -- Keep the lowest point at the fitted floor.
local floatConnection,floatWeld,floatBase
local function stopFloating()
 if floatConnection then floatConnection:Disconnect();floatConnection=nil end
 if floatWeld and floatWeld.Parent and floatBase then floatWeld.C0=floatBase end
 floatWeld=nil
 floatBase=nil
end
local function startFloating(model)
 if floatConnection then return end
 local root=model:FindFirstChild("RootPart")
 local weld=root and root:FindFirstChild("Stage02VisualRootWeld")
 if not weld or not weld:IsA("Weld")then return end
 floatWeld=weld
 floatBase=weld.C0
 local started=os.clock()
 floatConnection=RunService.PreSimulation:Connect(function()
  if not model.Parent or not weld.Parent then stopFloating();return end
  local offset=FLOAT_BASE_LIFT+FLOAT_AMPLITUDE*math.sin((os.clock()-started)*2*math.pi/FLOAT_PERIOD)
  local worldOffset=Vector3.new(0,offset,0)
  local localOffset=weld.Part0.CFrame:VectorToObjectSpace(worldOffset)
  weld.C0=CFrame.new(localOffset)*floatBase
 end)
end
local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local rig,idle,animation,destroyConnection
local hidden=false
local originals={}
local missingIdWarned=false
local function release()
 stopFloating()
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 if animation then animation:Destroy();animation=nil end
 rig=nil
 originals={}
end
local function refresh()
 local enemies=workspace:FindFirstChild("Enemies")
 local enemy=enemies and enemies:FindFirstChild("Stage02_Enemy")
 local current=enemy and enemy:FindFirstChild("TralaleroTralalaRig")
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
 if hidden then stopFloating();if idle then idle:Stop(0)end return end
 startFloating(rig)
 if not idle then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage02Idle")
  if not animator or not asset then return end
  local id=asset.AnimationId
  if id=="" then
   if not missingIdWarned then warn("Stage02 Idle_Breathing_Tralalero requires a published AnimationId");missingIdWarned=true end
   return
  end
  animation=Instance.new("Animation")
  animation.AnimationId=id
  local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
  if not ok then animation:Destroy();animation=nil;warn("Stage02 idle could not load: "..tostring(result));return end
  idle=result
  idle.Priority=Enum.AnimationPriority.Idle
  idle.Looped=true
 end
 if not idle.IsPlaying then idle:Play(.15,1,1)end
end
remote.OnClientEvent:Connect(function(d)
 if d.Type=="Initialize"then
  hidden=(d.Cleared and d.Cleared[2])==true or (d.Skipped and d.Skipped[2])==true
  refresh()
 elseif d.Type=="EnemyDefeated"and d.Stage==2 then
  hidden=true
  refresh()
 end
end)
workspace.DescendantAdded:Connect(function(d)
 if d.Name=="Stage02VisualRootWeld"or d.Name=="TralaleroTralalaRig"or d.Name=="Stage02Idle"or d:IsA("Animator")or d:IsA("ParticleEmitter")or d:IsA("Trail")or d:IsA("Beam")then
  task.defer(refresh)
 end
end)
script.Destroying:Connect(release)
refresh()
remote:FireServer({Type="RequestState"})
