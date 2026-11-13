-- Native prepared combat boundaries. Never include fixture positions/levels in natural timings.
assert(game.ReplicatedStorage:FindFirstChild('__FirstBattleMemory'))
local RS=game.ReplicatedStorage;local q=RS.__FirstBattleQA
local Services=game.ServerScriptService.Services
local D=require(Services.PlayerDataService);local E=require(game.ServerScriptService.World.EnemyManager)
local W=require(game.ServerScriptService.World.Stage1WallManager)
local B=require(game.ServerScriptService.World.BossCombatService)
local F=require(Services.ForgeService);local Return=require(Services.RunReturnService)
local function player()return assert(game.Players:GetPlayers()[1])end
local function snapshot(p)
 local d=D.Get(p).Data;local boss=B.Get(p)
 return {Facts=table.clone(d.FirstBattleTutorial),Ore=table.clone(d.OreMergeTutorial),Equipment=table.clone(d.EquipmentTutorial),
  Wall=W.GetSnapshot(p),Health=p.Character and p.Character:FindFirstChildOfClass('Humanoid')and p.Character.Humanoid.Health,
  Fighting=p:GetAttribute('IsFighting'),Stage=p:GetAttribute('CurrentStage'),World=p:GetAttribute('CurrentWorld') or 1,
  Boss=boss and {HP=boss.HP,Attacks=boss.Attacks,Strength=boss.BattleStartStrength},
  Forge=F.State(p),Position=p.Character and tostring(p.Character:GetPivot().Position)}
end
local function strength(p,lv,v)
 local s=D.Get(p);s.Data.Level=lv;s.Data.Strength=v;s.Dirty=true
 p:SetAttribute('Level',lv);p:SetAttribute('Strength',v)
end
local function place(p,pos,anchor)
 local c=p.Character;local r=c.HumanoidRootPart;local h=c.Humanoid
 local floor=workspace.GeneratedMap.BattleCorridor.Stage01.Floor
 local at=Vector3.new(pos.X,floor.Position.Y+floor.Size.Y/2+h.HipHeight+r.Size.Y/2,pos.Z)
 r.Anchored=false;c:PivotTo(CFrame.lookAt(at,at+Vector3.new(0,0,1)));r.AssemblyLinearVelocity=Vector3.zero;r.Anchored=anchor==true
 h:MoveTo(at)
end
local call=Instance.new('BindableFunction');call.Name='CombatChecks';call.Parent=q
call.OnInvoke=function(action,value)
 local p=player()
 if action=='Fresh' then
  assert(D.WaitForSave(p,20));assert(D.Reset(p));E.InitializePlayer(p)
  D.SetAutoTapEnabled(p,false)
  require(Services.LobbySpawnService).MoveToLobby(p,p.Character,1)
 elseif action=='AtWall' then
  strength(p,2,5);D.SetAutoTapEnabled(p,false);E.InitializePlayer(p)
  local wall=workspace.GeneratedMap.BattleCorridor.Stage01['Stage1.1'].Wall
  place(p,wall.Position-Vector3.new(0,0,4),true)
 elseif action=='AtBoss' then
  W.ApplyDamageForStage(p,1,1e6);E.SendState(p)
  local boss=E.GetEnemy(1,p);assert(boss,'Boss not spawned')
  local r=boss:FindFirstChild('HumanoidRootPart');assert(r)
  place(p,r.Position-Vector3.new(0,0,2),true)
 elseif action=='Back' then return {Returned=table.pack(Return.Request(p,p:GetAttribute('RunInventoryId'))),State=snapshot(p)}
 elseif action=='Tap' then return {Result=table.pack(E.TryManualAttack(p)),State=snapshot(p)}
 elseif action=='Death' then p.Character.HumanoidRootPart.Anchored=false;p.Character.Humanoid.Health=0
 elseif action=='Strength' then strength(p,value.Level,value.Strength)
 elseif action=='Reload' then
  assert(D.WaitForSave(p,20));assert(D.Save(p));D.Release(p);assert(D.Load(p));E.InitializePlayer(p)
 elseif action=='Auto' then D.SetAutoTapEnabled(p,value)
 elseif action=='MoveAway' then
  local wall=workspace.GeneratedMap.BattleCorridor.Stage01['Stage1.1'].Wall;place(p,wall.Position-Vector3.new(0,0,20),true)
 elseif action=='Stage2' then E.StartRun(p,2);place(p,workspace.GeneratedMap.BattleCorridor.Stage02['Stage2.1'].Wall.Position-Vector3.new(0,0,4),true)
 elseif action=='World2' then E.Deactivate(p);p:SetAttribute('CurrentWorld',2);E.ForWorld(2).Activate(p)
 elseif action~='State' then error('Unknown prepared combat action')end
 return snapshot(p)
end
