assert(game.PlaceId==0 and game.ReplicatedStorage:GetAttribute("BodyDumbbellFixture")==true)
local Players=game:GetService("Players")
Players.CharacterAutoLoads=false
local RS=game.ReplicatedStorage
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Service=require(game.ServerScriptService.Services.DumbbellService)
local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local control=Instance.new("RemoteFunction");control.Name="__BodyDumbbellControl";control.Parent=RS
local results=Instance.new("RemoteEvent");results.Name="__BodyDumbbellResults";results.Parent=RS
local observer=Instance.new("RemoteFunction");observer.Name="__BodyDumbbellObserver";observer.Parent=RS
local index=0
local function bind(p)
 index+=1;p:SetAttribute("FixtureIndex",index);p:SetAttribute("CurrentWorld",1);p:SetAttribute("RebirthCount",0)
 local s=Data.Get(p);p:SetAttribute("Level",s.Data.Level);p:SetAttribute("Strength",s.Data.Strength)
 p.CharacterAdded:Connect(function(c)
  c:WaitForChild("Humanoid",20).WalkSpeed=require(RS.Config.SpeedConfig).DefaultSpeed
 end)
end
Players.PlayerAdded:Connect(bind);for _,p in Players:GetPlayers()do bind(p)end
for _,m in {workspace.Treadmills.Normal01,workspace.World2Map.TrainingArea.TreadmillDisplays["01"]}do game.CollectionService:AddTag(m,"TrainingTreadmill")end
Training.Initialize()
Placement.Start()
local function machine(world)return world==2 and workspace.World2Map.TrainingArea.TreadmillDisplays["01"] or workspace.Treadmills.Normal01 end
local function snapshot(p,world)
 local s=Data.Get(p);local c=p.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
 local zone=machine(world or p:GetAttribute("CurrentWorld")).Area
 local parts={};local constraints={}
 if c then for _,x in c:GetDescendants()do
  if x:IsA("BasePart") then table.insert(parts,{Path=x:GetFullName(),Size={x.Size.X,x.Size.Y,x.Size.Z},Y=x.Position.Y,BottomY=x.Position.Y-(math.abs(x.CFrame.RightVector.Y)*x.Size.X+math.abs(x.CFrame.UpVector.Y)*x.Size.Y+math.abs(x.CFrame.LookVector.Y)*x.Size.Z)/2,Collide=x.CanCollide,Anchored=x.Anchored,Massless=x.Massless,Mass=x:GetMass(),AssemblyRoot=x.AssemblyRootPart and x.AssemblyRootPart.Name,MeshSize=x:IsA("MeshPart")and tostring(x.MeshSize)or nil})
  elseif x:IsA("Constraint")then table.insert(constraints,{Name=x.Name,Type=x.ClassName,Enabled=x.Enabled})end
 end end
 return {Data=table.clone(s.Data),Events=table.clone(s.Events),Parts=parts,Constraints=constraints,Health=h and h.Health,HipHeight=h and h.HipHeight,State=h and h:GetState().Name,Floor=h and h.FloorMaterial.Name,Move=h and tostring(h.MoveDirection),Root=r and tostring(r.Position),Velocity=r and tostring(r.AssemblyLinearVelocity),Mass=r and r.AssemblyMass,Inside=c and Training.IsPlayerInsideZone(p,zone),Training=p:GetAttribute("IsTraining"),Area={Size=tostring(zone.Size),Position=tostring(zone.Position)},Scale=c and c:GetAttribute("BodyPrototypeDumbbellScale")}
end
control.OnServerInvoke=function(p,action,v)
 if action=="Equip"then return v=="" and Service.UnequipDumbbell(p) or Service.EquipDumbbell(p,v)
 elseif action=="Snapshot"then return snapshot(p,v)
 elseif action=="World"then Training.StopTraining(p);p:SetAttribute("CurrentWorld",v);return Placement.MoveToLobby(p,p.Character,v)
 elseif action=="Training"then return Training.StartTraining(p,machine(v))
 elseif action=="Stop"then return Training.StopTraining(p)
 elseif action=="Loaded"then Data.Get(p).Loaded=v;return true
 elseif action=="Death"then local strength=Data.Get(p).Data.Strength;p.Character.Humanoid.Health=0;return strength
 elseif action=="LegacyBody"then
  assert(RS:GetAttribute("FixtureVariant")=="legacy_transition")
  local c=p.Character;local b=require(game.ServerStorage.BodyPrototype_20261114.PlayableBodyPrototype)
  b.BeginTransition(c);c.HumanoidRootPart.Anchored=true
  return b.ApplyStage(c,v.Stage,{Active=true,Body=v.Body,Mode=v.Mode,Stage=v.Stage,Height=1,Thickness=1})
 elseif action=="LegacyRelease"then
  assert(RS:GetAttribute("FixtureVariant")=="legacy_transition")
  require(game.ServerStorage.BodyPrototype_20261114.PlayableBodyPrototype).EndTransition(p.Character);p.Character.HumanoidRootPart.Anchored=false;return true
 elseif action=="Observer"then for _,other in Players:GetPlayers()do if other~=p then return observer:InvokeClient(other)end end;return {NoPeer=true}
 elseif action=="PeerEquip"then for _,other in Players:GetPlayers()do if other~=p then return Service.EquipDumbbell(other,v)end end;return false
 end
 error("Unknown fixture action: "..tostring(action))
end
local finished=false
results.OnServerEvent:Connect(function(p,result)
 if finished or p:GetAttribute("FixtureIndex")~=1 then return end
 finished=true;result.Isolation={PlaceId=0,Variant=RS:GetAttribute("FixtureVariant"),ProductionPersistencePresent=false,Players=#Players:GetPlayers(),ActualBodyComparisonHandshake=RS:GetAttribute("FixtureVariant")~="legacy_transition",ActualTrainingAndStrengthCalculation=true,MemoryGainFunctionCopiedVerbatim=true}
 game:GetService("StudioTestService"):EndTest(result)
end)
task.delay(600,function()if not finished then finished=true;game:GetService("StudioTestService"):EndTest({Passed=false,Error="Diagnostic timeout"})end end)
