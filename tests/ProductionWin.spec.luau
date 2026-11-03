-- Edit-only exact-Source isolated unit checks; no real datastore access.
local original=game;local Players={};local State=require(game.ServerScriptService.Services.ProductionWinState)
local storeValues,storedUsers,storedMeta={},{},{}
local function copy(x)if type(x)~="table" then return x end local y={}for k,v in x do y[k]=copy(v)end return y end
local store={}
function store:GetAsync(k)return copy(storeValues[k])end
function store:UpdateAsync(k,fn)
 local info={GetUserIds=function()return copy(storedUsers[k] or {})end,GetMetadata=function()return copy(storedMeta[k] or {})end}
 local v,u,m=fn(copy(storeValues[k]),info)
 if v then storeValues[k]=copy(v);storedUsers[k]=copy(u or {});storedMeta[k]=copy(m or {}) end
 return copy(storeValues[k])
end
local env=setmetatable({script=game.ServerScriptService.Services.ProductionWinService,game=setmetatable({PlaceId=126576845524886,GameId=10765181857,GetService=function(_,n)
 if n=="Players" then return Players end;if n=="RunService" then return {IsStudio=function()return true end}end
 if n=="MessagingService" then return {PublishAsync=function()error("isolated message outage")end}end
 return original:GetService(n)
end},{__index=function(_,k)return original[k]end}),typeof=function(x)if type(x)=="table" and x.TestPlayer then return "Instance"end return typeof(x)end},{__index=getfenv()})
local f=assert(loadstring(game.ServerScriptService.Services.ProductionWinService.Source));setfenv(f,env);local M=f()
local issuer={UserId=7467238848,Parent=Players,TestPlayer=true,IsA=function()return true end}
local target={UserId=321,SetAttribute=function(self,k,v)self[k]=v end}
local key="Player_321";storeValues[key]={Win=17,ResetToken="R",SessionOwnerToken="O",OwnedOres={ORE_001=8},Level=43};storedUsers[key]={321};storedMeta[key]={test="kept"}
local ok,message=M.Request(issuer,321,1000,store);assert(not ok and message:find("Pending",1,true))
local requestId=storeValues[key].AdminWin.Request.Id
local repeated=M.Request(issuer,321,1000,store);assert(not repeated and storeValues[key].AdminWin.Request.Id==requestId)
local different,why=M.Request(issuer,321,0,store);assert(not different and why:find("AnotherWinChangePending",1,true))
local session={Loaded=true,Data={Win=17,ResetToken="R"},OwnerToken="O"}
assert(M.Sync(target,session,store,function()return true end))
assert(session.Data.Win==1000 and target.Win==1000)
assert(storedMeta[key].test=="kept" and storedUsers[key][1]==321)
assert(storeValues[key].OwnedOres.ORE_001==8 and storeValues[key].Level==43)
local savedId=State.AppliedId(storeValues[key]);assert(savedId==session.AdminWinAppliedId)
assert(M.Sync(target,session,store,function()return true end))
-- Login consumes a pending directive once; a later earned balance is not replaced.
local raw={Win=2,ResetToken="R",AdminWin={Request={Id="next",Value=25,ActorUserId=7467238848,ResetToken="R"}}}
local acquired=State.Acquire(raw,"newOwner");assert(acquired.Win==25)
acquired.Win=27;assert(State.Acquire(acquired,"anotherOwner").Win==27)
raw.ResetToken="RESET";assert(State.Acquire(raw,"resetOwner").Win==2)
return {DuplicateRequestKeptId=true,ConflictingRequestRejected=true,MessagingOutagePending=true,MetadataPreserved=true,NonWinFieldsPreserved=true,LoginOnce=true,ResetFence=true}
