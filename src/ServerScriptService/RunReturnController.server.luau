local RS = game:GetService("ReplicatedStorage")
local Return = require(script.Parent.Services:WaitForChild("RunReturnService"))
local remotes = RS:WaitForChild("Remotes")
local remote = Instance.new("RemoteEvent")
remote.Name = "RunReturn"
remote.Parent = remotes
local lastRequest = {}
remote.OnServerEvent:Connect(function(player, runId)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < 0.4 then
		remote:FireClient(player, runId, false, "ReturnBusy")
		return
	end
	lastRequest[player] = now
	local success, code = Return.Request(player, runId)
	if player.Parent == game.Players then remote:FireClient(player, runId, success, code) end
end)
game.Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
