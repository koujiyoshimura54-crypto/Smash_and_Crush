local Binding=require(game.ReplicatedStorage.Modules:WaitForChild("World1BossPresentation"))
local GroundContact=require(game.ReplicatedStorage.Modules:WaitForChild("Stage03GroundContact"))
-- Idle follows the same personal defeat state as CombatClient.
-- Action-priority attacks override Idle without changing their timing.
local rig,idle,walk,destroyConnection
local removeGround,groundValid
local hidden=false
local function release()
 if removeGround then removeGround();removeGround=nil;groundValid=nil end
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if idle then idle:Stop(0);idle:Destroy();idle=nil end
 if walk then walk:Stop(0);walk:Destroy();walk=nil end
 rig=nil
end
local function refresh()
 local enemy=Binding.Get(3)
 hidden=enemy==nil
 local current=enemy and enemy:FindFirstChild("TungTungSahurRig")
 if current~=rig then release()end
 if hidden then
  if idle then idle:Stop(0)end
  if walk then walk:Stop(0)end
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
 -- Stage03 test-only: the boss is fixed in place, so preview Walk while visible.
 if not walk then
  local humanoid=rig:FindFirstChildOfClass("Humanoid")
  local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
  local asset=rig:FindFirstChild("Stage03Walk")
  if animator and asset then
   local ok,result=pcall(function() return animator:LoadAnimation(asset) end)
   if ok then
    walk=result
    walk.Priority=Enum.AnimationPriority.Movement
    walk.Looped=true
   else warn("Stage03 walk animation could not load: "..tostring(result)) end
  end
 end
 if walk and not walk.IsPlaying then walk:Play(0.15,1,1); walk:AdjustSpeed(0.6) end
 if removeGround and not groundValid()then removeGround();removeGround=nil;groundValid=nil end
 if not removeGround then removeGround,groundValid=GroundContact.Mount(rig)end
end
local disconnect=Binding.Watch(3,refresh)
script.Destroying:Connect(function() disconnect();release() end)
