local DSS=require(script.Parent.Runtime).DSS
local DumbbellItemMaster=require(script.Parent.DumbbellItemMaster)
local PlayerDataService={}
local store=DSS:GetDataStore("PlayerData_v1")
local sessions=setmetatable({}, {__mode="k"})
local TOTAL_STORE="TotalStrengthRanking_v1"
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
local function metadata(info)
 return info and info:GetUserIds() or {}, info and info:GetMetadata() or {}
end

local function defaults()
 return {Strength=0, RebirthCount=0, TotalStrengthEarned=0, DailyStrengthEarned=0, DailyDate=today(), Win=0, OwnedDumbbells={}, EquippedDumbbell="", OwnedItems={}, EquippedItems={Protein="",Glove="",TrainingBelt=""}}
end
-- Only an existing, owned Dumbbell can survive loading as equipped.
local function validEquipped(itemId,owned)
 if typeof(itemId)~="string" or itemId=="" or owned[itemId]~=true then return "" end
 local item=DumbbellItemMaster.Get(itemId)
 return item and item.Category=="Dumbbell" and itemId or ""
end
local function normalize(raw)
 local d=defaults()
 if typeof(raw)=="table" then
  if finite(raw.Strength) then d.Strength=math.max(0,raw.Strength) end
  if finite(raw.RebirthCount) then d.RebirthCount=math.max(0,math.floor(raw.RebirthCount)) end
  if finite(raw.TotalStrengthEarned) then d.TotalStrengthEarned=math.max(0,raw.TotalStrengthEarned) end
  if finite(raw.DailyStrengthEarned) then d.DailyStrengthEarned=math.max(0,raw.DailyStrengthEarned) end
  if typeof(raw.DailyDate)=="string" then d.DailyDate=raw.DailyDate end
  if finite(raw.Win) then d.Win=math.max(0,math.floor(raw.Win)) end
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
 player:SetAttribute("Strength",d.Strength)
 player:SetAttribute("RebirthCount",d.RebirthCount)
 player:SetAttribute("TotalStrengthEarned",d.TotalStrengthEarned)
 player:SetAttribute("DailyStrengthEarned",d.DailyStrengthEarned)
 player:SetAttribute("DailyDate",d.DailyDate)
 player:SetAttribute("Win",d.Win)
 -- Output mirror only: never read this Attribute as equipment authority.
 player:SetAttribute("EquippedDumbbell",d.EquippedDumbbell)
end
local function key(player) return "Player_"..tostring(player.UserId) end

function PlayerDataService.Get(player)
 local s=sessions[player]
 return s
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

function PlayerDataService.Load(player)
 local ok,raw=pcall(function() return store:GetAsync(key(player)) end)
 if not ok then
  sessions[player]={Loaded=false,Data=nil,Saving=false}
  return false,"DataStore load failed: "..tostring(raw)
 end
 local d,validationError=normalize(raw)
 if not d then
  sessions[player]={Loaded=false,Data=nil,Saving=false}
  return false,validationError
 end
 sessions[player]={Loaded=true,Data=d,Dirty=true,Saving=false,LastSave=nil}
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

function PlayerDataService.SetCurrentStrength(player,value)
 local s=sessions[player]
 if not s or not s.Loaded then return false end
 s.Data.Strength=math.max(0,tonumber(value) or 0)
 s.Dirty=true
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
 d.Dirty=true
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

