-- Programmatic ordinary inputs and Humanoid movement; no stat writes/teleports.
local Players=game:GetService("Players");local RS=game.ReplicatedStorage;local Run=game:GetService("RunService")
local p=Players.LocalPlayer;local qa=RS:WaitForChild("__EarlyQARoute");local rem=RS:WaitForChild("Remotes")
local Forge=require(RS.Modules.ForgeClient);local timeConfig=require(RS.Config.TimeRewardConfig)
local info;repeat info=qa.State:InvokeServer("Hello");if info.Waiting then task.wait(.2)end until not info.Waiting
local mode=info.Mode;local active=true;local tap=false;local defeated={};local start=info.StartAt
local currentStage=1;local deathCount=0
local function report(kind,data)qa.Report:FireServer(kind,data)end
local function root()local c=p.Character;return c and c:FindFirstChild("HumanoidRootPart")end
local function hum()local c=p.Character;return c and c:FindFirstChildOfClass("Humanoid")end
local function state()return qa.State:InvokeServer("State")end
local function alive()return hum()and hum().Health>0 and root()end
local function lobby()
 local f=workspace.GeneratedMap.TrainingArea.Floor;local r=root();if not r then return false end
 local at=f.CFrame:PointToObjectSpace(r.Position);return math.abs(at.X)<f.Size.X/2 and math.abs(at.Z)<f.Size.Z/2
end
rem.GameRemotes.CombatState.OnClientEvent:Connect(function(d)
 if typeof(d)~="table"or d.OwnerUserId and d.OwnerUserId~=p.UserId then return end
 if d.Type=="Initialize"then defeated=table.clone(d.Cleared or{})end
 if d.Type=="EnemyDefeated"then defeated[d.Stage]=true;report("BossDefeated"..d.Stage,{Generation=d.SpawnGeneration})end
 if d.Type=="TrophySpawn"then report("TrophySpawn"..tostring(d.Stage))end
end)
p.CharacterRemoving:Connect(function()deathCount+=1 end)
local function auto(value)
 if (p:GetAttribute("AutoTapEnabled")~=false)~=value then rem.AutoTapRequest:FireServer("Toggle");task.wait(.2)end
