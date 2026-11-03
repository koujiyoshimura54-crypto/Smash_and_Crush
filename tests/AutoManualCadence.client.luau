-- Native input probe/Remote fixture, no OS events or camera changes.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local function tap(mode)
 return p.PlayerScripts:WaitForChild("__TapQAInputProbe",10):Invoke(mode or "Valid")
end
RS:WaitForChild("__TapQARequest").OnClientEvent:Connect(function(id,action,value)
 local ok,result=pcall(function()
  if action=="Ready" then return p.PlayerScripts:WaitForChild("__TapQAInputProbe",15)~=nil
  elseif action=="Tap" then local r=tap(value);task.wait(.045);return r
  elseif action=="Burst" then for i=1,4 do tap();task.wait(.215) end return true
  elseif action=="RawSpam" then for i=1,5 do RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.01) end return true
  elseif action=="Invalid" then for i=1,5 do RS.Remotes.AutoTapRequest:FireServer("Invalid");RS.Remotes.AutoTapRequest:FireServer("Tap","extra");task.wait(.015) end return true
  elseif action=="Travel" then RS.Remotes.WorldTravelRequest:FireServer(value==2 and "ToWorld2" or "ReturnWorld1");return true
  end
 end)
 RS.__TapQAReply:FireServer(id,{OK=ok,Value=result})
end)
