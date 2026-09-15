-- Shop catalogue: benefit definitions and presentation share this authority.
local Speed=require(script.Parent.SpeedConfig)
local Items=require(script.Parent.ItemMaster)
local Daily=require(script.Parent.DailyRewardConfig)
local Potions=require(script.Parent.TimeRewardConfig)
local C={}
C.Order={"StarterPack","SecretPack","VIP","Speed_Premium","Win"}
C.Products={
 StarterPack={Name="Starter Pack",Kind="GamePass",PassId=1976228285,CardName="Card02_StarterPack",Order=1,Once=true,
  Icon="rbxassetid://106494459783367",WinAmount=100,Potions={Strength=1,Training=1}},
 SecretPack={Name="Secret Pack",Kind="GamePass",PassId=1977086287,CardName="Card01_SecretPack",Order=2,Once=true,
  Icon="rbxassetid://113527186215193",WinAmount=500,AuraId="Secret",RandomItem=true,
  RarityWeights={Epic=Items.DropWeights[Items.RarityRank.Epic],Legendary=Items.DropWeights[Items.RarityRank.Legendary]}},
 VIP={Name="VIP",Kind="GamePass",PassId=1977128286,CardName="Card03_VIP",Order=3,Featured=true,
  Icon="rbxassetid://122420734012429",StrengthMultiplier=1.10,AuraId="VIP",Tag="VIP",
  -- One extra claim per UTC day, including after normal Day 7 is complete.
  DailyBonus={RewardType="Win",Amount=Daily.Get(1).Amount}},
 Speed_Premium={Name=Speed.Premium.Name,Kind="PremiumSpeed",PassId=Speed.Premium.GamePassId,
  CardName="CardSpeedPremium",Order=4,Featured=true,Icon="rbxassetid://"..Speed.Premium.ImageAssetId},
 Win={Name="Win",Kind="Navigation",CardName="CardWin",Order=5,Featured=true,Icon="rbxassetid://106494459783367",ActionLabel="BUY WIN"},
}
C.Auras={
 VIP={Id="VIP",Name="VIP Aura",Icon=C.Products.VIP.Icon,StrengthBonus=0,PurchaseType="Entitlement",Entitlement="VIP",Tint=Color3.fromRGB(255,211,75)},
 Secret={Id="Secret",Name="Secret Aura",Icon=C.Products.SecretPack.Icon,StrengthBonus=0,PurchaseType="Entitlement",Entitlement="SecretPack",Tint=Color3.fromRGB(175,94,255)},
}
-- Fill ProductId and Amount after confirming the product's intended grant.
-- Unconfigured products cannot prompt or grant. Existing unused product:
C.UnconfirmedWinProductId=3711615649 -- Marketplace name: 2WinIcon; amount not verified.
C.WinProducts={}
function C.Get(id) return C.Products[id] end
function C.GetWinProduct(id) for _,p in ipairs(C.WinProducts) do if p.Key==id then return p end end end
function C.ForWinProduct(productId)
 for _,p in ipairs(C.WinProducts) do
  if p.ProductId==productId and typeof(productId)=="number" and productId>0
   and typeof(p.Amount)=="number" and p.Amount>0 and p.Amount%1==0 then return p end
 end
end
function C.ForPass(passId)
 for key,p in pairs(C.Products) do if p.PassId==passId and p.Kind=="GamePass" then return key,p end end
end
function C.GetSecretOutcomes()
 local out={} local weights=C.Products.SecretPack.RarityWeights
 local total=0 for _,weight in pairs(weights) do total+=weight end
 for _,rarity in ipairs(Items.Rarities) do
  if (weights[rarity] or 0)>0 then
   local pool={} for _,item in pairs(Items.GetAll()) do if item.Rarity==rarity then table.insert(pool,item) end end
   table.sort(pool,function(a,b)return a.ItemId<b.ItemId end)
   for _,item in ipairs(pool) do table.insert(out,{ItemId=item.ItemId,Name=item.DisplayName or item.ItemId,Rarity=rarity,Weight=weights[rarity]/#pool,Percent=100*weights[rarity]/total/#pool}) end
  end
 end
 return out,total
end
function C.RollSecret(random)
 local outcomes,total=C.GetSecretOutcomes()
 local roll=random:NextNumber(0,total)
 for _,outcome in ipairs(outcomes) do roll-=outcome.Weight;if roll<=0 then return outcome.ItemId end end
 return outcomes[#outcomes].ItemId
end
function C.Description(key)
 local p=C.Get(key)
 if key=="StarterPack" then return p.WinAmount.." Win • "..Potions.Potions.Strength.Name.." ×"..p.Potions.Strength.." • "..Potions.Potions.Training.Name.." ×"..p.Potions.Training.."\nPotions activate immediately ("..Potions.Potions.Strength.DurationSeconds.."s / "..Potions.Potions.Training.DurationSeconds.."s)" end
 if key=="SecretPack" then return p.WinAmount.." Win • "..C.Auras[p.AuraId].Name.." • Epic+ Item ×1\nNo MISS • View item odds before purchase" end
 if key=="VIP" then return ("Training / Walk +%g%% • VIP Aura • VIP tag\nDaily bonus: +%g Win"):format((p.StrengthMultiplier-1)*100,p.DailyBonus.Amount) end
 if key=="Speed_Premium" then return tostring(Speed.Premium.WalkSpeed).." WalkSpeed" end
 return "Purchase Win with Robux"
end
return C

