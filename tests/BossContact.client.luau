-- Temporary native observer/input fixture. No OS input or camera changes.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local packets={}
for _,w in {1,2} do
 RS.Remotes:WaitForChild("GameRemotes"):WaitForChild(w==1 and "CombatState" or "World2CombatState").OnClientEvent:Connect(function(d)
  if d.Type=="BossGauge" or d.Type=="BossInitialize" then packets[w]=packets[w] or {};packets[w][d.Stage]=d end
 end)
end
local function run(action,value)
 if action=="Ready" then return true
 elseif action=="Tap" then RS.Remotes:WaitForChild("AutoTapRequest"):FireServer("Tap");task.wait(.1);return true
 elseif action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(value==2 and "ToWorld2" or "ReturnWorld1");return true
 elseif action=="Gauge" then
  task.wait(.15)
  local folder=workspace:FindFirstChild(value.World==1 and "Enemies" or "World2Enemies")
  local owner=folder and folder:FindFirstChild("Owner_"..p.UserId)
  local actor=owner and owner:FindFirstChild(("Stage%02d_Enemy"):format(value.Stage))
  local gui=actor and actor:FindFirstChild("PersonalGauge",true)
  return {Packet=packets[value.World] and packets[value.World][value.Stage],
   Text=gui and gui.HPLabel.Text,Fill=gui and gui.HPBar.Fill.Size.X.Scale,
   Enabled=gui and gui.Enabled}
 end
end
RS:WaitForChild("__BossQARequest").OnClientEvent:Connect(function(id,action,value)
 local ok,result=pcall(run,action,value)
 RS.__BossQAReply:FireServer(id,{OK=ok,Value=result})
end)
