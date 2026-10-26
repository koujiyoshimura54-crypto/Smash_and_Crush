local RS=game:GetService("ReplicatedStorage")
local service=require(game.ServerScriptService.Services.ForgeService)
local folder=RS:WaitForChild("Remotes")
local remote=folder:FindFirstChild("ForgeRequest") or Instance.new("RemoteFunction")
remote.Name="ForgeRequest";remote.Parent=folder
local last=setmetatable({},{__mode="k"})
remote.OnServerInvoke=function(player,request)
 local now=os.clock()
 if last[player] and now-last[player]<0.12 then return {Success=false,Code="RateLimited",State=service.State(player)} end
 last[player]=now
 return service.Request(player,request)
end
