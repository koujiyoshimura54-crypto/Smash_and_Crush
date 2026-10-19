local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Chat=game:GetService("TextChatService")
local remotes=game:GetService("ReplicatedStorage"):WaitForChild("Remotes",10)
if not remotes then warn("[StudioTest] ReplicatedStorage.Remotes is missing");return end
local connection
local function display(message)
 print("[StudioTest] "..tostring(message))
 task.spawn(function()
  local channels=Chat:WaitForChild("TextChannels",10)
  local general=channels and channels:WaitForChild("RBXGeneral",10)
  if not general then warn("[StudioTest] Chat channel unavailable; reply is in Client Output");return end
  local ok,why=pcall(function()general:DisplaySystemMessage(tostring(message))end)
  if not ok then warn("[StudioTest] Chat display failed: "..tostring(why)) end
 end)
end
local function bind(remote)
 if remote.Name~="StudioTestCommandResult" then return end
 if not remote:IsA("RemoteEvent") then warn("[StudioTest] Result instance must be a RemoteEvent");return end
 if connection then return end
 connection=remote.OnClientEvent:Connect(display)
end
remotes.ChildAdded:Connect(bind)
local remote=remotes:FindFirstChild("StudioTestCommandResult")
if remote then bind(remote) end
task.delay(10,function()
 if not connection then warn("[StudioTest] Result Remote is not ready; waiting for server registration") end
end)
