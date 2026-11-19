-- A 24-hour window from the specified JST start date AND time.
-- YYYY-MM-DD + HH:MM (24-hour clock). Start inclusive; exactly +24 hours exclusive.
-- Empty/invalid date or start time fails closed in Studio AND production.
-- Server configuration is read once at startup. Edit before Play / publishing.
-- No local test clock, per-player epoch, ownership write, or global pass-gate override.
return table.freeze({
 Enabled=true,
 EventDateJST="2026-11-19", -- Start date, YYYY-MM-DD. Preserved from current Studio.
 EventStartTimeJST="22:00", -- Start time, HH:MM (00:00-23:59). Empty disables the event.
 StartIntervalSeconds=1800, -- Integer seconds, start-to-start (27-minute wait).
 OpenDurationSeconds=180, -- Integer seconds, clipped at the end of the 24-hour window.
 LogTransitions=true,
})
