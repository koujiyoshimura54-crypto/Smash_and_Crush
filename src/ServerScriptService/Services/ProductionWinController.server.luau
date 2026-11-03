-- Public servers consume only authenticated durable directives; no client remote.
local RunService=game:GetService("RunService")
if RunService:IsStudio() then return end
local Players=game:GetService("Players")
local Messaging=game:GetService("MessagingService")
local Data=require(script.Parent.PlayerDataService)
local Win=require(script.Parent.ProductionWinService)
local busy={}
local function sync(player)
 if busy[player] then return end
 busy[player]=true
 local ok,err=pcall(Data.SyncProductionWin,player)
 busy[player]=nil
 if not ok then warn("[AdminWin] Live sync retry: "..tostring(err)) end
end
task.spawn(function()
 local subscribed=false
 repeat
  subscribed=pcall(function()
   Messaging:SubscribeAsync(Win.Topic,function(message)
    local id=type(message.Data)=="table" and message.Data.UserId
    local p=type(id)=="number" and Players:GetPlayerByUserId(id)
    if p then task.spawn(sync,p) end
   end)
  end)
  if not subscribed then task.wait(30) end
 until subscribed
end)
task.spawn(function()
 while true do
  for _,p in Players:GetPlayers() do task.spawn(sync,p) end
  task.wait(15)
 end
end)
Players.PlayerRemoving:Connect(function(p)busy[p]=nil end)
