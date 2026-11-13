-- Witnesses come only from the existing World1 combat/return authorities.
-- Leaving the server, wall contact, arena recognition or a UI action is not a result.
local Players=game:GetService("Players")
local Data=require(script.Parent.PlayerDataService)
local M={}
local active=setmetatable({},{__mode="k"})
local function eligible(p)
 local s=Data.Get(p)
 if s and s.Loaded and s.Data and s.Data.FirstBattleTutorial and s.Data.FirstBattleTutorial.Eligible then return s end
end
local function living(p,c)
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return p.Parent==Players and p.Character==c and h and h.Health>0
end
function M.Start(p,ps,combat)
 local s=eligible(p)
 if not s or (p:GetAttribute("CurrentWorld") or 1)~=1 or combat.Stage~=1 or combat.CombatType~="MiniBoss"
  or ps.Defeated[1] or ps.Character~=combat.Character or not living(p,combat.Character)
  or not combat.Instance or combat.Instance:GetAttribute("OwnerUserId")~=p.UserId then return end
 active[p]={Character=combat.Character,Combat=combat,State=ps,RunId=ps.RunInventoryId,ResetToken=s.Data.ResetToken}
 Data.RecordFirstBattleFact(p,"Started")
end
function M.Death(p,c,ps,combat)
 local w=active[p];local s=eligible(p);local h=c and c:FindFirstChildOfClass("Humanoid")
 if not w or not s or w.Character~=c or p.Character~=c or w.State~=ps or w.Combat~=combat
  or not h or h.Health>0 or ps.Defeated[1] or (p:GetAttribute("CurrentWorld") or 1)~=1
  or ps.RunInventoryId~=w.RunId or s.Data.ResetToken~=w.ResetToken then return end
 Data.RecordFirstBattleFact(p,"Death");active[p]=nil
end
function M.Victory(p,ps)
 if not eligible(p) or (p:GetAttribute("CurrentWorld") or 1)~=1 or ps.Character~=p.Character
  or not ps.Defeated[1] or not living(p,p.Character) then return end
 Data.RecordFirstBattleFact(p,"Victory");active[p]=nil
end
function M.BackCurrent(p,w,ps)
 local s=eligible(p)
 return w~=nil and s~=nil and active[p]==w and w.State==ps and ps.RunInventoryId==w.RunId
  and p:GetAttribute("RunInventoryId")==w.RunId and s.Data.ResetToken==w.ResetToken
  and (p:GetAttribute("CurrentWorld") or 1)==1 and p:GetAttribute("CurrentStage")==1
  and p:GetAttribute("IsFighting")==true and not ps.Defeated[1] and living(p,w.Character)
end
function M.CaptureBack(p,runId,ps)
 local w=active[p]
 return w and w.RunId==runId and M.BackCurrent(p,w,ps) and w or nil
end
function M.BackPlaced(p,w,token,returnRunId)
 local s=eligible(p)
 if not w or not s or not token or not token.Accepted or token.RunId~=w.RunId or token.Character~=w.Character
  or s.Data.ResetToken~=w.ResetToken or not living(p,w.Character) or (p:GetAttribute("CurrentWorld") or 1)~=1
  or p:GetAttribute("RunInventoryId")~=returnRunId then return end
 Data.RecordFirstBattleFact(p,"Back")
end
function M.Cancel(p) active[p]=nil end
Players.PlayerRemoving:Connect(M.Cancel)
return M
