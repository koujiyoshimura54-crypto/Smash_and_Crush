local P=game:GetService("Players").LocalPlayer
local Run=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local remote=RS:WaitForChild("WalkTestRequest",60)
local reply=RS:WaitForChild("WalkTestReply",60)
if not remote or not reply then return end
print("WALK_CAMERA_USER",P.Name)
local cameraLabel=Instance.new("ScreenGui",P:WaitForChild("PlayerGui"));cameraLabel.Name="__WalkCameraLabel"
local cameraText=Instance.new("TextLabel",cameraLabel);cameraText.Size=UDim2.fromOffset(260,24)
cameraText.Position=UDim2.new(.5,-130,0,0);cameraText.Text="Walk QA "..P.Name;cameraText.TextSize=18
Run:BindToRenderStep("__WalkAllClientsCamera",Enum.RenderPriority.Last.Value+100,function()
 local folder=workspace:FindFirstChild("World2Enemies")
 local owner=folder and folder:FindFirstChild("Owner_"..P.UserId)
 local enemy=owner and owner:FindFirstChildWhichIsA("Model")
 local visual=enemy and enemy:FindFirstChildWhichIsA("Model")
 if not visual then return end
 local cf,size=visual:GetBoundingBox()
 local elapsed=workspace:GetServerTimeNow()-(RS:GetAttribute("__WalkCameraStartedAt") or 0)
 local root=enemy.HumanoidRootPart
 local direction=elapsed<6 and root.CFrame.LookVector or root.CFrame.RightVector
 local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(cf.Position+(direction+Vector3.new(0,.2,0))*size.Magnitude*1.2,cf.Position)
end)
remote.OnClientEvent:Connect(function(key,action,stage,duration)
 if action=="Leave" then task.wait(.5);game:GetService("StudioTestService"):LeaveTest();return end
 task.spawn(function()
  local folder=workspace:WaitForChild("World2Enemies")
  local own=folder:WaitForChild("Owner_"..P.UserId,15)
  local enemy=own and own:FindFirstChild(("Stage%02d_Enemy"):format(stage))
  if not enemy then reply:FireServer(key,{Error="Actor not streamed"});return end
  local visual=enemy:FindFirstChildWhichIsA("Model")
  local root=enemy:FindFirstChild("HumanoidRootPart")
  local motors={};local first={},{}
  local limbs={}
  for _,x in visual:GetDescendants() do
   if x:IsA("Motor6D") and x.Part0 and x.Part1 then motors[x]=x.Transform end
   if x:IsA("BasePart") and (x.Name:find("Leg") or x.Name:find("Arm") or x.Name=="Head") then
    limbs[x]=root.CFrame:ToObjectSpace(x.CFrame)
   end
  end
  local changed={},{}
  local maxJoint,maxLimb,moved=0,0,0
  local start=os.clock()
  local camera=workspace.CurrentCamera
  local width=enemy:GetAttribute("BossDisplayHeight") or 15
  Run:BindToRenderStep("__WalkTestCamera",Enum.RenderPriority.Last.Value+10,function()
   local elapsed=os.clock()-start
   local center=root.Position+Vector3.new(0,width*.25,0)
   local direction=elapsed<(duration or 2)/2 and Vector3.new(0,.25,-1) or Vector3.new(1,.25,0)
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=CFrame.lookAt(center+direction*width*2.0,center)
  end)
  repeat
   local elapsed=os.clock()-start
   local center=root.Position+Vector3.new(0,width*.25,0)
   local direction=elapsed<(duration or 2)/2 and Vector3.new(0,.25,-1) or Vector3.new(1,.25,0)
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=CFrame.lookAt(center+direction*width*2.5,center)
   for m,before in motors do
    if m.Parent then local _,angle=before:ToObjectSpace(m.Transform):ToAxisAngle()
     maxJoint=math.max(maxJoint,math.abs(angle));if math.abs(angle)>.01 then changed[m.Name]=true end
    end
   end
   for part,before in limbs do
    if part.Parent then
     local delta=before:ToObjectSpace(root.CFrame:ToObjectSpace(part.CFrame))
     local _,angle=delta:ToAxisAngle();maxLimb=math.max(maxLimb,math.abs(angle))
    end
   end
   moved=math.max(moved,(root.Position-enemy:GetAttribute("ChaseHomePivot").Position).Magnitude)
   Run.Heartbeat:Wait()
  until os.clock()-start>=(duration or 2)
  Run:UnbindFromRenderStep("__WalkTestCamera")
  local tracks=0
  for _,x in visual:GetDescendants() do if x:IsA("Animator") then tracks+=#x:GetPlayingAnimationTracks() end end
  local names={};for name in changed do table.insert(names,name)end
  local foreigners=0
  for _,x in folder:GetDescendants() do
   if x:IsA("BasePart") and x:GetAttribute("BossVisualTransparency") and x:GetAttribute("OwnerUserId")~=P.UserId then
    local actor=x.Parent
    while actor and actor~=folder and actor:GetAttribute("OwnerUserId")==nil do actor=actor.Parent end
    if actor and actor~=folder and actor:GetAttribute("OwnerUserId")~=P.UserId and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then foreigners+=1 end
   end
  end
  reply:FireServer(key,{Stage=stage,JointRadians=maxJoint,LimbRadians=maxLimb,ChangedJoints=names,
   Moved=moved,Tracks=tracks,Animation=enemy:GetAttribute("LocalBossAnimation"),Rate=enemy:GetAttribute("LocalBossWalkRate"),ForeignVisibleParts=foreigners})
 end)
end)
