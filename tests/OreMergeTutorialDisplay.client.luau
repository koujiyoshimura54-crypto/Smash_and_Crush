-- Appended temporarily to the native MergePanelClient_New owner for its real view.
-- No OS input, production requests, legacy tutorial start, or camera changes.
local qa=Instance.new('BindableFunction');qa.Name='__OreDisplayClient'
local pg=player.PlayerGui
local overlay=pg.OreMergeTutorialGui
local renderer=require(RS.Modules.OreMergeTutorialPresentation)
local function rect(x)return {X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y}end
local original,originalDraw,referenceTarget,referenceSnap
local normalView=view
local narrowScreen,narrowFrame
local originalCanvas={Position=overlay.Canvas.Position,Size=overlay.Canvas.Size}
local history={};local lastHealth,lastStep
RunService.Heartbeat:Connect(function()
 local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 local health=humanoid and humanoid.Health or -1;local step=overlay:GetAttribute('Step')
 if health~=lastHealth or step~=lastStep then
  table.insert(history,{Health=health,Step=step,FocusVisible=overlay.Canvas.Highlight.Visible})
  lastHealth=health;lastStep=step
 end
end)
local function referenceOff()
 if originalDraw then originalDraw:Disconnect();originalDraw=nil end
 if original then original:Destroy();original=nil end
end
local function status()
 local focus=overlay.Canvas.Highlight
 local lines=overlay.Canvas.Notification.Stack
 local line=lines:FindFirstChild('PinnedLine')
 local state=view:GetOreTutorialState()
 return {Step=overlay:GetAttribute('Step'),Target=overlay:GetAttribute('Target'),Focus=rect(focus),Visible=focus.Visible,
  Message=line and line.Message.Text,MessageBounds=line and rect(line.Message),Canvas=rect(overlay.Canvas),
  Panel=rect(view.Root),Header=rect(view.Root.Top),Close=rect(view.Root.Top.Close),Ore=rect(view.Tabs.Ore),
  Merge=rect(view.Merge),Selected=state.SelectedCount,Repeat=state.RepeatMaterial,Material=state.MaterialTarget and state.MaterialTarget.Name,
  LineCount=(function()local n=0;for _,x in lines:GetChildren() do if x.Name=='PinnedLine' then n+=1 end end;return n end)(),Thickness=focus.Outline.Thickness,Shadow=focus.Shadow.Thickness,
  Corner=tostring(focus.Corner.CornerRadius),Grow=focus:GetAttribute('GuiGrow'),
  ModalFocus=focus.Active or focus.Interactable,TemplateVisible=lines.Line.Visible}
