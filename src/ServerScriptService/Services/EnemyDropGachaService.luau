-- Independent enemy reward path; one roll per player/run/stage, before any yield.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
local RunInventory=require(game.ServerScriptService.Services.RunInventoryService)
local remote=RS.Remotes:WaitForChild("EnemyDropGachaResult")
local rng=Random.new()
local processed=setmetatable({},{__mode="k"})
local queues={}
local M={}
local function reserveFirstStage1(player,result)
 if result.WorldId~=1 or result.Stage~=1 then return end
 local session=Data.Get(player)
 if not session or not session.Loaded then result.CheckFirstStage1=true;return end
 result.CheckFirstStage1=nil
 if Data.ReserveFirstStage1Defeat(player,result.Id,result.Discarded,result.RunId) then
  result.FirstStage1=true;result.Outcome="ORE";result.OreId="ORE_001";result.ItemId=nil;result.Segment=1
 end
end
function M.OnEnemyDefeated(player,stage,run,worldId)
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(stage)~="number" or stage%1~=0 or stage<1 or stage>10 then return false,"InvalidStage" end
 if typeof(run)~="table" or not run.Defeated or run.Defeated[stage]~=true then return false,"NotDefeated" end
 worldId=worldId or (player:GetAttribute("CurrentWorld") or 1)
 if worldId~=1 and worldId~=2 then return false,"InvalidWorld" end
 local runId=run.RunInventoryId
 if not RunInventory.IsCurrent(player,runId) then return false,"StaleRun" end
 local record=processed[run]
 if not record then record={Player=player,Stages={}};processed[run]=record end
 if record.Player~=player then return false,"InvalidOwner" end
 if record.Stages[stage] then return false,"AlreadyProcessed" end
 local result=Roller.Roll(rng,stage,worldId)
 result.Id=game:GetService("HttpService"):GenerateGUID(false)
 result.OwnerUserId=player.UserId
 result.Stage=stage
 result.WorldId=worldId
 result.RunId=runId
 -- Owner decision: discard either category when the existing run bag is full.
 -- The discard animation is a separate future task; never show acquisition here.
 RunInventory.ExpectDrop(player,result.Id)
 local bag=RunInventory.GetSnapshot(player)
 if bag and bag.Count>=bag.Capacity then result.Discarded=true;result.Reason="InventoryFull" end
 reserveFirstStage1(player,result)
 record.Stages[stage]=result
 remote:FireClient(player,{Id=result.Id,OwnerUserId=player.UserId,RunId=runId,WorldId=worldId,Outcome="REPLACE"})
 if result.Discarded and not result.FirstStage1 and not result.CheckFirstStage1 then return true,"Discarded" end
 local queue=queues[player]
 if queue then table.insert(queue,result) else
  queue={result};queues[player]=queue
  task.spawn(function()
   while player.Parent==Players and #queue>0 do
    local nextResult=queue[1]
    local success
    while nextResult.CheckFirstStage1 and player.Parent==Players do
     reserveFirstStage1(player,nextResult)
     if nextResult.CheckFirstStage1 then task.wait(.25) end
    end
    if nextResult.FirstStage1 then
     while player.Parent==Players do
      local added,code=Data.ResolveFirstStage1Defeat(player,nextResult.Id)
      if added then
       if code=="BagPending" then
        local reason
        success,reason=RunInventory.TryAddOreDrop(player,nextResult.RunId,nextResult.Id,nextResult.OreId)
        if reason=="InventoryFull" then nextResult.Discarded=true;nextResult.Reason=reason end
       else success=code=="Applied" end
       if code=="Discarded" then nextResult.Discarded=true;nextResult.Reason="InventoryFull" end
       break
      end
      if code~="InventorySavePending" and code~="DataSaving" and code~="DataNotLoaded" then
       warn("[EnemyDropGacha] First Stage1 grant rejected: "..tostring(code));break
      end
      task.wait(.5)
     end
    elseif nextResult.Discarded then
     success=false
    elseif nextResult.Outcome=="ORE" then
     local reason
     success,reason=RunInventory.TryAddOreDrop(player,nextResult.RunId,nextResult.Id,nextResult.OreId)
     if reason=="InventoryFull" then nextResult.Discarded=true;nextResult.Reason=reason end
    else
     success=RunInventory.IsCurrent(player,nextResult.RunId)
     if success and nextResult.Outcome=="ITEM" then
      local added,code=RunInventory.TryAddDrop(player,nextResult.RunId,nextResult.Id,nextResult.ItemId)
      success=added
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
    end
    if success and player.Parent==Players then remote:FireClient(player,nextResult) end
    table.remove(queue,1)
   end
   if queues[player]==queue then queues[player]=nil end
  end)
 end
 return true,result.Discarded and "Discarded" or result.Outcome,result.ItemId
end
Players.PlayerRemoving:Connect(function(player) queues[player]=nil end)
return M