function PlayerDataService.Save(player)
 local s=sessions[player]
 if s and s.PendingItemMutation then
  local resolved,reason=PlayerDataService.ResolveItemMutation(player)
  if not resolved then return false,reason end
 end
 if not s or not s.Loaded or not s.Data then return false,"not loaded" end
 if s.Saving then return false,"saving" end
 if not s.Dirty and s.LastSave and os.clock()-s.LastSave<10 then return true,"already saved" end
 s.Saving=true
 local d=s.Data
 d.Strength=math.max(0,tonumber(player:GetAttribute("Strength")) or d.Strength)
 d.RebirthCount=math.max(0,math.floor(tonumber(player:GetAttribute("RebirthCount")) or d.RebirthCount))
 d.Win=math.max(0,math.floor(tonumber(player:GetAttribute("Win")) or d.Win))
 local now=today()
 if d.DailyDate~=now then
  d.DailyDate=now
  d.DailyStrengthEarned=0
 end
 local payload={
  Strength=d.Strength,
  RebirthCount=d.RebirthCount,
  TotalStrengthEarned=d.TotalStrengthEarned,
  DailyStrengthEarned=d.DailyStrengthEarned,
  DailyDate=d.DailyDate,
  Win=d.Win,
  OwnedDumbbells=table.clone(d.OwnedDumbbells),
  EquippedDumbbell=d.EquippedDumbbell,
  OwnedItems=table.clone(d.OwnedItems),
  EquippedItems=table.clone(d.EquippedItems)
 }
 local saved
 local ok,err=pcall(function()
  saved=store:UpdateAsync(key(player),function(old,info)
   local users,meta=metadata(info)
   if old==nil then return payload,users,meta end
   if typeof(old)~="table" then error("Invalid saved PlayerData") end
   local merged=table.clone(old)
   merged.Strength=payload.Strength
   merged.RebirthCount=math.max(tonumber(old.RebirthCount) or 0,payload.RebirthCount)
   merged.TotalStrengthEarned=math.max(tonumber(old.TotalStrengthEarned) or 0,payload.TotalStrengthEarned)
   merged.Win=payload.Win
   merged.OwnedDumbbells=table.clone(payload.OwnedDumbbells)
   merged.EquippedDumbbell=payload.EquippedDumbbell
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
  s.Saving=false
  return false,tostring(err)
 end
 if typeof(saved)=="table" then
  d.Strength=tonumber(saved.Strength) or d.Strength
  d.RebirthCount=tonumber(saved.RebirthCount) or d.RebirthCount
  d.TotalStrengthEarned=tonumber(saved.TotalStrengthEarned) or d.TotalStrengthEarned
  d.DailyStrengthEarned=tonumber(saved.DailyStrengthEarned) or d.DailyStrengthEarned
  d.DailyDate=typeof(saved.DailyDate)=="string" and saved.DailyDate or d.DailyDate
  d.Win=finite(saved.Win) and math.max(0,math.floor(saved.Win)) or d.Win
  if typeof(saved.OwnedItems)=="table" then d.OwnedItems=table.clone(saved.OwnedItems) end
 end
 applyAttributes(player,d)
 d.Dirty=false
 local totalOK=saveOrdered(TOTAL_STORE,tostring(player.UserId),d.TotalStrengthEarned)
 local dailyOK=saveOrdered("DailyStrengthRanking_"..d.DailyDate,tostring(player.UserId),d.DailyStrengthEarned)
 s.Saving=false
 s.LastSave=os.clock()
 if not totalOK or not dailyOK then
  warn("Player ranking mirror save failed for "..player.Name)
 end
 return true
end

-- All regular-item quantity mutations are durable before reporting success.
-- A failed/ambiguous write keeps its operation ID and local Win reservation;
-- Save retries the same operation rather than refunding a possibly committed purchase.
function PlayerDataService.ResolveItemMutation(player)
 local s=sessions[player]
 local op=s and s.PendingItemMutation
 if not s or not s.Loaded or not op then return false,"NoPendingMutation" end
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
   if meta.ItemMutationId~=op.Id then
    for itemId,delta in pairs(deltas) do
     local count=(owned[itemId] or 0)+delta
     if count<0 then rejection="NotEnoughItems"; return nil end
     if count>MAX_COUNT then rejection="CountOverflow"; return nil end
     owned[itemId]=count>0 and count or nil
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
  if op.WinPrice>0 then PlayerDataService.SetWin(player,(player:GetAttribute("Win") or 0)+op.WinPrice) end
  op.Result=rejection -- Transient completion for world pickup observers.
  s.PendingItemMutation=nil
  s.Saving=false
  return false,rejection
 end
 if not ok or not info or info:GetMetadata().ItemMutationId~=op.Id then
  return false,"InventorySavePending"
 end
 s.Data.OwnedItems=assert(normalizeItems(saved.OwnedItems))
 for slot,id in pairs(s.Data.EquippedItems) do
  if deltas[id] and deltas[id]<0 and not s.Data.OwnedItems[id] then s.Data.EquippedItems[slot]="" end
 end
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
function PlayerDataService.ChangeItemCounts(player,deltas)
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
 s.PendingItemMutation={Id=game:GetService("HttpService"):GenerateGUID(false),Deltas=changes,WinPrice=0}
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
 local storeName="DailyStrengthRanking_"..(date or today())
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
return PlayerDataService
