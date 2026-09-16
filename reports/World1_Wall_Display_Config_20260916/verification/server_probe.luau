-- Temporary Studio-only Play probe. Removed after verification.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local Boss=require(game.ServerScriptService.World.BossCombatService)
local remote=RS.Remotes.GameRemotes.CombatState
local control=Instance.new("Folder")
control.Name="WallDisplayQAControl"
control.Parent=workspace
local player=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(player) and Data.Get(player).Loaded and Enemy.IsReady()
local function sendWall(stage,index,current,max)
 remote:FireClient(player,{Type="WallGauge",MajorStage=stage,Index=index,Current=current,Max=max})
end
control:GetAttributeChangedSignal("Action"):Connect(function()
 local action=control:GetAttribute("Action")
 local ok,result=pcall(function()
  if action=="damage1" then
   local cleared,nextIndex=Wall.ApplyDamageForStage(player,1,25)
   local snapshot=Wall.GetSnapshotForStage(player,1)
   sendWall(1,snapshot.Current,snapshot.Gauges[snapshot.Current],snapshot.Maxes[snapshot.Current])
   return {cleared=cleared,nextIndex=nextIndex,snapshot=snapshot}
  elseif action=="carry1" then
   local cleared,nextIndex=Wall.ApplyDamageForStage(player,1,100)
   local snapshot=Wall.GetSnapshotForStage(player,1)
   remote:FireClient(player,{Type="WallCleared",MajorStage=1,Index=1,Next=nextIndex,NextMax=snapshot.Maxes[nextIndex],State=snapshot})
   return {cleared=cleared,nextIndex=nextIndex,snapshot=snapshot}
  elseif action=="stage6" or action=="stage10" then
   local stage=tonumber(action:match("%d+"))
   Enemy.StartRun(player,stage)
   local snapshot=Wall.GetSnapshotForStage(player,stage)
   remote:FireClient(player,{Type="WallInitialize",State=snapshot})
   return {stage=stage,snapshot=snapshot}
  elseif action=="boss1" then
   Enemy.StartRun(player,1)
   Wall.ApplyDamageForStage(player,1,1e15)
   local snapshot=Wall.GetSnapshotForStage(player,1)
   remote:FireClient(player,{Type="WallCleared",MajorStage=1,Index=4,Next=snapshot.Current,State=snapshot})
   remote:FireClient(player,{Type="BossRecommendation",Stage=1,Current=Enemy.GetGauge(player,1),Max=Boss.GetStageConfig(1).MaxHP,RecommendedLevel=Boss.GetStageConfig(1).RecommendedLevel})
   return {snapshot=snapshot,bossCurrent=Enemy.GetGauge(player,1),bossMax=Boss.GetStageConfig(1).MaxHP}
  end
  error("unknown action")
 end)
 control:SetAttribute("Result",Http:JSONEncode({action=action,ok=ok,result=ok and result or nil,error=not ok and tostring(result) or nil}))
end)
control:SetAttribute("Ready",true)
