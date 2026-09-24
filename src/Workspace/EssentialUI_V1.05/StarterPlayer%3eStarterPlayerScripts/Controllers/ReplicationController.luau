local ReplicationController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedUtils = ReplicatedStorage.Utils
local Packets = require(ReplicatedUtils.Packets)
local LemonSignal = require(ReplicatedStorage.Packages.LemonSignal)

-- { [name]: { Data:{}, Signal:LemonSignal } }
local ReplicationStore: {[string]: {Data:{}, Signal:LemonSignal.Signal<>}} = {}

local function getOrCreateEntry(name:string)
	if not ReplicationStore[name] then
		ReplicationStore[name] = {
			Data = {},
			Signal = LemonSignal.new()
		}
	end
	return ReplicationStore[name]
end


function ReplicationController.Subscribe(name:string): {}
	local entry = getOrCreateEntry(name)

	if next(entry.Data) ~= nil then
		return entry.Data
	end

	local ok, result = pcall(function()
		return Packets.Replication.Request:Fire(name)
	end)

	if ok and type(result) == "table" then
		for k, v in result do
			entry.Data[k] = v
		end
	end

	return entry.Data
end

function ReplicationController.Get(name:string): {}
	local entry = ReplicationStore[name]
	return entry and entry.Data or {}
end

function ReplicationController.GetSignal(name:string)
	return getOrCreateEntry(name).Signal
end

function ReplicationController.Clear(name:string)
	local entry = ReplicationStore[name]
	if not entry then return end
	entry.Signal:DisconnectAll()
	ReplicationStore[name] = nil
end

function ReplicationController.init()
	Packets.Replication.Push.OnClientEvent:Connect(function(name:string, data:{})
		local entry = getOrCreateEntry(name)
		
		table.clear(entry.Data)
		for k, v in data do
			entry.Data[k] = v
		end

		entry.Signal:Fire(entry.Data)
	end)
	Packets.Replication.Destroy.OnClientEvent:Connect(function (name: string)
		ReplicationController.Clear(name)
	end)
end

return ReplicationController