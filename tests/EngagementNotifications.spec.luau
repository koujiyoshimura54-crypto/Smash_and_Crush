-- Native Edit/CLI fixture: injected Source, memory storage, fake clock and HTTP only.
return function(sources)
local checks,groups=0,{}
local function eq(a,b) checks+=1;assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function group(name) table.insert(groups,name) end
local function load(name,env)
	local fn=assert(loadstring(assert(sources[name],name),name))
	setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
end
local C=load("Config")
local S=load("State")
local R=load("RewardConfig")
local W=load("Worker",{script={Parent={OfflineNotificationState="State"}},require=function(k) assert(k=="State");return S end})
local P=load("Prompts")
local function copy(x) if type(x)~="table" then return x end local o={} for k,v in pairs(x) do o[k]=copy(v) end return o end
group("String IDs / missing / independent settings")
C.Offline.OfflineRewardMessageId="" -- Exercise absence independently of deployment settings.
eq(C.OfflineConfigured(),false);eq(C.HasMessageId(123),false);eq(C.HasMessageId(""),false)
eq(C.HasMessageId("ここに通知文面ID"),false);eq(C.HasMessageId("000"),false)
eq(C.HasMessageId("12345678901234567890"),true)
eq(C.HasMessageId("12345678-1234-1234-1234-123456789abc"),true)
eq(C.HasMessageId("00000000-0000-0000-0000-000000000000"),false)
eq(C.HasMessageId("123-45"),false)
C.Offline.OfflineRewardMessageId="12345678901234567890"
eq(C.OfflineConfigured(),true);eq(C.Invite.FriendInviteMessageId,"")
local function fixture()
	local f={now=100, sends=0, updates=0, token=0, enabled=true, index={}, logs={},status=200, reads=0}
	f.raw={SessionOwnerToken="one",Strength=10000,OwnedItems={KEEP=3},Level=10,
		StrengthRewards={Owner="one",Presence={State="Offline",At=100,Basis="DepartureStrengthV1",Strength=10000}}}
	f.raw.OfflineNotificationExit=S.Departure(nil,"one",100,f.raw.StrengthRewards.Presence,C.Offline.DelaySeconds)
	f.raw.OfflineNotificationExit.ClockConfirmed=true -- Production adapter test covers metadata confirmation separately.
	f.now=f.raw.OfflineNotificationExit.DueAt
	local d={Now=function()return f.now end,Enabled=function()return f.enabled end,
		RewardAmount=R.OfflineAmount,Token=function() f.token+=1;return "lease"..f.token end,
		Read=function() f.reads+=1;if f.onRead then f.onRead(f.reads) end;return copy(f.raw) end,
		Update=function(_,transform)
			f.updates+=1;if f.beforeUpdate then f.beforeUpdate(f.updates) end
			if f.failUpdate==f.updates then error("before write") end
			-- Replay transform like optimistic UpdateAsync contention; no external side effects.
			transform(copy(f.raw))
			local n,last=transform(copy(f.raw))
			if not n then return nil end
			f.raw=copy(f.raw);f.raw.OfflineNotificationExit=n
			if last then f.raw.OfflineNotificationLastAttempt=last end
			if f.loseUpdate==f.updates then error("committed / lost acknowledgement") end
			return copy(f.raw)
		end,
		Prepare=function()
			if f.onPrepare then f.onPrepare() end
			if f.prepareError then return nil,f.prepareError end
			return {Key="FAKE-NOT-A-SECRET"}
		end,
		Send=function()
			f.sends+=1;if f.onSend then f.onSend() end
			if f.timeout then error("response lost") end
			return {StatusCode=f.status}
		end,
		Index=function(key,at) if f.indexFail then error("index unavailable") end;f.index[key]=at end,
		Remove=function(key) if f.indexFail then error("index unavailable") end;f.index[key]=nil end,
		Log=function(code) table.insert(f.logs,code) end,
	}
	f.worker=W.new(d,C);f.second=W.new(d,C)
	function f.process() return f.worker.Process("one-key",1,"one") end
	return f
end
group("Committed exit / due before, exact and after / unchanged reward")
for _,offset in ipairs({-1,0,1}) do
	local f=fixture();f.now+=offset
	eq(f.process(),offset<0 and "Wait" or "Accepted");eq(f.sends,offset<0 and 0 or 1)
	eq(f.raw.Strength,10000);eq(f.raw.Level,10);eq(f.raw.OwnedItems.KEEP,3)
	if offset>=0 then eq(f.process(),"Terminal");eq(f.sends,1) end
