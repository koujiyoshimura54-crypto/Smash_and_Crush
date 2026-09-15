return function(TestDSS,TestStrength)
local DSS=TestDSS
local HttpService=game:GetService("HttpService")
local DumbbellItemMaster=require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))
local AuraConfig=require(game:GetService("ReplicatedStorage").Config:WaitForChild("AuraConfig"))
local TimeRewardConfig=require(game.ReplicatedStorage.Config:WaitForChild("TimeRewardConfig"))
local DailyRewardConfig=require(game.ReplicatedStorage.Config:WaitForChild("DailyRewardConfig"))
local CommunityConfig=require(game.ReplicatedStorage.Config:WaitForChild("CommunityRewardConfig"))
local ShopConfig=require(game.ReplicatedStorage.Config:WaitForChild("ShopProductConfig"))
local LevelProgression=require(game.ReplicatedStorage.Modules.LevelProgression)
local PlayerDataService={}
local StoreConfig=require(game.ServerScriptService.Config:WaitForChild("DataStoreConfig"))
local store=DSS:GetDataStore(StoreConfig.GetName("PlayerData_v1"))
local sessions=setmetatable({}, {__mode="k"})
local TOTAL_STORE=StoreConfig.GetName("TotalStrengthRanking_v1")
local JST_OFFSET=9*60*60

local function today()
 return os.date("!%Y-%m-%d", os.time()+JST_OFFSET)
