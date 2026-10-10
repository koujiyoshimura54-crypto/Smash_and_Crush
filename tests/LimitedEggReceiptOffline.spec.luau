-- Integrated production receipt/PlayerData tests: memory only, no Roblox APIs.
do
 local function record(id,name)
  local entry=LimitedEgg.ByName[name or "Pet_042"]
  return {PlayerId=player.UserId,ProductId=LimitedEgg.ProductId,Kind="LimitedEgg",TableVersion=1,
   Result={id=guid(id),pet=entry.Name,percent=entry.Percent},Status="Reserved"}
 end
 local function countOwned() local n=0;for _ in pairs(durable.Pets.Owned) do n+=1 end;return n end
 local function grant(id,rec) return PlayerDataService.GrantLimitedEgg(player,id,rec) end
 s=reset(700)
 local r1=record(8101)
 equal(grant("paid-1",r1),true,"atomic paid grant")
 equal(countOwned(),1);equal(durable.LimitedEggReceipts["paid-1"].Result.id,guid(8101))
 equal(durable.Pets.Equipped[1],"","no auto-equip");equal(durable.Win,700);equal(durable.Pets.Revision,1)
 equal(durable.Pets.LastRequestId,"","paid receipt does not replace Win receipt")
 equal(grant("paid-1",r1),true);equal(countOwned(),1);equal(writes,1,"local durable marker replay")
 equal(grant("paid-2",record(8102)),true);equal(countOwned(),2,"same species are separate copies")
 equal(PlayerDataService.MutatePets(player,guid(8110),2,"Equip",guid(8102)),true)
 equal(grant("paid-1",r1),true,"older receipt survives equipment revision");equal(countOwned(),2)
 equal(durable.Pets.Equipped[1],guid(8102));equal(durable.Win,700)
 local bad=copy(r1);bad.Result=record(8199).Result
 equal(grant("paid-1",bad),false,"mismatched replay denied")
 bad=copy(r1);bad.TableVersion=9;equal(grant("bad-version",bad),false)
 equal(normalizeLimitedReceipts("bad"),nil);equal(normalizeLimitedReceipts({x={}}),nil)
 equal(next(assert(normalizeLimitedReceipts(nil))),nil,"legacy default")
 local restored=assert(normalizeLimitedReceipts(copy(durable.LimitedEggReceipts)))
 equal(restored["paid-1"].Result.id,guid(8101),"markers normalize after rejoin")
 for _,failure in ipairs({"before","after"}) do
  s=reset(700);mode=failure
  equal(grant("uncertain",r1),false);equal(s.PendingItemMutation.Record.Result.id,guid(8101))
  equal(attrs.PetSavePending,true);equal(grant("uncertain",bad),false,"changed pending payload rejected")
  mode=nil;equal(grant("uncertain",r1),true,"same operation recovers")
  equal(countOwned(),1);equal(durable.Pets.Revision,1);equal(durable.Win,700)
  equal(attrs.PetSavePending,false)
 end
 s=reset();s.Saving=true;equal(grant("busy",r1),false);equal(writes,0)
 s.Saving=false;s.PendingItemMutation={Other=true};equal(grant("busy",r1),false);equal(writes,0)
 s=reset();s.OwnershipLost=true;equal(grant("lost-owner",r1),false);equal(writes,0)
 s=reset();s.StudioStartOverride={};equal(grant("override",r1),false);equal(writes,0)
 s=reset();durable.LimitedEggReceipts={corrupt={}};equal(grant("corrupt",r1),false);equal(writes,0)

 local clock,now=1000,2000
 local journalEntries={};local journalFailure;local journalWrites=0
 local journal={}
 function journal:UpdateAsync(id,transform)
  local old=copy(journalEntries[id])
  local value=transform(copy(old));local repeated=transform(copy(old))
  if value and repeated and value.Result then equal(value.Result.id,repeated.Result.id,"journal callback retry keeps copy ID") end
  local transition=value and (value.Presented and "ack" or value.Status=="Granted" and (not old or old.Status~="Granted") and "final" or value.Status=="Reserved" and not old and "reserve")
  if transition and journalFailure==transition.."Before" then error("offline journal before commit") end
  if value then journalEntries[id]=copy(value);journalWrites+=1 end
  if transition and journalFailure==transition.."After" then error("offline journal lost response") end
  return copy(value)
 end
 local signal=function()
  local callbacks={}
  return {Callbacks=callbacks,Connect=function(_,f)table.insert(callbacks,f);return {Disconnect=function()end}end}
 end
 local finishSignal=signal();local removeSignal=signal()
 local promptCalls,noticeCalls,rolls,storeNames=0,0,0,{}
 local priceError,policyError,restricted,price,forSale,promptError,notifyError=false,false,false,149,true,false,false
 local malformedPolicy,withoutUniverse,wrongUniverse,listed=false,false,false,true
 local policyHook
 local Market={PromptProductPurchaseFinished=finishSignal}
 function Market:GetProductInfoAsync(id,kind)
  if priceError then error("offline price API") end
  return {ProductId=id,PriceInRobux=price,IsForSale=forSale,UniverseId=not withoutUniverse and (wrongUniverse and 1 or LimitedEgg.UniverseId) or nil}
 end
 function Market:GetDeveloperProductsAsync()
  return {IsFinished=true,GetCurrentPage=function()return listed and {{ProductId=LimitedEgg.ProductId}} or {}end}
 end
 function Market:PromptProductPurchase(p,id)
  equal(p,player);equal(id,LimitedEgg.ProductId)
  if promptError then error("offline prompt API") end
  promptCalls+=1
 end
 local policyService={GetPolicyInfoForPlayerAsync=function()
  if policyHook then local f=policyHook;policyHook=nil;f() end
  if policyError then error("offline Policy API") end
  return malformedPolicy and {} or {ArePaidRandomItemsRestricted=restricted}
 end}
 local HatchClient={};local Limited=LimitedEgg;local shownLimited={}
 local reveals=0;local presentationError=false
 local function playVerified(results,egg)
  if presentationError then return false end
  equal(egg,nil,"real saved notification selects existing RGBEgg fallback")
  equal(#results,1);reveals+=1;return true
 end
 local function clear()end
 local MenuClient={shroud=function()end}
 -- INSERT NOTICE GATE
 local commits={IsA=function(_,k)return k=="RemoteEvent"end,FireClient=function(_,p,notice)
  if notifyError then error("offline notification failed") end
  equal(notice.Saved,true);equal(notice.Status,"Granted");equal(notice.State.Owned[notice.Result.id],notice.Result.pet)
  noticeCalls+=1
  HatchClient.playCommittedLimited(notice)
 end}
 local rpc={IsA=function(_,k)return k=="RemoteFunction"end}
 RS.Remotes={GameRemotes={FindFirstChild=function(_,name)
  return name=="LimitedEggPurchase" and rpc or name=="LimitedEggCommitted" and commits
 end}}
 RS.Config.StageSkipConfig="StageSkip"
 modules.StageSkip={StageForProduct=function(id)return id==22 and 2 end}
 local itemGrants,skipGrants,winRoutes=0,0,0
 modules.ItemPurchases={RarityForProduct=function(id)return id==21 and "Epic"end,
  GetPending=function()return {PlayerId=101,ExpectedProductId=21,ItemId="old-item",IntentId="old-intent",Sequence=1}end,
  ValidateItem=function()return true end,ClaimPending=function()return true end,
  Grant=function()itemGrants+=1;return true end,Complete=function()return true end}
 modules.Skip={TryLock=function()return true end,GetStartCFrame=function()return {}end,
  ApplyLocked=function()skipGrants+=1;return true end,NotifyReceipt=function()end,Unlock=function()end}
 modules.ShopReward={ProcessWinReceipt=function(r)if r.ProductId==20 then winRoutes+=1;return "Granted"end end}
 modules.PlayerDataService=PlayerDataService
 game.ServerScriptService={Services={StageSkipService="Skip",PlayerDataService="PlayerDataService",ShopRewardService="ShopReward"},Systems={Purchases={ItemPurchaseService="ItemPurchases"}}}
 game.GameId=LimitedEgg.UniverseId;game.JobId="offline-A"
 Players.PlayerRemoving=removeSignal
 function Players:GetPlayerByUserId(id)return id==player.UserId and player.Parent==Players and player or nil end
 local function position(x)return setmetatable({X=x},{__sub=function(a,b)return {Magnitude=math.abs(a.X-b.X)}end})end
 local fakeRoot={Position=position(0)}
 player.Character={FindFirstChild=function()return fakeRoot end,FindFirstChildOfClass=function()return {Health=100}end}
 local workspace={FindFirstChild=function()return {PrimaryPart={Position=position(0)}}end}
 local studio=false
 local queued={}
 local advanceTime=false
 local task={spawn=function(f,...)table.insert(queued,{f=f,args={...}})end,wait=function(seconds)if advanceTime then now+=seconds or 0 end end}
 local Enum={ProductPurchaseDecision={PurchaseGranted="Granted",NotProcessedYet="Pending"},InfoType={Product="Product"}}
 local nextRoll=1
 local Random={new=function()return {NextInteger=function()rolls+=1;return nextRoll end}end}
 local baseGetService=game.GetService
 function game:GetService(name)
  if name=="RunService" then return {IsStudio=function()return studio end}end
  if name=="DataStoreService" then return {GetDataStore=function(_,storeName)table.insert(storeNames,storeName);return journal end}end
  if name=="MarketplaceService" then return Market end
  if name=="PolicyService" then return policyService end
  return baseGetService(self,name)
 end
 -- INSERT RECEIPT MODULE
 local baseLoader=newReceipts
 newReceipts=function()
  local fn=assert(loadstring(receiptSource))
  setfenv(fn,setmetatable({game=game,require=require,workspace=workspace,Enum=Enum,Random=Random,task=task,
   os={time=function()return now end,clock=function()return clock end},warn=function()end},{__index=getfenv()}))
  return fn()
 end
 local receipts=newReceipts();receipts.InitializeLimited();receipts.InitializeLimited()
 equal(#finishSignal.Callbacks,1,"one finish unlock connection")
 local function request(action,value)clock+=1;return receipts.LimitedRequest(player,action,value)end
 request("Ready")
 s=reset(700)
 -- Real models are mocked by exact registered names; existing lookup remains tested above.
 Pet.model=function(name)return LimitedEgg.ByName[name] and {} or nil end
 equal(request("Offer").ok,true,"eligible priced offer")
 restricted=true;equal(request("Offer").reason,"PaidRandomRestricted");equal(request("Purchase",1).ok,false);restricted=false
 policyError=true;equal(request("Offer").reason,"PolicyUnavailable");policyError=false
 malformedPolicy=true;equal(request("Offer").reason,"PolicyUnavailable");malformedPolicy=false
 priceError=true;equal(request("Offer").reason,"PriceUnavailable");priceError=false
 forSale=false;equal(request("Purchase",1).ok,false);forSale=true
 price=0;equal(request("Offer").ok,false);price=0/0;equal(request("Offer").ok,false);price=149
 game.GameId=1;equal(request("Offer").reason,"WrongExperience");game.GameId=LimitedEgg.UniverseId
 wrongUniverse=true;equal(request("Offer").reason,"WrongExperience");wrongUniverse=false
 withoutUniverse=true;equal(request("Offer").ok,true,"experience product enumeration fallback")
 listed=false;equal(request("Offer").reason,"ProductAssociationUnavailable");listed=true;withoutUniverse=false
 equal(request("Purchase",9).reason,"OfferChanged","displayed pool version required")
 promptError=true;equal(request("Purchase",1).reason,"PromptFailed");promptError=false
 equal(request("Purchase",1).ok,true,"error releases server prompt lock")
 equal(request("Purchase",1).reason,"PurchaseBusy");equal(promptCalls,1)
 for _,f in finishSignal.Callbacks do f(101,LimitedEgg.ProductId,false)end
 equal(countOwned(),0,"cancel never grants")
 equal(request("Purchase",1).ok,true,"cancel releases lock")
 for _,f in finishSignal.Callbacks do f(101,LimitedEgg.ProductId,true)end
 equal(countOwned(),0,"purchase finished never grants")
 policyHook=function()equal(receipts.LimitedRequest(player,"Purchase",1).reason,"PleaseWait","parallel prompt request rejected")end
 equal(request("Purchase",1).ok,true);equal(promptCalls,3)
 for _,f in finishSignal.Callbacks do f(101,LimitedEgg.ProductId,false)end
 local function paid(id)return {PlayerId=101,ProductId=LimitedEgg.ProductId,PurchaseId=id}end
 restricted=true;priceError=true
 equal(receipts.ProcessReceipt(paid("receipt-1")),"Granted","already paid fulfills despite policy/API outage")
 equal(countOwned(),1);equal(rolls,1);equal(noticeCalls,1)
 equal(reveals,1,"production notification contract accepted by Phase 4")
 local first=copy(journalEntries["receipt-1"])
 equal(first.Result.pet,"Pet_042");equal(first.TableVersion,1);equal(first.Status,"Granted")
 equal(durable.Pets.Equipped[1],"");equal(durable.Win,700)
 equal(receipts.ProcessReceipt(paid("receipt-1")),"Granted");equal(countOwned(),1);equal(rolls,1,"replay never rolls again")
 equal(reveals,1,"repeated real notification never reveals twice")
 equal(request("Acknowledge","receipt-1").ok,true);equal(journalEntries["receipt-1"].Presented,true)
 local notices=noticeCalls;equal(receipts.ProcessReceipt(paid("receipt-1")),"Granted");equal(noticeCalls,notices,"durable visual acknowledgement")
 restricted=false;priceError=false
 -- Each uncertain point reuses the first durable result/copy; callbacks repeat.
 for _,failure in ipairs({"reserveAfter","finalBefore","finalAfter"}) do
  s=reset(700);journalFailure=failure
  local id="journal-"..failure
  equal(receipts.ProcessReceipt(paid(id)),"Pending",failure)
  local reserved=copy(journalEntries[id]);local beforeRolls=rolls
  journalFailure=nil
  equal(receipts.ProcessReceipt(paid(id)),"Granted","retry "..failure)
  equal(journalEntries[id].Result.id,reserved.Result.id);equal(rolls,beforeRolls,"durable roll reused")
  equal(countOwned(),1);equal(durable.Pets.Revision,1);equal(durable.Win,700)
 end
 for _,failure in ipairs({"before","after"}) do
  s=reset(700);mode=failure
  local id="player-"..failure
  equal(receipts.ProcessReceipt(paid(id)),"Pending")
  local reserved=copy(journalEntries[id]);local beforeRolls=rolls;mode=nil
  equal(receipts.ProcessReceipt(paid(id)),"Granted")
  equal(journalEntries[id].Result.id,reserved.Result.id);equal(rolls,beforeRolls);equal(countOwned(),1);equal(durable.Pets.Revision,1)
 end
 -- Two server owners share the real journal schema and exact fenced grant path.
 s=reset(700);game.JobId="offline-B";local secondServer=newReceipts()
 hook=function()equal(secondServer.ProcessReceipt(paid("parallel")),"Pending","other owner held by lease")end
 equal(receipts.ProcessReceipt(paid("parallel")),"Granted")
 equal(secondServer.ProcessReceipt(paid("parallel")),"Granted");equal(countOwned(),1)
 s=reset(700);mode="before"
 equal(receipts.ProcessReceipt(paid("takeover")),"Pending")
 local original=copy(journalEntries.takeover);journalEntries.takeover.LeaseUntil=now-1
 mode=nil;sessions[player]={Loaded=true,Data=copy(durable)};s=sessions[player]
 equal(secondServer.ProcessReceipt(paid("takeover")),"Granted","expired lease/rejoin takeover")
 equal(journalEntries.takeover.Result.id,original.Result.id);equal(countOwned(),1)
 -- Notification failure has no effect on the persisted award/receipt decision.
 s=reset(700);notifyError=true
 equal(receipts.ProcessReceipt(paid("notify-failed")),"Granted");equal(countOwned(),1)
 equal(journalEntries["notify-failed"].Status,"Granted");notifyError=false
 notices=noticeCalls;equal(receipts.ProcessReceipt(paid("notify-failed")),"Granted");equal(noticeCalls,notices+1)
 s=reset(700);presentationError=true
 local previousReveals=reveals
 equal(receipts.ProcessReceipt(paid("presentation-failed")),"Granted");equal(countOwned(),1);equal(reveals,previousReveals)
 presentationError=false;equal(receipts.ProcessReceipt(paid("presentation-failed")),"Granted")
 equal(reveals,previousReveals+1,"Phase 4 setup failure releases only its visual claim")
 equal(countOwned(),1,"visual retry cannot grant another copy")
 -- Ownership failure cannot write or acknowledge; later fenced session retries.
 s=reset(700);s.OwnershipLost=true
 equal(receipts.ProcessReceipt(paid("ownership")),"Pending");equal(countOwned(),0)
 s.OwnershipLost=false;equal(receipts.ProcessReceipt(paid("ownership")),"Granted");equal(countOwned(),1)
 studio=true;equal(receipts.ProcessReceipt(paid("studio")),"Pending");equal(journalEntries.studio,nil);studio=false
 local malformed=paid("bad");malformed.PlayerId=0/0;equal(receipts.ProcessReceipt(malformed),"Pending")
 malformed=paid("bad");malformed.PurchaseId="";equal(receipts.ProcessReceipt(malformed),"Pending")
 local collision=paid("receipt-1");collision.PlayerId=102;equal(receipts.ProcessReceipt(collision),"Pending")
 -- Existing products still route through their original unchanged handlers.
 equal(receipts.ProcessReceipt({ProductId=20,PlayerId=101,PurchaseId="old-win"}),"Granted");equal(winRoutes,1)
 equal(receipts.ProcessReceipt({ProductId=21,PlayerId=101,PurchaseId="old-item"}),"Granted");equal(itemGrants,1)
 equal(receipts.ProcessReceipt({ProductId=22,PlayerId=101,PurchaseId="old-stage"}),"Granted");equal(skipGrants,1)
 for _,name in storeNames do equal(name,"DeveloperProductReceipts_v1","existing shared journal only")end
 equal(receipts.ProcessReceipt({ProductId=999,PlayerId=101,PurchaseId="unknown"}),"Pending")
 -- The exact server draw covers all 200 equally likely tickets (half-percent units).
 s=reset(700)
 local counts={}
 for ticket=1,200 do
  nextRoll=ticket
  local id="pool-ticket-"..ticket
  equal(receipts.ProcessReceipt(paid(id)),"Granted")
  local result=journalEntries[id].Result
  counts[result.pet]=(counts[result.pet] or 0)+1
 end
 for _,entry in ipairs(LimitedEgg.Entries) do equal(counts[entry.Name],entry.Percent*2,"exact half-percent weights")end
 equal(countOwned(),200);equal(durable.Win,700);equal(durable.Pets.Equipped[1],"")
 nextRoll=1
 -- Internal retry runs only an official receipt already accepted by the callback.
 s=reset(700);mode="before"
 equal(receipts.ProcessReceipt(paid("background-retry")),"Pending")
 local retry=queued[#queued];mode=nil;retry.f(table.unpack(retry.args))
 equal(journalEntries["background-retry"].Status,"Granted");equal(countOwned(),1)
 equal(receipts.ProcessReceipt(paid("background-retry")),"Granted");equal(countOwned(),1)
 -- Recovery worker remains active long enough to outlive a crashed owner's lease.
 s=reset(700);mode="before"
 equal(receipts.ProcessReceipt(paid("crashed-owner")),"Pending")
 local crashedResult=copy(journalEntries["crashed-owner"].Result)
 mode=nil;sessions[player]={Loaded=true,Data=copy(durable)};s=sessions[player]
 equal(secondServer.ProcessReceipt(paid("crashed-owner")),"Pending")
 local takeoverRetry=queued[#queued];advanceTime=true
 takeoverRetry.f(table.unpack(takeoverRetry.args));advanceTime=false
 equal(journalEntries["crashed-owner"].Status,"Granted");equal(countOwned(),1)
 equal(journalEntries["crashed-owner"].Result.id,crashedResult.id,"crashed owner's draw survives lease recovery")
 -- Execute the existing production ownership fence during a session takeover.
 do
  local Fence={}
  -- INSERT OWNERSHIP UPDATE
  local oldUpdate=ownedUpdate
  local switchOwner=false
  local fencedStore={UpdateAsync=function(_,key,transform)
   if switchOwner then durable.SessionOwnerToken="owner-B";switchOwner=false end
   local value=transform(copy(durable),nil)
   if value then durable=copy(value)end
   return value,nil
  end}
  ownedUpdate=function(p,session,transform)
   return Fence.Update(fencedStore,"Player_101",session,transform,function()return sessions[p]==session and not session.OwnershipLost end)
  end
  s=reset(700);s.OwnerToken="owner-A";durable.SessionOwnerToken="owner-A"
  switchOwner=true
  equal(grant("fenced",r1),false);equal(s.OwnershipLost,true);equal(countOwned(),0,"old session cannot grant after takeover")
  sessions[player]={Loaded=true,OwnerToken="owner-B",Data=copy(durable)};s=sessions[player]
  equal(grant("fenced",r1),true);equal(countOwned(),1);equal(durable.LimitedEggReceipts.fenced.Result.id,r1.Result.id)
  ownedUpdate=oldUpdate
 end
 -- Exact client prompt guard and completion unlock, with an in-memory RPC spy.
 do
  local M={};local active={};local Config=LimitedEgg;local started=true
  local Marketplace={PromptProductPurchaseFinished=signal()}
  local lifetime={Add=function()end}
  local oldLocal=Players.LocalPlayer;Players.LocalPlayer=player
  -- INSERT PURCHASE CLIENT
  -- INSERT CLIENT FINISH
  local calls=0;local rpcFailure=true;local deny
  requestRemote={InvokeServer=function(_,action,version)
   calls+=1;equal(action,"Purchase");equal(version,1)
   if rpcFailure then error("offline RPC failed") end
   if deny then return {ok=false,reason=deny}end
   return {ok=true}
  end}
  buyControl={};availability={}
  equal(M.purchase(),false,"no fetched offer, no purchase");equal(calls,0)
  priceReady=true;offeredVersion=1
  equal(M.purchase(),false);equal(purchaseBusy,false,"RPC error releases client lock")
  rpcFailure=false;equal(M.purchase(),true);equal(purchaseBusy,true)
  equal(M.purchase(),false,"repeat click blocked");equal(calls,2)
  for _,f in Marketplace.PromptProductPurchaseFinished.Callbacks do f(101,Config.ProductId,false)end
  equal(purchaseBusy,false);equal(buyControl.Active,true,"cancel allows re-operation")
  equal(M.purchase(),true)
  for _,f in Marketplace.PromptProductPurchaseFinished.Callbacks do f(101,Config.ProductId,true)end
  equal(purchaseBusy,false,"success event only unlocks")
  deny="PaidRandomRestricted";equal(M.purchase(),false);equal(priceReady,false);equal(buyControl.Active,false)
  Players.LocalPlayer=oldLocal
 end
 print("LIMITED_EGG_RECEIPT_OFFLINE_PASS")
end
