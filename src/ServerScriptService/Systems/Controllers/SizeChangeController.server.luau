local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Config=require(RS.Config:WaitForChild("SizeChangeConfig"))
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local remotes=RS:WaitForChild("Remotes")
local request=remotes:FindFirstChild("SizeChangeRequest") or Instance.new("RemoteEvent")
request.Name="SizeChangeRequest";request.Parent=remotes
local busy=setmetatable({}, {__mode="k"})
request.OnServerEvent:Connect(function(player,tier)
 if busy[player] then request:FireClient(player,{Code="Busy",Tier=player:GetAttribute("SelectedSizeTier") or 0});return end
 if typeof(tier)~="number" or tier%1~=0 or tier<Config.MinTier or tier>Config.MaxTier then request:FireClient(player,{Code="InvalidRequest",Tier=player:GetAttribute("SelectedSizeTier") or 0});return end
 busy[player]=true
 local ok,code,newTier,newWin=Data.ChangeSelectedSize(player,tier,Config)
 busy[player]=nil
 request:FireClient(player,{Code=code or (ok and "Success" or "Failed"),Tier=newTier or player:GetAttribute("SelectedSizeTier") or 0,Win=newWin or player:GetAttribute("Win")})
end)
Players.PlayerRemoving:Connect(function(player) busy[player]=nil end)
