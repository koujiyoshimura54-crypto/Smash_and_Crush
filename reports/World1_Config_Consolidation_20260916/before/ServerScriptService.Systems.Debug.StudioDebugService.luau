-- Studio-only commands. No normal gameplay service is patched.
local RunService=game:GetService("RunService")
local M={}
if not RunService:IsStudio() then
 function M.Execute() return false,"StudioOnly" end
 return M
end
local Players=game:GetService("Players")
local Data=require(game.ServerScriptService.Services.PlayerDataService)
local StoreConfig=require(game.ServerScriptService.Config.DataStoreConfig)
local Strength=require(game.ServerScriptService.Services.StrengthManager)
local Enemy=require(game.ServerScriptService.World.EnemyManager)
local Training=require(game.ServerScriptService.Services.TrainingManager)
local Trophy=require(game.ServerScriptService.Services.TrophyRewardService)
local Skip=require(game.ServerScriptService.Services.StageSkipService)
local Purchases=require(game.ServerScriptService.Systems.Purchases.ItemPurchaseService)
-- Enable only once the reset persistence target has been selected.
local RESET_SAVED_DATA=true
local busy=setmetatable({}, {__mode="k"})
local busyUserIds={}
local function validNumber(value)
 return typeof(value)=="number" and value==value and value>=0 and value<math.huge and value<=9007199254740991
end
local function lobby(player)
 local spawn=Trophy.GetLobbySpawn()
 local ch=player.Character
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not spawn or not ch or not hum or hum.Health<=0 then return false,"CharacterNotReady" end
 Training.StopTraining(player)
 Enemy.StartRun(player,1)
 hum.Health=hum.MaxHealth;hum.Sit=false
 local _,size=ch:GetBoundingBox()
 ch:PivotTo(spawn.CFrame*CFrame.new(0,spawn.Size.Y/2+math.max(size.Y/2,hum.HipHeight+2)+2,0))
 for _,p in ch:GetDescendants() do if p:IsA("BasePart") then p.AssemblyLinearVelocity=Vector3.zero;p.AssemblyAngularVelocity=Vector3.zero end end
 return true
end
local function reset(player)
 if not RESET_SAVED_DATA then return false,"ResetPersistenceNotConfigured" end
 local intent,reason=Purchases.GetPending(player)
 if intent or reason then return false,reason or "FinishPendingPurchaseFirst" end
 local s=Data.Get(player)
 if not s or not s.Loaded or s.Saving or s.PendingItemMutation then return false,"DataBusy" end
 if not Enemy.IsReady() then return false,"CombatNotReady" end
 local ch=player.Character
 local root=ch and ch:FindFirstChild("HumanoidRootPart")
 local hum=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 or not Trophy.GetLobbySpawn() then return false,"CharacterNotReady" end
 Training.StopTraining(player)
 local anchored=root.Anchored;root.Anchored=true
 local ok,err=Data.Reset(player)
 if root.Parent then root.Anchored=anchored end
 if not ok then return false,"ResetSaveFailed: "..tostring(err) end
 local fresh=Data.Get(player).Data
 Strength.ResetGainRemainder(player)
 Data.SetRebirthCount(player,0);Data.SetWin(player,0);Strength.SetStrength(player,0)
 for _,key in ipairs({"TotalStrengthEarned","DailyStrengthEarned","DailyDate","EquippedDumbbell"}) do player:SetAttribute(key,fresh[key]) end
 -- Old world items are part of the discarded test run, not the fresh inventory.
 local drops=workspace:FindFirstChild("BossItemDrops")
 if drops then for _,part in drops:GetChildren() do if part:GetAttribute("OwnerUserId")==player.UserId then part:Destroy() end end end
 lobby(player)
 local rankOK=pcall(function()
  game:GetService("DataStoreService"):GetOrderedDataStore(StoreConfig.GetName("TotalStrengthRanking_v1")):SetAsync(tostring(player.UserId),0)
  game:GetService("DataStoreService"):GetOrderedDataStore(StoreConfig.GetName("DailyStrengthRanking_"..fresh.DailyDate)):SetAsync(tostring(player.UserId),0)
 end)
 return true,rankOK and "Reset complete: Stage1 / Lv1 / Strength0 / Win0" or "Reset complete; ranking mirror will retry on autosave"
