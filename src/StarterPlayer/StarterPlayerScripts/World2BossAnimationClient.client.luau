-- Owner-only cosmetic animation; server chase/combat remains authoritative.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Config:WaitForChild("World2BossAnimationConfig"))
local Rig=require(RS.Modules:WaitForChild("World2BossRig"))
local Clip=require(RS.Modules:WaitForChild("World2BossClip"))
local Gait=require(RS.Modules:WaitForChild("World2BossGait"))
local Body096=require(RS.Modules:WaitForChild("World2SCP096Clip"))
local player=Players.LocalPlayer
local records={}
local cache={}
local alive=true
local function clean(enemy)
 local r=records[enemy];records[enemy]=nil
 if not r then return end
 r.Retired=true
 if r.Track then r.Track:Stop(0);r.Track:Destroy() end
 if r.Animation then r.Animation:Destroy() end
 if r.WalkClip then Clip.Reset(r.WalkClip) end
 if r.IntroClip then Clip.Reset(r.IntroClip) end
 if r.Gait then Gait.Reset(r.Gait) end
 if r.Body096 then Body096.Reset(r.Body096) end
end
local function add(enemy)
 if not alive or not enemy:IsA("Model") or records[enemy] or enemy:GetAttribute("OwnerUserId")~=player.UserId then return end
 local stage=enemy:GetAttribute("StageNumber")
 local entry=Config.Stages[stage]
 if not entry then return end
 local visual=enemy:FindFirstChild("SCP-"..({[1]="096",[2]="023",[3]="035",[4]="058",[5]="049",[6]="173",[7]="939",[8]="106",[9]="682",[10]="323"})[stage])
 local root=enemy:FindFirstChild("HumanoidRootPart")
 local hum=visual and visual:FindFirstChildWhichIsA("Humanoid",true)
 local animator=hum and hum:FindFirstChildOfClass("Animator")
 if entry.Rig=="SCP096Skin" then
  if not visual or not root then return end
  local ok,body=pcall(Body096.Compile,visual)
  if not ok then return end -- bounded mount retries wait for Bones and all five saved clips
  records[enemy]={Enemy=enemy,Visual=visual,Root=root,Last=root.Position,Entry=entry,Started=os.clock(),Body096=body}
  return
 end
 if not visual or not root or not entry.Gait and not animator then return end
 local connected=0
 for _,x in visual:GetDescendants() do
  if x:IsA("Motor6D") and x.Part0 and x.Part1 then connected+=1 end
 end
 if connected<(entry.MinMotors or ((entry.Rig=="R6" or entry.Rig=="SCP096") and 6 or 15)) then return end
 local gait
 if entry.Gait then
  local ok,value=pcall(Gait.Compile,visual,stage)
  if not ok then return end -- bounded mount retries wait for complete replicated joints
  gait=value
 end
 local r={Enemy=enemy,Visual=visual,Root=root,Last=root.Position,Entry=entry,Moving=false,
  LegLength=Rig.LegLength(visual,entry.Retarget~=nil),Started=os.clock(),Clock=0}
 r.Gait=gait;records[enemy]=r
 if gait then return end -- these joints have exactly one writer and no animation track
 local sequence=Rig.Intro(visual,stage)
 if sequence then
  local ok,clip=pcall(Clip.Compile,sequence,visual)
  if ok then r.IntroClip=clip else warn("[World2BossAnimation] Idle: "..tostring(clip)) end
 end
 task.spawn(function()
  local ok,err=pcall(function()
   if entry.Retarget then
    local sequence=cache[entry.Walk]
    if not sequence then
     sequence=game:GetService("KeyframeSequenceProvider"):GetKeyframeSequenceAsync(entry.Walk)
     cache[entry.Walk]=sequence
    end
    if records[enemy]~=r then return end
    local deadline=os.clock()+Config.LoadTimeout
    local why
    repeat
     if records[enemy]~=r then return end
     local ready,clip=pcall(Clip.Compile,sequence,visual,true,entry.RetargetWeight)
     if ready then r.WalkClip=clip;return end
     why=clip;task.wait(.1)
    until os.clock()>=deadline
    error(why)
   else
    local animation=Instance.new("Animation")
    animation.Name="ApprovedWorld2Walk";animation.AnimationId=entry.Walk
    r.Animation=animation
    r.Track=animator:LoadAnimation(animation)
    r.Track.Looped=true;r.Track.Priority=Enum.AnimationPriority.Movement
   end
  end)
  if not ok and records[enemy]==r then r.Failed=true;warn("[World2BossAnimation] Walk: "..tostring(err)) end
 end)