end
local function finite(v)
 return typeof(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local MAX_COUNT=9007199254740991
local function itemCount(value)
 if value==true then return 1 end
 if value==false or value==nil then return 0 end
 if finite(value) and value>=0 and value%1==0 and value<=MAX_COUNT then return value end
 return nil
end
local function normalizeItems(raw)
 if raw~=nil and typeof(raw)~="table" then return nil,"Invalid OwnedItems" end
 local result={}
 for id,value in pairs(raw or {}) do
  local count=itemCount(value)
  if typeof(id)~="string" or id=="" or count==nil then return nil,"Invalid OwnedItems entry" end
  if count>0 then result[id]=count end -- zero is always represented by an absent key
 end
 return result
end
local function normalizeSpeeds(raw)
 if raw~=nil and typeof(raw)~="table" then return nil,"Invalid OwnedSpeeds" end
 local owned={}
 for id,value in pairs(raw or {}) do
  if typeof(id)~="string" or id=="" or value~=true then return nil,"Invalid OwnedSpeeds entry" end
  owned[id]=true
 end
 return owned
end
local function metadata(info)
 return info and info:GetUserIds() or {}, info and info:GetMetadata() or {}
end

local function normalizeTimeRewards(raw)
 local t={ElapsedSeconds=0,Claimed={}}
 if raw==nil then return t end
 if typeof(raw)~="table" then return nil,"Invalid TimeRewards" end
 if raw.ElapsedSeconds~=nil then
  if not finite(raw.ElapsedSeconds) or raw.ElapsedSeconds<0 then return nil,"Invalid TimeRewards elapsed" end
  t.ElapsedSeconds=raw.ElapsedSeconds
 end
 if raw.Claimed~=nil then
  if typeof(raw.Claimed)~="table" then return nil,"Invalid TimeRewards claims" end
  for id,value in pairs(raw.Claimed) do
   if typeof(id)~="string" or value~=true then return nil,"Invalid TimeRewards claim" end
   t.Claimed[id]=true
  end
 end
 return t
end
local function mergeTimeRewards(a,b)
 local x=assert(normalizeTimeRewards(a))
 local y=assert(normalizeTimeRewards(b))
 x.ElapsedSeconds=math.max(x.ElapsedSeconds,y.ElapsedSeconds)
 for id in pairs(y.Claimed) do x.Claimed[id]=true end
 return x
end
local function timeRewardLimit()
 local limit=0 for _,r in ipairs(TimeRewardConfig.Rewards) do limit=math.max(limit,r.RequiredSeconds) end return limit
end

-- Independent from the JST daily Strength leaderboard and Time Rewards.
local function dailyUTC() return os.date("!%Y-%m-%d",os.time()) end
local function normalizeDailyRewards(raw)
 if raw==nil then return {ClaimedDays=0,LastClaimDateUTC=""} end
 if typeof(raw)~="table" then return nil,"Invalid DailyRewards" end
 local count=raw.ClaimedDays
 local date=raw.LastClaimDateUTC
 if not finite(count) or count%1~=0 or count<0 or count>DailyRewardConfig.GetDayCount() then return nil,"Invalid DailyRewards count" end
 if typeof(date)~="string" or (count==0 and date~="") or (count>0 and not date:match("^%d%d%d%d%-%d%d%-%d%d$")) then return nil,"Invalid DailyRewards date" end
 return {ClaimedDays=count,LastClaimDateUTC=date}
end
local function mergeDailyRewards(a,b)
 local x=assert(normalizeDailyRewards(a)) local y=assert(normalizeDailyRewards(b))
 if y.ClaimedDays>x.ClaimedDays then return y end
 if y.ClaimedDays==x.ClaimedDays and y.LastClaimDateUTC>x.LastClaimDateUTC then return y end
 return x
end

local function normalizeCommunity(raw)
 if raw==nil then return {Claimed=false} end
 if typeof(raw)~="table" or typeof(raw.Claimed)~="boolean" then return nil,"Invalid CommunityRewards" end
 return {Claimed=raw.Claimed}
end
local function mergeCommunity(a,b)
 return {Claimed=assert(normalizeCommunity(a)).Claimed or assert(normalizeCommunity(b)).Claimed}
end
-- Additive fields only; missing fields are legacy data and receive safe defaults.
local function normalizeShop(raw)
 local out={Claims={},VIPDailyDateUTC="",WinReceipts={},PotionExpiresUTC={},WinGrantedTotal=0}
 if raw==nil then return out end
 if typeof(raw)~="table" then return nil,"Invalid ShopRewards" end
 local total=raw.WinGrantedTotal or 0
 if not finite(total) or total<0 or total%1~=0 or total>MAX_COUNT then return nil,"Invalid Shop Win total" end
 out.WinGrantedTotal=total
 for _,field in ipairs({"Claims","WinReceipts"}) do
  if raw[field]~=nil and typeof(raw[field])~="table" then return nil,"Invalid ShopRewards "..field end
  for id,v in pairs(raw[field] or {}) do
   if typeof(id)~="string" or id=="" or v~=true then return nil,"Invalid ShopRewards marker" end
   out[field][id]=true
  end
 end
 local date=raw.VIPDailyDateUTC or ""
 if typeof(date)~="string" or (date~="" and not date:match("^%d%d%d%d%-%d%d%-%d%d$")) then return nil,"Invalid VIP daily date" end
 out.VIPDailyDateUTC=date
 if raw.PotionExpiresUTC~=nil and typeof(raw.PotionExpiresUTC)~="table" then return nil,"Invalid Shop potion deadlines" end
 for id,v in pairs(raw.PotionExpiresUTC or {}) do
  if typeof(id)~="string" or not finite(v) or v<0 then return nil,"Invalid Shop potion deadline" end
  out.PotionExpiresUTC[id]=v
 end
 return out
end
local function mergeShop(a,b)
 local x=assert(normalizeShop(a));local y=assert(normalizeShop(b))
 for _,field in ipairs({"Claims","WinReceipts"}) do for id in pairs(y[field]) do x[field][id]=true end end
 x.WinGrantedTotal=math.max(x.WinGrantedTotal,y.WinGrantedTotal)
 if y.VIPDailyDateUTC>x.VIPDailyDateUTC then x.VIPDailyDateUTC=y.VIPDailyDateUTC end
 for id,v in pairs(y.PotionExpiresUTC) do x.PotionExpiresUTC[id]=math.max(x.PotionExpiresUTC[id] or 0,v) end
 return x
end
local function normalizeUnlockedWorld(value)
 if value==nil then return 1 end
 if not finite(value) or value<1 or value%1~=0 or value>MAX_COUNT then
  return nil,"Invalid HighestUnlockedWorld"
 end
 return value
end
local function defaults()
 return {Level=1,LevelProgress=0,LevelProgressVersion=LevelProgression.Version,HighestUnlockedWorld=1,ShopRewards=assert(normalizeShop(nil)),CommunityRewards={Claimed=false},DailyRewards={ClaimedDays=0,LastClaimDateUTC=""},TimeRewards={ElapsedSeconds=0,Claimed={}}, TutorialCompleted=false, Strength=0, RebirthCount=0, TotalStrengthEarned=0, DailyStrengthEarned=0, DailyDate=today(), Win=0, OwnedSpeeds={}, OwnedDumbbells={}, EquippedDumbbell="", OwnedAuras={}, EquippedAura="", OwnedItems={}, EquippedItems={Protein="",Glove="",TrainingBelt=""}}
end
-- Only an existing, owned Dumbbell can survive loading as equipped.
local function validEquipped(itemId,owned)
 if typeof(itemId)~="string" or itemId=="" or owned[itemId]~=true then return "" end
 local item=DumbbellItemMaster.Get(itemId)
 return item and item.Category=="Dumbbell" and itemId or ""
end
local function normalize(raw)
 local d=defaults()
 if typeof(raw)=="table" and typeof(raw.ResetToken)=="string" then d.ResetToken=raw.ResetToken end
 if typeof(raw)=="table" then
  local world,worldError=normalizeUnlockedWorld(raw.HighestUnlockedWorld)
  if not world then return nil,worldError end
  d.HighestUnlockedWorld=world
  local shop,shopError=normalizeShop(raw.ShopRewards)
  if not shop then return nil,shopError end
  d.ShopRewards=shop
  local community,communityError=normalizeCommunity(raw.CommunityRewards)
  if not community then return nil,communityError end
  d.CommunityRewards=community
  local timeRewards,err=normalizeTimeRewards(raw.TimeRewards)
  if not timeRewards then return nil,err end
  d.TimeRewards=timeRewards
  local dailyRewards,dailyError=normalizeDailyRewards(raw.DailyRewards)
  if not dailyRewards then return nil,dailyError end
  d.DailyRewards=dailyRewards
  d.TutorialCompleted=raw.TutorialCompleted==true
  if finite(raw.Strength) then d.Strength=math.max(0,raw.Strength) end
  local level,progress=LevelProgression.Normalize(raw)
  if not level then return nil,progress end
  d.Level=level
  d.LevelProgress=progress
  if finite(raw.RebirthCount) then d.RebirthCount=math.max(0,math.floor(raw.RebirthCount)) end
  if finite(raw.TotalStrengthEarned) then d.TotalStrengthEarned=math.max(0,raw.TotalStrengthEarned) end
  if finite(raw.DailyStrengthEarned) then d.DailyStrengthEarned=math.max(0,raw.DailyStrengthEarned) end
  if typeof(raw.DailyDate)=="string" then d.DailyDate=raw.DailyDate end
  if finite(raw.Win) then d.Win=math.max(0,math.floor(raw.Win)) end
  local speeds,speedError=normalizeSpeeds(raw.OwnedSpeeds)
  if not speeds then return nil,speedError end
  d.OwnedSpeeds=speeds
  -- Missing inventory is legacy data. Never replace a malformed saved inventory.
  if raw.OwnedDumbbells~=nil then
   if typeof(raw.OwnedDumbbells)~="table" then return nil,"Invalid OwnedDumbbells" end
   for itemId,owned in pairs(raw.OwnedDumbbells) do
    if typeof(itemId)~="string" or itemId=="" or owned~=true then
     return nil,"Invalid OwnedDumbbells entry"
    end
    -- Preserve unknown IDs so future definitions do not lose ownership.
    d.OwnedDumbbells[itemId]=true
   end
  end
  if raw.OwnedAuras~=nil then
   if typeof(raw.OwnedAuras)~="table" then return nil,"Invalid OwnedAuras" end
   for id,owned in pairs(raw.OwnedAuras) do
    if typeof(id)~="string" or id=="" or owned~=true then return nil,"Invalid OwnedAuras entry" end
    d.OwnedAuras[id]=true -- Preserve unknown IDs without activating them.
   end
  end
  local equipped=raw.EquippedAura or raw.SelectedAura
  if typeof(equipped)=="string" and d.OwnedAuras[equipped]==true and AuraConfig.Get(equipped) then
   d.EquippedAura=equipped
  end
  local owned,inventoryError=normalizeItems(raw.OwnedItems)
  if not owned then return nil,inventoryError end
  d.OwnedItems=owned
  -- Add defaults only for missing slots. Reject malformed data without saving over it.
  if raw.EquippedItems~=nil then
   if typeof(raw.EquippedItems)~="table" then return nil,"Invalid EquippedItems" end
   for itemType,itemId in pairs(raw.EquippedItems) do
    if typeof(itemType)~="string" or typeof(itemId)~="string" then
     return nil,"Invalid EquippedItems entry"
    end
    d.EquippedItems[itemType]=itemId
   end
  end
 end
 if typeof(raw)=="table" then
  d.EquippedDumbbell=validEquipped(raw.EquippedDumbbell,d.OwnedDumbbells)
 end
 if d.DailyDate~=today() then
  d.DailyDate=today()
  d.DailyStrengthEarned=0
 end
 return d
end
local function applyAttributes(player,d)
 player:SetAttribute("HighestUnlockedWorld",d.HighestUnlockedWorld)
 player:SetAttribute("TutorialCompleted",d.TutorialCompleted==true)
 player:SetAttribute("Strength",d.Strength)
 player:SetAttribute("LevelProgress",d.LevelProgress)
 player:SetAttribute("Level",d.Level)
 player:SetAttribute("RebirthCount",d.RebirthCount)
 player:SetAttribute("TotalStrengthEarned",d.TotalStrengthEarned)
 player:SetAttribute("DailyStrengthEarned",d.DailyStrengthEarned)
 player:SetAttribute("DailyDate",d.DailyDate)
 player:SetAttribute("Win",d.Win)
 -- Output mirror only: never read this Attribute as equipment authority.
 player:SetAttribute("EquippedDumbbell",d.EquippedDumbbell)
 player:SetAttribute("EquippedAura",d.EquippedAura)
end
local function keyForUserId(userId) return "Player_"..tostring(userId) end
local function key(player) return keyForUserId(player.UserId) end

function PlayerDataService.Get(player)
 local s=sessions[player]
 return s
end
-- Called by state reads and every regular save, including leave/shutdown saves.
function PlayerDataService.GetTimeRewards(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil end
 local now=os.clock()
 local previous=s.TimeRewardClock or now
 s.TimeRewardClock=now
 local t=s.Data.TimeRewards
 local elapsed=math.min(timeRewardLimit(),t.ElapsedSeconds+math.max(0,now-previous))
 if elapsed~=t.ElapsedSeconds then t.ElapsedSeconds=elapsed;s.Dirty=true end
 return {ElapsedSeconds=t.ElapsedSeconds,Claimed=table.clone(t.Claimed)}
end
function PlayerDataService.GetDailyRewards(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil end
 local d=s.Data.DailyRewards
 local date=dailyUTC()
 return {ClaimedDays=d.ClaimedDays,LastClaimDateUTC=d.LastClaimDateUTC,
  CurrentDay=math.min(DailyRewardConfig.GetDayCount(),d.ClaimedDays+1),Completed=d.ClaimedDays==DailyRewardConfig.GetDayCount(),
  Ready=d.ClaimedDays<DailyRewardConfig.GetDayCount() and d.LastClaimDateUTC<date,DateUTC=date}
end
function PlayerDataService.IsLoaded(player)
 local s=sessions[player]
 return s~=nil and s.Loaded==true
end
function PlayerDataService.IsSaving(player)
 local s=sessions[player]
 return s~=nil and s.Saving==true
end
function PlayerDataService.WaitForSave(player,timeout)
 local deadline=os.clock()+(tonumber(timeout) or 30)
 while true do
  local s=sessions[player]
  if not s or not s.Saving then return true end
  if os.clock()>=deadline then return false end
  task.wait(0.05)
 end
end
function PlayerDataService.Today() return today() end

-- Persisted generation barrier: stale saves cannot overwrite a completed reset.
local function resetToken(raw)
 if typeof(raw)=="table" and typeof(raw.ResetToken)=="string" then return raw.ResetToken end
 return nil
end

local resetByUserIdBusy={}

local function validUserId(userId)
 return finite(userId) and userId%1==0 and userId>=1
end

local function freshResetData()
 local fresh=defaults()
 fresh.ResetToken=HttpService:GenerateGUID(false)
 return fresh
end

local function writeFreshReset(userId,fresh)
 local saved
 local ok,err=pcall(function()
  saved=store:UpdateAsync(keyForUserId(userId),function(old,info)
   local users,meta=metadata(info)
   local merged=typeof(old)=="table" and table.clone(old) or {}
   for field,value in pairs(fresh) do
    merged[field]=typeof(value)=="table" and table.clone(value) or value
   end
   merged.ResetToken=fresh.ResetToken
   return merged,users,meta
  end)
 end)
 if not ok then return false,tostring(err) end
 return true,saved
end

function PlayerDataService.Reset(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return false,"DataBusy" end
 local userId=player.UserId
 if resetByUserIdBusy[userId] then return false,"ResetBusy" end
 resetByUserIdBusy[userId]=true
 local fresh=freshResetData()
 s.Saving=true
 s.Loaded=false
 local ok,saved=writeFreshReset(userId,fresh)
 if not ok then
  s.Loaded=true
  s.Saving=false
  resetByUserIdBusy[userId]=nil
  return false,saved
 end
 s.Data=fresh
 s.TimeRewardClock=os.clock()
 s.Loaded=true
 s.Saving=false
 s.Dirty=true
 s.LastSave=nil
 applyAttributes(player,fresh)
 player:SetAttribute("TutorialResetSequence",(player:GetAttribute("TutorialResetSequence") or 0)+1)
 resetByUserIdBusy[userId]=nil
 return true,fresh
end

function PlayerDataService.ResetByUserId(userId)
 if not validUserId(userId) then return false,"InvalidUserId" end
 if game:GetService("Players"):GetPlayerByUserId(userId) then return false,"PlayerOnline" end
 if resetByUserIdBusy[userId] then return false,"ResetBusy" end
 resetByUserIdBusy[userId]=true
 local fresh=freshResetData()
 local ok,result=writeFreshReset(userId,fresh)
 resetByUserIdBusy[userId]=nil
 if not ok then return false,result end
 return true,fresh
end

function PlayerDataService.Load(player)
 local existing=sessions[player]
 if existing and existing.Loaded then return true,existing.Data end
 if existing and existing.Loading then return false,"DataLoading" end
 local loadId=HttpService:GenerateGUID(false)
 sessions[player]={Loaded=false,Data=nil,Saving=false,Loading=true,LoadId=loadId}
 local ok,raw=pcall(function() return store:GetAsync(key(player)) end)
 local current=sessions[player]
 if not current or current.LoadId~=loadId then return false,"LoadSuperseded" end
 if not ok then
  sessions[player]={Loaded=false,Data=nil,Saving=false}
  return false,"DataStore load failed: "..tostring(raw)
 end
 local d,validationError=normalize(raw)
 if not d then
  sessions[player]={Loaded=false,Data=nil,Saving=false}
  return false,validationError
 end
 sessions[player]={Loaded=true,Data=d,Dirty=true,Saving=false,LastSave=nil,Loading=false,TimeRewardClock=os.clock()}
 applyAttributes(player,d)
 return true,d
end

-- Server-only setter; data and its Attribute mirror change without yielding.
function PlayerDataService.SetEquippedDumbbell(player,itemId)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving then return false,"DataSaving" end
 if typeof(itemId)~="string" then return false,"InvalidItemId" end
 if itemId~="" then
  local item=DumbbellItemMaster.Get(itemId)
  if not item then return false,"InvalidItemId" end
  if item.Category~="Dumbbell" then return false,"InvalidCategory" end
  if s.Data.OwnedDumbbells[itemId]~=true then return false,"NotOwned" end
 end
 if s.Data.EquippedDumbbell==itemId then return true,"AlreadyEquipped" end
 s.Data.EquippedDumbbell=itemId
 s.Dirty=true
 player:SetAttribute("EquippedDumbbell",itemId)
 return true,itemId=="" and "Unequipped" or "Equipped"
end

-- Single-slot Aura authority. The Attribute is an output mirror only.
function PlayerDataService.SetEquippedAura(player,auraId)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving then return false,"DataSaving" end
 if typeof(auraId)~="string" then return false,"InvalidAuraId" end
 if auraId~="" then
  if not AuraConfig.Get(auraId) then return false,"InvalidAuraId" end
  if s.Data.OwnedAuras[auraId]~=true then return false,"NotOwned" end
 end
 s.Data.EquippedAura=auraId
 s.Dirty=true
 player:SetAttribute("EquippedAura",auraId)
 return true,auraId=="" and "Unequipped" or "Equipped"
end

function PlayerDataService.SetCurrentStrength(player,value)
 local s=sessions[player]
 if not s or not s.Loaded then return false end
 if not finite(value) then return false end
 s.Data.Strength=math.max(0,value)
 player:SetAttribute("Strength",s.Data.Strength)
 s.Dirty=true
 return true
end
-- Output mirrors only; saved progression never reads client-facing attributes.
function PlayerDataService.GetLevelState(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil end
 return s.Data.Level,s.Data.LevelProgress
end
function PlayerDataService.AddStrengthGain(player,gain)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 local d=s.Data
 local strength,level,progress=LevelProgression.ApplyGain(d,gain)
 if not strength then return nil,level end
 if gain==0 then return d.Strength end
 d.Strength,d.Level,d.LevelProgress=strength,level,progress
 s.Dirty=true
 player:SetAttribute("Strength",strength)
 player:SetAttribute("LevelProgress",progress)
 player:SetAttribute("Level",level)
 PlayerDataService.RecordStrengthGain(player,gain)
 return strength
end
function PlayerDataService.ResetStrengthProgress(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 local d=s.Data
 d.Strength,d.Level,d.LevelProgress=0,1,0
 s.Dirty=true
 player:SetAttribute("Strength",0)
 player:SetAttribute("LevelProgress",0)
 player:SetAttribute("Level",1)
 return true
end
function PlayerDataService.SetRebirthCount(player,value)
 local s=sessions[player]
 if not s or not s.Loaded then return false end
 s.Data.RebirthCount=math.max(0,math.floor(tonumber(value) or 0))
 player:SetAttribute("RebirthCount",s.Data.RebirthCount)
 s.Dirty=true
 return true
end
function PlayerDataService.SetWin(player,value)
 local s=sessions[player]
 if not s or not s.Loaded then return false end
 local n=tonumber(value)
 if not finite(n) then return false end
 s.Data.Win=math.max(0,math.floor(n))
 player:SetAttribute("Win",s.Data.Win)
 s.Dirty=true
 return true
end
function PlayerDataService.RecordStrengthGain(player,amount)
 local s=sessions[player]
 local gain=tonumber(amount) or 0
 if not s or not s.Loaded or gain<=0 then return false end
 local d=s.Data
 local now=today()
 if d.DailyDate~=now then
  d.DailyDate=now
  d.DailyStrengthEarned=0
 end
 d.Strength=math.max(0,tonumber(player:GetAttribute("Strength")) or d.Strength)
 d.TotalStrengthEarned+=gain
 d.DailyStrengthEarned+=gain
 s.Dirty=true
 player:SetAttribute("TotalStrengthEarned",d.TotalStrengthEarned)
 player:SetAttribute("DailyStrengthEarned",d.DailyStrengthEarned)
 player:SetAttribute("DailyDate",d.DailyDate)
 return true
end

local function saveOrdered(name,userKey,value)
 return pcall(function()
  DSS:GetOrderedDataStore(name):SetAsync(userKey,math.max(0,math.floor(tonumber(value) or 0)))
 end)
end

function PlayerDataService.Save(player,equipAuraOnSuccess)
 local s=sessions[player]
 PlayerDataService.GetTimeRewards(player)
 if s and s.PendingItemMutation then
  local resolved,reason=PlayerDataService.ResolveItemMutation(player)
  if not resolved then return false,reason end
 end
 if not s or not s.Loaded or not s.Data then return false,"not loaded" end
 if s.Saving then return false,"saving" end
 if not s.Dirty and s.LastSave and os.clock()-s.LastSave<10 then return true,"already saved" end
 if equipAuraOnSuccess~=nil and (not AuraConfig.Get(equipAuraOnSuccess) or s.Data.OwnedAuras[equipAuraOnSuccess]~=true) then return false,"InvalidAuraEquip" end
 s.Saving=true
 local d=s.Data
 local saveToken=d.ResetToken
 d.Strength=math.max(0,tonumber(player:GetAttribute("Strength")) or d.Strength)
 d.RebirthCount=math.max(0,math.floor(tonumber(player:GetAttribute("RebirthCount")) or d.RebirthCount))
 d.Win=math.max(0,math.floor(tonumber(player:GetAttribute("Win")) or d.Win))
 local now=today()
 if d.DailyDate~=now then
  d.DailyDate=now
  d.DailyStrengthEarned=0
 end
 local payload={
  HighestUnlockedWorld=d.HighestUnlockedWorld,
  ShopRewards=assert(normalizeShop(d.ShopRewards)),
  CommunityRewards=assert(normalizeCommunity(d.CommunityRewards)),
  TimeRewards=assert(normalizeTimeRewards(d.TimeRewards)),
  DailyRewards=assert(normalizeDailyRewards(d.DailyRewards)),
  TutorialCompleted=d.TutorialCompleted==true,
  Strength=d.Strength,
  Level=d.Level,
  LevelProgress=d.LevelProgress,
  LevelProgressVersion=LevelProgression.Version,
  RebirthCount=d.RebirthCount,
  TotalStrengthEarned=d.TotalStrengthEarned,
  DailyStrengthEarned=d.DailyStrengthEarned,
  DailyDate=d.DailyDate,
  Win=d.Win,
  OwnedSpeeds=table.clone(d.OwnedSpeeds),
  OwnedDumbbells=table.clone(d.OwnedDumbbells),
  EquippedDumbbell=d.EquippedDumbbell,
  OwnedAuras=table.clone(d.OwnedAuras),
  EquippedAura=equipAuraOnSuccess or d.EquippedAura,
  OwnedItems=table.clone(d.OwnedItems),
  EquippedItems=table.clone(d.EquippedItems),
  ResetToken=saveToken
 }
 -- Consume only the dirty generation captured by this snapshot. Mutations during
 -- either DataStore call set Dirty again and must be saved by a later pass.
 s.Dirty=false
 local saved
 local superseded=false
 local ok,err=pcall(function()
  saved=store:UpdateAsync(key(player),function(old,info)
   local users,meta=metadata(info)
   if old==nil then return payload,users,meta end
   if typeof(old)~="table" then error("Invalid saved PlayerData") end
   if resetToken(old)~=saveToken then superseded=true; return old,users,meta end
   local merged=table.clone(old)
   merged.HighestUnlockedWorld=math.max(assert(normalizeUnlockedWorld(old.HighestUnlockedWorld)),payload.HighestUnlockedWorld)
   merged.ShopRewards=mergeShop(old.ShopRewards,payload.ShopRewards)
   merged.CommunityRewards=mergeCommunity(old.CommunityRewards,payload.CommunityRewards)
   merged.TimeRewards=mergeTimeRewards(old.TimeRewards,payload.TimeRewards)
   merged.DailyRewards=mergeDailyRewards(old.DailyRewards,payload.DailyRewards)
   merged.TutorialCompleted=old.TutorialCompleted==true or payload.TutorialCompleted
   merged.Strength=payload.Strength
   merged.Level=payload.Level
   merged.LevelProgress=payload.LevelProgress
   merged.LevelProgressVersion=payload.LevelProgressVersion
   merged.RebirthCount=math.max(tonumber(old.RebirthCount) or 0,payload.RebirthCount)
   merged.TotalStrengthEarned=math.max(tonumber(old.TotalStrengthEarned) or 0,payload.TotalStrengthEarned)
   -- Preserve paid credits committed by a newer session after this snapshot.
   merged.Win=payload.Win+math.max(0,merged.ShopRewards.WinGrantedTotal-payload.ShopRewards.WinGrantedTotal)
   merged.OwnedSpeeds=assert(normalizeSpeeds(old.OwnedSpeeds))
   for id in pairs(payload.OwnedSpeeds) do merged.OwnedSpeeds[id]=true end
   merged.OwnedDumbbells=table.clone(payload.OwnedDumbbells)
   merged.EquippedDumbbell=payload.EquippedDumbbell
   merged.OwnedAuras=table.clone(payload.OwnedAuras)
   for key in pairs(merged.ShopRewards.Claims) do local product=ShopConfig.Get(key)
    if product and product.AuraId and old.OwnedAuras and old.OwnedAuras[product.AuraId] then merged.OwnedAuras[product.AuraId]=true end
   end
   merged.EquippedAura=payload.EquippedAura
   -- Quantity changes are committed by their own UpdateAsync transaction.
   -- Never overwrite a newer count with an autosave's stale inventory snapshot.
   merged.OwnedItems=assert(normalizeItems(old.OwnedItems))
   merged.EquippedItems=table.clone(payload.EquippedItems)
   if old.DailyDate==payload.DailyDate then
    merged.DailyStrengthEarned=math.max(tonumber(old.DailyStrengthEarned) or 0,payload.DailyStrengthEarned)
    merged.DailyDate=payload.DailyDate
   else
    merged.DailyDate=payload.DailyDate
    merged.DailyStrengthEarned=payload.DailyStrengthEarned
   end
   return merged,users,meta
  end)
 end)
 if not ok then
  s.Dirty=true
  s.Saving=false
  return false,tostring(err)
 end
 if superseded then
  local current,validationError=normalize(saved)
  if not current then s.Saving=false; return false,validationError end
  s.Data=current
  s.Dirty=false
  s.Saving=false
  s.LastSave=os.clock()
  applyAttributes(player,current)
  return false,"SaveSupersededByReset"
 end
 -- The persisted snapshot is never copied over live state after a yielding save.
 if sessions[player]~=s or s.Data~=d then s.Saving=false;return false,"SaveSuperseded" end
 d.HighestUnlockedWorld=math.max(d.HighestUnlockedWorld,assert(normalizeUnlockedWorld(saved.HighestUnlockedWorld)))
 player:SetAttribute("HighestUnlockedWorld",d.HighestUnlockedWorld)
 local unseenShopWin=math.max(0,saved.ShopRewards.WinGrantedTotal-d.ShopRewards.WinGrantedTotal)
 d.ShopRewards=mergeShop(d.ShopRewards,saved.ShopRewards)
 if unseenShopWin>0 then PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+unseenShopWin) end
 for key in pairs(d.ShopRewards.Claims) do local product=ShopConfig.Get(key)
  if product and product.AuraId and saved.OwnedAuras and saved.OwnedAuras[product.AuraId] then d.OwnedAuras[product.AuraId]=true end
 end
 if equipAuraOnSuccess then
  d.EquippedAura=equipAuraOnSuccess
  player:SetAttribute("EquippedAura",equipAuraOnSuccess)
 end
 local totalOK=saveOrdered(TOTAL_STORE,tostring(player.UserId),payload.TotalStrengthEarned)
 local dailyOK=saveOrdered(StoreConfig.GetName("DailyStrengthRanking_"..payload.DailyDate),tostring(player.UserId),payload.DailyStrengthEarned)
 s.Saving=false
 s.LastSave=os.clock()
 if not totalOK or not dailyOK then
  warn("Player ranking mirror save failed for "..player.Name)
 end
 return true
end

-- Called only by the server after a confirmed Stage 1 Trophy pickup.
-- Do not yield in the reward/teleport transaction. Reuse the regular save lock
-- and ResetToken barrier, and abandon retries when Reset replaces this data.
function PlayerDataService.CompleteTutorial(player)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 local data=s.Data
 if data.TutorialCompleted then return true end
 data.TutorialCompleted=true
 s.Dirty=true
 player:SetAttribute("TutorialCompleted",true)
 task.defer(function()
  for attempt=1,3 do
   if sessions[player]~=s or s.Data~=data or not s.Loaded then return end
   if PlayerDataService.WaitForSave(player,30) then
    if sessions[player]~=s or s.Data~=data or not s.Loaded then return end
    s.Dirty=true
    local ok=PlayerDataService.Save(player)
    if ok then return end
   end
   task.wait(attempt)
  end
  if sessions[player]==s and s.Data==data then
   s.Dirty=true
   warn("Tutorial completion save pending for "..player.Name.."; existing autosave will retry")
  end
 end)
 return true
end

-- Permanent progression is server-owned; Attributes are replication mirrors only.
-- Call only after a validated final-stage RewardPad has been credited and consumed.
function PlayerDataService.CanAccessWorld(player,world)
 local s=sessions[player]
 return finite(world) and world>=1 and world%1==0
  and s~=nil and s.Loaded==true and s.Data~=nil
  and s.Data.HighestUnlockedWorld>=world
end
function PlayerDataService.UnlockWorld(player,world)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 local value=normalizeUnlockedWorld(world)
 if not value then return false,"InvalidWorld" end
 local data=s.Data
 if data.HighestUnlockedWorld>=value then return true,"AlreadyUnlocked" end
 data.HighestUnlockedWorld=math.max(data.HighestUnlockedWorld,value)
 s.Dirty=true
 player:SetAttribute("HighestUnlockedWorld",data.HighestUnlockedWorld)
 -- Same save queue/reset barrier as tutorial completion. Never yield inside pickup.
 task.defer(function()
  for attempt=1,3 do
   if sessions[player]~=s or s.Data~=data or not s.Loaded then return end
   if PlayerDataService.WaitForSave(player,30) then
    if sessions[player]~=s or s.Data~=data or not s.Loaded then return end
    s.Dirty=true
    local ok=PlayerDataService.Save(player)
    if ok then return end
   end
   task.wait(attempt)
  end
  if sessions[player]==s and s.Data==data then
   s.Dirty=true
   warn("World unlock save pending for "..player.Name.."; existing autosave will retry")
  end
 end)
 return true,"Unlocked"
end

-- All regular-item quantity mutations are durable before reporting success.
-- A failed/ambiguous write keeps its operation ID and local Win reservation;
-- Save retries the same operation rather than refunding a possibly committed purchase.
function PlayerDataService.ResolveItemMutation(player)
 local s=sessions[player]
 local op=s and s.PendingItemMutation
 if not s or not s.Loaded or not op then return false,"NoPendingMutation" end
 -- PendingItemMutation serializes the player; the operation retains its reward ID
 -- and lock across every yielding write. Retries reuse this exact operation.
 if op.Resolving then return false,"InventorySavePending" end
 op.Resolving=true
 s.Saving=true
 local deltas=op.Deltas or {[op.ItemId]=op.Delta}
 local rejection
 local ok,saved,info=pcall(function()
  return store:UpdateAsync(key(player),function(old,keyInfo)
   rejection=nil
   if old~=nil and typeof(old)~="table" then error("Invalid saved PlayerData") end
   local merged=old and table.clone(old) or defaults()
   local owned=assert(normalizeItems(merged.OwnedItems))
   local users,meta=metadata(keyInfo)
   if op.ShopGrant then
    if resetToken(merged)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
    local shop=assert(normalizeShop(merged.ShopRewards));merged.ShopRewards=shop
    local g=op.ShopGrant
    local claimed=g.Kind=="VIPDaily" and shop.VIPDailyDateUTC>=g.Date
     or g.Kind=="Bundle" and shop.Claims[g.Key]
     or g.Kind=="WinReceipt" and shop.WinReceipts[g.ReceiptId]
    if claimed and meta.ItemMutationId~=op.Id then rejection="AlreadyClaimed";return merged,users,meta end
   end
   if op.CommunityReward then
    if resetToken(merged)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
    merged.CommunityRewards=assert(normalizeCommunity(merged.CommunityRewards))
    if merged.CommunityRewards.Claimed and meta.ItemMutationId~=op.Id then
     rejection="AlreadyClaimed";return merged,users,meta
    end
   end
   if op.DailyReward then
    if resetToken(merged)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
    merged.DailyRewards=assert(normalizeDailyRewards(merged.DailyRewards))
    local daily=merged.DailyRewards
    if meta.ItemMutationId~=op.Id then
     if daily.ClaimedDays>=op.DailyReward.Day then rejection="AlreadyClaimed";return merged,users,meta end
     if daily.ClaimedDays+1~=op.DailyReward.Day or daily.LastClaimDateUTC>=op.ClaimDateUTC then rejection="DailyLocked";return merged,users,meta end
    end
   end
   if op.TimeReward then
    if resetToken(merged)~=op.ResetToken then rejection="SaveSupersededByReset";return nil end
    merged.TimeRewards=mergeTimeRewards(merged.TimeRewards,{ElapsedSeconds=op.ElapsedSeconds,Claimed={}})
    if merged.TimeRewards.Claimed[op.TimeReward.Id] and meta.ItemMutationId~=op.Id then
     rejection="AlreadyClaimed";return merged,users,meta
    end
   end
   if meta.ItemMutationId~=op.Id then
    for itemId,delta in pairs(deltas) do
     local count=(owned[itemId] or 0)+delta
     if count<0 then rejection="NotEnoughItems"; return nil end
     if count>MAX_COUNT then rejection="CountOverflow"; return nil end
     owned[itemId]=count>0 and count or nil
    end
    if op.ShopGrant then
     local g=op.ShopGrant;local shop=merged.ShopRewards
     if g.Kind=="VIPDaily" then shop.VIPDailyDateUTC=g.Date
     elseif g.Kind=="WinReceipt" then shop.WinReceipts[g.ReceiptId]=true
     else shop.Claims[g.Key]=true end
     if g.WinAmount>0 then
      merged.Win=op.Snapshot.Win+math.max(0,shop.WinGrantedTotal-op.Snapshot.ShopWinGrantedTotal)+g.WinAmount
      shop.WinGrantedTotal+=g.WinAmount
      if shop.WinGrantedTotal>MAX_COUNT then error("Shop Win total overflow") end
     end
     merged.OwnedAuras=table.clone(merged.OwnedAuras or {})
     for _,id in ipairs(g.AuraIds) do merged.OwnedAuras[id]=true end
     for id,deadline in pairs(g.PotionExpiresUTC) do shop.PotionExpiresUTC[id]=math.max(shop.PotionExpiresUTC[id] or 0,deadline) end
    end
    if op.TimeReward then
     local reward=op.TimeReward
     merged.TimeRewards.Claimed[reward.Id]=true
     if reward.Result.RewardType=="Win" then
      merged.Win=op.Snapshot.Win+reward.Result.Amount
     elseif reward.Result.RewardType=="Strength" then
      local gain=reward.Result.Amount
      local strength,level,progress=LevelProgression.ApplyGain(op.Snapshot,gain)
      if not strength then error(level) end
      merged.Strength,merged.Level,merged.LevelProgress=strength,level,progress
      merged.LevelProgressVersion=LevelProgression.Version
      merged.TotalStrengthEarned=math.max(tonumber(merged.TotalStrengthEarned) or 0,op.Snapshot.TotalStrengthEarned)+gain
      merged.DailyDate=op.Snapshot.DailyDate
      merged.DailyStrengthEarned=op.Snapshot.DailyStrengthEarned+gain
     end
    end
    if op.DailyReward then
     merged.DailyRewards={ClaimedDays=op.DailyReward.Day,LastClaimDateUTC=op.ClaimDateUTC}
     if op.DailyReward.Result.RewardType=="Win" then merged.Win=op.Snapshot.Win+op.DailyReward.Result.Amount end
    end
    if op.CommunityReward then
     merged.CommunityRewards={Claimed=true}
     merged.Win=op.Snapshot.Win+op.CommunityReward.WinAmount
    end
    if op.WinPrice>0 then merged.Win=op.ReservedWin end
    if typeof(merged.EquippedItems)=="table" then
     merged.EquippedItems=table.clone(merged.EquippedItems)
     for slot,id in pairs(merged.EquippedItems) do
      if deltas[id] and deltas[id]<0 and not owned[id] then merged.EquippedItems[slot]="" end
     end
    end
    meta.ItemMutationId=op.Id
   end
   merged.OwnedItems=owned
   return merged,users,meta
  end)
 end)
 if ok and rejection then
  if op.ShopGrant and typeof(saved)=="table" then
   local merged=mergeShop(s.Data.ShopRewards,saved.ShopRewards)
   local delta=math.max(0,merged.WinGrantedTotal-s.Data.ShopRewards.WinGrantedTotal)
   s.Data.ShopRewards=merged
   if delta>0 then PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+delta) end
   for key in pairs(merged.Claims) do local product=ShopConfig.Get(key)
    if product and product.AuraId and saved.OwnedAuras and saved.OwnedAuras[product.AuraId] then s.Data.OwnedAuras[product.AuraId]=true end
   end
  end
  if op.CommunityReward and typeof(saved)=="table" then s.Data.CommunityRewards=mergeCommunity(s.Data.CommunityRewards,saved.CommunityRewards) end
  op.Resolving=false
  if op.DailyReward and typeof(saved)=="table" then s.Data.DailyRewards=mergeDailyRewards(s.Data.DailyRewards,saved.DailyRewards) end
  if op.TimeReward and typeof(saved)=="table" then s.Data.TimeRewards=mergeTimeRewards(s.Data.TimeRewards,saved.TimeRewards) end
  if op.WinPrice>0 then PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+op.WinPrice) end
  op.Result=rejection -- Transient completion for world pickup observers.
  s.PendingItemMutation=nil
  s.Saving=false
  return false,rejection
 end
 if not ok or not info or info:GetMetadata().ItemMutationId~=op.Id then
  op.Resolving=false
  return false,"InventorySavePending"
 end
 s.Data.OwnedItems=assert(normalizeItems(saved.OwnedItems))
 for slot,id in pairs(s.Data.EquippedItems) do
  if deltas[id] and deltas[id]<0 and not s.Data.OwnedItems[id] then s.Data.EquippedItems[slot]="" end
 end
 if op.ShopGrant then
  local g=op.ShopGrant
  local shop=mergeShop(s.Data.ShopRewards,saved.ShopRewards)
  local delta=math.max(0,shop.WinGrantedTotal-s.Data.ShopRewards.WinGrantedTotal)
  s.Data.ShopRewards=shop
  for _,id in ipairs(g.AuraIds) do s.Data.OwnedAuras[id]=true end
  if delta>0 then PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+delta) end
  if player.Parent==game:GetService("Players") then
   local potions=require(game.ServerScriptService.Services.PotionService)
   for id,deadline in pairs(g.PotionExpiresUTC) do potions.EnsureExpiresAt(player,id,deadline) end
  end
 end
 if op.CommunityReward then
  s.Data.CommunityRewards=mergeCommunity(s.Data.CommunityRewards,saved.CommunityRewards)
  PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+op.CommunityReward.WinAmount)
 end
 if op.TimeReward then
  s.Data.TimeRewards=mergeTimeRewards(s.Data.TimeRewards,saved.TimeRewards)
  local result=op.TimeReward.Result
  -- Apply the committed reward once locally before Save can snapshot attributes.
  if result.RewardType=="Win" then
   PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+result.Amount)
  elseif result.RewardType=="Strength" then
   TestStrength.AddRewardStrength(player,result.Amount)
  elseif result.RewardType=="Potion" and player.Parent==game:GetService("Players") then
   require(game.ServerScriptService.Services.PotionService).Activate(player,result.PotionId,op.TimeReward.Id)
  end
 end
 if op.DailyReward then
  s.Data.DailyRewards=mergeDailyRewards(s.Data.DailyRewards,saved.DailyRewards)
  local result=op.DailyReward.Result
  if result.RewardType=="Win" then
   PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+result.Amount)
  elseif result.RewardType=="Potion" and player.Parent==game:GetService("Players") then
   require(game.ServerScriptService.Services.PotionService).Activate(player,result.PotionId)
  end
 end
 op.Resolving=false
 op.Result="Changed" -- Not saved; lets a locked pickup observe a retried commit.
 s.PendingItemMutation=nil
 s.Saving=false
 s.Dirty=true
 return true,"Changed"
