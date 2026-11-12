-- Retry only the outcome fixture after retaining failed evidence.
-- The first fixture omitted the ordinary OwnerUserId packet filter.
return function(sources)
 assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
 assert(game.ServerStorage.__W1BalanceBoundaryHostResult:GetAttribute("Finished"))
 assert(game.ServerStorage:FindFirstChild("__W1BalanceBackup"))
 local function same(a,b)return a:gsub("\r\n","\n"):gsub("%s+$","")==b:gsub("\r\n","\n"):gsub("%s+$","")end
 local server=game.ServerScriptService.__W1BalanceBoundary
 assert(same(server.Source,sources["Boundary.server.luau"]),"QA server changed")
 local waitForInitial=[=[
local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local deadline=os.clock()+90
while true do
 local all=#Players:GetPlayers()==3
 for _,p in Players:GetPlayers()do if not Data.IsLoaded(p)then all=false end end
 if all then break end
 assert(os.clock()<deadline,"Initial native profiles not ready")
 task.wait(.1)
end
]=]
 local code=waitForInitial..sources["Analytics.server.luau"]
 assert(loadstring(code));assert(loadstring(sources["Analytics.client.luau"]))
 server.Source=code
 game.StarterPlayer.StarterPlayerScripts.__W1BalanceAnalytics.Source=sources["Analytics.client.luau"]
 local result=Instance.new("StringValue");result.Name="__W1BalanceAnalyticsHostResult";result.Parent=game.ServerStorage
 task.spawn(function()
  local ok,value=pcall(function()return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(3,{})end)
  result.Value=game.HttpService:JSONEncode({OK=ok,Value=value});result:SetAttribute("Finished",true)
 end)
 return "Separate corrected outcome fixture started; memory stores only"
end