end
local f=fixture();local old=f.raw.OfflineNotificationExit
eq(S.Departure(old,"one",999999,f.raw.StrengthRewards.Presence,86400),old)
group("No confirmed exit / save failure / recovery candidates")
f=fixture();f.raw.StrengthRewards.Presence.State="Online";f.raw.OfflineNotificationExit=nil
eq(f.process(),"Online");eq(f.sends,0);eq(f.index["one-key"],f.now+C.Worker.RecoverySeconds)
f.now+=C.Worker.CandidateLifetimeSeconds;eq(f.process(),"Online");eq(f.index["one-key"],nil)
f=fixture();f.indexFail=true;eq(pcall(f.process),false);eq(f.sends,1)
f.indexFail=false;eq(f.process(),"Terminal");eq(f.sends,1)
group("Rejoin / cross-server acquire / re-exit / daily protection")
f=fixture();f.now-=1;f.raw.SessionOwnerToken="two";f.raw.OfflineNotificationExit=nil
f.raw.StrengthRewards.Presence.State="Online"
eq(f.process(),"Cancelled");eq(f.sends,0)
f.raw.StrengthRewards.Presence.State="Offline";f.raw.StrengthRewards.Presence.At=f.now
f.raw.OfflineNotificationExit=S.Departure(nil,"two",f.now,f.raw.StrengthRewards.Presence,86400)
	f.raw.OfflineNotificationExit.ClockConfirmed=true
eq(f.second.Process("two-key",1,"two"),"Wait");f.now+=86400
eq(f.second.Process("two-key",1,"two"),"Accepted");eq(f.sends,1)
f=fixture();f.raw.OfflineNotificationLastAttempt={Generation="prior",At=f.now-100}
eq(f.process(),"Wait");eq(f.sends,0)
group("Multiple workers / lease expiry before HTTP / final ownership fence")
f=fixture();f.onPrepare=function() eq(f.second.Process("one-key",1,"one"),"Wait") end
eq(f.process(),"Accepted");eq(f.sends,1)
f=fixture();f.onPrepare=function()
	f.onPrepare=nil;f.now+=C.Worker.LeaseSeconds
	eq(f.second.Process("one-key",1,"one"),"Accepted")
end
eq(f.process(),"Cancelled");eq(f.sends,1)
f=fixture();f.onPrepare=function() f.raw.SessionOwnerToken="two";f.raw.OfflineNotificationExit=nil end
eq(f.process(),"Cancelled");eq(f.sends,0)
f=fixture();f.onRead=function(n) if n==2 then f.raw.SessionOwnerToken="two";f.raw.OfflineNotificationExit=nil end end
eq(f.process(),"Cancelled");eq(f.sends,0)
group("Stopped servers / deferred recovery / expiration / zero reward / disabled")
f=fixture();f.now+=3600;eq(f.process(),"Accepted");eq(f.sends,1)
f=fixture();f.now+=C.Worker.MaxLatenessSeconds+1;eq(f.process(),"Expired");eq(f.sends,0)
f=fixture();f.raw.StrengthRewards.Presence.Strength=0;eq(f.process(),"ZeroReward");eq(f.sends,0)
f=fixture();f.enabled=false;eq(f.process(),"Disabled");eq(f.reads,0)
group("Secret / HTTP preflight unavailable: bounded retries without sends")
for _,reason in ipairs({"SecretUnavailable","HttpDisabled"}) do
	f=fixture();f.prepareError=reason
	for _=1,C.Worker.MaxAttempts do eq(f.process(),reason);f.now+=C.Worker.MaxBackoffSeconds end
	eq(f.process(),"Terminal");eq(f.raw.OfflineNotificationExit.State,"LimitReached");eq(f.sends,0)
end
group("401 / 403 / 400 / 412 permanent errors and 429 bounded backoff")
for code,result in pairs({[401]="AuthError",[403]="AuthError",[400]="InvalidRequest",[412]="Ineligible"}) do
	f=fixture();f.status=code;eq(f.process(),result);eq(f.process(),"Terminal");eq(f.sends,1)
end
f=fixture();f.status=429
for attempt=1,C.Worker.MaxAttempts do
	eq(f.process(),"RateLimited");eq(f.sends,attempt)
	if attempt<C.Worker.MaxAttempts then eq(f.process(),"Wait");f.now=f.raw.OfflineNotificationExit.NextAttemptAt end
