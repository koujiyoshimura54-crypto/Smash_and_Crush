-- Temporary isolated Play fixture; never install in published game.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local Run=game:GetService('RunService');local p=game.Players.LocalPlayer;local q=game.ReplicatedStorage.__Stage1MotionQA;local f=Instance.new('BindableFunction');f.Name='Client';f.Parent=q
local locked=false;local fixed;local frames=0;Run:BindToRenderStep('__Stage1MotionCamera',Enum.RenderPriority.Last.Value+2,function()frames+=1;if locked then workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable;workspace.CurrentCamera.CFrame=fixed end end)
local function rig()return workspace.Enemies['Owner_'..p.UserId].Stage01_Enemy.BallerinaCappuccinaRig end
f.OnInvoke=function(action,value)
 local r=rig();if action=='Amplitude'then require(game.ReplicatedStorage.Config.Stage01MotionConfig).Amplitude=value
 elseif action=='Ground'then require(game.ReplicatedStorage.Config.Stage01MotionConfig).GroundFit=value
 elseif action=='Camera'then local center=r.RootPart.Position+Vector3.new(0,1.5,0);fixed=CFrame.lookAt(center+Vector3.new(13,4,-24),center);locked=true
 elseif action=='Side'then local center=r.RootPart.Position+Vector3.new(0,-1,0);fixed=CFrame.lookAt(center+Vector3.new(19,1,-8),center);locked=true
 elseif action=='Phase'then for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(0);t.TimePosition=t.Animation.AnimationId:find('101135')and value or 0 end
 elseif action=='Run'then for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(1)end
 elseif action=='HUD'then for _,g in p.PlayerGui:GetChildren()do if g:IsA('ScreenGui')then g.Enabled=value end end
 elseif action=='Sample'then
  local rows={};local start=os.clock();repeat local row={Time=os.clock()-start,Poses={},Tracks={}};for _,b in r.FakeRootPart:GetDescendants()do if b:IsA('Bone')then row.Poses[b.Name]={CF={b.Transform:GetComponents()},World={b.TransformedWorldCFrame:GetComponents()}}end end;for _,t in r.AnimationController.Animator:GetPlayingAnimationTracks()do table.insert(row.Tracks,{Name=t.Name,Time=t.TimePosition,Length=t.Length,Speed=t.Speed,Weight=t.WeightCurrent,Priority=t.Priority.Name})end;table.insert(rows,row);Run.PostSimulation:Wait()until os.clock()-start>value;return game.HttpService:JSONEncode(rows)
 end
 return {Frames=frames,Camera=tostring(workspace.CurrentCamera.CFrame),Viewport=tostring(workspace.CurrentCamera.ViewportSize),Root=tostring(r.RootPart.Position),Scale=r:GetScale()}
end
