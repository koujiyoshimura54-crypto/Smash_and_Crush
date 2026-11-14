-- Temporary isolated fixture. FloatHold is A/B-only and must be released for motion tests.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local Run=game:GetService('RunService');local p=game.Players.LocalPlayer
local f=Instance.new('BindableFunction');f.Name='Client';f.Parent=game.ReplicatedStorage.__Stage2MotionQA
local locked=false;local fixed;local frames=0;local heldWeld
Run.PostSimulation:Connect(function()if heldWeld and heldWeld.Weld.Parent then heldWeld.Weld.C0=heldWeld.Value end end)
Run:BindToRenderStep('__Stage2MotionCamera',Enum.RenderPriority.Last.Value+2,function()frames+=1;if locked then workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable;workspace.CurrentCamera.CFrame=fixed end end)
local function rig()return workspace.Enemies['Owner_'..p.UserId].Stage02_Enemy.TralaleroTralalaRig end
f.OnInvoke=function(action,value)
 local r=rig()
 if action=='FloatHold'then heldWeld=value and {Weld=r.RootPart.Stage02VisualRootWeld,Value=r.RootPart.Stage02VisualRootWeld.C0}or nil
 elseif action=='Camera'then local center=r.RootPart.Position;fixed=CFrame.lookAt(center+Vector3.new(19,3,-22),center+Vector3.new(0,-1,0));locked=true
 elseif action=='Side'then local center=r.RootPart.Position;fixed=CFrame.lookAt(center+Vector3.new(21,1,5),center+Vector3.new(0,-1,0));locked=true
 elseif action=='Phase'then for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(0);t.TimePosition=t.Animation.AnimationId:find('853126')and value or 0 end
 elseif action=='Run'then for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(1)end
 elseif action=='Amplitude'then require(game.ReplicatedStorage.Config.Stage02LegMotionConfig).Amplitude=value
 elseif action=='HUD'then for _,g in p.PlayerGui:GetChildren()do if g:IsA('ScreenGui')then g.Enabled=value end end end
 local tracks={};for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do table.insert(tracks,{Name=t.Name,Id=t.Animation.AnimationId,Speed=t.Speed,Time=t.TimePosition,Length=t.Length,Weight=t.WeightCurrent,Priority=t.Priority.Name})end
 return {Frames=frames,Root=tostring(r.RootPart.CFrame),Camera=tostring(workspace.CurrentCamera.CFrame),Viewport=tostring(workspace.CurrentCamera.ViewportSize),Scale=r:GetScale(),Tracks=tracks}
end
