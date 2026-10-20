local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Chat=game:GetService("TextChatService")
local RS=game:GetService("ReplicatedStorage")
local configured,settings=pcall(require,game.ServerScriptService.Config.StudioDebugConfig)
if not configured then warn("[StudioTest] Config initialization failed: "..tostring(settings));return end
local Config=settings.Start
if not Config or Config.Enabled~=true then warn("[StudioTest] Start.Enabled is not true; /test is disabled");return end
-- Register chat/replies before requiring gameplay modules: their failures must be visible.
local Data,Progression,Requirements,Enemy
local Placement=require(game.ServerScriptService.Services.LobbySpawnService)
local dependencyState="initializing"
local dependencyError
local remotes=RS:FindFirstChild("Remotes") or Instance.new("Folder");remotes.Name="Remotes";remotes.Parent=RS
local remote=remotes:FindFirstChild("StudioTestCommandResult")
if remote and not remote:IsA("RemoteEvent") then warn("[StudioTest] StudioTestCommandResult must be a RemoteEvent");return end
remote=remote or Instance.new("RemoteEvent");remote.Name="StudioTestCommandResult";remote.Parent=remotes
local states=setmetatable({},{__mode="k"});local connections=setmetatable({},{__mode="k"})
local function response(p,text)
 print("[StudioTest] "..p.Name.." "..tostring(text))
 local ok,why=pcall(function()remote:FireClient(p,tostring(text))end)
 if not ok then warn("[StudioTest] Reply failed: "..tostring(why)) end
end
local function integer(text,min,max,label)local n=tonumber(text);if not n or n%1~=0 or n<min or n>max then return nil,("TEST ERROR: %s must be between %d and %d"):format(label,min,max) end;return n end
local function strengthFor(level)
 if level<=1 then return 0 end
 local low,high=0,1
 while high<9007199254740991 do local v=Progression.Advance(1,0,high);if v and v>=level then break end;high=math.min(9007199254740991,high*2) end
 while low<high do local mid=math.floor((low+high)/2);local v=Progression.Advance(1,0,mid);if v and v>=level then high=mid else low=mid+1 end end
 return low
end
local function stageOf(p,w)local n=p:GetAttribute(w==2 and "World2CurrentStage" or "CurrentStage");return typeof(n)=="number" and math.clamp(math.floor(n),1,10) or 1 end
local function spawnFor(w)local map=workspace:FindFirstChild(w==2 and "World2Map" or "GeneratedMap");local area=map and map:FindFirstChild("TrainingArea");return area and area:FindFirstChild(w==2 and "World2LobbySpawn" or "SpawnLocation") end
local function move(p,w,s,ch)
 ch=ch or p.Character;local hum=ch and ch:FindFirstChildOfClass("Humanoid");local root=ch and ch:FindFirstChild("HumanoidRootPart");local spawn=spawnFor(w)
 if p.Character~=ch or not hum or hum.Health<=0 or not root or not spawn then return false,"TEST ERROR: Character is not ready" end
 local previous=Enemy.ForWorld(p:GetAttribute("CurrentWorld")==2 and 2 or 1);local target=Enemy.ForWorld(w)
 if not previous.IsReady() or not target.IsReady() then return false,"TEST ERROR: World combat is initializing" end
 previous.Deactivate(p);p:SetAttribute("CurrentWorld",w);target.InitializePlayer(p,s)
 local placed,why=Placement.MoveToLobby(p,ch,w);if not placed then return false,"TEST ERROR: "..tostring(why) end
 target.Activate(p);return true
end
local function apply(p,level,world,stage,levelOnly)
 if not RunService:IsStudio() then return false,"TEST ERROR: Studio only" end
 if not Data.IsLoaded(p) then return false,"TEST ERROR: Player data is not ready" end
 local st=states[p] or {};states[p]=st
 if st.Busy then return false,"TEST ERROR: Another test command is processing" end
 local ch=p.Character;if not ch or not ch:FindFirstChildOfClass("Humanoid") or not ch:FindFirstChild("HumanoidRootPart") then return false,"TEST ERROR: Character is initializing" end
 st.Busy=true
 local ok,a,b=pcall(function()
  local currentWorld=p:GetAttribute("CurrentWorld")==2 and 2 or 1
  if not st.Active then st.Original={World=currentWorld,Stage=stageOf(p,currentWorld)};st.Moved=false end
  local w=world or currentWorld;local s=stage or stageOf(p,currentWorld)
  if level then local changed,why=Data.ApplyStudioStartLevel(p,strengthFor(level),level);if not changed then return false,"TEST ERROR: "..tostring(why) end;st.Active=true end
  if not levelOnly then
   st.Moved=true;st.World=w;st.Stage=s
   local moved,why=move(p,w,s,ch);if not moved then return false,why end
  end
  st.Active=true;st.World=w;st.Stage=s
  return true,("TEST OK: Level=%d World=%d Stage=%d"):format(p:GetAttribute("Level") or 1,w,s)
 end)
 st.Busy=false;if not ok then return false,"TEST ERROR: "..tostring(a) end;return a,b
end
local function reset(p)
 local st=states[p];if not st or not st.Active then return true,"TEST OK: Override is not active" end
 if st.Busy then return false,"TEST ERROR: Another test command is processing" end
 st.Busy=true
 local called,ok,why=pcall(function()
  local restored,reason=Data.RestoreStudioStartOverride(p)
  if restored and st.Moved then return move(p,st.Original.World,st.Original.Stage) end
  return restored,reason
 end)
 st.Busy=false
 if not called then return false,"TEST ERROR: "..tostring(ok) end
 if not ok then return false,"TEST ERROR: "..tostring(why) end;st.Active=false;return true,"TEST OK: Runtime override reset"
