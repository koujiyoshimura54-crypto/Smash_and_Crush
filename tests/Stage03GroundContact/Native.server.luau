-- Temporary isolated Studio fixture; never publish.
assert(game.RunService:IsStudio()and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local E=require(game.ServerScriptService.World.EnemyManager);local W=require(game.ServerScriptService.World.Stage1WallManager);local D=require(game.ServerScriptService.Services.PlayerDataService);local R=require(game.ServerScriptService.Services.RunReturnService)
local f=Instance.new('BindableFunction');f.Name='Server';f.Parent=game.ReplicatedStorage.__Stage3GroundQA
f.OnInvoke=function(action)
 local p=game.Players:GetPlayers()[1];local s=D.Get(p);assert(s and s.Loaded)
 if action=='Unlock'then s.Data.Strength=2000;s.Data.Level=15;p:SetAttribute('Strength',2000);p:SetAttribute('Level',15);E.StartRun(p,3);W.ApplyDamageForStage(p,3,100000);E.SendState(p)
 elseif action=='Battle'then local e=E.GetEnemy(3,p);p.Character:PivotTo(CFrame.new(e.HumanoidRootPart.Position+Vector3.new(0,0,-5)));p.Character.HumanoidRootPart.Anchored=true
 elseif action=='Tap'then E.TryManualAttack(p)
 elseif action=='Back'then p.Character.HumanoidRootPart.Anchored=false;return R.Request(p,p:GetAttribute('RunInventoryId'))end
 return {Gauge=E.GetGauge(p,3),Stage=p:GetAttribute('CurrentStage'),Fighting=p:GetAttribute('IsFighting')}
end
