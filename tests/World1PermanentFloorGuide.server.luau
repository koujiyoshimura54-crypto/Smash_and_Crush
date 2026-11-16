-- Temporary native Play driver. Production persistence/payment must be isolated.
assert(game.ReplicatedStorage:FindFirstChild("__FloorRouteMemory"))
local D=require(game.ServerScriptService.Services.PlayerDataService)
local E=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local P=require(game.ServerScriptService.Services.LobbySpawnService)
local call=Instance.new("BindableFunction");call.Name="__FloorRouteServerCall";call.Parent=game.ReplicatedStorage
local function waitFor(fn)
 local deadline=os.clock()+15
 repeat local a=fn();if a then return a end;task.wait(.1) until os.clock()>deadline
 error("FloorRoute fixture timeout")
end
call.OnInvoke=function(action,value)
 local p=game.Players:GetPlayers()[1];waitFor(function()return D.IsLoaded(p) and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end)
 local root=p.Character.HumanoidRootPart
 if action=="Wall" then
  D.SetCurrentStrength(p,50);D.Get(p).Data.Level=2;p:SetAttribute("Level",2);E.StartRun(p,1)
  local wall=workspace.GeneratedMap.BattleCorridor.Stage01["Stage1.1"].Wall
  local pos=Vector3.new(wall.Position.X,7.5,wall.Position.Z-1)
  root.Anchored=true;root.CFrame=CFrame.lookAt(pos,Vector3.new(wall.Position.X,7.5,wall.Position.Z));task.wait(.5)
  local ok,why=E.TryManualAttack(p);assert(ok,tostring(why));task.wait(.7)
 elseif action=="Boss" then
  local actor=waitFor(function()return E.GetEnemy(1,p)end)
  root.Anchored=true;root.CFrame=actor.CombatZone.CFrame;task.wait(.4)
  for _=1,10 do
   E.TryManualAttack(p);task.wait(.9)
   if E.GetPlayerState(p).Defeated[1] then break end
   if actor.Parent then root.CFrame=actor.CombatZone.CFrame end
  end
  root.Anchored=false
 elseif action=="Trophy" then
  local handle=workspace.GeneratedMap.BattleCorridor.Stage01.TrophyNormalButton.Handle
  root.Anchored=false;root.CFrame=CFrame.new(handle.Position+Vector3.new(0,3,0));task.wait(1.5)
 elseif action=="Lobby" then
  assert(P.MoveToLobby(p,p.Character,1));task.wait(.8)
 elseif action=="Death" then
  local old=p.Character;root.Anchored=false;old.Humanoid.Health=0
  waitFor(function()return p.Character~=old and p.Character and p.Character:GetAttribute("LobbySpawnPlaced")end)
  task.wait(.5)
 elseif action=="Gate" then
  if value==2 then D.UnlockWorld(p,2) end
  local contact=require(game.ReplicatedStorage.Modules.WorldGateContact).Wall(p:GetAttribute("CurrentWorld") or 1)
  root.Anchored=false;root.CFrame=CFrame.new(contact.Position);task.wait(.3)
 elseif action=="Complete" then
  D.CompleteTutorial(p)
 elseif action=="Merge" then
  assert(P.MoveToLobby(p,p.Character,1))
  p:SetAttribute("FirstBattleOutcome","Victory");p:SetAttribute("FirstBattleStage1Defeated",true)
  p:SetAttribute("OreTutorialCompleted",false);p:SetAttribute("DumbbellEquipTutorialInitialCompleted",false)
  -- Feed a confirmed guide target to exercise the existing rendering branch only.
  p:SetAttribute("OreTutorialTarget",workspace.RestockShop:GetPivot().Position)
 elseif action=="Attributes" then
  for k,v in value do p:SetAttribute(k,v) end
 else assert(action=="Status",action) end
 return {Loaded=D.IsLoaded(p),Level=p:GetAttribute("Level"),World=p:GetAttribute("CurrentWorld") or 1,
  Complete=p:GetAttribute("TutorialCompleted"),Wall=W.GetSnapshot(p),
  Defeated=E.GetPlayerState(p).Defeated[1],Root=tostring(p.Character.HumanoidRootPart.Position)}
end
