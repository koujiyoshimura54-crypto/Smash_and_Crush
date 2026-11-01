-- Presentation only. Completion is committed by the ordinary server Forge transaction.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Forge=require(script.Parent.ForgeClient)
local State=require(script.Parent.OreMergeTutorialState)
local M={}
function M.Mount(player,gui,view)
 local pg=player:WaitForChild("PlayerGui")
 local overlay=pg:WaitForChild("OreMergeTutorialGui")
 local canvas=overlay.Canvas;local focus=canvas.Highlight;local message=canvas.Message
 local messages=overlay.Messages
 local messageSize=message.Size
 local connections,targetConnections={},{}
 local dead,dismissed,wasLobby=false,false,false
 local closeRevision=0
 local target,step
 local elapsed=0
 local function connect(signal,fn) local c=signal:Connect(fn);connections[#connections+1]=c;return c end
 local function navigation(position)
  if player:GetAttribute("OreTutorialTarget")~=position then player:SetAttribute("OreTutorialTarget",position) end
 end
 local function clearTarget()
  for _,c in targetConnections do c:Disconnect() end;table.clear(targetConnections);target=nil
 end
 local function displayed(x)
  while x and x~=pg do
   if x:IsA("GuiObject") and not x.Visible or x:IsA("ScreenGui") and not x.Enabled then return false end
   x=x.Parent
  end
  return x==pg
 end
 local function place()
  if dead or not message.Visible then return end
  local size=canvas.AbsoluteSize;local origin=canvas.AbsolutePosition
  local pad=8
  local width=math.max(1,math.min(message:GetAttribute("MaxWidth") or 500,size.X-2*pad,
   size.X*messageSize.X.Scale+messageSize.X.Offset))
  local height=math.max(1,size.Y*messageSize.Y.Scale+messageSize.Y.Offset)
  local center=Vector2.new(size.X*.5,math.max(pad,size.Y*.06))
  focus.Visible=false
  if target and target.Parent and displayed(target) then
   local a=target.AbsolutePosition-origin;local b=a+target.AbsoluteSize
   local ancestor=target.Parent
   while ancestor and ancestor~=pg do
    if ancestor:IsA("GuiObject") and ancestor.ClipsDescendants then
     local p=ancestor.AbsolutePosition-origin;local q=p+ancestor.AbsoluteSize
     a=Vector2.new(math.max(a.X,p.X),math.max(a.Y,p.Y));b=Vector2.new(math.min(b.X,q.X),math.min(b.Y,q.Y))
    end
    ancestor=ancestor.Parent
   end
   a=Vector2.new(math.max(a.X,0),math.max(a.Y,0));b=Vector2.new(math.min(b.X,size.X),math.min(b.Y,size.Y))
   if b.X>a.X and b.Y>a.Y then
    local px=focus:GetAttribute("PaddingX") or 0;local py=focus:GetAttribute("PaddingY") or 0
    focus.Position=UDim2.fromOffset(a.X-px,a.Y-py);focus.Size=UDim2.fromOffset(b.X-a.X+2*px,b.Y-a.Y+2*py);focus.Visible=true
    local gap=message:GetAttribute("Gap") or 0
    local y=a.Y-height-gap-py
    if y<pad then y=b.Y+py+gap end
    center=Vector2.new((a.X+b.X)/2,math.clamp(y,pad,math.max(pad,size.Y-height-pad)))
   end
  end
  -- While the panel is open, use its title band for the callout. The target
  -- outline remains on the control; instructions never cover tabs or ore cards.
  local header=view.Root:FindFirstChild("Top")
  if header and displayed(view.Root) then
   local hp=header.AbsolutePosition-origin;local hs=header.AbsoluteSize
   local inset=message:GetAttribute("HeaderInset") or 4
   width=math.max(1,hs.X*(message:GetAttribute("HeaderWidthScale") or .70))
   height=math.max(1,hs.Y-2*inset)
   center=Vector2.new(hp.X+hs.X*(message:GetAttribute("HeaderCenterX") or .50),hp.Y+inset)
  end
  message.Size=UDim2.fromOffset(width,height)
  message.Position=UDim2.fromOffset(math.clamp(center.X,width*.5+pad,math.max(width*.5+pad,size.X-width*.5-pad)),center.Y)
 end
 local function setTarget(nextTarget)
  if target==nextTarget then place();return end
  clearTarget();target=nextTarget
  if target then
   for _,property in {"AbsolutePosition","AbsoluteSize","Visible"} do
    targetConnections[#targetConnections+1]=target:GetPropertyChangedSignal(property):Connect(place)
   end
   targetConnections[#targetConnections+1]=target.AncestryChanged:Connect(place)
  end
  place()
 end
 local function hide(reason)
  navigation(nil);step=nil;focus.Visible=false;message.Visible=false;clearTarget()
  overlay:SetAttribute("Step",reason or "Waiting")
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
  local current=view:GetOreTutorialState()
  if current.CloseRevision~=closeRevision then closeRevision=current.CloseRevision;dismissed=true end
  if current.Open then dismissed=false end
  local inLobby,destination=lobby()
  if not inLobby then dismissed=false end
  if inLobby and not wasLobby then dismissed=false end;wasLobby=inLobby
  if player:GetAttribute("OreTutorialEligible")~=true then hide("Ineligible");return end
  if player:GetAttribute("OreTutorialCompleted")==true then hide("Complete");return end
  if player:GetAttribute("TutorialCompleted")~=true or not inLobby or blocked() then hide("Waiting");return end
  local state=Forge.State
  if not state or not state.Loaded or state.Token~=player:GetAttribute("ForgeSessionToken")
   or State.AvailableCount(state.Ores)<2 then hide("WaitingForOres");return end
  if dismissed and not current.Open then hide("Dismissed");return end
  local nextStep,nextTarget
  if not current.Open then
   if not destination then hide("WaitingForFacility");return end
   nextStep="GoToMerge";navigation(destination.Position)
  else
   navigation(nil)
   if current.Tab~="Ore" or current.Selling then nextStep="ChooseOre";nextTarget=view.Tabs.Ore
   elseif current.Pending then nextStep="Saving";nextTarget=view.Merge
   elseif current.Valid then nextStep="Merge";nextTarget=view.Merge
   else nextStep="AddOres";nextTarget=view.List end
  end
  step=nextStep;overlay:SetAttribute("Step",step)
  message.Text=messages[step].Value;message.Visible=true;setTarget(nextTarget)
 end
 connect(view.Changed,refresh);connect(Forge.Changed,refresh)
 for _,name in {"TutorialCompleted","OreTutorialEligible","OreTutorialCompleted","ForgeSessionToken","TutorialResetSequence","RunReturnBusy","CurrentWorld"} do
  connect(player:GetAttributeChangedSignal(name),function()
   if name=="TutorialResetSequence" or name=="ForgeSessionToken" then dismissed=false end
   refresh()
  end)
 end
 connect(canvas:GetPropertyChangedSignal("AbsoluteSize"),place)
 connect(focus.AttributeChanged,place);connect(message.AttributeChanged,place)
 connect(player.CharacterRemoving,function()hide("Waiting")end)
 -- Only fixed references / known modal paths at 5Hz; no full Workspace/PlayerGui scans.
 connect(RunService.Heartbeat,function(dt)
  elapsed+=dt;if elapsed<.2 then return end;elapsed=0
  if player:GetAttribute("OreTutorialEligible")==true and player:GetAttribute("OreTutorialCompleted")~=true then refresh() end
 end)
 task.defer(Forge.Refresh);refresh()
 return function()
  if dead then return end;hide("Stopped");dead=true
  for _,c in connections do c:Disconnect() end
 end
end
return M
