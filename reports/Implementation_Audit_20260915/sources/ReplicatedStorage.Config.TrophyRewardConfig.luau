-- Temporary World1 Play-debug Trophy rewards. Pass multipliers stay server-owned.
local Config={}
Config.Rewards=table.freeze({1,3,5,10,30,75,150,300,750,1000})
function Config.GetBaseReward(stage) return Config.Rewards[stage] end
return table.freeze(Config)

