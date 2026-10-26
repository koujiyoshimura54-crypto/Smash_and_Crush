local Players=game.Players
local RS=game.ReplicatedStorage
local ST=game:GetService("StudioTestService")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Forge=require(game.ServerScriptService.Services.ForgeService)
local Enemy=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local Wall=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local Run=require(game.ServerScriptService.Services.RunInventoryService)
local Drops=require(game.ServerScriptService.Services.EnemyDropGachaService)
local request=Instance.new("RemoteEvent");request.Name="__OreMultiRequest";request.Parent=RS
local reply=Instance.new("RemoteEvent");reply.Name="__OreMultiReply";reply.Parent=RS
local responses={}
reply.OnServerEvent:Connect(function(p,key,r)responses[key]={Player=p,Value=r}end)
local report={Kind="Two real native clients, isolated stores; scripted inputs",Checks={},Combat={}}
local function check(ok,name) assert(ok,name);table.insert(report.Checks,name) end
local function waitFor(fn,seconds)
 local deadline=os.clock()+seconds
 repeat local value=fn();if value then return value end;task.wait(.1) until os.clock()>deadline
end
local function ask(p,action)
 local key=game.HttpService:GenerateGUID(false);request:FireClient(p,key,action)
 local result=assert(waitFor(function()return responses[key]end,15),"Client response timeout")
 check(result.Player==p and result.Value.OK,"Client owns response")
 return result.Value.Result
end
local ended=false
local function finish() if ended then return end;ended=true;ST:EndTest(report) end
task.delay(180,function()report.Timeout=true;finish()end)
local ok,err=xpcall(function()
 check(waitFor(function()return #Players:GetPlayers()==2 end,45),"Two clients connected")
 local players=Players:GetPlayers();table.sort(players,function(a,b)return a.Name<b.Name end)
 for _,p in ipairs(players) do
  check(waitFor(function()local s=Data.Get(p);return s and s.Loaded and s.Data.OwnedOres.ORE_016==8 end,45),"Isolated seed loaded")
 end
 local p1,p2=players[1],players[2]
 local first=ask(p1,"Merge")
 check(first.Success,"Client one merge")
 check(Forge.State(p2).Ores.ORE_001==8 and not Forge.State(p2).DumbbellCounts.NORMAL_01,"Other inventory unchanged")
 local second=ask(p2,"Merge")
 check(second.Success and Forge.State(p1).Ores.ORE_001==7,"Client two merge independent")
 -- Native combat path, with isolated strength and wall progress preparation.
 for _,p in ipairs(players) do
  Data.SetAutoTapEnabled(p,false);Data.SetCurrentStrength(p,1000000000)
  p:SetAttribute("CurrentWorld",1);Enemy.StartRun(p,1)
  Wall.ApplyDamageForStage(p,1,1000000000)
 end
 check(waitFor(Enemy.IsReady,20),"Enemy service ready")
 for _,p in ipairs(players) do
  local actor=assert(waitFor(function()return Enemy.GetEnemy(1,p)end,10))
  local root=p.Character.HumanoidRootPart;root.Anchored=true
  root.CFrame=actor.CombatZone.CFrame
 end
 task.wait(.3)
 local accepted,reason=Enemy.TryManualAttack(p1)
 table.insert(report.Combat,{Player=p1.Name,Accepted=accepted,Reason=reason})
 local defeated=waitFor(function()return Enemy.GetPlayerState(p1).Defeated[1]end,8)
 check(defeated,"Personal Boss defeated by combat path")
 check(not Enemy.GetPlayerState(p2).Defeated[1],"Other Boss alive")
 task.wait(.15)
 local a,b=ask(p1,"Snapshot"),ask(p2,"Snapshot")
 check(#a.Drops==1 and #b.Drops==0,"Drop remote sent only to owner")
 check(#a.Icons==1 and a.Icons[1].OwnHead and #b.Icons==0,"Head cue only on owner client")
 report.OwnerCue=a.Icons
 local run=Enemy.GetPlayerState(p1)
 local duplicate,why=Drops.OnEnemyDefeated(p1,1,run,1)
 check(not duplicate and why=="AlreadyProcessed","Boss reward dedup")
 local before=Forge.State(p2)
 p1.Character.Humanoid.Health=0;task.wait(.2)
 local after=ask(p2,"Snapshot")
 check(after.State.Sequence==before.Sequence,"Other client inventory survives owner death")
 check(#ask(p1,"Snapshot").Icons==0,"Cue cleaned on death")
 report.Passed=true
end,debug.traceback)
if not ok then report.Error=err;report.Passed=false end
finish()
