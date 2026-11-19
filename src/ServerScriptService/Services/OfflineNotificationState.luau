-- Pure notification outbox transitions. Never awards rewards or changes ownership.
local M = {}
local terminal = {Accepted=true, Cancelled=true, Expired=true, ZeroReward=true,
	Uncertain=true, AuthError=true, Ineligible=true, InvalidRequest=true, LimitReached=true}
function M.Departure(previous, generation, now, presence, delay)
	if previous and previous.Generation==generation then return previous end
	if not presence or presence.State~="Offline" or presence.Basis~="DepartureStrengthV1" then return nil end
	return {Version=1, Generation=generation, ConfirmedAt=now, DueAt=now+delay, State="Pending", Attempts=0}
end
function M.Matches(profile, generation)
	local p=profile and profile.StrengthRewards and profile.StrengthRewards.Presence
	local n=profile and profile.OfflineNotificationExit
	return profile and profile.SessionOwnerToken==generation and p and p.State=="Offline"
		and p.Basis=="DepartureStrengthV1" and n and n.Version==1 and n.Generation==generation
end
function M.IsTerminal(n) return n and terminal[n.State]==true end
function M.Decide(profile, generation, now, config, rewardAmount)
	if not profile or profile.SessionOwnerToken~=generation then return "Cancelled" end
	if not M.Matches(profile,generation) then return "Online" end
	local n=profile.OfflineNotificationExit
	if M.IsTerminal(n) then return "Terminal" end
	-- The original callback timestamp precedes durable commit. Confirm from key metadata
	-- once before sending, so slow saves cannot start the 24-hour delay prematurely.
	if not n.ClockConfirmed then return "ConfirmClock" end
	-- A durable Sending intent is never automatically resent, even after a crash.
	if n.State=="Sending" then return "Uncertain" end
	if now<n.DueAt then return "Wait",n.DueAt end
	if now>n.DueAt+config.Worker.MaxLatenessSeconds then return "Expired" end
	local p=profile.StrengthRewards.Presence
	if rewardAmount(p.Strength,math.max(0,now-p.At))<=0 then return "ZeroReward" end
	if n.Attempts>=config.Worker.MaxAttempts then return "LimitReached" end
	if n.State=="Leased" and now<(n.LeaseUntil or 0) then return "Wait",n.LeaseUntil end
	if now<(n.NextAttemptAt or 0) then return "Wait",n.NextAttemptAt end
	local last=profile.OfflineNotificationLastAttempt
	if last and last.Generation~=generation and now<last.At+config.Worker.DailyLimitSeconds then
		return "Wait",last.At+config.Worker.DailyLimitSeconds
	end
	return "Ready"
end
function M.Classify(response)
	if type(response)~="table" then return "Uncertain" end
	local status=response.StatusCode
	if type(status)~="number" then return "Uncertain" end
	if status>=200 and status<300 then return "Accepted" end
	if status==429 then return "RateLimited" end -- Explicit rejection, bounded backoff.
	if status==401 then return "AuthError" end
	if status==403 then return "AuthError" end -- Do not infer user age/consent from generic 403.
	if status==400 or status==404 then return "InvalidRequest" end
	if status==412 then return "Ineligible" end
	-- 408/5xx/unknown responses can follow a side effect. Prefer omission to duplication.
	return "Uncertain"
end
return M
