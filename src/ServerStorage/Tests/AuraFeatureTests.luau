-- Isolated production-source regression tests. No real players or DataStores.
local T={}
function T.Run()
 local folder=Instance.new("Folder") folder.Name="AuraFeatureTestSandbox" folder.Parent=game.ServerStorage
 local results={}
 local function module(name,source) local m=Instance.new("ModuleScript") m.Name=name m.Source=source m.Parent=folder return m end
 local function replaceAll(source,before,after)
  local output={} local start=1
  while true do local a,b=source:find(before,start,true) if not a then table.insert(output,source:sub(start)) break end
   table.insert(output,source:sub(start,a-1)) table.insert(output,after) start=b+1
  end return table.concat(output)
 end
 local ok,err=xpcall(function()
  local runtimeModule=module("Runtime",[==[
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
  local R=require(runtimeModule)
  function R.Players:GetPlayers() local t={} for _,p in pairs(R.PlayersList) do table.insert(t,p) end return t end
  local shim='local originalTypeof=typeof\nlocal function typeof(v) if type(v)=="table" and v.TestPlayer then return "Instance" end return originalTypeof(v) end\n'
  local function dependencies(source)
   for service,field in pairs({Players="Players",DataStoreService="DSS",RunService="RunService",HttpService="Http",MarketplaceService="Marketplace"}) do
    source=replaceAll(source,'game:GetService("'..service..'")','require(script.Parent.Runtime).'..field)
   end
   return shim..source
  end
  module("AuraConfig",game.ReplicatedStorage.Config.AuraConfig.Source)
  module("PlayerDataService",replaceAll(dependencies(game.ServerScriptService.Services.PlayerDataService.Source),'game:GetService("ReplicatedStorage").Config:WaitForChild("AuraConfig")','script.Parent.AuraConfig'))
  module("ItemService",dependencies(game.ServerScriptService.Services.ItemService.Source))
  local Data=require(folder.PlayerDataService) local Items=require(folder.ItemService)
  local Master=require(game.ReplicatedStorage.Config.ItemMaster)
  local seq=990000
  local function player(raw)
   seq+=1
   local p={TestPlayer=true,Name="BestEquipTest",UserId=seq,Parent=R.Players,Attributes={}}
   function p:IsA(name) return name=="Player" end
   function p:GetAttribute(name) return self.Attributes[name] end
   function p:SetAttribute(name,v) self.Attributes[name]=v end
   R.PlayersList[p.UserId]=p
   R.Stores.PlayerData_v1["Player_"..p.UserId]=R.Copy(raw or {})
   assert(Data.Load(p)) return p
  end
  local function same(a,b)
   for k,v in pairs(a) do assert(b[k]==v,"Mismatch "..tostring(k)) end
   for k,v in pairs(b) do assert(a[k]==v,"Extra "..tostring(k)) end
  end
  local function check(name,fn) fn() table.insert(results,"PASS "..name) end
  local auraSource=dependencies(game.ServerScriptService.Services.AuraService.Source)
  auraSource=replaceAll(auraSource,'game.ReplicatedStorage.Config:WaitForChild("AuraConfig")','script.Parent.AuraConfig')
  module("AuraService",auraSource)
  local Aura=require(folder.AuraService)
  local Config=require(folder.AuraConfig)
  R.PassOwned=false
  function R.Marketplace:UserOwnsGamePassAsync(userId,id)
   assert(id==1975173075)
   if R.PassFailure then error("simulated marketplace outage") end
   return R.PassOwned
  end
  check("All Win prices, exact balance, permanent owned, auto equip, save/reload",function()
   for _,id in ipairs(Config.Order) do if id~="Red" then
    local a=Config.Get(id)
    local p=player({Win=a.Price})
    assert(Aura.PurchaseAura(p,id))
    assert(Data.Get(p).Data.Win==0 and Aura.GetOwnedAuras(p)[id])
    assert(Aura.GetStrengthBonus(p)==a.StrengthBonus and Aura.GetEquippedAura(p)==id)
    local before=Data.Get(p).Data.Win
    assert(not Aura.PurchaseAura(p,id))
    assert(Data.Get(p).Data.Win==before)
    Data.Release(p) assert(Data.Load(p))
    assert(Aura.GetOwnedAuras(p)[id])
    assert(Aura.EquipAura(p,id))
    assert(Aura.GetStrengthBonus(p)==a.StrengthBonus)
    assert(Data.Save(p)) Data.Release(p) assert(Data.Load(p))
    assert(Aura.GetEquippedAura(p)==id and Aura.GetStrengthBonus(p)==a.StrengthBonus)
   end end
  end)
  check("Pink 9 insufficient, invalid IDs, unowned equip, saving and request locks",function()
   local p=player({Win=9})
   assert(not Aura.PurchaseAura(p,"Pink"))
   assert(Data.Get(p).Data.Win==9 and not Aura.GetOwnedAuras(p).Pink)
   for _,id in ipairs({"Invalid",{},17}) do assert(not Aura.PurchaseAura(p,id));assert(not Aura.EquipAura(p,id)) end
   assert(not Aura.EquipAura(p,"Blue"))
   assert(not Aura.PurchaseAura(p,"Red"))
   Data.SetWin(p,10)
   local attempted=false
   R.BeforeUpdate=function(name)
    if name=="PlayerData_v1" and not attempted then attempted=true;assert(not Aura.PurchaseAura(p,"Pink")) end
   end
   assert(Aura.PurchaseAura(p,"Pink")) R.BeforeUpdate=nil
   assert(attempted and Data.Get(p).Data.Win==0)
  end)
  check("Equip replacement, toggle target unequip, Rebirth preservation",function()
   local p=player({OwnedAuras={Pink=true,Purple=true},Win=0})
   assert(Aura.EquipAura(p,"Pink"));assert(Aura.GetEquippedAura(p)=="Pink")
   assert(Aura.EquipAura(p,"Purple"));assert(Aura.GetEquippedAura(p)=="Purple")
   Data.SetRebirthCount(p,3);Data.SetCurrentStrength(p,0)
   assert(Aura.GetEquippedAura(p)=="Purple" and Aura.GetOwnedAuras(p).Pink)
   assert(Aura.UnequipAura(p));assert(Aura.GetEquippedAura(p)==nil and Aura.GetStrengthBonus(p)==0)
  end)
  check("Failed and ambiguous save retain debit+ownership together; retry cannot charge twice",function()
   for _,ambiguous in ipairs({false,true}) do
    local p=player({Win=10})
    if ambiguous then R.FailAfterWrite=function(name) return name=="PlayerData_v1" end
    else R.FailWrite=function(name) return name=="PlayerData_v1" end end
    assert(not Aura.PurchaseAura(p,"Pink"))
    R.FailWrite=nil R.FailAfterWrite=nil
    assert(Data.Get(p).Data.Win==0 and Aura.GetOwnedAuras(p).Pink)
    assert(not Aura.PurchaseAura(p,"Pink"))
    assert(Data.Save(p)) Data.Release(p) assert(Data.Load(p))
    assert(Data.Get(p).Data.Win==0 and Aura.GetOwnedAuras(p).Pink)
   end
  end)
  check("Red pass source of truth, denied stale cache, verified grant and rejoin equivalent",function()
   local p=player({OwnedAuras={Red=true},EquippedAura="Red"})
   assert(Aura.GetStrengthBonus(p)==0)
   assert(not Aura.RefreshRedOwnership(p,true));assert(not Aura.EquipAura(p,"Red"))
   R.PassOwned=true
   assert(Aura.RefreshRedOwnership(p,true));assert(Aura.EquipAura(p,"Red"))
   assert(Aura.GetStrengthBonus(p)==1000)
   assert(Data.Save(p))
   local raw=R.Stores.PlayerData_v1["Player_"..p.UserId]
   local q=player(raw)
   assert(Aura.GetStrengthBonus(q)==0)
   assert(Aura.RefreshRedOwnership(q,true));assert(Aura.GetStrengthBonus(q)==1000)
   R.PassOwned=false R.PassFailure=true
   local denied=player({OwnedAuras={Red=true},EquippedAura="Red"})
   assert(not Aura.RefreshRedOwnership(denied,true));assert(Aura.GetStrengthBonus(denied)==0)
   R.PassFailure=false
  end)
  module("DumbbellService","return {GetStrengthBonus=function() return 7 end}")
  module("TrainingLobbyAreaService","return {IsInTrainingLobby=function(player) return player.InLobby end}")
  module("PotionService","return {GetStrengthMultiplier=function(player) return player.Potion or 1 end}")
  local strengthSource=dependencies(game.ServerScriptService.Services.StrengthManager.Source)
  strengthSource=replaceAll(strengthSource,'game:GetService("ReplicatedStorage").Remotes.StrengthGain:FireClient(player,result-before)','do end -- presentation remote omitted in isolated fixture')
  module("StrengthManager",strengthSource)
  local Strength=require(folder.StrengthManager)
  check("Actual V5 gain: every Aura, lobby/outside/treadmill, rebirth and potion exactly once",function()
   for _,id in ipairs(Config.Order) do
    local p=player({OwnedAuras={[id]=true}})
    if id=="Red" then R.PassOwned=true;assert(Aura.RefreshRedOwnership(p,true)) end
    assert(Aura.EquipAura(p,id))
    Data.SetRebirthCount(p,3)
    local rebirth=Strength.GetStrengthGainMultiplier(p)
    for _,inside in ipairs({true,false}) do
     p.InLobby=inside
     for _,mult in ipairs({1,5,20}) do
      p.Potion=2
      Strength.SetStrength(p,0)
      local value=Strength.AddStrength(p,2,1,mult)
      local expected=(2+(inside and 7 or 0)+Config.Get(id).StrengthBonus)*rebirth*mult*2
      assert(math.abs(value-expected)<.001,id.." gain mismatch")
     end
    end
   end
  end)
  check("New purchases replace equipment and failed saves keep the old slot",function()
   local p=player({Win=40})
   assert(Aura.PurchaseAura(p,"Pink"));assert(Aura.GetEquippedAura(p)=="Pink")
   assert(Aura.PurchaseAura(p,"Purple"));assert(Aura.GetEquippedAura(p)=="Purple")
   Data.Release(p);assert(Data.Load(p));assert(Aura.GetEquippedAura(p)=="Purple")
   assert(not Aura.PurchaseAura(p,"Yellow"));assert(Aura.GetEquippedAura(p)=="Purple")
   Data.SetWin(p,75)
   R.FailWrite=function(name) return name=="PlayerData_v1" end
   assert(not Aura.PurchaseAura(p,"Yellow"))
   R.FailWrite=nil
   assert(Aura.GetEquippedAura(p)=="Purple")
  end)
  check("Red completed purchase verifies pass and saves auto-equip; failures do not equip",function()
   local p=player({OwnedAuras={Pink=true},EquippedAura="Pink"})
   R.PassOwned=false;assert(not Aura.CompleteRedPurchase(p));assert(Aura.GetEquippedAura(p)=="Pink")
   R.PassOwned=true;R.PassFailure=true;assert(not Aura.CompleteRedPurchase(p));R.PassFailure=false
   assert(Aura.GetEquippedAura(p)=="Pink")
   R.FailWrite=function(name) return name=="PlayerData_v1" end
   assert(not Aura.CompleteRedPurchase(p));R.FailWrite=nil;assert(Aura.GetEquippedAura(p)=="Pink")
   assert(Aura.CompleteRedPurchase(p));assert(Aura.GetEquippedAura(p)=="Red")
   local saved=R.Stores.PlayerData_v1["Player_"..p.UserId]
   assert(saved.EquippedAura=="Red")
   R.PassOwned=false
  end)
  check("Legacy missing Aura fields default safely",function()
   local p=player({})
   assert(Aura.GetEquippedAura(p)==nil and not Aura.GetOwnedAuras(p).Pink)
  end)
 end,debug.traceback)
 folder:Destroy()
 if not ok then error(err) end
 return results
end
return T