end
qa.OnInvoke=function(action,value)
 if action=='Status' then return status()
 elseif action=='History' then return history
 elseif action=='Show' then openShop()
 elseif action=='Hide' then view:Hide('Closed')
 elseif action=='Tab' then view:SelectTab(value)
 elseif action=='Add' then view:ActivateMaterial(value)
 elseif action=='Remove' then view:RemoveMaterial(value)
 elseif action=='Clear' then view:Clear()
 elseif action=='Submit' then view:SubmitItem()
 elseif action=='Scroll' then view.List.CanvasPosition=Vector2.new(0,value)
 elseif action=='Narrow' then
  stopOreTutorial();view:Hide()
  narrowScreen=Instance.new('ScreenGui');narrowScreen.Name='__OreDisplayNarrow';narrowScreen.DisplayOrder=40
  narrowScreen.ResetOnSpawn=false;narrowScreen.IgnoreGuiInset=true;narrowScreen.Parent=pg
  narrowFrame=Instance.new('Frame');narrowFrame.Name='Bounds';narrowFrame.BackgroundTransparency=1
  narrowFrame.Size=UDim2.fromOffset(460,560);narrowFrame.Position=UDim2.fromOffset(20,-narrowScreen.AbsolutePosition.Y);narrowFrame.Parent=narrowScreen
  local source=gui.ShopPanel:Clone();source.Visible=false;source.Parent=narrowFrame
  view=buildMergeShop({gui=narrowFrame,RS=RS,PetClient=PetClient,Egg=Egg,Master=Master,ItemColors=colors,
   PurchasedInventory=game.StarterGui.ScreenGui.Menus.Inventory.Main,EggViewport=require(RS.Modules.LimitedPetViewport),
   Input=game.UserInputService,GuiService=game.GuiService})
  overlay.Canvas.Position=narrowFrame.Position;overlay.Canvas.Size=narrowFrame.Size
  stopOreTutorial=require(RS.Modules.OreMergeTutorialGuide).Mount(player,narrowFrame,view)
  view:Show()
 elseif action=='Resize' then
  assert(narrowFrame);narrowFrame.Size=UDim2.fromOffset(value.X,value.Y);overlay.Canvas.Size=narrowFrame.Size
 elseif action=='Move' then
  assert(narrowFrame);narrowFrame.Position+=UDim2.fromOffset(value,0);overlay.Canvas.Position=narrowFrame.Position
 elseif action=='Normal' then
  referenceOff();stopOreTutorial();view:Destroy();narrowScreen:Destroy();view=normalView
  overlay.Canvas.Position=originalCanvas.Position;overlay.Canvas.Size=originalCanvas.Size
  stopOreTutorial=require(RS.Modules.OreMergeTutorialGuide).Mount(player,gui,view);view:Show()
 elseif action=='Transition' then
  local h=overlay.Canvas.Highlight;local canvas=overlay.Canvas
  local expectedPosition,expectedSize=h.Position,h.Size
  view:SelectTab('Ore')
  local target=view:GetOreTutorialState().MaterialTarget;assert(target)
  local samples={};local maxError=0
  local c=RunService.RenderStepped:Connect(function(dt)
   local viewport=canvas.AbsoluteSize;local size=target.AbsoluteSize
   local a=target.AbsolutePosition-canvas.AbsolutePosition
   local position=UDim2.fromScale((a.X+size.X/2)/viewport.X,(a.Y+size.Y/2)/viewport.Y)
   local grown=UDim2.fromScale(size.X*Config.Tutorial.guiGrow/viewport.X,size.Y*Config.Tutorial.guiGrow/viewport.Y)
   local alpha=math.clamp(1-math.exp(-dt/Config.Tutorial.moveSeconds),0,1)
   expectedPosition=expectedPosition:Lerp(position,alpha);expectedSize=expectedSize:Lerp(grown,alpha)
   local wantedPosition,wantedSize=expectedPosition,expectedSize
   -- Compare after all RenderStepped listeners; callback registration order is not an API guarantee.
   task.defer(function()
    local e=math.max(math.abs(h.Position.X.Scale-wantedPosition.X.Scale)*viewport.X,
     math.abs(h.Position.Y.Scale-wantedPosition.Y.Scale)*viewport.Y,
     math.abs(h.Size.X.Scale-wantedSize.X.Scale)*viewport.X,math.abs(h.Size.Y.Scale-wantedSize.Y.Scale)*viewport.Y)
    maxError=math.max(maxError,e);table.insert(samples,{dt=dt,Error=e,X=h.AbsolutePosition.X,Y=h.AbsolutePosition.Y})
   end)
  end)
  task.wait(.4);c:Disconnect()
  return {Samples=samples,MaxPixelError=maxError,State=status()}
 elseif action=='HitTest' then
  local target=value=='Ore' and view.Tabs.Ore or value=='Merge' and view.Merge or view.List:FindFirstChild('ORE_001').Button
  local center=target.AbsolutePosition+target.AbsoluteSize/2
  local objects=pg:GetGuiObjectsAtPosition(center.X,center.Y)
  local found=false;local blockers={}
  for _,x in objects do
   if x==target then found=true end
   if x:IsDescendantOf(overlay) and (x.Active or x.Interactable) then table.insert(blockers,x:GetFullName()) end
  end
  return {TargetPresent=found,TargetActive=target.Active,TargetInteractable=target.Interactable,OverlayBlockers=blockers}
 elseif action=='Drag' then
  local card=view.List:FindFirstChild(value);assert(card)
  local a=card.AbsolutePosition+card.AbsoluteSize/2
  local b=view.Drop.AbsolutePosition+view.Drop.AbsoluteSize/2
  view:PressMaterial(value,a,false,nil);view:MovePointer(b);view:ReleasePointer(b)
 elseif action=='Reference' then
  referenceOff();stopOreTutorial()
  -- Purchased guiRect/draw, copied independently. Only target/container references change.
  original=RS.Assets.Tutorial.TutorialHighlight:Clone();original.Name='__PurchasedReference'
  original.ZIndex=Config.Tutorial.zIndex;original.Parent=overlay.Canvas
  referenceTarget=value=='Merge' and view.Merge or value=='Card' and view.List:FindFirstChild('ORE_001') or view.Tabs.Ore
  referenceSnap=true
  originalDraw=RunService.RenderStepped:Connect(function(delta)
   local viewport=overlay.Canvas.AbsoluteSize
   local size=referenceTarget.AbsoluteSize
   local corner=referenceTarget.AbsolutePosition-overlay.Canvas.AbsolutePosition
   local position=UDim2.fromScale((corner.X+size.X/2)/viewport.X,(corner.Y+size.Y/2)/viewport.Y)
   local grown=UDim2.fromScale(size.X*Config.Tutorial.guiGrow/viewport.X,size.Y*Config.Tutorial.guiGrow/viewport.Y)
   if referenceSnap then original.Position=position;original.Size=grown;referenceSnap=false
   else local alpha=math.clamp(1-math.exp(-delta/Config.Tutorial.moveSeconds),0,1)
    original.Position=original.Position:Lerp(position,alpha);original.Size=original.Size:Lerp(grown,alpha) end
   original.Visible=true
  end)
 elseif action=='Revised' then
  referenceOff();stopOreTutorial=require(RS.Modules.OreMergeTutorialGuide).Mount(player,gui,view)
 elseif action=='ReferenceState' then return {Rect=rect(original),Thickness=original:FindFirstChildOfClass('UIStroke').Thickness}
 else error('Unknown client probe action: '..action) end
 task.wait(.5)
 return status()
end
qa.Parent=RS
print('[OreDisplay QA] native client probe ready')
