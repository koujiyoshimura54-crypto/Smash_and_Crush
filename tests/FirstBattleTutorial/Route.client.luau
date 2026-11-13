-- Natural earned progression with programmatic ordinary movement/attack/Forge remotes.
-- No LV/Strength grants, forced outcomes, warps, or time-reward waiting.
local RS=game.ReplicatedStorage;local q=RS:WaitForChild('__FirstBattleQA')
local p=game.Players.LocalPlayer;local rem=RS:WaitForChild('Remotes')
local Forge=require(RS.Modules.ForgeClient)
local active,tapping=false,false
local tapInterval=.25
local encounterLabel='First'
local function report(name,details) q.Report:FireServer(name,details) end
rem:WaitForChild('GameRemotes'):WaitForChild('CombatState').OnClientEvent:Connect(function(d)
 if d.Type=='Fighting' and d.Active==true and d.CombatType=='MiniBoss' and d.Stage==1 then
  report(encounterLabel..'BossStarted')
 end
end)
local function root()return p.Character and p.Character:FindFirstChild('HumanoidRootPart')end
local function hum()return p.Character and p.Character:FindFirstChildOfClass('Humanoid')end
local function alive()return root() and hum() and hum().Health>0 end
local function waitFor(fn,timeout,label)
 local deadline=os.clock()+timeout
 repeat local value=fn();if value then return value end;task.wait(.05)until os.clock()>deadline
 error(label or 'Route timeout')
end
local function lobby()
 if not root()then return false end
 local f=workspace.GeneratedMap.TrainingArea.Floor;local v=f.CFrame:PointToObjectSpace(root().Position)
 return math.abs(v.X)<f.Size.X/2 and math.abs(v.Z)<f.Size.Z/2
