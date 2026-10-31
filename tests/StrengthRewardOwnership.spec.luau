return function(sources)
local config=assert(loadstring(sources.Config))()
local modules={Config=config,RunReturn={Recover=function()end}}
local function load(source)
local fn=assert(loadstring(source));setfenv(fn,setmetatable({game={ReplicatedStorage={Config={StrengthRewardConfig="Config"}}},script={Parent={StrengthRewardState="State",RunReturnPersistence="RunReturn"}},require=function(k)return modules[k]end},{__index=getfenv()}));return fn()
end
modules.State=load(sources.State);local S=modules.State
local O=load(sources.Ownership)
local raw=nil;local fail=false;local count=0
local store={}
function store:GetAsync() if fail then error("read failed")end;return raw end
function store:UpdateAsync(_,transform) local result=transform(raw);if result then raw=result end;return raw end
local function defaults()return {OwnedItems={}}end
local function normalize(value)return value or defaults()end
local function eq(a,b)count+=1;assert(a==b,tostring(a).." ~= "..tostring(b))end
fail=true;local attempt={Token="one"}
eq(pcall(O.Acquire,store,"test",attempt,defaults,normalize,function()return true end),false);eq(raw,nil);eq(attempt.Read,nil)
fail=false;O.Acquire(store,"test",attempt,defaults,normalize,function()return true end)
eq(raw.SessionOwnerToken,"one");eq(next(raw.StrengthRewards.Rewards),nil)
raw.StrengthRewards=S.Checkpoint(raw.StrengthRewards,"one",100,1000,true)
local nextAttempt={Token="two",StrengthNow=3700}
O.Acquire(store,"test",nextAttempt,defaults,normalize,function()return true end)
eq(raw.StrengthRewards.Rewards.two.Amount,180000)
O.Acquire(store,"test",nextAttempt,defaults,normalize,function()return true end)
eq(raw.StrengthRewards.Rewards.two.Amount,180000)
local oldSession={OwnerToken="one"}
eq(pcall(O.Update,store,"test",oldSession,function()error("must not run")end,function()return true end),false)
eq(oldSession.OwnershipLost,true)
local third={Token="three",StrengthNow=3700}
O.Acquire(store,"test",third,defaults,normalize,function()return true end)
eq(raw.StrengthRewards.Rewards.three,nil);eq(raw.StrengthRewards.Rewards.two.Amount,180000)
return {Checks=count,Store="memory only",OwnershipFence=true,FailedReadDidNotCreateData=true}
end

