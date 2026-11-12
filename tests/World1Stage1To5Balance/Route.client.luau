-- Native ordinary-route driver. Only normal remotes and Humanoid:MoveTo; no grants or teleports.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage
local p=Players.LocalPlayer;local qa=RS:WaitForChild("__W1BalanceRoute");local rem=RS:WaitForChild("Remotes")
local Forge=require(RS.Modules.ForgeClient)
local info;repeat info=qa.State:InvokeServer("Hello");if info.Waiting then task.wait(.2)end until not info.Waiting
local mode=info.Mode;local active,tap=true,false;local defeated={};local deaths=0;local firstMerge=false
local function report(kind,details)qa.Report:FireServer(kind,details)end
local function root()return p.Character and p.Character:FindFirstChild("HumanoidRootPart")end
local function hum()return p.Character and p.Character:FindFirstChildOfClass("Humanoid")end
local function alive()return hum()and hum().Health>0 and root()end
local function lobby()
 local r=root();if not r then return false end
 local f=workspace.GeneratedMap.TrainingArea.Floor;local v=f.CFrame:PointToObjectSpace(r.Position)
 return math.abs(v.X)<f.Size.X/2 and math.abs(v.Z)<f.Size.Z/2
end
local function bind(c)local h=c:WaitForChild("Humanoid");h.Died:Connect(function()deaths+=1;report("Death",{Count=deaths})end)end
p.CharacterAdded:Connect(bind);if p.Character then bind(p.Character)end
rem.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if typeof(d)~="table"or d.OwnerUserId and d.OwnerUserId~=p.UserId then return end
 if d.Type=="Initialize"then defeated=table.clone(d.Cleared or{})end
 if d.Type=="EnemyDefeated"then defeated[d.Stage]=true;report("BossDefeated"..d.Stage,{Generation=d.SpawnGeneration})end
 if d.Type=="TrophySpawn"then report("TrophySpawn"..tostring(d.Stage))end
end)
local function auto(value)
 if (p:GetAttribute("AutoTapEnabled")~=false)~=value then rem.AutoTapRequest:FireServer("Toggle");task.wait(.2)end
end
while workspace:GetServerTimeNow()<info.StartAt do task.wait()end
report("Operable",{Mode=mode,InitialAuto=p:GetAttribute("AutoTapEnabled"),Policy="CurrentRecommendedLV; normal Rebirth between expeditions; +25% Strength per death retry"})
assert(p:GetAttribute("AutoTapEnabled")==false,"initial Auto must be OFF")
auto(mode~="Manual")
task.spawn(function()while active do if tap and alive()and mode~="Auto"then rem.AutoTapRequest:FireServer("Tap")end;task.wait(mode=="Manual"and .25 or .9)end end)
local claimed={}
task.spawn(function()
 while active do
  local ok,s=pcall(function()return rem.TimeRewardState:InvokeServer()end)
  if ok and s.Loaded then for _,id in {"StoneIntro01","IronIntro01","Reward03"}do if s.States[id]=="Ready"then rem.TimeRewardClaim:FireServer(id);task.wait(.25)end end end
  task.wait(.4)
 end
end)
rem.TimeRewardClaim.OnClientEvent:Connect(function(r)if r.Success and not claimed[r.RewardId]then claimed[r.RewardId]=true;report("TimeReward",r.RewardId)end end)
local function move(target,done,timeout)
 local start=os.clock();local nextMove=0
 while active do
  assert(alive(),"DEATH")
  if done and done()then hum():MoveTo(root().Position);return end
  if not done and (Vector3.new(root().Position.X,0,root().Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude<2.5 then return end
  assert(os.clock()-start<(timeout or 60),"movement timeout: "..tostring(target).." at "..tostring(root().Position))
  if os.clock()>=nextMove then hum():MoveTo(Vector3.new(target.X,root().Position.Y,target.Z));nextMove=os.clock()+.35 end
  task.wait(.05)
 end
end
local function maybeMerge()
 local s=Forge.Refresh();if not s or not s.Loaded or s.Pending or not lobby()then return end
 local equipped=s.EquippedDumbbell or "";local material
 if (s.Ores.ORE_003 or 0)>=2 and(equipped==""or equipped=="NORMAL_01")then material="ORE_003"
 elseif(s.Ores.ORE_001 or 0)>=2 and equipped==""then material="ORE_001"end
 if not material then return end
 tap=false;report("MergeStart",{Material=material})
 move(workspace.RestockShop.Area.Position,nil,35);hum():MoveTo(root().Position)
 local stop=os.clock()+10;repeat task.wait(.1)until p.PlayerGui:FindFirstChild("MergeShopGui")or os.clock()>stop
 Forge.Refresh();assert(Forge.Request("MergeOre",{Materials={[material]=2}}))
 stop=os.clock()+30;repeat task.wait(.1)until not Forge.IsPending()or os.clock()>stop
 assert(not Forge.IsPending(),"merge timeout")
 local result=Forge.State and Forge.State.Journal;assert(result and result.ResultId,"merge result missing")
 report(firstMerge and"HigherMerge"or"FirstMerge",{Material=material,Result=result.ResultId});firstMerge=true
 task.wait(.2);stop=os.clock()+20;local hatch=require(p.PlayerScripts.Services.HatchClient)
 while hatch.playing()and os.clock()<stop do hatch.__W1BalancePress();task.wait(.4)end
 assert(not hatch.playing(),"hatch timeout")
 rem.DumbbellEquipRequest:FireServer("__BestEquip",nil,p:GetAttribute("ForgeSessionToken"))
 stop=os.clock()+5;repeat task.wait(.1)until(p:GetAttribute("EquippedDumbbell")or"")~=""or os.clock()>stop
 report("DumbbellEquipped",p:GetAttribute("EquippedDumbbell"));report("MergeEnd")
end
local function train(level,strength)
 report("TrainStart",{TargetLevel=level,MinimumStrength=strength})
 local target;local flip=false;local mergeAt=0;local started=os.clock()
 while(p:GetAttribute("Level")or 1)<level or(p:GetAttribute("Strength")or 0)<(strength or 0)do
  assert(alive(),"DEATH");assert(os.clock()-started<1800,"training timeout")
  if os.clock()>=mergeAt then maybeMerge();mergeAt=os.clock()+3 end
  tap=true
  if not target or(Vector3.new(root().Position.X,0,root().Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude<3 then
   flip=not flip;local f=workspace.GeneratedMap.TrainingArea.Floor
   target=Vector3.new(f.Position.X+(flip and 18 or -2),root().Position.Y,f.Position.Z-15)
  end
  hum():MoveTo(target);task.wait(.05)
 end
 tap=false;hum():MoveTo(root().Position);report("TrainEnd")
end
local function fight(stage,attempt)
 report("ApproachStage"..stage,{Attempt=attempt});tap=true
 local map=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)]
 for i=1,4 do
  if(p:GetAttribute("Stage"..stage.."SubStage")or 1)<=i then
   local wall=map[("Stage%d.%d"):format(stage,i)].Wall
   move(wall.Position+Vector3.new(0,0,4),function()return(p:GetAttribute("Stage"..stage.."SubStage")or 1)>i end,120)
  end
 end
 local deadline=os.clock()+60
 while not defeated[stage]do
  assert(alive(),"DEATH")
  local enemies=workspace:FindFirstChild("Enemies");local owner=enemies and enemies:FindFirstChild("Owner_"..p.UserId)
  local boss=owner and owner:FindFirstChild(("Stage%02d_Enemy"):format(stage));local target=boss and boss:FindFirstChild("HumanoidRootPart")
  if target then hum():MoveTo(Vector3.new(target.Position.X,root().Position.Y,target.Position.Z))end
  assert(os.clock()<deadline,"boss timeout");task.wait(.05)
 end
 tap=false;hum():MoveTo(root().Position);report("StageFightEnd"..stage,{Attempt=attempt})
end
local function trophy(stage)
 report("TrophyApproach"..stage)
 local pad=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)].TrophyNormalButton.Handle
 move(pad.Position,function()return lobby()end,60)
 repeat task.wait(.05)until not root().Anchored
 report("TrophyReturned"..stage)
