-- Existing normal-Pet points and Possible Eggs odds, shared by UI and server.
local Egg=require(script.Parent.Egg)
local M={}
function M.Eligible(state,id)
 local name=state and state.Owned and state.Owned[id]
 if not name or not Egg.mergePet(name) then return false,"PetNotMergeable" end
 if table.find(state.Equipped or {},id) then return false,"PetEquipped" end
 if state.Protected and state.Protected[id] then return false,"PetProtected" end
 return true
end
function M.Groups(state)
 local byName={}
 for id,name in pairs(state and state.Owned or {}) do
  local info=Egg.mergePet(name)
  if info then
   -- Use the authoritative species ID, never a shared icon/model/display name.
   local group=byName[name]
   if not group then group={Key=name,Name=name,Count=0,Points=info.Points,Ids={}};byName[name]=group end
   group.Count+=1
   if M.Eligible(state,id) then table.insert(group.Ids,id) end
  end
 end
 local groups={}
 for _,group in pairs(byName) do table.sort(group.Ids);table.insert(groups,group) end
 table.sort(groups,function(a,b) return a.Points~=b.Points and a.Points>b.Points or a.Points==b.Points and a.Name<b.Name end)
 return groups
end
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
  local allowed,reason=M.Eligible(state,id)
  if not allowed then return nil,reason end
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
