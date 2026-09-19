local Stage03AttackVisual=require(script.Parent:WaitForChild("Stage03AttackVisual"))
local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")local T=game:GetService("TweenService")local RunService=game:GetService("RunService")
local R=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
local NumberFormat=require(RS.Modules:WaitForChild("NumberFormat"))
-- Fixed world-space UI metrics from the original 27-stud Wall, 580x270 canvas.
-- Resize the canvas with the physical wall: text pixels and bar height no longer stretch.
local BossDisplayConfig=require(RS.Config:WaitForChild("BossDisplayConfig"))
local bossSurfaces={}
local WallGaugeLayout={}
WallGaugeLayout.StageGapStuds=1
local function metrics(wall,surface)
 local height=wall.Size.Y
 surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 surface.CanvasSize=Vector2.new(580,height*10)
 return height,4.32,5.13
end
function WallGaugeLayout.ApplyBoss(wall,reference,gui,stageNumber)
 local height,_,barHeight=metrics(wall,gui)
 -- Only canvas conversion uses surface height; the world-space HP center is Boss based.
 local centerY=gui:GetAttribute("BossDisplayCenterY")
 local center=wall.CFrame:PointToObjectSpace(Vector3.new(wall.Position.X,centerY,wall.Position.Z)).Y+height/2
 local bottom=center-barHeight/2
 gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize
 gui.CanvasSize=Vector2.new(580,height*10)
 local sourceBar=reference.Panel.HPBar
 local bar=gui:FindFirstChild("HPBar")
 if not bar then return end
 local y=1-(bottom+barHeight)/height
 bar.Position=UDim2.new(sourceBar.Position.X.Scale,sourceBar.Position.X.Offset,y,0)
 bar.Size=UDim2.new(sourceBar.Size.X.Scale,sourceBar.Size.X.Offset,barHeight/height,0)
 local hp=gui:FindFirstChild("HPLabel")
 if hp then
  hp.Position=UDim2.new(bar.Position.X.Scale+.01,0,y+.02*barHeight/height,0)
  hp.Size=UDim2.new(bar.Size.X.Scale-.02,0,.96*barHeight/height,0)
 end
 local stage=gui:FindFirstChild("StageNumber")
 local name=gui:FindFirstChild("BossName")
 local stageHeight=3.5
 local nameHeight=stageNumber==9 and 12 or 6
 local stageBottom=bottom+barHeight+WallGaugeLayout.StageGapStuds
 if stage then stage.Position=UDim2.new(0,8,1-(stageBottom+stageHeight)/height,0);stage.Size=UDim2.new(1,-16,stageHeight/height,0) end
 if name then name.Position=UDim2.new(0,8,1-(stageBottom+stageHeight+.4+nameHeight)/height,0);name.Size=UDim2.new(1,-16,nameHeight/height,0) end
end

local bossSuppressed={}
local TrophyConfig=require(RS.Config:WaitForChild("TrophyRewardConfig"))
local RIGHT_PUNCH_ANIMATION_ID = "rbxassetid://121823319369216"
local LEFT_PUNCH_ANIMATION_ID  = "rbxassetid://87608603137173"
local PUNCH_SOUND_ID="rbxassetid://139897497838184"
local DEFEAT_SOUND_ID="rbxassetid://128974899749995"
local folder=Instance.new("Folder")folder.Name="PersonalCombatVisuals"folder.Parent=workspace
local fills,gates,defeated={},{},{} local track,sound local currentStage=P:GetAttribute("CurrentStage") or 1
local wallGauges,wallState={},{ }
local wallParts={}
local activeCombatType,activeCombatStage,activeWallIndex
local recommendationGui
local trophyVisuals={}
local function clearTrophy(id)
 if id~=nil then
  local visual=trophyVisuals[id]
  if visual then visual:Destroy();trophyVisuals[id]=nil end
  return
 end
 for key,visual in trophyVisuals do visual:Destroy();trophyVisuals[key]=nil end
