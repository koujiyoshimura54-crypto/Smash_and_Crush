local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.Config.DailyRewardConfig)
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local Items=require(game.ServerScriptService.Services.ItemService)
local Roller=require(game.ServerScriptService.Services.EnemyDropRoller)
local Stage=require(game.ServerScriptService.World.StageManager)
local Shop=require(game.ServerScriptService.Services.ShopRewardService)
local M={}
local rng=Random.new()
local sessions=setmetatable({}, {__mode="k"})
local function stateFor(p)
 if typeof(p)~="Instance" or not p:IsA("Player") or p.Parent~=Players then return nil end
 local data=Data.Get(p)
 if not data or not data.Loaded or not data.Data then return nil end
 local s=sessions[p]
 if not s or s.Data~=data.Data then s={Data=data.Data,Records={},Busy=false};sessions[p]=s end
 return s,data
end
function M.GetState(p)
 local s=stateFor(p)
 if not s then return {Loaded=false,HasReady=false} end
 local d=Data.GetDailyRewards(p)
 local states={} local ready=false
 for day=1,Config.GetDayCount() do
  local record=s.Records[day]
  local status=day<=d.ClaimedDays and "Claimed" or (record and record.Status or (day==d.CurrentDay and d.Ready and "Ready" or "Locked"))
  states["Day"..day]=status
  if status=="Ready" then ready=true end
 end
 local vip=Shop.GetState(p).VIPDaily
 states.VIP=vip.Status
 ready=ready or vip.Status=="Ready"
 return {Loaded=true,CurrentDay=d.CurrentDay,ClaimedDays=d.ClaimedDays,
  Completed=d.Completed,DateUTC=d.DateUTC,States=states,HasReady=ready}
end
function M.Claim(p,day)
 if day=="VIP" then return Shop.ClaimVIPDaily(p) end
 local reward=Config.Get(day)
 if not reward then return false,"InvalidDailyDay" end
 local s,data=stateFor(p)
 if not s then return false,"DataNotLoaded" end
 if s.Busy then return false,"ClaimInProgress" end
 local state=Data.GetDailyRewards(p)
 if day<=state.ClaimedDays then return false,"AlreadyClaimed" end
 if s.Records[day] then return false,s.Records[day].Status end
 if not state.Ready or day~=state.CurrentDay then return false,"DailyLocked" end
 if data.Saving or data.PendingItemMutation then return false,"DataSaving" end
 local record={Status="Pending"} s.Records[day]=record s.Busy=true
 local ok,success,code=xpcall(function()
  local result
  if reward.RewardType=="Win" then result={RewardType="Win",Amount=reward.Amount}
  elseif reward.RewardType=="Potion" then result={RewardType="Potion",PotionId=reward.PotionId}
  elseif reward.RewardType=="ItemRoll" then
   local stage=Stage.GetCurrentStageNumber(p)
   local list,counts={},{}
   for i=1,reward.Amount do
    local id=Roller.RollItem(rng,stage,Config.GetRarityWeights(day))
    list[i]=id counts[id]=(counts[id] or 0)+1
   end
   result={RewardType="ItemRoll",Stage=stage,Items=list,Quantities=counts}
  else return false,"InvalidRewardType" end
  record.Result=result
  local context={DailyDay=day,Result=result,ItemGrantSource="DailyReward"}
  if result.RewardType=="ItemRoll" then
   return Items.RunItemTransaction(p,function(token)
    for id,count in pairs(result.Quantities) do
     local added,reason=Items.AddItem(p,id,count,token)
     if not added then return false,reason end
    end
    return true,"Staged"
   end,context)
  end
  return Data.ClaimDailyReward(p,context)
 end,debug.traceback)
 s.Busy=false
 if not ok then record.Status="Failed";warn("[DailyReward] "..tostring(success));return false,"ClaimFailed" end
 if success then record.Status="Claimed";return true,"Claimed",record.Result end
 if code=="InventorySavePending" then return false,"Pending" end
 s.Records[day]=nil return false,code
end
Players.PlayerRemoving:Connect(function(p) sessions[p]=nil end)
return M
