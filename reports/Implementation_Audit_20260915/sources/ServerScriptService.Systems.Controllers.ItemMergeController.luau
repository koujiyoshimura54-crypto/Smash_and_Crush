local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Items=require(game.ServerScriptService.Services.ItemService)
local Merge=require(game.ServerScriptService.Services.ItemMergeService)
local remote=RS.Remotes:WaitForChild("ItemMergeRequest")
local last=setmetatable({}, {__mode="k"})
remote.OnServerEvent:Connect(function(player,itemId,...)
 local now=os.clock()
 local success,code,result
 if select("#",...)>0 then
  success,code=false,"InvalidRequest"
 elseif last[player] and now-last[player]<0.3 then
  success,code=false,"RateLimited"
 else
  last[player]=now
  success,code,result=Merge.MergeItem(player,itemId)
 end
 if player.Parent~=Players then return end
 local owned=Items.GetOwnedItems(player)
 remote:FireClient(player,{Success=success,Code=code,
  ItemId=typeof(itemId)=="string" and #itemId<=128 and itemId or nil,
  ResultItemId=result,
  State={Loaded=owned~=nil,OwnedItems=owned or {},EquippedItems=Items.GetEquippedItems(player) or {},Win=player:GetAttribute("Win") or 0}})
end)
Players.PlayerRemoving:Connect(function(player) last[player]=nil end)

