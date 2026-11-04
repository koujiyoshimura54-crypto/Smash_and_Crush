-- Temporary native client; calls original input closures and production Remotes, never OS input.
local RS=game.ReplicatedStorage
local p=game.Players.LocalPlayer
local trace={}
local function probe() return p.PlayerScripts:WaitForChild("__TapQAInputProbe",15) end
RS:WaitForChild("__TapQARequest").OnClientEvent:Connect(function(id,action,value)
 local ok,result=pcall(function()
  if action=="Ready" then return probe()~=nil
  elseif action=="Tap" then return probe():Invoke("Tap")
  elseif action=="Toggle" then return probe():Invoke("Toggle")
  elseif action=="Burst" then for _=1,4 do probe():Invoke("Tap");task.wait(.215) end return true
  elseif action=="RawSpam" then for _=1,5 do RS.Remotes.AutoTapRequest:FireServer("Tap");task.wait(.01) end return true
  elseif action=="Trace" then local animations={}
   for _,x in p.PlayerScripts:GetChildren() do if x:IsA("BindableFunction") and x.Name:match("^__AnimationQA") then
    for _,row in x:Invoke() do animations[#animations+1]=row end
   end end
   table.sort(animations,function(a,b)return a.Time<b.Time end)
   return {Events=trace,Visuals=animations} end
 end)
 RS.__TapQAReply:FireServer(id,{OK=ok,Value=result})
end)
for _,name in {"CombatState","World2CombatState"} do
 RS.Remotes.GameRemotes:WaitForChild(name).OnClientEvent:Connect(function(d)
  if d.Type=="CombatAttack" or d.Type=="WallGauge" or d.Type=="BossGauge" then
   trace[#trace+1]={Time=workspace:GetServerTimeNow(),Type=d.Type,Id=d.Id,AttackId=d.AttackId,Manual=d.Manual,HitDelay=d.HitDelay,HP=d.Current,World=d.WorldId,Remote=name}
  end
 end)
end
