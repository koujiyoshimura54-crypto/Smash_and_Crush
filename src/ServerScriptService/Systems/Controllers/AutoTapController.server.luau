local ReplicatedStorage=game:GetService("ReplicatedStorage")
local AutoTap=require(game.ServerScriptService.Services.AutoTapService)
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local remote=remotes:FindFirstChild("AutoTapRequest") or Instance.new("RemoteEvent")
remote.Name="AutoTapRequest"
remote.Parent=remotes
remote.OnServerEvent:Connect(function(player,action,...)
 if select("#",...)~=0 then return end
 if action=="Toggle" then AutoTap.Toggle(player)
 elseif action=="Tap" then AutoTap.HandleTap(player) end
end)
