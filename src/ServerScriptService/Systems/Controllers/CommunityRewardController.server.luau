local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Service=require(game.ServerScriptService.Services.CommunityRewardService)
local state=RS.Remotes:WaitForChild("CommunityRewardState")
local claim=RS.Remotes:WaitForChild("CommunityRewardClaim")
local last=setmetatable({}, {__mode="k"})
state.OnServerInvoke=function(p)return Service.GetState(p,true)end
claim.OnServerEvent:Connect(function(p)
 local now=os.clock()
 if last[p] and now-last[p]<.5 then return end
 last[p]=now
 local success,code,result=Service.Claim(p)
 if p.Parent==Players then claim:FireClient(p,{Success=success,Code=code,Result=result,State=Service.GetState(p)}) end
end)
Players.PlayerRemoving:Connect(function(p)last[p]=nil end)
task.spawn(function()
 while task.wait(5) do
  for _,p in Players:GetPlayers() do
   task.spawn(function()
    local s=Service.GetState(p,true)
    if p.Parent==Players then claim:FireClient(p,{State=s}) end
   end)
  end
 end
end)