local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Config=require(game.ServerScriptService.Config:WaitForChild("StudioDebugConfig")).Start
if not Config or Config.Enabled~=true then return end
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Progression=require(game.ReplicatedStorage.Modules:WaitForChild("LevelProgression"))
local Requirements=require(game.ReplicatedStorage.Config:WaitForChild("LevelRequirements"))
local Stage=require(game.ServerScriptService.World:WaitForChild("StageManager"))
local Enemy=require(game.ServerScriptService.World:WaitForChild("EnemyManager"))
local connections=setmetatable({}, {__mode="k"})
local function integer(value,min,max) return typeof(value)=="number" and value==value and value%1==0 and value>=min and value<=max and value or nil end
local level=Config.StartLevel==nil and nil or integer(Config.StartLevel,1,Requirements.MaxLevel)
local world=Config.StartWorld==nil and nil or integer(Config.StartWorld,1,2)
local stage=Config.StartStage==nil and nil or integer(Config.StartStage,1,10)
if Config.StartLevel~=nil and not level then warn("Studio start rejected invalid StartLevel");return end
if Config.StartWorld~=nil and not world then warn("Studio start rejected invalid StartWorld");return end
if Config.StartStage~=nil and not stage then warn("Studio start rejected invalid StartStage");return end
local function minimumStrength(target)
 if target<=1 then return 0 end
 local high=1
 while high<9007199254740991 do local calculated=Progression.Advance(1,0,high);if calculated and calculated>=target then break end;high=math.min(9007199254740991,high*2) end
 local low=0
 while low<high do local mid=math.floor((low+high)/2);local calculated=Progression.Advance(1,0,mid);if calculated and calculated>=target then high=mid else low=mid+1 end end
 return low
end
local startStrength=level and minimumStrength(level)
local function spawnFor(targetWorld)
 if targetWorld==2 then local map=workspace:FindFirstChild("World2Map");local area=map and map:FindFirstChild("TrainingArea");return area and area:FindFirstChild("World2LobbySpawn") end
 local map=workspace:FindFirstChild("GeneratedMap");local area=map and map:FindFirstChild("TrainingArea");return area and area:FindFirstChild("SpawnLocation")
end
local function place(player,character)
 if not world or player.Character~=character then return end
 local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10);local root=character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart",10);local spawn=spawnFor(world)
 if not humanoid or not root or not spawn or not spawn:IsA("BasePart") then return end
 local previous=player:GetAttribute("CurrentWorld")==2 and 2 or 1;Enemy.ForWorld(previous).Deactivate(player);player:SetAttribute("CurrentWorld",world);Stage.ForWorld(world).InitializePlayer(player,stage or 1)
 character:PivotTo(spawn.CFrame*CFrame.new(0,spawn.Size.Y*.5+humanoid.HipHeight+root.Size.Y*.5+.1,0))
 for _,part in character:GetDescendants() do if part:IsA("BasePart") then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end end
 Enemy.ForWorld(world).Activate(player)
end
local function setup(player)
 task.spawn(function()
  while player.Parent==Players and not Data.IsLoaded(player) do task.wait() end
  if player.Parent~=Players then return end
  if level then local ok,reason=Data.ApplyStudioStartLevel(player,startStrength,level);if not ok then warn("Studio start level failed: "..tostring(reason));return end end
  if world then player:SetAttribute("HighestUnlockedWorld",math.max(world,tonumber(player:GetAttribute("HighestUnlockedWorld")) or 1)) end
  local old=connections[player];if old then old:Disconnect() end
  connections[player]=player.CharacterAdded:Connect(function(character) task.defer(place,player,character) end)
  if player.Character then task.defer(place,player,player.Character) end
 end)
end
Players.PlayerAdded:Connect(setup);for _,player in Players:GetPlayers() do setup(player) end
Players.PlayerRemoving:Connect(function(player) local c=connections[player];if c then c:Disconnect();connections[player]=nil end end)
