local C={
 DefaultSpeed=24,
 Order={"Speed1","Premium"},
 Speed1={Name="Speed Boost",WalkSpeed=32,PriceType="Win",PriceWin=500,ImageAssetId=130304640405359},
 Premium={Name="Premium Speed",WalkSpeed=40,PriceType="GamePass",FallbackPrice=100,GamePassId=1979583273,ImageAssetId=130974760210275},
}
C.Premium.PriceRobux=C.Premium.FallbackPrice -- Legacy compatibility alias, not an independent value.
table.freeze(C.Speed1);table.freeze(C.Premium);table.freeze(C.Order)
return table.freeze(C)

