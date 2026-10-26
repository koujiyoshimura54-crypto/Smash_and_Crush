-- Server sampling and one durable Item transaction; no client odds/results accepted.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Config=require(game.ReplicatedStorage.Config.ItemMergeConfig)
local Items=require(game.ServerScriptService.Services.ItemService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local M={}
local sessions=setmetatable({},{__mode="k"})
local random=Random.new()
local function session(player)
 local s=sessions[player]
 if not s then s={Token=Http:GenerateGUID(false),Requests={}};sessions[player]=s end
 return s
end
local function finish(player,record)
 local op=record.Context and record.Context.Operation
 if op and op.Result then
  record.Success=op.Result=="Changed";record.Code=record.Success and "Merged" or op.Result;record.Pending=false
 end
 if record.Success and not record.Notified then record.Notified=true;Items.NotifyRegularItemGranted(player,record.ResultItemId) end
 return record.Success==true,record.Pending and "InventorySavePending" or record.Code,record.Success and record.ResultItemId or nil
end
function M.GetState(player)
 local owned=Items.GetOwnedItems(player)
 local s=session(player)
 local data=Data.Get(player)
 local journal=data and data.Data and data.Data.ItemMergeJournal or {Sequence=0}
 local last=s.LastRequest
 local result
 if last then
  local ok,code,id=finish(player,last)
  result={Success=ok,Code=code,RequestId=last.RequestId,ResultItemId=id}
 end
 return {Loaded=owned~=nil,OwnedItems=owned or {},EquippedItems=Items.GetEquippedItems(player) or {},
  MinimumCount=Config.MinimumCount,SessionToken=s.Token,NextSequence=(journal.Sequence or 0)+1,
  World2Unlocked=Data.HasReachedWorld2(player),
  SavePending=data and (data.Saving or data.PendingItemMutation~=nil) or false,LastResult=result}
end
function M.MergeItem(player,request)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(request)~="table" or typeof(request.RequestId)~="string" or #request.RequestId~=36
  or not request.RequestId:match("^[%x%-]+$") then return false,"InvalidRequest" end
 local s=session(player)
 if request.SessionToken~=s.Token then return false,"MergeSessionChanged" end
 local owned=Items.GetOwnedItems(player)
 if not owned then return false,"DataNotLoaded" end
 local preview,reason=Config.Evaluate(request.Materials,owned,Data.HasReachedWorld2(player))
 -- Replays compare immutable submitted counts, not possibly already-consumed holdings.
 local previous=s.Requests[request.RequestId]
 if previous then
  local shape=Config.Evaluate(request.Materials)
  if not shape or previous.Signature~=shape.Signature or previous.Sequence~=request.Sequence then return false,"InvalidReplay" end
  return finish(player,previous)
 end
 if not preview then return false,reason end
 local data=Data.Get(player)
 local journal=data.Data.ItemMergeJournal or {Sequence=0}
 if request.Sequence~=journal.Sequence+1 or request.Sequence>Config.MaxInteger then return false,"MergeSequenceChanged" end
 if s.Busy or data.Saving or data.PendingItemMutation then return false,"DataSaving" end
 local resultId=Config.Sample(preview,function()return random:NextNumber()end)
 local context={RequestId=request.RequestId,SessionToken=s.Token,Sequence=request.Sequence,
  Signature=preview.Signature,ResultItemId=resultId,Version=Config.Version}
 local record={RequestId=request.RequestId,Sequence=request.Sequence,Signature=preview.Signature,
  ResultItemId=resultId,Context=context,Pending=true,Code="InventorySavePending"}
 s.Requests[request.RequestId]=record;s.LastRequest=record;s.Busy=true
 local ok,changed,code=pcall(function()
  return Items.RunItemTransaction(player,function(token)
   for id,n in pairs(request.Materials) do
    local removed,why=Items.RemoveItem(player,id,n,token);if not removed then return false,why end
   end
   return Items.AddItem(player,resultId,1,token)
  end,{ItemMerge=context})
 end)
 s.Busy=false
 if not ok then record.Pending=context.Operation~=nil and not context.Operation.Result;record.Code="MergeFailed"
 elseif changed then record.Success=true;record.Pending=false;record.Code="Merged"
 elseif code~="InventorySavePending" then record.Pending=false;record.Code=code end
 return finish(player,record)
end
Players.PlayerRemoving:Connect(function(player)sessions[player]=nil end)
return M
