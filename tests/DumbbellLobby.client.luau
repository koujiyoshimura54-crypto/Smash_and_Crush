-- Temporary native test input; no OS input, camera edits, or persistent writes.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local gains={}
RS.Remotes:WaitForChild("StrengthGain").OnClientEvent:Connect(function(n)gains[#gains+1]=n end)
RS:WaitForChild("__DumbQARequest").OnClientEvent:Connect(function(id,action,value)
 local ok,result=pcall(function()
  if action=="Ready" then return true
  elseif action=="Tap" then RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.2);return true
  elseif action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(value==2 and "ToWorld2" or "ReturnWorld1");return true
  elseif action=="Walk" then
   local h=p.Character.Humanoid
   local c=game.RunService.PreSimulation:Connect(function()h:Move(value,false)end)
   task.wait(1.3);c:Disconnect();h:Move(Vector3.zero,false)
   return true
  elseif action=="Gains" then return {Strength=p:GetAttribute("Strength"),Gains=gains} end
 end)
 RS.__DumbQAReply:FireServer(id,{OK=ok,Value=result})
end)

