-- World2-only wall balance view. Does not load or initialize World1 wall progression.
local World=require(game.ReplicatedStorage.Config.World2Config)
local C={}
for stage=1,World.StageCount do
 local entry=World.GetStageConfig(stage)
 C[stage]=table.freeze({Walls=entry.Walls})
end
function C.GetMaxHP(stage,index)
 local entry=C[stage]
 return entry and entry.Walls[index]
end
return table.freeze(C)
