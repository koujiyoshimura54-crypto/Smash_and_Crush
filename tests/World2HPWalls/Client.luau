-- Temporary native QA client; observes the actual production renderer/state stream.
local P=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local request=RS:WaitForChild("__HPWallsRequest")
local reply=RS:WaitForChild("__HPWallsReply")
local states,events={},{}
for world=1,2 do
 states[world]={Walls={},Events={}}
 local remote=RS.Remotes.GameRemotes:WaitForChild(world==2 and "World2CombatState" or "CombatState")
 remote.OnClientEvent:Connect(function(d)
  local s=states[world]
  table.insert(s.Events,{Type=d.Type,Stage=d.MajorStage or d.Stage,Index=d.Index,Next=d.Next,Current=d.Current})
  if d.Type=="Initialize" then s.CurrentStage=d.CurrentStage;s.Walls={} end
  if d.Type=="WallInitialize" then s.Walls[d.State.MajorStage]=d.State end
  if d.Type=="WallCleared" and d.State then s.Walls[d.MajorStage]=d.State end
  if d.Type=="WallGauge" then local wall=s.Walls[d.MajorStage];if wall then wall.Gauges[d.Index]=d.Current end end
 end)
end
request.OnClientEvent:Connect(function(key,action,args)
 task.spawn(function()
  local ok,result=xpcall(function()
   args=args or {};local world=args.World or 2;local n=args.Stage or 1
   local remote=RS.Remotes.GameRemotes[world==2 and "World2CombatState" or "CombatState"]
   if action=="Resync" then remote:FireServer({Type="RequestState"});task.wait(.3) end
   if action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(args.Action);return {Requested=args.Action} end
   if action=="Walk" then
    local hum=P.Character:FindFirstChildOfClass("Humanoid")
    hum:MoveTo(args.Target)
    local deadline=os.clock()+12
    repeat task.wait(.1) until P.Character.HumanoidRootPart.Position.Z>=args.Target.Z-1 or os.clock()>deadline
    return {Position={P.Character.HumanoidRootPart.Position.X,P.Character.HumanoidRootPart.Position.Y,P.Character.HumanoidRootPart.Position.Z},TargetZ=args.Target.Z}
   end
   local map=workspace[world==2 and "World2Map" or "GeneratedMap"]
   local stage=map.BattleCorridor[("Stage%02d"):format(n)]
   local result={State=states[world].Walls[n],CurrentStage=states[world].CurrentStage,Walls={},Events=states[world].Events}
   for i=1,args.Count or (world==2 and (n<=5 and 5 or 6) or 4) do
    local model=stage:FindFirstChild(("Stage%d.%d"):format(n,i));local wall=model and model:FindFirstChild("Wall")
    if wall then
     local gui=wall:FindFirstChild("SurfaceGui") or wall:FindFirstChild(world==2 and "World2StageSurface" or "StageSurface")
     local hp=gui and (gui:FindFirstChild("Amount",true) or gui:FindFirstChild("HPLabel",true))
     result.Walls[i]={Collide=wall.CanCollide,Hidden=wall.LocalTransparencyModifier>=.99,Enabled=gui and gui.Enabled,Text=hp and hp.Text}
    end
   end
   return result
  end,debug.traceback)
  reply:FireServer(key,{Success=ok,Result=result})
 end)
end)
reply:FireServer("Ready",true)