end
local function showTrophy(d)
 local existing=trophyVisuals[d.Id]
 if existing and existing.Parent then return end
 local visual=RS.UI.Templates:WaitForChild("TrophyRewardTemplate"):Clone()
 visual.Name="PersonalTrophy"
 visual:SetAttribute("TrophyId",d.Id)
 visual:SetAttribute("MajorStage",d.Stage)
 visual:SetAttribute("WinReward",TrophyConfig.GetBaseReward(d.Stage))
 visual:PivotTo(d.CFrame)
 visual.Parent=workspace
 trophyVisuals[d.Id]=visual
 local button=visual:FindFirstChild("FloorButton")
 local core=button and button:FindFirstChild("Core")
 local light=core and core:FindFirstChildOfClass("SpotLight")
 if light then
  local pulse=T:Create(light,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Brightness=1.65})
  visual.Destroying:Once(function() pulse:Cancel();pulse:Destroy() end)
  pulse:Play()
 end
end
local function wallModel(a,b)
 local major,index=1,a; if b~=nil then major,index=a,b end
 local map=workspace:FindFirstChild("GeneratedMap") local bc=map and map:FindFirstChild("BattleCorridor") local st=bc and bc:FindFirstChild(("Stage%02d"):format(major))
 return st and st:FindFirstChild(("Stage%d.%d"):format(major,index))
end
local function wallSurface(major,index)
 local m=wallModel(major,index)
 local wall=m and m:FindFirstChild("Wall")
 return wall,wall and wall:FindFirstChild("StageSurface")
end
local function setWallStageDisplay(major,index,on)
 local wall,surface=wallSurface(major,index)
 if surface then
  surface:SetAttribute("PersonalStageDisplayEnabled",on==true)
  surface.Enabled=on==true and wall.LocalTransparencyModifier<.99 and wall.Transparency<.99
 end
end
local function showBossRecommendation(major,v)
 local map=workspace:FindFirstChild("GeneratedMap"); local bc=map and map:FindFirstChild("BattleCorridor"); local st=bc and bc:FindFirstChild(("Stage%02d"):format(major)); local m=st and st:FindFirstChild(("Stage%d.5"):format(major)); local floor=m and m:FindFirstChild("Floor")
 if not floor then return end
 if recommendationGui then recommendationGui:Destroy() end
 local g=Instance.new("BillboardGui"); g.Name="BossRecommendedLevel"; g.Adornee=floor; g.Size=UDim2.fromOffset(112,32); g.StudsOffset=Vector3.new(-14,3,0); g.AlwaysOnTop=true; g.Parent=floor
 local l=Instance.new("TextLabel"); l.Size=UDim2.fromOffset(112,32); l.BackgroundTransparency=1; l.Text=("Recommended Lv. %d"):format(v); l.TextColor3=Color3.fromRGB(255,235,170); l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Parent=g
 recommendationGui=g
end
local function hideBossRecommendation() if recommendationGui then recommendationGui:Destroy(); recommendationGui=nil end end
local function setWallVisible(a,b,c)
 local major,index,on=1,a,b; if c~=nil then major,index,on=a,b,c end
 local m=wallModel(major,index) if not m then return end
 for _,x in m:GetDescendants() do
  if x:IsA("BasePart") and x.Name=="Wall" then
   wallParts[x]={Major=major,Index=index}
   x.LocalTransparencyModifier=on and 0 or 1
   x.CanCollide=on
  end
 end
end
local function wallGauge(a,b,c,d)
 local major,index,v,max=1,a,b,c; if d~=nil then major,index,v,max=a,b,c,d end
 local m=wallModel(major,index)
 local w,gui=wallSurface(major,index)
 local panel=gui and gui:FindFirstChild("Panel")
 local bar=panel and panel:FindFirstChild("HPBar")
 if not bar then return end
 local state=wallState[major]
 bar.Visible=major==currentStage and state~=nil and not state.Skipped and state.Current==index and not state.Cleared[index]
 bar.Fill.Size=UDim2.fromScale(max>0 and math.clamp(v/max,0,1) or 0,1)
 bar.HPLabel.Text=NumberFormat.Format(v).." / "..NumberFormat.Format(max)
 wallGauges[tostring(major).."."..tostring(index)]={Fill=bar.Fill,HP=bar.HPLabel,Max=max}
