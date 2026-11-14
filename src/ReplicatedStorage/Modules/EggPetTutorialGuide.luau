-- Read-only Phase 1 guidance; normal Pet transactions alone purchase/equip/complete.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Egg=require(RS.Modules.Egg)
local Config=require(RS.Modules.Config)
local State=require(RS.Modules.EggPetTutorialState)
local Presentation=require(RS.Modules.OreMergeTutorialPresentation)
local Coordinator=require(RS.Modules.TutorialPresentationCoordinator)
local M={}
function M.Mount(player,services)
 local pg=player:WaitForChild("PlayerGui")
 local gui=pg:WaitForChild("StrengthGui")
 local screen=pg:WaitForChild("ScreenGui")
 local overlay=pg:WaitForChild("EggPetTutorialGui")
 local canvas=overlay.Canvas
 local proxy=canvas.TargetProxy
 local PetClient=require(services.PetClient)
 local MenuClient=require(services.MenuClient)
 local HatchClient=require(services.HatchClient)
 local presentation=Presentation.Mount(overlay,canvas.NotificationRegion)
 local connections={}
 local dead,dismissed,wasLobby,wasNear=false,false,false,false
 local closeRevision=MenuClient.closeRevision()
 local priorCompleted,completionPending,completionUntil
 local generation=player:GetAttribute("PetViewGeneration") or 0
 local step,sheetTarget
 local elapsed=0
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 local function navigation(position)
  if player:GetAttribute("EggTutorialTarget")~=position then player:SetAttribute("EggTutorialTarget",position) end
 end
 local function hide(reason,hold)
  navigation(nil);step=nil;sheetTarget=nil;proxy.Visible=false;presentation:Hide()
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
 local function blocked()
  if player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") or player:GetAttribute("IsFighting") then return true end
  for _,name in {"OfflineRewards","TimeRewardsPanel","DailyRewardsPanel","CommunityRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel","MergePanel"} do
   local x=gui:FindFirstChild(name);if x and displayed(x) then return true end
  end
  for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"},{"MergeShopGui","MergeShopPanel"}} do
   local root=pg:FindFirstChild(path[1]);local x=root and root:FindFirstChild(path[2]);if x and displayed(x) then return true end
  end
  for _,name in {"HatchGui","EnemyDropGacha","LimitedEgg01Gui","LimitedEgg02Gui"} do local x=pg:FindFirstChild(name);if x and x.Enabled then return true end end
  for name in Config.Eggs.Eggs do
   local sheet=screen:FindFirstChild(name)
   if name~="Basic" and sheet and sheet:IsA("BillboardGui") and sheet.Enabled then return true end
  end
  local notify=pg:FindFirstChild("NotifyGui");local stack=notify and notify:FindFirstChild("Stack")
  if stack then for _,x in stack:GetChildren() do if x:IsA("GuiObject") and displayed(x) and x.AbsoluteSize.Y>1 then return true end end end
  local win=gui:FindFirstChild("WinLabel");local feedback=win and win:FindFirstChild("RewardFeedbackScale")
  return feedback and math.abs(feedback.Scale-1)>.001 or false
 end
 local function location()
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not hum or hum.Health<=0 or (player:GetAttribute("CurrentWorld") or 1)~=1 then return false,false end
  local bounds=RS:FindFirstChild("BattleBagLobbyBounds")
  local cf=bounds and bounds:GetAttribute("World1CFrame");local size=bounds and bounds:GetAttribute("World1Size")
  if typeof(cf)~="CFrame" or typeof(size)~="Vector3" then return false,false end
  local p=cf:PointToObjectSpace(root.Position)
  local inside=math.abs(p.X)<=size.X/2 and math.abs(p.Z)<=size.Z/2 and math.abs(p.Y)<=40
  local part=Egg.part("Basic")
  return inside,part and (root.Position-part.Position).Magnitude<=Config.Egg.reach or false,part
 end
 local function project()
  if not sheetTarget or not sheetTarget.Parent then proxy.Visible=false;return end
  local sheet=sheetTarget:FindFirstAncestorOfClass("BillboardGui")
  local camera=workspace.CurrentCamera
  local part=sheet and sheet.Adornee
  if not sheet or not sheet.Enabled or not part or not camera or not displayed(sheetTarget) then proxy.Visible=false;return end
  local point=camera:WorldToScreenPoint(part.Position+sheet.StudsOffsetWorldSpace)
  if point.Z<=0 then proxy.Visible=false;return end
  -- The ordinary Egg sheet is unrotated; descendant AbsolutePosition is sheet-local.
  local corner=Vector2.new(point.X,point.Y)-sheet.AbsoluteSize/2+sheetTarget.AbsolutePosition
  proxy.Position=UDim2.fromOffset(corner.X-canvas.AbsolutePosition.X,corner.Y-canvas.AbsolutePosition.Y)
  proxy.Size=UDim2.fromOffset(sheetTarget.AbsoluteSize.X,sheetTarget.AbsoluteSize.Y)
  proxy.Visible=true
 end
 local function refresh()
  if dead then return end
  local currentGeneration=player:GetAttribute("PetViewGeneration") or 0
  if currentGeneration~=generation then
   generation=currentGeneration;dismissed=false;priorCompleted=nil;completionPending=nil;completionUntil=nil
   hide("Reset")
  end
  local inLobby,near,part=location()
  local inventoryOpen=MenuClient.shown()=="Inventory"
  local revision=MenuClient.closeRevision()
  if revision~=closeRevision then closeRevision=revision;dismissed=true end
  if inventoryOpen or near and not wasNear or inLobby and not wasLobby then dismissed=false end
  if not inLobby then dismissed=false end
  wasLobby=inLobby;wasNear=near
  local tutorial=PetClient.tutorialState();local pets=PetClient.state()
  if not tutorial or not pets then hide("Loading");return end
  if not tutorial.Eligible then hide("Ineligible");return end
  if priorCompleted==false and tutorial.Completed then completionPending=true end
  priorCompleted=tutorial.Completed
  if tutorial.Completed and not completionPending then hide("Complete");return end
  -- This gate belongs only to initial Egg/Pet guidance, never to shared Ore guides.
  if player:GetAttribute("EggTutorialStage2Defeated")~=true then
   completionPending=nil;completionUntil=nil;hide("WaitingForStage2Victory");return
  end
  if not require(script.Parent.FirstBattleTutorialState).AllowLaterGuides(player) or not inLobby then hide("WaitingForLobby");return end
  if HatchClient.playing() or PetClient.busy() then hide("WaitingForHatch",Coordinator.Owner()==overlay);return end
  if blocked() then
   local merge=pg:FindFirstChild("MergeShopGui")
   local usingMerge=merge and merge:FindFirstChild("MergeShopPanel") and displayed(merge.MergeShopPanel)
   local usingEquipment=gui.InventoryPanel.Visible
   hide("WaitingForDisplay",not usingMerge and not usingEquipment and Coordinator.Owner()==overlay);return
  end
  if dismissed and not inventoryOpen then hide("Dismissed");return end
  local owned=State.OwnedTarget(tutorial,pets)
  if not tutorial.Completed and not owned and (player:GetAttribute("Win") or 0)<Egg.price("Basic") then hide("WaitingForWin");return end
  if not Coordinator.Acquire(overlay) then hide("WaitingForGuide");return end
  local target,nextStep
  sheetTarget=nil;proxy.Visible=false;navigation(nil)
  if tutorial.Completed then
   completionUntil=completionUntil or os.clock()+(overlay:GetAttribute("CompletionSeconds") or 2.5)
   if os.clock()>=completionUntil then completionPending=nil;hide("Complete");return end
   nextStep="Complete"
  elseif owned then
   if inventoryOpen then
    local inventory=screen.Menus:FindFirstChild("Inventory")
    target=inventory and inventory.Main:FindFirstChild("PetBestEquip")
    nextStep="Equip"
   else
    local menu=gui:FindFirstChild("LeftMenu")
    target=menu and menu:FindFirstChild("PetsButton");nextStep="OpenPets"
   end
  else
   if inventoryOpen then hide("WaitingForEgg");return end
   local sheet=screen:FindFirstChild("Basic")
   local opens=sheet and sheet:FindFirstChild("Opens")
   local open1=opens and opens:FindFirstChild("Open1")
   if near and sheet and sheet.Enabled and open1 and displayed(open1) then
    sheetTarget=open1;project();target=proxy;nextStep="OpenOne"
   else
    if not part then hide("WaitingForEgg");return end
    nextStep="GoToEgg";navigation(part.Position)
   end
  end
  if nextStep~="GoToEgg" and nextStep~="Complete" and not target then hide("WaitingForControl");return end
  step=nextStep;overlay:SetAttribute("Step",step)
  overlay:SetAttribute("Target",sheetTarget and sheetTarget:GetFullName() or target and target:GetFullName() or nil)
  presentation:Pin(overlay.Messages[step].Value);presentation:Target(target)
 end
 connect(PetClient.StateChanged,refresh)
 for _,name in {"Win","CurrentWorld","TutorialCompleted","EggTutorialStage2Defeated","PetViewGeneration","PetSavePending","RunReturnBusy","StageSkipBusy"} do
  connect(player:GetAttributeChangedSignal(name),refresh)
 end
 connect(player:GetAttributeChangedSignal("TutorialResetSequence"),function()
  dismissed=false;priorCompleted=nil;completionPending=nil;completionUntil=nil;hide("Reset");refresh()
 end)
 connect(player.CharacterRemoving,function()hide("WaitingForLobby")end)
 connect(RunService.Heartbeat,function(dt)
  elapsed+=dt;if elapsed<.2 then return end;elapsed=0;refresh()
 end)
 connect(RunService.RenderStepped,project)
 refresh()
 return function()
  if dead then return end
  hide("Stopped");dead=true;presentation:Destroy()
  for _,c in connections do c:Disconnect() end
 end
end
return M
