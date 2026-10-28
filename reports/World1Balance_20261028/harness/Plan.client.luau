-- QA: wait for an observed training goal, then ordinary movement. No stat writes.
local p=game.Players.LocalPlayer;local c=p.PlayerScripts:WaitForChild('__NightControl')
local route=p.PlayerScripts:WaitForChild('__BalanceRoute')
local b=Instance.new('BindableFunction');b.Name='__BalancePlan';b.Parent=p.PlayerScripts
local token=0
b.OnInvoke=function(a)
 token+=1;local own=token
 task.spawn(function()
  local function alive()return own==token and p.Character and p.Character.Humanoid.Health>0 end
  local function go(v)
   c:Invoke('Move',v)
   local untilTime=os.clock()+20
   repeat task.wait(.1)until not alive()or (Vector3.new(p.Character.HumanoidRootPart.Position.X,0,p.Character.HumanoidRootPart.Position.Z)-Vector3.new(v[1],0,v[3])).Magnitude<2 or os.clock()>untilTime
  end
  go({287.8,7.3,-42.6});if not alive()then return end
  go(a.Trainer);if not alive()then return end
  c:Invoke('Phase',{Phase='training',Reason=a.Reason..'; target '..a.Strength})
  repeat task.wait(.1)until not alive()or (p:GetAttribute('Strength')or 0)>=a.Strength
  if not alive()then return end
  c:Invoke('Phase',{Phase='movement',Reason='Actual threshold reached '..tostring(p:GetAttribute('Strength'))..'; route Stage'..a.Goal})
  route:Invoke('Run',{Goal=a.Goal,Laps=1,Dodge=false})
 end)
 return true
end
