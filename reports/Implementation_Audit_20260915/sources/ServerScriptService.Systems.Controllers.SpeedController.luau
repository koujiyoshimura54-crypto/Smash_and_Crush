local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Speed=require(game.ServerScriptService.Services:WaitForChild("SpeedService"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local Pass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local function remote(name,class)
 local r=RS.Remotes:FindFirstChild(name)
 if not r then r=Instance.new(class);r.Name=name;r.Parent=RS.Remotes end
 assert(r.ClassName==class)
 return r
end
local purchase=remote("SpeedPurchaseRequest","RemoteEvent")
local stateRemote=remote("SpeedInventoryState","RemoteFunction")
local prompt=remote("SpeedPremiumPrompt","RemoteEvent")
local last=setmetatable({}, {__mode="k"})
local bindings={}
local function publish(player)
 if player.Parent==Players then purchase:FireClient(player,{State=Speed.Apply(player)}) end
end
stateRemote.OnServerInvoke=function(player) return Speed.GetState(player) end
local function allowed(player)
 local now=os.clock()
 if last[player] and now-last[player]<.3 then return false end
 last[player]=now;return true
end
purchase.OnServerEvent:Connect(function(player,id)
 if not allowed(player) then
  purchase:FireClient(player,{Success=false,Code="RequestInProgress",State=Speed.GetState(player)});return
 end
 local ok,code=Speed.Purchase(player,id)
 if player.Parent==Players then purchase:FireClient(player,{Success=ok,Code=code,State=Speed.GetState(player)}) end
end)
prompt.OnServerEvent:Connect(function(player,action)
 if action~="Prompt" then prompt:FireClient(player,{Success=false,Code="InvalidRequest"});return end
 if not allowed(player) then prompt:FireClient(player,{Success=false,Code="RequestInProgress"});return end
 local ok,code=Pass.PromptPremiumSpeed(player)
 if player.Parent==Players then prompt:FireClient(player,{Success=ok,Code=code}) end
end)
local function bind(player)
 local connections={}
 bindings[player]=connections
 local function characterAdded(character)
  task.spawn(function()
   local h=character:WaitForChild("Humanoid",10)
   if h and player.Character==character then publish(player) end
  end)
 end
 connections[#connections+1]=player.CharacterAdded:Connect(characterAdded)
 connections[#connections+1]=player:GetAttributeChangedSignal("HasPremiumSpeed"):Connect(function() publish(player) end)
 if player.Character then characterAdded(player.Character) end
 task.spawn(function()
  while player.Parent==Players and not Data.IsLoaded(player) do task.wait(.25) end
  if player.Parent~=Players then return end
  publish(player)
  while player.Parent==Players do
   Pass.RefreshPremiumSpeed(player)
   publish(player)
   task.wait(30)
  end
 end)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
Players.PlayerRemoving:Connect(function(p)
 for _,c in bindings[p] or {} do c:Disconnect() end
 bindings[p]=nil;last[p]=nil
end)

