-- Temporary isolated fixture; never publish.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local D=require(game.ServerScriptService.Services.PlayerDataService)
local R=require(game.ServerScriptService.Services.RunReturnService)
local f=Instance.new('BindableFunction');f.Name='Server';f.Parent=game.ReplicatedStorage.__Stage2MotionQA
f.OnInvoke=function(action)
 local p=game.Players:GetPlayers()[1];local s=D.Get(p);assert(s and s.Loaded)
 if action=='Unlock'then s.Data.Strength=360;s.Data.Level=8;p:SetAttribute('Strength',360);p:SetAttribute('Level',8);E.StartRun(p,2);W.ApplyDamageForStage(p,2,10000);E.SendState(p)
 elseif action=='Battle'then local e=E.GetEnemy(2,p);p.Character:PivotTo(CFrame.new(e.HumanoidRootPart.Position+Vector3.new(0,0,-5)));p.Character.HumanoidRootPart.Anchored=true
 elseif action=='Tap'then E.TryManualAttack(p)
 elseif action=='Back'then p.Character.HumanoidRootPart.Anchored=false;return R.Request(p,p:GetAttribute('RunInventoryId'))end
 local e=E.GetEnemy(2,p);return {HP=e and e:GetAttribute('BossMaxHP'),Gauge=E.GetGauge(p,2),Fighting=p:GetAttribute('IsFighting'),Stage=p:GetAttribute('CurrentStage')}
end
