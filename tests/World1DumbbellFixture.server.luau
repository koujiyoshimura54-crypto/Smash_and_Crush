-- Only in the fresh local fixture. No production profile/save implementation.
assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute("DumbbellFixture")==true)
local Players=game:GetService("Players")
local RS=game.ReplicatedStorage
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Service=require(game.ServerScriptService.Services.DumbbellService)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local Body=require(game.ServerStorage.BodyPrototype_20261114.PlayableBodyPrototype)
local Stand=require(game.ServerScriptService.Services.DumbbellStandService)
local control=Instance.new("RemoteFunction");control.Name="__DumbbellControl";control.Parent=RS
local results=Instance.new("RemoteEvent");results.Name="__DumbbellResults";results.Parent=RS
local observer=Instance.new("RemoteFunction");observer.Name="__DumbbellObserver";observer.Parent=RS
local index=0
local function ready(p,c)
 local h=c:WaitForChild("Humanoid",20);local r=c:WaitForChild("HumanoidRootPart",20);assert(h and r)
 h.WalkSpeed=24
 r.CFrame=CFrame.new((p:GetAttribute("FixtureIndex")-1)*20,h.HipHeight+r.Size.Y/2+.1,0)
 p:SetAttribute("FixtureReady",true)
end
local function bind(p)
 index+=1;p:SetAttribute("FixtureIndex",index);p:SetAttribute("CurrentWorld",1)
 Data.Get(p)
 if index==2 then Service.EquipDumbbell(p,"NORMAL_12") end
 p.CharacterAdded:Connect(function(c)ready(p,c)end)
 if p.Character then task.spawn(ready,p,p.Character)end
end
Players.PlayerAdded:Connect(bind);for _,p in Players:GetPlayers()do bind(p)end
game.CollectionService:AddTag(workspace.Treadmills.Normal01,"TrainingTreadmill")
Training.Initialize()
Stand.Start(function(p,id)p:SetAttribute("FixtureStandEntry",id);return true end)
control.OnServerInvoke=function(p,action,v)
 local c=p.Character
 if action=="Equip" then return v=="" and Service.UnequipDumbbell(p) or Service.EquipDumbbell(p,v)
 elseif action=="Snapshot" then return {Data=game.HttpService:JSONEncode(Data.Get(p).Data),Bonus=Service.GetStrengthBonus(p),Ticks=p:GetAttribute("FixtureTicks") or 0,Gain=p:GetAttribute("FixtureGain"),Stand=p:GetAttribute("FixtureStandEntry")}
 elseif action=="World" then p:SetAttribute("CurrentWorld",v);return true
 elseif action=="Loaded" then Data.Get(p).Loaded=v;return true
 elseif action=="Owned" then Data.Get(p).Data.OwnedDumbbells.NORMAL_01=v and 1 or nil;return true
 elseif action=="Body" then
  c:SetAttribute("BodyPrototypeManaged",true)
  local ok,why=Body.Apply(c,function()return p.Character==c end);assert(ok,why)
  Body.BeginTransition(c);c.HumanoidRootPart.Anchored=true
  ok,why=Body.ApplyStage(c,v.Stage,{Active=true,Body=v.Body,Mode=v.Mode,Stage=v.Stage,Height=v.Height or 1,Thickness=v.Thickness or 1});assert(ok,why)
  return {Scale=c:GetAttribute("BodyPrototypeDumbbellScale"),Height=c:GetAttribute("BodyComparisonHeight"),Hip=c.Humanoid.HipHeight}
 elseif action=="BodyRelease" then Body.EndTransition(c);c.HumanoidRootPart.Anchored=false;return true
 elseif action=="Pose" then
  local zone=workspace.Treadmills.Normal01.Area
  local feet={};for _,name in {"LeftFoot","RightFoot"}do local f=c:FindFirstChild(name);if f then feet[name]={Y=f.Position.Y,SizeY=f.Size.Y,ZoneY=zone.CFrame:PointToObjectSpace(f.Position).Y}end end
  return {Health=c.Humanoid.Health,Root=tostring(c.HumanoidRootPart.Position),Feet=feet,Hip=c.Humanoid.HipHeight,Inside=Training.IsPlayerInsideZone(p,zone)}
 elseif action=="Training" then
  if v then return Training.StartTraining(p,workspace.Treadmills.Normal01) else Training.StopTraining(p);return true end
 elseif action=="Missing" then
  local library=game.ServerStorage.World1DumbbellModels
  if v then library.NORMAL_04.Name="__FixtureMissing" else library.__FixtureMissing.Name="NORMAL_04" end return true
 elseif action=="Respawn" then p:SetAttribute("FixtureReady",false);p:LoadCharacterAsync();return true
 elseif action=="Death" then c.Humanoid.Health=0;return true
 elseif action=="Observer" then
  for _,other in Players:GetPlayers()do if other~=p then return observer:InvokeClient(other)end end
  return {Error="No second client"}
 end
 error("Unknown fixture action "..action)
end
local finished=false
results.OnServerEvent:Connect(function(p,result)
 if finished or p:GetAttribute("FixtureIndex")~=1 then return end
 finished=true
 result.Isolation={PlaceId=game.PlaceId,ProductionPersistencePresent=false,Players=#Players:GetPlayers(),FixtureBodyGateAdapted=true}
 game:GetService("StudioTestService"):EndTest(result)
end)
task.delay(240,function()if not finished then finished=true;game:GetService("StudioTestService"):EndTest({Passed=false,Error="Fixture timeout"})end end)
