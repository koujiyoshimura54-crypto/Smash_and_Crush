-- Player action timing only; treadmill and Boss-to-Player timers remain independent.
return table.freeze({
 MinimumInterval=0.2,
 AfterManualDelay=0.5,
 AutoInterval=0.5, -- Ordinary grounded-walking Strength only.
 CombatAutoInterval=0.8,
 ManualAttackAnimationSpeed=2.0,
})