end
local function execute(p,message)
 if not RunService:IsStudio() then return false,"TEST ERROR: Studio only" end
 local w={} for word in message:gmatch("%S+") do w[#w+1]=word end;if w[1] and w[1]:lower()=="/test" then table.remove(w,1) end
 local sub=w[1] and w[1]:lower() or "help";if tonumber(sub) then table.insert(w,1,"start");sub="start" end
 if sub=="help" then return true,"TEST: /test [start] <level> <world> <stage> | level <n> | world <n> | stage <n> | status | default | reset | help" end
 local cw=p:GetAttribute("CurrentWorld")==2 and 2 or 1
 if sub=="status" then return true,("TEST: Level=%d Strength=%.0f World=%d Stage=%d Dependencies=%s"):format(p:GetAttribute("Level") or 1,p:GetAttribute("Strength") or 0,cw,stageOf(p,cw),dependencyError or dependencyState) end
 if dependencyState~="ready" then return false,"TEST ERROR: Dependencies "..(dependencyError or dependencyState).."; see Server Output" end
 if sub=="reset" then return reset(p) end
 local level,world,stage,err
 if sub=="default" then local d=Config.Defaults or {};level,world,stage=d.Level,d.World,d.Stage
 elseif sub=="start" then level,err=integer(w[2],1,Requirements.MaxLevel,"Level");if not level then return false,err end;world,err=integer(w[3],1,2,"World");if not world then return false,err end;stage,err=integer(w[4],1,10,"Stage");if not stage then return false,err end
 elseif sub=="level" then level,err=integer(w[2],1,Requirements.MaxLevel,"Level");if not level then return false,err end;return apply(p,level,nil,nil,true)
 elseif sub=="world" then world,err=integer(w[2],1,2,"World");if not world then return false,err end
 elseif sub=="stage" then stage,err=integer(w[2],1,10,"Stage");if not stage then return false,err end
 else return false,"TEST ERROR: Unknown command; use /test help" end
 return apply(p,level,world,stage)
end
local function setup(p)connections[p]=Placement.Spawned:Connect(function(owner,ch)if owner~=p or p.Character~=ch then return end;local st=states[p];if st and st.Active and st.Moved then
 local called,ok,why=pcall(move,p,st.World,st.Stage,ch)
 if not called or not ok then response(p,"TEST ERROR: Respawn placement: "..tostring(called and why or ok)) end
end end)end
Players.PlayerAdded:Connect(setup);for _,p in Players:GetPlayers() do setup(p) end
Players.PlayerRemoving:Connect(function(p)local c=connections[p];if c then c:Disconnect() end;connections[p]=nil;states[p]=nil end)
local function auto(p)task.spawn(function()while p.Parent==Players and not Data.IsLoaded(p) do task.wait() end;if p.Parent==Players then local d=Config.Defaults or {};local ok,text=apply(p,d.Level,d.World,d.Stage);if not ok then warn(text) end end end)end
if Config.ChatCommandsEnabled==true then
 for _,old in Chat:GetChildren() do if old.Name=="StudioTestCommand" then old:Destroy() end end
 local command=Instance.new("TextChatCommand");command.Name="StudioTestCommand";command.PrimaryAlias="/test"
 command.Triggered:Connect(function(source,message)
  if not RunService:IsStudio() or not source then return end
  local p=Players:GetPlayerByUserId(source.UserId);if not p then return end
  local called,ok,text=pcall(execute,p,message)
  if not called then text="TEST ERROR: "..tostring(ok) end
  response(p,text)
 end)
 command.Parent=Chat
 print("[StudioTest] Registered /test")
else warn("[StudioTest] Start.ChatCommandsEnabled is not true; /test is disabled")
end
task.delay(10,function()
 if dependencyState=="initializing" then warn("[StudioTest] Dependencies still initializing at "..tostring(dependencyError).."; /test help and status remain available") end
end)
task.spawn(function()
 local function load(module)
  dependencyError=module:GetFullName()
  return require(module)
 end
 local ok,why=pcall(function()
  Data=load(game.ServerScriptService.Services.PlayerDataService)
  Progression=load(RS.Modules.LevelProgression)
  Requirements=load(RS.Config.LevelRequirements)
  Enemy=load(game.ServerScriptService.World.EnemyManager)
  assert(type(Data.ApplyStudioStartLevel)=="function" and type(Data.RestoreStudioStartOverride)=="function","Missing Studio override API")
  assert(type(Progression.Advance)=="function" and type(Requirements.MaxLevel)=="number" and type(Enemy.ForWorld)=="function","Missing progression/world API")
 end)
 if not ok then dependencyState="failed";dependencyError=tostring(dependencyError)..": "..tostring(why);warn("[StudioTest] Initialization failed: "..dependencyError);return end
 dependencyState="ready";dependencyError=nil
 print("[StudioTest] Dependencies ready; automatic start="..tostring(Config.AutoApplyOnPlay==true))
 if Config.AutoApplyOnPlay==true then Players.PlayerAdded:Connect(auto);for _,p in Players:GetPlayers() do auto(p) end end
end)
