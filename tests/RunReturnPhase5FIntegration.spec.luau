-- Integration assertions for unmodified PlayerDataService copies, with only
-- their store handle/ranking sink redirected by the external Studio test runner.
return function(A,B,Store)
 local results={}
 local id="PROTEIN_COMMON_FIRE"
 local players={}
 local function newPlayer()
  local attrs={}
  return {Name="Phase5FFixture",UserId=1,
   SetAttribute=function(_,key,value) attrs[key]=value end,
   GetAttribute=function(_,key) return attrs[key] end,
   Destroy=function() end}
 end
 local function fixture()
  Store.Reset()
  local p=newPlayer() p.Name="Phase5FFixture"
  players[#players+1]=p
  assert(A.Load(p)) return p
 end
 local function context(tag)
  local c={Id=tag,RunId="run-"..tag,Permit=true,Alive=true}
  c.Validate=function()return c.Alive end return c
 end
 local function grant(Data,p,c,n) return Data.ChangeItemCounts(p,{[id]=n},{RunReturn=c}) end
 local function count() return Store.Data.OwnedItems[id] or 0 end
 local function test(name,fn)
  local ok,err=pcall(fn) results[#results+1]={name=name,passed=ok,error=not ok and tostring(err) or nil}
 end
 test("PDS 1 and 5; ordinary Save retains latest journal/count/equipment",function()
  local p=fixture() local t=context("T") assert(grant(A,p,t,1))
  assert(count()==11)
  local u=context("U") assert(grant(A,p,u,5)) assert(count()==16)
  A.Get(p).Data.OwnedItems[id]=0 -- intentionally stale autosave quantity
  A.Get(p).Dirty=true assert(A.Save(p))
  assert(count()==16 and Store.Data.RunReturnJournal.TransactionId=="U")
  assert(Store.Data.EquippedItems.Protein=="" and Store.Meta.Keep=="unchanged")
 end)
 test("PDS T Granted / old cancel / U retry stays 16",function()
  local p=fixture() local t=context("T")
  Store.FailAfter=Store.Requests+2 assert(not grant(A,p,t,5)) assert(count()==15)
  assert(B.Load(p))
  local u=context("U") Store.FailAfter=Store.Requests+2
  assert(not grant(B,p,u,1)) assert(count()==16)
  local metadataBefore=Store.Meta.RunReturnId
  t.Alive=false assert(not A.ResolveItemMutation(p))
  assert(count()==16 and Store.Meta.RunReturnId==metadataBefore)
  assert(B.ResolveItemMutation(p)) assert(count()==16)
  assert(Store.Data.RunReturnJournal.State=="Granted")
 end)
 test("PDS Pending crash Recovery cancels; U produces 11",function()
  local p=fixture() local t=context("T") Store.FailAfter=Store.Requests+1
  assert(not grant(A,p,t,5)) assert(count()==10)
  assert(B.Load(p))
  assert(Store.Data.RunReturnJournal.State=="Cancelled" and B.Get(p).Data.OwnedItems[id]==10)
  assert(grant(B,p,context("U"),1)) assert(count()==11)
  t.Alive=false assert(not A.ResolveItemMutation(p))
  assert(count()==11 and Store.Data.RunReturnJournal.TransactionId=="U")
 end)
 test("PDS no grant after Pending save fails; retry works",function()
  local p=fixture() local t=context("T") Store.FailBefore=Store.Requests+1
  assert(not grant(A,p,t,5)) assert(count()==10 and not Store.Data.RunReturnJournal)
  assert(A.ResolveItemMutation(p)) assert(count()==15)
 end)
 test("PDS AutoSave / BindToClose-equivalent cannot grant Pending",function()
  local p=fixture() local t=context("T") Store.FailBefore=Store.Requests+2
  assert(not grant(A,p,t,5)) t.Permit=false
  for _=1,3 do assert(not A.Save(p)) end
  assert(count()==10 and Store.Data.RunReturnJournal.State=="Pending")
  A.Release(p) assert(B.Load(p))
  assert(count()==10 and Store.Data.RunReturnJournal.State=="Cancelled")
 end)
 test("PDS PlayerRemoving-equivalent Pending cancellation",function()
  local p=fixture() local t=context("T") Store.FailAfter=Store.Requests+1
  assert(not grant(A,p,t,5)) t.Alive=false t.Permit=false
  A.ResolveItemMutation(p) A.Save(p) A.Release(p)
  assert(B.Load(p)) assert(count()==10 and Store.Data.RunReturnJournal.State=="Cancelled")
 end)
 test("PDS PlayerRemoving-equivalent Granted response loss preserves items",function()
  local p=fixture() local t=context("T") Store.FailAfter=Store.Requests+2
  assert(not grant(A,p,t,5)) t.Alive=false t.Permit=false
  assert(A.ResolveItemMutation(p)) A.Save(p) A.Release(p)
  assert(B.Load(p)) assert(count()==15 and Store.Data.RunReturnJournal.State=="Granted")
 end)
 test("PDS old normal item mutation, Save and Reset rejected after handoff",function()
  local p=fixture() assert(B.Load(p))
  A.Get(p).Dirty=true
  assert(not A.Save(p)) assert(count()==10)
  assert(not A.ChangeItemCount(p,id,1))
  assert(not A.Reset(p))
  assert(count()==10 and Store.Data.SessionOwnerToken==B.Get(p).OwnerToken)
 end)
 test("PDS normal current-owner Reset clears journal without losing owner",function()
  local p=fixture() assert(grant(A,p,context("T"),1))
  local token=A.Get(p).OwnerToken
  assert(A.Reset(p)) assert(Store.Data.SessionOwnerToken==token and not Store.Data.RunReturnJournal)
  assert(A.ChangeItemCount(p,id,1)) assert(count()==1)
 end)
 test("PDS same callback replay / failure retry remains idempotent",function()
  local p=fixture() Store.Repeat=true local t=context("T")
  Store.FailAfter=Store.Requests+2 assert(not grant(A,p,t,5))
  for _=1,4 do A.ResolveItemMutation(p) end
  assert(count()==15)
 end)
 test("PDS ownership response failure cannot reclaim after B Load",function()
  Store.Reset()
  local p=newPlayer() p.Name="Phase5FFixture" players[#players+1]=p
  Store.FailAfter=1 assert(not A.Load(p))
  assert(B.Load(p))
  assert(not A.Load(p)) assert(Store.Data.SessionOwnerToken==B.Get(p).OwnerToken)
 end)
 test("PDS first-ever Join initializes owner before normal Return",function()
  Store.Reset() Store.Data=nil
  local p=newPlayer() players[#players+1]=p
  assert(A.Load(p)) assert(Store.Data.SessionOwnerToken==A.Get(p).OwnerToken)
  assert(grant(A,p,context("First"),1)) assert(count()==1)
 end)
 test("PDS legacy boolean ownership and 5D marker migrate without loss",function()
  Store.Reset() Store.Data.OwnedItems[id]=true
  Store.Meta.RunReturnId="legacy" Store.Meta.RunReturnState="Granted"
  local p=newPlayer() players[#players+1]=p
  assert(A.Load(p)) assert(count()==1 and not Store.Data.RunReturnJournal)
  assert(Store.Meta.RunReturnId=="legacy")
  assert(grant(A,p,context("New"),1)) assert(count()==2)
 end)
 test("PDS malformed journal fails Load without overwriting saved data",function()
  Store.Reset() Store.Data.RunReturnJournal={invalid=true}
  local p=newPlayer() players[#players+1]=p
  assert(not A.Load(p))
  assert(count()==10 and Store.Writes==0 and not Store.Data.SessionOwnerToken)
 end)
 for _,p in players do A.Release(p) B.Release(p) p:Destroy() end
 local passed=0 for _,r in results do if r.passed then passed+=1 end end
 return {total=#results,passed=passed,results=results}
end
