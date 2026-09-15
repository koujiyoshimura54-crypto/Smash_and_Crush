-- Server-side HP-only projection from the current World1 wall authority.
local Base=require(game.ServerScriptService.World.Stage1WallManager).Config
local World=require(game.ReplicatedStorage.Config.World2Config)
local C={}
for stage,entry in pairs(Base) do
 local walls={}
 for index,hp in ipairs(entry.Walls) do walls[index]=hp*World.World2HPScale end
 C[stage]=table.freeze({Walls=table.freeze(walls)})
end
function C.GetMaxHP(stage,index)
 local entry=C[stage]
 return entry and entry.Walls[index]
end
return table.freeze(C)

