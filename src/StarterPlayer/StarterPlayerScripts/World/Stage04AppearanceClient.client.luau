local Binding=require(game.ReplicatedStorage.Modules:WaitForChild("World1BossPresentation"))
-- Personal visual state follows the server's existing combat snapshots.
local RS=game:GetService("ReplicatedStorage")
local rig,idle,animation,destroyConnection
local hidden=false
local originals={}
local missingIdWarned=false
local function releaseTrack()
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 if animation then animation:Destroy();animation=nil end
end
local function release()
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 releaseTrack()
 rig=nil
 originals={}
end
local function refresh()
 local enemy=Binding.Get(4)
 hidden=enemy==nil
 local current=enemy and enemy:FindFirstChild("BombardiroCrocodiloRig")
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
 if hidden then releaseTrack();return end
 if not idle then
  local controller=rig:FindFirstChildOfClass("AnimationController")
  local animator=controller and controller:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage04FlyingIdle")
  if not animator or not asset or not asset:IsA("Animation") then return end
  local id=asset.AnimationId
  if id=="" then
   if not missingIdWarned then warn("Stage04FlyingIdle requires a published AnimationId");missingIdWarned=true end
   return
  end
  animation=Instance.new("Animation")
  animation.AnimationId=id
  local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
  if not ok then animation:Destroy();animation=nil;warn("Stage04 Flying Idle could not load: "..tostring(result));return end
  idle=result
  idle.Name="Stage04FlyingIdle"
  idle.Priority=Enum.AnimationPriority.Idle
  idle.Looped=true
 end
 if not idle.IsPlaying then idle:Play(.15,1,1)end
end
local disconnect=Binding.Watch(4,refresh)
script.Destroying:Connect(function() disconnect();release() end)
