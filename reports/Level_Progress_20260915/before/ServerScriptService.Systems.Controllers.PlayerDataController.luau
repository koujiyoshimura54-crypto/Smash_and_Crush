local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local AUTOSAVE_INTERVAL=90
local MAX_CONCURRENT_SAVES=6
local winConnections=setmetatable({}, {__mode="k"})

local function load(player)
 for attempt=1,3 do
  local ok=Data.Load(player)
  if ok then return true end
  task.wait(attempt)
 end
 warn("PlayerData unavailable for "..player.Name.."; session will not be saved")
 return false
end

local function bindWin(player)
 if winConnections[player] then return end
 winConnections[player]=player:GetAttributeChangedSignal("Win"):Connect(function()
  if Data.IsLoaded(player) then
   Data.SetWin(player,player:GetAttribute("Win"))
  end
 end)
end

local function saveLatest(player,timeout)
 local deadline=os.clock()+(timeout or 30)
 for attempt=1,3 do
  Data.WaitForSave(player,math.max(0,deadline-os.clock()))
  local ok=Data.Save(player)
  local session=Data.Get(player)
  if not session or not session.Loaded then return end
  if ok and not session.Dirty then return end
  if os.clock()>=deadline then return end
  task.wait(0.05)
 end
end

local function saveBounded(players,timeout,flush)
 local total=#players
 if total==0 then return true end
 local nextIndex=0
 local completed=0
 local workers=math.min(MAX_CONCURRENT_SAVES,total)
 local function worker()
  while true do
   nextIndex+=1
   local index=nextIndex
   local player=players[index]
   if not player then return end
   if Data.IsLoaded(player) then
    if flush then saveLatest(player,timeout or 30)
    else Data.Save(player);Data.WaitForSave(player,timeout or 30) end
   end
   completed+=1
  end
 end
 for _=1,workers do task.spawn(worker) end
 local deadline=os.clock()+(timeout or 30)+math.ceil(total/workers)*10
 while completed<total and os.clock()<deadline do task.wait(0.05) end
 return completed>=total
end

local function currentPlayers()
 local result={}
 for _,player in ipairs(Players:GetPlayers()) do
  if Data.IsLoaded(player) then result[#result+1]=player end
 end
 return result
end

Players.PlayerAdded:Connect(function(player)
 bindWin(player)
 task.spawn(load,player)
end)
for _,player in ipairs(Players:GetPlayers()) do
 bindWin(player)
 task.spawn(load,player)
end

Players.PlayerRemoving:Connect(function(player)
 local c=winConnections[player]
 if c then c:Disconnect(); winConnections[player]=nil end
 if Data.IsLoaded(player) then
  saveLatest(player,30)
 end
 Data.Release(player)
end)

task.spawn(function()
 while true do
  task.wait(AUTOSAVE_INTERVAL)
  saveBounded(currentPlayers(),30)
 end
end)

game:BindToClose(function()
 saveBounded(currentPlayers(),30,true)
end)