end
function PlayerDataService.ChangeItemCount(player,itemId,delta,winPrice)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return false,"DataSaving" end
 if not require(game.ReplicatedStorage.Config.ItemMaster).Get(itemId) then return false,"InvalidItemId" end
 if not finite(delta) or delta==0 or delta%1~=0 or math.abs(delta)>MAX_COUNT then return false,"InvalidAmount" end
 local nextCount=(s.Data.OwnedItems[itemId] or 0)+delta
 if nextCount<0 then return false,"NotEnoughItems" end
 if nextCount>MAX_COUNT then return false,"CountOverflow" end
 local price=winPrice or 0
 if not finite(price) or price<0 or price%1~=0 then return false,"InvalidPrice" end
 local win=player:GetAttribute("Win")
 if price>0 then
  if not finite(win) or win%1~=0 or win<price then return false,"NotEnoughWin" end
 end
 local op={Id=game:GetService("HttpService"):GenerateGUID(false),ItemId=itemId,Delta=delta,WinPrice=price}
 if price>0 then
  op.ReservedWin=win-price
  PlayerDataService.SetWin(player,op.ReservedWin)
 end
 s.PendingItemMutation=op
 return PlayerDataService.ResolveItemMutation(player)
end

-- Commit a staged set of item additions/removals in one existing mutation.
-- Private validation and snapshot for an atomic first-play reward commit.
local function prepareTimeReward(player,context)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return nil,"DataSaving" end
 local config=typeof(context)=="table" and TimeRewardConfig.Get(context.Id)
 local result=typeof(context)=="table" and context.Result
 if not config or typeof(result)~="table" or result.RewardType~=config.RewardType then return nil,"InvalidRewardId" end
 local progress=PlayerDataService.GetTimeRewards(player)
 if progress.Claimed[config.Id] then return nil,"AlreadyClaimed" end
 if progress.ElapsedSeconds<config.RequiredSeconds then return nil,"Locked" end
 if result.RewardType=="Strength" or result.RewardType=="Win" then
  if not finite(result.Amount) or result.Amount<=0 then return nil,"InvalidAmount" end
  if result.RewardType=="Win" and result.Amount~=config.Amount then return nil,"InvalidAmount" end
  if result.RewardType=="Strength" then
   local total,reason=LevelProgression.ApplyGain(s.Data,result.Amount)
   if not total then return nil,reason end
  end
 elseif result.RewardType=="Potion" then
  if result.PotionId~=config.PotionId then return nil,"InvalidPotion" end
 end
 local d=s.Data
 local win=player:GetAttribute("Win")
 local strength=player:GetAttribute("Strength")
 if not finite(win) or not finite(strength) then return nil,"InvalidPlayerValues" end
 return {
  Id=HttpService:GenerateGUID(false),WinPrice=0,TimeReward=context,
  ResetToken=d.ResetToken,ElapsedSeconds=progress.ElapsedSeconds,
  Snapshot={Win=win,Strength=strength,Level=d.Level,LevelProgress=d.LevelProgress,TotalStrengthEarned=d.TotalStrengthEarned,
   DailyDate=today(),DailyStrengthEarned=d.DailyDate==today() and d.DailyStrengthEarned or 0},
 }
