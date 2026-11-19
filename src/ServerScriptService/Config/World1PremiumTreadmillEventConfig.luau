-- Development preview ONLY. The server additionally requires IsStudio/IsServer/IsRunning.
-- All durations are seconds from this server's Play start, not player join time.
-- Edit these values before Play; ModuleScript configuration is cached for that Play.
-- No production calendar, ownership write, or global GamePass gate override.
return table.freeze({
 Enabled=true,
 StartIntervalSeconds=1800, -- Start-to-start: 3 minutes open, then 27 minutes waiting.
 OpenDurationSeconds=180,
 SessionDurationSeconds=86400, -- Hard cutoff; no new window at exactly 24 hours.
 LogTransitions=true, -- One Output message per state/cycle change, not per frame.
})