end
while workspace:GetServerTimeNow()<start do task.wait()end
auto(mode~="Manual");report("Operable",{ClientReady=workspace:GetServerTimeNow(),Mode=mode})
task.spawn(function()
 while active do
  if tap and alive()and mode~="Auto"then rem.AutoTapRequest:FireServer("Tap")end
  task.wait(mode=="Manual"and .25 or .9)
 end
end)
local claimed={}
task.spawn(function()
 while active do
  local ok,s=pcall(function()return rem.TimeRewardState:InvokeServer()end)
  if ok and s.Loaded then
   for _,id in {"StoneIntro01","IronIntro01","Reward03"}do
    if s.States[id]=="Ready"then rem.TimeRewardClaim:FireServer(id);task.wait(.25)end
   end
  end
  task.wait(.4)
 end
end)
rem.TimeRewardClaim.OnClientEvent:Connect(function(result)
 if result.Success and not claimed[result.RewardId]then claimed[result.RewardId]=true;report("TimeReward",result.RewardId)end
end)
local function move(target,done,timeout)
 local began=os.clock();local lastIssue=0
 while active do
  assert(alive(),"death during movement")
  if done and done()then hum():MoveTo(root().Position);return end
  if not done and (Vector3.new(root().Position.X,0,root().Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude<2.5 then return end
  assert(os.clock()-began<(timeout or 35),"movement timeout: "..tostring(target).." at "..tostring(root().Position))
  if os.clock()-lastIssue>.35 then hum():MoveTo(Vector3.new(target.X,root().Position.Y,target.Z));lastIssue=os.clock()end
  task.wait(.05)
 end
end
local firstMerge=false
local function maybeMerge()
 local s=Forge.Refresh();if not s or not s.Loaded or s.Pending or not lobby()then return end
 local equipped=s.EquippedDumbbell or "";local material
 if (s.Ores.ORE_003 or 0)>=2 and (equipped==""or equipped=="NORMAL_01")then material="ORE_003"
 elseif (s.Ores.ORE_001 or 0)>=2 and equipped==""then material="ORE_001"end
 if not material then return end
 tap=false
 local area=workspace.RestockShop.Area
 move(area.Position,nil,25)
 hum():MoveTo(root().Position)
 local stop=os.clock()+10;repeat task.wait(.1)until p.PlayerGui:FindFirstChild("MergeShopGui")or os.clock()>stop
 Forge.Refresh()
 local view=_G.__FirstAnalyticsMergeView;assert(view,"native Merge view absent")
 view:SelectTab("Ore");task.wait(.4);view:ActivateMaterial(material);view:ActivateMaterial(material);task.wait(.4)
 local snap=require(RS.Modules.FirstPlayAnalyticsClient).Snapshot();snap.Character=nil
 report("VisibleOreSelection",{Snapshot=snap,PanelVisible=view.Root.Visible})
 view:SubmitItem()
 stop=os.clock()+25
 repeat task.wait(.1)until not Forge.IsPending()or os.clock()>stop
 assert(not Forge.IsPending(),"merge timeout")
 local result=Forge.State and Forge.State.Journal
 assert(result and result.ResultId,"merge result missing")
 report(firstMerge and "HigherMerge"or"FirstMerge",{Material=material,Result=result.ResultId})
 firstMerge=true
 task.wait(.2)
 stop=os.clock()+15
 local hatch=require(p.PlayerScripts.Services.HatchClient)
 while hatch.playing()and os.clock()<stop do hatch.__EarlyQAPress();task.wait(.4)end
 assert(not hatch.playing(),"hatch did not finish")
 rem.DumbbellEquipRequest:FireServer(mode=="Manual"and result.ResultId or"__BestEquip",nil,p:GetAttribute("ForgeSessionToken"))
 stop=os.clock()+5
 repeat task.wait(.1)until (p:GetAttribute("EquippedDumbbell")or"")~=""or os.clock()>stop
 report("DumbbellEquipped",p:GetAttribute("EquippedDumbbell"))
end
local function train(target,allowMerge,toLevel)
 report("TrainStart",{Target=target,ToLevel=toLevel})
 local flip=false;local walkTarget;local nextMerge=os.clock()
 while (toLevel and (p:GetAttribute("Level")or 1)<target)or(not toLevel and (p:GetAttribute("Strength")or 0)<target)do
  assert(alive(),"death during training")
  if allowMerge and os.clock()>=nextMerge then maybeMerge();nextMerge=os.clock()+2 end
  tap=true
  if not walkTarget or (Vector3.new(root().Position.X,0,root().Position.Z)-Vector3.new(walkTarget.X,0,walkTarget.Z)).Magnitude<3 then
   flip=not flip
   local f=workspace.GeneratedMap.TrainingArea.Floor
   walkTarget=Vector3.new(f.Position.X+(flip and 18 or -2),root().Position.Y,f.Position.Z-15)
  end
  hum():MoveTo(walkTarget)
  task.wait(.05)
 end
 tap=false;hum():MoveTo(root().Position);report("TrainEnd")
end
local function fight(stage,label)
 currentStage=stage;report(label.."Start")
 tap=true
 local stageModel=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)]
 for i=1,4 do
  local wall=stageModel[("Stage%d.%d"):format(stage,i)].Wall
  if (p:GetAttribute("Stage"..stage.."SubStage")or 1)<=i then
   move(wall.Position+Vector3.new(0,0,4),function()return (p:GetAttribute("Stage"..stage.."SubStage")or 1)>i end,100)
  end
 end
 local deadline=os.clock()+40
 while not defeated[stage]do
  assert(alive(),"death during boss "..stage)
  local enemies=workspace:FindFirstChild("Enemies");local owner=enemies and enemies:FindFirstChild("Owner_"..p.UserId)
  local boss=owner and owner:FindFirstChild(("Stage%02d_Enemy"):format(stage))
  local target=boss and boss:FindFirstChild("HumanoidRootPart")
  if target then hum():MoveTo(Vector3.new(target.Position.X,root().Position.Y,target.Position.Z))end
  assert(os.clock()<deadline,"boss timeout")
  task.wait(.1)
 end
 tap=false;hum():MoveTo(root().Position);report(label.."End")
end
local function trophy(stage)
 report("TrophyApproach"..stage)
 local pad=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(stage)].TrophyNormalButton.Handle
 move(pad.Position,function()return lobby()end,35)
 repeat task.wait(.05)until not root().Anchored
 report("TrophyReturned"..stage)
end
local ok,err=xpcall(function()
 train(info.Targets[1],false)
 fight(1,"FirstStage1");trophy(1)
 local deadline=os.clock()+90
 repeat maybeMerge();task.wait(.4) until firstMerge or os.clock()>deadline
 assert(firstMerge,"normal first merge unavailable")
 task.wait(1)

end,debug.traceback)
active=false;tap=false;if hum()then hum():MoveTo(root().Position)end
report(ok and"Complete"or"Failed",{Error=not ok and err or nil,Deaths=deathCount})
