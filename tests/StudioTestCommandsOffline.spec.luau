-- Loaded by StudioTestCommandsOffline.py; never a Studio script.
local checks=0
local function check(value,message)
 checks+=1
 assert(value,message or ("Check "..checks))
end
local function signal()
 local self={listeners={}}
 function self:Connect(callback)
  local connection={Connected=true}
  function connection:Disconnect()self.Connected=false end
  table.insert(self.listeners,{connection,callback})
  return connection
 end
 function self:Fire(...)
  for _,entry in table.clone(self.listeners) do if entry[1].Connected then entry[2](...) end end
 end
 return self
end
local function newInstance(class,name)
 local self={ClassName=class,Name=name or class,children={},ChildAdded=signal()}
 if class=="TextChatCommand" then self.Triggered=signal() end
 if class=="RemoteEvent" then self.OnClientEvent=signal() end
 function self:IsA(kind)return self.ClassName==kind end
 function self:FindFirstChild(childName)
  for _,child in self.children do if child.Name==childName then return child end end
 end
 function self:WaitForChild(childName)return self:FindFirstChild(childName)end
 function self:GetChildren()return table.clone(self.children)end
 function self:GetFullName()return self.Parent and self.Parent:GetFullName().."."..self.Name or self.Name end
 function self:Destroy()self.Parent=nil;self.destroyed=true end
 return setmetatable(self,{
  __index=function(t,key)if key=="Parent" then return rawget(t,"_parent")end;return t:FindFirstChild(key)end,
  __newindex=function(t,key,value)
   if key~="Parent" then rawset(t,key,value);return end
   local old=rawget(t,"_parent")
   if old then local index=table.find(old.children,t);if index then table.remove(old.children,index) end end
   rawset(t,"_parent",value)
   if value then table.insert(value.children,t);value.ChildAdded:Fire(t) end
  end,
 })
end
local function child(parent,class,name)
 local value=newInstance(class,name);value.Parent=parent;return value
end
local function run(source,env)
 local fn,why=loadstring(source);assert(fn,why)
 setfenv(fn,setmetatable(env,{__index=getfenv()}));return fn()