end
function PlayerDataService.ClaimTimeReward(player,context)
 local op,reason=prepareTimeReward(player,context)
 if not op then return false,reason end
 if op.TimeReward.Result.RewardType=="ItemRoll" then return false,"UseItemTransaction" end
 op.Deltas={}
 sessions[player].PendingItemMutation=op
 return PlayerDataService.ResolveItemMutation(player)
end


local function prepareDailyReward(player,context)
 if player.Parent~=game:GetService("Players") then return nil,"InvalidPlayer" end
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return nil,"DataSaving" end
 local config=typeof(context)=="table" and DailyRewardConfig.Get(context.DailyDay)
 local result=typeof(context)=="table" and context.Result
 if not config or typeof(result)~="table" or result.RewardType~=config.RewardType then return nil,"InvalidDailyDay" end
 local state=PlayerDataService.GetDailyRewards(player)
 if config.Day<=state.ClaimedDays then return nil,"AlreadyClaimed" end
 if not state.Ready or config.Day~=state.CurrentDay then return nil,"DailyLocked" end
 if config.RewardType=="Win" and (result.Amount~=config.Amount or not finite(player:GetAttribute("Win")) or player:GetAttribute("Win")+result.Amount>=MAX_COUNT) then return nil,"InvalidWin" end
 if config.RewardType=="Potion" and result.PotionId~=config.PotionId then return nil,"InvalidPotion" end
 return {Id=HttpService:GenerateGUID(false),WinPrice=0,DailyReward={Day=config.Day,Result=result},
  ResetToken=s.Data.ResetToken,ClaimDateUTC=state.DateUTC,Snapshot={Win=player:GetAttribute("Win")}}
