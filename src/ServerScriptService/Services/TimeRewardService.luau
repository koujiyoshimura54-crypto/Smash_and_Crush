local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.TimeRewardConfig)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local Potions=require(game.ServerScriptService.Services.PotionService)
local Items=require(game.ServerScriptService.Services.ItemService)
local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
local Stage=require(game.ServerScriptService.World.StageManager)
local M={}
local sessions={}
local rng=Random.new()
local function stateFor(p)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players then return nil end
 local data=Data.Get(p)
 if not data or not data.Loaded or not data.Data then return nil end
 local s=sessions[p]
 if not s or s.Data~=data.Data then s={Data=data.Data,Records={},Busy=false};sessions[p]=s end
 return s,data
end
Players.PlayerRemoving:Connect(function(p) sessions[p]=nil end)
function M.GetState(p)
 local s=stateFor(p)
 if not s then return {Loaded=false} end
 local progress=Data.GetTimeRewards(p)
 local states={} local completed=true
 for _,reward in ipairs(Config.Rewards) do
  local record=s.Records[reward.Id]
  local status=progress.Claimed[reward.Id] and "Claimed"
   or (record and record.Status or (progress.ElapsedSeconds>=reward.RequiredSeconds and "Ready" or "Locked"))
  states[reward.Id]=status
  if status~="Claimed" then completed=false end
 end
 return {Loaded=true,ElapsedSeconds=progress.ElapsedSeconds,ClaimedRewards=progress.Claimed,
  States=states,Completed=completed,Potions=Potions.GetState(p)}
end
function M.Claim(p,id)
 local reward=Config.Get(id)
 if not reward then return false,"InvalidRewardId" end
 local s,data=stateFor(p)
 if not s then return false,"DataNotLoaded" end
 if s.Busy then return false,"ClaimInProgress" end
 local progress=Data.GetTimeRewards(p)
 if progress.Claimed[id] then return false,"AlreadyClaimed" end
 local previous=s.Records[id]
 if previous and previous.Resolving then return false,"ClaimInProgress" end
 if previous then return false,previous.Status,previous.Result end
 if progress.ElapsedSeconds<reward.RequiredSeconds then return false,"Locked" end
 if data.Saving or data.PendingItemMutation then return false,"DataSaving" end
 local amount=reward.Amount
 if typeof(amount)~="number" or amount~=amount or amount<=0 or amount==math.huge then return false,"InvalidAmount" end
 local record={Status="Pending",Resolving=true}
 s.Records[id]=record s.Busy=true
 local ok,success,code=xpcall(function()
  local result
  if reward.RewardType=="Win" then
   local win=p:GetAttribute("Win")
   if typeof(win)~="number" or win~=win or win<0 or amount%1~=0 or win+amount>=9007199254740991 then return false,"InvalidWin" end
   result={RewardType="Win",Amount=amount}
  elseif reward.RewardType=="Strength" then
   local base,interval=Training.GetNormalTrainingReference()
   if not base or not interval or interval<=0 then return false,"TrainingNotReady" end
   local reference=Strength.GetNormalTrainingGain(p,base)
   if not reference then return false,"InvalidReference" end
   result={RewardType="Strength",Amount=reference*(amount/interval),ReferenceTick=reference,Ticks=amount/interval}
  elseif reward.RewardType=="Potion" then
   if amount~=1 or not Config.Potions[reward.PotionId] then return false,"InvalidPotion" end
   result={RewardType="Potion",PotionId=reward.PotionId}
  elseif reward.RewardType=="ItemRoll" then
   if amount%1~=0 or amount>100 then return false,"InvalidRollCount" end
   local stage=Stage.GetCurrentStageNumber(p)
   local list,counts={},{}
   for i=1,amount do
    local itemId=Roller.RollItem(rng,stage)
    list[i]=itemId counts[itemId]=(counts[itemId] or 0)+1
   end
   result={RewardType="ItemRoll",Stage=stage,Items=list,Quantities=counts}
  else return false,"InvalidRewardType" end
  record.Result=result
  local context={Id=id,Result=result,ItemGrantSource="TimeReward"}
  if result.RewardType=="ItemRoll" then
   return Items.RunItemTransaction(p,function(token)
    for itemId,count in pairs(result.Quantities) do
     local added,reason=Items.AddItem(p,itemId,count,token)
     if not added then return false,reason end
    end
    return true,"Staged"
   end,context)
  end
  return Data.ClaimTimeReward(p,context)
 end,debug.traceback)
 record.Resolving=false
 s.Busy=false
 if not ok then record.Status="Failed";warn("[TimeReward] "..tostring(success));return false,"ClaimFailed" end
 if success then record.Status="Claimed";return true,"Claimed",record.Result end
 if code=="InventorySavePending" then return false,"Pending" end
 s.Records[id]=nil
 return false,code
end
return M
