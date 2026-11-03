local RS=game.ReplicatedStorage
RS:WaitForChild("__DepthQARequest").OnClientEvent:Connect(function(id,action)
 local ok,value=pcall(function()
  if action=="Tap" then RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.08) end
  return true
 end)
 RS.__DepthQAReply:FireServer(id,{OK=ok,Value=value})
end)