end
eq(f.process(),"Terminal");eq(f.raw.OfflineNotificationExit.State,"LimitReached")
group("Timeout / lost response / failed accepted-record / durable pre-send crash")
f=fixture();f.timeout=true;eq(f.process(),"Uncertain");eq(f.process(),"Terminal");eq(f.sends,1)
f=fixture();f.status=503;eq(f.process(),"Uncertain");eq(f.process(),"Terminal");eq(f.sends,1)
for _,mode in ipairs({"failUpdate","loseUpdate"}) do
	f=fixture();f[mode]=3;eq(pcall(f.process),false);eq(f.sends,1)
	f[mode]=nil;f.now+=C.Worker.LeaseSeconds+1
	f.process();eq(f.sends,1)
end
f=fixture();f.loseUpdate=2;eq(pcall(f.process),false);eq(f.sends,0)
f.loseUpdate=nil;f.now+=C.Worker.LeaseSeconds+1;eq(f.process(),"Uncertain");eq(f.sends,0)
f=fixture();f.failUpdate=1;eq(pcall(f.process),false);eq(f.sends,0)
f.failUpdate=nil;eq(f.process(),"Accepted");eq(f.sends,1)
group("Rejoin while HTTP already in flight is not falsely reported as prevented")
f=fixture();f.onSend=function()f.raw.SessionOwnerToken="two";f.raw.OfflineNotificationExit=nil end
eq(f.process(),"Accepted");eq(f.sends,1);eq(f.raw.OfflineNotificationExit,nil)
group("Prompt eligibility / cancel / double click / errors / cleanup (no real prompts)")
local function signal()
	local s={}
	function s:Connect(fn) self.fn=fn;return {Disconnect=function()self.fn=nil end} end
	function s:Fire(...) if self.fn then self.fn(...) end end
	return s
end
for _,kind in ipairs({"Invite","Notify"}) do
	local closed=signal();local calls,queries,now=0,0,0;local can,enabled=true,true;local failCheck,failPrompt=false,false
	local p=P.new({Now=function()return now end,Closed=closed,Enabled=function()return enabled end,
		CanPrompt=function() queries+=1;if failCheck then error("fake") end;return can end,
		Prompt=function()if failPrompt then error("fake") end;calls+=1 end})
	eq(calls,0);eq(p.Click(),"Opened");eq(p.Click(),"DisabledOrBusy");eq(calls,1)
	closed:Fire();eq(p.Click(),"DisabledOrBusy");now+=2;can=false
	eq(p.Click(),"Unavailable");eq(calls,1);closed:Fire();now+=2;can=true;failCheck=true
	eq(p.Click(),"CheckFailed");now+=2;failCheck=false;failPrompt=true
	eq(p.Click(),"PromptFailed");now+=2;failPrompt=false
	eq(p.Click(),"Opened");closed:Fire();now+=2;enabled=false
	local q=queries;eq(p.Click(),"DisabledOrBusy");eq(queries,q)
	p.Destroy();enabled=true;eq(p.Click(),"DisabledOrBusy");eq(closed.fn,nil)
end
group("Actual profile acquisition atomically cancels previous exit and retains receipt journal")
local modules={State=load("RewardState",{game={ReplicatedStorage={Config={StrengthRewardConfig="Config"}}},require=function()return R end}),
	RunReturn={Recover=function()end},AdminWin={Acquire=function(d)return d end}}
local O=load("Ownership",{script={Parent={StrengthRewardState="State",RunReturnPersistence="RunReturn",ProductionWinState="AdminWin"}},
	game={ReplicatedStorage={Modules={}}},require=function(k)return assert(modules[k],k)end})
local raw={OwnedItems={KEEP=3},SessionOwnerToken="first"}
raw.StrengthRewards=modules.State.Checkpoint(modules.State.Acquire(nil,"first",0),"first",100,10000,true)
raw.OfflineNotificationExit=S.Departure(nil,"first",100,raw.StrengthRewards.Presence,86400)
raw.OfflineNotificationLastAttempt={Generation="older",At=50}
local store={GetAsync=function()return copy(raw)end,
	UpdateAsync=function(_,_,fn)local v=fn(copy(raw));if v then raw=v end;return copy(raw)end}
O.Acquire(store,"fake",{Token="second",StrengthNow=3700},function()error("unexpected")end,function(d)return d end,function()return true end)
eq(raw.SessionOwnerToken,"second");eq(raw.OfflineNotificationExit,nil)
eq(raw.OfflineNotificationLastAttempt.At,50);eq(raw.StrengthRewards.Rewards.second.Amount,400)
eq(raw.OwnedItems.KEEP,3)
return {Checks=checks,Groups=groups,Execution="isolated Source with memory adapters; no actual requests"}
end
