local p=game.Players:GetPlayers()[1]
local Boss=require(game.ServerScriptService.World.BossCombatService)
local Mem=require(game.ReplicatedStorage.__NightMemory)
local r=Instance.new('BindableFunction');r.Name='__BalanceCombatRead';r.Parent=game.ServerScriptService
r.OnInvoke=function()
 local s=Boss.Get(p)
 return {Boss=s and {HP=s.HP,Max=s.MaxHP,Attacks=s.Attacks,Damage=s.BattleDamage,Stage=s.Stage},MemoryWrites=Mem.Writes}
end
