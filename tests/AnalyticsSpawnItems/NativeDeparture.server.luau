-- Run at the end of an isolated native Play; actually disconnects the local test player.
assert(game.PlaceId==126576845524886 and game.GameId==10765181857 and game:GetService("RunService"):IsStudio())
assert(game.ReplicatedStorage:FindFirstChild("__ThreeFixMemory"))
local q=game.ReplicatedStorage.__ThreeFixQA
local p=assert(game.Players:GetPlayers()[1])
local L=require(game.ServerScriptService.Services.LobbySpawnService)
local finished=false
local added=0
p.CharacterAdded:Connect(function()added+=1;q:SetAttribute("DepartureCharacterAdds",added)end)
game.Players.PlayerRemoving:Connect(function(who)
 if who==p then
  q:SetAttribute("DepartureParentStillPlayers",p.Parent==game.Players)
  q:SetAttribute("DepartureBeforeReturn",not finished)
 end
end)
task.spawn(function()
 q:SetAttribute("DepartureLoadStarted",true)
 local result=L.LoadCharacter(p)
 finished=true;q:SetAttribute("DepartureLoadResult",result);q:SetAttribute("DepartureLoadReturned",true)
end)
task.defer(function()p:Kick("Isolated QA: disconnect during LoadCharacterAsync")end)
