-- Executes the production adapter / client callable module with trapped services.
return function(sources)
local checks=0
local function eq(a,b) checks+=1;if a~=b then error("Values differ") end end
local function load(source,env)
	local fn=assert(loadstring(source));setfenv(fn,setmetatable(env or {},{__index=getfenv()}));return fn()
end
local function copy(v)if type(v)~="table"then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local JSON=game:GetService("HttpService") -- encoding only, never network
local function fixture(studio,configured)
	local f={now=100,http=0,secret=0,stores=0,sorted=0,threads={},indexes={},profiles={},coord={},budget=1000,logs={}}
	local c=load(sources.Config);c.LogTransitions=false
	if configured then c.Offline.OfflineRewardMessageId="12345678901234567890" end
	local secret=setmetatable({},{__tostring=function()error("Secret must never be stringified")end})
	local info={UpdatedTime=100000,GetUserIds=function()return {1}end,GetMetadata=function()return {Preserve="yes"}end}
	local profileStore={}
	function profileStore:GetAsync(key) return copy(f.profiles[key]) end
	function profileStore:UpdateAsync(key,fn)
		local result,users,meta=fn(copy(f.profiles[key]),info)
		if result then eq(users[1],1);eq(meta.Preserve,"yes");f.profiles[key]=result end
		return copy(result)
	end
	local index={}
	function index:SetAsync(key,at) if f.indexFailure then error("index unavailable")end;f.indexes[key]=at end
	function index:RemoveAsync(key) f.indexes[key]=nil end
	function index:GetSortedAsync(ascending,limit,min,max)
		f.sorted+=1;eq(ascending,true);eq(limit,c.Worker.MaxBatch)
		local rows={}for key,at in pairs(f.indexes)do if at>=min and at<=max then table.insert(rows,{key=key,value=at}) end end
		table.sort(rows,function(a,b)return a.value<b.value end)
		while #rows>limit do table.remove(rows) end
		return {GetCurrentPage=function()return rows end}
	end
	local coordinate={UpdateAsync=function(_,key,fn)local v=fn(f.coord[key]);if v then f.coord[key]=v end;return v end}
	local DSS={GetRequestBudgetForRequestType=function()return f.budget end,
		GetDataStore=function(_,name)f.stores+=1;if name=="PlayerData_v1" then return profileStore end;eq(name,"OfflineNotifyWorker_v1");return coordinate end,
		GetOrderedDataStore=function(_,name)f.stores+=1;eq(name,"OfflineNotifyDue_v1");return index end}
	local count=0
	local Http={HttpEnabled=true,GenerateGUID=function()count+=1;return string.format("00000000-0000-0000-0000-%012d",count)end,
		GetSecret=function(_,name)f.secret+=1;eq(name,"OfflineRewardNotificationKey");if f.secretFailure then error("fake")end;return secret end,
		JSONEncode=function(_,v)return JSON:JSONEncode(v)end,
		RequestAsync=function(_,request)
			f.http+=1;f.request=request
			eq(request.Headers["x-api-key"],secret);eq(request.Headers["Content-Type"],"application/json")
			eq(request.Method,"POST");eq(request.Url,"https://apis.roblox.com/cloud/v2/users/1/notifications")
			local body=JSON:JSONDecode(request.Body)
			eq(body.source.universe,"universes/10765181857");eq(body.payload.type,"MOMENT")
			eq(body.payload.message_id,c.Offline.OfflineRewardMessageId);eq(body.payload.messageId,nil)
			return {StatusCode=200}
		end}
	local services={RunService={IsStudio=function()return studio end},HttpService=Http,DataStoreService=DSS}
	local modules={Config=c,Reward=load(sources.RewardConfig)}
	modules.State=load(sources.State)
	modules.Worker=load(sources.Worker,{script={Parent={OfflineNotificationState="State"}},require=function(k)return modules[k]end})
	local function resume(co) local ok,err=coroutine.resume(co);assert(ok,err)end
	local schedule={spawn=function(fn)local co=coroutine.create(fn);table.insert(f.threads,co);resume(co)end,
		wait=function()coroutine.yield()end}
	f.service=load(sources.Service,{game={GameId=10765181857,GetService=function(_,name)return assert(services[name],name)end,
		ReplicatedStorage={Config={EngagementConfig="Config",StrengthRewardConfig="Reward"}}},
		script={Parent={OfflineNotificationWorker="Worker"}},require=function(k)return modules[k]end,
		task=schedule,os={time=function()return f.now end}})
	f.config=c;f.httpService=Http;f.state=modules.State
	function f.step()for _,co in ipairs(table.clone(f.threads))do if coroutine.status(co)~="dead"then resume(co)end end end
	f.generation="abcdef00-1234-5678-9012-123456789abc"
	function f.exit()
		local profile={SessionOwnerToken=f.generation,Strength=10000,OwnedItems={KEEP=1},StrengthRewards={Presence={State="Offline",At=f.now,Basis="DepartureStrengthV1",Strength=10000}}}
		profile.OfflineNotificationExit=f.state.Departure(nil,f.generation,f.now,profile.StrengthRewards.Presence,c.Offline.DelaySeconds)
		f.profiles.Player_1=profile
		info.UpdatedTime=(f.now+5)*1000 -- Simulate a save taking five seconds after its callback.
		return profile.OfflineNotificationExit
	end
	return f
