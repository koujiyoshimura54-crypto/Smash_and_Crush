local S=game.ServerScriptService.Services local p=game.Players:GetPlayers()[1]
local E=require(game.ServerScriptService.World.EnemyManager).ForWorld(1)
local W=require(game.ServerScriptService.World.Stage1WallManager).ForWorld(1)
local A=require(game.ServerScriptService.World.BossAttackService).ForWorld(1)
local R=require(S.RunInventoryService)
local function waitFor(fn,n) local t=os.clock()+n repeat local v=fn() if v then return v end task.wait() until os.clock()>t error("timeout") end
local ok,err=xpcall(function()
 p:SetAttribute("CurrentWorld",1) E.StartRun(p,1)
 local c=p.Character local hum=c.Humanoid local root=c.HumanoidRootPart
 local ps=E.GetPlayerState(p)
 assert(R.TryAddOreDrop(p,ps.RunInventoryId,game.HttpService:GenerateGUID(false),"ORE_001"))
 W.ApplyDamageForStage(p,1,1e30)
 local e=waitFor(function()return E.GetEnemy(1,p)end,5)
 local f=workspace.GeneratedMap.BattleCorridor.Stage01.Floor
 root.CFrame=CFrame.new(e.CombatZone.Position.X,f.Position.Y+f.Size.Y/2+hum.HipHeight+root.Size.Y/2,e.CombatZone.Position.Z)
 waitFor(function()return A.GetState(p)end,10)
 hum.Health=1
 waitFor(function()return hum.Health<=0 end,15)
 script:SetAttribute("Lost",c:GetAttribute("BattleBagLostCount"))
 script:SetAttribute("Dead",true)
end,debug.traceback)
script:SetAttribute("Result",game.HttpService:JSONEncode({OK=ok,Error=not ok and err or nil}))
