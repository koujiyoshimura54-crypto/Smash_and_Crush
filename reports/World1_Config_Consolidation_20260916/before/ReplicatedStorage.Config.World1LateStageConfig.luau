-- World1 Stage6-10 override. Keep legacy World1BossConfig and Wall.Config intact:
-- World2 still derives its intentionally unchanged HP from those baseline tables.
local Base=require(script.Parent.World1BossConfig)
local C=table.clone(Base)
C.RequiredStrength=table.clone(Base.RequiredStrength)
C.RecommendedLevels=table.clone(Base.RecommendedLevels)
local required={37315,81865,196915,462965,1018015}
local walls={}
for offset,strength in ipairs(required) do
 local stage=offset+5
 C.RequiredStrength[stage]=strength
 C.RecommendedLevels[stage]=25+offset*5
 walls[stage]=table.freeze({Walls=table.freeze({strength*2,strength*2.5,strength*3,strength*4}),BossMaxHP=strength*5})
end
function C.GetRequiredStrength(stage) return C.RequiredStrength[stage] end
function C.GetRecommendedLevel(stage) return C.RecommendedLevels[stage] end
function C.GetMaxHP(stage)
 local strength=C.GetRequiredStrength(stage)
 return strength and strength*C.HPPerRequiredStrength
end
function C.GetWallConfig(stage) return walls[stage] end
table.freeze(C.RequiredStrength)
table.freeze(C.RecommendedLevels)
return table.freeze(C)