end
-- Read-only Studio snapshot; no production GUI and no player-state mutation.
function M.GetBalanceSnapshot(player)
 if not RunService:IsStudio() then return nil,"StudioOnly" end
 local session=Data.Get(player)
 if not session or not session.Loaded then return nil,"DataNotLoaded" end
 local RS=game:GetService("ReplicatedStorage")
 local BossConfig=require(RS.Config.World1LateStageConfig)
 local TreadmillConfig=require(RS.Config.TreadmillConfig)
 local Stage=require(game.ServerScriptService.World.StageManager)
 local Speed=require(game.ServerScriptService.Services.SpeedService)
 local Item=require(game.ServerScriptService.Services.ItemService)
 local Dumbbell=require(game.ServerScriptService.Services.DumbbellService)
 local Aura=require(game.ServerScriptService.Services.AuraService)
 local stage=Stage.GetCurrentStageNumber(player)
 local required=BossConfig.GetRequiredStrength(stage)
 local strength=Strength.GetStrength(player)
 local treadmill=Training.GetOccupiedTreadmill(player)
 local tier=treadmill and TreadmillConfig.Get(treadmill.Name)
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 return {
  PlayElapsedSeconds=workspace.DistributedGameTime,
  Stage=stage,Strength=strength,Level=Strength.GetLevel(player),
  Rebirth=Strength.GetRebirthCount(player),RebirthMultiplier=Strength.GetStrengthGainMultiplier(player),
  Dumbbell=Dumbbell.GetEquippedDumbbell(player) or "",Aura=Aura.GetEquippedAura(player) or "",
  Items=Item.GetEquippedItems(player),Treadmill=treadmill and treadmill.Name or "",
  TreadmillMultiplier=tier and tier.Multiplier or 1,
  Speed=Speed.GetState(player),AppliedWalkSpeed=h and h.WalkSpeed,
  Win=player:GetAttribute("Win"),BossMaxHP=BossConfig.GetMaxHP(stage),
  BossRequiredStrength=required,LotteryRatio=required and strength/required,
  LotteryChancePercent=required and strength<required and BossConfig.GetLotteryWinChance(strength/required)*100 or 0,
  LotteryRoute=required and strength>=required and "LEVEL_DAMAGE" or "LOTTERY",
  TrophyCollections=Trophy.GetStudioCollectionCounts(player),
 }
end
function M.Execute(player,message)
 if not RunService:IsStudio() then return false,"StudioOnly" end
 if typeof(player)~="Instance" or not player:IsA("Player") or player.Parent~=Players then return false,"InvalidPlayer" end
 if typeof(message)~="string" or #message>100 then return false,"InvalidCommand" end
 local words={}
 for word in message:gmatch("%S+") do words[#words+1]=word end
 local command=words[1] and words[1]:lower()
 local value=tonumber(words[2])
 local target=player
 local targetUserId=player.UserId
 local userIdSpecified=false
 if command=="/balance" then
  if #words~=1 then return false,"Usage: /balance" end
  local snapshot,reason=M.GetBalanceSnapshot(player)
  if not snapshot then return false,reason end
  return true,game:GetService("HttpService"):JSONEncode(snapshot)
 end
 if command=="/resetdata" then
  if #words==2 then
   if not validNumber(value) or value%1~=0 or value<1 then return false,"Usage: /resetdata [UserId]" end
   targetUserId=value
   target=Players:GetPlayerByUserId(targetUserId)
   userIdSpecified=true
  elseif #words~=1 then return false,"Usage: /resetdata [UserId]" end
 elseif command=="/setstrength" then
  if #words~=2 or not validNumber(value) then return false,"Usage: /setstrength non-negative finite number" end
 elseif command=="/setstage" then
  if #words~=2 or not validNumber(value) or value%1~=0 or value<1 or value>10 then return false,"Usage: /setstage 1-10" end
 else return false,"UnknownCommand" end
 if busy[player] then return false,"DebugBusy" end
 if command=="/resetdata" and busyUserIds[targetUserId] then return false,"DebugBusy" end
 local sessionTarget
 if command=="/resetdata" then
  -- Explicit UserId resets an offline Production record and do not depend on
  -- the command issuer's Studio PlayerData session state.
  sessionTarget=userIdSpecified and nil or player
 else
  sessionTarget=player
 end
 if sessionTarget then
  local session=Data.Get(sessionTarget)
  if not session or not session.Loaded then return false,"DataNotLoaded" end
  if session.Saving or session.PendingItemMutation then return false,"DataBusy" end
 end
 busy[player]=true
 if command=="/resetdata" then busyUserIds[targetUserId]=true end
 local ok,success,result=pcall(function()
  if command=="/resetdata" then
   if not RESET_SAVED_DATA then return false,"ResetPersistenceNotConfigured" end
   if not userIdSpecified then
    local studioOK,studioResult=reset(player)
    if not studioOK then return false,studioResult end
    local productionOK,productionResult=Data.ResetProductionByUserId(player.UserId,player)
    if not productionOK then return false,"Studio reset complete; ProductionResetFailed: "..tostring(productionResult) end
    print(("[StudioDebug] Production reset success: UserId=%d"):format(player.UserId))
    return true,"Studio and Production reset complete"
   end
   local resetOK,freshOrError=Data.ResetProductionByUserId(targetUserId)
   if not resetOK then return false,"ProductionResetFailed: "..tostring(freshOrError) end
   print(("[StudioDebug] Production reset success: UserId=%d"):format(targetUserId))
   return true,("Production reset success: UserId=%d"):format(targetUserId)
  end
  if command=="/setstrength" then
   Strength.ResetGainRemainder(player)
   Strength.SetStrength(player,value)
   return true,"Strength = "..value.." / Lv."..Strength.GetLevel(player)
  end
  if not Enemy.IsReady() then return false,"CombatNotReady" end
  if value==1 then local moved,code=lobby(player);return moved,code or "Stage1 / Lobby" end
  if not Skip.TryLock(player) then return false,"StageBusy" end
  local applied,moved,code=pcall(Skip.ApplyLocked,player,value)
  Skip.Unlock(player)
  if not applied then return false,tostring(moved) end
  return moved,code
 end)
 busy[player]=nil
 if command=="/resetdata" then busyUserIds[targetUserId]=nil end
 if not ok then return false,tostring(success) end
 return success,result
end
return M
