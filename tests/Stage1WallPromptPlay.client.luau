-- Native observation and synthetic UI/state controls. Never a shipping dependency.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer;local pg=p:WaitForChild("PlayerGui")
local q=RS:WaitForChild("__WallPromptQA")
local packets={};local frames=0
game:GetService("RunService").RenderStepped:Connect(function()frames+=1 end)
RS.Remotes.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if d.Type=="CombatAttack" and d.OwnerUserId==p.UserId then packets[#packets+1]={Type=d.CombatType,Manual=d.Manual,Index=d.WallIndex,Id=d.Id} end
end)
local call=Instance.new("BindableFunction");call.Name="Client";call.Parent=q
local removed,removedParent
call.OnInvoke=function(action,value)
 if action=="Tap" then RS.Remotes.AutoTapRequest:FireServer("Tap")
 elseif action=="Menu" then pg.StrengthGui.InventoryPanel.Visible=value
 elseif action=="Camera" then
  game:GetService("RunService"):UnbindFromRenderStep("__WallPromptQACamera")
  local root=p.Character.HumanoidRootPart;local camera=workspace.CurrentCamera
  camera.CameraType=Enum.CameraType.Custom
  local pos=root.Position+Vector3.new(0,8,-18)
  camera.CFrame=CFrame.lookAt(pos,root.Position+Vector3.new(0,3,8))
 elseif action=="PinCamera" or action=="Behind" then
  local camera=workspace.CurrentCamera;local cf=camera.CFrame
  if action=="Behind" then cf*=CFrame.Angles(0,math.pi,0) end
  game:GetService("RunService"):UnbindFromRenderStep("__WallPromptQACamera")
  game:GetService("RunService"):BindToRenderStep("__WallPromptQACamera",Enum.RenderPriority.Camera.Value+1,function() camera.CFrame=cf end)
 elseif action=="Unload" then
  removed=workspace.GeneratedMap.BattleCorridor.Stage01["Stage1.1"];removedParent=removed.Parent;removed.Parent=nil
 elseif action=="Reload" then removed.Parent=removedParent;removed=nil;removedParent=nil
 elseif action~="State" then error("Unknown fixture action") end
 local gui=pg:FindFirstChild("Stage1WallPromptGui");local hand=gui and gui:FindFirstChild("Finger");local label=gui and gui:FindFirstChild("Action")
 local count=0 for _,x in pg:GetChildren()do if x.Name=="Stage1WallPromptGui" then count+=1 end end
 local center=hand and hand.AbsolutePosition+hand.AbsoluteSize/2
 local intercept={}
 if center then for _,x in pg:GetGuiObjectsAtPosition(center.X,center.Y)do
  local node=x
  while node and node~=pg do
   if node:IsA("GuiButton")or node:IsA("TextBox")or node:IsA("ScrollingFrame")or node:IsA("GuiObject")and node.Active then intercept[#intercept+1]=node:GetFullName();break end
   node=node.Parent
  end
 end end
 return {Shown=gui and gui.Enabled,Count=count,Label=label and label.Text,Loaded=hand and hand.IsLoaded,
  Hand=hand and {X=hand.AbsolutePosition.X,Y=hand.AbsolutePosition.Y,W=hand.AbsoluteSize.X,H=hand.AbsoluteSize.Y},
  Center=center and {center.X,center.Y},Intercept=intercept,Packets=packets,Frames=frames,
  Completed=p:GetAttribute("Stage1WallPromptCompletedEpoch"),Epoch=p:GetAttribute("TutorialResetSequence"),
  Input=game:GetService("UserInputService").PreferredInput.Name,
  Viewport=tostring(workspace.CurrentCamera.ViewportSize),Position=p.Character and tostring(p.Character:GetPivot().Position)}
end
q:SetAttribute("ClientReady",true)
