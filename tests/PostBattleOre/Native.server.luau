-- Prepared native Play, memory persistence only. Never install in a published server.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local RS=game.ReplicatedStorage;local q=RS.__PostOreQA
local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService);local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local B=require(game.ServerScriptService.World.BossCombatService)
local R=require(S.RunReturnService);local F=require(S.ForgeService)
local T=require(S.FirstPlayAnalyticsTransport);local Memory=require(RS.__FirstBattleMemory)
local function p()return assert(game.Players:GetPlayers()[1])end
local function inspect()
 local player=p();local s=D.Get(player);local d=s and s.Data;local rows={}
 for _,e in T.StudioRecords()do
  if e.Name=='MTF_FirstOreMerge_v1' or e.Kind=='Custom' and string.find(e.Fields.CustomField03,'PostFirstBattle',1,true) then
   table.insert(rows,{Kind=e.Kind,Name=e.Name,Step=e.Step,StepName=e.StepName,Fields=e.Fields,Value=e.Value})
  end
 end
 local c=player.Character;local boss=B.Get(player)
 return{Rows=rows,New=player:GetAttribute('MTFNewFirstSession'),Facts=d and d.FirstBattleTutorial,
  Ore=d and d.OreMergeTutorial.Completed,Ores=d and d.OwnedOres,Loaded=s and s.Loaded,Pending=s and s.PendingItemMutation~=nil,
  Level=d and d.Level,Strength=d and d.Strength,Stage=player:GetAttribute('CurrentStage'),Fighting=player:GetAttribute('IsFighting'),
  Health=c and c:FindFirstChildOfClass('Humanoid')and c.Humanoid.Health,Anchored=c and c.HumanoidRootPart.Anchored,
  BossHP=boss and boss.HP,Position=c and tostring(c:GetPivot().Position)}
end
local call=Instance.new('BindableFunction');call.Name='Server';call.Parent=q
call.OnInvoke=function(action,value)
 local player=p();local s=D.Get(player)
 if action=='PrepareBoss'then
  assert(s and s.Loaded and player:GetAttribute('MTFNewFirstSession')==true)
  assert(not s.Data.FirstBattleTutorial.FirstOutcome)
  s.Data.Level=4;s.Data.Strength=40;player:SetAttribute('Level',4);player:SetAttribute('Strength',40)
  D.SetAutoTapEnabled(player,false);W.ApplyDamageForStage(player,1,10000);E.SendState(player)
  local boss=assert(E.GetEnemy(1,player));local r=boss.HumanoidRootPart;local c=player.Character
  local at=Vector3.new(r.Position.X,c.HumanoidRootPart.Position.Y,r.Position.Z-2)
  c:PivotTo(CFrame.lookAt(at,at+Vector3.new(0,0,1)));c.HumanoidRootPart.Anchored=true
 elseif action=='ReleaseFixtureAnchor'then player.Character.HumanoidRootPart.Anchored=false
 elseif action=='Tap'then E.TryManualAttack(player)
 elseif action=='Back'then return {Result=table.pack(R.Request(player,player:GetAttribute('RunInventoryId'))),State=inspect()}
 elseif action=='Stage2' then
  local c=player.Character;local wall=workspace.GeneratedMap.BattleCorridor.Stage02['Stage2.1'].Wall
  local at=Vector3.new(wall.Position.X,c.HumanoidRootPart.Position.Y,wall.Position.Z-4)
  c:PivotTo(CFrame.lookAt(at,at+Vector3.new(0,0,1)))
 elseif action=='Fault' then
  Memory.TargetKey='Player_'..player.UserId
  Memory.HoldWrites=value=='Hold';Memory.FailBefore=value=='Fail'and 100 or 0
 elseif action=='Resolve'then D.ResolveItemMutation(player)
 elseif action=='FailAnalytics'then T.StudioFailNext(1)
 elseif action~='Inspect'then error('Unknown action')end
 return inspect()
end
