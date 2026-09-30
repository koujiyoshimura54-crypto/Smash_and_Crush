local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Chat=game:GetService("TextChatService")
local remotes=game:GetService("ReplicatedStorage"):WaitForChild("Remotes",10)
local remote=remotes and remotes:WaitForChild("StudioTestCommandResult",10)
if not remote then return end
remote.OnClientEvent:Connect(function(message)
 local channels=Chat:FindFirstChild("TextChannels");local general=channels and channels:FindFirstChild("RBXGeneral")
 if general then general:DisplaySystemMessage(tostring(message)) end
end)
