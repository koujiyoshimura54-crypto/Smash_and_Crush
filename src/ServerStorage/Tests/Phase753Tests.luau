-- Phase 7.4.1: isolated production-source tests; no Robux or live stores used.
local T={}
function T.Run()
 local folder=Instance.new("Folder"); folder.Name="Phase741Sandbox"; folder.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript"); m.Name=name; m.Source=source; m.Parent=folder; return m end
 local function replace(s,a,b) local i,j=s:find(a,1,true); assert(i,"Missing seam: "..a); return s:sub(1,i-1)..b..s:sub(j+1) end
 local ok,err=pcall(function()
  local runtime=module("Runtime",[==[
local R={Stores={},Metadata={},UserIds={},Prompts={},PlayersList={},Sequence=0,StageApplications=0}
local H=game:GetService("HttpService")
function R.Copy(v) if v==nil then return nil end return H:JSONDecode(H:JSONEncode(v)) end
function R.Signal()
 local s={Listeners={}}
 function s:Connect(fn) table.insert(self.Listeners,fn) end
 function s:Fire(...) for _,fn in ipairs(self.Listeners) do fn(...) end end
 return s
end
R.Players={PlayerRemoving=R.Signal()}
function R.Players:GetPlayerByUserId(id) return R.PlayersList[id] end
R.Marketplace={PromptProductPurchaseFinished=R.Signal()}
function R.Marketplace:PromptProductPurchase(player,product)
 if R.PromptFailure then error("simulated prompt failure") end
 local intent=R.Stores.ItemPurchaseIntents_v1["Player_"..player.UserId]
 assert(intent and intent.ItemId and intent.ExpectedProductId==product,"Prompt before durable intent")
 table.insert(R.Prompts,{Player=player,ProductId=product,ItemId=intent.ItemId})
end
R.RunService={IsStudio=function() return false end}
R.Http={GenerateGUID=function() R.Sequence+=1; return "guid-"..R.Sequence end}
R.DSS={}
function R.DSS:GetDataStore(name)
 R.Stores[name]=R.Stores[name] or {}
 R.Metadata[name]=R.Metadata[name] or {}
 R.UserIds[name]=R.UserIds[name] or {}
 local records=R.Stores[name]
 local function info(key)
  return {GetMetadata=function() return R.Copy(R.Metadata[name][key] or {}) end,
   GetUserIds=function() return R.Copy(R.UserIds[name][key] or {}) end}
 end
 return {
  GetAsync=function(_,key) return R.Copy(records[key]),info(key) end,
  UpdateAsync=function(_,key,fn)
   if R.BeforeUpdate then R.BeforeUpdate(name,key) end
   if R.FailRead==name then error("simulated read failure") end
   fn(R.Copy(records[key]),info(key)) -- retry the callback against unchanged input
   local nextValue,users,meta=fn(R.Copy(records[key]),info(key))
   if R.FailWrite and R.FailWrite(name,key,nextValue) then error("simulated write failure") end
   if nextValue==nil then return nil end -- match the engine's cancelled-update contract
   records[key]=R.Copy(nextValue)
   R.Metadata[name][key]=R.Copy(meta or {})
   R.UserIds[name][key]=R.Copy(users or {})
   if R.FailAfterWrite and R.FailAfterWrite(name,key,nextValue) then error("simulated lost acknowledgement") end
   return R.Copy(records[key]),info(key)
  end,
 }
end
function R.DSS:GetOrderedDataStore() return {SetAsync=function() end} end
return R
]==])
  local R=require(runtime)
  local shim='local realTypeof=typeof\nlocal function typeof(v) if type(v)=="table" and v.TestPlayer then return "Instance" end return realTypeof(v) end\n'
  local function dependencies(source)
   for service,field in pairs({Players="Players",MarketplaceService="Marketplace",RunService="RunService",HttpService="Http",DataStoreService="DSS"}) do
    local before='game:GetService("'..service..'")'
    if source:find(before,1,true) then source=replace(source,before,'require(script.Parent.Runtime).'..field) end
   end
   return shim..source
  end
  module("PlayerDataService",dependencies(game.ServerScriptService.Services.PlayerDataService.Source))
  module("ItemService",dependencies(game.ServerScriptService.Services.ItemService.Source))
  module("ItemPurchaseService",dependencies(game.ServerScriptService.Systems.Purchases.ItemPurchaseService.Source))
  module("StageSkipService",[==[
local R=require(script.Parent.Runtime)
local S={}
local locks={}
function S.TryLock(p) if locks[p] then return false end locks[p]=true return true end
function S.Unlock(p) locks[p]=nil end
function S.GetStartCFrame(p,stage) return p.Ready~=false and CFrame.new() or nil end
function S.ApplyLocked(p,stage)
 if p.Ready==false then return false end
 R.StageApplications+=1; p.LastStage=stage; return true
end
function S.NotifyReceipt(p,stage) p.NotifiedStage=stage end
return S
]==])
  local receiptSource=dependencies(game.ServerScriptService.Systems.Purchases.ReceiptService.Source)
  module("ReceiptService",receiptSource)
  local Data=require(folder.PlayerDataService)
  local Items=require(folder.ItemService)
  local Purchases=require(folder.ItemPurchaseService)
  local Receipts=require(folder.ReceiptService)
  local Master=require(game.ReplicatedStorage.Config.ItemMaster)
  local granted=Enum.ProductPurchaseDecision.PurchaseGranted
  local pending=Enum.ProductPurchaseDecision.NotProcessedYet
  local nextUser=734000
  local function player(raw)
   nextUser+=1
   local p={TestPlayer=true,UserId=nextUser,Name="Test734",Parent=R.Players,Attributes={}}
   function p:IsA(name) return name=="Player" end
   function p:GetAttribute(name) return self.Attributes[name] end
   function p:SetAttribute(name,value) self.Attributes[name]=value end
   R.PlayersList[p.UserId]=p
   if raw then R.Stores.PlayerData_v1=R.Stores.PlayerData_v1 or {}; R.Stores.PlayerData_v1["Player_"..p.UserId]=R.Copy(raw) end
   assert(Data.Load(p))
   return p
  end
  local function receipt(p,product,suffix) return {PlayerId=p.UserId,ProductId=product,PurchaseId=tostring(p.UserId).."-"..suffix} end
  local function check(name,fn) fn(); table.insert(results,"PASS "..name) end
  local function assertOwned(p,id)
   assert((Data.Get(p).Data.OwnedItems[id] or 0)>=1,id)
   assert((R.Stores.PlayerData_v1["Player_"..p.UserId].OwnedItems[id] or 0)>=1,"not persisted")
  end

  R.Time=0;R.FlashCount=0;R.RunService.Heartbeat=R.Signal()
  R.Flash={FireAllClients=function(_,cf) assert(typeof(cf)=="CFrame");R.FlashCount+=1 end}
  R.Roll=0;R.Index=1;R.Rolls=0
  R.Random={NextNumber=function() R.Rolls+=1;return R.Roll end,NextInteger=function(_,a,b) assert(a==1 and b==9);return R.Index end}
  R.Boss={FindFirstChild=function(_,name) assert(name=="HumanoidRootPart");return {Position=Vector3.new(0,5,0),CFrame=CFrame.new(0,5,0)} end}
  R.World={FindFirstChild=function(_,name)
   if name=="Enemies" then return {FindFirstChild=function(_,id) assert(id:match("^Stage%d%d_Enemy$"));return R.Boss end} end
   if name=="GeneratedMap" then return workspace.GeneratedMap end
  end}
  local world=dependencies(game.ServerStorage.Legacy.Modules.BossWorldDropService.Source)
  world=replace(world,'game.ReplicatedStorage.Remotes:WaitForChild("BossDropFlash")','require(script.Parent.Runtime).Flash')
  world=replace(world,'folder.Parent=workspace','folder.Parent=script.Parent')
  world=world:gsub("os%.clock%(%)","require(script.Parent.Runtime).Time")
  world=replace(world,'task.spawn(M.TryPickup,r.Owner,part)','M.TryPickup(r.Owner,part)')
  local World=require(module("BossWorldDropService",world))
  local drop=dependencies(game.ServerStorage.Legacy.Modules.BossItemDropService.Source)
  drop=replace(drop,'local rng=Random.new()','local rng=require(script.Parent.Runtime).Random\nlocal workspace=require(script.Parent.Runtime).World')
  local Drops=require(module("BossItemDropService",drop))
  local function character(p,position)
   local root={Position=position}
   p.Character={FindFirstChild=function(_,name) return name=="HumanoidRootPart" and root end,
    FindFirstChildOfClass=function() return {Health=100} end}
   return root
  end
  local function tick() R.RunService.Heartbeat:Fire(.2) end
  local function pickup(p,part)
   local root=character(p,part.Position+Vector3.new(10,0,0))
   assert(not World.TryPickup(p,part));root.Position=part.Position;R.Time+=1
   return World.TryPickup(p,part)
  end
  local function clear(p) p.Parent=nil;tick() end
  local id="PROTEIN_COMMON_FIRE"
  check("All 10 bosses spawn world drops without inventory mutation; VFX once at appearance",function()
   local p=player();local before=R.FlashCount;local rolls=R.Rolls
   for stage=1,10 do local run={Defeated={[stage]=true}}
    assert(Drops.OnBossDefeated(p,stage,5,run))
    assert(not Drops.OnBossDefeated(p,stage,5,run))
   end
   assert(R.FlashCount==before+10 and R.Rolls==rolls+10)
   assert(Items.GetItemCount(p,id)==0)
   assert(#folder.BossItemDrops:GetChildren()==10)
   for _,part in folder.BossItemDrops:GetChildren() do
    assert(part:GetAttribute("ItemId")==id and part:GetAttribute("OwnerUserId")==p.UserId)
    assert(part.ImagePlate.FrontImage.Texture==Master.Get(id).Image and part.ImagePlate.BackImage.Texture==Master.Get(id).Image)
   end
   clear(p);assert(#folder.BossItemDrops:GetChildren()==0)
  end)
  check("Pickup adds one to new/existing count, removes world object and cannot repeat; no pickup VFX",function()
   for _,count in ipairs({0,3}) do
    local p=player({OwnedItems={[id]=count}})
    local part=assert(World.Spawn(p,id,CFrame.new()))
    local flash=R.FlashCount
    assert(Items.GetItemCount(p,id)==count)
    assert(pickup(p,part));assert(Items.GetItemCount(p,id)==count+1 and part.Parent==nil)
    assert(not World.TryPickup(p,part) and R.FlashCount==flash)
    assert(Data.Save(p));Data.Release(p);assert(Data.Load(p));assert(Items.GetItemCount(p,id)==count+1)
   end
  end)
  check("No instant spawn pickup, wrong owner and distant player rejected; later proximity scan picks up",function()
   local p=player();local q=player()
   local part=assert(World.Spawn(p,id,CFrame.new()))
   local root=character(p,part.Position)
   R.Time+=1;assert(not World.TryPickup(p,part))
   assert(not pickup(q,part));assert(Items.GetItemCount(q,id)==0)
   root.Position=Vector3.new(10,0,0);tick();root.Position=part.Position;tick()
   assert(Items.GetItemCount(p,id)==1 and not part.Parent)
  end)
  check("70% no spawn; normal .1-.4, skipped/unconfirmed and invalid stages cannot drop",function()
   local p=player();R.Roll=.3;local flash=R.FlashCount
   local ok,code=Drops.OnBossDefeated(p,1,5,{Defeated={[1]=true}})
   assert(ok and code=="NoDrop" and R.FlashCount==flash)
   local rolls=R.Rolls
   for stage=1,10 do for sub=1,4 do assert(not Drops.OnBossDefeated(p,stage,sub,{Defeated={[stage]=true}})) end end
   assert(not Drops.OnBossDefeated(p,3,5,{Defeated={},Skipped={[3]=true}}))
   assert(R.Rolls==rolls and Items.GetItemCount(p,id)==0)
   R.Roll=0
  end)
  check("All nine random choices preserve Common ItemId and Image",function()
   local seen={};local p=player()
   for index=1,9 do R.Index=index
    local ok,code,item=Drops.OnBossDefeated(p,1,5,{Defeated={[1]=true}})
    assert(ok and code=="WorldDropSpawned" and not seen[item]);seen[item]=true
    assert(Master.Get(item).Rarity=="Common")
   end
   assert(Items.GetItemCount(p,id)==0);clear(p);R.Index=1
  end)
  check("Failed/ambiguous save locks same drop; existing mutation retry adds once then deletes it",function()
   for _,lostAck in ipairs({false,true}) do
    local p=player();local part=assert(World.Spawn(p,id,CFrame.new()))
    if lostAck then R.FailAfterWrite=function(name) return name=="PlayerData_v1" end
    else R.FailWrite=function(name) return name=="PlayerData_v1" end end
    local ok,code=pickup(p,part)
    assert(not ok and code=="InventorySavePending" and part.Parent)
    assert(not World.TryPickup(p,part))
    R.FailAfterWrite=nil;R.FailWrite=nil
    assert(Data.Save(p));tick()
    assert(Items.GetItemCount(p,id)==1 and not part.Parent)
    assert(not World.TryPickup(p,part));assert(Items.GetItemCount(p,id)==1)
   end
  end)
  check("Busy existing save accepts no mutation; available drop can be picked up afterward",function()
   local p=player();local part=assert(World.Spawn(p,id,CFrame.new()))
   Data.Get(p).Saving=true
   assert(not pickup(p,part));assert(part.Parent and Items.GetItemCount(p,id)==0)
   Data.Get(p).Saving=false
   assert(World.TryPickup(p,part));assert(Items.GetItemCount(p,id)==1 and not part.Parent)
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T