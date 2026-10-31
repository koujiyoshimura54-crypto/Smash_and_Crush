-- Runs with injected current Sources, a fake clock and an in-memory store only.
return function(sources)
	local checks = 0
	local function eq(a,b) checks+=1; assert(a==b, tostring(a).." ~= "..tostring(b)) end
	local function near(a,b) checks+=1; assert(math.abs(a-b)<1e-7, tostring(a).." ~= "..tostring(b)) end
	local modules = {}
	local fakeGame = {ReplicatedStorage={Config={StrengthRewardConfig="Config",LevelRequirements="Requirements"},Modules={LevelProgression="Progress"}}}
	local parent = {StrengthRewardState="State"}
	local function load(name)
		local fn=assert(loadstring(sources[name],name))
		setfenv(fn,setmetatable({game=fakeGame,script={Parent=parent},require=function(key)return assert(modules[key],key)end},{__index=getfenv()}))
		return fn()
	end
	modules.Config=load("Config");modules.Requirements=load("Requirements");modules.Progress=load("Progress");modules.State=load("State")
	local C,S=modules.Config,modules.State
	near(C.OfflineAmount(1000,0),0);near(C.OfflineAmount(1000,60),3000)
	near(C.OfflineAmount(1000,3600),180000);near(C.OfflineAmount(1000,7200),180000)
	eq(C.Offline.MaxSeconds,3600);eq(C.Offline.Efficiency,.05)
	for i,seconds in ipairs({120,720,2400}) do eq(C.Packs[i].Seconds,seconds) end
	local s=S.Acquire(nil,"first",100)
	eq(next(s.Rewards),nil)
	s=S.Checkpoint(s,"first",200,1000,true)
	s=S.Acquire(s,"second",3800)
	near(s.Rewards.second.Amount,180000)
	local again=S.Acquire(s,"second",999999);near(again.Rewards.second.Amount,180000)
	local online=S.Acquire(s,"simultaneous",3800);eq(online.Rewards.simultaneous,nil)
	local uncertain=S.Acquire(s,"stale-online",1000000);eq(uncertain.Rewards["stale-online"],nil)
	s=S.Checkpoint(s,"second",4000,1,true)
	s=S.Acquire(s,"third",4060);near(s.Rewards.second.Amount,180000);near(s.Rewards.third.Amount,3)
	local other=S.Acquire(nil,"other",1);eq(next(other.Rewards),nil)
	local op={Id="claim",Action="Claim",RewardId="second"}
	local nextState,gain=S.Apply(s,op);near(gain,180000)
	s=nextState
	local _,duplicate=S.Apply(s,op);near(duplicate,0)
	local _,spam=S.Apply(s,{Id="spam",Action="Claim",RewardId="second"});near(spam,0)
	local base=S.Acquire(S.Checkpoint(S.Acquire(nil,"a",0),"a",100,1000,true),"reward",3700)
	local product=C.DoubleOffline.ProductId
	local prep={Id="intent",Action="Prepare",ProductId=product,RewardId="reward"}
	base=assert(S.Apply(base,prep));near(base.Pending[tostring(product)].Amount,180000)
	local resumed=S.Apply(base,{Id="resume",Action="Prepare",ProductId=product,RewardId="reward"})
	eq(resumed.Pending[tostring(product)].Id,"intent")
	local opened=S.Apply(base,{Id="open",Action="Open",ProductId=product,IntentId="intent"})
	eq(opened.Pending[tostring(product)].State,"Prompting")
	eq(S.Apply(opened,{Id="repeat-open",Action="Open",ProductId=product,IntentId="intent"}),nil)
	local receipt={Id="receipt-op",Action="Receipt",ProductId=product,IntentId="intent",PurchaseId="paid"}
	local paid,twice=S.Apply(base,receipt);near(twice,360000);near(paid.Rewards.reward.Paid,360000)
	local _,repeatGain=S.Apply(paid,receipt);near(repeatGain,0)
	local raced,normal=S.Apply(base,{Id="normal",Action="Claim",RewardId="reward"});near(normal,180000)
	local final,additional=S.Apply(raced,receipt);near(additional,180000);near(final.Rewards.reward.Paid,360000)
	local rejoined=S.Acquire(base,"new-server",3701)
	local _,delayed=S.Apply(rejoined,receipt);near(delayed,360000)
	local cancelled=S.Apply(base,{Id="cancel",Action="Cancel",ProductId=product,IntentId="intent"})
	eq(cancelled.Pending[tostring(product)].State,"Cancelled")
	local claimed,claimAfterCancel=S.Apply(cancelled,{Id="normal2",Action="Claim",RewardId="reward"});near(claimAfterCancel,180000)
	local _,lateAfterCancel=S.Apply(claimed,receipt);near(lateAfterCancel,180000)
	local none,_,reason=S.Apply(base,{Id="bad",Action="Receipt",ProductId=product,IntentId="newer",PurchaseId="old"});eq(none,nil);eq(reason,"UnmatchedReceipt")
	local oldEfficiency=C.Offline.Efficiency;C.Offline.Efficiency=.001
	local _,frozen=S.Apply(base,receipt);near(frozen,360000);C.Offline.Efficiency=oldEfficiency
	for _,pack in ipairs(C.Packs) do
		local state=S.Acquire(nil,"pack-player",0)
		state=assert(S.Apply(state,{Id="offer",Action="Prepare",ProductId=pack.ProductId,Amount=1000*pack.Seconds}))
		local applied,amount=S.Apply(state,{Id="deliver",Action="Receipt",ProductId=pack.ProductId,IntentId="offer",PurchaseId="p"})
		near(amount,1000*pack.Seconds)
		local strength,level,progress=modules.Progress.ApplyGain({Strength=17,Level=1,LevelProgress=0},amount)
		near(strength,17+amount);checks+=1;assert(level>1);checks+=1;assert(progress>=0)
		eq(applied.Pending[tostring(pack.ProductId)],nil)
	end
	-- Real persistence adapter: commit-then-lost-response, retry, concurrent gain.
	local Persistence=load("Persistence")
	local original=S.Acquire(nil,"owner",0)
	original=assert(S.Apply(original,{Id="quoted",Action="Prepare",ProductId=C.Packs[1].ProductId,Amount=120000}))
	local before={Strength=10,Level=1,LevelProgress=0,TotalStrengthEarned=10,DailyStrengthEarned=10,DailyDate="2026-10-31"}
	local session={Data=table.clone(before),Loaded=true};session.Data.StrengthRewards=S.Copy(original)
	local transaction={Id="grant",Action="Receipt",ProductId=C.Packs[1].ProductId,IntentId="quoted",PurchaseId="persistence",Before=before}
	session.PendingItemMutation=transaction
	local durable=table.clone(before);durable.StrengthRewards=S.Copy(original)
	local fail=true;local retried=false;local attrs={}
	local player={SetAttribute=function(_,k,v)attrs[k]=v end,GetAttribute=function(_,k)return attrs[k]end}
	local ctx={Current=function()return true end,ResetToken=function()return nil end,Metadata=function()return {},{}end,
		Retry=function()retried=true end,Grant=function(delta)
			session.Data.Strength,session.Data.Level,session.Data.LevelProgress=modules.Progress.ApplyGain(session.Data,delta);return session.Data.Strength
		end}
	ctx.Update=function(transform)
		local value=transform(S.Copy(durable));if value then durable=value end
		if fail then fail=false;error("lost response") end
		return S.Copy(durable)
	end
	local ok=Persistence.Resolve(player,session,transaction,ctx);eq(ok,false);eq(retried,true);near(session.Data.Strength,10)
	session.Data.Strength+=7 -- legitimate online training during an unconfirmed save
	ok=Persistence.Resolve(player,session,transaction,ctx);eq(ok,true);near(session.Data.Strength,120017);near(durable.Strength,120010)
	eq(session.PendingItemMutation,nil)
	checks+=1;assert(S.Normalize({Version=1})==nil)
	return {Checks=checks,OfflineOneHour=180000,OfflineDouble=360000,Persistence="memory only; response loss retried"}
end
