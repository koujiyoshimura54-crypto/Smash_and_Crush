-- Preflight only: initial fixture funds; this entire Play is discarded before the fresh run.
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local p=game.Players:GetPlayers()[1]or game.Players.PlayerAdded:Wait()
while not Data.IsLoaded(p)do task.wait(.1)end
assert(Data.SetWin(p,1000))
script:SetAttribute('Seeded',true)
