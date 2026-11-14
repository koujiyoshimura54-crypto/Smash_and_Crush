-- Temporary isolated Play fixture; never install in published game.
assert(game:GetService('RunService'):IsStudio() and game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local q=game.ReplicatedStorage.__Stage1MotionQA
local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local D=require(game.ServerScriptService.Services.PlayerDataService)
local R=require(game.ServerScriptService.Services.RunReturnService)
local f=Instance.new('BindableFunction');f.Name='Server';f.Parent=q
f.OnInvoke=function(action)
 local p=game.Players:GetPlayers()[1];local s=D.Get(p);assert(s and s.Loaded)
 if action=='Unlock' then s.Data.Strength=40;s.Data.Level=4;p:SetAttribute('Strength',40);p:SetAttribute('Level',4);W.ApplyDamageForStage(p,1,10000);E.SendState(p)
 elseif action=='Battle' then local e=E.GetEnemy(1,p);local c=p.Character;local r=e.HumanoidRootPart;c:PivotTo(CFrame.new(r.Position+Vector3.new(0,0,-5)));c.HumanoidRootPart.Anchored=true
 elseif action=='Tap'then E.TryManualAttack(p)
 elseif action=='Back'then p.Character.HumanoidRootPart.Anchored=false;return R.Request(p,p:GetAttribute('RunInventoryId')) end
 local e=E.GetEnemy(1,p);return {Enemy=e and e:GetFullName(),HP=e and e:GetAttribute('BossMaxHP'),Fighting=p:GetAttribute('IsFighting')}
end
