-- Isolated native Play fixture only. Requires temporary in-memory service redirects.
assert(game:GetService("RunService"):IsStudio() and game.ReplicatedStorage:FindFirstChild("__WallPromptMemory"))
local RS=game.ReplicatedStorage
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Wall=require(game.ServerScriptService.World.Stage1WallManager)
local q=RS:WaitForChild("__WallPromptQA")
local taps,toggles=0,0
RS.Remotes:WaitForChild("AutoTapRequest").OnServerEvent:Connect(function(_,action)
 if action=="Tap" then taps+=1 elseif action=="Toggle" then toggles+=1 end
end)
local call=Instance.new("BindableFunction");call.Name="Server";call.Parent=q
local function player() return assert(game.Players:GetPlayers()[1],"No test player") end
local function position(p,distance)
 local wall=workspace.GeneratedMap.BattleCorridor.Stage01["Stage1.1"].Wall
 local floor=workspace.GeneratedMap.BattleCorridor.Stage01.Floor
 local c=p.Character;local root=c.HumanoidRootPart;local hum=c:FindFirstChildOfClass("Humanoid")
 local y=floor.Position.Y+floor.Size.Y/2+hum.HipHeight+root.Size.Y/2
 local pos=Vector3.new(wall.Position.X,y,wall.Position.Z-distance)
 c:PivotTo(CFrame.lookAt(pos,Vector3.new(wall.Position.X,y,wall.Position.Z)))
 root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=true
end
call.OnInvoke=function(action,value)
 local p=player();assert(Data.IsLoaded(p),"Data not loaded")
 if action=="Prepare" then
  local s=Data.Get(p);s.Data.Level=2;s.Data.Strength=10;s.Data.TutorialCompleted=false
  p:SetAttribute("Level",2);p:SetAttribute("Strength",10);p:SetAttribute("TutorialCompleted",false)
  Data.SetAutoTapEnabled(p,false);Enemy.InitializePlayer(p);position(p,4)
 elseif action=="Move" then position(p,value)
 elseif action=="Auto" then Data.SetAutoTapEnabled(p,value)
 elseif action=="TrainingPhase" then
  Data.Get(p).Data.Strength=4;p:SetAttribute("Strength",4);p:SetAttribute("Level",1)
 elseif action=="Reset" then
  p:SetAttribute("TutorialResetSequence",(p:GetAttribute("TutorialResetSequence") or 0)+1)
  Enemy.InitializePlayer(p)
 elseif action=="Death" then p.Character.HumanoidRootPart.Anchored=false;p.Character.Humanoid.Health=0
 elseif action=="Busy" then p:SetAttribute("RunReturnBusy",value)
 elseif action=="Completed" then p:SetAttribute("TutorialCompleted",value)
 elseif action=="Stage" then Enemy.InitializePlayer(p,value)
 elseif action=="World" then p:SetAttribute("CurrentWorld",value)
 elseif action=="SendState" then Enemy.SendState(p)
 elseif action~="State" then error("Unknown fixture action") end
 return {Taps=taps,Toggles=toggles,Wall=Wall.GetSnapshot(p),Fighting=p:GetAttribute("IsFighting"),
  Auto=p:GetAttribute("AutoTapEnabled"),Stage=p:GetAttribute("CurrentStage"),World=p:GetAttribute("CurrentWorld"),
  Level=p:GetAttribute("Level"),Strength=p:GetAttribute("Strength"),Character=p.Character and p.Character.Name}
end
q:SetAttribute("ServerReady",true)