end
-- Actual Studio adapter and missing-ID adapter cause zero store / Secret / HTTP calls.
for _,setting in ipairs({{true,true},{true,false},{false,false}})do
	local f=fixture(setting[1],setting[2]);f.service.Init();f.service.Joined(1,f.generation);f.service.Committed(1,f.exit())
	eq(f.http,0);eq(f.secret,0);eq(f.stores,0);eq(#f.threads,0)
end
local f=fixture(false,true)
f.service.Init();f.service.Init();eq(#f.threads,1)
f.service.Joined(1,f.generation);f.now+=10
local exit=f.exit();f.service.Committed(1,exit);eq(f.http,0)
f.now=exit.DueAt-1;f.step();eq(f.http,0)
f.now=exit.DueAt;f.step();eq(f.http,0)
eq(f.profiles.Player_1.OfflineNotificationExit.DueAt,exit.DueAt+5)
f.now+=5;f.step();eq(f.http,1);eq(f.profiles.Player_1.OfflineNotificationExit.State,"Accepted")
eq(f.profiles.Player_1.Strength,10000);eq(f.profiles.Player_1.OwnedItems.KEEP,1)
f.step();eq(f.http,1);eq(next(f.indexes),nil)
-- Committed outbox remains discoverable from the pre-existing successful-join candidate
-- when the exit's enqueue failed, including after a simulated full-server outage.
f=fixture(false,true);f.service.Init();f.service.Joined(1,f.generation)
f.now+=10;exit=f.exit();f.indexFailure=true;f.service.Committed(1,exit)
f.indexFailure=false;f.now=exit.DueAt+3600;f.step();f.step();eq(f.http,1)
-- Budget gate / single dispatcher lock avoid querying all profiles.
f=fixture(false,true);f.service.Init();f.service.Committed(1,f.exit());f.now+=86400
f.budget=0;f.step();eq(f.http,0);eq(f.sorted,0)
f.budget=1000;f.coord.Dispatcher={Owner="another-server",Until=f.now+120};f.step();eq(f.sorted,0)
f.now+=120;f.step();f.step();eq(f.http,1)
-- Actual preflight suppresses calls and allows only bounded attempts.
for _,failure in ipairs({"http","secret"})do
	f=fixture(false,true);f.service.Init();f.service.Committed(1,f.exit());f.now+=86400
	if failure=="http"then f.httpService.HttpEnabled=false else f.secretFailure=true end
	for _=1,5 do f.step();f.now+=3600 end
	eq(f.http,0);eq(f.profiles.Player_1.OfflineNotificationExit.State,"LimitReached")
end
-- Callable client integration: module load does nothing, methods use only fake native APIs.
local c=load(sources.Config);c.Invite.FriendInviteMessageId="12345678901234567890";c.Offline.OfflineRewardMessageId="22222222222222222222"
local function signal()local s={};function s:Connect(fn)self.fn=fn;return {Disconnect=function()self.fn=nil end}end;return s end
local inviteClosed,notifyClosed=signal(),signal();local invitations,opts,permissions=0,0,0;local player={}
local Social={GameInvitePromptClosed=inviteClosed,CanSendGameInviteAsync=function(_,p)eq(p,player);return true end,
	PromptGameInvite=function(_,p,o)eq(p,player);eq(o.InviteMessageId,c.Invite.FriendInviteMessageId);invitations+=1 end}
local Notification={OptInPromptClosed=notifyClosed,CanPromptOptInAsync=function()return true end,PromptOptIn=function()permissions+=1 end}
local services={RunService={IsClient=function()return true end},Players={LocalPlayer=player},SocialService=Social,ExperienceNotificationService=Notification}
local prompts=load(sources.Prompts)
local client=load(sources.Client,{game={GetService=function(_,n)return assert(services[n],n)end,ReplicatedStorage={Config={EngagementConfig="Config"}}},
	script={Parent={EngagementPrompts="Prompts"}},require=function(k)return k=="Config"and c or prompts end,
	Instance={new=function(class)eq(class,"ExperienceInviteOptions");opts+=1;return {Destroy=function()opts-=1 end}end}})
eq(invitations,0);eq(permissions,0);eq(inviteClosed.fn,nil)
eq(client.Invite(),"Opened");eq(client.Invite(),"DisabledOrBusy");eq(invitations,1);eq(opts,0)
eq(client.NotifyMe(),"Opened");eq(client.NotifyMe(),"DisabledOrBusy");eq(permissions,1)
client.Destroy();eq(inviteClosed.fn,nil);eq(notifyClosed.fn,nil)
return {Checks=checks,Execution="actual service/client Source with trapped DataStore/Secret/HTTP/native-prompt adapters"}
end
