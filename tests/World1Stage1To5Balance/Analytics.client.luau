-- Prepared-stat analytics probe; all combat/Back/Trophy inputs use normal paths.
local RS=game.ReplicatedStorage;local p=game.Players.LocalPlayer
local q=RS:WaitForChild("__W1BalanceBoundary")
local remote=q:WaitForChild("AnalyticsCall");local ready=q:WaitForChild("AnalyticsReady")
local C=require(RS.Config.World1BossConfig)
local defeated,gauges={},{};local tap=false
RS.Remotes.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if typeof(d)~="table"or d.OwnerUserId and d.OwnerUserId~=p.UserId then return end
 if d.Type=="Initialize"then defeated=table.clone(d.Cleared or{});gauges=table.clone(d.Gauges or{})end
 if d.Type=="BossGauge"or d.Type=="BossInitialize"then gauges[d.Stage]=d.Current end
 if d.Type=="EnemyDefeated"then defeated[d.Stage]=true end
end)
local function root()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end
local function hum()return p.Character and p.Character:FindFirstChildOfClass("Humanoid")end
local function alive()return hum()and hum().Health>0 and root()end
local function lobby()
 local r=root();if not r then return false end
 local f=workspace.GeneratedMap.TrainingArea.Floor;local v=f.CFrame:PointToObjectSpace(r.Position)
 return math.abs(v.X)<f.Size.X/2 and math.abs(v.Z)<f.Size.Z/2
end
local function waitFor(fn,t)
 local stop=os.clock()+(t or 30)
 repeat local v=fn();if v then return v end;task.wait(.025)until os.clock()>stop
 error("Analytics client timeout")
end
task.spawn(function()while true do if tap and alive()then RS.Remotes.AutoTapRequest:FireServer("Tap")end;task.wait(.25)end end)
local function move(target,done)
 local untilTime=os.clock()+90
 repeat
  assert(alive(),"Unexpected death while approaching")
  if done()then hum():MoveTo(root().Position);return end
  hum():MoveTo(Vector3.new(target.X,root().Position.Y,target.Z));task.wait(.05)
 until os.clock()>untilTime
 error("Analytics movement timeout")
end
local function battle(goal,win)
 waitFor(function()return alive()and not root().Anchored end)
 tap=true
 for stage=1,goal do if not defeated[stage]then
  local map=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)]
  for i=1,4 do if(p:GetAttribute("Stage"..stage.."SubStage")or 1)<=i then
   move(map[("Stage%d.%d"):format(stage,i)].Wall.Position+Vector3.new(0,0,4),function()return(p:GetAttribute("Stage"..stage.."SubStage")or 1)>i end)
  end end
  local limit=os.clock()+30
  while not defeated[stage]and not(stage==goal and not win and gauges[stage]and gauges[stage]<C.GetMaxHP(stage))do
   assert(alive(),"Unexpected death during player attacks")
   local owner=workspace.Enemies:FindFirstChild("Owner_"..p.UserId)
   local actor=owner and owner:FindFirstChild(("Stage%02d_Enemy"):format(stage))
   local target=actor and actor:FindFirstChild("HumanoidRootPart")
   if target then hum():MoveTo(Vector3.new(target.Position.X,root().Position.Y,target.Position.Z))end
   assert(os.clock()<limit,"Analytics Boss timeout");task.wait(.025)
  end
 end end
 tap=false;hum():MoveTo(root().Position)
 return {HP=gauges[goal],Defeated=defeated[goal]==true,Health=hum().Health,Strength=p:GetAttribute("Strength")}
end
remote.OnClientInvoke=function(action,value)
 local ok,result=xpcall(function()
  if action=="Ready"then return {Auto=p:GetAttribute("AutoTapEnabled"),Session=p:GetAttribute("MTFSession")}end
  if action=="Damage"then return battle(value,false)end
  if action=="Defeat"then return battle(value,true)end
  if action=="Back"then
   local id=p:GetAttribute("RunInventoryId")
   for _=1,8 do RS.Remotes.RunReturn:FireServer(id)end
   waitFor(function()return alive()and lobby()and not root().Anchored and p:GetAttribute("RunInventoryId")~=id end)
   return {RunChanged=true,Health=hum().Health}
  end
  if action=="Death"then
   local c=p.Character;local h=hum()
   waitFor(function()return h.Health<=0 end,12)
   waitFor(function()return p.Character~=c and alive()and lobby()and not root().Anchored end,25)
   return {OldHealth=h.Health,NewHealth=hum().Health,CharacterChanged=p.Character~=c}
  end
  if action=="Trophy"then
   local stage=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(value)]
   move(stage.TrophyNormalButton.Handle.Position,function()return lobby()end)
   waitFor(function()return not root().Anchored end)
   return true
  end
  if action=="Auto"then
   if p:GetAttribute("AutoTapEnabled")~=value then RS.Remotes.AutoTapRequest:FireServer("Toggle")end
   task.wait(.3);return p:GetAttribute("AutoTapEnabled")
  end
  error("Unknown analytics action")
 end,debug.traceback)
 tap=false
 return {OK=ok,Value=result}
end
ready:FireServer()
