-- Pure shared arithmetic. This module NEVER grants authority or reads a local clock.
local M={}
local DAY=86400
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function seconds(n) return finite(n) and n>0 and n<=DAY and n%1==0 end
local function disabled(reason) return {Valid=false,Reason=reason,Version=1} end
function M.Compile(config)
 if type(config)~="table" or config.Enabled~=true then return disabled("ConfigDisabled") end
 local date=config.EventDateJST
 if date=="" or date==nil then return disabled("DateUnset") end
 if type(date)~="string" then return disabled("InvalidDate") end
 local y,m,d=date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
 y,m,d=tonumber(y),tonumber(m),tonumber(d)
 if not y or y<1970 or y>9999 or m<1 or m>12 then return disabled("InvalidDate") end
 local leap=y%4==0 and (y%100~=0 or y%400==0)
 local days={31,leap and 29 or 28,31,30,31,30,31,31,30,31,30,31}
 if d<1 or d>days[m] then return disabled("InvalidDate") end
 local startTime=config.EventStartTimeJST
 if startTime=="" or startTime==nil then return disabled("StartTimeUnset") end
 if type(startTime)~="string" then return disabled("InvalidStartTime") end
 local hour,minute=startTime:match("^(%d%d):(%d%d)$")
 hour,minute=tonumber(hour),tonumber(minute)
 if not hour or hour>23 or minute>59 then return disabled("InvalidStartTime") end
 local interval,duration=config.StartIntervalSeconds,config.OpenDurationSeconds
 if not seconds(interval) or not seconds(duration) or duration>interval then return disabled("InvalidTiming") end
 -- UTC constructor, never OS local timezone; JST is UTC+09:00 (no DST).
 local ok,utc=pcall(DateTime.fromUniversalTime,y,m,d,hour,minute,0)
 if not ok then return disabled("InvalidDate") end
 local start=utc.UnixTimestamp-9*3600
 return {Valid=true,Version=1,StartUnixSeconds=start,EndUnixSeconds=start+DAY,
  StartIntervalSeconds=interval,OpenDurationSeconds=duration}
end
function M.Validate(plan)
 return type(plan)=="table" and plan.Valid==true and plan.Version==1
  and finite(plan.StartUnixSeconds) and finite(plan.EndUnixSeconds)
  and plan.EndUnixSeconds-plan.StartUnixSeconds==DAY
  and seconds(plan.StartIntervalSeconds) and seconds(plan.OpenDurationSeconds)
  and plan.OpenDurationSeconds<=plan.StartIntervalSeconds
end
function M.At(plan,now)
 if not M.Validate(plan) or not finite(now) then
  return {State="Disabled",Open=false,InEventDay=false,Reason=type(plan)=="table" and plan.Reason or "InvalidPlan"}
 end
 local start,finish=plan.StartUnixSeconds,plan.EndUnixSeconds
 if now<start then return {State="Before",Open=false,InEventDay=false} end
 if now>=finish then return {State="Ended",Open=false,InEventDay=false} end
 local cycle=math.floor((now-start)/plan.StartIntervalSeconds)
 local opens=start+cycle*plan.StartIntervalSeconds
 local closes=math.min(opens+plan.OpenDurationSeconds,finish)
 local nextStart=opens+plan.StartIntervalSeconds
 if nextStart>=finish then nextStart=nil end
 local open=now<closes
 return {State=open and "Open" or "Waiting",Open=open,InEventDay=true,Cycle=cycle,
  OpenedAt=opens,ClosesAt=closes,NextStartAt=nextStart,
  RemainingSeconds=open and (closes-now) or (nextStart and nextStart-now or nil)}
end
function M.FormatTime(secondsRemaining)
 local n=finite(secondsRemaining) and math.max(0,math.ceil(secondsRemaining)) or 0
 return string.format("%02d:%02d",math.floor(n/60),n%60)
end
function M.Presentation(status)
 local showTime=status.InEventDay==true and status.RemainingSeconds~=nil
 local clock=showTime and M.FormatTime(status.RemainingSeconds) or ""
 return {BoardVisible=status.InEventDay==true,TimeVisible=showTime,Open=status.Open==true,
  BoardTime=showTime and ((status.Open and "Now! " or "Next ")..clock) or "",
  OverheadTime=status.Open and clock or ""}
end
return table.freeze(M)
