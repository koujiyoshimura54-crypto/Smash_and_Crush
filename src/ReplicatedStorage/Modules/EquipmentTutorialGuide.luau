-- Display only. Existing equipment setters and owned-session saves confirm completion.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Presentation=require(script.Parent.OreMergeTutorialPresentation)
local Coordinator=require(script.Parent.TutorialPresentationCoordinator)
local Config=require(script.Parent.Config)
local M={}
function M.Mount(player,services,kind)
 local pg=player:WaitForChild("PlayerGui");local gui=pg:WaitForChild("StrengthGui")
 local overlay=pg:WaitForChild(kind.."EquipTutorialGui")
 local panel=gui:WaitForChild("InventoryPanel");local tab=kind=="Item" and "Items" or "Dumbbells"
 local page=panel.Content[tab];local prefix=kind.."EquipTutorial"
 local Menu=require(services.MenuClient);local Hatch=require(services.HatchClient)
 local renderer=Presentation.Mount(overlay,overlay.Canvas.NotificationRegion)
 local connections={};local dead,dismissed,wasOpen,wasLobby=false,false,false,false
 local generation=player:GetAttribute("ForgeSessionToken")
 local priorCompleted,completionPending,completionUntil
 local elapsed=0;local wasReady=false
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 local function displayed(x)
  while x and x~=pg do
   if x:IsA("GuiObject") and not x.Visible or x:IsA("LayerCollector") and not x.Enabled then return false end
   x=x.Parent
  end
  return x==pg
 end
 local function hide(reason)
  renderer:Hide();overlay:SetAttribute("Step",reason);overlay:SetAttribute("Target",nil);Coordinator.Release(overlay)
 end
 local function lobby()
  local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
  if not root or not hum or hum.Health<=0 then return false end
  local bounds=RS:FindFirstChild("BattleBagLobbyBounds");local world=player:GetAttribute("CurrentWorld") or 1
  local cf=bounds and bounds:GetAttribute("World"..world.."CFrame");local size=bounds and bounds:GetAttribute("World"..world.."Size")
  if typeof(cf)~="CFrame" or typeof(size)~="Vector3" then return false end
  local p=cf:PointToObjectSpace(root.Position)
  return math.abs(p.X)<=size.X/2 and math.abs(p.Z)<=size.Z/2 and math.abs(p.Y)<=40
 end
 local function blocked()
  if player:GetAttribute("RunReturnBusy") or player:GetAttribute("StageSkipBusy") or player:GetAttribute("IsFighting")
   or player:GetAttribute("ForgeSavePending") or player:GetAttribute("PetSavePending") or Hatch.playing() or Menu.shown()~=nil then return true end
  for _,name in {"OfflineRewards","TimeRewardsPanel","DailyRewardsPanel","CommunityRewardsPanel","ShopPanel","RebirthPanel","MergePanel"} do
   local x=gui:FindFirstChild(name);if x and displayed(x) then return true end
  end
  for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"},{"MergeShopGui","MergeShopPanel"}} do
   local root=pg:FindFirstChild(path[1]);local x=root and root:FindFirstChild(path[2]);if x and displayed(x) then return true end
  end
  for _,name in {"HatchGui","EnemyDropGacha","LimitedEgg01Gui","LimitedEgg02Gui"} do local x=pg:FindFirstChild(name);if x and x.Enabled then return true end end
  local screen=pg:FindFirstChild("ScreenGui")
  if screen then for name in Config.Eggs.Eggs do local x=screen:FindFirstChild(name);if x and x:IsA("BillboardGui") and x.Enabled then return true end end end
  local notify=pg:FindFirstChild("NotifyGui");local stack=notify and notify:FindFirstChild("Stack")
  if stack then for _,x in stack:GetChildren() do if x:IsA("GuiObject") and displayed(x) and x.AbsoluteSize.Y>1 then return true end end end
  local win=gui:FindFirstChild("WinLabel");local feedback=win and win:FindFirstChild("RewardFeedbackScale")
  return feedback and math.abs(feedback.Scale-1)>.001 or false
 end
 local function refresh()
  if dead then return end
  local token=player:GetAttribute("ForgeSessionToken")
  if token~=generation then generation=token;dismissed=false;priorCompleted=nil;completionPending=nil;completionUntil=nil;hide("Reset") end
  local inLobby=lobby();local open=panel.Visible
  local ready=player:GetAttribute(prefix.."Ready")==true
  if ready and not wasReady then dismissed=false end
  wasReady=ready
  if wasOpen and not open and ready then dismissed=true end
  if open and not wasOpen or inLobby and not wasLobby then dismissed=false end
  if not inLobby then dismissed=false end
  wasOpen=open;wasLobby=inLobby
  if player:GetAttribute(prefix.."Eligible")~=true then hide("Ineligible");return end
  local complete=player:GetAttribute(prefix.."Completed")==true
  if priorCompleted==false and complete then completionPending=true end
  priorCompleted=complete
  if complete and not completionPending then hide("Complete");return end
  if not token or player:GetAttribute("TutorialCompleted")~=true or not inLobby then hide("WaitingForLobby");return end
  if blocked() then hide("WaitingForDisplay");return end
  if dismissed and not open then hide("Dismissed");return end
  if not complete and player:GetAttribute(prefix.."Ready")~=true then hide("WaitingForEquipment");return end
  if not Coordinator.Acquire(overlay) then hide("WaitingForGuide");return end
  local target,step
  if complete then
   completionUntil=completionUntil or os.clock()+(overlay:GetAttribute("CompletionSeconds") or 2.5)
   if os.clock()>=completionUntil then completionPending=nil;hide("Complete");return end
   step="Complete"
  elseif not open then target=gui.LeftMenu.InventoryButton;step="OpenInventory"
  elseif not page.Visible then target=panel.Tabs[tab];step="ChooseTab"
  else
   local equipped=page.Equipped
   local header=kind=="Item" and equipped:FindFirstChild("EquipmentHeader") or equipped
   target=header and header:FindFirstChild("BestEquipButton");step="Equip"
  end
  if step~="Complete" and (not target or not displayed(target) or not target.Active or not target.Interactable) then hide("WaitingForControl");return end
  overlay:SetAttribute("Step",step);overlay:SetAttribute("Target",target and target:GetFullName() or nil)
  renderer:Pin(overlay.Messages[step].Value);renderer:Target(target)
 end
 for _,name in {prefix.."Eligible",prefix.."Ready",prefix.."Completed","ForgeSessionToken","CurrentWorld","TutorialCompleted","RunReturnBusy","StageSkipBusy","ForgeSavePending","PetSavePending"} do connect(player:GetAttributeChangedSignal(name),refresh) end
 connect(panel:GetPropertyChangedSignal("Visible"),refresh);connect(page:GetPropertyChangedSignal("Visible"),refresh)
 connect(player.CharacterRemoving,function() hide("WaitingForLobby") end)
 connect(RunService.Heartbeat,function(dt)elapsed+=dt;if elapsed>=.2 then elapsed=0;refresh() end end)
 refresh()
 return function()if dead then return end;hide("Stopped");dead=true;renderer:Destroy();for _,c in connections do c:Disconnect()end end
end
return M