end
function PlayerDataService.ClaimDailyReward(player,context)
 local op,reason=prepareDailyReward(player,context)
 if not op then return false,reason end
 if op.DailyReward.Result.RewardType=="ItemRoll" then return false,"UseItemTransaction" end
 op.Deltas={} sessions[player].PendingItemMutation=op
 return PlayerDataService.ResolveItemMutation(player)
end

-- Server-only membership authorization is rechecked here before committing.
local function prepareCommunityReward(player,context)
 local s=sessions[player]
 if player.Parent~=game:GetService("Players") or not s or not s.Loaded or not s.Data then return nil,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return nil,"DataSaving" end
 if s.Data.CommunityRewards.Claimed then return nil,"AlreadyClaimed" end
 if not CommunityConfig.IsValid() then return nil,"Unavailable" end
 if typeof(context)~="table" or context.CommunityReward~=true then return nil,"InvalidReward" end
 local data=s.Data
 local ok,joined=pcall(function()return player:IsInGroupAsync(CommunityConfig.GroupId)end)
 if not ok then return nil,"MembershipUnavailable" end
 if not joined then return nil,"NotJoined" end
 if sessions[player]~=s or s.Data~=data or not s.Loaded or player.Parent~=game:GetService("Players") then return nil,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return nil,"DataSaving" end
 if data.CommunityRewards.Claimed then return nil,"AlreadyClaimed" end
 local win=player:GetAttribute("Win")
 if not finite(win) or win<0 or win%1~=0 or win+CommunityConfig.WinAmount>=MAX_COUNT then return nil,"InvalidWin" end
 return {Id=HttpService:GenerateGUID(false),WinPrice=0,ResetToken=data.ResetToken,
  CommunityReward={WinAmount=CommunityConfig.WinAmount},Snapshot={Win=win}}
