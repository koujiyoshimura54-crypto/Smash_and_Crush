-- Fixed World2 pursuit settings. Never derive difficulty from the player's speed.
-- TurnResponse is an exponential response rate (1/seconds): larger turns faster.
-- Player upgrades are 24/28/32/36/40, costing 100/200/300/400 Win; Premium is 50.
-- All upgrades cost 1,000 total, below World2 Stage1's 3,000 Win reward. There is
-- no stage-specific Speed gate, so 40 and Premium 50 remain valid at every Stage.
local C={Stages={
 {Speed=18,TurnResponse=4.5},
 {Speed=19,TurnResponse=4.8},
 {Speed=20,TurnResponse=5.1},
 {Speed=21,TurnResponse=5.4},
 {Speed=22,TurnResponse=5.7},
 {Speed=23,TurnResponse=6.0},
 {Speed=24,TurnResponse=6.3},
 {Speed=25,TurnResponse=6.6},
 {Speed=26,TurnResponse=6.9},
 {Speed=27,TurnResponse=7.2},
}}
for _,stage in C.Stages do table.freeze(stage) end
table.freeze(C.Stages)
function C.Get(stage) return assert(C.Stages[stage],"Invalid World2 movement Stage") end
return table.freeze(C)