end
-- One renderer for every Stage; server snapshots and clear/gauge notifications
-- remain authoritative, including after a Wall streams back into the client.
local function isWallClosed(major,index)
 local state=wallState[major]
 return not state or not (state.Skipped or state.Cleared[index] or index<state.Current)
end
local function clearWallGauge(major,index)
 local m=wallModel(major,index)
 local wall=m and m:FindFirstChild("Wall")
 local surface=wall and wall:FindFirstChild("StageSurface")
 local panel=surface and surface:FindFirstChild("Panel")
 local bar=panel and panel:FindFirstChild("HPBar")
 if bar then bar.Visible=false end
 wallGauges[tostring(major).."."..tostring(index)]=nil
end
local function renderWallStage(major)
 local state=wallState[major]
 for index=1,4 do
  local closed=isWallClosed(major,index)
  setWallVisible(major,index,closed)
  setWallStageDisplay(major,index,state~=nil and closed and not state.Skipped and major==currentStage and state.Current==index)
  if state and closed and not state.Skipped then
   wallGauge(major,index,state.Gauges[index],state.Maxes[index])
  else
   clearWallGauge(major,index)
  end
 end
end
local function enemy(n)return workspace:WaitForChild("Enemies"):WaitForChild(("Stage%02d_Enemy"):format(n))end
local function bossName(e)
 local visual=e:FindFirstChildOfClass("Model")
 if not visual then return e.Name end
 local name=visual.Name
 -- Imported rig suffixes are implementation names; preserve authored asset names otherwise.
 if name:match("Rig$") then name=name:gsub("Rig$",""):gsub("(%l)(%u)","%1 %2") end
 return name
end
local function bossWall(n)
 if n<10 then return wallSurface(n+1,1) end
 local m=wallModel(10,4)
 local stage=m and m.Parent
 local _,reference=wallSurface(10,4)
 return stage and stage:FindFirstChild("Stage10BoundaryWall"),reference
end
local function bossDisplayEnabled(n)
 local state=wallState[n]
 return n==currentStage and not defeated[n] and not bossSuppressed[n]
  and state~=nil and not state.Skipped and state.Current>=5
end
local function updateGaugeLayout(e,n,g)
 local wall,reference=bossWall(n)
 local bossHeight=e:GetAttribute("BossDisplayHeight")
 local bossBase=e:GetAttribute("BossDisplayBaseY")
 if not wall or not reference or not bossHeight or not bossBase then return false end
 local settings=BossDisplayConfig.Get(n)
 local surface=bossSurfaces[n]
 if not surface or not surface:IsDescendantOf(folder) then
  surface=Instance.new("Part")
  surface.Name="BossDisplaySurface"
  surface.Anchored=true
  surface.CanCollide=false
  surface.CanTouch=false
  surface.CanQuery=false
  surface.CastShadow=false
  surface.Material=Enum.Material.SmoothPlastic
  surface:SetAttribute("VisualOnly",true)
  surface:SetAttribute("BossStage",n)
  surface.Parent=folder
  bossSurfaces[n]=surface
 end
 -- Reference StageSurface.Face is the authored player-facing face.
 local localNormal=Vector3.FromNormalId(reference.Face)
 local normal=wall.CFrame:VectorToWorldSpace(localNormal)
 local up=wall.CFrame.UpVector
 local depth=math.abs(localNormal.X)*wall.Size.X+math.abs(localNormal.Z)*wall.Size.Z
 local width=math.abs(localNormal.Z)*wall.Size.X+math.abs(localNormal.X)*wall.Size.Z
 local thickness=math.max(.01,settings.Thickness)
 surface.Size=Vector3.new(width,wall.Size.Y,thickness)
 local position=wall.Position+normal*(depth/2+settings.SurfaceOffset+thickness/2)
 surface.CFrame=CFrame.fromMatrix(position,up:Cross(-normal),up,-normal)
 surface.Color=settings.Color
 surface.Transparency=g.Enabled and settings.Transparency or 1
 surface:SetAttribute("ReferenceWall",wall:GetFullName())
 surface:SetAttribute("ReferenceFace",reference.Face.Name)
 surface:SetAttribute("SurfaceOffset",settings.SurfaceOffset)
 g.Adornee=surface
 g:SetAttribute("WallAnchored",false)
 g:SetAttribute("BossDisplayHeight",bossHeight)
 g:SetAttribute("BossDisplayCenterY",bossBase+bossHeight*settings.HeightRatio+settings.VerticalOffset)
 g.Face=Enum.NormalId.Front
 g.Active=false
 for _,property in ipairs({"SizingMode","CanvasSize","PixelsPerStud","LightInfluence","AlwaysOnTop","MaxDistance","ZOffset"}) do
  g[property]=reference[property]
 end
 WallGaugeLayout.ApplyBoss(surface,reference,g,n)
 return true