end
function PlayerDataService.ChangeItemCounts(player,deltas,timeReward)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return false,"DataSaving" end
 if typeof(deltas)~="table" or next(deltas)==nil then return false,"InvalidChanges" end
 local changes={}
 local master=require(game.ReplicatedStorage.Config.ItemMaster)
 for id,delta in pairs(deltas) do
  if not master.Get(id) then return false,"InvalidItemId" end
  if not finite(delta) or delta==0 or delta%1~=0 or math.abs(delta)>MAX_COUNT then return false,"InvalidAmount" end
  local count=(s.Data.OwnedItems[id] or 0)+delta
  if count<0 then return false,"NotEnoughItems" end
  if count>MAX_COUNT then return false,"CountOverflow" end
  changes[id]=delta
 end
 local op
 if timeReward and timeReward.CommunityReward then
  local reason
  op,reason=prepareCommunityReward(player,timeReward)
  if not op then return false,reason end
  local count=0
  for _,delta in pairs(changes) do if delta<=0 then return false,"InvalidRewardItems" end count+=delta end
  if count~=CommunityConfig.ItemAmount then return false,"InvalidRewardItems" end
 elseif timeReward and timeReward.DailyDay then
  local reason
  op,reason=prepareDailyReward(player,timeReward)
  if not op then return false,reason end
  if op.DailyReward.Result.RewardType~="ItemRoll" then return false,"InvalidRewardType" end
  local count=0 for _,delta in pairs(changes) do if delta<=0 then return false,"InvalidRewardItems" end count+=delta end
  if count~=DailyRewardConfig.Get(timeReward.DailyDay).Amount then return false,"InvalidRewardItems" end
 elseif timeReward then
  local reason
  op,reason=prepareTimeReward(player,timeReward)
  if not op then return false,reason end
  if op.TimeReward.Result.RewardType~="ItemRoll" then return false,"InvalidRewardType" end
  local count=0 for _,delta in pairs(changes) do if delta<=0 then return false,"InvalidRewardItems" end count+=delta end
  if count~=TimeRewardConfig.Get(timeReward.Id).Amount then return false,"InvalidRewardItems" end
 else
  op={Id=game:GetService("HttpService"):GenerateGUID(false),WinPrice=0}
 end
 op.Deltas=changes
 s.PendingItemMutation=op
 return PlayerDataService.ResolveItemMutation(player)
