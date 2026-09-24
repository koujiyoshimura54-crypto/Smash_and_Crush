-- Presentation only. Progress comes from existing server Attributes/CombatState.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local trained=false
local enteredWall=false
local trophy
local guide,anchor,bob
local targetKey
local resetSequence=player:GetAttribute("TutorialResetSequence")
local remoteConnection
local connections={}

local function clear()
 if bob then bob:Cancel();bob:Destroy();bob=nil end
 if guide then guide:Destroy();guide=nil end
 if anchor then anchor:Destroy();anchor=nil end
 targetKey=nil
end

local function show(key,position)
 if targetKey==key and guide and guide.Parent then
  anchor.Position=position
  return
 end
 clear()
 targetKey=key
 anchor=Instance.new("Part")
 anchor.Name="TutorialGuideAnchor"
 anchor.Size=Vector3.new(0.1,0.1,0.1)
 anchor.Anchored=true
 anchor.Transparency=1
 anchor.CanCollide=false
 anchor.CanTouch=false
 anchor.CanQuery=false
 anchor.Position=position
 anchor.Parent=workspace

 guide=Instance.new("BillboardGui")
 guide.Name="TutorialGuide"
 guide.Adornee=anchor
 guide.Size=UDim2.fromOffset(104,116)
 guide.AlwaysOnTop=false
 guide.LightInfluence=0
 guide.ResetOnSpawn=false
 guide.StudsOffsetWorldSpace=Vector3.zero
 -- Native UI strips form two solid chevrons with sharp peaks and vertical ends.
 -- No rotated clipping artifacts, text, borders, or external image assets.
 for row=1,2 do
  local chevron=Instance.new("Frame")
  chevron.Name="Chevron"..row
  chevron.BackgroundTransparency=1
  chevron.BorderSizePixel=0
  chevron.Position=UDim2.fromOffset(0,(row-1)*56)
  chevron.Size=UDim2.fromOffset(104,52)
  chevron.Parent=guide
  for column=0,103 do
   local strip=Instance.new("Frame")
   strip.Name="Stroke"
   strip.Position=UDim2.fromOffset(column,math.abs(column+0.5-52)*0.7)
   strip.Size=UDim2.fromOffset(1,22)
   strip.BackgroundColor3=Color3.new(1,1,1)
   strip.BorderSizePixel=0
   strip.Parent=chevron
  end
 end
 guide.Parent=playerGui
 bob=TweenService:Create(guide,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{
  StudsOffsetWorldSpace=Vector3.new(0,0.65,0)
 })
 bob:Play()
end

local function refresh()
 local completed=player:GetAttribute("TutorialCompleted")
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 -- nil means the existing data loader has not provided a saved value yet.
 if completed~=false or not humanoid or humanoid.Health<=0 then clear();return end
 if not trained then
  local treadmill=workspace:FindFirstChild("Tredmill01")
  local zone=treadmill and treadmill:FindFirstChild("TrainingZone")
  if zone and zone:IsA("BasePart") then
   show("Treadmill",zone.Position+Vector3.new(0,zone.Size.Y/2+2,0))
  else clear() end
 elseif not enteredWall then
  if (player:GetAttribute("Level") or 1)<2 then clear();return end
  local map=workspace:FindFirstChild("GeneratedMap")
  local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage01")
  local model=stage and stage:FindFirstChild("Stage1.1")
  local wall=model and model:FindFirstChild("Wall")
  if wall and wall:IsA("BasePart") then
   show("Wall1.1",wall.Position+Vector3.new(0,wall.Size.Y/2+3,0))
  else clear() end
 elseif trophy then
  show("Trophy"..trophy.Id,trophy.CFrame.Position+Vector3.new(0,3.5,0))
 else clear() end
end

local function trainingChanged()
 if player:GetAttribute("TutorialCompleted")==false and player:GetAttribute("IsTraining")==true then
  trained=true
 end
 refresh()
end
table.insert(connections,player:GetAttributeChangedSignal("IsTraining"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("Level"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialCompleted"):Connect(function()
 trainingChanged()
end))
table.insert(connections,player:GetAttributeChangedSignal("TutorialResetSequence"):Connect(function()
 local sequence=player:GetAttribute("TutorialResetSequence")
 if sequence~=resetSequence then
  resetSequence=sequence
  trained=false
  enteredWall=false
  trophy=nil
  clear()
  refresh()
 end
end))
table.insert(connections,player.CharacterRemoving:Connect(clear))
table.insert(connections,player.CharacterAdded:Connect(function() task.defer(refresh) end))

-- One display survives character respawns; streamed destinations may arrive later.
local elapsed=0
table.insert(connections,RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<0.2 then return end
 elapsed=0
 refresh()
end))
trainingChanged()
task.spawn(function()
 local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
 remoteConnection=remote.OnClientEvent:Connect(function(d)
  if typeof(d)~="table" then return end
  if d.Type=="Initialize" then
   trophy=nil
  elseif d.Type=="Fighting" and d.Active and d.CombatType=="Wall" and d.Stage==1 and d.WallIndex==1 then
   if trained and (player:GetAttribute("Level") or 1)>=2 then enteredWall=true end
  elseif d.Type=="TrophySpawn" and d.Stage==1 and typeof(d.Id)=="number" and typeof(d.CFrame)=="CFrame" then
   -- This existing event is FireClient(owner), never a shared world Trophy scan.
   trophy={Id=d.Id,CFrame=d.CFrame}
  elseif d.Type=="TrophyRemoved" and trophy and d.Id==trophy.Id then
   trophy=nil -- removal alone is not proof of collection; server sets completion.
  end
  refresh()
 end)
 remote:FireServer({Type="RequestState"})
end)
script.Destroying:Once(function()
 clear()
 if remoteConnection then remoteConnection:Disconnect() end
 for _,connection in connections do connection:Disconnect() end
end)
