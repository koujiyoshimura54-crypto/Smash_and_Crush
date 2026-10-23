local P=game.Players.LocalPlayer
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local request=RS:WaitForChild('__SCP096TestRequest')
local reply=RS:WaitForChild('__SCP096TestReply')
local captures={}
local live
local function ownerActor()
 local folder=workspace:FindFirstChild('World2Enemies')
 local owner=folder and folder:FindFirstChild('Owner_'..P.UserId)
 return owner and owner:FindFirstChild('Stage01_Enemy')
end
-- Native test windows can suspend rendering while simulation still advances.
-- This measures replicated simulation poses, not a rendered visual acceptance.
Run.Heartbeat:Connect(function()
 local actor=ownerActor()
 if actor and actor~=live then
  local visual=actor:FindFirstChild('SCP-096')
  local mesh=visual and visual:FindFirstChild('Body.LP')
  if not mesh then return end
  local bones={};for _,d in mesh:GetDescendants() do if d:IsA('Bone') then table.insert(bones,d) end end
  if #bones~=73 then return end
  live=actor
  captures[actor]={Generation=actor:GetAttribute('SpawnGeneration'),Bones=bones,Mesh=mesh,
   Phases={},Changes={},Previous={},FirstRoot=actor:GetPivot(),MaxTravel=0,Visible=false,
   MinFootY=math.huge,MaxFootY=-math.huge}
 end
 local r=actor and captures[actor]
 if not r then return end
 local phase=actor:GetAttribute('LocalBossAnimation') or 'Loading'
 if r.LastPhase~=phase then table.insert(r.Phases,{Phase=phase,Time=workspace:GetServerTimeNow()});r.LastPhase=phase end
 local changed=0
 for _,bone in r.Bones do
  if r.Previous[bone] and r.Previous[bone]~=bone.Transform then changed+=1 end
  r.Previous[bone]=bone.Transform
  if bone.Name=='L.Toes' or bone.Name=='R.Toes' then
   local map=workspace:FindFirstChild('World2Map')
   local corridor=map and map:FindFirstChild('BattleCorridor')
   local stage=corridor and corridor:FindFirstChild('Stage01')
   local floor=stage and stage:FindFirstChild('Floor')
   if floor then
    local y=bone.TransformedWorldCFrame.Position.Y-floor.Position.Y-floor.Size.Y/2
    r.MinFootY=math.min(r.MinFootY,y);r.MaxFootY=math.max(r.MaxFootY,y)
   end
  end
 end
 r.Changes[phase]=math.max(r.Changes[phase] or 0,changed)
 r.MaxTravel=math.max(r.MaxTravel,(actor:GetPivot().Position-r.FirstRoot.Position).Magnitude)
 r.Visible=r.Visible or r.Mesh.Transparency<.99 and r.Mesh.LocalTransparencyModifier<.99
end)
request.OnClientEvent:Connect(function(key,action,generation)
 if action=='Leave' then game:GetService('StudioTestService'):LeaveTest();return end
 if action=='Mounted' then
  task.spawn(function()
   local deadline=os.clock()+12
   repeat
    local actor=ownerActor()
    if actor and actor:GetAttribute('SpawnGeneration')==generation and actor:GetAttribute('LocalBossAnimation') then
     reply:FireServer(key,{Mounted=true});return
    end
    task.wait(.05)
   until os.clock()>deadline
   reply:FireServer(key,{Mounted=false})
  end)
  return
 end
 local result={Actors={},ForeignVisible=0,Tracks=0}
 for actor,r in captures do
  table.insert(result.Actors,{Generation=r.Generation,Phases=r.Phases,Changes=r.Changes,
   MaxTravel=r.MaxTravel,Visible=r.Visible,BoneCount=#r.Bones,MinFootY=r.MinFootY,MaxFootY=r.MaxFootY})
 end
 local folder=workspace:FindFirstChild('World2Enemies')
 if folder then for _,owner in folder:GetChildren() do
  for _,d in owner:GetDescendants() do
   if owner.Name~='Owner_'..P.UserId and d:IsA('BasePart') and d.Transparency<.99 and d.LocalTransparencyModifier<.99 then result.ForeignVisible+=1 end
   if owner.Name=='Owner_'..P.UserId and d:IsA('Animator') then result.Tracks+=#d:GetPlayingAnimationTracks() end
  end
 end end
 local diag=script.Parent.World2BossAnimationClient:FindFirstChild('__SCP096Diagnostics')
 if diag then result.Diagnostics=diag:Invoke() end
 reply:FireServer(key,result)
end)
