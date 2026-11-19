-- Production adapter. Studio exits BEFORE obtaining stores, Secrets or HTTP.
local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local DSS=game:GetService("DataStoreService")
local C=require(game.ReplicatedStorage.Config.EngagementConfig)
local Reward=require(game.ReplicatedStorage.Config.StrengthRewardConfig)
local Worker=require(script.Parent.OfflineNotificationWorker)
local M={}
local started=false
local profiles,indexStore,coordinator
local pausedUntil=0
local function enabled()
	return not RunService:IsStudio() and game.GameId==10765181857 and C.OfflineConfigured()
end
M.Enabled=enabled
local function log(code)
	if code=="AuthError" then pausedUntil=os.time()+C.Worker.AuthPauseSeconds end
	if C.LogTransitions then print("[OfflineNotification] "..code) end
end
local function stores()
	assert(enabled(),"NotificationsDisabled")
	if not profiles then
		profiles=DSS:GetDataStore("PlayerData_v1")
		indexStore=DSS:GetOrderedDataStore("OfflineNotifyDue_v1")
		coordinator=DSS:GetDataStore("OfflineNotifyWorker_v1")
	end
end
local function budget()
	return DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)>=C.Worker.BudgetReserve
		and DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)>=C.Worker.BudgetReserve
		and DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)>=2
		and DSS:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)>=10
end
local function queueKey(userId,generation)
	return tostring(userId).."_"..generation:gsub("%-","")
end
local function parse(key)
	local uid,g=key:match("^(%d+)_([%x]+)$")
	if not uid or #g~=32 then return nil end
	return tonumber(uid),g:sub(1,8).."-"..g:sub(9,12).."-"..g:sub(13,16).."-"..g:sub(17,20).."-"..g:sub(21)
end
-- Only user IDs are parsed numerically. Message IDs never pass through this function.
local pending={}
function M.Track(userId,generation,dueAt)
	if not enabled() then return end
	local key=queueKey(userId,generation)
	if pending[key] then pending[key].DueAt=dueAt;return end
	local request={DueAt=dueAt};pending[key]=request
	task.spawn(function()
		for attempt=1,C.Worker.IndexRetryAttempts do
			if not enabled() then break end
			local success=false
			if budget() then success=pcall(function()
				stores();indexStore:SetAsync(key,math.ceil(request.DueAt))
			end) end
			if success then pending[key]=nil;return end
			task.wait(math.min(15,2^attempt))
		end
		pending[key]=nil;log("IndexUnconfirmed")
	end)
end
function M.Joined(userId,generation)
	-- Recovery-only candidate, registered on NEW successful acquisitions, no legacy scan.
	-- If exit commits but the server stops before enqueue, this candidate discovers its outbox.
	M.Track(userId,generation,os.time()+C.Offline.DelaySeconds)
end
function M.Committed(userId,exit)
	if exit then M.Track(userId,exit.Generation,exit.DueAt) end
end
local function read(userId)
	local options=Instance.new("DataStoreGetOptions");options.UseCache=false
	return profiles:GetAsync("Player_"..userId,options)
end
local function update(userId,transform)
	return profiles:UpdateAsync("Player_"..userId,function(old,info)
		if type(old)~="table" then return nil end
		local notification,last=transform(old,info and info.UpdatedTime/1000)
		if not notification then return nil end
		-- Merge only notification-owned fields into the CURRENT stored value.
		local merged=table.clone(old);merged.OfflineNotificationExit=notification
		if last then merged.OfflineNotificationLastAttempt=last end
		return merged,info and info:GetUserIds() or {},info and info:GetMetadata() or {}
	end)
end
local function prepare()
	if not enabled() then return nil,"Disabled" end
	if not Http.HttpEnabled then return nil,"HttpDisabled" end
	local ok,secret=pcall(Http.GetSecret,Http,C.Offline.SecretName)
	if not ok or secret==nil then return nil,"SecretUnavailable" end
	return {Key=secret} -- Secret object remains server-local; never stringify or log it.
end
local function send(userId,prepared)
	assert(enabled(),"NotificationsDisabled")
	return Http:RequestAsync({
		Url="https://apis.roblox.com/cloud/v2/users/"..userId.."/notifications",
		Method="POST",
		Headers={["Content-Type"]="application/json",["x-api-key"]=prepared.Key},
		Body=Http:JSONEncode({source={universe="universes/10765181857"},
			payload={message_id=C.Offline.OfflineRewardMessageId,type="MOMENT"}}),
	})
end
function M.Init()
	if started then return end
	started=true
	if not enabled() then log(RunService:IsStudio() and "StudioSuppressed" or "DisabledOrIdMissing");return end
	local worker=Worker.new({Now=os.time,Token=function() return Http:GenerateGUID(false) end,
		Enabled=enabled,RewardAmount=Reward.OfflineAmount,Read=read,Update=update,
		Prepare=prepare,Send=send,Log=log,
		Index=function(key,at) indexStore:SetAsync(key,at) end,
		Remove=function(key) indexStore:RemoveAsync(key) end},C)
	local server=Http:GenerateGUID(false)
	task.spawn(function()
		task.wait(math.random(5,15))
		while enabled() do
			if os.time()>=pausedUntil and budget() then
				local ok=pcall(function()
					stores()
					local lease=coordinator:UpdateAsync("Dispatcher",function(old)
						if old and old.Until>os.time() and old.Owner~=server then return nil end
						return {Owner=server,Until=os.time()+C.Worker.LeaseSeconds}
					end)
					if not lease or lease.Owner~=server then return end
					local page=indexStore:GetSortedAsync(true,C.Worker.MaxBatch,0,os.time())
					for _,row in ipairs(page:GetCurrentPage()) do
						if not budget() or os.time()<pausedUntil then break end
						local uid,generation=parse(row.key)
						if uid then
							local processed=pcall(worker.Process,row.key,uid,generation)
							if not processed then
								log("StorageOrProcessingUnconfirmed")
								-- A failed item cannot monopolize the earliest five index entries.
								indexStore:SetAsync(row.key,os.time()+C.Worker.RecoverySeconds)
							end
						else indexStore:RemoveAsync(row.key) end
					end
				end)
				if not ok then log("WorkerStorageUnavailable") end
			end
			task.wait(C.Worker.IntervalSeconds)
		end
	end)
end
return M
