-- Single-stage ordinary movement evasion, uses existing Auto. No combat calls.
local p=game.Players.LocalPlayer;local ps=p.PlayerScripts;local stage=10
local control=ps.__OneControl;local measure=game.ReplicatedStorage.__OneMeasure
local active=false;local ended=false
local floor=workspace.GeneratedMap.BattleCorridor[string.format('Stage%02d',stage)].Floor
local rx,rz=floor.Size.X/2-6,floor.Size.Z/2-6;local points={Vector3.new(-rx,5,-rz),Vector3.new(rx,5,-rz),Vector3.new(rx,5,rz),Vector3.new(-rx,5,rz)}
for i,x in points do points[i]=floor.CFrame:PointToWorldSpace(x)end
local con
local finish=measure.OnClientEvent:Connect(function(op)if op=='Finished'then ended=true;control:Invoke('StopMove')end end)
local function run()
 if active or ended then return end;active=true
 task.spawn(function()
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  local owner=workspace.Enemies:FindFirstChild('Owner_'..p.UserId)
  local enemy=owner and owner:FindFirstChild(string.format('Stage%02d_Enemy',stage))
  if not h or not root or not enemy then script:SetAttribute('State','Missing actual encounter');return end
  local index,best=1,-math.huge
  for i,x in points do local score=(x-enemy:GetPivot().Position).Magnitude-(x-root.Position).Magnitude*.5;if score>best then best=score;index=i end end
  local direction=index%2==1 and -1 or 1;local lastMove,lastSample=0,0;local lastJumpCycle=-1;local start=os.clock()

  local lastHP=h.Health;local nextJump
  local hpCon=h.HealthChanged:Connect(function(value)
   if stage==10 and value<lastHP and value>0 then nextJump=os.clock()+.68;measure:FireServer('ClientEvent',{Type='JumpCalibration',Stage=stage,Health=value,Delay=.68})end
   lastHP=value
  end)
  if stage==10 then task.spawn(function()
   while script.Parent and not ended and h.Health>0 and p:GetAttribute('CurrentStage')==stage do
    if nextJump and os.clock()>=nextJump then control:Invoke('Jump');nextJump+=1 end
    task.wait(.03)
   end
  end)end
  script:SetAttribute('State','Kiting actual Boss')
  while script.Parent and not ended and h.Health>0 and p:GetAttribute('CurrentStage')==stage and enemy.Parent and os.clock()-start<120 do
   local goal=points[index]
   if (Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(goal.X,0,goal.Z)).Magnitude<3 then index=(index-1+direction)%#points+1;lastMove=0;goal=points[index]end
   if os.clock()-lastMove>6 then control:Invoke('Move',{X=goal.X,Y=goal.Y,Z=goal.Z,Reason='Ordinary in-arena evasion Stage'..stage..' corner'..index});lastMove=os.clock()end
   if os.clock()-lastSample>1 then
    local ep=enemy:GetPivot().Position
    measure:FireServer('ClientEvent',{Type='KiteObservation',Stage=stage,Health=h.Health,Position={root.Position.X,root.Position.Y,root.Position.Z},EnemyPosition={ep.X,ep.Y,ep.Z},Elapsed=os.clock()-start})
    lastSample=os.clock()
   end
   task.wait(.15)
  end
  ended=true;active=false;script:SetAttribute('State',h.Health<=0 and'Died'or'Ended after Stage/encounter changed')
  if p:GetAttribute('CurrentStage')==stage then control:Invoke('StopMove')end
  if con then con:Disconnect()end
  finish:Disconnect();hpCon:Disconnect()
 end)
end
con=game.ReplicatedStorage.Remotes.GameRemotes.CombatState.OnClientEvent:Connect(function(data)
 if type(data)=='table'and data.Stage==stage then
  if data.Type=='BossInitialize'then run()end
  if data.Type=='BossInitialize'or data.Type=='BossGauge'or data.Type=='BossResult'then measure:FireServer('ClientEvent',{Type='ObservedCombat',Data=data})end
 end
end)
script:SetAttribute('State','Waiting for actual BossInitialize')
