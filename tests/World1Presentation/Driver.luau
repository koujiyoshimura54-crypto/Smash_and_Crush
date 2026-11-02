-- Temporary native server fixture. Install only with the memory service substitutions.
local RS=game.ReplicatedStorage
local Memory=require(RS.__PresentationMemory)
local S=game.ServerScriptService.Services
local Data=require(S.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local Placement=require(S.LobbySpawnService)
local M={}
function M.Wait(fn,seconds)
 local deadline=os.clock()+seconds
 repeat local value=fn();if value then return value end;task.wait(.1) until os.clock()>deadline
 error("Fixture timeout")
end
function M.Ready(p)
 M.Wait(function()local s=Data.Get(p);return s and s.Loaded and p.Character and p.Character:FindFirstChild("HumanoidRootPart") end,30)
 Data.SetAutoTapEnabled(p,false)
end
local function place(p,position)
 local root=p.Character.HumanoidRootPart
 root.Anchored=false
 p.Character:PivotTo(CFrame.new(position)*root.CFrame.Rotation)
end
function M.Status(p)
 return {Win=p:GetAttribute("Win"),World=p:GetAttribute("CurrentWorld") or 1,Stage=p:GetAttribute("CurrentStage"),
  Defeated=table.clone(Enemy.GetPlayerState(p).Defeated),Prompts=Memory.Prompts or 0,
  PromptBusy=p:GetAttribute("WinPassPromptBusy")==true}
end
function M.Run(p,action,value)
 if action=="Status" then return M.Status(p) end
 M.Ready(p)
 if action=="Stage" then
  Data.SetCurrentStrength(p,0);Enemy.StartRun(p,value)
  local actor=M.Wait(function()return Enemy.GetEnemy(value,p)end,10)
  local floor=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(value)].Floor
  local origin=actor.HumanoidRootPart.Position
  place(p,Vector3.new(origin.X,floor.Position.Y+floor.Size.Y/2+3.5,origin.Z-32))
  -- Prepared visual inspection: clear only this owner's walls.
  Wall.ApplyDamageForStage(p,value,1e18)
 elseif action=="Position" then place(p,Vector3.new(value[1],value[2],value[3]))
 elseif action=="Lobby" then Placement.MoveToLobby(p,p.Character,1)
 elseif action=="Defeat" then
  local n=p:GetAttribute("CurrentStage") or 1
  -- Encounter strength is captured at Begin: prepare a new encounter after the grant.
  Data.SetCurrentStrength(p,1e18);Enemy.StartRun(p,n)
  local actor=M.Wait(function()return Enemy.GetEnemy(n,p)end,10)
  Wall.ApplyDamageForStage(p,n,1e18)
  local root=p.Character.HumanoidRootPart
  root.Anchored=true;root.CFrame=actor.CombatZone.CFrame;task.wait(.35)
  local ok,reason=Enemy.TryManualAttack(p);assert(ok,reason)
  M.Wait(function()return Enemy.GetPlayerState(p).Defeated[n]end,10)
  root.Anchored=false;Data.SetCurrentStrength(p,0);task.wait(.5)
 elseif action=="Pad" then
  local stage=workspace.GeneratedMap.BattleCorridor[("Stage%02d"):format(value.Stage)]
  local handle=stage[value.Double and "TrophyDoubleButton" or "TrophyNormalButton"].Handle
  place(p,handle.Position+Vector3.new(0,3,0));task.wait(.8)
 elseif action=="CancelPrompt" then
  local row=Memory.LastPrompt
  assert(row and row.Player==p);Memory.PromptFinished:Fire(p,row.PassId,false);task.wait(.2)
 elseif action=="Death" then p.Character.Humanoid.Health=0
 elseif action=="Gate" then
  local trigger
  if value==2 then
   Data.UnlockWorld(p,2)
   local config=require(RS.Config.WorldGateConfig)
   trigger=workspace[config.GateName].WorldGateTrigger
  else trigger=workspace.World2Map.TrainingArea.World1ReturnGate.WorldGateTrigger end
  place(p,trigger.Position)
 elseif action=="OreGuide" then
  Data.CompleteTutorial(p)
  local Forge=require(S.ForgeService)
  for _=1,2 do assert(Forge.GrantOre(p,"ORE_001",game.HttpService:GenerateGUID(false))) end
  Placement.MoveToLobby(p,p.Character,1)
 else error("Unknown action: "..action) end
 return M.Status(p)
end
return M