end
local function gauge(n,v,max)
 -- Keep authoritative HP even when streaming has not delivered the Boss root yet.
 fills[n]={Max=max,Current=v,Gui=nil}
 local e=enemy(n)
 local head=e:FindFirstChild("HumanoidRootPart") or e:FindFirstChildWhichIsA("BasePart")
 if not head then return end
 local old=e:FindFirstChild("PersonalGauge",true) if old then old:Destroy() end
 local nextWall=bossWall(n)
 if not nextWall then
  fills[n]={Max=max,Current=v,Gui=nil}
  return
 end
 local g=Instance.new("SurfaceGui")
 g.Name="PersonalGauge"
 g.Enabled=bossDisplayEnabled(n)
 g.Parent=head
 updateGaugeLayout(e,n,g)
 local function label(name,text,pos,size,minSize,maxSize)
  local l=Instance.new("TextLabel");l.Name=name;l.Text=text;l.Position=pos;l.Size=size
  l.BackgroundTransparency=1;l.TextColor3=Color3.new(1,1,1);l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.FredokaOne;l.Parent=g
  local constraint=Instance.new("UITextSizeConstraint");constraint.MinTextSize=minSize;constraint.MaxTextSize=maxSize;constraint.Parent=l
  local stroke=Instance.new("UIStroke");stroke.Color=Color3.fromRGB(20,23,30);stroke.Thickness=2;stroke.Parent=l
  return l
 end
 local nameHeight=n==9 and 116 or 60
 label("BossName",bossName(e),UDim2.fromOffset(8,0),UDim2.new(1,-16,0,nameHeight),20,32)
 label("StageNumber","STAGE "..n,UDim2.fromOffset(8,nameHeight+2),UDim2.new(1,-16,0,22),16,18)
 local barY=nameHeight+34
 local b=Instance.new("Frame");b.Name="HPBar";b.Position=UDim2.fromOffset(10,barY);b.Size=UDim2.new(1,-20,0,50);b.BackgroundColor3=Color3.fromRGB(35,38,45);b.BorderSizePixel=0;b.ClipsDescendants=true;b.Parent=g
 local outline=Instance.new("UIStroke");outline.Thickness=3;outline.Color=Color3.fromRGB(15,18,22);outline.Parent=b
 local f=Instance.new("Frame");f.Name="Fill";f.Size=UDim2.fromScale(max>0 and math.clamp(v/max,0,1) or 0,1);f.BackgroundColor3=Color3.fromRGB(80,225,65);f.BorderSizePixel=0;f.Parent=b
 local hp=label("HPLabel",NumberFormat.Format(v).." / "..NumberFormat.Format(max),UDim2.fromOffset(16,barY+4),UDim2.new(1,-32,0,42),20,30)
 hp.ZIndex=3
 fills[n]={Fill=f,HP=hp,Max=max,Current=v,Gui=g}
 updateGaugeLayout(e,n,g)
end
local function gate(n)local stage=workspace.GeneratedMap.BattleCorridor:FindFirstChild(("Stage%02d"):format(n)); local s=stage and stage:FindFirstChild("Gate"); if not s then return end; local g=s:Clone()g:ClearAllChildren()g.Name=("PersonalGate_Stage%02d"):format(n)g.Transparency=0 g.Color=Color3.fromRGB(155,55,45)g.CanCollide=true g.Parent=folder gates[n]=g end
local function staticVFX(e,on)
 if not e:GetAttribute("StaticAppearance") then return end
 for _,d in e:GetDescendants() do
  if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Highlight") then
   local enabled=d:GetAttribute("StaticVFXEnabled")
   if typeof(enabled)~="boolean" then enabled=d.Enabled end
   d.Enabled=on and enabled or false
   if not on and (d:IsA("ParticleEmitter") or d:IsA("Trail")) then d:Clear() end
  end
 end
