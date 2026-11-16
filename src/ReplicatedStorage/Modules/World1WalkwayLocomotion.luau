-- Locomotion only. Never changes Animate, Humanoid.WalkSpeed, or action tracks.
-- Matches current R15 Animate onRunning/setRunSpeed normalization (16, 1.25,
-- height scaling, walk/run blend). Feed voluntary speed instead of belt speed.
local M={}
local EPSILON=.0001
local function animationHipHeight(character,humanoid)
 -- Current engine Animate measures the leg attachment chain for a single
 -- collider avatar. Its physical HipHeight need not equal animation leg height.
 local collider=character:FindFirstChild("CollisionPart")
 local weld=collider and collider:FindFirstChildOfClass("Weld")
 local torso=character:FindFirstChild("LowerTorso")
 if not torso or not weld or weld.Part1~=character:FindFirstChild("HumanoidRootPart") then return humanoid.HipHeight end
 local function y(part,name)
  local a=part and part:FindFirstChild(name)
  return a and a:IsA("Attachment") and a.Position.Y or 0
 end
 local hips={torso:FindFirstChild("LeftHipRigAttachment"),torso:FindFirstChild("RightHipRigAttachment")}
 if not hips[1] and not hips[2] then return humanoid.HipHeight end
 local line=math.min(hips[1] and hips[1].Position.Y or math.huge,hips[2] and hips[2].Position.Y or math.huge)
 local heights={}
 for i,side in {"Left","Right"} do
  local upper=character:FindFirstChild(side.."UpperLeg")
  local lower=character:FindFirstChild(side.."LowerLeg")
  local foot=character:FindFirstChild(side.."Foot")
  local length=y(upper,side.."HipRigAttachment")-y(upper,side.."KneeRigAttachment")
   +y(lower,side.."KneeRigAttachment")-y(lower,side.."AnkleRigAttachment")
   +(foot and y(foot,side.."AnkleRigAttachment")+foot.Size.Y/2 or 0)
  heights[i]=line-y(torso,side.."HipRigAttachment")+length
 end
 local large=math.max(heights[1],heights[2])
 local height=math.abs(heights[1]-heights[2])<large*.05 and math.min(heights[1],heights[2]) or large
 return height>0 and height or humanoid.HipHeight
end
local function normalRate(character,humanoid,animate,speed)
 local scale=character:GetScale()
 if humanoid.AutomaticScalingEnabled then
  local hipHeight=animationHipHeight(character,humanoid)
  scale=hipHeight/2
  local dampening=animate and animate:FindFirstChild("ScaleDampeningPercent")
  if dampening then scale=1+(hipHeight-2)*dampening.Value/2 end
 end
 local normalized=speed*1.25/(16*math.max(scale,.01))
 if normalized<=.5 then return normalized/.5,1,EPSILON end
 if normalized<1 then local run=(normalized-.5)/.5;return 1,1-run,run end
 return normalized,EPSILON,1
end
function M.new(character,humanoid)
 local self={}
 local animate,animator,idleTrack
 local ids={}
 local overridden={}
 local active=false
 local floorRate,floorSpeed,floorHip,floorScale
 local observeAfter=0
 local function collect()
  local nextAnimate=character:FindFirstChild("Animate")
  if nextAnimate==animate and next(ids) then return end
  animate=nextAnimate;table.clear(ids)
  if animate then for _,kind in {"walk","run"} do
   local container=animate:FindFirstChild(kind)
   if container then for _,animation in container:GetDescendants() do
    if animation:IsA("Animation") then
     local id=animation.AnimationId:match("%d+$");if id then ids[id]=kind end
    end
   end end
  end end
 end
 local function voluntarySpeed()
  local velocity=humanoid:GetMoveVelocity()
  return Vector3.new(velocity.X,0,velocity.Z).Magnitude
 end
 local function playback(speed)
  local rate,walkWeight,runWeight=normalRate(character,humanoid,animate,speed)
  -- Animate updates on Running events, not every physical frame. Reuse its
  -- observed normal-floor rate for the same input speed and rig when available,
  -- including its event threshold, instead of making that gait slightly faster.
  if floorRate and math.abs(speed-floorSpeed)<.01
   and math.abs(animationHipHeight(character,humanoid)-floorHip)<.001
   and math.abs(character:GetScale()-floorScale)<.001 then rate=floorRate end
  return rate,walkWeight,runWeight
 end
 local function idle(enabled)
  if enabled and not idleTrack and animator and animate then
   local container=animate:FindFirstChild("idle")
   local animation=container and container:FindFirstChildWhichIsA("Animation",true)
   if animation then
    idleTrack=animator:LoadAnimation(animation)
    idleTrack.Name="World1WalkwayIdle";idleTrack.Priority=Enum.AnimationPriority.Core;idleTrack.Looped=true
   end
  end
  if idleTrack then
   if enabled then if not idleTrack.IsPlaying then idleTrack:Play(.15,1,1) end
   elseif idleTrack.IsPlaying then idleTrack:Stop(.15) end
  end
 end
 local function restore()
  if not active then return end
  active=false;idle(false)
  -- Restore normal-floor rates; Animate owns subsequent state changes.
  local rate,walkWeight,runWeight=playback(voluntarySpeed())
  for track,kind in overridden do if track.IsPlaying then
   track:AdjustSpeed(rate);track:AdjustWeight(kind=="walk" and walkWeight or runWeight,.1)
  end end
  table.clear(overridden)
  observeAfter=os.clock()+.25
 end
 function self:Update(enabled,canObserve)
  collect();animator=humanoid:FindFirstChildOfClass("Animator")
  if not animator or not next(ids) then restore();return end
  local speed=voluntarySpeed()
  if not enabled or humanoid.Health<=0 then
   restore()
   local root=character:FindFirstChild("HumanoidRootPart")
   local velocity=root and root.AssemblyLinearVelocity or Vector3.zero
   if canObserve and humanoid:GetState()==Enum.HumanoidStateType.Running
    and os.clock()>=observeAfter and speed>.05
    and math.abs(Vector3.new(velocity.X,0,velocity.Z).Magnitude-speed)<speed*.05 then
    for _,track in animator:GetPlayingAnimationTracks() do
     local id=track.Animation and track.Animation.AnimationId:match("%d+$")
     if id and ids[id] and track.Priority==Enum.AnimationPriority.Core and track.WeightCurrent>.5 and track.Speed>0 then
      floorRate=track.Speed;floorSpeed=speed;floorHip=animationHipHeight(character,humanoid);floorScale=character:GetScale()
     end
    end
   end
   return
  end
  active=true
  local rate,walkWeight,runWeight=playback(speed)
  for _,track in animator:GetPlayingAnimationTracks() do
   local id=track.Animation and track.Animation.AnimationId:match("%d+$")
   local kind=id and ids[id]
   -- Treadmill uses Movement; attacks/tools use Action. ID alone is unsafe.
   if kind and track.Priority==Enum.AnimationPriority.Core and track~=idleTrack then
    overridden[track]=kind
    track:AdjustSpeed(rate)
    track:AdjustWeight(speed>.05 and (kind=="walk" and walkWeight or runWeight) or EPSILON,0)
   end
  end
  idle(speed<=.05)
 end
 function self:Destroy()
  restore()
  if idleTrack then idleTrack:Destroy();idleTrack=nil end
 end
 return self
end
return M