end
local folder=workspace:WaitForChild("World2Enemies")
local pending={}
local function queue(enemy)
 if not enemy:IsA("Model") or not enemy.Name:match("^Stage%d%d_Enemy$") or records[enemy] or pending[enemy] then return end
 pending[enemy]=true
 task.spawn(function()
  local deadline=os.clock()+Config.LoadTimeout
  repeat
   local owner=enemy:GetAttribute("OwnerUserId")
   local stage=enemy:GetAttribute("StageNumber")
   if not alive or owner and owner~=player.UserId or stage and not Config.Stages[stage] then break end
   add(enemy)
   if records[enemy] or not enemy.Parent then break end
   task.wait(.1)
  until os.clock()>=deadline
  pending[enemy]=nil
  if alive and enemy:IsDescendantOf(folder) and enemy:GetAttribute("OwnerUserId")==player.UserId and not records[enemy]
   and Config.Stages[enemy:GetAttribute("StageNumber")] then warn("[World2BossAnimation] Rig mount timed out: "..enemy.Name) end
 end)
end
local added=folder.DescendantAdded:Connect(queue)
for _,x in folder:GetDescendants() do queue(x) end
local heartbeat=Run.PreSimulation:Connect(function(dt)
 for enemy,r in records do
  if not enemy:IsDescendantOf(folder) or player:GetAttribute("CurrentWorld")~=2 then clean(enemy);continue end
  local position=r.Root.Position
  local speed=(Vector3.new(position.X,0,position.Z)-Vector3.new(r.Last.X,0,r.Last.Z)).Magnitude/math.max(dt,.001)
  r.Last=position
  -- Replication arrives in packets. Preserve their measured distance/time over a
  -- short window, while server MotionSpeed explicitly clears contact/idle stops.
  speed=enemy:GetAttribute("BossMotionSpeed") or speed
  if r.Body096 then
   local phase=enemy:GetAttribute("SCP096Phase") or "Waiting"
   local active=speed>Config.MoveThreshold or enemy:GetAttribute("SCP096AttackEligible")==true
   Body096.Update(r.Body096,phase,enemy:GetAttribute("SCP096PhaseStartedAt") or 0,
    workspace:GetServerTimeNow(),active,enemy:GetAttribute("SCP096PhaseRevision") or 0)
   enemy:SetAttribute("LocalBossAnimation",phase)
   continue
  end
  local intro=enemy:GetAttribute("BossIntroState")=="Playing"
  if intro and r.IntroClip then
   if r.Track and r.Track.IsPlaying then r.Track:Stop(0) end
   local elapsed=math.clamp(workspace:GetServerTimeNow()-(enemy:GetAttribute("BossIntroStartedAt") or 0),0,r.IntroClip.Duration)
   Clip.Sample(r.IntroClip,elapsed);r.InIntro=true;r.Moving=false
   enemy:SetAttribute("LocalBossAnimation","Intro")
  else
   if r.InIntro then Clip.Reset(r.IntroClip);r.InIntro=false end
   local available=r.Track~=nil or r.WalkClip~=nil or r.Gait~=nil
   local moving=available and not intro and speed>Config.MoveThreshold
   local rate=speed/(Config.ReferenceSpeed*r.LegLength/Config.ReferenceLegLength)/(r.Entry.RetargetWeight or 1)
   if r.Gait then
    Gait.Update(r.Gait,dt,moving and speed or 0)
    rate=speed/r.Entry.Gait.ReferenceSpeed
   elseif moving then
    if r.Track then
     if not r.Track.IsPlaying then r.Track:Play(Config.FadeTime,1,rate) else r.Track:AdjustSpeed(rate) end
    elseif r.WalkClip then
     r.Clock=(r.Clock+dt*rate)%r.WalkClip.Duration;Clip.Sample(r.WalkClip,r.Clock)
    end
   else
    if r.Track and r.Track.IsPlaying then r.Track:Stop(Config.FadeTime) end
    if r.WalkClip and r.Moving then Clip.Reset(r.WalkClip) end
   end
   r.Moving=moving
   enemy:SetAttribute("LocalBossAnimation",not available and (r.Failed and "Failed" or "Loading") or moving and "Walk" or "Stopped")
   enemy:SetAttribute("LocalBossWalkRate",rate)
  end
  if not r.Warned and os.clock()-r.Started>Config.LoadTimeout and
   (r.Track and r.Track.Length==0 or not r.Track and not r.WalkClip and not r.Gait) then
   r.Warned=true;r.Failed=true;warn("[World2BossAnimation] Walk load timed out: "..r.Entry.Walk)
  end
 end
end)
local worldChanged=player:GetAttributeChangedSignal("CurrentWorld"):Connect(function()
 if player:GetAttribute("CurrentWorld")~=2 then for enemy in records do clean(enemy) end
 else for _,x in folder:GetDescendants() do queue(x) end end
end)
script.Destroying:Connect(function()
 alive=false
 heartbeat:Disconnect();added:Disconnect();worldChanged:Disconnect();for enemy in records do clean(enemy) end
end)