end
local Requirements=run(SOURCES.requirements,{})
local Progression=run(SOURCES.progression,{
 game={ReplicatedStorage={Config={LevelRequirements={}}}},require=function()return Requirements end,
})
local function context(studio)
 local c={studio=studio,jobs={},delays={},messages={},warnings={},logs={},moves={},applyCalls=0,requireCalls=0}
 local root=newInstance("DataModel","game")
 local Players=child(root,"Players","Players");Players.PlayerAdded=signal();Players.PlayerRemoving=signal()
 local Chat=child(root,"TextChatService","TextChatService")
 local RS=child(root,"ReplicatedStorage","ReplicatedStorage");local remotes=child(RS,"Folder","Remotes")
 local SSS=child(root,"ServerScriptService","ServerScriptService")
 local configFolder=child(SSS,"Folder","Config");local settings=child(configFolder,"ModuleScript","StudioDebugConfig")
 local services=child(SSS,"Folder","Services");local dataModule=child(services,"ModuleScript","PlayerDataService")
 local modules=child(RS,"Folder","Modules");local progressionModule=child(modules,"ModuleScript","LevelProgression")
 local rsconfig=child(RS,"Folder","Config");local requirementsModule=child(rsconfig,"ModuleScript","LevelRequirements")
 local world=child(SSS,"Folder","World");local enemyModule=child(world,"ModuleScript","EnemyManager")
 local Workspace=newInstance("Workspace","Workspace")
 local frameMT={__mul=function(a,b)return {a=a,b=b}end}
 for w=1,2 do
  local map=child(Workspace,"Model",w==1 and "GeneratedMap" or "World2Map")
  local area=child(map,"Model","TrainingArea")
  local spawn=child(area,"SpawnLocation",w==1 and "SpawnLocation" or "World2LobbySpawn")
  spawn.CFrame=setmetatable({world=w},frameMT);spawn.Size={Y=1}
 end
 local p={Name="MemoryFixture",UserId=123,Parent=Players,CharacterAdded=signal(),attrs={
  Strength=123,Level=7,LevelProgress=17,CurrentWorld=1,CurrentStage=3,World2CurrentStage=1,
 },attributeSignals={}}
 function p:GetAttribute(name)return self.attrs[name]end
 function p:GetAttributeChangedSignal(name)
  self.attributeSignals[name]=self.attributeSignals[name] or signal();return self.attributeSignals[name]
 end
 function p:SetAttribute(name,value)
  local old=self.attrs[name];self.attrs[name]=value
  if old~=value and self.attributeSignals[name] then self.attributeSignals[name]:Fire() end
 end
 local character=newInstance("Model","Character")
 local humanoid=child(character,"Humanoid","Humanoid");humanoid.Health=100;humanoid.HipHeight=2
 local part=child(character,"BasePart","HumanoidRootPart");part.Size={Y=2}
 function character:FindFirstChildOfClass(kind)
  for _,item in self.children do if item.ClassName==kind then return item end end
 end
 function character:GetDescendants()return self:GetChildren()end
 function character:PivotTo(value)table.insert(c.moves,value)end
 p.Character=character
 function Players:GetPlayers()return {p}end
 function Players:GetPlayerByUserId(id)return id==p.UserId and p or nil end
 local RunService={IsStudio=function()return c.studio end}
 local game={ServerScriptService=SSS,ReplicatedStorage=RS}
 function game:GetService(name)return ({Players=Players,RunService=RunService,TextChatService=Chat,ReplicatedStorage=RS})[name]end
 local taskAdapter={
  spawn=function(callback)table.insert(c.jobs,callback)end,
  defer=function(callback)table.insert(c.jobs,callback)end,
  delay=function(_,callback)table.insert(c.delays,callback)end,
  wait=function()error("Unexpected fixture wait")end,
 }
 local saved={Strength=123,Level=7,LevelProgress=17,TotalStrengthEarned=456,
  DailyStrengthEarned=12,DailyDate="fixture",Win=9,RebirthCount=2}
 local sessions={[p]={Loaded=true,Data=table.clone(saved)}}
 local Data={}
 function Data.IsLoaded(player)local s=sessions[player];return s and s.Loaded end
 run(SOURCES.data,{PlayerDataService=Data,RunService=RunService,sessions=sessions,
  finite=function(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end})
 local actualApply=Data.ApplyStudioStartLevel
 Data.ApplyStudioStartLevel=function(...)c.applyCalls+=1;return actualApply(...)end
 local worlds={}
 for w=1,2 do
  worlds[w]={
   IsReady=function()return not c.worldNotReady end,
   Deactivate=function()c.deactivated=(c.deactivated or 0)+1 end,
   InitializePlayer=function(player,stage)player:SetAttribute(w==2 and "World2CurrentStage" or "CurrentStage",stage)end,
   Activate=function()c.activated=(c.activated or 0)+1 end,
  }
 end
 local Enemy={ForWorld=function(w)return worlds[w]end}
 local Config=run(SOURCES.config,{})
 check(Config.Start.Enabled and Config.Start.ChatCommandsEnabled and Config.Start.AutoApplyOnPlay==false,"Actual Start flags")
 local env={game=game,workspace=Workspace,task=taskAdapter,
  CFrame={new=function(...)return {...}end},Vector3={zero={}},
  print=function(...)table.insert(c.logs,table.concat({...}," "))end,
  warn=function(message)table.insert(c.warnings,message)end,
 }
 env.Instance={new=function(class)
  local value=newInstance(class)
  if class=="RemoteEvent" then
   function value:FireClient(player,message)
    check(player==p,"Reply recipient")
    table.insert(c.messages,message);self.OnClientEvent:Fire(message)
   end
  end
  return value
 end}
 env.require=function(module)
  c.requireCalls+=1
  if c.failModule==module.Name then error("fixture initialization failure") end
  return ({[settings]=Config,[dataModule]=Data,[progressionModule]=Progression,
   [requirementsModule]=Requirements,[enemyModule]=Enemy})[module]
 end
 function c:flush()
  while #self.jobs>0 do local job=table.remove(self.jobs,1);job()end
 end
 function c:server()run(SOURCES.server,env)end
 function c:client()run(SOURCES.client,env)end
 function c:send(message)
  local command=Chat:FindFirstChild("StudioTestCommand");check(command~=nil,"Registered /test")
  local before=#self.messages;command.Triggered:Fire({UserId=p.UserId},message)
  check(#self.messages==before+1,"Exactly one reply")
  return self.messages[#self.messages]
 end
 function c:chatChannel()
  local channels=Chat:FindFirstChild("TextChannels") or child(Chat,"Folder","TextChannels")
  local channel=child(channels,"TextChannel","RBXGeneral");channel.messages={}
  function channel:DisplaySystemMessage(message)table.insert(self.messages,message)end
  return channel
 end
 if SOURCES.hud~="" then
  local hud={totalLabel={},levelLabel={},amountLabel={},fill={}}
  local huEnv={player=p,Requirements=Requirements,Format={Format=tostring},task=taskAdapter,
   script={Parent=true},UDim2={fromScale=function(x,y)return {X=x,Y=y}end}}
  for key,value in hud do huEnv[key]=value end
  run(SOURCES.hud,huEnv);c.hud=hud
 end
 c.player=p;c.Chat=Chat;c.remotes=remotes;c.Data=Data;c.sessions=sessions;c.saved=saved;c.Config=Config;c.env=env
 return c
end

local c=context(true)
c:client() -- Client can start before the server creates the result Remote.
local channel=c:chatChannel()
local duplicate=child(c.Chat,"TextChatCommand","StudioTestCommand");duplicate.PrimaryAlias="/test"
c:server()
check(duplicate.destroyed,"Stale named registration replaced")
check(#c.Chat:GetChildren()==2,"One command plus TextChannels")
check(c.Chat.StudioTestCommand.PrimaryAlias=="/test","Alias")
check(#c.Chat.StudioTestCommand.Triggered.listeners==1,"One Triggered connection")
check(c:send('/test help'):find('level <n>',1,true),"Help before dependency loading")
check(c:send('/test status'):find('initializing',1,true),"Status before dependency loading")
check(c:send('/test level 45'):find('TEST ERROR',1,true),"Initializing dependency is not silent")
c:flush()
check(c.applyCalls==0 and #c.moves==0,"AutoApplyOnPlay=false")
local attributes=table.clone(c.player.attrs)
check(c:send('/test level 45'):find('Level=45',1,true),"Level command")
c:flush()
check(c.player.attrs.Level==45 and c.player.attrs.LevelProgress==0,"Authoritative level and progress")
check(Progression.Advance(1,0,c.player.attrs.Strength)==45,"Existing requirement curve")
check(c.player.attrs.CurrentWorld==attributes.CurrentWorld and c.player.attrs.CurrentStage==attributes.CurrentStage and #c.moves==0,"Level-only never moves")
local session=c.sessions[c.player]
check(session.StudioStartOverride.Level==7 and session.StudioStartOverride.LevelProgress==17,"Original snapshot")
local saveOK,saveReason=c.Data.Save(c.player)
check(saveOK and saveReason=="StudioRuntimeOverride","Actual Save guard excludes temporary data")
if c.hud then check(c.hud.levelLabel.Text=="Lv.45" and c.hud.fill.Size.X==0,"Actual HUD update from changed attributes")end
c.player.CharacterAdded:Fire(c.player.Character);c:flush();check(#c.moves==0,"Level-only respawn does not request a teleport")
check(c:send('/test status'):find('Dependencies=ready',1,true),"Ready status")
c:flush()
check(#channel.messages==#c.messages,"Remote to Client to chat system-message path")
check(c:send('/test reset'):find('Runtime override reset',1,true),"Reset")
for key,value in c.saved do check(session.Data[key]==value,"Restored "..key)end
check(not session.StudioStartOverride and #c.moves==0,"Level-only reset retains position")
check(c:send('/test start 45 2 1'):find('World=2 Stage=1',1,true),"Start command")
check(c.player.attrs.CurrentWorld==2 and c.player.attrs.World2CurrentStage==1 and #c.moves==1,"World API and lobby placement")
check(c:send('/test reset'):find('TEST OK',1,true),"Start reset")
check(c.player.attrs.CurrentWorld==1 and c.player.attrs.CurrentStage==3 and #c.moves==2,"Original World/Stage restored")
for _,message in {'/test world 2','/test stage 4','/test default','/test reset'} do check(c:send(message):find('TEST OK',1,true),message)end
for _,message in {'/test level nope','/test level 0','/test level 10001','/test start 45 3 1','/test start 45 2 11','/test unknown'} do
 local count=c.applyCalls;check(c:send(message):find('TEST ERROR',1,true),message);check(c.applyCalls==count,"Invalid input does not apply")
end
session.Loaded=false
check(c:send('/test level 45'):find('Player data is not ready',1,true),"No fabricated loaded data")
session.Loaded=true
c.worldNotReady=true
check(c:send('/test start 45 2 1'):find('World combat is initializing',1,true),"World startup not silent")
check(c:send('/test reset'):find('TEST ERROR',1,true),"Reset failure visible")
c.worldNotReady=false
check(c:send('/test reset'):find('TEST OK',1,true),"Reset Busy released after failure")
local originalRestore=c.Data.RestoreStudioStartOverride
c:send('/test level 45')
c.Data.RestoreStudioStartOverride=function()error('fixture restore failure')end
check(c:send('/test reset'):find('fixture restore failure',1,true),"Unexpected execution failure replies")
c.Data.RestoreStudioStartOverride=originalRestore
check(c:send('/test reset'):find('TEST OK',1,true),"Reset remains recoverable")
c:flush()

local failed=context(true);failed.failModule='PlayerDataService';failed:server();failed:flush()
check(#failed.warnings>0,"Initialization error Output")
check(failed:send('/test help'):find('TEST:',1,true),"Help survives failed require")
check(failed:send('/test status'):find('fixture initialization failure',1,true),"Status names failed dependency")
check(failed:send('/test level 45'):find('TEST ERROR',1,true) and failed.applyCalls==0,"Failed require rejects mutation")
local brokenConfig=context(true);brokenConfig.failModule='StudioDebugConfig';brokenConfig:server()
check(not brokenConfig.Chat.StudioTestCommand and #brokenConfig.warnings==1,"Config failure visible in Output")
local missingChannel=context(true);missingChannel:client();missingChannel:server();missingChannel:flush()
missingChannel:send('/test help');missingChannel:flush()
check(#missingChannel.warnings>0,"Missing chat channel logs fallback")
local late=missingChannel:chatChannel();missingChannel:send('/test status');missingChannel:flush()
check(#late.messages==1,"Later channel recovers")
local production=context(false);production:server();production:client();production:flush()
check(not production.Chat.StudioTestCommand and #production.remotes:GetChildren()==0 and production.requireCalls==0,"Outside Studio no registration, Remote or requires")
c.studio=false
local count=#c.messages;c.Chat.StudioTestCommand.Triggered:Fire({UserId=c.player.UserId},'/test level 45')
check(#c.messages==count,"Triggered Studio guard")
print('PASS StudioTestCommandsOffline: '..checks..' assertions (simulation only)')
