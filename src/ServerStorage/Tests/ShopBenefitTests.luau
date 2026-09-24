-- Manual isolated tests: synthetic players and in-memory DataStore; never runs automatically.
local T={}
function T.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local modules={}
 local function factory(name,source,args)
  local m=Instance.new("ModuleScript");m.Name=name;m.Source="return function("..args..")\n"..source.."\nend";m.Parent=game.ServerStorage
  table.insert(modules,m);return require(m)
 end
 local source=game.ServerScriptService.Services.PlayerDataService.Source
 source=source:gsub('local DSS=game:GetService%("DataStoreService"%)','local DSS=TestDSS')
 source=source:gsub('local ShopConfig=require%(game.ReplicatedStorage.Config:WaitForChild%("ShopProductConfig"%)%)','local ShopConfig=TestShop')
 source=source:gsub('require%(game.ServerScriptService.Services.GamePassService%)','TestPass')
 source=source:gsub('require%(game.ServerScriptService.Services.PotionService%)','TestPotion')
 source=source:gsub('local function dailyUTC%(%) return os.date%("!%%Y%-%%m%-%%d",os.time%(%)%) end','local function dailyUTC() return TestDate() end')
 local make=factory("ShopDataTestFactory",source,"TestDSS,TestShop,TestPass,TestPotion,TestDate")
 local cfg=require(game.ReplicatedStorage.Config.ShopProductConfig)
 local results={}
 local function test(name,fn)local ok,err=pcall(fn);table.insert(results,{Name=name,Pass=ok,Error=not ok and tostring(err) or nil})end
 local function copy(v)if typeof(v)~="table" then return v end local o={}for k,x in pairs(v)do o[k]=copy(x)end return o end
 local function fixture()
  local f={Records={},Metadata={},Date="2026-09-14",Passes={},PotionCalls=0,Deadlines={},Names={}}
  local store={}
  function store:GetAsync(key)return copy(f.Records[key])end
  function store:UpdateAsync(key,fn)
   local meta=copy(f.Metadata[key] or {})
   local info={GetMetadata=function()return copy(meta)end,GetUserIds=function()return {123}end}
   local value,_,m=fn(copy(f.Records[key]),info)
   if value then f.Records[key]=copy(value);f.Metadata[key]=copy(m or meta)end
   if f.Hook then local h=f.Hook;f.Hook=nil;h()end
   if f.FailAfterCommit then f.FailAfterCommit=false;error("Injected ambiguous result")end
   return copy(f.Records[key]),{GetMetadata=function()return copy(f.Metadata[key] or {})end}
  end
  local dss={GetDataStore=function(_,name)table.insert(f.Names,name);return store end,GetOrderedDataStore=function(_,name)table.insert(f.Names,name);return {SetAsync=function()end}end}
  local attributes={}
  local p={UserId=987654320,Name="IsolatedShopTest",Parent=game.Players}
  function p:SetAttribute(k,v)attributes[k]=v end
  function p:GetAttribute(k)return attributes[k]end
  local passes={HasShopPass=function(_,key)return f.Passes[key]==true end}
  local potions={GetRemaining=function(_,id)return math.max(0,(f.Deadlines[id] or 0)-os.time())end,
   EnsureExpiresAt=function(_,id,deadline)f.PotionCalls+=1;f.Deadlines[id]=math.max(f.Deadlines[id] or 0,deadline)end}
  local config=table.clone(cfg)
  config.ForWinProduct=function(id)if id==900000001 then return {Key="IsolatedWin",Amount=17,ProductId=id}end end
  f.Config=config;f.Player=p;f.Data=make(dss,config,passes,potions,function()return f.Date end)
  assert(f.Data.Load(p));return f
 end
 test("legacy data defaults, Studio name and existing metadata preserved",function()
  local f=fixture();local d,p=f.Data,f.Player
  f.Metadata.Player_987654320={ItemReceiptId="existing",ItemReceiptSequence=8}
  assert(d.Save(p))
  assert(f.Names[1]=="PlayerData_v1_Studio")
  assert(f.Metadata.Player_987654320.ItemReceiptId=="existing")
  assert(d.GetShopRewards(p).VIPDailyDateUTC=="")
 end)
 test("Starter ambiguous retry, concurrent Win/Strength, one potion activation, rejoin",function()
  local f=fixture();local d,p=f.Data,f.Player
  f.Passes.StarterPack=true;d.SetWin(p,20)
  local blocked
  f.Hook=function()
   d.SetWin(p,27);p:SetAttribute("Strength",11);d.SetCurrentStrength(p,11)
   local ok,code=d.ResolveItemMutation(p);blocked=not ok and code=="InventorySavePending"
  end
  f.FailAfterCommit=true
  local ok,code=d.ClaimShopReward(p,"StarterPack")
  assert(not ok and code=="InventorySavePending" and blocked)
  assert(d.ResolveItemMutation(p))
  assert(p:GetAttribute("Win")==127 and p:GetAttribute("Strength")==11)
  assert(f.PotionCalls==2)
  local deadline=f.Deadlines.Strength
  for i=1,10 do local granted=d.ClaimShopReward(p,"StarterPack");assert(not granted)end
  assert(f.PotionCalls==2 and f.Deadlines.Strength==deadline)
  assert(d.Save(p));d.Release(p);assert(d.Load(p))
  assert(p:GetAttribute("Win")==127 and p:GetAttribute("Strength")==11)
  assert(d.GetShopRewards(p).Claims.StarterPack)
  assert(not d.ClaimShopReward(p,"StarterPack"));assert(f.PotionCalls==2)
 end)
 test("Secret atomic Win + owned aura + exactly one Epic/Legendary, retry retains roll",function()
  local f=fixture();local d,p=f.Data,f.Player;f.Passes.SecretPack=true
  f.FailAfterCommit=true
  local ok=d.ClaimShopReward(p,"SecretPack");assert(not ok)
  local selected=d.Get(p).PendingItemMutation.ShopGrant.ItemId
  assert(d.ResolveItemMutation(p))
  assert(p:GetAttribute("Win")==500 and d.Get(p).Data.OwnedAuras.Secret)
  assert(d.Get(p).Data.OwnedItems[selected]==1)
  assert(not d.ClaimShopReward(p,"SecretPack"))
  local rarity=require(game.ReplicatedStorage.Config.ItemMaster).Get(selected).Rarity
  assert(rarity=="Epic" or rarity=="Legendary")
  assert(d.Save(p));d.Release(p);assert(d.Load(p))
  assert(d.Get(p).Data.OwnedItems[selected]==1 and p:GetAttribute("Win")==500)
 end)
 test("VIP daily independent of normal Day 7; one claim per UTC date",function()
  local f=fixture();local d,p=f.Data,f.Player
  assert(not d.ClaimShopReward(p,"VIPDaily"))
  f.Passes.VIP=true;assert(d.ClaimShopReward(p,"VIP"))
  assert(d.Get(p).Data.OwnedAuras.VIP)
  assert(d.ClaimShopReward(p,"VIPDaily"))
  assert(not d.ClaimShopReward(p,"VIPDaily"))
  assert(d.Get(p).Data.DailyRewards.ClaimedDays==0)
  f.Date="2026-09-15";assert(d.ClaimShopReward(p,"VIPDaily"))
  assert(p:GetAttribute("Win")==cfg.Get("VIP").DailyBonus.Amount*2)
 end)
 test("Win receipt replay across rejoin grants once; unknown product rejected",function()
  local f=fixture();local d,p=f.Data,f.Player
  local receipt={PlayerId=p.UserId,ProductId=900000001,PurchaseId="isolated-receipt"}
  f.FailAfterCommit=true;assert(not d.ClaimShopReward(p,"IsolatedWin",receipt))
  assert(d.ResolveItemMutation(p));assert(p:GetAttribute("Win")==17)
  assert(d.Save(p));d.Release(p);assert(d.Load(p))
  assert(not d.ClaimShopReward(p,"IsolatedWin",receipt));assert(p:GetAttribute("Win")==17)
  receipt.PurchaseId="second";assert(d.ClaimShopReward(p,"IsolatedWin",receipt));assert(p:GetAttribute("Win")==34)
  receipt.ProductId=1;assert(not d.ClaimShopReward(p,"IsolatedWin",receipt))
 end)
 test("reset barrier blocks pending grant",function()
  local f=fixture();local d,p=f.Data,f.Player;f.Passes.StarterPack=true
  f.FailAfterCommit=true;assert(not d.ClaimShopReward(p,"StarterPack"))
  f.Records.Player_987654320.ResetToken="new-generation"
  local ok,code=d.ResolveItemMutation(p)
  assert(not ok and code=="SaveSupersededByReset");assert(f.PotionCalls==0)
 end)
 test("stale session save preserves paid Win, bundle aura and receipt markers",function()
  local f=fixture();local d,p=f.Data,f.Player;f.Passes.SecretPack=true
  local attrs={};local stale={UserId=p.UserId,Name="StaleSession",Parent=game.Players}
  function stale:SetAttribute(k,v)attrs[k]=v end
  function stale:GetAttribute(k)return attrs[k]end
  assert(d.Load(stale))
  assert(d.ClaimShopReward(p,"SecretPack"))
  assert(d.Save(stale))
  assert(f.Records.Player_987654320.Win==500)
  assert(f.Records.Player_987654320.OwnedAuras.Secret)
  assert(f.Records.Player_987654320.ShopRewards.Claims.SecretPack)
  assert(stale:GetAttribute("Win")==500)
  assert(d.Save(stale));assert(f.Records.Player_987654320.Win==500)
 end)
 test("Secret outcomes are server definitions; probability sums to 100 and no MISS",function()
  local outcomes=cfg.GetSecretOutcomes();assert(#outcomes==18)
  local sum=0;for _,o in ipairs(outcomes)do sum+=o.Percent;assert(o.Rarity=="Epic" or o.Rarity=="Legendary")end
  assert(math.abs(sum-100)<.00001)
  for _=1,100 do assert(require(game.ReplicatedStorage.Config.ItemMaster).Get(cfg.RollSecret(Random.new())))end
 end)
 test("Secret policy restriction and lookup failure block prompt and random grant",function()
  local source=game.ServerScriptService.Services.ShopRewardService.Source
  source=source:gsub('local Marketplace=game:GetService%("MarketplaceService"%)','local Marketplace=TestMarket')
  source=source:gsub('local Policy=game:GetService%("PolicyService"%)','local Policy=TestPolicy')
  source=source:gsub('local Data=require%b()','local Data=TestData')
  source=source:gsub('local Passes=require%b()','local Passes=TestPass')
  source=source:gsub('local Potions=require%b()','local Potions=TestPotions')
  local build=factory("ShopPolicyTestFactory",source,"TestMarket,TestPolicy,TestData,TestPass,TestPotions")
  local prompts,secret=0,0
  local fail=false
  local m=build({PromptGamePassPurchase=function()prompts+=1 end},
   {GetPolicyInfoForPlayerAsync=function()if fail then error("Injected policy outage")end return {ArePaidRandomItemsRestricted=true}end},
   {IsLoaded=function()return true end,GetShopRewards=function()return {Claims={},VIPDailyDateUTC="",PotionExpiresUTC={}}end,
    ClaimShopReward=function(_,key)if key=="SecretPack"then secret+=1 end end},
   {HasShopPass=function()return false end,HasPremiumSpeed=function()return false end,RefreshShopPass=function()return true,"Verified"end},{})
  local p={Parent=game.Players}
  assert(not m.Prompt(p,"SecretPack"));m.Refresh(p)
  assert(prompts==0 and secret==0 and not m.CanUseSecret(p))
  fail=true;assert(not m.Prompt(p,"SecretPack"));m.Refresh(p)
  assert(prompts==0 and secret==0)
 end)
 test("isolated Config edits drive actual bundle grant and its description",function()
  local f=fixture();f.Passes.StarterPack=true
  local source=game.ReplicatedStorage.Config.ShopProductConfig.Source
  source=source:gsub('require%(script.Parent%.(%w+)%)',function(name)return 'require(game.ReplicatedStorage.Config.'..name..')'end)
  local clone=factory("ShopConfigFollowTest",source,"")()
  clone.Products.StarterPack.WinAmount=123
  f.Config.Get=clone.Get
  assert(f.Data.ClaimShopReward(f.Player,"StarterPack"))
  assert(f.Player:GetAttribute("Win")==123)
  assert(clone.Description("StarterPack"):find("123 Win",1,true))
  assert(cfg.Get("StarterPack").WinAmount==100)
 end)
 local strength=game.ServerScriptService.Services.StrengthManager.Source
 strength=strength:gsub('local PlayerData=require%b()','local PlayerData=TestData')
 strength=strength:gsub('local DumbbellService=require%b()','local DumbbellService=TestDumbbell')
 strength=strength:gsub('local ItemService=require%b()','local ItemService=TestItem')
 strength=strength:gsub('local AuraService=require%b()','local AuraService=TestAura')
 strength=strength:gsub('local PotionService=require%b()','local PotionService=TestPotion')
 strength=strength:gsub('local ShopPasses=require%b()','local ShopPasses=TestPass')
 strength=strength:gsub('or not player:IsA%("Player"%)','')
 local makeStrength=factory("ShopStrengthTestFactory",strength,"TestData,TestDumbbell,TestItem,TestAura,TestPotion,TestPass")
 test("actual StrengthManager applies VIP x1.1 once to Walk and Training",function()
  local p=Instance.new("Folder");p:SetAttribute("Strength",0);p:SetAttribute("RebirthCount",0)
  local vip=false
  local m=makeStrength({SetCurrentStrength=function()end,RecordStrengthGain=function()end},
   {GetStrengthBonus=function()return 5 end},{GetProteinBonus=function()return 3 end},{GetStrengthBonus=function()return 2 end},
   {GetStrengthMultiplier=function()return 1.5 end},{GetVIPStrengthMultiplier=function()return vip and cfg.Get("VIP").StrengthMultiplier or 1 end})
  local walk=m.AddStrength(p,1);m.SetStrength(p,0);vip=true
  local vipWalk=m.AddStrength(p,1);assert(math.abs(vipWalk-walk*1.1)<1e-8)
  m.SetStrength(p,0);vip=false;local train=m.AddStrength(p,1,1,4)
  m.SetStrength(p,0);vip=true;local vipTrain=m.AddStrength(p,1,1,4)
  assert(math.abs(vipTrain-train*1.1)<1e-8)
  m.SetStrength(p,0);assert(m.AddRewardStrength(p,10)==10);p:Destroy()
 end)
 for _,m in ipairs(modules)do m:Destroy()end
 return results
end
return T
