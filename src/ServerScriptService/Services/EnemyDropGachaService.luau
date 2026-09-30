-- Independent enemy reward path; one roll per player/run/stage, before any yield.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Items=require(game.ServerScriptService.Services.ItemService)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
local RunInventory=require(game.ServerScriptService.Services.RunInventoryService)
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local rng=Random.new()
local processed=setmetatable({},{__mode="k"})
local queues={}
local M={}
local function grant(player,result)
 while player.Parent==Players do
  local session=Data.Get(player)
  if not session or not session.Loaded or session.Saving or session.PendingItemMutation then
   task.wait(.25)
  else
   local added,code=Items.AddItem(player,result.ItemId,1)
   if added then Items.NotifyRegularItemGranted(player,result.ItemId);return true end
   if code=="InventorySavePending" then
    -- Observe the original operation: never issue a second +1 after an ambiguous write.
    local op=session.PendingItemMutation
    if not op then return false end
    repeat task.wait(.25) until op.Result or player.Parent~=Players
    local changed=op.Result=="Changed"
    if changed then Items.NotifyRegularItemGranted(player,result.ItemId) end
    return changed
   elseif code~="DataSaving" and code~="DataNotLoaded" then
    warn("[EnemyDropGacha] Grant rejected: "..tostring(code))
    return false
   end
  end
 end
 return false
end
function M.OnEnemyDefeated(player,stage,run,worldId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(stage)~="number" or stage%1~=0 or stage<1 or stage>10 then return false,"InvalidStage" end
 if typeof(run)~="table" or not run.Defeated or run.Defeated[stage]~=true then return false,"NotDefeated" end
 worldId=worldId or (player:GetAttribute("CurrentWorld") or 1)
 if worldId~=1 and worldId~=2 then return false,"InvalidWorld" end
 local runId=worldId==1 and run.RunInventoryId or nil
 if worldId==1 and not RunInventory.IsCurrent(player,runId) then return false,"StaleRun" end
 local record=processed[run]
 if not record then record={Player=player,Stages={}};processed[run]=record end
 if record.Player~=player then return false,"InvalidOwner" end
 if record.Stages[stage] then return false,"AlreadyProcessed" end
 local result=Roller.Roll(rng,stage)
 result.Id=game:GetService("HttpService"):GenerateGUID(false)
 result.OwnerUserId=player.UserId
 result.Stage=stage
 result.WorldId=worldId
 result.RunId=runId
 record.Stages[stage]=result
 local queue=queues[player]
 if queue then table.insert(queue,result) else
  queue={result};queues[player]=queue
  task.spawn(function()
   while player.Parent==Players and #queue>0 do
    local nextResult=queue[1]
    local success
    if nextResult.WorldId==1 then
     success=RunInventory.IsCurrent(player,nextResult.RunId)
     if success and nextResult.Outcome=="ITEM" then
      local added,code=RunInventory.TryAddDrop(player,nextResult.RunId,nextResult.Id,nextResult.ItemId)
      success=added
      if added then Items.NotifyRegularItemGranted(player,nextResult.ItemId) end
      if code=="InventoryFull" then
       -- Preserve the draw, but never present an ungranted item as acquired.
       nextResult.Outcome="MISS"
       nextResult.Reason="InventoryFull"
       nextResult.ItemId=nil
       nextResult.Segment=1
       success=true
      end
     end
     success=success and RunInventory.IsCurrent(player,nextResult.RunId)
    else
     -- World2 retains its existing durable inventory grant path.
     success=nextResult.Outcome=="MISS" or grant(player,nextResult)
    end
    if success and player.Parent==Players then remote:FireClient(player,nextResult) end
    table.remove(queue,1)
   end
   if queues[player]==queue then queues[player]=nil end
  end)
 end
 return true,result.Outcome,result.ItemId
end
Players.PlayerRemoving:Connect(function(player) queues[player]=nil end)
return M