end
local function visible(n,on)local e=enemy(n)staticVFX(e,on)for _,d in e:GetDescendants()do if d:IsA("BasePart")then d.LocalTransparencyModifier=on and 0 or 1 end end end
local rightTrack,leftTrack
local animationCharacter
local lastAttackId=0
local cleanupVersion=0
local punchUntil=0
local function releasePunch()
 if rightTrack then rightTrack:Stop(0);rightTrack:Destroy();rightTrack=nil end
 if leftTrack then leftTrack:Stop(0);leftTrack:Destroy();leftTrack=nil end
 if sound then sound:Stop();sound:Destroy();sound=nil end
 animationCharacter=nil
end
local function preparePunch()
 local ch=P.Character
 if ch~=animationCharacter then releasePunch() end
 if not ch then return end
 local hum=ch:FindFirstChildOfClass("Humanoid")
 local animator=hum and hum:FindFirstChildOfClass("Animator")
 if animator and not rightTrack then
  local right=Instance.new("Animation");right.AnimationId=RIGHT_PUNCH_ANIMATION_ID
  local left=Instance.new("Animation");left.AnimationId=LEFT_PUNCH_ANIMATION_ID
  rightTrack=animator:LoadAnimation(right);leftTrack=animator:LoadAnimation(left)
  rightTrack.Looped=false;leftTrack.Looped=false
  right:Destroy();left:Destroy()
  animationCharacter=ch
 end
 if not sound and ch:FindFirstChild("HumanoidRootPart") then
  sound=Instance.new("Sound");sound.SoundId=PUNCH_SOUND_ID;sound.Looped=false;sound.Parent=ch.HumanoidRootPart
 end
end
local function fight(on)
 if not on then Stage03AttackVisual.Stop() end
 cleanupVersion+=1
 if on then preparePunch();return end
 local version=cleanupVersion
 -- A Wall clear or zone exit must not cut off an already authorized punch.
 task.delay(math.max(0,punchUntil-os.clock()),function()
  if cleanupVersion==version then releasePunch() end
 end)
end
local function playCombatAttack(d)
 if typeof(d.Id)~="number" or d.Id<=lastAttackId then return end
 lastAttackId=d.Id;cleanupVersion+=1
 preparePunch()
 local duration=typeof(d.Duration)=="number" and math.clamp(d.Duration,.1,2) or .6
 local manualSpeed=d.Manual==true and tonumber(d.AnimationSpeed) or nil
 punchUntil=os.clock()+duration/(manualSpeed or 1)
 if rightTrack and leftTrack then
  rightTrack:Stop(0);leftTrack:Stop(0)
  local selected=d.Id%2==1 and rightTrack or leftTrack
  local speed=manualSpeed or (selected.Length>0 and selected.Length/duration or 1)
  selected:Play(0.03,1,speed)
 end
 if sound then sound:Stop();sound.TimePosition=0;sound:Play() end
end
local function playDefeatSound()
	local sound=Instance.new("Sound")
	sound.SoundId=DEFEAT_SOUND_ID
	sound.Volume=1
	sound.Looped=false
	sound.Parent=workspace.CurrentCamera
	sound:Play()

	sound.Ended:Once(function()
		sound:Destroy()
	end)
end
local function refreshGaugeVisibility()
 for stage=1,10 do
  local enemies=workspace:FindFirstChild("Enemies")
  local e=enemies and enemies:FindFirstChild(("Stage%02d_Enemy"):format(stage))
  local gui=e and e:FindFirstChild("PersonalGauge",true)
  local sub=P:GetAttribute(("Stage%dSubStage"):format(stage)) or 1
  if gui then
   gui.Enabled=bossDisplayEnabled(stage)
   if gui.Enabled then updateGaugeLayout(e,stage,gui) end
  end
  local surface=bossSurfaces[stage]
  if surface and surface.Parent then
   surface.Transparency=gui and gui.Enabled and BossDisplayConfig.Get(stage).Transparency or 1
  end
  renderWallStage(stage)
 end
