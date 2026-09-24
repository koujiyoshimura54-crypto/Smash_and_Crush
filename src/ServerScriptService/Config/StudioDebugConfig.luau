-- Server-only debugging. Stop Play, change a flag, publish if needed, then start again.
return {
 -- Existing Studio-wide switch. Ownership remains visible while benefits are suppressed.
 GamePassEffectsEnabled = false,
 ForceSpeedPremiumUnowned = false,
 -- Production-only switch for explicitly listed creator accounts.
 ProductionCreatorGamePassEffectsEnabled = false,
 ProductionCreatorUserIds = {
  [7467238848] = true,
 },
}
