-- Temporary Studio-only Play probe. Removed after verification.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Debug=require(game.ServerScriptService.Systems.Debug.StudioDebugService)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local Boss=require(game.ServerScriptService.World.BossCombatService)
local control=Instance.new("Folder")
control.Name="BossDisplayQAControl"
control.Parent=workspace
local p=Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
repeat task.wait(.1) until Data.Get(p) and Data.Get(p).Loaded and Enemy.IsReady() and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
local remote=RS.Remotes.GameRemotes.CombatState
local function park(cf)
 local ch=p.Character
 local root=ch.HumanoidRootPart
 root.Anchored=true
 ch:PivotTo(cf)
 root.AssemblyLinearVelocity=Vector3.zero
 root.AssemblyAngularVelocity=Vector3.zero
end
control:GetAttributeChangedSignal("Action"):Connect(function()
 local action=control:GetAttribute("Action")
 local ok,err=pcall(function()
  if action=="prepare" then
   assert(Debug.Execute(p,"/setstrength 57"))
   Enemy.StartRun(p,1)
   park(CFrame.new(27.92,6,-12)*CFrame.Angles(0,math.pi,0))
  elseif action:match("^wall%d$") then
   local i=tonumber(action:sub(-1))
   local w=workspace.GeneratedMap.BattleCorridor.Stage01[("Stage1.%d"):format(i)].Wall
   park(CFrame.new(w.Position.X,w.Position.Y-w.Size.Y/2+3,w.Position.Z-3.5)*CFrame.Angles(0,math.pi,0))
  elseif action=="boss" then
   local z=Enemy.GetEnemy(1).CombatZone
   park(CFrame.new(z.Position.X,5,z.Position.Z-z.Size.Z/2+1)*CFrame.Angles(0,math.pi,0))
  elseif action=="park" then
   park(CFrame.new(27.92,6,35)*CFrame.Angles(0,math.pi,0))
  elseif action:match("^show%d+$") then
   local n=tonumber(action:match("%d+"))
   Enemy.StartRun(p,n)
   local cleared,nextIndex=Wall.ApplyDamageForStage(p,n,1e15)
   -- UI fixture uses real wall snapshots and existing CombatState packets.
   -- Does not queue synthetic excess into Boss Combat.
   remote:FireClient(p,{Type="WallCleared",MajorStage=n,Index=4,Next=nextIndex,State=Wall.GetSnapshotForStage(p,n)})
   remote:FireClient(p,{Type="BossRecommendation",Stage=n,Current=Enemy.GetGauge(p,n),Max=Boss.GetStageConfig(n).MaxHP,RecommendedLevel=Boss.GetStageConfig(n).RecommendedLevel})
  elseif action=="sendstate" then
   Enemy.SendState(p)
  end
 end)
 control:SetAttribute("Result",Http:JSONEncode({action=action,ok=ok,error=not ok and tostring(err) or nil}))
end)
control:SetAttribute("Ready",true)
