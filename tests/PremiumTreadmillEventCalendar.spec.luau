-- Pure arithmetic, with a fixture date that is never written to game Config.
return function(S)
 local count=0
 local function check(x,msg) count+=1;assert(x,msg) end
 local c={Enabled=true,EventDateJST="2040-02-29",EventStartTimeJST="18:45",StartIntervalSeconds=1800,OpenDurationSeconds=180}
 local p=S.Compile(c);local t=p.StartUnixSeconds
 check(S.Validate(p),"valid leap date")
 check(DateTime.fromUnixTimestamp(t):ToIsoDate()=="2040-02-29T09:45:00Z","JST to UTC start")
 check(p.EndUnixSeconds-t==86400,"24 hours from configured start")
 for _,date in {"","2040-2-29","2040-02-30","2100-02-29","2026-04-31","2026-00-01","2026-13-01","2026-01-00","1969-12-31","10000-01-01","2026-11-19 "," 2026-11-19","garbage"} do
  local x=table.clone(c);x.EventDateJST=date;local invalid=S.Compile(x)
  local st=S.At(invalid,t)
  check(not st.Open and not S.Presentation(st).BoardVisible,"bad date: "..date)
 end
 for _,date in {"2000-02-29","2024-02-29","2100-02-28","2026-12-31"} do
  local x=table.clone(c);x.EventDateJST=date;check(S.Compile(x).Valid,"valid "..date)
 end
 for _,clock in {"","0:00","00:0","24:00","23:60","12:34:56","-1:00","12:00 "," 12:00","ab:cd",false,1234} do
  local x=table.clone(c);x.EventStartTimeJST=clock
  local st=S.At(S.Compile(x),t)
  check(not st.Open and not S.Presentation(st).BoardVisible,"invalid start time: "..tostring(clock))
 end
 local missingTime=table.clone(c);missingTime.EventStartTimeJST=nil
 check(S.Compile(missingTime).Reason=="StartTimeUnset","missing time cannot assume midnight")
 local midnight=table.clone(c);midnight.EventStartTimeJST="00:00"
 check(S.Compile(midnight).StartUnixSeconds==DateTime.fromUniversalTime(2040,2,28,15).UnixTimestamp,"explicit midnight accepted")
 local yearEnd=table.clone(c);yearEnd.EventDateJST="2040-12-31";yearEnd.EventStartTimeJST="23:59"
 local yearPlan=S.Compile(yearEnd)
 check(DateTime.fromUnixTimestamp(yearPlan.StartUnixSeconds):ToIsoDate()=="2040-12-31T14:59:00Z","23:59 start conversion")
 check(DateTime.fromUnixTimestamp(yearPlan.EndUnixSeconds):ToIsoDate()=="2041-01-01T14:59:00Z","year rollover plus 24 hours")
 check(DateTime.fromUnixTimestamp(p.EndUnixSeconds):ToIsoDate()=="2040-03-01T09:45:00Z","leap month rollover plus 24 hours")
 check(S.At(p,DateTime.fromUniversalTime(2040,2,29,15).UnixTimestamp).InEventDay,"JST midnight does not end a started window")
 check(not S.At(p,t-.001).InEventDay,"start boundary excludes earlier instant")
 check(S.At(p,t).Open and S.At(p,t+.001).Open,"start boundary inclusive")
 check(S.At(p,p.EndUnixSeconds-.001).InEventDay and not S.At(p,p.EndUnixSeconds).InEventDay,"end boundary exclusive")
 for _,field in {"StartIntervalSeconds","OpenDurationSeconds"} do
  for _,n in {0,-1,0/0,math.huge,180.1,86401,"180",false} do
   local x=table.clone(c);x[field]=n;check(not S.Compile(x).Valid,"invalid timing "..field)
  end
 end
 local x=table.clone(c);x.OpenDurationSeconds=1801;check(not S.Compile(x).Valid,"duration > period")
 x=table.clone(c);x.Enabled=false;check(not S.At(S.Compile(x),t).Open,"OFF")
 for _,bad in {0/0,math.huge,-math.huge,"0"}do check(not S.At(p,bad).Open,"bad clock")end
 for _,delta in {-0.001,0,0.001,179.001,179.999,180,1800,1980,84600,84780,86399.999,86400}do
  local a=S.At(p,t+delta);local b=S.At(S.Compile(c),t+delta)
  check(a.State==b.State and a.RemainingSeconds==b.RemainingSeconds,"independent server epoch")
 end
 local before=S.Presentation(S.At(p,t-0.001))
 check(not before.BoardVisible and not before.TimeVisible,"before hidden")
 local open=S.Presentation(S.At(p,t+1))
 check(open.BoardTime=="Now! 02:59" and open.OverheadTime=="02:59" and open.Open,"opening text")
 local lastSecond=S.Presentation(S.At(p,t+179.999))
 check(lastSecond.BoardTime=="Now! 00:01","ceil subsecond, never zero while open")
 local wait=S.Presentation(S.At(p,t+181))
 check(wait.BoardTime=="Next 26:59" and wait.OverheadTime=="" and not wait.Open,"waiting text")
 local endWindow=S.Presentation(S.At(p,t+180))
 check(endWindow.BoardTime=="Next 27:00" and not endWindow.Open,"exclusive close")
 local last=S.Presentation(S.At(p,t+84780))
 check(last.BoardVisible and not last.TimeVisible and last.BoardTime=="" and not last.Open,"final wait has no next")
 check(not S.Presentation(S.At(p,t+86400)).BoardVisible,"day end hidden")
 for _,n in {-1,0,0.01,59.001,60,3600}do
  check(not S.FormatTime(n):find("-"),"nonnegative format")
 end
 check(S.FormatTime(59.001)=="01:00","carry ceil minute")
 x=table.clone(c);x.StartIntervalSeconds=20000;x.OpenDurationSeconds=10000
 local clipped=S.Compile(x)
 check(S.At(clipped,t+86399.9).Open and not S.At(clipped,t+86400).Open,"last open clipped to day")
 x=table.clone(c);x.StartIntervalSeconds=86400
 local single=S.Presentation(S.At(S.Compile(x),t+180))
 check(single.BoardVisible and not single.TimeVisible,"one-window day")
 return {Kind="Pure absolute-time schedule simulation",Assertions=count,FixtureDate=c.EventDateJST,FixtureStartTime=c.EventStartTimeJST,UTCEnd=DateTime.fromUnixTimestamp(p.EndUnixSeconds):ToIsoDate(),UTCStart=DateTime.fromUnixTimestamp(t):ToIsoDate()}
end
