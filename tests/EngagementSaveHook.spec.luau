-- Execute the EXACT current Save function with unrelated normalizers stubbed and a memory store.
-- This checks hook placement, not production persistence or all gameplay field validators.
return function(sources)
local count=0
local function eq(a,b)count+=1;assert(a==b,tostring(a).." ~= "..tostring(b))end
local function copy(v)if type(v)~="table"then return v end local x={}for k,a in pairs(v)do x[k]=copy(a)end return x end
local start=assert(sources.PlayerData:find("function PlayerDataService.Save(",1,true))
local ending=assert(sources.PlayerData:find("-- Called only by EnemyManager",start,true))
local function loaded(src,env)local fn=assert(loadstring(src));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()end
local Config=loaded(sources.Config)
local RewardConfig=loaded(sources.RewardConfig)
local State=loaded(sources.State)
local RewardState=loaded(sources.RewardState,{game={ReplicatedStorage={Config={StrengthRewardConfig="C"}}},require=function()return RewardConfig end})
local function identity(v)return v end
local generic={Normalize=identity,NormalizeSavedTier=identity,NormalizeStage=identity,NormalizeState=identity,Journal=identity,
	Refresh=function()end,Merge=function(_,v)return v end,MergeCombatFact=function(_,v)return v end}
for _,mode in ipairs({"success","before-failure","lost-response","queue-failure","ordinary-save","disabled"})do
	local d={Strength=10000,Level=9,LevelProgress=17,LevelCurveVersion=2,RebirthCount=0,
		Win=123,TotalStrengthEarned=10000,DailyStrengthEarned=100,DailyDate="2026-11-19",ResetToken=1,
		HighestUnlockedWorld=1,World2Visited=false,World1Cleared=false,AutoTapEnabled=false,SelectedSizeTier=0,
		InventoryCapacity=5,SpeedUpgradeStage=0,EquippedSpeed="1",EquippedDumbbell="NORMAL_01",EquippedAura="",
		ShopRewards={Claims={},WinGrantedTotal=0},PetMergeTutorial={},EggPetTutorial={Eligible=false}}
	for _,k in ipairs({"Pets","CommunityRewards","TimeRewards","FirstStage1Reward","FirstBattleTutorial","DailyRewards","OreMergeTutorial",
		"HigherOreMergeTutorial","EquipmentTutorial","OwnedSpeeds","OwnedDumbbells","OwnedOres","ForgeJournal","OwnedAuras","OwnedItems",
		"ItemMergeJournal","EquippedItems","InventoryNotificationSeen"})do d[k]={}end
	d.OwnedItems.KEEP=3
	d.StrengthRewards=RewardState.Acquire(nil,"one",100)
	local s={Loaded=true,Data=d,Dirty=true,OwnerToken="one",StrengthClosing=mode~="ordinary-save"}
	local raw=copy(d);raw.SessionOwnerToken="one"
	local attrs={Strength=10000,Win=123,RebirthCount=0}
	local player={UserId=1,Name="Synthetic",GetAttribute=function(_,k)return attrs[k]end,SetAttribute=function(_,k,v)attrs[k]=v end}
	local calls,confirmed=0,false
	local Data={GetTimeRewards=function()end}
	local env={PlayerDataService=Data,sessions={[player]=s},RunService={IsStudio=function()return false end},
		StrengthRewardState=RewardState,OfflineNotificationState=State,EngagementConfig=Config,
		OfflineNotifications={Enabled=function()return mode~="disabled"end,Committed=function(_,n)
			eq(confirmed,true);eq(n.Generation,"one");eq(n.ConfirmedAt,1000);calls+=1
			if mode=="queue-failure"then error("fake queue failure")end
		end},today=function()return "2026-11-19"end,
		os={time=function()return 1000 end,clock=function()return 1 end},
		metadata=function()return {},{}end,resetToken=function(x)return x.ResetToken end,
		ownedUpdate=function(_,_,fn)
			if mode=="before-failure"then error("fake failure")end
			local value=fn(copy(raw));eq(calls,0);if value then raw=value end
			if mode=="lost-response"then error("fake lost acknowledgement")end
			confirmed=true;return copy(raw)
		end,
		EquipmentTutorial=generic,SizeChangeConfig=generic,Pet=generic,FirstStage1=generic,FirstBattle=generic,OreTutorial=generic,
		HigherOreTutorial=generic,EggTutorial=generic,PetMergeTutorial=generic,LevelProgression={Version=1},ForgeInventory=generic,
		CapacityConfig=generic,SpeedConfig=generic,Counts=generic,
		AuraConfig={Get=function()return nil end},ShopConfig={Get=function()return nil end},
		world2VisitedForSession=function()return false end,
		saveOrdered=function()return true end,TOTAL_STORE="fake-total",StoreConfig={GetName=identity}}
	for _,name in ipairs({"normalizeShop","normalizeCommunity","normalizeTimeRewards","normalizeDailyRewards","normalizeItemMerge",
		"normalizeUnlockedWorld","normalizeSpeeds","normalizeItems","cloneNotificationSeen"})do env[name]=identity end
	for _,name in ipairs({"mergeShop","mergeCommunity","mergeTimeRewards","mergeDailyRewards","mergeNotificationSeen"})do env[name]=function(_,v)return v end end
	loaded(sources.PlayerData:sub(start,ending-1),env)
	local ok=Data.Save(player)
	if mode=="before-failure"or mode=="lost-response"then eq(ok,false);eq(calls,0)
	elseif mode=="ordinary-save"or mode=="disabled"then eq(ok,true);eq(calls,0)
	else eq(ok,true);eq(calls,1)end
	if mode=="before-failure"or mode=="ordinary-save"or mode=="disabled"then eq(raw.OfflineNotificationExit,nil)
	else eq(raw.OfflineNotificationExit.DueAt,87400);eq(raw.OfflineNotificationExit.State,"Pending")end
	eq(raw.Strength,10000);eq(raw.Level,9);eq(raw.LevelProgress,17);eq(raw.Win,123);eq(raw.OwnedItems.KEEP,3)
end
return {Checks=count,Execution="exact PlayerDataService.Save with memory ownedUpdate and stub unrelated normalizers"}
end
