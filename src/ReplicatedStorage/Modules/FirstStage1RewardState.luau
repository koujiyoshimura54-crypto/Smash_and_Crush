-- Lifetime World1 Stage1 replacement. Existing records without this field are excluded.
local M={OreId="ORE_001"}
function M.Normalize(raw,isNew)
 if raw==nil then return {Version=1,Consumed=not isNew} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Consumed)~="boolean"
  or raw.DefeatId~=nil and (type(raw.DefeatId)~="string" or raw.DefeatId=="")
  or raw.OreGranted~=nil and type(raw.OreGranted)~="boolean" then return nil,"InvalidFirstStage1Reward" end
 return {Version=1,Consumed=raw.Consumed,DefeatId=raw.DefeatId,OreGranted=raw.OreGranted}
end
function M.Merge(old,incoming)
 local a=assert(M.Normalize(old,false));local b=assert(M.Normalize(incoming,false))
 if a.Consumed then return a end
 return b.Consumed and b or a
end
return table.freeze(M)
