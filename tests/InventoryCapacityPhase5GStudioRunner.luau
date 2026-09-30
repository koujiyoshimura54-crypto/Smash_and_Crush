-- Call from Studio Server command context during Play with
-- {spec = InventoryCapacityPhase5G.spec source, memory = Phase5FMemoryStore source}.
-- Read ServerScriptService.Phase5GTests.Results; Stop removes every fixture.
return function(sources)
	local S=game.ServerScriptService.Services
	local function module(name, source, parent)
		local m=Instance.new("ModuleScript");m.Name=name;m.Source=source;m.Parent=parent
	end
	local function replace(source, old, new)
		local a,b=source:find(old,1,true);assert(a,old)
		return source:sub(1,a-1)..new..source:sub(b+1)
	end
	module("Phase5GMemory",sources.memory,game.ServerStorage)
	module("Phase5GSpec",sources.spec,game.ServerStorage)
	for _,name in {"Phase5GDataA","Phase5GDataB"} do
		local source=replace(S.PlayerDataService.Source,
			'local store=DSS:GetDataStore(StoreConfig.GetName("PlayerData_v1"))',
			'local store=require(game.ServerStorage.Phase5GMemory)')
		source=replace(source,'local function saveOrdered(name,userKey,value)',
			'local function saveOrdered(name,userKey,value)\n if true then return true end')
		module(name,source,S)
	end
	local runner=Instance.new("Script");runner.Name="Phase5GTests"
	runner.Source=[[
local S=game.ServerScriptService.Services
local ok,result=pcall(function()
 return require(game.ServerStorage.Phase5GSpec)(require(S.Phase5GDataA),require(S.Phase5GDataB),require(game.ServerStorage.Phase5GMemory))
end)
script:SetAttribute("Results",game.HttpService:JSONEncode({ok=ok,result=result}))
]]
	runner.Parent=game.ServerScriptService
	return runner
end
