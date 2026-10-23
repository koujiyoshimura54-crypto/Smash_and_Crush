-- Pure per-actor timeline. No delayed callbacks, tasks, damage or movement.
local Config=require(game.ReplicatedStorage.Config.World2SCP096Config)
local M={}
local function phase(r,name,started)
 r.Phase=name;r.StartedAt=started;r.Revision+=1
end
function M.Create(durations)
 local intervals={}
 for name,entry in Config.Clips do
  local duration=durations[name]
  assert(typeof(duration)=="number" and duration>0 and duration<math.huge,"Invalid body clip duration: "..name)
  assert(entry.Speed>0 and entry.Speed<math.huge,"Invalid clip speed: "..name)
  intervals[name]=duration/entry.Speed
 end
 return {Phase="Waiting",StartedAt=0,Revision=0,Used=false,AttackEligible=false,Intervals=intervals}
end
function M.Begin(r,now)
 if r.Used or r.Phase=="Cancelled" then return false end
 r.Used=true;phase(r,"GetUp_Panic",now);return true
end
function M.Update(r,now)
 -- Preserve exact clip boundaries even if a server frame crosses two of them.
 if r.Phase=="GetUp_Panic" and now>=r.StartedAt+r.Intervals.GetUp_Panic then
  phase(r,"Panic",r.StartedAt+r.Intervals.GetUp_Panic)
 end
 if r.Phase=="Panic" and now>=r.StartedAt+r.Intervals.Panic then
  phase(r,"AttackRunStart",r.StartedAt+r.Intervals.Panic)
 end
 if r.Phase=="AttackRunStart" and now>=r.StartedAt+r.Intervals.AttackRunStart then
  phase(r,"AttackRun",r.StartedAt+r.Intervals.AttackRunStart)
 end
 return r.Phase
end
function M.Ready(r,now)
 M.Update(r,now)
 return r.Phase=="Running" or r.Phase=="AttackRunStart" or r.Phase=="AttackRun"
end
function M.SetAttack(r,eligible,now)
 -- Pursuit keeps the approved arms-forward loop, independent of hit range.
 -- Eligibility only keeps that loop playing during stationary close combat.
 r.AttackEligible=M.Ready(r,now) and eligible==true
end
function M.Cancel(r)
 r.AttackEligible=false
 if r.Phase~="Cancelled" then phase(r,"Cancelled",r.StartedAt) end
end
return M