end

-- The shared receipt journal remains the long-term dedupe authority.
-- A single pending intent prevents another receipt from advancing until the
-- current journal entry is Granted. Store that receipt's marker WITH its +1;
-- ordinary saves/mutations preserve it, including removal of the last copy.
-- The monotonic intent sequence also rejects a stale server resuming an older
-- grant after its lease expired and a newer receipt has already completed.
function PlayerDataService.GrantPurchasedItem(player,itemId,purchaseId,quantityVersion,intentSequence)
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving then return false,"DataSaving" end
 local item=require(game.ReplicatedStorage.Config.ItemMaster).Get(itemId)
 if not item or (item.Rarity~="Epic" and item.Rarity~="Legendary") then return false,"InvalidItemId" end
 if typeof(purchaseId)~="string" or purchaseId=="" or #purchaseId>100 then return false,"InvalidPurchaseId" end
 if not finite(intentSequence) or intentSequence<1 or intentSequence%1~=0 then return false,"InvalidIntentSequence" end
 s.Saving=true
 local ok,saved,info=pcall(function()
  return store:UpdateAsync(key(player),function(old,keyInfo)
   if old~=nil and typeof(old)~="table" then error("Invalid saved PlayerData") end
   local merged=old and table.clone(old) or defaults()
   local owned=assert(normalizeItems(merged.OwnedItems))
   local users,meta=metadata(keyInfo)
   local previous=meta.ItemReceiptSequence or 0
   if intentSequence==previous then
    if meta.ItemReceiptId~=purchaseId or meta.ItemReceiptItem~=itemId then error("Receipt sequence mismatch") end
   elseif intentSequence>previous then
    local count=owned[itemId] or 0
    -- Reserved receipts created before quantity migration retain their original
    -- boolean-grant semantics; newly reserved receipts always add exactly one.
    local nextCount=quantityVersion==1 and count+1 or math.max(count,1)
    if nextCount>MAX_COUNT then error("Item count overflow") end
    owned[itemId]=nextCount
    meta.ItemReceiptId=purchaseId
    meta.ItemReceiptItem=itemId
    meta.ItemReceiptSequence=intentSequence
   end
   merged.OwnedItems=owned
   return merged,users,meta
  end)
 end)
 s.Saving=false
 if not ok or not info or (info:GetMetadata().ItemReceiptSequence or 0)<intentSequence then return false,"OwnershipSaveFailed" end
 s.Data.OwnedItems=assert(normalizeItems(saved.OwnedItems))
 s.Dirty=true
 return true,"Granted"
