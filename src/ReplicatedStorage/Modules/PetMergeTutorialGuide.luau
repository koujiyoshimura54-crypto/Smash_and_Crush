-- Presentation only: existing transactions, eligibility, renderer and display owner.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local State=require(script.Parent.PetMergeTutorialState)
local Presentation=require(script.Parent.OreMergeTutorialPresentation)
local Coordinator=require(script.Parent.TutorialPresentationCoordinator)
local Config=require(script.Parent.Config)
local M={}
function M.Mount(player,gui,view)
 local pg=player:WaitForChild("PlayerGui")
 local overlay=pg:WaitForChild("PetMergeTutorialGui")
 local services=player:WaitForChild("PlayerScripts"):WaitForChild("Services")
 local PetClient=require(services.PetClient)
 local HatchClient=require(services.HatchClient)
 local MenuClient=require(services.MenuClient)
 local presentation=Presentation.Mount(overlay,view.Root:FindFirstChild("Top"))
 local connections={}
 local dead,dismissed,wasLobby=false,false,false
 local closeRevision=view:GetPetTutorialState().CloseRevision
 local generation=player:GetAttribute("PetViewGeneration") or 0
 local priorCompleted,completionPending,completionUntil
 local elapsed=0
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 local function navigation(position)
  if player:GetAttribute("PetMergeTutorialTarget")~=position then player:SetAttribute("PetMergeTutorialTarget",position) end
 end
 local function hide(reason,hold)
  navigation(nil);presentation:Hide()
  overlay:SetAttribute("Step",reason);overlay:SetAttribute("Target",nil)
  if not hold then Coordinator.Release(overlay) end
 end
 local function displayed(x)
  while x and x~=pg do
   if x:IsA("GuiObject") and not x.Visible or x:IsA("LayerCollector") and not x.Enabled then return false end
   x=x.Parent
  end
  return x==pg
 end
 local function lobby()
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not hum or hum.Health<=0 then return false end
  local world=player:GetAttribute("CurrentWorld") or 1
  local bounds=RS:FindFirstChild("BattleBagLobbyBounds")
  local cf=bounds and bounds:GetAttribute("World"..world.."CFrame");local size=bounds and bounds:GetAttribute("World"..world.."Size")
  if typeof(cf)~="CFrame" or typeof(size)~="Vector3" then return false end
  local p=cf:PointToObjectSpace(root.Position)
  local inside=math.abs(p.X)<=size.X/2 and math.abs(p.Z)<=size.Z/2 and math.abs(p.Y)<=40
  local model=workspace:FindFirstChild("RestockShop")
  if world==2 then
   local map=workspace:FindFirstChild("World2Map");local area=map and map:FindFirstChild("TrainingArea")
   local facilities=area and area:FindFirstChild("FacilityDisplays");model=facilities and facilities:FindFirstChild("MergeDisplay")
  end
  return inside,model and model:FindFirstChild("Area")
 end
 local function blocked()
  if player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") or player:GetAttribute("IsFighting") or MenuClient.shown() then return true end
  for _,name in {"OfflineRewards","TimeRewardsPanel","DailyRewardsPanel","CommunityRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel"} do
   local x=gui:FindFirstChild(name);if x and displayed(x) then return true end
  end
  for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"}} do
   local root=pg:FindFirstChild(path[1]);local x=root and root:FindFirstChild(path[2]);if x and displayed(x) then return true end
  end
  for _,name in {"HatchGui","EnemyDropGacha","LimitedEgg01Gui","LimitedEgg02Gui"} do local x=pg:FindFirstChild(name);if x and x.Enabled then return true end end
  local screen=pg:FindFirstChild("ScreenGui")
  for name in Config.Eggs.Eggs do local x=screen and screen:FindFirstChild(name);if x and x:IsA("BillboardGui") and x.Enabled then return true end end
  local notify=pg:FindFirstChild("NotifyGui");local stack=notify and notify:FindFirstChild("Stack")
  if stack then for _,x in stack:GetChildren() do if x:IsA("GuiObject") and displayed(x) and x.AbsoluteSize.Y>1 then return true end end end
  local win=gui:FindFirstChild("WinLabel");local feedback=win and win:FindFirstChild("RewardFeedbackScale")
  return feedback and math.abs(feedback.Scale-1)>.001 or false
 end
 local function refresh()
  if dead then return end
  local g=player:GetAttribute("PetViewGeneration") or 0
  if g~=generation then
   generation=g;dismissed=false;priorCompleted=nil;completionPending=nil;completionUntil=nil;hide("Reset")
  end
  local current=view:GetPetTutorialState()
  if current.CloseRevision~=closeRevision then closeRevision=current.CloseRevision;dismissed=true end
  if current.Open then dismissed=false end
  local inLobby,destination=lobby()
  if not inLobby or inLobby and not wasLobby then dismissed=false end;wasLobby=inLobby
  local state=PetClient.mergeTutorialState();local pets=PetClient.state()
  if not state or not pets then hide("Loading");return end
  if not state.Eligible then hide("Ineligible");return end
  if priorCompleted==false and state.Completed then completionPending=true end
  priorCompleted=state.Completed
  if state.Completed and not completionPending then hide("Complete");return end
  if not require(script.Parent.FirstBattleTutorialState).AllowLaterGuides(player) or not inLobby then hide("WaitingForLobby");return end
  local owns=Coordinator.Owner()==overlay
  -- Success consumes the materials before the response/hatch. Do not re-gate on count.
  if current.Pending or PetClient.busy() or HatchClient.playing() then hide("WaitingForTransaction",owns);return end
  if blocked() then hide("WaitingForDisplay",owns and not gui.InventoryPanel.Visible);return end
  if dismissed and not current.Open then hide("Dismissed");return end
  local _,eligible=State.Available(pets)
  if not state.Completed and not eligible then hide("WaitingForPets");return end
  if not Coordinator.Acquire(overlay) then hide("WaitingForGuide");return end
  local step,target,key
  navigation(nil)
  if state.Completed then
   completionUntil=completionUntil or os.clock()+(overlay:GetAttribute("CompletionSeconds") or 2.5)
   if os.clock()>=completionUntil then completionPending=nil;hide("Complete");return end
   step="Complete"
  elseif not current.Open then
   if not destination then hide("WaitingForFacility");return end
   step="GoToMerge";navigation(destination.Position)
  elseif current.Tab~="Pet" then step="ChoosePet";target=view.Tabs.Pet
  elseif current.Valid then step="Merge";target=view.Merge
  else
   step="AddPets";target=current.MaterialTarget or view.List
   key=not current.MaterialTarget and "ScrollPets" or current.RepeatMaterial and "AddAnother" or "AddPets"
  end
  overlay:SetAttribute("Step",step);overlay:SetAttribute("Target",target and target:GetFullName() or nil)
  presentation:Pin(overlay.Messages[key or step].Value);presentation:Target(target)
 end
 connect(view.Changed,refresh);connect(PetClient.StateChanged,refresh)
 for _,name in {"TutorialCompleted","PetViewGeneration","RunReturnBusy","StageSkipBusy","CurrentWorld"} do connect(player:GetAttributeChangedSignal(name),refresh) end
 connect(player:GetAttributeChangedSignal("TutorialResetSequence"),function()
  dismissed=false;priorCompleted=nil;completionPending=nil;completionUntil=nil;hide("Reset");refresh()
 end)
 connect(player.CharacterRemoving,function()hide("WaitingForLobby")end)
 connect(RunService.Heartbeat,function(dt)elapsed+=dt;if elapsed<.2 then return end;elapsed=0;refresh()end)
 task.defer(PetClient.refresh);refresh()
 return function()
  if dead then return end;hide("Stopped");dead=true;presentation:Destroy()
  for _,c in connections do c:Disconnect() end
 end
end
return M
