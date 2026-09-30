-- Execute this factory from Studio's Server command context during Play.
-- sources = {unit=<spec source>, integration=<integration spec>, memory=<memory store>}
-- All fixtures exist only in the Play data model. Stop removes them.
return function(sources)
 local S=game.ServerScriptService.Services
 local function module(name,source,parent)
  local m=Instance.new("ModuleScript") m.Name=name m.Source=source m.Parent=parent return m
 end
 local function replace(source,old,new)
  local first,last=source:find(old,1,true) assert(first,old)
  return source:sub(1,first-1)..new..source:sub(last+1)
 end
 module("Phase5FMemory",sources.memory,game.ServerStorage)
 module("Phase5FUnit",sources.unit,game.ServerStorage)
 module("Phase5FIntegration",sources.integration,game.ServerStorage)
 for _,name in {"Phase5FDataA","Phase5FDataB"} do
  local source=S.PlayerDataService.Source
  source=replace(source,'local store=DSS:GetDataStore(StoreConfig.GetName("PlayerData_v1"))',
   'local store=require(game.ServerStorage.Phase5FMemory)')
  source=replace(source,'local function saveOrdered(name,userKey,value)',
   'local function saveOrdered(name,userKey,value)\n if true then return true end -- isolated test sink')
  module(name,source,S)
 end
 local script=Instance.new("Script") script.Name="Phase5FRunner"
 script.Source=[[
local S=game.ServerScriptService.Services
local unit=require(game.ServerStorage.Phase5FUnit)(require(S.RunReturnPersistence),require(S.PlayerDataOwnership))
local integration=require(game.ServerStorage.Phase5FIntegration)(require(S.Phase5FDataA),require(S.Phase5FDataB),require(game.ServerStorage.Phase5FMemory))
script:SetAttribute("Results",game:GetService("HttpService"):JSONEncode({unit=unit,integration=integration}))
]]
 script.Parent=game.ServerScriptService
 return script
end
