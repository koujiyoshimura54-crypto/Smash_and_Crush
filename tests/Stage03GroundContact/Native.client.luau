-- Temporary isolated Studio fixture; never publish.
assert(game.RunService:IsStudio()and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local Run=game.RunService;local p=game.Players.LocalPlayer;local f=Instance.new('BindableFunction');f.Name='Client';f.Parent=game.ReplicatedStorage.__Stage3GroundQA
local locked=false;local fixed;local frames=0
Run:BindToRenderStep('__Stage3GroundCamera',Enum.RenderPriority.Last.Value+2,function()frames+=1;if locked then workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable;workspace.CurrentCamera.CFrame=fixed end end)
f.OnInvoke=function(action,value)
 local r=workspace.Enemies['Owner_'..p.UserId].Stage03_Enemy.TungTungSahurRig
 if action=='Ground'then require(game.ReplicatedStorage.Modules.Stage03GroundContact).Enabled=value
 elseif action=='Camera'then local center=r.HumanoidRootPart.Position+Vector3.new(0,-1,0);fixed=CFrame.lookAt(center+Vector3.new(17,-2,-23),center);locked=true
 elseif action=='Side'then local center=r.HumanoidRootPart.Position+Vector3.new(0,-2,0);fixed=CFrame.lookAt(center+Vector3.new(19,-1,-5),center);locked=true
 elseif action=='Phase'then for _,t in r.Humanoid.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(0);t.TimePosition=t.Animation.AnimationId:find('165623')and value or 0 end
 elseif action=='Run'then for _,t in r.Humanoid.Animator:GetPlayingAnimationTracks()do t:AdjustSpeed(t.Animation.AnimationId:find('165623')and .6 or 1)end
 elseif action=='HUD'then for _,g in p.PlayerGui:GetChildren()do if g:IsA('ScreenGui')then g.Enabled=value end end end
 local ts={};for _,t in r.Humanoid.Animator:GetPlayingAnimationTracks()do table.insert(ts,{Id=t.Animation.AnimationId,Speed=t.Speed,Length=t.Length,Time=t.TimePosition,Priority=t.Priority.Name})end
 return {Frames=frames,Root=tostring(r.HumanoidRootPart.Position),Camera=tostring(workspace.CurrentCamera.CFrame),Tracks=ts}
end
