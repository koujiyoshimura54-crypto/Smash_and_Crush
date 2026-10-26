local p=game.Players.LocalPlayer
local control=p.PlayerScripts:WaitForChild('__NightControl')
local bridge=Instance.new('BindableFunction');bridge.Name='__NightRoute';bridge.Parent=p.PlayerScripts
local token=0
local points={165.875,283.86,404.62,528.695,656.52,826.87,1049.87,1257.87,1420.87,1595.42}
local function move(x,y,z)control:Invoke('Move',{x,y,z})end
bridge.OnInvoke=function(op,arg)
 token+=1;local own=token
 if op=='Stop'then control:Invoke('StopMove');return true end
 assert(op=='Run')
 task.spawn(function()
  for lap=1,arg.Laps do
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if not h or h.Health<=0 then return end
   control:Invoke('Phase',{Phase='movement',Reason='Ordinary route lap '..lap..' target '..arg.Goal})
   local stage=p:GetAttribute('CurrentStage')or 1
   if stage==1 then
    move(287.8,7.3,13)
    local deadline=os.clock()+20
    repeat task.wait(.2)until token~=own or h.Health<=0 or (p.Character.HumanoidRootPart.Position-Vector3.new(287.8,8.3,13)).Magnitude<4 or os.clock()>deadline
   end
   local previous=0
   while token==own and h.Health>0 do
    stage=p:GetAttribute('CurrentStage')or 1
    if stage>arg.Goal then break end
    if stage~=previous then move(287.8,7.3,points[stage]);previous=stage end
    task.wait(.2)
   end
   if token~=own or h.Health<=0 then control:Invoke('StopMove');return end
   move(255.12,4.18,points[arg.Goal])
   local deadline=os.clock()+30
   repeat task.wait(.2)until token~=own or h.Health<=0 or (p:GetAttribute('CurrentStage')or 1)==1 or os.clock()>deadline
   control:Invoke('StopMove')
   if token~=own or h.Health<=0 or (p:GetAttribute('CurrentStage')or 1)~=1 then return end
   task.wait(1)
  end
 end)
 return true
end
