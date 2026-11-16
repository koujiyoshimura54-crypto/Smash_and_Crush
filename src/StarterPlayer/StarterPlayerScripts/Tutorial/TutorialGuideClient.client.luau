local treadmillFolder=workspace:WaitForChild("Treadmills")
-- Local-only floor navigation; progression and completion use existing server state.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local IntroBalance=require(RS.Config:WaitForChild("World1BossConfig"))
local RunService=game:GetService("RunService")
local FirstBattle=require(RS.Modules.FirstBattleTutorialState)
local Coordinator=require(RS.Modules.TutorialPresentationCoordinator)
local wallCount=#IntroBalance.GetWallConfig(1).Walls
local player=Players.LocalPlayer
local wallPrompt=require(RS.Modules:WaitForChild("Stage1WallPrompt")).Mount(player)
local trained=false
local enteredWall=false -- Monotonic Step2 completion: Wall clear, never combat entry.
local trophy
local wallIndex=1
local stage1Defeated=false
local resetSequence=player:GetAttribute("TutorialResetSequence")
local connections={}
local remoteConnection
local UPDATE_INTERVAL=.2
local tickConnection
local updateScheduler
local characterConnections={}
local renderer=require(RS.Modules:WaitForChild("FloorGuideRenderer")).new({Name="TutorialFloorGuide",Owner=script})
local function clear() renderer:Clear() end
local function hide() renderer:Hide() end
local function stopCache() renderer:StopCache() end
local function show(key,target)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then hide();return end
 renderer:Show(key,root.Position,target)
 local folder=renderer:GetFolder()
 if folder then
  folder:SetAttribute("Step1Completed",trained)
  folder:SetAttribute("Step2Completed",enteredWall)
 end
end
local function wallCleared()
 trained=true enteredWall=true
end
local function inLobby(character)
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local map=workspace:FindFirstChild("GeneratedMap")
 local area=map and map:FindFirstChild("TrainingArea")
 local floor=area and area:FindFirstChild("Floor")
 if not root or not floor then return false end
 local p=floor.CFrame:PointToObjectSpace(root.Position)
 return math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 and math.abs(p.Y)<=40
end
local function refresh()
 wallPrompt:SetGuide(nil,nil)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if updateScheduler then updateScheduler() end
 local pg=player:FindFirstChild("PlayerGui")
 local mergeGui=pg and pg:FindFirstChild("MergeShopGui")
 local panel=mergeGui and mergeGui:FindFirstChild("MergeShopPanel")
 local phase=FirstBattle.Phase(FirstBattle.Read(player),{
  -- Existing WorldGate authority represents the initial World1 with a nil attribute.
  World=player:GetAttribute("CurrentWorld") or 1,Alive=humanoid~=nil and humanoid.Health>0,
  InLobby=inLobby(character),MergeOpen=panel~=nil and panel.Visible,
  Merged=player:GetAttribute("OreTutorialCompleted")==true,
  Equipped=player:GetAttribute("DumbbellEquipTutorialInitialCompleted")==true,Level=player:GetAttribute("Level"),
 })
 local target=player:GetAttribute("OreTutorialTarget")
 if phase=="Merge" then
  if typeof(target)=="Vector3" then show("OreMerge",target) else hide() end
  return
 elseif phase=="Equip" or phase=="Waiting" then hide();return end
 local legacy=phase=="Legacy"
 if player:GetAttribute("TutorialCompleted")~=false
  or phase=="Complete" and not (stage1Defeated and trophy) then
  local egg=player:GetAttribute("EggTutorialTarget")
  local pet=player:GetAttribute("PetMergeTutorialTarget")
  target=target or egg or pet
  if FirstBattle.AllowLaterGuides(player) and typeof(target)=="Vector3" and humanoid and humanoid.Health>0 then show(egg and "BasicEgg" or pet and "PetMerge" or "OreMerge",target)
  else clear();stopCache() end
  return
 end
 if (player:GetAttribute("CurrentWorld") or 1)~=1 then hide();stopCache();return end
 if not humanoid or humanoid.Health<=0 then hide();stopCache();return end
 local owner=Coordinator.Owner()
 if owner and owner.Name~="Stage1WallPromptGui" then hide();return end
 if panel and panel.Visible or player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") then hide();return end
 if phase=="Train" or legacy and IntroBalance.NeedsIntroTraining(player:GetAttribute("Level"),player:GetAttribute("Strength"),enteredWall or stage1Defeated) then
  local treadmill=treadmillFolder:FindFirstChild("Normal01")
  local zone=treadmill and treadmill:FindFirstChild("Area")
  if zone then show("Treadmill",zone.Position) else hide() end
 elseif stage1Defeated or phase=="Reward" then
  if trophy then show("Trophy"..trophy.Id,trophy.CFrame.Position) else hide() end
 else
  local map=workspace:FindFirstChild("GeneratedMap")
  local corridor=map and map:FindFirstChild("BattleCorridor")
  local stage=corridor and corridor:FindFirstChild("Stage01")
  -- Authored boss arena stays Stage1.5 even when only one wall remains.
  local isWall=wallIndex<=wallCount
  local model=stage and stage:FindFirstChild(isWall and "Stage1."..wallIndex or "Stage1.5")
  local destination=model and (isWall and model:FindFirstChild("Wall")
   or model:FindFirstChild("EnemySpawn") or model:FindFirstChild("MiniBossSpawn") or model:FindFirstChild("Floor"))
  if destination then
   if isWall then wallPrompt:SetGuide(wallIndex,destination) end
   if wallPrompt:IsVisible() then hide() else show(isWall and ("Wall1."..wallIndex) or "Stage1Boss",destination.Position) end
  else hide() end
 end
