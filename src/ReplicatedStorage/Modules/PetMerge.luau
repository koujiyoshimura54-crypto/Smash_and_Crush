-- Existing normal-Pet points and Possible Eggs odds, shared by UI and server.
local Egg=require(script.Parent.Egg)
local M={}
function M.Evaluate(state,ids)
 if typeof(state)~="table" or typeof(state.Owned)~="table" or typeof(ids)~="table" then return nil,"InvalidPetMaterials" end
 local count=#ids
 if count<2 then return nil,"SelectAtLeastTwoPets" end
 local seen,points={},0
 for key in pairs(ids) do if typeof(key)~="number" or key%1~=0 or key<1 or key>count then return nil,"InvalidPetMaterials" end end
 for _,id in ipairs(ids) do
  if typeof(id)~="string" or seen[id] then return nil,"InvalidPetMaterials" end
  seen[id]=true
  local name=state.Owned[id];local info=name and Egg.mergePet(name)
  if not info then return nil,"PetNotMergeable" end
  if table.find(state.Equipped or {},id) then return nil,"PetEquipped" end
  if state.Protected and state.Protected[id] then return nil,"PetProtected" end
  points+=info.Points
 end
 local preview=Egg.mergePreview(points,count)
 if not preview.Eligible then return nil,"InvalidPetMaterials" end
 return {Ids=table.clone(ids),Count=count,Points=points,Outcomes=preview.Outcomes}
end
function M.Pick(preview,unit)
 local sum=0
 for _,row in ipairs(preview.Outcomes) do sum+=row.Percent/100;if unit<sum then return row.Egg end end
 return preview.Outcomes[#preview.Outcomes].Egg
end
function M.ValidEgg(preview,name)
 for _,row in ipairs(preview.Outcomes) do if row.Egg==name and row.Percent>0 then return true end end
 return false
end
return table.freeze(M)