end

function PlayerDataService.GetTotalStrengthTop(limit)
 local n=math.clamp(math.floor(tonumber(limit) or 10),1,100)
 local ok,pages=pcall(function()
  return DSS:GetOrderedDataStore(TOTAL_STORE):GetSortedAsync(false,n)
 end)
 if not ok then return nil,pages end
 local out={}
 for _,entry in ipairs(pages:GetCurrentPage()) do
  out[#out+1]={UserId=tonumber(entry.key),Value=entry.value}
 end
 return out
end
function PlayerDataService.GetDailyStrengthTop(limit,date)
 local n=math.clamp(math.floor(tonumber(limit) or 10),1,100)
 local storeName=StoreConfig.GetName("DailyStrengthRanking_"..(date or today()))
 local ok,pages=pcall(function()
  return DSS:GetOrderedDataStore(storeName):GetSortedAsync(false,n)
 end)
 if not ok then return nil,pages end
 local out={}
 for _,entry in ipairs(pages:GetCurrentPage()) do
  out[#out+1]={UserId=tonumber(entry.key),Value=entry.value}
 end
 return out
end
function PlayerDataService.Release(player)
 sessions[player]=nil
end

-- Atomically persist the Win debit and permanent entitlement before publishing either.
function PlayerDataService.PurchaseSpeed(player,id)
 local config=require(game.ReplicatedStorage.Config.SpeedConfig)
 local item=typeof(id)=="string" and config[id]
 if id~="Speed1" or not item or item.PriceType~="Win" then return false,"InvalidRequest" end
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return false,"DataSaving" end
 if s.Data.OwnedSpeeds[id] then return false,"AlreadyOwned" end
 local win=player:GetAttribute("Win")
 if not finite(win) or win%1~=0 or win<item.PriceWin then return false,"NotEnoughWin" end
 local token=s.Data.ResetToken
 s.Saving=true
 local rejected
 local already=false
 local ok,saved=pcall(function()
  return store:UpdateAsync(key(player),function(old,info)
   rejected=nil;already=false
   if old~=nil and typeof(old)~="table" then error("Invalid saved PlayerData") end
   if resetToken(old)~=token then rejected="SaveSupersededByReset";return nil end
   local owned,err=normalizeSpeeds(old and old.OwnedSpeeds)
   if not owned then error(err) end
   local users,meta=metadata(info)
   if owned[id] then already=true;return old,users,meta end
   local nextData=old and table.clone(old) or defaults()
   owned[id]=true
   nextData.OwnedSpeeds=owned
   nextData.Win=win-item.PriceWin
   return nextData,users,meta
  end)
 end)
 s.Saving=false
 if not ok or not saved or rejected then return false,rejected or "SaveFailed" end
 if sessions[player]~=s then return false,"DataNotLoaded" end
 if not saved.OwnedSpeeds or saved.OwnedSpeeds[id]~=true then return false,"SaveFailed" end
 s.Data.OwnedSpeeds=assert(normalizeSpeeds(saved.OwnedSpeeds))
 -- Preserve Win earned while UpdateAsync was yielding.
 local earned=(tonumber(player:GetAttribute("Win")) or win)-win
 s.Data.Win=math.max(0,(already and saved.Win or win-item.PriceWin)+earned)
 s.Dirty=true
 player:SetAttribute("Win",s.Data.Win)
 return true,already and "AlreadyOwned" or "Purchased"
end

-- Server-only entry point. Client requests choose a catalogue key, never a grant.
function PlayerDataService.ClaimShopReward(player,productKey,receipt)
 -- Developer Product receipts retain their existing fulfillment path.
 if not receipt and not require(game.ServerScriptService.Services.GamePassService).AreEffectsEnabled() then return false,"GamePassEffectsDisabled" end
 local s=sessions[player]
 if not s or not s.Loaded or not s.Data then return false,"DataNotLoaded" end
 if s.Saving or s.PendingItemMutation then return false,"DataSaving" end
 local config
 local kind="Bundle"
 local date=dailyUTC()
 if receipt then
  if typeof(receipt)~="table" or receipt.PlayerId~=player.UserId or typeof(receipt.PurchaseId)~="string"
   or receipt.PurchaseId=="" or #receipt.PurchaseId>100 then return false,"InvalidReceipt" end
  config=ShopConfig.ForWinProduct(receipt.ProductId)
  if not config or config.Key~=productKey then return false,"InvalidProduct" end
  kind="WinReceipt"
 elseif productKey=="VIPDaily" then
  config=ShopConfig.Get("VIP").DailyBonus;kind="VIPDaily"
  if not require(game.ServerScriptService.Services.GamePassService).HasShopPass(player,"VIP") then return false,"VIPRequired" end
 else
  config=ShopConfig.Get(productKey)
  if not config or config.Kind~="GamePass" then return false,"InvalidProduct" end
  if not require(game.ServerScriptService.Services.GamePassService).HasShopPass(player,productKey) then return false,"NotOwned" end
 end
 local shop=s.Data.ShopRewards
 if kind=="VIPDaily" and shop.VIPDailyDateUTC>=date
  or kind=="Bundle" and shop.Claims[productKey]
  or kind=="WinReceipt" and shop.WinReceipts[receipt.PurchaseId] then return false,"AlreadyClaimed" end
 local amount=kind=="Bundle" and (config.WinAmount or 0) or config.Amount
 local win=player:GetAttribute("Win")
 if not finite(amount) or amount<0 or amount%1~=0 or not finite(win) or win+amount>=MAX_COUNT then return false,"InvalidWin" end
 local grant={Kind=kind,Key=productKey,Date=date,ReceiptId=receipt and receipt.PurchaseId,
  WinAmount=amount,AuraIds={},PotionExpiresUTC={}}
 if config.AuraId then table.insert(grant.AuraIds,config.AuraId) end
 if config.Potions then
  local potions=require(game.ServerScriptService.Services.PotionService)
  for id,count in pairs(config.Potions) do
   grant.PotionExpiresUTC[id]=os.time()+math.ceil(potions.GetRemaining(player,id))+TimeRewardConfig.GetPotionDuration(id)*count
  end
 end
 local deltas={}
 if config.RandomItem then
  local id=ShopConfig.RollSecret(Random.new())
  if (s.Data.OwnedItems[id] or 0)>=MAX_COUNT then return false,"CountOverflow" end
  deltas[id]=1;grant.ItemId=id
 end
 local op={Id=HttpService:GenerateGUID(false),WinPrice=0,ShopGrant=grant,
  Snapshot={Win=win,ShopWinGrantedTotal=shop.WinGrantedTotal},ResetToken=s.Data.ResetToken,Deltas=deltas}
 s.PendingItemMutation=op
 local ok,reason=PlayerDataService.ResolveItemMutation(player)
 return ok,reason,grant
end
function PlayerDataService.GetShopRewards(player)
 local s=sessions[player]
 return s and s.Loaded and assert(normalizeShop(s.Data.ShopRewards)) or nil
end

return PlayerDataService
end
