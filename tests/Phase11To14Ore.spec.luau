-- Native pure checks against the current live definitions; no data services.
return function(RS)
 local Ore=require(RS.Config.OreConfig)
 local Merge=require(RS.Modules.OreMerge)
 local Forge=require(RS.Modules.ForgeInventory)
 local checks=0
 local function check(v,s)assert(v,s);checks+=1 end
 local owned,materials={},{}
 local total=0
 for i=1,32 do
  local id=string.format("ORE_%03d",i);local o=Ore.Get(id)
  local rank=i<=10 and 1 or i<=20 and 2 or i<=30 and 3 or 4
  check(o.Rarity==({"Common","Uncommon","Rare","Super Rare"})[rank],id.." rarity")
  check(o.RarityId==string.format("RARITY_%02d",rank),id.." rank")
  owned[id]=2;materials[id]=1;total+=o.SellWin
  local base={OwnedOres={[id]=2},OwnedDumbbells={},Win=0,ForgeJournal={Sequence=0}}
  local op={Action="SellOre",Materials={[id]=1},Sequence=1,Id=id,Signature=id,ResultId=""}
  local sold=assert(Forge.Apply(base,op))
  check(sold.Win==o.SellWin and sold.OwnedOres[id]==1,id.." sale")
  local again,why=Forge.Apply(sold,op);check(again==sold and why=="AlreadyApplied",id.." replay")
 end
 check(#Ore.GetAvailable()==32,"32 definitions")
 check(Merge.Selection(materials,owned,true).Total==4190 and total==4190,"all sale prices unchanged")
 for _,world2 in {false,true}do
  for _,selection in {{ORE_001=2},{ORE_016=5},{ORE_031=4,ORE_026=1},{ORE_032=5}}do
   local p=assert(Merge.Evaluate(selection,nil,world2));local sum=0
   for _,out in p.Outcomes do sum+=out.Probability end
   check(math.abs(sum-1)<1e-12,"probabilities")
   local base={OwnedOres=table.clone(selection),OwnedDumbbells={},Win=123,ForgeJournal={Sequence=0}}
   local op={Action="MergeOre",Materials=selection,World2Unlocked=world2,ResultId=p.Outcomes[1].Id,Sequence=1,Id="merge",Signature="merge"}
   local result=assert(Forge.Apply(base,op))
   check(not next(result.OwnedOres) and result.OwnedDumbbells[op.ResultId]==1 and result.Win==123,"merge consumes/grants no fee")
   check(select(2,Forge.Apply(result,op))=="AlreadyApplied","merge replay")
  end
 end
 check(Merge.Evaluate({ORE_001=1})==nil,"one rejected")
 check(Merge.Evaluate({ORE_001=6})==nil,"six rejected")
 return {Passed=checks}
end