end
P.CharacterAdded:Connect(function()
 activeCombatType,activeCombatStage,activeWallIndex=nil,nil,nil
 refreshGaugeVisibility()
end)
P:GetAttributeChangedSignal("CurrentStage"):Connect(function()
 local nextStage=P:GetAttribute("CurrentStage")
 if typeof(nextStage)=="number" then
  if nextStage~=3 then Stage03AttackVisual.Stop() end
  currentStage=nextStage
  refreshGaugeVisibility()
  hideBossRecommendation()
  -- Never reconstruct HP from the Major/SubStage number.
  for major in wallState do renderWallStage(major) end
 end
end)
RunService.PreSimulation:Connect(function()
 for part,record in wallParts do
  if not part:IsDescendantOf(workspace) then
   wallParts[part]=nil
  else
   local closed=isWallClosed(record.Major,record.Index)
   if part.CanCollide~=closed then part.CanCollide=closed end
   local transparency=closed and 0 or 1
   if part.LocalTransparencyModifier~=transparency then part.LocalTransparencyModifier=transparency end
  end
 end
 for stage in defeated do
  local e=workspace:FindFirstChild("Enemies") and workspace.Enemies:FindFirstChild(("Stage%02d_Enemy"):format(stage))
  if e then
   staticVFX(e,false)
   for _,part in e:GetDescendants() do
    if part:IsA("BasePart") then
     part.CanCollide=false
     part.LocalTransparencyModifier=1
    end
   end
  end
 end
end)
R.OnClientEvent:Connect(function(d)
 if d.Type=="CombatAttack" then
  playCombatAttack(d)
  Stage03AttackVisual.Play(d)
 elseif d.Type=="TrophySpawn" then
  showTrophy(d)
 elseif d.Type=="TrophyRemoved" then
  clearTrophy(d.Id)
 elseif d.Type=="WallInitialize" then
  local major=d.State.MajorStage or 1
  wallState[major]=d.State
  refreshGaugeVisibility()
 elseif d.Type=="WallGauge" then
  local major=d.MajorStage or 1
  local state=wallState[major]
  if state then
   state.Gauges[d.Index]=d.Current
   state.Maxes[d.Index]=d.Max
   renderWallStage(major)
  end
 elseif d.Type=="BossRecommendation" then
  showBossRecommendation(d.Stage,d.RecommendedLevel)
  if typeof(d.Current)=="number" then gauge(d.Stage,d.Current,d.Max) end
  refreshGaugeVisibility()
 elseif d.Type=="BossInitialize" then
  if d.Stage==3 then Stage03AttackVisual.Prepare() end
  currentStage=d.Stage
  gauge(d.Stage,d.Current,d.Max)
  showBossRecommendation(d.Stage,d.RecommendedLevel)
  refreshGaugeVisibility()
 elseif d.Type=="BossGauge" then
  local f=fills[d.Stage] if f then f.Current=d.Current;f.Max=d.Max;if f.Fill then f.Fill.Size=UDim2.fromScale(math.clamp(d.Current/d.Max,0,1),1) f.HP.Text=NumberFormat.Format(d.Current).." / "..NumberFormat.Format(d.Max) end end
 elseif d.Type=="BossResult" then
  bossSuppressed[currentStage]=true
  activeCombatType,activeCombatStage,activeWallIndex=nil,nil,nil
  refreshGaugeVisibility()
  hideBossRecommendation()
  fight(false)
 elseif d.Type=="WallCleared" then
  playDefeatSound()
  local major=d.MajorStage or 1
  -- Snapshot was captured after the existing Carry loop finished. Install it
  -- atomically before rendering; never expose the cached pre-Carry MaxHP.
  if d.State then wallState[major]=d.State end
  local state=wallState[major]
  if state then
   state.Cleared[d.Index]=true
   state.Gauges[d.Index]=0
   state.Current=d.Next
   if d.Next<=4 and d.NextMax then state.Maxes[d.Next]=d.NextMax end
   refreshGaugeVisibility()
  end
 elseif d.Type=="Stage1BossUnlocked" then
  visible(d.MajorStage or 1,true)
  refreshGaugeVisibility()
 elseif d.Type=="Initialize"then activeCombatType,activeCombatStage,activeWallIndex=nil,nil,nil Stage03AttackVisual.Reset() lastAttackId=0 clearTrophy() hideBossRecommendation() fight(false) currentStage=d.CurrentStage for major in wallState do for i=1,4 do clearWallGauge(major,i) end end table.clear(wallState) folder:ClearAllChildren()table.clear(bossSurfaces)table.clear(gates)table.clear(defeated)table.clear(bossSuppressed)for i=1,10 do gauge(i,d.Gauges[i],enemy(i):GetAttribute("BossMaxHP") or d.Gauges[i])if d.Cleared[i] or (d.Skipped and d.Skipped[i]) then defeated[i]=true visible(i,false)else gate(i)visible(i,true)end end refreshGaugeVisibility() elseif d.Type=="Gauge"then local f=fills[d.Stage]if f then f.Current=d.Current;f.Max=d.Max;if f.Fill then f.Fill.Size=UDim2.fromScale(math.clamp(d.Current/d.Max,0,1),1) f.HP.Text=NumberFormat.Format(d.Current).." / "..NumberFormat.Format(d.Max) end end
	elseif d.Type=="EnemyDefeated"then activeCombatType,activeCombatStage,activeWallIndex=nil,nil,nil hideBossRecommendation() defeated[d.Stage]=true if d.Stage<10 then currentStage=d.Stage+1 end refreshGaugeVisibility() fight(false) playDefeatSound() local e=enemy(d.Stage)for _,x in e:GetDescendants()do if x:IsA("BasePart")then T:Create(x,TweenInfo.new(.25),{LocalTransparencyModifier=1}):Play()end end
 elseif d.Type=="StageCleared"then currentStage=d.CurrentStage refreshGaugeVisibility() for major in wallState do renderWallStage(major) end local g=gates[d.Stage]if g then g.CanCollide=false T:Create(g,TweenInfo.new(.45),{Size=Vector3.new(g.Size.X,.2,g.Size.Z),Transparency=1}):Play()task.delay(.5,function()if g.Parent then g:Destroy()end end)gates[d.Stage]=nil end
 elseif d.Type=="Fighting"then
  activeCombatType=d.Active and d.CombatType or nil
  activeCombatStage=d.Active and d.Stage or nil
  activeWallIndex=d.Active and d.WallIndex or nil
  refreshGaugeVisibility()
  fight(d.Active)
 end
end)
workspace.DescendantAdded:Connect(function(part)
 if not part:IsA("BasePart") or part.Name~="Wall" then return end
 local model=part.Parent
 if not model then return end
 local major,index=model.Name:match("^Stage(%d+)%.([1-4])$")
 major,index=tonumber(major),tonumber(index)
 if not major or major<1 or major>10 then return end
 task.defer(function()
  if wallModel(major,index)==model then renderWallStage(major) end
 end)
end)
task.defer(function()
 task.wait(.5)
 for major in wallState do renderWallStage(major) end
end)
-- Presentation maintenance retries streamed walls/models. Boss bounds are sampled only at spawn.
task.spawn(function()
 while script.Parent do
  task.wait(.5)
  for n,record in fills do
   local enemies=workspace:FindFirstChild("Enemies")
   local e=enemies and enemies:FindFirstChild(("Stage%02d_Enemy"):format(n))
   if e and not defeated[n] then
    if not record.Gui or not record.Gui:IsDescendantOf(e) then
     gauge(n,record.Current,record.Max)
     record=fills[n]
     refreshGaugeVisibility()
    end
    if record.Gui and record.Gui.Enabled and record.Gui.Adornee then
     updateGaugeLayout(e,n,record.Gui)
    end
   end
  end
 end
end)
R:FireServer({Type="RequestState"})
