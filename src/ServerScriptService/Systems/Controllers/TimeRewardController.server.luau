local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Service=require(game.ServerScriptService.Services.TimeRewardService)
local state=RS.Remotes:WaitForChild("TimeRewardState")
local claim=RS.Remotes:WaitForChild("TimeRewardClaim")
local last=setmetatable({}, {__mode="k"})
state.OnServerInvoke=function(p) return Service.GetState(p) end
claim.OnServerEvent:Connect(function(p,id)
 local now=os.clock()
 if last[p] and now-last[p]<.2 then return end
 last[p]=now
 local success,code,result=Service.Claim(p,id)
 if p.Parent==Players then
  claim:FireClient(p,{Success=success,Code=code,RewardId=typeof(id)=="string" and #id<=64 and id or nil,Result=result,State=Service.GetState(p)})
 end
end)
Players.PlayerRemoving:Connect(function(p) last[p]=nil end)
task.spawn(function()
 while task.wait(1) do
  for _,p in Players:GetPlayers() do claim:FireClient(p,{State=Service.GetState(p)}) end
 end
end)