end
local function trainingChanged()
 if player:GetAttribute("TutorialCompleted")==false and player:GetAttribute("IsTraining")==true then trained=true end
 refresh()
end
table.insert(connections,player:GetAttributeChangedSignal("IsTraining"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("Level"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialCompleted"):Connect(trainingChanged))
table.insert(connections,player:GetAttributeChangedSignal("OreTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("EggTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("PetMergeTutorialTarget"):Connect(refresh))
table.insert(connections,player:GetAttributeChangedSignal("TutorialResetSequence"):Connect(function()
 local sequence=player:GetAttribute("TutorialResetSequence")
 if sequence~=resetSequence then
  resetSequence=sequence trained=false enteredWall=false stage1Defeated=false wallIndex=1 trophy=nil clear() refresh()
 end
end))
for _,name in {"FirstBattleTutorialEligible","FirstBattleOutcome","FirstBattleStage1Defeated","OreTutorialCompleted","DumbbellEquipTutorialInitialCompleted"} do
 table.insert(connections,player:GetAttributeChangedSignal(name):Connect(refresh))
end
local elapsed=0
updateScheduler=function()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local original=(player:GetAttribute("TutorialCompleted")==false or FirstBattle.Active(player)) and (player:GetAttribute("CurrentWorld") or 1)==1
 local merge=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("OreTutorialTarget"))=="Vector3"
 local egg=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("EggTutorialTarget"))=="Vector3"
 local pet=FirstBattle.AllowLaterGuides(player) and typeof(player:GetAttribute("PetMergeTutorialTarget"))=="Vector3"
 local enabled=(original or merge or egg or pet)
  and humanoid and humanoid.Health>0
 if not enabled then
  if tickConnection then tickConnection:Disconnect();tickConnection=nil end
  elapsed=0;return
 end
 if tickConnection then return end
 tickConnection=RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt
  if elapsed<UPDATE_INTERVAL then return end
  elapsed=0;refresh()
 end)
end
local function bindCharacter(character)
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
 task.spawn(function()
  local humanoid=character:WaitForChild("Humanoid",10)
  local root=character:WaitForChild("HumanoidRootPart",10)
  if player.Character~=character or not humanoid or not root then return end
  table.insert(characterConnections,humanoid.Died:Connect(refresh));refresh()
 end)
end
table.insert(connections,player.CharacterRemoving:Connect(function()
 hide();stopCache();if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
end))
table.insert(connections,player.CharacterAdded:Connect(bindCharacter))
table.insert(connections,player:GetAttributeChangedSignal("CurrentWorld"):Connect(refresh))
if player.Character then bindCharacter(player.Character) end
trainingChanged()
task.spawn(function()
 local remote=RS.Remotes:WaitForChild("GameRemotes"):WaitForChild("CombatState")
 remoteConnection=remote.OnClientEvent:Connect(function(d)
  if typeof(d)~="table" then return end
  wallPrompt:Handle(d)
  if (d.Type=="EnemyDefeated" or d.Type=="StageCleared") and d.Stage==1 then stage1Defeated=true
  elseif d.Type=="Initialize" then
   trophy=nil wallIndex=1
   stage1Defeated=typeof(d.Cleared)=="table" and d.Cleared[1]==true
  elseif d.Type=="WallCleared" and d.MajorStage==1 then
   wallCleared()
   wallIndex=math.clamp(tonumber(d.Next) or (d.Index+1),1,wallCount+1)
  elseif d.Type=="WallInitialize" and typeof(d.State)=="table" and d.State.MajorStage==1 then
   wallIndex=math.clamp(tonumber(d.State.Current) or 1,1,wallCount+1)
   if not d.State.Skipped and typeof(d.State.Cleared)=="table" and d.State.Cleared[1]==true then wallCleared() end
  elseif d.Type=="TrophySpawn" and d.Stage==1 and typeof(d.Id)=="number" and typeof(d.CFrame)=="CFrame" then
   -- Owner-only event from TrophyRewardService. Never scan another player's Trophy.
   wallCleared()
   stage1Defeated=true
   trophy={Id=d.Id,CFrame=d.CFrame}
  elseif d.Type=="TrophyRemoved" and trophy and d.Id==trophy.Id then trophy=nil end
  refresh()
 end)
 wallPrompt:RequestUsing(function() remote:FireServer({Type="RequestState"}) end)
 remote:FireServer({Type="RequestState"})
end)
renderer.OnDestroy=function()
 wallPrompt:Destroy()
 if tickConnection then tickConnection:Disconnect();tickConnection=nil end
 for _,connection in characterConnections do connection:Disconnect() end;table.clear(characterConnections)
 if remoteConnection then remoteConnection:Disconnect() end
 for _,connection in ipairs(connections) do connection:Disconnect() end
end
script.Destroying:Once(function() renderer:Destroy() end)
