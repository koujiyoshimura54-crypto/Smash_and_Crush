-- QA ordinary physics route and optional arena dodging. No progression services.
local p=game.Players.LocalPlayer
local c=p.PlayerScripts:WaitForChild('__NightControl')
local b=Instance.new('BindableFunction');b.Name='__BalanceRoute';b.Parent=p.PlayerScripts
local running=0
local z={165.875,283.86,404.62,528.695,656.52,826.87,1049.87,1257.87,1420.87,1595.42}
local function move(x,y,d)c:Invoke('Move',{x,y,d})end
local function healthy()local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 end
b.OnInvoke=function(op,arg)
 running+=1;local own=running
 if op=='Stop'then c:Invoke('StopMove');return true end
 task.spawn(function()
  for lap=1,arg.Laps or 1 do
   if not healthy()or running~=own then return end
   c:Invoke('Phase',{Phase='movement',Reason='Ordinary route target '..arg.Goal..'; dodge '..tostring(arg.Dodge)})
   if (p:GetAttribute('CurrentStage')or 1)==1 and p.Character.HumanoidRootPart.Position.Z<50 then
    move(287.8,7.3,-42.6);task.wait(2)
    move(287.8,7.3,13);task.wait(2.5)
   end
   local last=0;local angle=0;local nextPoint=0;local nextJump=0
   while running==own and healthy()do
    local stage=p:GetAttribute('CurrentStage')or 1;if stage>arg.Goal then break end
    local root=p.Character.HumanoidRootPart
    if stage~=last then move(287.8,7.3,z[stage]);last=stage;nextPoint=0 end
    if arg.Dodge and p:GetAttribute('IsFighting')and root.Position.Z>z[stage]-16 and os.clock()>nextPoint then
     angle+=math.pi/6
     move(287.8+28*math.cos(angle),7.3,z[stage]+28*math.sin(angle))
     nextPoint=os.clock()+.58
    end
    if arg.Jump and p:GetAttribute('IsFighting')and root.Position.Z>z[stage]-16 and os.clock()>nextJump then p.Character.Humanoid.Jump=true;nextJump=os.clock()+.7 end
    task.wait(.1)
   end
   if running~=own or not healthy()then c:Invoke('StopMove');return end
   if arg.Goal>=10 then c:Invoke('StopMove');return end
   move(255.12,4.18,z[arg.Goal])
   local deadline=os.clock()+30
   repeat task.wait(.1)until running~=own or not healthy()or (p:GetAttribute('CurrentStage')or 1)==1 or os.clock()>deadline
   c:Invoke('StopMove')
   if running~=own or not healthy()or (p:GetAttribute('CurrentStage')or 1)~=1 then return end
   task.wait(.5)
  end
 end)
 return true
end
