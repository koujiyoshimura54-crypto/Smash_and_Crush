-- Read once at server/client startup: edit before the next Play / deployment.
-- Message IDs are Notification asset ID STRINGS, never numeric Lua literals.
-- Empty IDs disable only that feature's calls. The registered Secret is NOT a key string.
local C = {
	Offline = {Enabled = true, OfflineRewardMessageId = "", SecretName = "OfflineRewardNotificationKey",
		DelaySeconds = 86400}, -- From the committed departure; independent of reward's 86400s cap.
	Invite = {Enabled = true, FriendInviteMessageId = ""},
	Worker = {IntervalSeconds = 60, MaxBatch = 5, LeaseSeconds = 120,
		MaxAttempts = 3, RetryBaseSeconds = 300, MaxBackoffSeconds = 3600,
		RecoverySeconds = 3600, CandidateLifetimeSeconds = 604800,
		MaxLatenessSeconds = 604800, IndexRetryAttempts = 3, BudgetReserve = 40,
		DailyLimitSeconds = 86400, AuthPauseSeconds = 900},
	LogTransitions = true, -- Categories only: no keys, bodies, player identifiers or profile data.
}
function C.HasMessageId(id)
	-- Notification strings use UUIDs (official InviteMessageId example). Also accept
	-- numeric asset-ID strings without tonumber; preserve their exact characters.
	if type(id)~="string" then return false end
	if id:match("^%d+$") then return id:match("^0+$")==nil end
	local a,b,c,d,e=id:match("^(%x+)%-(%x+)%-(%x+)%-(%x+)%-(%x+)$")
	return a~=nil and #a==8 and #b==4 and #c==4 and #d==4 and #e==12
		and id~="00000000-0000-0000-0000-000000000000"
end
function C.OfflineConfigured()
	return C.Offline.Enabled and C.HasMessageId(C.Offline.OfflineRewardMessageId)
		and type(C.Offline.DelaySeconds)=="number" and C.Offline.DelaySeconds>=0
		and C.Offline.DelaySeconds<math.huge
end
return C
