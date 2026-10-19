-- Temporary World1 Play-debug Trophy rewards. Pass multipliers stay server-owned.
local Config={}
Config.Rewards=table.freeze({1,3,7,15,30,50,75,150,500,1000})
local World2=require(script.Parent.World2GameplayConfig)
function Config.GetBaseReward(stage,worldId)
 if worldId==2 then local row=World2.Stages[stage];return row and row.WinReward end
 return Config.Rewards[stage]
end
return table.freeze(Config)
