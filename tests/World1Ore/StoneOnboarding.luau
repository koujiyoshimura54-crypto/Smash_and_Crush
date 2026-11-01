-- Run only in a Studio session whose persistence dependencies are replaced by Memory.
local RS=game.ReplicatedStorage
local C=require(RS.Config.TimeRewardConfig)
local First=require(RS.Modules.FirstStage1RewardState)
local Inventory=require(RS.Modules.ForgeInventory)
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local ids={"StoneIntro01","Reward01","Reward02","Reward03","Reward04","Reward05","Reward07","Reward08","Reward09"}
local times={60,120,300,420,600,900,1200,1800,2700}
for i,r in ipairs(C.Rewards) do
 check(r.Id==ids[i] and r.RequiredSeconds==times[i] and r.ClaimOrder==i,"slot identity and time "..i)
 check(C.GetCardName(r)==string.format("Reward%02d",i),"authored card "..i)
end
check(#C.Rewards==9 and C.Get("Reward06")==nil,"retired strength reward; nine slots")
check(C.Get("StoneIntro01").Amount==1 and C.GetImage(C.Rewards[1])=="rbxassetid://131452437678251","real Stone catalogue art")
check(C.GetPotionDuration("Training",C.Get("Reward02"))==60,"short Training potion retained")
check(C.GetPotionDuration("Training",C.Get("Reward07"))==180,"long Training potion retained")
check(C.GetPotionDuration("Strength",C.Get("Reward04"))==180 and C.Potions.Strength.Multiplier==1.5,"Strength potion retained")
-- Every legacy claim combination keeps the same content claimed, independently of slot.
for mask=0,511 do
 local claimed={}
 for i=1,9 do if bit32.band(mask,bit32.lshift(1,i-1))~=0 then claimed[string.format("Reward%02d",i)]=true end end
 for _,r in ipairs(C.Rewards) do
  local old=tonumber(r.Id:match("^Reward(%d+)$"))
  check((claimed[r.Id]==true)==(old~=nil and bit32.band(mask,bit32.lshift(1,old-1))~=0),"claim identity mapping")
 end
 check(not claimed.StoneIntro01,"new Stone has independent claim")
end
local fresh=First.Normalize(nil,true)
check(not fresh.Consumed and First.Normalize(nil,false).Consumed,"new only; legacy excluded")
local function data()
 return {OwnedOres={},OwnedDumbbells={},Win=0,ForgeJournal={Sequence=0},FirstStage1Reward=First.Normalize(nil,true)}
end
local a,b=data(),data()
local op={Action="FirstStage1Defeat",Id="first-a",Sequence=1,Signature="FirstStage1Defeat|ORE_001",ResultId="ORE_001"}
local granted=assert(Inventory.Apply(a,op))
check(granted.OwnedOres.ORE_001==1 and granted.FirstStage1Reward.Consumed,"one Stone and flag together")
check(not a.FirstStage1Reward.Consumed and not b.FirstStage1Reward.Consumed,"inputs and second player independent")
local duplicate,reason=Inventory.Apply(granted,op)
check(duplicate==granted and reason=="AlreadyApplied" and duplicate.OwnedOres.ORE_001==1,"duplicate first defeat")
op.Sequence=2;op.Id="second-a"
check(Inventory.Apply(granted,op)==nil,"lifetime guarantee cannot repeat")
op.Sequence=1;op.Id="full-b";op.ResultId="";op.Signature="FirstStage1Defeat|"
local discarded=assert(Inventory.Apply(b,op))
check(discarded.FirstStage1Reward.Consumed and not discarded.FirstStage1Reward.OreGranted and next(discarded.OwnedOres)==nil,"full bag consumes guarantee without extra loot")
check(First.Merge(granted.FirstStage1Reward,fresh).Consumed,"save merge cannot restore eligibility")
local reloaded=game.HttpService:JSONDecode(game.HttpService:JSONEncode(granted))
check(First.Normalize(reloaded.FirstStage1Reward,false).Consumed and reloaded.OwnedOres.ORE_001==1,"serialized roundtrip")
return {Passed=checks,Kind="Pure modules and serialized tables; no production persistence"}
