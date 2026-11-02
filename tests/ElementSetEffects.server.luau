-- Native server QA; install only with the memory DataStore/Badge adapter.
-- No Marketplace prompts or live save data. All fixtures die with the Play session.
return function(player)
 local RS=game.ReplicatedStorage
 local Services=game.ServerScriptService.Services
 local Data=require(Services.PlayerDataService)
 local Item=require(Services.ItemService)
 local Strength=require(Services.StrengthManager)
 local Reference=require(Services.StrengthReference)
 local Set=require(RS.Modules.ElementSetBonus)
 local Master=require(RS.Config.ItemMaster)
 local Calc=require(RS.Modules.StrengthCalculation)
 local Config=require(RS.Config.StrengthRewardConfig)
 local Rewards=require(Services.StrengthRewardState)
 local Boss=require(game.ServerScriptService.World.BossCombatService)
 local session=assert(Data.Get(player));assert(session.Loaded)
 local d=session.Data
 local checks,examples={},{}
 local function near(actual,expected,name)
  assert(type(actual)=="number" and math.abs(actual-expected)<=1e-9*math.max(1,math.abs(expected)),
   name..": "..tostring(actual).." ~= "..tostring(expected))
  checks[#checks+1]=name
 end
 local function fixture(equipment,extras)
  d.OwnedItems={};d.EquippedItems={Protein="",Glove="",TrainingBelt=""}
  for _,id in pairs(equipment) do if id~="" then d.OwnedItems[id]=1 end end
  for id,count in pairs(extras or {}) do d.OwnedItems[id]=count end
  for _,id in pairs(equipment) do if id~="" then assert(Item.EquipItem(player,id)) end end
 end
 local function id(kind,rarity,element,world) return Master.Id(kind,rarity,element,world) end
 local function trio(rarity,element,world)
  local out={} for _,kind in ipairs(Master.Kinds) do out[kind]=id(kind,rarity,element,world) end return out
 end
 Data.SetAutoTapEnabled(player,false)
 d.RebirthCount=0;player:SetAttribute("RebirthCount",0)
 d.EquippedDumbbell="";d.EquippedAura="";d.World2Visited=false;d.HighestUnlockedWorld=1
 -- Real current config, all ten ranks; mixed rarities still form sets.
 for world=1,2 do for _,rarity in ipairs(Master.Rarities) do
  local equipment=trio(rarity,"Fire",world);fixture(equipment)
  local effective=Item.GetEffectiveEffects(player)
  for kind,itemId in pairs(equipment) do near(effective[kind],Set.GetBaseEffect(Master.Get(itemId))*1.5,world..rarity..kind) end
 end end
 local set={Protein=id("Protein","Uncommon","Fire"),Glove=id("Glove","Common","Fire"),TrainingBelt=id("TrainingBelt","Common","Fire")}
 local ice=id("Glove","Uncommon","Ice")
 fixture(set,{[ice]=1})
 near(Item.GetProteinBonus(player),22.5,"Protein effective")
 near(Item.GetGloveBossDamageBonus(player),.075,"Glove bonus only")
 near(Item.GetBeltTreadmillBonus(player),.375,"Fractional Belt")
 local function gain(multiplier,name)
  d.Level=100;d.LevelProgress=0;player:SetAttribute("Level",100);player:SetAttribute("LevelProgress",0)
  assert(Strength.SetStrength(player,1000))
  local amount=assert(Strength.AddStrength(player,1,1,multiplier))-1000
  near(d.LevelProgress,amount,name.." LevelProgress")
  return amount
 end
 local expected=(1+22.5)*(2+.375)
 near(gain(2+Item.GetBeltTreadmillBonus(player),"Treadmill"),expected,"Actual training delta")
 near(gain(nil,"Walk"),23.5,"Walking excludes Belt and Dumbbell")
 examples.Training={BeforeOldSet=(1+15)*(2+.25)*1.5,After=expected,Belt=.375}
 -- The real Boss HP mutation, preserving encounter Strength while reacting to equipment.
 for world=1,2 do
  local combat=Boss.ForWorld(world);combat.Reset(player)
  assert(Strength.SetStrength(player,100))
  local encounter=combat.Begin(player,nil,1);local before=encounter.HP
  combat.Attack(player);near(before-encounter.HP,107.5,"World"..world.." Boss damage")
  assert(Item.EquipItem(player,ice))
  before=encounter.HP;combat.Attack(player)
  near(before-encounter.HP,110,"World"..world.." changed Glove during encounter")
  near(Item.GetProteinBonus(player),15,"Set removed immediately")
  assert(Item.EquipItem(player,set.Glove));combat.Reset(player)
 end
 -- Current Stage01 route uses the same effect getter.
 local inputs=require(game.ServerScriptService.MergeToForge.BossCombatInputs)
 local stage=require(game.ServerScriptService.MergeToForge.BossCombatService)
 inputs.BindItemService(Item);stage.Reset(player)
 local encounter=stage.Begin(player,nil);encounter.BattleStartStrength=100;encounter.HP=1000
 local _,_,dealt=stage.Attack(player);near(dealt,107.5,"Stage01 Boss damage")
 assert(Item.EquipItem(player,ice));local _,_,changedDamage=stage.Attack(player)
 near(changedDamage,110,"Stage01 live set removal");stage.Reset(player)
 for i=1,4 do
  assert(Item.EquipItem(player,set.Glove));near(Item.GetBeltTreadmillBonus(player),.375,"Swap set "..i)
  assert(Item.EquipItem(player,ice));near(Item.GetBeltTreadmillBonus(player),.25,"Swap unset "..i)
 end
 assert(Item.EquipBestItems(player))
 assert(d.EquippedItems.Glove==set.Glove,"Best must choose weaker glove to complete set")
 checks[#checks+1]="Best Equip prefers set training over standalone Glove"
 examples.BestEquip={RejectedGlove=ice,SelectedGlove=set.Glove,EffectiveGlove=Item.GetGloveBossDamageBonus(player)}
 local components,candidates=Reference.GetContext(player,false)
 local rate,selected=Reference.Get(player)
 local c=components[selected.World]
 near(rate,(1+c.Dumbbell+c.Aura+22.5)*(selected.Multiplier+.375)*c.Rebirth*c.VIP*c.Pet/.5,"Reward reference no old multiplier")
 examples.Reference={Rate=rate,Treadmill=selected.Name,Multiplier=selected.Multiplier}
 near(Calc.Gain(1,1,{Dumbbell=10,Aura=20,Protein=22.5,Rebirth=2,VIP=1.1,Pet=3},2.375),
  (1+10+20+22.5)*2.375*2*1.1*3,"Non Item bonuses not set multiplied")
 -- All full sets equal: preserve current IDs, not alphabetical Fire.
 local current=trio("Common","Ice");local extras={}
 for _,v in pairs(trio("Common","Fire")) do extras[v]=17 end
 fixture(current,extras);local ok,reason=Item.EquipBestItems(player)
 assert(ok and reason=="AlreadyBestEquipped");for k,v in pairs(current) do assert(d.EquippedItems[k]==v) end
 checks[#checks+1]="Equal scores preserve current, duplicate units collapsed"
 fixture({Protein=set.Protein,Glove=ice,TrainingBelt=id("TrainingBelt","Common","Electric")})
 assert(Item.EquipBestItems(player));near(Set.GetMultiplier(d.OwnedItems,d.EquippedItems),1,"No set possible")
 fixture({Protein=set.Protein,Glove=ice});assert(Item.EquipBestItems(player))
 assert(d.EquippedItems.TrainingBelt=="");checks[#checks+1]="Missing slot remains empty"
 fixture({Protein=set.Protein,Glove=id("Glove","Common","Electric"),TrainingBelt=id("TrainingBelt","Common","Ice")},
  {[id("Glove","Uncommon","Electric")]=1})
 assert(Item.EquipBestItems(player));assert(d.EquippedItems.Glove==id("Glove","Uncommon","Electric"))
 checks[#checks+1]="Equal training chooses higher Boss bonus"
 -- World2 effects are cross-world; arrival history controls reference facilities.
 local w2=trio("Rare","Electric",2);fixture(w2)
 d.World2Visited=true;d.HighestUnlockedWorld=2;d.RebirthCount=20;player:SetAttribute("RebirthCount",20)
 player:SetAttribute("CurrentWorld",2);local w2rate=Reference.Get(player)
 player:SetAttribute("CurrentWorld",1);near(Reference.Get(player),w2rate,"Return to World1 preserves W2 effects and facilities")
 near(Item.GetProteinBonus(player),1500,"W2 Protein")
 near(Item.GetGloveBossDamageBonus(player),1.425,"W2 Glove")
 near(Item.GetBeltTreadmillBonus(player),7.5,"W2 Belt")
 local before=Reference.Get(player);require(Services.PotionService).Activate(player,"Strength")
 require(Services.PotionService).Activate(player,"Training")
 near(Reference.Get(player),before,"Reward reference excludes temporary potions")
 local normal,cs=Reference.GetContext(player,true)
 assert(Reference.Calculate(normal,cs)>before);checks[#checks+1]="Best training snapshot includes fixed potions"
 -- Durable commitments keep their quoted amounts, independent of new equipment rate.
 local raw=Rewards.Acquire(nil,"old-login",100)
 raw=assert(Rewards.Apply(raw,{Action="Prepare",Id="fixed",ProductId=3724835102,Amount=1234.5}))
 raw=Rewards.Checkpoint(raw,"old-login",100,1000,true)
 raw=Rewards.Acquire(raw,"new-login",3700)
 near(raw.Rewards["new-login"].Amount,180000,"Offline fixed departure rate")
 local next,gained=Rewards.Apply(raw,{Action="Receipt",Id="receipt",PurchaseId="mock",ProductId=3724835102,IntentId="fixed"})
 near(gained,1234,"Pending pack quote preserved")
 local _,again=Rewards.Apply(next,{Action="Receipt",Id="receipt-again",PurchaseId="mock",ProductId=3724835102,IntentId="fixed"})
 near(again,0,"Existing receipt dedup preserved")
 for _,product in ipairs(Config.Products or Config.Packs) do
  near(Rewards.PackAmount(before,product.Seconds),math.floor(before*product.Seconds),"Pack seconds "..product.Seconds)
 end
 -- Native HUD receives the same authoritative state via the existing reply.
 game.ReplicatedStorage.Remotes.ItemEquipRequest:FireClient(player,{Success=true,Code="Equipped",
  State={Loaded=true,OwnedItems=table.clone(d.OwnedItems),EquippedItems=table.clone(d.EquippedItems)}})
 player:SetAttribute("World1Cleared",true)
 return {Checks=checks,Examples=examples,FinalEffects=Item.GetEffectiveEffects(player),Equipment=table.clone(d.EquippedItems)}
end

