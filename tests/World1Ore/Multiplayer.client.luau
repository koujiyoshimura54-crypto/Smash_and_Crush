local RS=game.ReplicatedStorage
local player=game.Players.LocalPlayer
local request=RS:WaitForChild("__OreMultiRequest")
local reply=RS:WaitForChild("__OreMultiReply")
local drops={}
RS.Remotes:WaitForChild("EnemyDropGachaResult").OnClientEvent:Connect(function(r)
 table.insert(drops,{Owner=r.OwnerUserId,Id=r.Id,Outcome=r.Outcome,OreId=r.OreId})
end)
request.OnClientEvent:Connect(function(key,action)
 local ok,result=pcall(function()
  if action=="Merge" then
   local remote=RS.Remotes.ForgeRequest;local state=remote:InvokeServer({Action="GetState"}).State;task.wait(.2)
   return remote:InvokeServer({Action="MergeOre",Materials={ORE_001=1},Id=game.HttpService:GenerateGUID(false),Token=state.Token,Sequence=state.Sequence+1,Generation=state.Generation})
  end
  local icons={}
  for _,g in player.PlayerGui:GetChildren() do if g.Name=="PersonalDropReward" then
   table.insert(icons,{Id=g:GetAttribute("RewardId"),LocalParent=g.Parent==player.PlayerGui,OwnHead=g.Adornee and g.Adornee:IsDescendantOf(player.Character),Image=g.Icon.Image,Loaded=g.Icon.IsLoaded})
  end end
  return {Drops=table.clone(drops),Icons=icons,State=RS.Remotes.ForgeRequest:InvokeServer({Action="GetState"}).State}
 end)
 reply:FireServer(key,{OK=ok,Result=result})
end)
