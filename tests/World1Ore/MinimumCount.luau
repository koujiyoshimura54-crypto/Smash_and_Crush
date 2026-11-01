-- Focused pure-module regression; no PlayerData, Remote, or DataStore writes.
local RS=game.ReplicatedStorage
local Ore=require(RS.Config.OreConfig)
local Master=require(RS.Config.DumbbellItemMaster)
local Merge=require(RS.Modules.OreMerge)
local Inventory=require(RS.Modules.ForgeInventory)
local checks=0
local function check(ok,message) assert(ok,message);checks+=1 end
check(Merge.Minimum==2 and Merge.Maximum==5,"merge requires two through five units")
check(Merge.Evaluate({})==nil,"empty merge refused")
for _,ore in ipairs(Ore.GetAvailable()) do
 local one,reason=Merge.Evaluate({[ore.Id]=1},{[ore.Id]=10})
 check(one==nil and reason=="SelectAtLeastTwoOres","one ore refused regardless of points: "..ore.Id)
 local selected=assert(Merge.Selection({[ore.Id]=1},{[ore.Id]=10},false))
 check(selected.Count==1 and selected.Total==ore.Points,"single selection retains points")
 local sale=assert(Merge.Selection({[ore.Id]=1},{[ore.Id]=10},true))
 check(sale.Count==1 and sale.Total==ore.SellWin,"single ore sale remains valid")
 for n=2,5 do
  local preview=assert(Merge.Evaluate({[ore.Id]=n},{[ore.Id]=10}))
  local probability=0
  for _,outcome in ipairs(preview.Outcomes) do
   local item=assert(Master.Get(outcome.Id))
   check((item.WorldId or 1)==1 and outcome.Probability>0,"positive World1 outcome")
   probability+=outcome.Probability
  end
  check(preview.Count==n and preview.Total==n*ore.Points and math.abs(probability-1)<1e-10,"valid repeated units")
 end
 check(Merge.Evaluate({[ore.Id]=6},{[ore.Id]=10})==nil,"six units refused")
end
local mixed=assert(Merge.Evaluate({ORE_001=1,ORE_002=1},{ORE_001=1,ORE_002=1}))
check(mixed.Count==2 and mixed.Total==12,"two different ores accepted")
local two=assert(Merge.Evaluate({ORE_001=2},{ORE_001=2}))
check(two.Outcomes[1].Id=="NORMAL_01" and math.abs(two.Outcomes[1].Probability-2/3)<1e-10,"existing lower probability retained")
check(two.Outcomes[2].Id=="NORMAL_02" and math.abs(two.Outcomes[2].Probability-1/3)<1e-10,"existing upper probability retained")
check(Merge.Evaluate({ORE_001=2},{ORE_001=1})==nil,"owned quantity enforced")
check(Merge.Evaluate({ORE_001=1.5},{ORE_001=10})==nil,"fractional quantity refused")
check(Merge.Evaluate({ORE_001=1,ORE_017=1},{ORE_001=1,ORE_017=1})==nil,"reserved ore refused")
local original={OwnedOres={ORE_001=10},OwnedDumbbells={NORMAL_01=1},EquippedDumbbell="NORMAL_01",Win=7,ForgeJournal={Sequence=0}}
local op={Action="MergeOre",Materials={ORE_001=1},ResultId="NORMAL_01",Sequence=1,Id="minimum-count",Signature="minimum-count"}
local rejected,reason=Inventory.Apply(original,op)
check(rejected==nil and reason=="SelectAtLeastTwoOres","transaction refuses one ore")
check(original.OwnedOres.ORE_001==10 and original.OwnedDumbbells.NORMAL_01==1 and original.Win==7 and original.ForgeJournal.Sequence==0,"refusal consumes and grants nothing")
op.Materials={ORE_001=2}
local merged=assert(Inventory.Apply(original,op))
check(merged.OwnedOres.ORE_001==8 and merged.OwnedDumbbells.NORMAL_01==2 and merged.Win==7,"two materials consume and grant exactly once")
local retry,why=Inventory.Apply(merged,op)
check(why=="AlreadyApplied" and retry.OwnedOres.ORE_001==8 and retry.OwnedDumbbells.NORMAL_01==2,"retry does not duplicate grant")
local sale={Action="SellOre",Materials={ORE_001=1},ResultId="",Sequence=1,Id="single-sale",Signature="single-sale"}
local sold=assert(Inventory.Apply(original,sale))
check(sold.OwnedOres.ORE_001==9 and sold.Win==8 and sold.OwnedDumbbells.NORMAL_01==1,"single sale consumes one and credits existing Win price")
sale.Materials={ORE_001=6}
sold=assert(Inventory.Apply(original,sale))
check(sold.OwnedOres.ORE_001==4 and sold.Win==13,"sale retains no five-unit limit")
-- An already committed historical one-ore operation remains idempotent after this change.
local historical={OwnedOres={ORE_001=9},OwnedDumbbells={NORMAL_01=2},Win=7,ForgeJournal={Sequence=1,Id="old-one",Signature="old-one",ResultId="NORMAL_01"}}
op.Id="old-one";op.Signature="old-one";op.Materials={ORE_001=1}
local old,oldReason=Inventory.Apply(historical,op)
check(old==historical and oldReason=="AlreadyApplied","historical completed operations remain acknowledged without new grants")
return {Passed=checks,Kind="Pure module regression; not Studio Play"}
