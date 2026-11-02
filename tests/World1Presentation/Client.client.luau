-- Temporary native client observer: actual tracks, body transforms and full equipment visibility.
local RS=game.ReplicatedStorage
local player=game.Players.LocalPlayer
local request=RS:WaitForChild("__PresentationRequest")
local reply=RS:WaitForChild("__PresentationReply")
local function actor()
 local folder=workspace:FindFirstChild("Enemies")
 local owner=folder and folder:FindFirstChild("Owner_"..player.UserId)
 if owner then for _,x in owner:GetChildren() do if x:IsA("Model") then return x end end end
end
local function snapshot()
 local e=actor();local tracks={};local meshes,bones,motors=0,0,0
 if e then for _,x in e:GetDescendants() do
  if x:IsA("MeshPart") and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then meshes+=1 end
  if x:IsA("Bone") then bones+=1 end
  if x:IsA("Motor6D") then motors+=1 end
  if x:IsA("Animator") then for _,t in x:GetPlayingAnimationTracks() do
   table.insert(tracks,{Name=t.Name,Id=t.Animation and t.Animation.AnimationId,Length=t.Length,Time=t.TimePosition,Speed=t.Speed,Priority=t.Priority.Name})
  end end
 end end
 local trophies={}
 local corridor=workspace.GeneratedMap.BattleCorridor
 for i=1,10 do for _,name in {"TrophyNormalButton","TrophyDoubleButton"} do
  local root=corridor[("Stage%02d"):format(i)][name]
  local visible,enabled,gui=0,0,0
  for _,x in root:GetDescendants() do
   if (x:IsA("BasePart") or x:IsA("Decal")) and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then visible+=1 end
   if x:IsA("LayerCollector") and x.Enabled then gui+=1 end
   if (x:IsA("Light") or x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam")) and x.Enabled then enabled+=1 end
  end
  table.insert(trophies,{Stage=i,Double=name=="TrophyDoubleButton",VisibleParts=visible,EnabledGui=gui,EnabledEffects=enabled})
 end end
 local floor=workspace:FindFirstChild("TutorialFloorGuide");local arrows=0
 if floor then for _,x in floor:GetChildren() do if x:IsA("BasePart") and x.Transparency<1 then arrows+=1 end end end
 return {World=player:GetAttribute("CurrentWorld") or 1,Stage=e and e:GetAttribute("StageNumber"),
  Run=e and e:GetAttribute("RunRevision"),Generation=e and e:GetAttribute("SpawnGeneration"),Tracks=tracks,
  VisibleMeshes=meshes,Bones=bones,Motors=motors,Trophies=trophies,Arrows=arrows,
  ArrowTarget=floor and floor:GetAttribute("Target"),OreTarget=tostring(player:GetAttribute("OreTutorialTarget"))}
end
local function sample()
 local e=assert(actor());local root=e.HumanoidRootPart
 local before={};local maxPosition,maxAngle,changedBones,changedParts=0,0,0,0
 local function pose(x)
  if x:IsA("Bone") then return root.CFrame:ToObjectSpace(x.TransformedWorldCFrame) end
  if x:IsA("MeshPart") and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then return root.CFrame:ToObjectSpace(x.CFrame) end
 end
 for _,x in e:GetDescendants() do local p=pose(x);if p then before[x]=p end end
 local changed={}
 for _=1,10 do
  task.wait(.12)
  for x,p in before do
   if x.Parent then local now=pose(x);if now then
    local delta=p:ToObjectSpace(now);local _,angle=delta:ToAxisAngle();local distance=delta.Position.Magnitude
    maxPosition=math.max(maxPosition,distance);maxAngle=math.max(maxAngle,math.abs(angle))
    if distance>.001 or math.abs(angle)>.001 then changed[x]=true end
   end end
  end
 end
 for x in changed do if x:IsA("Bone") then changedBones+=1 else changedParts+=1 end end
 return {Snapshot=snapshot(),BodyMotion={MaxPosition=maxPosition,MaxAngle=maxAngle,ChangedBones=changedBones,ChangedVisibleParts=changedParts}}
end
local function run(action,value)
 if action=="Sample" then return sample()
 elseif action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(value==2 and "ToWorld2" or "ReturnWorld1");task.wait(1.5)
 elseif action=="OtherOwners" then
  local out={};for _,owner in workspace.Enemies:GetChildren() do if owner.Name~="Owner_"..player.UserId then
   local count,playing=0,0
   for _,x in owner:GetDescendants() do
    if x:IsA("BasePart") and x.Transparency<.99 and x.LocalTransparencyModifier<.99 then count+=1 end
    if x:IsA("Animator") then playing+=#x:GetPlayingAnimationTracks() end
   end
   table.insert(out,{VisibleParts=count,Tracks=playing})
  end end;return out
 end
 return snapshot()
end
local probe=Instance.new("BindableFunction");probe.Name="__PresentationClient";probe.OnInvoke=run;probe.Parent=RS
request.OnClientEvent:Connect(function(key,action,value)
 local ok,result=pcall(run,action,value);reply:FireServer(key,{OK=ok,Result=result})
end)
