-- Only packaged in a fresh local test Place. No production data/store code.
assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute("WalkwayFixture")==true)
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Speed=require(game.ServerScriptService.Services.SpeedService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local control=Instance.new("RemoteFunction");control.Name="__WalkwayControl";control.Parent=RS
local results=Instance.new("RemoteEvent");results.Name="__WalkwayResults";results.Parent=RS
local players={}
local function ready(p,c)
 local h=c:WaitForChild("Humanoid",20);local root=c:WaitForChild("HumanoidRootPart",20)
 assert(h and root)
 p:SetAttribute("CurrentWorld",1)
 c:SetAttribute("LobbySpawnPlaced",true)
 c:SetAttribute("SpawnPlacementRevision",(c:GetAttribute("SpawnPlacementRevision") or 0)+1)
 Speed.Apply(p)
 if (p:GetAttribute("FixtureIndex") or 1)>1 then
  -- Keep the spectator out of the start-boundary fixture and avatar collisions.
  root.CFrame=CFrame.new(310,4.4+h.HipHeight+root.Size.Y/2,13)
 end
 p:SetAttribute("FixtureReady",true)
end
local function bind(p)
 players[#players+1]=p
 p:SetAttribute("FixtureIndex",#players)
 p.CharacterAdded:Connect(function(c) ready(p,c) end)
 if p.Character then task.spawn(ready,p,p.Character) end
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
control.OnServerInvoke=function(p,action,value)
 if action=="Speed" then
  Data.Get(p).Data.SpeedUpgradeStage=value
  Speed.Apply(p)
  return p.Character.Humanoid.WalkSpeed
 elseif action=="World" then p:SetAttribute("CurrentWorld",value);return true
 elseif action=="Training" then
  p:SetAttribute("TrainingTreadmill",value and "Normal01" or nil)
  p:SetAttribute("IsTraining",value);return true
 elseif action=="Scale" then
  p.Character:ScaleTo(value)
  Speed.Apply(p)
  return p.Character.Humanoid.HipHeight
 elseif action=="Respawn" then
  p:SetAttribute("FixtureReady",false)
  p:LoadCharacterAsync();return true
 elseif action=="Death" then p.Character.Humanoid.Health=0;return true
 elseif action=="Status" then
  local rows={}
  for _,other in Players:GetPlayers() do
   rows[#rows+1]={Index=other:GetAttribute("FixtureIndex"),Riding=other:GetAttribute("World1WalkwayRiding")==true,
    Position=other.Character and tostring(other.Character:GetPivot().Position)}
  end
  return rows
 end
 error("Unknown fixture command")
end
local finished=false
results.OnServerEvent:Connect(function(p,result)
 if finished or p:GetAttribute("FixtureIndex")~=1 then return end
 finished=true
 result.Isolation={PlaceId=game.PlaceId,DataStoreDependencies=0,ProductionSaveCode=false,Players=#Players:GetPlayers()}
 game:GetService("StudioTestService"):EndTest(result)
end)
task.delay(180,function()
 if not finished then finished=true;game:GetService("StudioTestService"):EndTest({Passed=false,Error="Fixture timed out"}) end
end)
