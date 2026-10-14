local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Items=require(game.ServerScriptService.Services.ItemService)
local Merge=require(game.ServerScriptService.Services.ItemMergeService)
local remote=RS.Remotes:WaitForChild("ItemMergeRequest")
local last=setmetatable({},{__mode="k"})
remote.OnServerEvent:Connect(function(player,request,...)
 local now=os.clock()
 local success,code,result
 if select("#",...)>0 then success,code=false,"InvalidRequest"
 else
  -- Service deduplication owns accepted request IDs; throttling never invents a new operation.
  local id=typeof(request)=="table" and request.RequestId
  local previous=last[player]
  if previous and now-previous.Time<.3 and id~=previous.Id then success,code=false,"RateLimited"
  else
   last[player]={Time=now,Id=id}
   local ok,a,b,c=pcall(Merge.MergeItem,player,request)
   if ok then success,code,result=a,b,c else warn("[ItemMerge] "..tostring(a));success,code=false,"MergeFailed" end
  end
 end
 if player.Parent~=Players then return end
 local owned=Items.GetOwnedItems(player)
 remote:FireClient(player,{Success=success,Code=code,
  RequestId=typeof(request)=="table" and typeof(request.RequestId)=="string" and #request.RequestId==36 and request.RequestId or nil,
  ResultItemId=result,MergeState=Merge.GetState(player),
  State={Loaded=owned~=nil,OwnedItems=owned or {},EquippedItems=Items.GetEquippedItems(player) or {},Win=player:GetAttribute("Win") or 0}})
end)
Players.PlayerRemoving:Connect(function(player)last[player]=nil end)
local stateRemote=RS.Remotes:FindFirstChild("ItemMergeState")
if not stateRemote then stateRemote=Instance.new("RemoteFunction");stateRemote.Name="ItemMergeState";stateRemote.Parent=RS.Remotes end
stateRemote.OnServerInvoke=Merge.GetState
