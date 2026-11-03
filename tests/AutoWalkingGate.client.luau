-- Temporary native input fixture; no OS input.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
RS:WaitForChild("__WalkQARequest").OnClientEvent:Connect(function(id,action)
 local ok,value=pcall(function()
  if action=="Tap" then RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.06)
  elseif action=="Walk" then
   local h=p.Character.Humanoid
   local c=game.RunService.PreSimulation:Connect(function()h:Move(Vector3.new(0,0,1),false)end)
   task.wait(1.3);c:Disconnect();h:Move(Vector3.zero,false);task.wait(.25)
  end
  return true
 end)
 RS.__WalkQAReply:FireServer(id,{OK=ok,Value=value})
end)
