-- A noninteractive decoration of the existing floor guide. No attack/input sender.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local State=require(script.Parent.Stage1WallPromptState)
local Coordinator=require(script.Parent.TutorialPresentationCoordinator)
local HUDLayout=require(script.Parent.HUDLayout)
local Config=require(RS.Config.Stage1WallPromptConfig)
local Style=require(RS.Config.StrengthHUDStyle)
local M={}
local mounted=setmetatable({}, {__mode="k"})
local function shown(x,root)
 if not x then return false end
 while x and x~=root do
  if x:IsA("GuiObject") and not x.Visible or x:IsA("LayerCollector") and not x.Enabled
   or x:IsA("CanvasGroup") and x.GroupTransparency>=1 then return false end
  x=x.Parent
 end
 return x==root
end
local function overlap(a,b)
 return a.X<b.X+b.W+4 and a.X+a.W+4>b.X and a.Y<b.Y+b.H+4 and a.Y+a.H+4>b.Y
end
local function rect(x)
 local p,s=x.AbsolutePosition,x.AbsoluteSize
 return {X=p.X,Y=p.Y,W=s.X,H=s.Y}
end
-- Same oriented-wall broad phase as EnemyManager, using its actual replicated trigger.
function M.Contact(trigger,wall)
 local cf=wall.CFrame:ToObjectSpace(trigger.CFrame);local h=trigger.Size/2
 local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
 local extent=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
  math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
  math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
 local p=cf.Position;local half=wall.Size/2
 return math.abs(p.X)<=half.X+extent.X and math.abs(p.Y)<=half.Y+extent.Y and math.abs(p.Z)<=half.Z+extent.Z
end
local function projectedBox(camera,cf,size)
 local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
 for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
  local p=camera:WorldToViewportPoint(cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2))
  if p.Z<=0 then return nil end
  x0=math.min(x0,p.X);y0=math.min(y0,p.Y);x1=math.max(x1,p.X);y1=math.max(y1,p.Y)
 end end end
 return {X=x0,Y=y0,W=x1-x0,H=y1-y0}
