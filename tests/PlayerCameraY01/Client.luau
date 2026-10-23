-- Temporary native LocalScript: use real game ModuleScript cache, not plugin require.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local Run=game:GetService("RunService")
local remote=RS:WaitForChild("__Y01CameraControl")
local pm=p.PlayerScripts:FindFirstChild("PlayerModule") or game.StarterPlayer:WaitForChild("PlayerModule")
local cm=require(pm:WaitForChild("CameraModule"))
local function sample()
 local c=workspace.CurrentCamera;local ctl=cm.activeCameraController
 local ch=p.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid")
 local target=ctl and ctl:GetCameraToSubjectDistance()
 local scale=ch and ch:GetAttribute("MuscleHeightScale")
 return {Scale=scale,Expected=scale and 18*(1+(scale-1)*.15),Nominal=target,
  Measured=(c.CFrame.Position-c.Focus.Position).Magnitude,Type=c.CameraType.Name,
  Offset=h and {h.CameraOffset.X,h.CameraOffset.Y,h.CameraOffset.Z},Min=p.CameraMinZoomDistance,Max=p.CameraMaxZoomDistance,
  SubjectMatches=h==c.CameraSubject,World=p:GetAttribute("CurrentWorld") or 1,
  Position={c.CFrame.X,c.CFrame.Y,c.CFrame.Z},Focus={c.Focus.X,c.Focus.Y,c.Focus.Z}}
end
local control=Instance.new("BindableFunction");control.Name="__Y01ClientControl";control.Parent=p.PlayerScripts
control.OnInvoke=function(op,value)
 if op=="sample" then return sample()
 elseif op=="server" then return remote:InvokeServer(value[1],value[2])
 elseif op=="scriptedGrowth" then
  local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable
  remote:InvokeServer("strength",value);task.wait(.5)
  local during=sample();c.CameraType=Enum.CameraType.Custom;task.wait(.5)
  return {During=during,After=sample()}
 elseif op=="travel" then
  remote:InvokeServer("gate",value)
  RS.Remotes.WorldTravelRequest:FireServer(value==2 and "ToWorld2" or "ReturnWorld1");task.wait(2)
  return sample()
 elseif op=="replace" then
  local old=workspace.CurrentCamera;local c=Instance.new("Camera");c.CFrame=old.CFrame;c.Focus=old.Focus
  c.CameraSubject=p.Character.Humanoid;c.CameraType=Enum.CameraType.Custom;c.Parent=workspace;workspace.CurrentCamera=c;old:Destroy()
  task.wait(.5);return sample()
 elseif op=="subject" then
  local c=workspace.CurrentCamera;local h=p.Character.Humanoid;c.CameraSubject=p.Character.Head
  task.wait(.2);c.CameraSubject=h;task.wait(.4);return sample()
 elseif op=="zoom" then cm.activeCameraController:SetCameraToSubjectDistance(value);task.wait(.3);return sample()
 elseif op=="death" then
  local ch=p.Character;remote:InvokeServer("die");task.wait(.2)
  local c=workspace.CurrentCamera;local a=c.CFrame;task.wait(.3)
  local frozen={Type=c.CameraType.Name,Stationary=a==c.CFrame}
  local deadline=os.clock()+15
  repeat task.wait(.1) until (p.Character~=ch and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health>0) or os.clock()>deadline
  task.wait(1);return {Frozen=frozen,Respawn=sample()}
 end
end
