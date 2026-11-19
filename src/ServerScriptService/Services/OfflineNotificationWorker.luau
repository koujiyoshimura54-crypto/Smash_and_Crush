-- Dependency-injected worker. No services, real HTTP, clocks or stores at module load.
-- Update callbacks below are pure; adapter preserves current profile and key metadata.
local State=require(script.Parent.OfflineNotificationState)
local M={}
function M.new(d,c)
	local w={}
	local function log(code) if d.Log then d.Log(code) end end
	local function index(key,at)
		if at then d.Index(key,math.ceil(at)) else d.Remove(key) end
	end
	function w.Process(key,userId,generation)
		if not d.Enabled() then return "Disabled" end
		local now=d.Now()
		local profile=d.Read(userId)
		local decision,at=State.Decide(profile,generation,now,c,d.RewardAmount)
		if decision=="ConfirmClock" then
			local saved=d.Update(userId,function(old,committedAt)
				if not State.Matches(old,generation) or old.OfflineNotificationExit.ClockConfirmed then return nil end
				assert(type(committedAt)=="number" and committedAt>=0 and committedAt<math.huge,"CommitTimeUnavailable")
				local n=table.clone(old.OfflineNotificationExit)
				local delay=n.DueAt-n.ConfirmedAt
				n.ConfirmedAt=math.max(n.ConfirmedAt,math.ceil(committedAt))
				n.DueAt=n.ConfirmedAt+delay;n.ClockConfirmed=true
				return n
			end)
			if saved and State.Matches(saved,generation) then index(key,saved.OfflineNotificationExit.DueAt) end
			return "ClockConfirmed"
		end
		if decision=="Online" then
			-- Recovery candidate is NOT a reservation. Never infer exit from a stale heartbeat.
			local acquired=profile.StrengthRewards and profile.StrengthRewards.Presence
			if acquired and now-acquired.At<c.Worker.CandidateLifetimeSeconds then
				index(key,now+c.Worker.RecoverySeconds)
			else index(key,nil) end
			return decision
		end
		if decision=="Cancelled" or decision=="Terminal" then index(key,nil);return decision end
		if decision=="Wait" then index(key,at);return decision end
		if decision~="Ready" then
			d.Update(userId,function(old)
				if not State.Matches(old,generation) then return nil end
				if State.Decide(old,generation,d.Now(),c,d.RewardAmount)~=decision then return nil end
				local n=table.clone(old.OfflineNotificationExit)
				if State.IsTerminal(n) then return nil end
				-- A worker already sending still owns its intent until its lease expires.
				if n.State=="Sending" and d.Now()<(n.LeaseUntil or 0) then return nil end
				n.State=decision;n.FinishedAt=d.Now();return n
			end)
			if decision=="Uncertain" and now<(profile.OfflineNotificationExit.LeaseUntil or 0) then
				index(key,profile.OfflineNotificationExit.LeaseUntil)
			else index(key,nil);log(decision) end
			return decision
		end
		local token=d.Token()
		local saved=d.Update(userId,function(old)
			if State.Decide(old,generation,d.Now(),c,d.RewardAmount)~="Ready" then return nil end
			local n=table.clone(old.OfflineNotificationExit)
			n.State="Leased";n.Lease=token;n.LeaseUntil=d.Now()+c.Worker.LeaseSeconds
			return n
		end)
		local n=saved and saved.OfflineNotificationExit
		if not n or n.Lease~=token or n.State~="Leased" then return "Contended" end
		-- Prepare validates HTTP/Secret before committing a send intent. It NEVER sends.
		local prepared,reason=d.Prepare()
		if not prepared then
			d.Update(userId,function(old)
				if not State.Matches(old,generation) then return nil end
				local current=old.OfflineNotificationExit
				if current.State~="Leased" or current.Lease~=token then return nil end
				local nextState=table.clone(current)
				nextState.Attempts+=1;nextState.State=nextState.Attempts>=c.Worker.MaxAttempts and "LimitReached" or "Pending"
				nextState.NextAttemptAt=d.Now()+c.Worker.MaxBackoffSeconds
				return nextState
			end)
			index(key,d.Now()+c.Worker.MaxBackoffSeconds);log(reason or "Unavailable")
			return reason or "Unavailable"
		end
		-- This commit is the final atomic fence against join/acquire and competing servers.
		saved=d.Update(userId,function(old)
			if not d.Enabled() or not State.Matches(old,generation) then return nil end
			local current=old.OfflineNotificationExit
			if current.State~="Leased" or current.Lease~=token or d.Now()>=current.LeaseUntil then return nil end
			local p=old.StrengthRewards.Presence
			if d.RewardAmount(p.Strength,math.max(0,d.Now()-p.At))<=0 then return nil end
			local nextState=table.clone(current)
			nextState.State="Sending";nextState.Attempts+=1;nextState.SendingAt=d.Now()
			return nextState,{Generation=generation,At=d.Now()}
		end)
		n=saved and saved.OfflineNotificationExit
		if not n or n.Lease~=token or n.State~="Sending" then return "Cancelled" end
		-- Uncached check after the marker. A join after this check can still race in-flight HTTP.
		profile=d.Read(userId)
		if not d.Enabled() or not State.Matches(profile,generation)
			or profile.OfflineNotificationExit.Lease~=token then return "Cancelled" end
		local ok,response=pcall(d.Send,userId,prepared)
		local result=ok and State.Classify(response) or "Uncertain"
		local retryAt=d.Now()+math.min(c.Worker.MaxBackoffSeconds,c.Worker.RetryBaseSeconds*2^(n.Attempts-1))
		-- A failure here leaves Sending durable; recovery does NOT issue another HTTP request.
		d.Update(userId,function(old)
			if not State.Matches(old,generation) then return nil end
			local current=old.OfflineNotificationExit
			if current.State~="Sending" or current.Lease~=token then return nil end
			local nextState=table.clone(current)
			nextState.State=result
			if result=="RateLimited" then
				nextState.State=current.Attempts>=c.Worker.MaxAttempts and "LimitReached" or "Pending"
				nextState.NextAttemptAt=retryAt
			end
			nextState.FinishedAt=d.Now();return nextState
		end)
		if result=="RateLimited" and n.Attempts<c.Worker.MaxAttempts then index(key,retryAt) else index(key,nil) end
		log(result)
		return result
	end
	return w
end
return M
