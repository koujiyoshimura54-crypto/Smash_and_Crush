-- Separate lifetime progress; completion is committed with the ordinary Pet merge.
local Merge=require(script.Parent.PetMerge)
local M={}
function M.Normalize(raw,eligible)
 if raw==nil then return {Version=1,Eligible=eligible==true,Completed=false} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Eligible)~="boolean" or type(raw.Completed)~="boolean"
  or raw.RequestId~=nil and type(raw.RequestId)~="string"
  or raw.ResultPetId~=nil and type(raw.ResultPetId)~="string" then return nil,"InvalidPetMergeTutorial" end
 return {Version=1,Eligible=raw.Eligible,Completed=raw.Completed,RequestId=raw.RequestId,ResultPetId=raw.ResultPetId}
end
function M.Available(state)
 local ids={}
 for id in pairs(state and state.Owned or {}) do if Merge.Eligible(state,id) then table.insert(ids,id) end end
 table.sort(ids)
 return ids,#ids>=2 and Merge.Evaluate(state,{ids[1],ids[2]})~=nil
end
function M.Apply(raw,op,pets,eligible)
 local state=assert(M.Normalize(raw,eligible))
 if state.Eligible and not state.Completed and op.Action=="Merge" then
  local result=op.Results and op.Results[1]
  -- Called only after Pet.ApplyOperation validated and applied this transaction.
  if result and pets.Owned[result.id]==result.pet and pets.LastRequestId==op.Id then
   state.Completed=true;state.RequestId=op.Id;state.ResultPetId=result.id
  end
 end
 return state
end
function M.Publish(player,state)
 player:SetAttribute("PetMergeTutorialEligible",state.Eligible)
 player:SetAttribute("PetMergeTutorialCompleted",state.Completed)
end
return table.freeze(M)
