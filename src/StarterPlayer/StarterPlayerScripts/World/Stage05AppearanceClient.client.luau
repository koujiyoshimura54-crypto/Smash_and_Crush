local Binding=require(game.ReplicatedStorage.Modules:WaitForChild("World1BossPresentation"))
-- Personal visual state follows the server's existing combat snapshots.
local RS=game:GetService("ReplicatedStorage")
local rig,idle,animation,destroyConnection
local walk,walkAnimation
local function stopWalk()
 if walk then walk:Stop(0);walk:Destroy();walk=nil end
 if walkAnimation then walkAnimation:Destroy();walkAnimation=nil end
end
local hidden=false
local originals={}
local missingIdWarned=false
local function release()
 stopWalk()
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 if animation then animation:Destroy();animation=nil end
 rig=nil
 originals={}
end
local function refresh()
 local enemy=Binding.Get(5)
 hidden=enemy==nil
 local current=enemy and enemy:FindFirstChild("67Rig")
 if current~=rig then
  release()
  rig=current
  if rig then destroyConnection=rig.Destroying:Connect(release)end
 end
 if not rig then return end
 for _,d in rig:GetDescendants()do
  if d:IsA("ParticleEmitter")then
   if originals[d]==nil then originals[d]=d.Enabled end
   d.Enabled=not hidden and originals[d]
   if hidden then d:Clear()end
  end
 end
 if hidden then stopWalk();if idle then idle:Stop(0)end return end
 if not idle then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage05Idle")
  if not animator or not asset then return end
  local id=asset.AnimationId
  if id=="" then
   if not missingIdWarned then warn("Stage05 Idle_Fighting_67 requires a published AnimationId");missingIdWarned=true end
   return
  end
  animation=Instance.new("Animation")
  animation.AnimationId=id
  local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
  if not ok then animation:Destroy();animation=nil;warn("Stage05 idle could not load: "..tostring(result));return end
  idle=result
  idle.Priority=Enum.AnimationPriority.Idle
  idle.Looped=true
 end
 if not idle.IsPlaying then idle:Play(.15,1,1)end
 if not walk then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage05Walk")
  if animator and asset and asset:IsA("Animation") and asset.AnimationId~="" then
   walkAnimation=Instance.new("Animation")
   walkAnimation.AnimationId=asset.AnimationId
   local ok,result=pcall(function()return animator:LoadAnimation(walkAnimation)end)
   if ok then
    walk=result
    walk.Name="Stage05Walk"
    walk.Looped=true
    walk.Priority=Enum.AnimationPriority.Movement
   else
    stopWalk()
    warn("Stage05 walk could not load: "..tostring(result))
   end
  end
 end
 if walk and not walk.IsPlaying then walk:Play(.15,1,1)end
end
local disconnect=Binding.Watch(5,refresh)
script.Destroying:Connect(function() disconnect();release() end)