end
local function move(target,done,timeout)
 local stop=os.clock()+(timeout or 90)
 repeat
  assert(alive(),'DEATH')
  if done and done() or not done and (Vector3.new(root().Position.X,0,root().Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude<2 then hum():MoveTo(root().Position);return end
  hum():MoveTo(Vector3.new(target.X,root().Position.Y,target.Z))
  assert(os.clock()<stop,'Movement timeout '..tostring(target))
  task.wait(.1)
 until not active
end
task.spawn(function()while true do
 -- Follow the guide: click during established combat, not while approaching on foot.
 if active and tapping and alive() and p:GetAttribute('IsFighting')==true then rem.AutoTapRequest:FireServer('Tap')end
 task.wait(tapInterval)
end end)
local function train(level)
 if (p:GetAttribute('Level')or 0)>=level then return end
 report('TrainStart',{Goal=level})
 local area=workspace.Treadmills.Normal01.Area
 move(area.Position,function()
  return p:GetAttribute('Level')>=level or p:GetAttribute('IsTraining')==true
 end,90)
 if p:GetAttribute('Level')<level then
  waitFor(function()return p:GetAttribute('IsTraining')==true end,20,'Treadmill not entered')
  report('TreadmillEntered')
  waitFor(function()return p:GetAttribute('Level')>=level end,240,'Training timeout')
 end
 report('TrainEnd',{Goal=level})
 -- Walk off the deck using its actual footprint before moving toward battle.
 if p:GetAttribute('IsTraining')==true then
  local toward=workspace.GeneratedMap.TrainingArea.Floor.Position-area.Position
  move(area.Position+Vector3.new(toward.X,0,toward.Z).Unit*(math.max(area.Size.X,area.Size.Z)/2+7))
 end
end
local function fight(label)
 encounterLabel=label
 report(label..'Approach');tapping=true
 local stage=workspace.GeneratedMap.BattleCorridor.Stage01
 local wall=stage['Stage1.1'].Wall
 move(wall.Position+Vector3.new(0,0,5),function()return(p:GetAttribute('Stage1SubStage')or 1)>1 end,120)
 report(label..'WallDestroyed')
 local stop=os.clock()+100
 repeat
  assert(alive(),'DEATH')
  if p:GetAttribute('CurrentStage')~=1 then tapping=false;report(label..'Victory');return end
  local enemies=workspace:FindFirstChild('Enemies');local owner=enemies and enemies:FindFirstChild('Owner_'..p.UserId)
  local boss=owner and owner:FindFirstChild('Stage01_Enemy');local r=boss and boss:FindFirstChild('HumanoidRootPart')
  local pos=r and r.Position or stage['Stage1.5'].EnemySpawn.Position
  hum():MoveTo(Vector3.new(pos.X,root().Position.Y,pos.Z))
  assert(os.clock()<stop,'Boss timeout');task.wait(.1)
 until not active
end
local function returnAfterFight(ok,label)
 tapping=false
 if not ok then
  assert(not alive(),'Unexpected route error')
  report(label..'Death')
  waitFor(function()return alive()and lobby()and not root().Anchored end,45,'Respawn timeout')
 else
  report('TrophyApproach')
  local pad=workspace.GeneratedMap.BattleCorridor.Stage01.TrophyNormalButton.Handle
  move(pad.Position,lobby,60)
  waitFor(function()return not root().Anchored end,15)
 end
 report(label..'LobbyReturn')
end
local function merge()
 report('MergeApproach');move(workspace.RestockShop.Area.Position,nil,60)
 waitFor(function()
  local gui=p.PlayerGui:FindFirstChild('MergeShopGui');local panel=gui and gui:FindFirstChild('MergeShopPanel')
  return panel and panel.Visible
 end,15,'Shop did not open')
 report('MergeShopOpened');Forge.Refresh()
 waitFor(function()return Forge.State and Forge.State.Loaded and not Forge.State.Pending end,15)
 assert(Forge.Request('MergeOre',{Materials={ORE_001=2}}))
 waitFor(function()return p:GetAttribute('OreTutorialCompleted')==true and not Forge.IsPending()end,30,'Merge not committed')
 report('MergeCommitted',Forge.State.Journal)
 report('WaitingRevealClicks')
 local hatch=require(p.PlayerScripts.Services.HatchClient)
 task.wait(.5)
 local nextPress=0
 waitFor(function()
  if hatch.playing() and hatch.__FirstBattlePress and os.clock()>=nextPress then nextPress=os.clock()+.4;hatch.__FirstBattlePress() end
  return not hatch.playing()
 end,150,'Reveal awaiting ordinary clicks')
 report('RevealFinished')
 rem.DumbbellEquipRequest:FireServer('__BestEquip',nil,p:GetAttribute('ForgeSessionToken'))
 waitFor(function()return p:GetAttribute('DumbbellEquipTutorialInitialCompleted')==true end,15,'Equip timeout')
 report('DumbbellEquipped',p:GetAttribute('EquippedDumbbell'))
end
local call=Instance.new('BindableFunction');call.Name='Route';call.Parent=q
call.OnInvoke=function(mode)
 assert(not active,'Route already active');active=true
 task.spawn(function()
  local ok,err=xpcall(function()
   waitFor(function()return alive()and p:GetAttribute('FirstBattleTutorialEligible')==true and p.Character:GetAttribute('LobbySpawnPlaced')and not root().Anchored end,45)
   local initial=q.State:InvokeServer();assert(initial.Level==1 and initial.Strength==0,'Natural route must start fresh')
   assert(initial.Auto==false and initial.Ores.ORE_001==2)
   tapInterval=mode=='SlowFirst' and 1.5 or .25
   report('Operable',{Mode=mode,FirstTapInterval=tapInterval,RetryTapInterval=.25})
   if mode=='EarlyMerge' then merge()end
   train(mode=='WinFirst' and 4 or 2)
   local won,why=pcall(fight,'First');if not won and alive()then error(why)end
   returnAfterFight(won,'First')
   tapInterval=.25
   if mode~='EarlyMerge'then merge()end
   if p:GetAttribute('FirstBattleStage1Defeated')~=true then
    train(4)
    local retry,reason=pcall(fight,'Retry');if not retry and alive()then error(reason)end
    returnAfterFight(retry,'Retry')
   end
   report('Complete',{Stage1Defeated=p:GetAttribute('FirstBattleStage1Defeated')})
  end,debug.traceback)
  active=false;tapping=false
  if not ok then report('Failed',err)end
 end)
 return 'Started '..mode
end
if q:GetAttribute('NaturalMode') then task.defer(function()call:Invoke(q:GetAttribute('NaturalMode'))end)end
