-- World1 provisional Item/Ore boss loot shares one capacity and return transaction.
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local Ore=require(game.ReplicatedStorage.Config.OreConfig)
local Data=require(script.Parent.PlayerDataService)
local states={}
local M={}

-- Server PlayerData is authoritative; attributes are output mirrors only.
function M.GetCapacity(player)
 return Data.GetInventoryCapacity(player)
end
local function validPlayer(player)
 return typeof(player)=="Instance" and player:IsA("Player") and player.Parent==Players
end
local function alive(player)
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 return hum~=nil and hum.Health>0
end
local function sync(player,s)
 s.Capacity=M.GetCapacity(player)
 player:SetAttribute("RunInventoryCount",s.Count)
 player:SetAttribute("RunInventoryCapacity",s.Capacity)
 player:SetAttribute("RunInventoryWorldId",s.WorldId)
 player:SetAttribute("RunInventoryActive",s.Active)
 player:SetAttribute("RunInventoryId",s.RunId)
end
function M.Reset(player,active)
 if not validPlayer(player) then return nil end
 local s={RunId=HttpService:GenerateGUID(false),WorldId=1,Capacity=M.GetCapacity(player),
  Items={},Ores={},Count=0,Active=active==true,ProcessedDrops={}}
 states[player]=s
 sync(player,s)
 return s.RunId
end
function M.Invalidate(player)
 return M.Reset(player,false)
end
-- Latch the loss on the dying character BEFORE clearing the run.
-- An ambiguous durable write must settle before we claim its loot was lost.
function M.DiscardOnDeath(player,character)
 if player.Character~=character or character:GetAttribute("BattleBagDeathPending") then return end
 character:SetAttribute("BattleBagDeathPending",true)
 local s=states[player]
 local count=s and s.Count or 0
 local session=Data.Get(player)
 local op=session and session.PendingItemMutation
 if not (op and op.RunReturn and s and op.RunId==s.RunId) then op=nil end
 M.Invalidate(player)
 local function finish()
  character:SetAttribute("BattleBagLostCount",op and op.Result=="Changed" and 0 or count)
  character:SetAttribute("BattleBagDeathResolved",true)
 end
 if op and not op.Result then
  task.spawn(function()
   while not op.Result and player.Parent==Players do
    Data.ResolveItemMutation(player)
    if not op.Result then task.wait(.25) end
   end
   if op.Result then finish() end
  end)
 else finish() end
end
function M.SetActive(player,runId,active)
 local s=states[player]
 if not validPlayer(player) or not s or s.RunId~=runId then return false end
 s.Active=active==true
 sync(player,s)
 return true
end
function M.IsCurrent(player,runId)
 local s=states[player]
 return validPlayer(player) and s~=nil and s.RunId==runId and s.Active and not s.ReturnToken
  and (player:GetAttribute("CurrentWorld") or 1)==1 and alive(player)
end
function M.RefreshCapacity(player)
 local s=states[player]
 if s then s.Capacity=M.GetCapacity(player) end
 player:SetAttribute("RunInventoryCapacity",M.GetCapacity(player))
end
-- Freeze the existing generation while its immutable snapshot is being banked.
-- A failed/unconfirmed write keeps this token, so retry cannot include new drops.
function M.BeginReturn(player,runId)
 local s=states[player]
 if not validPlayer(player) or not s or s.RunId~=runId or not s.Active
  or (player:GetAttribute("CurrentWorld") or 1)~=1 or not alive(player) then return nil,"StaleRun" end
 if not s.ReturnToken then
  s.ReturnToken={Id=HttpService:GenerateGUID(false),RunId=runId,Character=player.Character,
   Items=table.clone(s.Items),Ores=table.clone(s.Ores),Count=s.Count}
 end
 return s.ReturnToken
end
function M.CanReturn(player,token)
 local s=states[player]
 return validPlayer(player) and s~=nil and s.ReturnToken==token and s.RunId==token.RunId
  and s.Active and player.Character==token.Character and alive(player)
  and (player:GetAttribute("CurrentWorld") or 1)==1
end
function M.ReleaseReturn(player,token)
 local s=states[player]
 if s and s.ReturnToken==token then s.ReturnToken=nil end
end
function M.CompleteReturn(player,token)
 if not M.CanReturn(player,token) then return false end
 M.Invalidate(player)
 return true
end
function M.GetSnapshot(player)
 local s=states[player]
 if not s then return nil end
 return {RunId=s.RunId,WorldId=s.WorldId,Capacity=s.Capacity,Items=table.clone(s.Items),Ores=table.clone(s.Ores),
  Count=s.Count,Active=s.Active}
end
-- No yields between generation/duplicate/capacity checks and the write.
local function addDrop(player,runId,dropId,itemId,isOre)
 if not M.IsCurrent(player,runId) then return false,"StaleRun" end
 if typeof(dropId)~="string" or dropId=="" then return false,"InvalidDropId" end
 local definition=isOre and Ore.Get(itemId) or Master.Get(itemId)
 if not definition or isOre and not definition.Available then return false,isOre and "InvalidOreId" or "InvalidItemId" end
 local s=states[player]
 if s.ProcessedDrops[dropId] then return false,"AlreadyProcessed" end
 s.Capacity=M.GetCapacity(player)
 s.ProcessedDrops[dropId]=true
 if s.Count>=s.Capacity then return false,"InventoryFull" end
 local inventory=isOre and s.Ores or s.Items
 inventory[itemId]=(inventory[itemId] or 0)+1
 s.Count+=1
 sync(player,s)
 return true,"Added"
end
function M.TryAddDrop(player,runId,dropId,itemId)
 return addDrop(player,runId,dropId,itemId,false)
end
function M.TryAddOreDrop(player,runId,dropId,oreId)
 return addDrop(player,runId,dropId,oreId,true)
end
local capacityConnections={}
local function watchCapacity(player)
 capacityConnections[player]=player:GetAttributeChangedSignal("InventoryCapacity"):Connect(function()
  M.RefreshCapacity(player)
 end)
 M.RefreshCapacity(player)
end
Players.PlayerAdded:Connect(watchCapacity)
for _,player in Players:GetPlayers() do watchCapacity(player) end
Players.PlayerRemoving:Connect(function(player)
 states[player]=nil
 if capacityConnections[player] then capacityConnections[player]:Disconnect();capacityConnections[player]=nil end
end)
return M
