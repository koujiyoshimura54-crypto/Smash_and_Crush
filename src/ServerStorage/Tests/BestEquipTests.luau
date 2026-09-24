-- Isolated production-source regression tests. No real players or DataStores.
local T={}
function T.Run()
 local folder=Instance.new("Folder") folder.Name="BestEquipTestSandbox" folder.Parent=game.ServerStorage
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
   for service,field in pairs({Players="Players",DataStoreService="DSS",RunService="RunService",HttpService="Http"}) do
    source=replaceAll(source,'game:GetService("'..service..'")','require(script.Parent.Runtime).'..field)
   end
   return shim..source
  end
  module("PlayerDataService",dependencies(game.ServerScriptService.Services.PlayerDataService.Source))
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
  local fixture={
   PROTEIN_COMMON_FIRE=2,PROTEIN_EPIC_ICE=1,PROTEIN_RARE_ELECTRIC=3,
   GLOVE_RARE_FIRE=3,GLOVE_LEGENDARY_ICE=1,
   TRAININGBELT_COMMON_ICE=1,TRAININGBELT_UNCOMMON_FIRE=2,TRAININGBELT_EPIC_ELECTRIC=1,
  }
  check("Requested example, quantities unchanged, existing effects, durable save and reload",function()
   local p=player({OwnedItems=fixture,Win=77,Strength=123,RebirthCount=2})
   local calls=0 local original=Items.EquipItem
   Items.EquipItem=function(...) calls+=1 return original(...) end
   assert(Items.EquipBestItems(p))
   Items.EquipItem=original
   assert(calls==3,"Must reuse all three EquipItem calls")
   local e=Items.GetEquippedItems(p)
   assert(e.Protein=="PROTEIN_EPIC_ICE" and e.Glove=="GLOVE_LEGENDARY_ICE" and e.TrainingBelt=="TRAININGBELT_EPIC_ELECTRIC")
   same(Items.GetOwnedItems(p),fixture)
   assert(Items.GetProteinBonus(p)==100 and Items.GetGloveBossDamageBonus(p)==.5 and Items.GetBeltTreadmillBonus(p)==1.5)
   assert(Data.Get(p).Dirty,"Best Equip must remain dirty until normal save")
   assert(Data.Save(p))
   local saved=R.Stores.PlayerData_v1["Player_"..p.UserId]
   same(saved.EquippedItems,e) same(saved.OwnedItems,fixture)
   assert(saved.Win==77 and saved.Strength==123 and saved.RebirthCount==2)
   Data.Release(p) assert(Data.Load(p))
   same(Items.GetEquippedItems(p),e) same(Items.GetOwnedItems(p),fixture)
   assert(Items.EquipItem(p,"PROTEIN_COMMON_FIRE"))
   assert(Items.GetProteinBonus(p)==5)
   assert(Data.Save(p)) Data.Release(p) assert(Data.Load(p))
   assert(Items.GetEquippedItems(p).Protein=="PROTEIN_COMMON_FIRE")
  end)
  check("Every type/rarity/element: keep current highest rarity, stable ID fallback",function()
   local prefixes={Protein="PROTEIN",Glove="GLOVE",TrainingBelt="TRAININGBELT"}
   for kind,prefix in pairs(prefixes) do
    for _,rarity in ipairs({"COMMON","UNCOMMON","RARE","EPIC","LEGENDARY"}) do
     local owned={} local ids={}
     for _,element in ipairs({"ICE","FIRE","ELECTRIC"}) do
      local id=prefix.."_"..rarity.."_"..element owned[id]=1 table.insert(ids,id)
     end
     for _,id in ipairs(ids) do
      local p=player({OwnedItems=owned,EquippedItems={[kind]=id}})
      assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p)[kind]==id)
     end
     table.sort(ids)
     local p=player({OwnedItems=owned})
     assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p)[kind]==ids[1])
     for _=1,3 do assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p)[kind]==ids[1]) end
    end
   end
  end)
  check("Rarity beats current lower rarity regardless of element",function()
   for _,element in ipairs({"FIRE","ICE","ELECTRIC"}) do
    local id="PROTEIN_EPIC_"..element
    local p=player({OwnedItems={PROTEIN_RARE_FIRE=1,[id]=1},EquippedItems={Protein="PROTEIN_RARE_FIRE"}})
    assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p).Protein==id)
   end
  end)
  check("Missing type untouched; empty inventory succeeds; unknown/zero-count ignored",function()
   local p=player({OwnedItems={PROTEIN_RARE_ICE=1,TRAININGBELT_EPIC_FIRE=1,UNKNOWN=3,PROTEIN_LEGENDARY_FIRE=0},EquippedItems={Glove="GLOVE_RARE_ICE"}})
   assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p).Glove=="GLOVE_RARE_ICE")
   assert(Items.GetEquippedItems(p).Protein=="PROTEIN_RARE_ICE")
   local q=player() local e=Items.GetEquippedItems(q)
   assert(Items.EquipBestItems(q)) same(Items.GetEquippedItems(q),e) same(Items.GetOwnedItems(q),{})
  end)
  check("Unowned current high rarity is replaced; forged attributes ignored",function()
   local p=player({OwnedItems={PROTEIN_COMMON_ICE=1},EquippedItems={Protein="PROTEIN_LEGENDARY_FIRE"}})
   p:SetAttribute("EquippedProtein","PROTEIN_LEGENDARY_FIRE")
   assert(Items.EquipBestItems(p)) assert(Items.GetEquippedItems(p).Protein=="PROTEIN_COMMON_ICE")
  end)
  check("Invalid player, unloaded, save lock and pending quantity transaction rejected",function()
   assert(not Items.EquipBestItems({}))
   local p=player({OwnedItems=fixture}) local session=Data.Get(p)
   session.Saving=true assert(not Items.EquipBestItems(p)) session.Saving=false
   session.PendingItemMutation={} assert(not Items.EquipBestItems(p)) session.PendingItemMutation=nil
   same(Items.GetEquippedItems(p),{Protein="",Glove="",TrainingBelt=""})
   Data.Release(p) assert(not Items.EquipBestItems(p))
  end)
  check("Best Equip never saves or yields; normal save failure retains dirty state and retry persists",function()
   local p=player({OwnedItems=fixture})
   local save=Data.Save
   Data.Save=function() error("Best Equip must not call Save") end
   local co=coroutine.create(function() return Items.EquipBestItems(p) end)
   local ok,success,code=coroutine.resume(co)
   Data.Save=save
   assert(ok and success and code=="BestEquipped")
   assert(coroutine.status(co)=="dead","Best Equip yielded")
   assert(Data.Get(p).Dirty and not Data.Get(p).Saving)
   assert(not R.Stores.PlayerData_v1["Player_"..p.UserId].EquippedItems,"Unexpected immediate save")
   same(Items.GetOwnedItems(p),fixture)
   R.FailWrite=function(name) return name=="PlayerData_v1" end
   assert(not Data.Save(p))
   assert(Data.Get(p).Dirty and not Data.Get(p).Saving)
   R.FailWrite=nil assert(Data.Save(p))
   local expected=Items.GetEquippedItems(p)
   Data.Release(p) assert(Data.Load(p)) same(Items.GetEquippedItems(p),expected)
  end)
  check("Actual remote bridge: forged payload rejected, server selection, rate limit, manual equip",function()
   R.Remotes={}
   for _,name in ipairs({"ItemInventoryState","ItemEquipRequest","ItemPurchaseRequest","ItemRobuxPurchaseRequest"}) do
    local remote={OnServerEvent=R.Signal(),Replies={}}
    function remote:FireClient(p,result) self.Replies[p]=result end
    R.Remotes[name]=remote
   end
   R.RS={WaitForChild=function(_,name) return assert(R.Remotes[name]) end}
   module("ItemPurchaseService",'return {SetNotifier=function() end,Prompt=function() return false end}')
   local source=dependencies(game.ServerScriptService.Systems.Controllers.ItemController.Source)
   source=replaceAll(source,'game:GetService("ReplicatedStorage")','require(script.Parent.Runtime).RS')
   require(module("ItemController",source.."\nreturn true"))
   local remote=R.Remotes.ItemEquipRequest
   local forged=player({OwnedItems={PROTEIN_COMMON_FIRE=1}})
   remote.OnServerEvent:Fire(forged,{PROTEIN_LEGENDARY_FIRE=99},"BestEquip")
   assert(remote.Replies[forged].Code=="InvalidRequest" and Items.GetEquippedItems(forged).Protein=="")
   local p=player({OwnedItems=fixture})
   remote.OnServerEvent:Fire(p,nil,"BestEquip")
   assert(remote.Replies[p].Success and remote.Replies[p].State.EquippedItems.Protein=="PROTEIN_EPIC_ICE")
   remote.OnServerEvent:Fire(p,nil,"BestEquip") assert(remote.Replies[p].Code=="RateLimited")
   local manual=player({OwnedItems={PROTEIN_COMMON_FIRE=1}})
   remote.OnServerEvent:Fire(manual,"PROTEIN_COMMON_FIRE")
   assert(remote.Replies[manual].Success and Items.GetEquippedItems(manual).Protein=="PROTEIN_COMMON_FIRE")
   same(Items.GetOwnedItems(p),fixture)
  end)
 end,debug.traceback)
 folder:Destroy()
 if not ok then error(table.concat(results,"\n").."\nFAIL "..tostring(err)) end
 return table.concat(results,"\n")
end
return T
