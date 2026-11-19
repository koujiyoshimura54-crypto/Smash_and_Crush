-- One JST calendar day. Empty/invalid date fails closed in Studio AND production.
-- YYYY-MM-DD; 00:00 JST inclusive through next 00:00 JST exclusive.
-- Server configuration is read once at startup. Edit before Play / publishing.
-- No local test clock, per-player epoch, ownership write, or global pass-gate override.
return table.freeze({
 Enabled=true,
 EventDateJST="", -- Intentionally unset. Do not insert a trial date here.
 StartIntervalSeconds=1800, -- Integer seconds, start-to-start (27-minute wait).
 OpenDurationSeconds=180, -- Integer seconds, clipped at the end of the JST day.
 LogTransitions=true,
})
