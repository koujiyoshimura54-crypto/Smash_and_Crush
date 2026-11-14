local Q=game.ReplicatedStorage:WaitForChild("__BodyQA")
local p=game.Players.LocalPlayer
local cameraCF
game:GetService("RunService"):BindToRenderStep("BodyComparisonCamera",Enum.RenderPriority.Last.Value+2,function()
 if cameraCF then local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.CFrame=cameraCF;c.FieldOfView=50 end
end)
Q.Client.OnInvoke=function(action,a)
 if action=="Camera" then cameraCF=CFrame.lookAt(Vector3.new(unpack(a.Position)),Vector3.new(unpack(a.LookAt)));return true
 elseif action=="ReleaseCamera" then cameraCF=nil;workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;return true
 elseif action=="Panel" then p.PlayerGui.SizeChangeGui.SizePanel.Visible=a.Visible;return true
 elseif action=="Move" then p.Character.Humanoid:Move(Vector3.new(unpack(a.Direction)),true);return true
 elseif action=="Jump" then p.Character.Humanoid.Jump=true;return true
 elseif action=="UI" then
  local g=p.PlayerGui.SizeChangeGui;local panel=g.SizePanel;local b={}
  for _,v in panel:GetChildren() do if v:IsA("GuiButton") then b[#b+1]={Name=v.Name,Position={v.AbsolutePosition.X,v.AbsolutePosition.Y},Size={v.AbsoluteSize.X,v.AbsoluteSize.Y},Visible=v.Visible,Active=v.Active} end end
  return {Viewport={workspace.CurrentCamera.ViewportSize.X,workspace.CurrentCamera.ViewportSize.Y},IconVisible=g.SizeButton.Visible,PanelVisible=panel.Visible,Buttons=b,PanelPosition={panel.AbsolutePosition.X,panel.AbsolutePosition.Y},PanelSize={panel.AbsoluteSize.X,panel.AbsoluteSize.Y}}
 end
end
