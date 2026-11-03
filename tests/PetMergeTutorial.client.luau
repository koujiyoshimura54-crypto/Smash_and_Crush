local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local pg=p:WaitForChild("PlayerGui")
local services=script.Parent.Services
local PC=require(services.PetClient)
local HC=require(services.HatchClient)
local function waitFor(fn)
 for i=1,250 do local v=fn();if v then return v end;task.wait(.1)end error("PM client timeout")
end
local view=waitFor(function()return _G.__PMView end)
local overlay=pg:WaitForChild("PetMergeTutorialGui")
local history,last={},nil
game.RunService.Heartbeat:Connect(function()
 local s=overlay:GetAttribute("Step");if s~=last then last=s;table.insert(history,{Step=s,At=os.clock()})end
end)
local function rect(x)return x and {X=x.AbsolutePosition.X,Y=x.AbsolutePosition.Y,W=x.AbsoluteSize.X,H=x.AbsoluteSize.Y}end
local function status()
 local t=view:GetPetTutorialState();t.MaterialTarget=t.MaterialTarget and t.MaterialTarget:GetFullName()
 local line=overlay.Canvas.Notification.Stack:FindFirstChild("PinnedLine")
 local cards={}
 for _,x in view.List:GetChildren()do if x:IsA("GuiObject")then table.insert(cards,{Name=x.Name,Points=x:GetAttribute("Points"),Selected=x:GetAttribute("SelectedCount"),Order=x.LayoutOrder,Rect=rect(x)})end end
 table.sort(cards,function(a,b)return a.Order<b.Order end)
 return {Step=overlay:GetAttribute("Step"),Target=overlay:GetAttribute("Target"),Arrow=tostring(p:GetAttribute("PetMergeTutorialTarget")),
  EggStep=pg.EggPetTutorialGui:GetAttribute("Step"),OreStep=pg.OreMergeTutorialGui:GetAttribute("Step"),Owner=tostring(require(RS.Modules.TutorialPresentationCoordinator).Owner()),
  Message=line and line.Message.Text,MessageRect=line and rect(line.Message),Focus=rect(overlay.Canvas.Highlight),FocusVisible=overlay.Canvas.Highlight.Visible,
  View=t,Cards=cards,Tutorial=PC.mergeTutorialState(),Pets=PC.state(),Busy=PC.busy(),Hatch=HC.playing(),Root=rect(view.Root),
  Outline=overlay.Canvas.Highlight.Outline.Thickness,Shadow=overlay.Canvas.Highlight.Shadow.Transparency,Grow=overlay.Canvas.Highlight:GetAttribute("GuiGrow")}
end
local probe=Instance.new("BindableFunction");probe.Name="__PMQAProbe"
probe.OnInvoke=function(action,v)
 if action=="Status"then return status()
 elseif action=="History"then return history
 elseif action=="Refresh"then PC.refresh();view:SetPetState(PC.state())
 elseif action=="Tab"then view:SelectTab(v)
 elseif action=="Add"then view:ActivateMaterial(v)
 elseif action=="Remove"then view:RemoveMaterial(v)
 elseif action=="Submit"then view:SubmitItem()
 elseif action=="Close"then view:Hide("Closed")
 elseif action=="Show"then view:Show()
 elseif action=="Scroll"then view.List.CanvasPosition=Vector2.new(0,v)
 elseif action=="AdvanceHatch"then HC.__QAAdvance()
 elseif action=="Equip"then task.spawn(PC.request,"Equip",v)
 elseif action=="Notification"then require(services.NotifyClient).push({{text="QA notification"}})
 elseif action=="ReplayResponse"then PC.__QAAccept(v)
 elseif action=="Drag"then
  local card=view.List:FindFirstChild(v);local a=card.AbsolutePosition+card.AbsoluteSize/2
  local b=view.Drop.AbsolutePosition+view.Drop.AbsoluteSize/2
  view:PressMaterial(v,a,false);view:MovePointer(b);view:ReleasePointer(b)
 elseif action=="Hit"then
  local a=view.Merge.AbsolutePosition+view.Merge.AbsoluteSize/2;local hits={}
  for _,x in pg:GetGuiObjectsAtPosition(a.X,a.Y) do if x:IsDescendantOf(overlay)and (x.Active or x:IsA("GuiButton")and x.Interactable)then table.insert(hits,x:GetFullName())end end
  return hits
 else error(action)end
 return status()
end
probe.Parent=p.PlayerScripts
print("[PM QA] native client ready")
