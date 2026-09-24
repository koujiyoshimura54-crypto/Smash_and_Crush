-- Manual isolated regression tests. Run require(ServerStorage.Tests.Phase721Tests).Run()
-- Clones production sources; replaces only engine dependencies with in-memory fakes.
-- Never accesses Roblox DataStores or changes a real player's Attributes.
local Tests = {}
function Tests.Run()
 local folder = Instance.new("Folder")
 folder.Name = "Phase721TestSandbox"
 folder.Parent = game:GetService("ServerStorage")
 local results = {}
 local function module(name, source)
  local v = Instance.new("ModuleScript")
  v.Name = name
  v.Source = source
  v.Parent = folder
  return v
 end
 local function replaceOnce(source, before, after)
  local first, last = string.find(source, before, 1, true)
  assert(first, "Dependency seam missing: " .. before)
  return string.sub(source, 1, first-1) .. after .. string.sub(source, last+1)
 end
 local ok, err = pcall(function()
  local fake = module("FakeDSS", [==[
local H=game:GetService("HttpService")
local F={Records={}, Updates=0, FailLoad=false, FailSave=false}
local function copy(value)
 if value==nil then return nil end
 return H:JSONDecode(H:JSONEncode(value))
end
function F:GetDataStore(name)
 assert(name=="PlayerData_v1", "Unexpected DataStore")
 return {
  GetAsync=function(_,key)
   if F.FailLoad then error("simulated load failure") end
   return copy(F.Records[key])
  end,
  UpdateAsync=function(_,key,callback)
   F.Updates+=1
   if F.BeforeUpdate then F.BeforeUpdate() end
   if F.FailSave then error("simulated save failure") end
   -- Exercise callback retry without persisting the first result.
   callback(copy(F.Records[key]))
   F.Records[key]=copy(callback(copy(F.Records[key])))
   return copy(F.Records[key])
  end,
 }
end
function F:GetOrderedDataStore(_name)
 return {SetAsync=function() end}
end
return F
]==])
  local dataSource = replaceOnce(game.ServerScriptService.Services.PlayerDataService.Source,
   'local DSS=game:GetService("DataStoreService")', 'local DSS=require(script.Parent.FakeDSS)')
  local dataModule = module("PlayerDataService", dataSource)
  local masterModule = module("DumbbellItemMaster", game.ReplicatedStorage.Config.DumbbellItemMaster.Source)
  local serviceSource = replaceOnce(game.ServerScriptService.Services.DumbbellService.Source,
   'local Players = game:GetService("Players")',
   'local Players = script.Parent\nlocal engineTypeof = typeof\nlocal function typeof(v) if type(v)=="table" and v.IsTestPlayer then return "Instance" end return engineTypeof(v) end')
  serviceSource = replaceOnce(serviceSource,
   'require(game:GetService("ReplicatedStorage").Config:WaitForChild("DumbbellItemMaster"))',
   'require(script.Parent.DumbbellItemMaster)')
  local serviceModule = module("DumbbellService", serviceSource)
  local F, Data, Master, Service = require(fake), require(dataModule), require(masterModule), require(serviceModule)
  local sequence = 721000
  local function player()
   sequence+=1
   local p={IsTestPlayer=true, UserId=sequence, Name="IsolatedTest", Parent=folder, Attributes={}}
   function p:IsA(name) return name=="Player" end
   function p:GetAttribute(name) return self.Attributes[name] end
   function p:SetAttribute(name,value)
    self.Attributes[name]=value
    if self.OnSet then self.OnSet(name,value) end
   end
   return p
  end
  local function check(name, fn)
   fn()
   table.insert(results, "PASS " .. name)
  end
  local p=player()
  check("A: new inventory empty, no free NORMAL_01", function()
   assert(Data.Load(p))
   assert(next(Service.GetOwnedDumbbells(p))==nil)
   assert(not Service.HasDumbbell(p,"NORMAL_01"))
  end)
  check("ItemMaster: all five definitions and immutable dictionary", function()
   local count=0
   for _ in pairs(Master.GetAll()) do count+=1 end
   assert(count==5 and Master.Get({})==nil and Master.Get("UNKNOWN")==nil)
   for i, expected in ipairs({{1,2},{3,5},{5,10},{10,25},{20,50}}) do
    local id=string.format("NORMAL_%02d",i)
    local item=Master.Get(id)
    assert(item.ItemId==id and item.Name=="Normal Dumbbell "..i and item.Grade==i)
    assert(item.PriceWin==expected[1] and item.StrengthMultiplier==expected[2])
    assert(item.Category=="Dumbbell" and item.SeriesId=="NORMAL" and item.ElementId=="NORMAL")
    assert(item.SourceType=="Earned" and item.Mergeable==true)
    assert(item.ImageAssetId==89307391617240 and item.Image=="rbxassetid://89307391617240")
    assert(item.ModelId==nil)
   end
   assert(not pcall(function() Master.Get("NORMAL_01").PriceWin=0 end))
   assert(not pcall(function() Master.GetAll().NEW={} end))
  end)
  check("B: NORMAL_01 debits 10 -> 9 before adding ownership", function()
   Data.SetWin(p,10)
   p.OnSet=function(name)
    if name=="Win" then assert(not Service.HasDumbbell(p,"NORMAL_01")) end
   end
   assert(Service.PurchaseDumbbell(p,"NORMAL_01"))
   p.OnSet=nil
   assert(p:GetAttribute("Win")==9 and Service.HasDumbbell(p,"NORMAL_01"))
  end)
  check("C: 100 duplicate requests do not debit again", function()
   for _=1,100 do
    local success,code=Service.PurchaseDumbbell(p,"NORMAL_01")
    assert(not success and code=="AlreadyOwned")
   end
   assert(p:GetAttribute("Win")==9)
  end)
  check("D: NORMAL_03 debits 9 -> 4", function()
   assert(Service.PurchaseDumbbell(p,"NORMAL_03"))
   assert(p:GetAttribute("Win")==4 and Service.HasDumbbell(p,"NORMAL_03"))
  end)
  check("E: insufficient Win leaves balance and inventory intact", function()
   local success,code=Service.PurchaseDumbbell(p,"NORMAL_05")
   assert(not success and code=="NotEnoughWin")
   assert(p:GetAttribute("Win")==4 and not Service.HasDumbbell(p,"NORMAL_05"))
  end)
  check("Inventory API returns independent copies", function()
   local owned=Service.GetOwnedDumbbells(p)
   owned.NORMAL_01=nil
   owned.NORMAL_05=true
   assert(Service.HasDumbbell(p,"NORMAL_01") and not Service.HasDumbbell(p,"NORMAL_05"))
  end)
  check("Invalid IDs and payload types are rejected without debit", function()
   for _,id in ipairs({"","UNKNOWN",{},123,false}) do assert(not Service.PurchaseDumbbell(p,id)) end
   assert(not Service.PurchaseDumbbell(p,nil))
   assert(p:GetAttribute("Win")==4)
  end)
  check("F: UpdateAsync -> Release -> Load restores both items and Win", function()
   assert(Data.Save(p))
   local saved=F.Records["Player_"..p.UserId]
   assert(saved.Win==4 and saved.OwnedDumbbells.NORMAL_01 and saved.OwnedDumbbells.NORMAL_03)
   Data.Release(p)
   assert(Data.Load(p))
   assert(p:GetAttribute("Win")==4 and Service.HasDumbbell(p,"NORMAL_01") and Service.HasDumbbell(p,"NORMAL_03"))
  end)
  check("G: legacy stats preserved through load, purchase and save", function()
   local q=player()
   local key="Player_"..q.UserId
   F.Records[key]={Strength=1234,RebirthCount=7,TotalStrengthEarned=5678,DailyStrengthEarned=90,DailyDate=Data.Today(),Win=10,ExistingExtra="keep"}
   assert(Data.Load(q))
   assert(next(Service.GetOwnedDumbbells(q))==nil)
   assert(Service.PurchaseDumbbell(q,"NORMAL_01"))
   assert(Data.Save(q))
   local saved=F.Records[key]
   assert(saved.Strength==1234 and saved.RebirthCount==7 and saved.TotalStrengthEarned==5678)
   assert(saved.DailyStrengthEarned==90 and saved.DailyDate==Data.Today() and saved.Win==9)
   assert(saved.ExistingExtra=="keep")
  end)
  check("Missing definition retains future owned ItemId across save/load", function()
   local q=player()
   F.Records["Player_"..q.UserId]={Win=8,OwnedDumbbells={FUTURE_31=true}}
   assert(Data.Load(q))
   assert(Service.HasDumbbell(q,"FUTURE_31"))
   assert(Data.Save(q))
   Data.Release(q)
   assert(Data.Load(q) and Service.HasDumbbell(q,"FUTURE_31"))
  end)
  check("Invalid inventory and failed load cannot purchase or overwrite saved data", function()
   for _,inventory in ipairs({"bad",{NORMAL_01="bad"}}) do
    local q=player()
    F.Records["Player_"..q.UserId]={Strength=99,Win=10,OwnedDumbbells=inventory}
    assert(not Data.Load(q))
    assert(not Service.PurchaseDumbbell(q,"NORMAL_01"))
    assert(not Data.Save(q))
    assert(F.Records["Player_"..q.UserId].Strength==99)
   end
   local q=player()
   F.FailLoad=true
   assert(not Data.Load(q))
   F.FailLoad=false
   assert(not Service.PurchaseDumbbell(q,"NORMAL_01"))
   assert(Service.GetOwnedDumbbells(q)==nil)
  end)
  check("Save serialization and purchase rejection while UpdateAsync is active", function()
   local q=player()
   assert(Data.Load(q))
   Data.SetWin(q,10)
   F.BeforeUpdate=function()
    assert(Data.IsSaving(q))
    local success,code=Service.PurchaseDumbbell(q,"NORMAL_01")
    assert(not success and code=="DataSaving" and q:GetAttribute("Win")==10)
    local saved,reason=Data.Save(q)
    assert(not saved and reason=="saving")
   end
   assert(Data.Save(q))
   F.BeforeUpdate=nil
   assert(Service.PurchaseDumbbell(q,"NORMAL_01"))
   assert(Data.Save(q))
   assert(F.Records["Player_"..q.UserId].Win==9)
  end)
  check("Failed save retains inventory and allows successful retry", function()
   local q=player()
   assert(Data.Load(q))
   Data.SetWin(q,10)
   assert(Service.PurchaseDumbbell(q,"NORMAL_01"))
   F.FailSave=true
   assert(not Data.Save(q))
   F.FailSave=false
   assert(not Data.IsSaving(q) and Service.HasDumbbell(q,"NORMAL_01") and q:GetAttribute("Win")==9)
   assert(Data.Save(q))
   Data.Release(q)
   assert(Data.Load(q) and Service.HasDumbbell(q,"NORMAL_01") and q:GetAttribute("Win")==9)
  end)
  check("Reentrant purchase cannot double debit", function()
   local q=player()
   assert(Data.Load(q))
   Data.SetWin(q,10)
   q.OnSet=function(name)
    if name=="Win" then
     local success,code=Service.PurchaseDumbbell(q,"NORMAL_01")
     assert(not success and code=="PurchaseInProgress")
    end
   end
   assert(Service.PurchaseDumbbell(q,"NORMAL_01"))
   q.OnSet=nil
   assert(q:GetAttribute("Win")==9 and Service.HasDumbbell(q,"NORMAL_01"))
  end)
  check("Invalid Win rejects NaN, infinity, negative and fractional balances", function()
   local q=player()
   assert(Data.Load(q))
   for _,win in ipairs({0/0,math.huge,-math.huge,-1,1.5}) do
    q.Attributes.Win=win
    local success,code=Service.PurchaseDumbbell(q,"NORMAL_01")
    assert(not success and code=="InvalidWin")
    assert(not Service.HasDumbbell(q,"NORMAL_01"))
   end
  end)
  check("Validation rejects wrong category and malformed master prices", function()
   -- A separate cloned service uses a mutable test master to exercise defensive guards.
   module("InvalidMaster", 'return {Get=function(id) return {Category=id=="CATEGORY" and "Other" or "Dumbbell",PriceWin=({ZERO=0,NEGATIVE=-1,FRACTION=1.5,INF=math.huge,STRING="1",NAN=0/0})[id]} end}')
   local invalidSource=replaceOnce(serviceSource,'require(script.Parent.DumbbellItemMaster)','require(script.Parent.InvalidMaster)')
   local invalid=require(module("InvalidService",invalidSource))
   local q=player()
   assert(Data.Load(q))
   Data.SetWin(q,10)
   local success,code=invalid.PurchaseDumbbell(q,"CATEGORY")
   assert(not success and code=="InvalidCategory")
   for _,id in ipairs({"ZERO","NEGATIVE","FRACTION","INF","STRING","NAN","MISSING"}) do
    local purchased,reason=invalid.PurchaseDumbbell(q,id)
    assert(not purchased and reason=="InvalidPrice")
   end
   assert(q:GetAttribute("Win")==10 and next(Service.GetOwnedDumbbells(q))==nil)
  end)
 end)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n") .. "\nFAIL " .. tostring(err)) end
 return table.concat(results,"\n")
end
return Tests
