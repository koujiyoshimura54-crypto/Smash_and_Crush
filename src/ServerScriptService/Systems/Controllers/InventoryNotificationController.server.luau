local RS=game:GetService("ReplicatedStorage")
local Data=require(game.ServerScriptService.Services:WaitForChild("PlayerDataService"))
local remotes=RS:WaitForChild("Remotes")
local remote=remotes:FindFirstChild("InventoryNotificationState")
if not remote then
 remote=Instance.new("RemoteFunction")
 remote.Name="InventoryNotificationState"
 remote.Parent=remotes
end
remote.OnServerInvoke=function(player,action,tab,ids)
 if action=="Get" then
  local seen=Data.GetInventoryNotificationSeen(player)
  return {Success=seen~=nil,Seen=seen or {}}
 end
 if action=="MarkSeen" then
  local ok,result=Data.MarkInventoryNotificationsSeen(player,tab,ids)
  return {Success=ok,Code=ok and nil or result,Seen=ok and result or nil}
 end
 return {Success=false,Code="InvalidRequest"}
end
