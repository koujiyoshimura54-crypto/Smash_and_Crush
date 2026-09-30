local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Data = require(script.Parent.Services.PlayerDataService)
local remote = Instance.new("RemoteEvent")
remote.Name = "PurchaseInventoryCapacity"
remote.Parent = RS:WaitForChild("Remotes")
local lastRequest = {}
remote.OnServerEvent:Connect(function(player, currentCapacity)
	if player.Parent ~= Players or typeof(currentCapacity) ~= "number"
		or currentCapacity ~= currentCapacity or currentCapacity % 1 ~= 0 then return end
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < .4 then
		remote:FireClient(player, false, "DataSaving")
		return
	end
	lastRequest[player] = now
	local ok, success, code = pcall(Data.PurchaseInventoryCapacity, player, currentCapacity)
	if not ok then warn("Capacity purchase failed: " .. tostring(success)); success, code = false, "PurchaseFailed" end
	if player.Parent == Players then remote:FireClient(player, success, code) end
end)
Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
