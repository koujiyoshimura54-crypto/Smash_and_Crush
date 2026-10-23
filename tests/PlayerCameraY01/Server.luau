-- Temporary native Play fixture. Never retained in the place.
local RS=game.ReplicatedStorage
local Players=game.Players
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
local E=require(game.ServerScriptService.World.EnemyManager)
local control=Instance.new("RemoteFunction");control.Name="__Y01CameraControl";control.Parent=RS
control.OnServerInvoke=function(p,op,value)
 assert(game:GetService("RunService"):IsStudio() and RS:FindFirstChild("__Y01CameraMemory"))
 local deadline=os.clock()+30
 while not Data.IsLoaded(p) and os.clock()<deadline do task.wait(.05) end
 assert(Data.IsLoaded(p),"Isolated profile unavailable")
 if op=="setup" then
  Data.SetRebirthCount(p,10);Data.SetWin(p,1000000);Data.UnlockWorld(p,2)
  Data.SetAutoTapEnabled(p,false);Data.CompleteTutorial(p)
 elseif op=="strength" then Strength.SetStrength(p,value)
 elseif op=="tier" then return {Data.ChangeSelectedSize(p,value,require(RS.Config.SizeChangeConfig))}
 elseif op=="die" then p.Character.Humanoid.Health=0
 elseif op=="gate" then
  local trigger
  if value==2 then trigger=workspace:FindFirstChild(require(RS.Config.WorldGateConfig).GateName).WorldGateTrigger
  else trigger=workspace.World2Map.TrainingArea.World1ReturnGate.WorldGateTrigger end
  local root=p.Character.HumanoidRootPart;root.CFrame=trigger.CFrame;root.AssemblyLinearVelocity=Vector3.zero
 elseif op=="skip" then return {require(game.ServerScriptService.Services.StageSkipService).BuyWithWin(p,value)}
 elseif op=="lobby" then return {Placement.MoveToLobby(p,p.Character,Placement.WorldFor(p))}
 elseif op=="trophy" then
  local world=Placement.WorldFor(p);local enemy=E.ForWorld(world)
  enemy.StartRun(p,1)
  enemy.GetPlayerState(p).Defeated[1]=true -- condition fixture, not a battle-clear claim
  local trophy=require(game.ServerScriptService.Services.TrophyRewardService).ForWorld(world)
  assert(trophy.Spawn(p,1),"Trophy condition setup")
  local map=workspace[world==2 and "World2Map" or "GeneratedMap"]
  local pad=map.BattleCorridor.Stage01.TrophyNormalButton.Handle
  local root=p.Character.HumanoidRootPart
  root.CFrame=pad.CFrame+Vector3.new(0,p.Character.Humanoid.HipHeight+root.Size.Y/2,0)
  root.AssemblyLinearVelocity=Vector3.zero
 end
 return {World=p:GetAttribute("CurrentWorld") or 1,Scale=p.Character:GetAttribute("MuscleHeightScale"),
  Strength=p:GetAttribute("Strength"),Win=p:GetAttribute("Win"),Stage=p:GetAttribute("CurrentStage")}
end
