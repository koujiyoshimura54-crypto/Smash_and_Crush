-- Temporary native solo-Play fixture. Install only with __OreDisplayMemory interception.
local RS=game.ReplicatedStorage
assert(RS:FindFirstChild('__OreDisplayMemory'),'Memory isolation is required')
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Forge=require(game.ServerScriptService.Services.ForgeService)
local Lobby=require(game.ServerScriptService.Services.LobbySpawnService)
local p=game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()
local function waitFor(fn)
 local untilTime=os.clock()+25
 repeat local v=fn();if v then return v end;task.wait(.1) until os.clock()>untilTime
 error('Ore display fixture timed out')
end
waitFor(function()local s=Data.Get(p);return s and s.Loaded and p.Character and p.Character:FindFirstChild('HumanoidRootPart')end)
Data.SetAutoTapEnabled(p,false)
local function status()
 local d=Data.Get(p).Data
 return {Tutorial=d.OreMergeTutorial,Floor=d.TutorialCompleted,Ores=d.OwnedOres,Bells=d.OwnedDumbbells,Time=d.TimeRewards.Claimed}
end
local probe=Instance.new('BindableFunction');probe.Name='__OreDisplayServer'
probe.OnInvoke=function(action,value)
 if action=='Prepare' then
  waitFor(function()return not Data.Get(p).Saving end)
  assert(Data.CompleteTutorial(p))
  for _=1,2 do
   waitFor(function()return not Data.Get(p).Saving end)
   local ok,why=Forge.GrantOre(p,'ORE_001',game.HttpService:GenerateGUID(false));assert(ok,why)
  end
  Lobby.MoveToLobby(p,p.Character,1)
 elseif action=='Grant' then
  for _,id in value do
   waitFor(function()return not Data.Get(p).Saving end)
   local ok,why=Forge.GrantOre(p,id,game.HttpService:GenerateGUID(false));assert(ok,why)
  end
 elseif action=='Death' then p.Character.Humanoid.Health=0
 elseif action=='Lobby' then Lobby.MoveToLobby(p,p.Character,1)
 elseif action=='Status' then
 else error('Unknown server probe action') end
 return status()
end
probe.Parent=RS
print('[OreDisplay QA] isolated native server ready')
