-- World1 provisional boss loot. Never reads or writes PlayerData/Backpack/Tools.
local Players=game:GetService("Players")
local HttpService=game:GetService("HttpService")
local Master=require(game.ReplicatedStorage.Config.ItemMaster)
local DEFAULT_CAPACITY=5
local states={}
local M={}

-- Future purchased capacity resolves here; no client attribute is authoritative.
function M.GetCapacity(_player)
 return DEFAULT_CAPACITY
end
local function validPlayer(player)
 return typeof(player)=="Instance" and player:IsA("Player") and player.Parent==Players
end
local function alive(player)
 local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 return hum~=nil and hum.Health>0
end
local function sync(player,s)
 player:SetAttribute("RunInventoryCount",s.Count)
 player:SetAttribute("RunInventoryCapacity",s.Capacity)
 player:SetAttribute("RunInventoryWorldId",s.WorldId)
 player:SetAttribute("RunInventoryActive",s.Active)
 player:SetAttribute("RunInventoryId",s.RunId)
end
function M.Reset(player,active)
 if not validPlayer(player) then return nil end
 local s={RunId=HttpService:GenerateGUID(false),WorldId=1,Capacity=M.GetCapacity(player),
  Items={},Count=0,Active=active==true,ProcessedDrops={}}
 states[player]=s
 sync(player,s)
 return s.RunId
end
function M.Invalidate(player)
 return M.Reset(player,false)
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
-- Freeze the existing generation while its immutable snapshot is being banked.
-- A failed/unconfirmed write keeps this token, so retry cannot include new drops.
function M.BeginReturn(player,runId)
 local s=states[player]
 if not validPlayer(player) or not s or s.RunId~=runId or not s.Active
  or (player:GetAttribute("CurrentWorld") or 1)~=1 or not alive(player) then return nil,"StaleRun" end
 if not s.ReturnToken then
  s.ReturnToken={Id=HttpService:GenerateGUID(false),RunId=runId,Character=player.Character,
   Items=table.clone(s.Items),Count=s.Count}
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
 return {RunId=s.RunId,WorldId=s.WorldId,Capacity=s.Capacity,Items=table.clone(s.Items),
  Count=s.Count,Active=s.Active}
end
-- No yields between generation/duplicate/capacity checks and the write.
function M.TryAddDrop(player,runId,dropId,itemId)
 if not M.IsCurrent(player,runId) then return false,"StaleRun" end
 if typeof(dropId)~="string" or dropId=="" then return false,"InvalidDropId" end
 if not Master.Get(itemId) then return false,"InvalidItemId" end
 local s=states[player]
 if s.ProcessedDrops[dropId] then return false,"AlreadyProcessed" end
 s.ProcessedDrops[dropId]=true
 if s.Count>=s.Capacity then return false,"InventoryFull" end
 s.Items[itemId]=(s.Items[itemId] or 0)+1
 s.Count+=1
 sync(player,s)
 return true,"Added"
end
Players.PlayerRemoving:Connect(function(player) states[player]=nil end)
return M
