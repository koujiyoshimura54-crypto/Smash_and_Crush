-- Manual deterministic contract tests. Production DataStores are never used.
local T={}
function T.Run()
 assert(game:GetService("RunService"):IsStudio(),"Studio only")
 local source=game.ServerScriptService.Services.PlayerDataService.Source
 source=source:gsub('local DSS=game:GetService%("DataStoreService"%)','local DSS=TestDSS')
 source=source:gsub('require%(game.ServerScriptService.Config:WaitForChild%("DataStoreConfig"%)%)','require(game.ServerScriptService.Config.DataStoreConfig)')
 source=source:gsub('require%(game.ServerScriptService.Services.StrengthManager%)','TestStrength')
 source=source:gsub('require%(game.ServerScriptService.Services.PotionService%)','TestPotion')
 local factory=Instance.new("ModuleScript")
 factory.Name="Phase2DataFactoryRuntime"
 factory.Source="return function(TestDSS,TestStrength,TestPotion) "..source.." end"
 factory.Parent=game.ServerStorage
 local make=require(factory)
 local results={}
 local function test(name,fn)
  local ok,err=pcall(fn)
  results[#results+1]={Name=name,Pass=ok,Error=not ok and tostring(err) or nil}
 end
 local function copy(v) if type(v)~="table" then return v end local r={} for k,x in pairs(v) do r[k]=copy(x) end return r end
 local function fixture()
  local f={Records={},Meta={},PotionCalls=0,PotionSeconds=0,Names={}}
  local store={}
  function store:GetAsync(k) return copy(f.Records[k]) end
  function store:UpdateAsync(k,fn)
   local meta=copy(f.Meta[k] or {})
   local info={GetUserIds=function() return {} end,GetMetadata=function() return copy(meta) end}
   local value,users,nextMeta=fn(copy(f.Records[k]),info)
   if value then f.Records[k]=copy(value);f.Meta[k]=copy(nextMeta or meta) end
   if f.Hook then local hook=f.Hook;f.Hook=nil;hook() end
   if f.FailAfterCommit then f.FailAfterCommit=false;error("Injected ambiguous completion") end
   return copy(f.Records[k]),info and {GetMetadata=function() return copy(f.Meta[k] or {}) end,GetUserIds=function() return {} end}
  end
  local dss={GetDataStore=function(_,name) table.insert(f.Names,name);return store end,GetOrderedDataStore=function(_,name) table.insert(f.Names,name);return {SetAsync=function()end} end}
  local attributes={Strength=0,Win=0}
  local p={UserId=987654321,Name="Phase2Fake",Parent=game.Players}
  function p:SetAttribute(k,v) attributes[k]=v end
  function p:GetAttribute(k) return attributes[k] end
  local strength={AddRewardStrength=function(_,gain) attributes.Strength+=gain;f.Data.SetCurrentStrength(p,attributes.Strength) end}
  local potions={Activate=function(_,id,rewardId)
   f.PotionCalls+=1
   local cfg=require(game.ReplicatedStorage.Config.TimeRewardConfig)
   f.PotionSeconds+=(rewardId and cfg.Get(rewardId).PotionDurationSeconds) or cfg.Potions[id].DurationSeconds
  end}
  f.Data=make(dss,strength,potions);f.Player=p
  assert(f.Data.Load(p));return f
 end
 test("save preserves concurrent training and Win changes and remains dirty",function()
  local f=fixture();local d,p=f.Data,f.Player
  p:SetAttribute("Strength",100);d.SetCurrentStrength(p,100);d.SetWin(p,50)
  f.Hook=function() p:SetAttribute("Strength",107);d.SetCurrentStrength(p,107);d.RecordStrengthGain(p,7);d.SetWin(p,63) end
  assert(d.Save(p));assert(p:GetAttribute("Strength")==107 and p:GetAttribute("Win")==63)
  assert(d.Get(p).Dirty==true);assert(d.Save(p))
  d.Release(p);assert(d.Load(p));assert(p:GetAttribute("Strength")==107 and p:GetAttribute("Win")==63)
 end)
 test("save includes Trophy-style Attribute credit without rollback",function()
  local f=fixture();local d,p=f.Data,f.Player
  d.SetWin(p,20)
  f.Hook=function() p:SetAttribute("Win",23);d.SetWin(p,p:GetAttribute("Win")) end
  assert(d.Save(p));assert(p:GetAttribute("Win")==23);assert(d.Get(p).Dirty);assert(d.Save(p))
  assert(f.Records.Player_987654321.Win==23)
 end)
 local cfg=require(game.ReplicatedStorage.Config.TimeRewardConfig)
 for _,id in ipairs({"Reward01","Reward02","Reward06","Reward09"}) do
  test(id.." concurrent resolver and ambiguous retry apply exactly once",function()
   local f=fixture();local d,p=f.Data,f.Player
   d.Get(p).Data.TimeRewards.ElapsedSeconds=100000
   local r=cfg.Get(id)
   local result={RewardType=r.RewardType,Amount=r.Amount,PotionId=r.PotionId}
   if r.RewardType=="Strength" then result.Amount=30 end
   local context={Id=id,Result=result}
   local blocked
   f.Hook=function() local ok,reason=d.ResolveItemMutation(p);blocked=not ok and reason=="InventorySavePending" end
   f.FailAfterCommit=true
   local ok,reason
   if r.RewardType=="ItemRoll" then ok,reason=d.ChangeItemCounts(p,{PROTEIN_COMMON_FIRE=r.Amount},context)
   else ok,reason=d.ClaimTimeReward(p,context) end
   assert(not ok and reason=="InventorySavePending");assert(blocked)
   assert(d.ResolveItemMutation(p))
   assert(not d.ResolveItemMutation(p))
   assert(d.GetTimeRewards(p).Claimed[id])
   if r.RewardType=="Win" then assert(p:GetAttribute("Win")==r.Amount)
   elseif r.RewardType=="Strength" then assert(p:GetAttribute("Strength")==30)
   elseif r.RewardType=="Potion" then assert(f.PotionCalls==1 and f.PotionSeconds==r.PotionDurationSeconds)
   else assert(d.Get(p).Data.OwnedItems.PROTEIN_COMMON_FIRE==r.Amount) end
   assert(d.Save(p));d.Release(p);assert(d.Load(p));assert(d.GetTimeRewards(p).Claimed[id])
  end)
 end
 test("all persistent store names are Studio isolated",function()
  local f=fixture();assert(f.Data.Save(f.Player))
  for _,name in ipairs(f.Names) do assert(name:sub(-7)=="_Studio",name) end
 end)

 test("save preserves a concurrent Win debit",function()
  local f=fixture();local d,p=f.Data,f.Player
  d.SetWin(p,100)
  f.Hook=function() d.SetWin(p,60) end
  assert(d.Save(p));assert(p:GetAttribute("Win")==60 and d.Get(p).Dirty)
  assert(d.Save(p));assert(f.Records.Player_987654321.Win==60)
 end)
 test("ordinary save preserves receipt metadata, item quantities and unknown schema fields",function()
  local f=fixture();local d,p=f.Data,f.Player
  f.Records.Player_987654321=copy(d.Get(p).Data)
  f.Records.Player_987654321.OwnedItems={PROTEIN_COMMON_FIRE=4}
  f.Records.Player_987654321.FutureField="preserve"
  f.Meta.Player_987654321={ItemMutationId="mutation",ItemReceiptId="receipt",ItemReceiptItem="PROTEIN_EPIC_FIRE",ItemReceiptSequence=9}
  assert(d.Save(p))
  assert(f.Records.Player_987654321.OwnedItems.PROTEIN_COMMON_FIRE==4)
  assert(f.Records.Player_987654321.FutureField=="preserve")
  assert(f.Meta.Player_987654321.ItemReceiptSequence==9 and f.Meta.Player_987654321.ItemMutationId=="mutation")
 end)
 test("a completed reset rejects a stale normal save",function()
  local f=fixture();local d,p=f.Data,f.Player
  d.SetWin(p,100)
  f.Records.Player_987654321=copy(d.Get(p).Data)
  f.Records.Player_987654321.ResetToken="new-reset"
  f.Records.Player_987654321.Win=0
  local ok,reason=d.Save(p)
  assert(not ok and reason=="SaveSupersededByReset")
  assert(f.Records.Player_987654321.Win==0 and f.Records.Player_987654321.ResetToken=="new-reset")
 end)

 factory:Destroy()
 return results
end
return T