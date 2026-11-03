-- Server-authored lifetime progress, separate from Ore onboarding and Pet ownership.
local M={}
function M.Normalize(raw,isNew)
 if raw==nil then return {Version=1,Eligible=isNew==true,Completed=false,Acquired={}} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Eligible)~="boolean" or type(raw.Completed)~="boolean"
  or type(raw.Acquired)~="table" or raw.PurchaseId~=nil and type(raw.PurchaseId)~="string"
  or raw.CompletionId~=nil and type(raw.CompletionId)~="string" then return nil,"InvalidEggPetTutorial" end
 local out={Version=1,Eligible=raw.Eligible,Completed=raw.Completed,Acquired={},PurchaseId=raw.PurchaseId,CompletionId=raw.CompletionId}
 local count=0
 for id,species in raw.Acquired do
  count+=1
  if count>8 or type(id)~="string" or #id==0 or #id>128 or type(species)~="string" or #species==0 or #species>128 then return nil,"InvalidEggTutorialPet" end
  out.Acquired[id]=species
 end
 return out
end
function M.OwnedTarget(state,pets)
 local ids={}
 for id,species in state.Acquired do if pets.Owned[id]==species then table.insert(ids,id) end end
 table.sort(ids)
 return ids[1]
end
function M.Apply(raw,op,pets)
 local state=assert(M.Normalize(raw,false))
 if not state.Eligible or state.Completed then return state end
 -- Only confirmed ordinary Basic hatches establish provenance; merge/paid grants do not.
 if op.Action=="Hatch" and op.EggName=="Basic" and not M.OwnedTarget(state,pets) then
  state.Acquired={};state.PurchaseId=op.Id
  for _,result in op.Results do state.Acquired[result.id]=result.pet end
 end
 for _,id in pets.Equipped do
  if id~="" and state.Acquired[id] and pets.Owned[id]==state.Acquired[id] then
   state.Completed=true;state.CompletionId=op.Id;break
  end
 end
 return state
end
function M.Publish(player,state)
 player:SetAttribute("EggTutorialEligible",state.Eligible)
 player:SetAttribute("EggTutorialCompleted",state.Completed)
end
return table.freeze(M)
