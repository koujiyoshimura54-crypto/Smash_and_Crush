-- Host Edit setup AFTER every timed route has finished and its output is retained.
return function(sources)
 assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
 assert(game.ServerStorage.__W1BalanceAfterQueue:GetAttribute("Finished"),"timed routes still active")
 assert(game.ServerStorage:FindFirstChild("__W1BalanceBackup"),"Memory isolation required")
 assert(not game.ReplicatedStorage:FindFirstChild("__W1BalanceBoundary"))
 local oldRoute=game.StarterPlayer.StarterPlayerScripts.__W1BalanceRoute
 local oldObserver=game.ServerScriptService.__W1BalanceObserver
 local function same(a,b)return a:gsub("\r\n","\n")==b:gsub("\r\n","\n")end
 assert(same(oldRoute.Source,sources["Route.client.luau"]),"Unexpected QA route edit")
 assert(same(oldObserver.Source,sources["Observer.server.luau"]),"Unexpected QA observer edit")
 for _,name in {"Boundary.server.luau","Boundary.client.luau","Analytics.client.luau","CombatProbe.server.luau"}do assert(loadstring(sources[name],name))end
 oldRoute:Destroy();oldObserver:Destroy();game.ReplicatedStorage.__W1BalanceRoute:Destroy()
 local q=Instance.new("Folder");q.Name="__W1BalanceBoundary";q.Parent=game.ReplicatedStorage
 for name,class in {Call="RemoteFunction",AnalyticsCall="RemoteFunction",AnalyticsReady="RemoteEvent"}do
  local v=Instance.new(class);v.Name=name;v.Parent=q
 end
 local combat=Instance.new("ModuleScript");combat.Name="CombatProbe";combat.Source=sources["CombatProbe.server.luau"];combat.Parent=q
 local server=Instance.new("Script");server.Name="__W1BalanceBoundary";server.Source=sources["Boundary.server.luau"];server.Parent=game.ServerScriptService
 for name,file in {__W1BalanceBoundary="Boundary.client.luau",__W1BalanceAnalytics="Analytics.client.luau"}do
  local client=Instance.new("LocalScript");client.Name=name;client.Source=sources[file];client.Parent=game.StarterPlayer.StarterPlayerScripts
 end
 local result=Instance.new("StringValue");result.Name="__W1BalanceBoundaryHostResult";result.Parent=game.ServerStorage
 task.spawn(function()
  local ok,value=pcall(function()return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(3,{})end)
  result.Value=game.HttpService:JSONEncode({OK=ok,Value=value});result:SetAttribute("Finished",true)
 end)
 return "Separate native boundary test started; no Save/Publish"
end
