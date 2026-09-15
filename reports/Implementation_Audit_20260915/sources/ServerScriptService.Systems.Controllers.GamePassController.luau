local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Pass=require(game.ServerScriptService.Services:WaitForChild("GamePassService"))
local remote=RS.Remotes:WaitForChild("World1DoubleWinPrompt")
Players.PlayerAdded:Connect(function(player) task.spawn(Pass.Refresh,player) end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(Pass.Refresh,player) end
remote.OnServerEvent:Connect(function(player,action)
 if action=="Prompt" then Pass.Prompt(player) end
end)

local shop=workspace:FindFirstChild("World1DoubleWinShop")
local prompt=shop and shop:FindFirstChild("PurchasePrompt",true)
if prompt then prompt.Triggered:Connect(function(player) Pass.Prompt(player) end) end

