return function(sources)
	local n=0;local cases={}
	local function eq(a,b,label) n+=1;assert(a==b,(label or "check")..": "..tostring(a).." != "..tostring(b)) end
	local function load(source,env)
		local f=assert(loadstring(source));if env then setfenv(f,setmetatable(env,{__index=getfenv()})) end;return f()
	end
	local Config=load(sources.Config);local State=load(sources.State)
	local Persistence=load(sources.Persistence,{script={Parent={RewardedStrengthBoostState="State"}},require=function(k)assert(k=="State");return State end})
	local Controller=load(sources.Controller);local Calculation=load(sources.Calculation)
	local now=1000
	local function receipt(id) return {PurchaseId=id,ProductId=Config.ProductId,PlayerId=123,Channel="AdReward"} end
	local first=assert(State.Apply(nil,receipt("a"),now,300));eq(first.ExpiresAt,1300)
	for _,t in {1000,1299,1300,1301,3000} do eq(State.Bonus(first,t,1),t<1300 and 1 or 0,"expiry boundary") end
	local replay=assert(State.Apply(first,receipt("a"),2000,300));eq(replay.ExpiresAt,1300,"duplicate after expiry")
	eq(assert(State.Apply(first,receipt("b"),1100,300)).ExpiresAt,1600,"distinct receipt extends")
	eq(assert(State.Apply(first,receipt("b"),1400,300)).ExpiresAt,1700,"expired fresh receipt")
	eq(first.ExpiresAt,1300,"pure input preserved")
	local bad=receipt("a");bad.PlayerId=124;eq(State.Apply(first,bad,1100,300),nil,"cross user ID conflict")
	for _,v in {-1,0/0,math.huge,"300"} do eq(State.Apply(first,receipt("b"),now,v),nil,"invalid duration") end
	eq(State.Normalize({ExpiresAt=0/0,Receipts={}}),nil,"corrupt state fails closed")
	cases.PureExpiry=true
	-- Actual owned-profile update wrapper + actual persistence adapter, with an in-memory store.
	local Owned=load("local M={}\n"..sources.OwnedUpdate.."\nreturn M")
	local player={UserId=123,Attributes={}}
	function player:SetAttribute(k,v) self.Attributes[k]=v end
	local session={Loaded=true,OwnerToken="server-a",Data={StrengthBoost=assert(State.Normalize(nil)),Strength=71}}
	local disk={SessionOwnerToken="server-a",StrengthBoost=assert(State.Normalize(nil)),Strength=71,Other="unchanged"}
	local writes,retries=0,0;local mode="ok";local live=true
	local store={}
	function store:UpdateAsync(_,fn)
		writes+=1
		if mode=="before" then error("write refused") end
		local value=fn(disk,nil)
		if value then
			local twice=fn(disk,nil);eq(twice.StrengthBoost.ExpiresAt,value.StrengthBoost.ExpiresAt,"callback replay pure")
			disk=value
		end
		if mode=="lost" then error("ack lost AFTER commit") end
		return value
	end
	local function resolve(id)
		local op=session.PendingItemMutation or receipt(id);op.ResetToken=nil;op.DurationSeconds=300
		session.PendingItemMutation=op
		return Persistence.Resolve(player,session,op,{
			Update=function(fn) return Owned.Update(store,"synthetic",session,fn,function()return live end) end,
			ResetToken=function(old)return old.ResetToken end,Now=function()return now end,
			Metadata=function()return {},{} end,Current=function()return live and not session.OwnershipLost end,
			Retry=function()retries+=1 end,
		})
	end
	mode="before";eq(resolve("p1"),false);eq(disk.StrengthBoost.ExpiresAt,0);eq(player.Attributes.StrengthBoostExpiresAt,nil)
	eq(session.PendingItemMutation.PurchaseId,"p1");eq(retries,1)
	mode="lost";eq(resolve("p1"),false);eq(disk.StrengthBoost.ExpiresAt,1300);eq(player.Attributes.StrengthBoostExpiresAt,nil)
	now=1003;mode="ok";eq(resolve("p1"),true);eq(disk.StrengthBoost.ExpiresAt,1300);eq(player.Attributes.StrengthBoostExpiresAt,1300)
	eq(session.PendingItemMutation,nil);eq(disk.Strength,71);eq(disk.Other,"unchanged")
	eq(resolve("p1"),true);eq(disk.StrengthBoost.ExpiresAt,1300)
	eq(resolve("p2"),true);eq(disk.StrengthBoost.ExpiresAt,1600)
	-- Simultaneous resolver cannot enter a yielding write twice.
	session.PendingItemMutation=receipt("p3");session.PendingItemMutation.Resolving=true
	local beforeWrites=writes;eq(resolve("p3"),false);eq(writes,beforeWrites)
	session.PendingItemMutation=nil
	-- A second server owns the profile: the old writer cannot grant or acknowledge.
	disk.SessionOwnerToken="server-b";eq(resolve("p3"),false);eq(session.OwnershipLost,true);eq(disk.StrengthBoost.ExpiresAt,1600)
	-- New session loads durable state, retains same receipt marker; no reset on travel/death/rejoin.
	session={Loaded=true,OwnerToken="server-b",Data={StrengthBoost=assert(State.Normalize(disk.StrengthBoost))}}
	eq(resolve("p2"),true);eq(session.Data.StrengthBoost.ExpiresAt,1600)
	now=2000;eq(State.Bonus(session.Data.StrengthBoost,now,1),0,"time offline elapsed")
	eq(resolve("p4"),true);eq(disk.StrengthBoost.ExpiresAt,2300)
	cases.OwnershipPersistence=true
	-- Exercise the actual PlayerDataService entry and authoritative bonus methods.
	local sessions={[player]=session};local pd={};local calls=0
	function pd.ResolveItemMutation(p) calls+=1;return resolve(sessions[p].PendingItemMutation.PurchaseId) end
	load(sources.Commit..sources.Bonus,{PlayerDataService=pd,sessions=sessions,BoostState=State,BoostConfig=Config,os={time=function()return now end}})
	eq(pd.CommitStrengthBoostReceipt(player,receipt("p4")),true);eq(calls,0,"confirmed duplicate no extra write")
	eq(pd.GetStrengthBoostBonus(player),1)
	now=2300;eq(pd.GetStrengthBoostBonus(player),0)
	session.Saving=true;eq(pd.CommitStrengthBoostReceipt(player,receipt("p5")),false);session.Saving=false
	session.StrengthClosing=true;eq(pd.CommitStrengthBoostReceipt(player,receipt("p5")),false);session.StrengthClosing=false
	eq(pd.CommitStrengthBoostReceipt(player,receipt("p5")),true);eq(disk.StrengthBoost.ExpiresAt,2600)
	session.Loaded=false;eq(pd.GetStrengthBoostBonus(player),0);eq(pd.CommitStrengthBoostReceipt(player,receipt("p6")),false);session.Loaded=true
	cases.PlayerDataEntry=true
	-- Ad result is not a grant; legitimate late receipts are independent of ad state.
	local adCalls,buyCalls,commits=0,0,0
	local safe,studio,commitOK=true,false,true
	local fakeSession={Loaded=true,Data={StrengthBoost={ExpiresAt=0}}}
	local mono=0;local showed=Enum.ShowAdResult.ShowCompleted
	local d={Config=Config,Now=function()return now end,Monotonic=function()return mono end,
		IsStudio=function()return studio end,Session=function()return fakeSession end,Player=function(id)return id==123 and player or nil end,
		Safe=function()return safe end,CreateReward=function(id)eq(id,3733706770);return "opaqueReward" end,
		Show=function(p,reward,id)eq(p,player);eq(reward,"opaqueReward");eq(id,28777229838999);adCalls+=1;return showed end,
		Purchase=function(_,id)eq(id,3733706770);buyCalls+=1 end,
		Commit=function(_,r)commits+=1;eq(r.Channel,"AdReward");return commitOK end}
	local api=Controller.New(d)
	eq(api.Request(player,"Ad"),"AwaitingReceipt");eq(commits,0);eq(buyCalls,0)
	eq(api.Request(player,"Ad"),"Busy");mono+=4;safe=false;eq(api.Request(player,"Ad"),"ReturnToLobby")
	mono+=4;safe=true;fakeSession.Data.StrengthBoost.ExpiresAt=now+300;eq(api.Request(player,"Ad"),"BoostActive")
	mono+=4;eq(api.Request(player,"Buy"),"Prompted");eq(buyCalls,1)
	local r=receipt("native");r.ProductPurchaseChannel=Enum.ProductPurchaseChannel.AdReward
	eq(api.Receipt(r),Enum.ProductPurchaseDecision.PurchaseGranted)
	commitOK=false;eq(api.Receipt(r),Enum.ProductPurchaseDecision.NotProcessedYet);commitOK=true
	r.PlayerId=321;eq(api.Receipt(r),Enum.ProductPurchaseDecision.NotProcessedYet);r.PlayerId=123
	Config.Enabled=false;eq(api.Request(player,"Ad"),"Unavailable");eq(api.Receipt(r),Enum.ProductPurchaseDecision.PurchaseGranted);Config.Enabled=true
	studio=true;eq(api.Request(player,"Buy"),"StudioPreviewOnly");eq(api.Receipt(r),Enum.ProductPurchaseDecision.NotProcessedYet);studio=false
	fakeSession.Data.StrengthBoost.ExpiresAt=0;mono+=4;showed=Enum.ShowAdResult.ShowInterrupted;eq(api.Request(player,"Ad"),"AdUnavailable")
	d.Show=function()error("ad call timeout")end;mono+=4;eq(api.Request(player,"Ad"),"Unavailable");eq(api.Receipt(r),Enum.ProductPurchaseDecision.PurchaseGranted)
	for _,channel in {Enum.ProductPurchaseChannel.InExperience,Enum.ProductPurchaseChannel.ExperienceDetailsPage,Enum.ProductPurchaseChannel.CommerceProduct} do
		d.Commit=function(_,op)eq(op.Channel,channel.Name);return true end;r.ProductPurchaseChannel=channel
		eq(api.Receipt(r),Enum.ProductPurchaseDecision.PurchaseGranted)
	end
	-- A long-running Show call holds a lock even if the UI's response timer expires.
	d.Show=function()coroutine.yield();return Enum.ShowAdResult.ShowCompleted end;mono+=4
	local co=coroutine.create(function()api.Request(player,"Ad")end);eq(coroutine.resume(co),true)
	mono+=200;eq(api.Request(player,"Ad"),"Busy");eq(coroutine.resume(co),true)
	api.Forget(player)
	cases.AdAndReceiptController=true
	-- Actual AddStrength + actual Calculation, with isolated equipment/session adapters.
	local pass,boost=0,1;local factors={Dumbbell=0,Aura=0,Protein=0,Rebirth=1,StrengthPotion=1,VIP=1,Pet=1}
	local gained=0;local manager={GetStrengthGainMultiplier=function()return factors.Rebirth end,GetStrength=function()return 0 end}
	local env={StrengthManager=manager,validatePlayer=function()return true end,isFiniteNumber=function(x)return type(x)=="number" and x==x and math.abs(x)<math.huge end,
		TrainingLobbyArea={IsInTrainingLobby=function()return true end},DumbbellService={GetStrengthBonus=function()return factors.Dumbbell end},
		ItemService={GetProteinBonus=function()return factors.Protein end},AuraService={GetStrengthBonus=function()return factors.Aura end},
		ShopPasses={GetStrengthPassBonus=function()return pass end,GetVIPStrengthMultiplier=function()return factors.VIP end},
		PlayerData={GetStrengthBoostBonus=function()return boost end},PotionService={GetStrengthMultiplier=function()return factors.StrengthPotion end},
		PetServer={GetStrengthMultiplier=function()return factors.Pet end},Calculation=Calculation,Analytics={Strength=function()end},
		commitGain=function(_,v)gained=v;return v end}
	load(sources.Training..sources.Direct,env)
	for _,world in {1,2} do for _,permanent in {0,1} do pass=permanent
		for _,source in {"Walking","Manual"} do eq(manager.AddStrength(player,1,1,nil,source),2+pass,source..world) end
		for _,base in {1,world==1 and 7 or 15,29} do eq(manager.AddStrength(player,1,1,base),base+pass+1,"Treadmill additive") end
	end end
	pass=1;factors={Dumbbell=3,Aura=5,Protein=7,Rebirth=2,StrengthPotion=3,VIP=1.1,Pet=1.5}
	eq(manager.AddStrength(player,2,2,10),Calculation.Gain(2,2,factors,12),"existing equipment/order, Belt/TrainingPotion in source")
	eq(manager.AddRewardStrength(player,42),42,"offline/daily/purchased direct gains bypass boost")
	boost=0;eq(manager.AddStrength(player,2,2,10),Calculation.Gain(2,2,factors,11),"expiry removes only temporary +1")
	cases.TrainingCalculation=true
	return {Assertions=n,Cases=cases,Mode="Edit / memory mocks / actual source functions; no Play, live data, ads or purchases"}
end
