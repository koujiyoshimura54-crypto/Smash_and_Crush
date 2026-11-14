-- Presentation only. Completion is committed by the ordinary server Forge transaction.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Forge=require(script.Parent.ForgeClient)
local State=require(script.Parent.OreMergeTutorialState)
local Higher=require(script.Parent.HigherOreMergeTutorialState)
local Presentation=require(script.Parent.OreMergeTutorialPresentation)
local Coordinator=require(script.Parent.TutorialPresentationCoordinator)
local FirstBattle=require(script.Parent.FirstBattleTutorialState)
local M={}
function M.Mount(player,gui,view)
 local pg=player:WaitForChild("PlayerGui")
 local overlay=pg:WaitForChild("OreMergeTutorialGui")
 local canvas=overlay.Canvas
 local presentation=Presentation.Mount(overlay,view.Root:FindFirstChild("Top"))
 local messages=overlay.Messages
 local connections={}
 local dead,dismissed,wasLobby=false,false,false
 local closeRevision=0
 local step
 local elapsed=0
 local analytics=require(script.Parent.FirstPlayAnalyticsClient)
 local unbindAnalytics=analytics.BindMergeGuide(function()
  return not dead and step~=nil and overlay:GetAttribute("GuideKind")=="Initial"
   and Coordinator.Owner()==overlay and presentation:IsShown()
 end)
 local function connect(signal,fn) local c=signal:Connect(fn);connections[#connections+1]=c;return c end
 local function navigation(position)
  if player:GetAttribute("OreTutorialTarget")~=position then player:SetAttribute("OreTutorialTarget",position) end
 end
 local function displayed(x)
  while x and x~=pg do
   if x:IsA("GuiObject") and not x.Visible or x:IsA("ScreenGui") and not x.Enabled then return false end
   x=x.Parent
  end
  return x==pg
 end
 local function hide(reason)
  Coordinator.Release(overlay)
  navigation(nil);step=nil;presentation:Hide()
  overlay:SetAttribute("Step",reason or "Waiting")
  overlay:SetAttribute("Target",nil)
 end
 local function lobby()
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not humanoid or humanoid.Health<=0 or not root then return false end
  local world=player:GetAttribute("CurrentWorld") or 1
  local map=workspace:FindFirstChild(world==2 and "World2Map" or "GeneratedMap")
  local area=map and map:FindFirstChild("TrainingArea")
  local floor=area and area:FindFirstChild("Floor")
  if not floor then return false end
  local p=floor.CFrame:PointToObjectSpace(root.Position)
  local inside=math.abs(p.X)<=floor.Size.X*.5 and math.abs(p.Z)<=floor.Size.Z*.5 and math.abs(p.Y)<=40
  local model=workspace:FindFirstChild("RestockShop")
  if world==2 then local facilities=area:FindFirstChild("FacilityDisplays");model=facilities and facilities:FindFirstChild("MergeDisplay") end
  local destination=model and model:FindFirstChild("Area")
  return inside,destination
 end
 local function blocked()
  if player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") then return true end
  for _,name in {"OfflineRewards","TimeRewardsPanel","DailyRewardsPanel","CommunityRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel"} do
   local x=gui:FindFirstChild(name);if x and displayed(x) then return true end
  end
  for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"}} do
   local root=pg:FindFirstChild(path[1]);local x=root and root:FindFirstChild(path[2]);if x and displayed(x) then return true end
  end
  for _,name in {"HatchGui","EnemyDropGacha"} do local x=pg:FindFirstChild(name);if x and x.Enabled then return true end end
  local notify=pg:FindFirstChild("NotifyGui");local stack=notify and notify:FindFirstChild("Stack")
  if stack then for _,x in stack:GetChildren() do if x:IsA("GuiObject") and displayed(x) and x.AbsoluteSize.Y>1 then return true end end end
  local win=gui:FindFirstChild("WinLabel");local feedback=win and win:FindFirstChild("RewardFeedbackScale")
  return feedback and math.abs(feedback.Scale-1)>.001 or false
 end
 local function refresh()
  if dead then return end
  local higher=player:GetAttribute("OreTutorialCompleted")==true
  local current=view:GetOreTutorialState(higher and Higher.MinimumPoints or nil)
  overlay:SetAttribute("GuideKind",higher and "Higher" or "Initial")
  if current.CloseRevision~=closeRevision then closeRevision=current.CloseRevision;dismissed=true end
  if current.Open then dismissed=false end
  local inLobby,destination=lobby()
  if not inLobby then dismissed=false end
  if inLobby and not wasLobby then dismissed=false end;wasLobby=inLobby
  if player:GetAttribute("OreTutorialEligible")~=true then hide("Ineligible");return end
  if higher and (player:GetAttribute("HigherOreTutorialEligible")~=true or player:GetAttribute("HigherOreTutorialCompleted")==true) then hide("Complete");return end
  local initialFlow=FirstBattle.Active(player)
  if initialFlow and higher then hide("WaitingForFirstBattle");return end
  local early=initialFlow and not higher and (current.Open or player:GetAttribute("FirstBattleOutcome")~=nil)
  if not (early or FirstBattle.AllowLaterGuides(player)) or not inLobby or blocked() then hide("Waiting");return end
  local state=Forge.State
  if not state or not state.Loaded or state.Token~=player:GetAttribute("ForgeSessionToken")
   or State.AvailableCount(state.Ores)<2 or higher and not Higher.Selection(state.Ores,state.World2Unlocked) then hide("WaitingForOres");return end
  if dismissed and not current.Open then hide("Dismissed");return end
  if not Coordinator.Acquire(overlay) then hide("WaitingForGuide");return end
  local nextStep,nextTarget,messageKey
  if not current.Open then
   if not destination then hide("WaitingForFacility");return end
   nextStep="GoToMerge";navigation(destination.Position)
  else
   navigation(nil)
   if current.Tab~="Ore" or current.Selling then nextStep="ChooseOre";nextTarget=view.Tabs.Ore
   elseif current.Pending then nextStep="Saving";nextTarget=view.Merge
   elseif current.Valid and (not higher or current.TotalPoints>=Higher.MinimumPoints) then nextStep="Merge";nextTarget=view.Merge
   else
    nextStep="AddOres";nextTarget=current.SelectedCount>=5 and view.ClearButton or current.MaterialTarget or view.List
    messageKey=higher and current.SelectedCount>=5 and "ClearOres" or not current.MaterialTarget and "ScrollOres" or current.RepeatMaterial and "AddAnother" or "AddOres"
   end
  end
  step=nextStep;overlay:SetAttribute("Step",step)
  local text=higher and messages:FindFirstChild("Higher"..(messageKey or step)) or messages:FindFirstChild(messageKey or step) or messages[step]
  presentation:Pin(text.Value);presentation:Target(nextTarget)
  overlay:SetAttribute("Target",nextTarget and nextTarget:GetFullName() or nil)
 end
 connect(view.Changed,refresh);connect(Forge.Changed,refresh)
 for _,name in {"TutorialCompleted","OreTutorialEligible","OreTutorialCompleted","HigherOreTutorialEligible","HigherOreTutorialCompleted","ForgeSessionToken","TutorialResetSequence","RunReturnBusy","CurrentWorld"} do
  connect(player:GetAttributeChangedSignal(name),function()
   if name=="TutorialResetSequence" or name=="ForgeSessionToken" then dismissed=false end
   refresh()
  end)
 end
 connect(player.CharacterRemoving,function()hide("Waiting")end)
 -- Only fixed references / known modal paths at 5Hz; no full Workspace/PlayerGui scans.
 connect(RunService.Heartbeat,function(dt)
  elapsed+=dt;if elapsed<.2 then return end;elapsed=0
  if player:GetAttribute("OreTutorialEligible")==true and (player:GetAttribute("OreTutorialCompleted")~=true or player:GetAttribute("HigherOreTutorialCompleted")~=true) then refresh() end
 end)
 task.defer(Forge.Refresh);refresh()
 return function()
  if dead then return end;hide("Stopped");dead=true;unbindAnalytics();presentation:Destroy()
  for _,c in connections do c:Disconnect() end
 end
end
return M