end
local function rebirthIfReady()
 local s=qa.State:InvokeServer("State")
 if s.RequiredRebirthLevel and s.Level>=s.RequiredRebirthLevel then
  report("RebirthRequested");local before=p:GetAttribute("RebirthCount")or 0
  rem.RebirthRequest:FireServer("Request")
  local stop=os.clock()+10;repeat task.wait(.1)until(p:GetAttribute("RebirthCount")or 0)>before or os.clock()>stop
  if(p:GetAttribute("RebirthCount")or 0)==before then report("RebirthDeferred",{Reason="busy/pending"});return end
  assert((p:GetAttribute("RebirthCount")or 0)==before+1,"rebirth duplicated")
  report("Rebirth"..(before+1))
 end
end
local ok,err=xpcall(function()
 for goal=1,5 do
  local attempts=0;local minimum=0
  while true do
   attempts+=1;assert(attempts<=5,"five natural attempts failed")
   train(info.Recommended[goal],minimum)
   report("ExpeditionStart",{Goal=goal,Attempt=attempts})
   local passed,why=pcall(function()for stage=1,goal do if not defeated[stage]then fight(stage,attempts)end end end)
   if passed then break end
   if alive()then error(why)end
   tap=false;report("RetryNeeded",{Goal=goal,Attempt=attempts,Error=tostring(why)})
   minimum=math.max(minimum,(p:GetAttribute("Strength")or 0)*1.25)
   local deadline=os.clock()+30;repeat task.wait(.1)until alive()and lobby()and not root().Anchored or os.clock()>deadline
   assert(alive()and lobby(),"respawn timeout");auto(mode~="Manual")
  end
  if goal==5 then
   report("Stage5RouteCompleted")
   local stage=workspace.GeneratedMap.BattleCorridor.Stage06;local wall=stage["Stage6.1"].Wall
   tap=true;report("Stage6FirstWallStart")
   move(wall.Position+Vector3.new(0,0,4),function()return(p:GetAttribute("Stage6SubStage")or 1)>1 end,180)
   tap=false;report("Stage6FirstWallEnd")
  end
  trophy(goal);maybeMerge();rebirthIfReady()
 end
end,debug.traceback)
active=false;tap=false;if hum()then hum():MoveTo(root().Position)end
report(ok and"Complete"or"Failed",{Error=not ok and err or nil,Deaths=deaths})
