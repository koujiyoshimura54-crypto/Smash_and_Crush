local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Data=require(script.Parent.PlayerDataService)
local Merge=require(RS.Modules.OreMerge)
local Counts=require(RS.Modules.InventoryCounts)
local M={}
local rng=Random.new()
local busy=setmetatable({},{__mode="k"})
function M.State(player)
 local s=Data.Get(player)
 if not s or not s.Loaded then return {Loaded=false} end
 if not s.ForgeToken then s.ForgeToken=Http:GenerateGUID(false) end
 local d=s.Data
 return {Loaded=true,Token=s.ForgeToken,Sequence=d.ForgeJournal.Sequence,Journal=table.clone(d.ForgeJournal),
  Ores=table.clone(d.OwnedOres),DumbbellCounts=table.clone(d.OwnedDumbbells),EquippedDumbbell=d.EquippedDumbbell,
  Win=player:GetAttribute("Win") or d.Win,Pending=s.PendingItemMutation~=nil,Generation=s.PetViewGeneration or 0}
end
function M.Request(player,request)
 local state=M.State(player)
 local function response(ok,code) return {Success=ok,Code=code,State=M.State(player)} end
 if typeof(request)~="table" then return response(false,"InvalidRequest") end
 if request.Action=="GetState" then return response(true,"State") end
 if not state.Loaded then return response(false,"DataNotLoaded") end
 if request.Token~=state.Token or request.Generation~=state.Generation then return response(false,"InventoryChanged") end
 if typeof(request.Id)~="string" or #request.Id~=36 or not request.Id:match("^[%x%-]+$") or typeof(request.Sequence)~="number" or not Counts.Count(request.Sequence) then return response(false,"InvalidRequest") end
 local selection,reason,itemId,signature
 if request.Action=="MergeOre" or request.Action=="SellOre" then
  selection,reason=Merge.Selection(request.Materials,nil,request.Action=="SellOre")
  if not selection then return response(false,reason) end
  signature=Merge.Signature(request.Action,selection.Materials)
 elseif request.Action=="SellDumbbell" then
  itemId=request.ItemId
  if typeof(itemId)~="string" or #itemId>128 or typeof(request.Count)~="number" or not Counts.Count(request.Count) or request.Count<1 then return response(false,"InvalidSale") end
  signature=Merge.Signature(request.Action,{[itemId]=request.Count})
 else return response(false,"InvalidAction") end
 if state.Journal.Id==request.Id then
  return response(state.Journal.Sequence==request.Sequence and state.Journal.Signature==signature,"AlreadyApplied")
 end
 if request.Sequence~=state.Sequence+1 then return response(false,"InventoryChanged") end
 if busy[player] then return response(false,"InventorySavePending") end
 busy[player]=true
 local ok,success,code=pcall(function()
  local s=Data.Get(player);local pending=s.PendingItemMutation
  if pending then
   if pending.ForgeMutation and pending.Id==request.Id and pending.Signature==signature then return Data.ResolveItemMutation(player) end
   return false,"InventorySavePending"
  end
  local resultId=""
  if request.Action=="MergeOre" then
   local preview,err=Merge.Evaluate(selection.Materials,s.Data.OwnedOres)
   if not preview then return false,err end
   resultId=Merge.Pick(preview,rng:NextNumber())
  end
  return Data.MutateForge(player,{Id=request.Id,Sequence=request.Sequence,Signature=signature,
   Action=request.Action,Materials=selection and selection.Materials,ItemId=itemId,Count=request.Count,ResultId=resultId})
 end)
 busy[player]=nil
 if not ok then warn("[Forge] "..tostring(success));return response(false,"RequestFailed") end
 return response(success,code)
end
function M.GrantOre(player,oreId,dropId)
 local s=Data.Get(player);if not s or not s.Loaded then return false,"DataNotLoaded" end
 local signature="DropOre|"..oreId
 if s.Data.ForgeJournal.Id==dropId then return s.Data.ForgeJournal.Signature==signature,"AlreadyApplied" end
 local pending=s.PendingItemMutation
 if pending then
  if pending.ForgeMutation and pending.Id==dropId and pending.Signature==signature then return Data.ResolveItemMutation(player) end
  return false,"InventorySavePending"
 end
 return Data.MutateForge(player,{Action="DropOre",ResultId=oreId,Id=dropId,Signature=signature,Sequence=s.Data.ForgeJournal.Sequence+1})
end
return M
