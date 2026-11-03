-- Native two-client fixture. All external persistence/payment handles are isolated.
local RS=game.ReplicatedStorage
local D=require(game.ServerScriptService.Services.PlayerDataService)
local P=require(game.ServerScriptService.Services.LobbySpawnService)
local C=require(RS.Modules.WorldGateContact)
local remote=Instance.new("RemoteFunction");remote.Name="__GateQAMulti";remote.Parent=RS
local players,ready,phase,reports={},false,0,{}
local ended=false
local function waitFor(fn,t)
 local limit=os.clock()+(t or 30)
 repeat local v=fn();if v then return v end;task.wait(.05)until os.clock()>limit
 error("Gate multiplayer timeout")
end
local function finish(v)if ended then return end;ended=true;game:GetService("StudioTestService"):EndTest(game.HttpService:JSONEncode(v))end
local function idle(p)return waitFor(function()local s=D.Get(p);return s and s.Loaded and not s.Saving and s end)end
local function status(p)
 local w=p:GetAttribute("CurrentWorld")==2 and 2 or 1
 local wall=C.Wall(w);local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
 return {World=w,Highest=D.Get(p).Data.HighestUnlockedWorld,Touching=C.Touching(wall,c,.3),
  WallDistance=root and wall.CFrame:PointToObjectSpace(root.Position).Z,Health=c and c:FindFirstChildOfClass("Humanoid")and c.Humanoid.Health or 0}
end
task.spawn(function()
 local ok,err=xpcall(function()
  waitFor(function()return #game.Players:GetPlayers()==2 end,45)
  players=game.Players:GetPlayers();table.sort(players,function(a,b)return a.UserId<b.UserId end)
  for _,p in players do
   local s=idle(p);if s.StudioStartOverride then D.RestoreStudioStartOverride(p)end;idle(p)
   assert(D.Reset(p));D.SetAutoTapEnabled(p,false);D.CompleteTutorial(p)
   waitFor(function()local c=p.Character;return c and c:GetAttribute("LobbySpawnPlaced")and c:FindFirstChild("HumanoidRootPart")and not c.HumanoidRootPart.Anchored end,40)
  end
  assert(D.UnlockWorld(players[1],2));ready=true
 end,debug.traceback)
 if not ok then finish({Error=err})end
end)
remote.OnServerInvoke=function(p,action,v)
 if action=="Ready" then waitFor(function()return ready end,70);return table.find(players,p)
 elseif action=="AtGate" then
  local world=p:GetAttribute("CurrentWorld")==2 and 2 or 1;local wall=C.Wall(world)
  local floor=select(2,P.GetLobby(world));local c=p.Character;local r=c.HumanoidRootPart
  local pos=wall.CFrame:PointToWorldSpace(Vector3.new(0,0,8))
  pos=Vector3.new(pos.X,floor.Position.Y+floor.Size.Y/2+P.GetRootClearance(p,c)+.15,pos.Z)
  c:PivotTo(CFrame.lookAt(pos,Vector3.new(wall.Position.X,pos.Y,wall.Position.Z))*r.CFrame:ToObjectSpace(c:GetPivot()))
  r.AssemblyLinearVelocity=Vector3.zero
 elseif action=="Unlock" then assert(D.UnlockWorld(p,2))
 elseif action=="Status" then return status(p)
 elseif action=="Peer" then return status(players[p==players[1] and 2 or 1])
 elseif action=="Phase" then phase=math.max(phase,v);return true
 elseif action=="WaitPhase" then waitFor(function()return phase>=v end,90);return true
 elseif action=="Die" then p.Character.Humanoid.Health=0
 elseif action=="Respawn" then waitFor(function()
  local c=p.Character;return c and c:FindFirstChildOfClass("Humanoid")and c.Humanoid.Health>0 and c:GetAttribute("LobbySpawnPlaced")
   and c:FindFirstChild("HumanoidRootPart")and not c.HumanoidRootPart.Anchored end,40)
 elseif action=="Report" then
  reports[table.find(players,p)]=v
  if reports[1]and reports[2]then task.defer(function()finish({Reports=reports,States={status(players[1]),status(players[2])}})end)end
  return true
 end
 return status(p)
end
task.delay(210,function()finish({Timeout=true,Reports=reports,Phase=phase})end)
