-- Current production Sources, isolated values only; no DataStore or purchases.
return function(sources)
 local count=0
 local function eq(a,b) count+=1;assert(a==b,tostring(a).." ~= "..tostring(b)) end
 local function near(a,b) count+=1;assert(math.abs(a-b)<=math.max(1e-10,math.abs(b)*1e-14),tostring(a).." ~= "..tostring(b)) end
 local C=assert(loadstring(sources.Config))()
 local f=assert(loadstring(sources.State))
 setfenv(f,setmetatable({game={ReplicatedStorage={Config={StrengthRewardConfig=true}}},require=function()return C end},{__index=getfenv()}))
 local S=f()
 for _,row in ipairs({{0,0},{3600,.04},{43200,.48},{86400,.96},{172800,.96}}) do
  near(C.OfflineAmount(1234.567,row[1]),1234.567*row[2]);eq(C.OfflineAmount(0,row[1]),0)
  local a=S.Acquire(nil,"first",0)
  a=S.Checkpoint(a,"first",100,1234.567,true)
  local b=S.Acquire(a,"second",100+row[1]);local _,r=S.NextReward(b)
  if row[1]==0 then eq(r,nil) else near(r.Amount,1234.567*row[2]);eq(r.Seconds,math.min(row[1],86400)) end
 end
 near(C.OfflineAmount(1.7e308,86400),1.632e308)
 eq(pcall(C.OfflineAmount,math.huge,3600),false)
 eq(pcall(C.OfflineAmount,0/0,3600),false)
 -- Legacy Rate is never reinterpreted; an old immutable paid quote survives.
 for _,paid in ipairs({0,123.456}) do
  local product=C.DoubleOffline.ProductId
  local old={Version=1,Owner="old",GrantedTotal=paid,
   Presence={State="Offline",At=100,Rate=999999999},
   Rewards={old={Amount=123.456,Paid=paid,CreatedAt=50}},
   Pending={[tostring(product)]={Id="intent",ProductId=product,Kind="DoubleOffline",RewardId="old",Amount=123.456,State="Cancelled"}},
   Receipts={previous={ProductId=C.Packs[1].ProductId,IntentId="pack-old",Gain=1.125}}}
  local b=S.Acquire(old,"migration",3700)
  eq(b.Version,2);eq(S.NextReward(b),nil);eq(b.Rewards.old.Amount,123.456)
  eq(b.Pending[tostring(product)].Amount,123.456);eq(b.Receipts.previous.Gain,1.125)
  local op={Id="paid-op",Action="Receipt",ProductId=product,IntentId="intent",PurchaseId="old-paid"}
  local nextState,gain=S.Apply(b,op);near(gain,246.912-paid)
  local _,duplicate=S.Apply(nextState,op);eq(duplicate,0)
  local _,wrong,reason=S.Apply(b,{Id="wrong",Action="Receipt",ProductId=product,IntentId="different",PurchaseId="x"})
  eq(wrong,0);eq(reason,"UnmatchedReceipt")
  b=S.Checkpoint(nextState,"migration",4000,250.25,true)
  b=S.Acquire(b,"new",7600);near(b.Rewards.new.Amount,10.01);eq(b.Rewards.new.Seconds,3600)
  local unchanged=S.Acquire(b,"new",1000000);near(unchanged.Rewards.new.Amount,10.01)
 end
 -- Legacy online/stale heartbeat and zero Strength earn no offline reward.
 local a=S.Acquire(nil,"a",0)
 for _,closing in ipairs({false,true}) do
  local b=S.Acquire(S.Checkpoint(a,"a",100,0,closing),"b",100000)
  eq(S.NextReward(b),nil)
 end
 -- Fixed pack intent remains fractional across schema normalization/receipt.
 local product=C.Packs[1].ProductId
 local p={Version=1,Owner="a",Rewards={},Receipts={},GrantedTotal=0,
  Pending={[tostring(product)]={Id="legacy-pack",ProductId=product,Kind="Pack",Amount=12.345,State="Prompting"}}}
 local b,gain=S.Apply(p,{Id="receipt",Action="Receipt",ProductId=product,IntentId="legacy-pack",PurchaseId="p"})
 eq(gain,12.345);eq(b.Receipts.p.Gain,12.345)
 return {Checks=count,Migration="No legacy Rate reinterpretation; old paid quotes exact",Fractional=true}
end
