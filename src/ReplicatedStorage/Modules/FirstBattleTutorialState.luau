-- Durable facts for the new cohort; missing fields on old profiles never opt in.
-- Ore completion and equipment completion remain owned by their existing records.
local M={}
local outcomes={Victory=true,Death=true,Back=true}
function M.Normalize(raw,isNew)
 if raw==nil then return {Version=1,Eligible=isNew==true,BattleStarted=false,Stage1Defeated=false} end
 if type(raw)~="table" or raw.Version~=1 or type(raw.Eligible)~="boolean"
  or type(raw.BattleStarted)~="boolean" or type(raw.Stage1Defeated)~="boolean"
  or raw.FirstOutcome~=nil and not outcomes[raw.FirstOutcome]
  or (raw.FirstOutcome~=nil or raw.Stage1Defeated) and not raw.BattleStarted then
  return nil,"InvalidFirstBattleTutorial"
 end
 return {Version=1,Eligible=raw.Eligible,BattleStarted=raw.BattleStarted,
  Stage1Defeated=raw.Stage1Defeated,FirstOutcome=raw.FirstOutcome}
end
function M.Record(raw,fact)
 local s=assert(M.Normalize(raw,false))
 if not s.Eligible then return s,false end
 local changed=false
 if fact=="Started" or fact=="Victory" then
  if not s.BattleStarted then s.BattleStarted=true;changed=true end
 elseif not outcomes[fact] or not s.BattleStarted then return s,false end
 if outcomes[fact] and not s.FirstOutcome then s.FirstOutcome=fact;changed=true end
 if fact=="Victory" and not s.Stage1Defeated then s.Stage1Defeated=true;changed=true end
 return s,changed
end
function M.Merge(old,incoming)
 local b=assert(M.Normalize(incoming,false))
 if old==nil then return b end
 local a=assert(M.Normalize(old,false))
 if not a.Eligible then return a end
 a.BattleStarted=a.BattleStarted or b.BattleStarted
 a.Stage1Defeated=a.Stage1Defeated or b.Stage1Defeated
 a.FirstOutcome=a.FirstOutcome or b.FirstOutcome
 return a
end
function M.StoneProtected(data)
 return data.FirstBattleTutorial~=nil and data.FirstBattleTutorial.Eligible==true
  and not (data.OreMergeTutorial and data.OreMergeTutorial.Completed==true)
end
function M.Done(facts,merged,equipped)
 return facts.Eligible==true and facts.Stage1Defeated==true and merged==true and equipped==true
end
function M.Phase(facts,c)
 if facts.Eligible~=true then return "Legacy" end
 if M.Done(facts,c.Merged,c.Equipped) then return "Complete" end
 if c.World~=1 or c.Alive~=true then return "Waiting" end
 if c.InLobby and not c.Merged and (c.MergeOpen or facts.FirstOutcome~=nil) then return "Merge" end
 if c.InLobby and c.Merged and not c.Equipped then return "Equip" end
 if facts.Stage1Defeated then return "Reward" end
 if facts.FirstOutcome~=nil and (not c.Merged or not c.Equipped) then return "Waiting" end
 local goal=facts.FirstOutcome~=nil and 4 or 2
 return type(c.Level)=="number" and c.Level>=goal and "Battle" or "Train"
end
function M.Publish(player,s)
 player:SetAttribute("FirstBattleTutorialEligible",s.Eligible)
 player:SetAttribute("FirstBattleStarted",s.BattleStarted)
 player:SetAttribute("FirstBattleOutcome",s.FirstOutcome)
 player:SetAttribute("FirstBattleStage1Defeated",s.Stage1Defeated)
end
function M.Read(player)
 return {Eligible=player:GetAttribute("FirstBattleTutorialEligible"),
  BattleStarted=player:GetAttribute("FirstBattleStarted"),FirstOutcome=player:GetAttribute("FirstBattleOutcome"),
  Stage1Defeated=player:GetAttribute("FirstBattleStage1Defeated")}
end
function M.ClientDone(player)
 return M.Done(M.Read(player),player:GetAttribute("OreTutorialCompleted"),
  player:GetAttribute("DumbbellEquipTutorialInitialCompleted"))
end
function M.Active(player) return player:GetAttribute("FirstBattleTutorialEligible")==true and not M.ClientDone(player) end
function M.AllowLaterGuides(player)
 if player:GetAttribute("FirstBattleTutorialEligible")==true then return M.ClientDone(player) end
 return player:GetAttribute("TutorialCompleted")==true
end
return table.freeze(M)
