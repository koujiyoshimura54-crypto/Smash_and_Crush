-- Separate lifetime onboarding state. Missing fields on existing records never opt in.
local M={}
function M.Normalize(raw,isNew)
 if raw==nil then return {Version=1,Eligible=isNew==true,Completed=false} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Eligible)~="boolean" or type(raw.Completed)~="boolean"
  or raw.CompletionId~=nil and type(raw.CompletionId)~="string" then return nil,"InvalidOreMergeTutorial" end
 return {Version=1,Eligible=raw.Eligible,Completed=raw.Completed,CompletionId=raw.CompletionId}
end
function M.Complete(raw,id)
 local state=assert(M.Normalize(raw,false))
 if state.Eligible and not state.Completed then state.Completed=true;state.CompletionId=id end
 return state
end
function M.Merge(old,incoming)
 local a=assert(M.Normalize(old,false));local b=assert(M.Normalize(incoming,false))
 if old==nil then return b end
 if a.Completed then return a end
 return b.Completed and b or a
end
function M.Publish(player,state)
 player:SetAttribute("OreTutorialEligible",state.Eligible)
 player:SetAttribute("OreTutorialCompleted",state.Completed)
end
function M.AvailableCount(ores)
 local config=require(game.ReplicatedStorage.Config.OreConfig)
 local count=0
 for id,n in pairs(ores or {}) do
  local ore=config.Get(id)
  if ore and ore.Available and type(n)=="number" and n>0 and n%1==0 then count+=n end
 end
 return count
end
return table.freeze(M)
