local RS=game.ReplicatedStorage
local Ore=require(RS.Config.OreConfig)
local Master=require(RS.Config.DumbbellItemMaster)
local Merge=require(RS.Modules.OreMerge)
local Inventory=require(RS.Modules.ForgeInventory)
local Counts=require(RS.Modules.InventoryCounts)
local checks=0
local function check(ok,message) assert(ok,message);checks+=1 end
local prices={7,20,50,130,250,500,1000,1500,2500,4500,8000,13000}
local effects={3,5,9,15,25,45,75,120,180,280,450,700}
local points={5,20,40,70,110,160,220,290,370,450,530,650}
local sales={3,10,25,65,125,250,500,750,1250,2250,4000,6500}
for i=1,12 do
 local d=Master.Get(string.format("NORMAL_%02d",i))
 check(d.PriceWin==prices[i],"buy "..i);check(d.StrengthBonus==effects[i],"effect "..i)
 check(d.MergePoints==points[i],"points "..i);check(d.SellWin==sales[i],"sale "..i)
end
check(#Ore.GetAvailable()==16,"available")
check(Ore.Get("ORE_001").Image=="rbxassetid://131452437678251","Stone image")
for i=1,20 do local o=Ore.Get(string.format("ORE_%03d",i))
 check(o.RarityId==string.format("RARITY_%02d",math.ceil(i/5)),"rarity")
 if i>16 then check(not o.Available and o.SellWin==nil,"reserved") end
end
for stage,pool in ipairs(Ore.DropPools) do
 local sum=0
 for _,row in ipairs(pool) do
  check(Ore.Roll(stage,(sum+.001)/100)==row.Id,"pool lower boundary")
  sum+=row.Weight
  check(Ore.Roll(stage,(sum-.001)/100)==row.Id,"pool upper boundary")
  check(row.Id~="ORE_016" or stage>=9,"Spark unlock")
 end
 check(sum==100,"pool total")
end
local examples={
 {0,5,500,{{"NORMAL_10",.375},{"NORMAL_11",.625}}},
 {1,4,530,{{"NORMAL_11",1}}},
 {2,3,560,{{"NORMAL_11",.75},{"NORMAL_12",.25}}},
 {3,2,590,{{"NORMAL_11",.5},{"NORMAL_12",.5}}},
 {4,1,620,{{"NORMAL_11",.25},{"NORMAL_12",.75}}},
 {5,0,650,{{"NORMAL_12",1}}},
}
for _,case in ipairs(examples) do
 local materials={};if case[1]>0 then materials.ORE_016=case[1] end;if case[2]>0 then materials.ORE_015=case[2] end
 local p=assert(Merge.Evaluate(materials))
 check(p.Total==case[3] and p.Count==5,"example total")
 check(#p.Outcomes==#case[4],"example count")
 for i,row in ipairs(case[4]) do check(p.Outcomes[i].Id==row[1] and math.abs(p.Outcomes[i].Probability-row[2])<1e-10,"example probability") end
end
-- Find attainable boundary totals with at most five real ores; test every threshold.
local reachable={[0]={}}
for _=1,5 do
 local add={}
 for total,selection in pairs(reachable) do for _,ore in ipairs(Ore.GetAvailable()) do
  if not reachable[total+ore.Points] then local n=table.clone(selection);n[ore.Id]=(n[ore.Id] or 0)+1;add[total+ore.Points]=n end
 end end
 for total,selection in pairs(add) do if not reachable[total] then reachable[total]=selection end end
end
for i,threshold in ipairs(points) do
 local p=assert(Merge.Evaluate(assert(reachable[threshold])))
 check(#p.Outcomes==1 and p.Outcomes[1].Id==string.format("NORMAL_%02d",i) and p.Outcomes[1].Probability==1,"exact threshold "..i)
end
for _,bad in ipairs({{}, {ORE_001=6},{ORE_017=1},{ORE_020=1},{ORE_001=-1},{ORE_001=1.5},{ORE_001=true},{ORE_001=math.huge},{NOT_AN_ORE=1}}) do
 check(Merge.Evaluate(bad)==nil,"invalid material")
end
check(Merge.Evaluate({ORE_001=2},{ORE_001=1})==nil,"insufficient")
local sell=assert(Merge.Selection({ORE_016=50},{ORE_016=50},true))
check(sell.Count==50 and sell.Total==3250,"sale has no five cap")
check(Counts.Normalize({NORMAL_01=true,NORMAL_02=3}).NORMAL_01==1,"legacy true")
check(Counts.Normalize(Counts.Normalize({NORMAL_01=true})).NORMAL_01==1,"idempotent normalize")
local original={OwnedDumbbells={NORMAL_01=true},OwnedOres={ORE_016=5},EquippedDumbbell="NORMAL_01",Win=0,ForgeJournal={Sequence=0}}
local op={Action="MergeOre",Materials={ORE_016=5},ResultId="NORMAL_12",Sequence=1,Id="test-merge",Signature="test"}
local nextData,reason=Inventory.Apply(original,op)
check(nextData and reason=="Applied","merge applies")
check(original.OwnedOres.ORE_016==5 and original.OwnedDumbbells.NORMAL_12==nil,"input not mutated")
check(nextData.OwnedOres.ORE_016==nil and nextData.OwnedDumbbells.NORMAL_12==1,"consume and grant")
local retry,retryReason=Inventory.Apply(nextData,op)
check(retryReason=="AlreadyApplied" and retry.OwnedDumbbells.NORMAL_12==1,"duplicate request")
local bad=table.clone(op);bad.Id="different"
check(Inventory.Apply(nextData,bad)==nil,"replayed sequence")
local sale={Action="SellDumbbell",ItemId="NORMAL_01",Count=1,Id="sell",Sequence=2,Signature="sell",ResultId=""}
check(Inventory.Apply(nextData,sale)==nil,"equipped last copy")
nextData.OwnedDumbbells.NORMAL_01=3;sale.Count=2
local sold=assert(Inventory.Apply(nextData,sale))
check(sold.OwnedDumbbells.NORMAL_01==1 and sold.Win==6,"sell extra equipped copies")
sale.Sequence=3;sale.ItemId="NORMAL_12";sale.Count=2
check(Inventory.Apply(sold,sale)==nil,"over-sale")
local purchase={Action="BuyDumbbell",ItemId="NORMAL_02",Sequence=3,Id="buy",Signature="buy",ResultId="NORMAL_02"}
check(Inventory.Apply(sold,purchase)==nil,"insufficient buy")
sold.Win=20
local bought=assert(Inventory.Apply(sold,purchase))
check(bought.Win==0 and bought.OwnedDumbbells.NORMAL_02==1,"exact buy cost")
purchase.Sequence=4;purchase.Id="buy-twice"
check(Inventory.Apply(bought,purchase)==nil,"owned purchase refusal")
return game.HttpService:JSONEncode({Passed=checks,Kind="Native Luau pure/config simulation; no UI or production datastore",Examples={500,530,560,590,620,650}})
