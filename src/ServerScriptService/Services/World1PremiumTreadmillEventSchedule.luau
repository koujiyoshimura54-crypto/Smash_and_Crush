-- Pure schedule arithmetic; callers must supply the server-side Studio guard.
local M={}
local function positive(n)
 return type(n)=="number" and n==n and n>0 and n<math.huge
end
function M.At(config,studioServerRunning,elapsed)
 local disabled={State="Disabled",Open=false,RemainingSeconds=0}
 if not studioServerRunning then disabled.Reason="NotRunningStudioServer";return disabled end
 if config.Enabled~=true then disabled.Reason="ConfigDisabled";return disabled end
 local interval,duration,total=config.StartIntervalSeconds,config.OpenDurationSeconds,config.SessionDurationSeconds
 if not positive(interval) or not positive(duration) or not positive(total) or duration>interval then
  disabled.Reason="InvalidConfig";return disabled
 end
 if type(elapsed)~="number" or elapsed~=elapsed or elapsed<0 or elapsed==math.huge then
  disabled.Reason="InvalidClock";return disabled
 end
 if elapsed>=total then return {State="Ended",Open=false,ElapsedSeconds=elapsed,RemainingSeconds=0,SessionEndsAt=total} end
 local cycle=math.floor(elapsed/interval)
 local openedAt=cycle*interval
 local closesAt=math.min(openedAt+duration,total)
 local open=elapsed<closesAt
 local nextStart=openedAt+interval
 -- A next start at/after the hard cutoff is not another event.
 local nextChange=open and closesAt or math.min(nextStart,total)
 return {
  State=open and "Open" or "Waiting",Open=open,Cycle=cycle,
  ElapsedSeconds=elapsed,RemainingSeconds=nextChange-elapsed,
  OpenedAt=openedAt,ClosesAt=closesAt,SessionEndsAt=total,
  NextStartAt=nextStart<total and nextStart or nil,
 }
end
return table.freeze(M)