end
function M.Mount(player)
 if mounted[player] then mounted[player]:Destroy() end
 local pg=player:WaitForChild("PlayerGui")
 local services=player:WaitForChild("PlayerScripts"):WaitForChild("Services")
 local Menu=require(services:WaitForChild("MenuClient"))
 local Hatch=require(services:WaitForChild("HatchClient"))
 local epoch=player:GetAttribute("TutorialResetSequence") or 0
 local state=State.new(player.UserId,epoch,player:GetAttribute("Stage1WallPromptCompletedEpoch")==epoch)
 local api={};mounted[player]=api
 local connections={};local dead=false;local guideIndex,guideWall,requestState
 local windowFocused=true
 local old=pg:FindFirstChild("Stage1WallPromptGui")
 if old and old:GetAttribute("Stage1WallPromptOwned")==true then old:Destroy() end
 local gui=Instance.new("ScreenGui")
 gui.Name="Stage1WallPromptGui";gui:SetAttribute("Stage1WallPromptOwned",true)
 gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None
 gui.ClipToDeviceSafeArea=true;gui.DisplayOrder=11;gui.Enabled=false
 local hand=Instance.new("ImageLabel");hand.Name="Finger"
 hand.BackgroundTransparency=1;hand.Image=Config.Image;hand.ImageColor3=Color3.new(1,1,1)
 hand.ScaleType=Enum.ScaleType.Fit;hand.AnchorPoint=Config.FingerTip
 hand.Size=UDim2.fromOffset(Config.MinSize,Config.MinSize)
 hand.Active=false;hand.Interactable=false;hand.Selectable=false;hand.Parent=gui
 local label=Instance.new("TextLabel");label.Name="Action"
 label.BackgroundTransparency=1;label.Text="";label.Font=Style.Font
 label.TextColor3=Style.Colors.Text;label.AutoLocalize=false
 label.Active=false;label.Interactable=false;label.Selectable=false;label.Parent=gui
 local outline=Instance.new("UIStroke");outline.Color=Style.Colors.Outline;outline.Thickness=2.5;outline.Parent=label
 gui.Parent=pg
 local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
 local function hide()
  gui.Enabled=false;Coordinator.Release(gui)
 end
 local function reset()
  local nextEpoch=player:GetAttribute("TutorialResetSequence") or 0
  if nextEpoch~=state.Epoch then
   state:Reset(nextEpoch);player:SetAttribute("Stage1WallPromptCompletedEpoch",nil)
   guideIndex=nil;guideWall=nil;hide()
   if requestState then requestState() end
  end
 end
 function api:RequestUsing(fn) requestState=fn end
 function api:SetGuide(index,wall) guideIndex=index;guideWall=wall end
 function api:IsVisible() return gui.Enabled and hand.IsLoaded end
 function api:Handle(d)
  reset()
  if state:Handle(d,player.Character) and state.Completed then
   player:SetAttribute("Stage1WallPromptCompletedEpoch",state.Epoch);hide()
  end
 end
 local function blocked()
  if not windowFocused or GuiService.MenuIsOpen or GuiService.IsModalDialog or UIS:GetFocusedTextBox()
   or Menu.shown()~=nil or Hatch.playing() then return true end
  for _,name in {"RunReturnBusy","StageSkipBusy","WinPassPromptBusy"} do
   if player:GetAttribute(name)==true then return true end
  end
  local strength=pg:FindFirstChild("StrengthGui")
  for _,name in {"OfflineRewards","TimeRewardsPanel","DailyRewardsPanel","CommunityRewardsPanel","InventoryPanel","ShopPanel","RebirthPanel","MergePanel"} do
   if strength and shown(strength:FindFirstChild(name),pg) then return true end
  end
  for _,path in {{"DeathGui","Overlay"},{"WorldTravelGui","Modal"},{"StageSkipGui","Panel"},{"MergeShopGui","MergeShopPanel"}} do
   local root=pg:FindFirstChild(path[1]);if root and shown(root:FindFirstChild(path[2]),pg) then return true end
  end
  for _,name in {"HatchGui","EnemyDropGacha","LimitedEgg01Gui","LimitedEgg02Gui"} do
   local x=pg:FindFirstChild(name);if x and x.Enabled then return true end
  end
  local notify=pg:FindFirstChild("NotifyGui");local stack=notify and notify:FindFirstChild("Stack")
  if stack then for _,x in stack:GetChildren() do if x:IsA("GuiObject") and shown(x,pg) and x.AbsoluteSize.Y>1 then return true end end end
  return false
 end
 local obstacles={};local obstacleElapsed=1
 local function collectObstacles()
  table.clear(obstacles)
  local inset=GuiService:GetGuiInset()
  local function add(box)
   box.X+=inset.X;box.Y+=inset.Y;table.insert(obstacles,box)
  end
  local strength=pg:FindFirstChild("StrengthGui")
  if strength then
   local hud=strength:FindFirstChild("HUD")
   for _,x in {hud and hud:FindFirstChild("RightHUD"),hud and hud:FindFirstChild("LeftHUD")} do
    if x and shown(x,pg) then local box=rect(x);if box.W>0 and box.H>0 then add(box) end end
   end
   local menu=strength:FindFirstChild("LeftMenu")
   if menu then for _,x in menu:GetDescendants() do
    if x:IsA("GuiButton") and shown(x,pg) then add(rect(x)) end
   end end
   local bottom=strength:FindFirstChild("StrengthLevelHUD")
   if bottom then for _,x in bottom:GetChildren() do
    if x:IsA("GuiObject") and shown(x,pg) then add(rect(x)) end
   end end
  end
  for _,control in HUDLayout.GetControls(pg) do
   add({X=control.P.X,Y=control.P.Y,W=control.S.X,H=control.S.Y})
  end
  -- The dynamic stick's transparent input region is larger than its visible disc.
  -- A cue inside it would point at an area that AutoTapClient correctly excludes.
  local touch=pg:FindFirstChild("TouchGui")
  if touch then for _,x in touch:GetDescendants() do
   if x:IsA("GuiObject") and (x.Active or x:IsA("GuiButton")) and shown(x,pg) then add(rect(x)) end
  end end
 end
 local function render(dt)
  if dead then return end
  reset()
  if state.Completed or not guideIndex then hide();return end
  local character=player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local camera=workspace.CurrentCamera;local wall=guideWall
  local ref=character and character:FindFirstChild("WallCombatTriggerRef")
  local trigger=ref and ref:IsA("ObjectValue") and ref.Value
  local loaded=wall~=nil and wall:IsA("BasePart") and wall:IsDescendantOf(workspace) and wall.LocalTransparencyModifier<.99
  local contact=loaded and trigger and trigger:IsA("BasePart") and trigger:IsDescendantOf(workspace)
   and trigger:GetAttribute("OwnerUserId")==player.UserId and M.Contact(trigger,wall)
  if not state:CanShow({GuideIndex=guideIndex,TutorialCompleted=player:GetAttribute("TutorialCompleted"),
   World=player:GetAttribute("CurrentWorld") or (state.Ready and 1),Stage=player:GetAttribute("CurrentStage"),AutoTap=player:GetAttribute("AutoTapEnabled"),
   Alive=humanoid~=nil and humanoid.Health>0 and root~=nil,Training=player:GetAttribute("IsTraining"),
   TargetLoaded=loaded,Contact=contact==true,Blocked=blocked()})
   or not camera or camera.CameraType==Enum.CameraType.Scriptable then hide();return end
  local text=State.Label(UIS.PreferredInput.Name)
  if not text then hide();return end
  local viewport=camera.ViewportSize
  local size=math.clamp(viewport.Y*Config.ViewportHeightRatio,Config.MinSize,Config.MaxSize)
  local textSize=math.clamp(size*.29,Config.MinTextSize,Config.MaxTextSize)
  obstacleElapsed+=dt
  if obstacleElapsed>=.1 then obstacleElapsed=0;collectObstacles() end
  local characterCF,characterSize=character:GetBoundingBox()
  local body=projectedBox(camera,characterCF,characterSize)
  -- Read the real wall and its authored HP region, independently of world placement.
  local hp
  local surface=wall:FindFirstChildOfClass("SurfaceGui")
  local health=surface and surface:FindFirstChild("Health")
  if health and surface.Enabled and health.Visible and surface.Face==Enum.NormalId.Front then
   local canvas=surface.AbsoluteSize
   if canvas.X>0 and canvas.Y>0 then
    local center=health.AbsolutePosition-surface.AbsolutePosition+health.AbsoluteSize/2
    local cf=wall.CFrame*CFrame.new((.5-center.X/canvas.X)*wall.Size.X,
     (.5-center.Y/canvas.Y)*wall.Size.Y,-wall.Size.Z/2-.02)
    hp=projectedBox(camera,cf,Vector3.new(health.AbsoluteSize.X/canvas.X*wall.Size.X,
     health.AbsoluteSize.Y/canvas.Y*wall.Size.Y,.01))
   end
  end
  local rootLocal=wall.CFrame:PointToObjectSpace(root.Position)
  local cameraLocal=wall.CFrame:PointToObjectSpace(camera.CFrame.Position)
  local depth=(cameraLocal.Z<0 and -1 or 1)*(wall.Size.Z/2+.02)
  local origin=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
  local inset=GuiService:GetGuiInset()
  local chosen,labelPosition,labelWidth
  -- All candidates lie on the actual wall face. Never clamp an offscreen target
  -- to a screen edge: try a clear face position, otherwise wait for a better view.
  for _,layout in {"Below","Left","Right"} do
  for _,offset in {Vector2.new(-6,.3),Vector2.new(6,.3),Vector2.new(-10,0),Vector2.new(10,0),Vector2.new(-14,0),Vector2.new(14,0),Vector2.new(-6,1.5),Vector2.new(6,1.5),Vector2.new(-10,3.5),Vector2.new(10,3.5),Vector2.new(-6,6.5),Vector2.new(6,6.5)} do
   local localPoint=Vector3.new(math.clamp(rootLocal.X+offset.X,-wall.Size.X*.42,wall.Size.X*.42),
    math.clamp(rootLocal.Y+offset.Y,-wall.Size.Y*.42,wall.Size.Y*.42),depth)
   local p,onScreen=camera:WorldToViewportPoint(wall.CFrame:PointToWorldSpace(localPoint))
   local left,top=p.X-size*Config.FingerTip.X,p.Y-size*Config.FingerTip.Y
   local width=layout=="Below" and size or math.max(60,textSize*2.7)
   local labelX=layout=="Left" and left-width-6 or layout=="Right" and left+size+6 or left
   local labelY=layout=="Below" and top+size or top+(size-textSize-6)/2
   local x0,y0=math.min(left,labelX),math.min(top,labelY)
   local box={X=x0-Config.PressPixels,Y=y0-Config.PressPixels,
    W=math.max(left+size,labelX+width)-x0+Config.PressPixels,
    H=math.max(top+size,labelY+textSize+6)-y0+Config.PressPixels}
   local clear=onScreen and p.Z>0 and box.X>=origin.Min.X+inset.X+8 and box.Y>=origin.Min.Y+inset.Y+8
    and box.X+box.W<=origin.Max.X+inset.X-8 and box.Y+box.H<=origin.Max.Y+inset.Y-8
    and not (body and overlap(box,body)) and not (hp and overlap(box,hp))
   if clear then for _,block in obstacles do if overlap(box,block) then clear=false;break end end end
   if clear then chosen=Vector2.new(p.X,p.Y);labelPosition=Vector2.new(labelX,labelY);labelWidth=width;break end
  end
  if chosen then break end
  end
  if not chosen or not Coordinator.Acquire(gui) then hide();return end
  local press=(1-math.cos(os.clock()*math.pi*2/Config.Period))/2
  local animatedSize=size*(1-(1-Config.PressScale)*press)
  hand.Size=UDim2.fromOffset(animatedSize,animatedSize)
  hand.Position=UDim2.fromOffset(chosen.X-Config.PressPixels*press,chosen.Y-Config.PressPixels*press)
  -- Enabling the eligible image lets the engine load/retry it. A failed eager
  -- preload must not permanently suppress the cue; do not show a text-only cue.
  label.Visible=hand.IsLoaded;label.Text=text;label.TextSize=textSize
  label.Size=UDim2.fromOffset(labelWidth,textSize+6)
  label.Position=UDim2.fromOffset(labelPosition.X,labelPosition.Y)
  gui.Enabled=true
 end
 connect(player:GetAttributeChangedSignal("TutorialResetSequence"),reset)
 connect(player.CharacterRemoving,function() state:Invalidate();guideIndex=nil;guideWall=nil;hide() end)
 connect(UIS.WindowFocusReleased,function() windowFocused=false;hide() end)
 connect(UIS.WindowFocused,function() windowFocused=true end)
 connect(RunService.RenderStepped,render)
 function api:Destroy()
  if dead then return end
  dead=true;hide();for _,c in connections do c:Disconnect() end;gui:Destroy()
  if mounted[player]==api then mounted[player]=nil end
 end
 return api
end
return M
