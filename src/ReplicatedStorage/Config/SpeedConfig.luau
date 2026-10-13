local C={
 DefaultSpeed=24,
 Order={"Speed1","Premium"},
 MaxUpgradeStage=4,
 UpgradeSpeeds={24,28,32,36,40},
 Upgrades={
  [0]={NextStage=1,NextSpeed=28,PriceWin=100},
  [1]={NextStage=2,NextSpeed=32,PriceWin=200},
  [2]={NextStage=3,NextSpeed=36,PriceWin=300},
  [3]={NextStage=4,NextSpeed=40,PriceWin=400},
 },
 Speed1={Name="Speed Boost",WalkSpeed=40,PriceType="Win",PriceWin=600,ImageAssetId=130304640405359},
 Premium={Name="Premium Speed",WalkSpeed=50,PriceType="GamePass",FallbackPrice=100,GamePassId=1979583273,ImageAssetId=130974760210275},
}
function C.NormalizeStage(value,owned)
 if value==nil then value=0 end
 if typeof(value)~="number" or value~=value or value%1~=0 or value<0 or value>C.MaxUpgradeStage then
  return nil,"Invalid SpeedUpgradeStage"
 end
 return owned and owned.Speed1==true and C.MaxUpgradeStage or value
end
function C.UpgradeSpeed(stage)
 return C.UpgradeSpeeds[stage+1]
end
for _,tier in C.Upgrades do table.freeze(tier) end
table.freeze(C.Upgrades);table.freeze(C.UpgradeSpeeds)
C.Premium.PriceRobux=C.Premium.FallbackPrice -- Legacy compatibility alias, not an independent value.
table.freeze(C.Speed1);table.freeze(C.Premium);table.freeze(C.Order)
return table.freeze(C)
