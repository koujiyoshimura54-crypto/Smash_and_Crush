# Shared Boss behavior — 2026-11-09

Canonical live Edit: PlaceId126576845524886, loaded version475, initial489 Sources. The live Source is the baseline. Its Speed attack angles were104/160/210 degrees, whereas Git still had104 for all three profiles; the owner's live160/210 adjustments are preserved. No UI, model, animation, Egg price or Player action timing change.

## Changed Full Paths and manual configuration

| Full Path | Change |
|---|---|
| ReplicatedStorage.Config.BossBehaviorConfig | New sole authority: Worlds[worldId][stage], for both Worlds and all ten Stages; SpeedModifiers retain equipped-Speed angle tuning. |
| ServerScriptService.World.BossChaseService | Both Worlds read Speed/TurnResponse from the same Stage row. Existing bounds, owner selection, locomotion and W2 intro/animation hooks remain. |
| ServerScriptService.World.BossAttackService | Existing native Heartbeat reads the Stage's interval/damage; actual hit predicate reads Stage geometry and Speed adjustments. |
| ReplicatedStorage.Config.World2BossMovementConfig | Compatibility view of the common World2 Stage rows. |
| ReplicatedStorage.Config.BossAttackHitboxConfig | Legacy Stage1 view of the common depth value; live attacks read their own Stage. |
| ReplicatedStorage.Config.SpeedBossAttackConfig | Legacy Stage1 view resolved from the common Stage/Speed definitions. No duplicate authoring values. |

Edit **BossBehaviorConfig.Worlds[1 or 2][1..10]** before starting a server/Play. Speed is studs/sec; TurnResponse is the exponential response/sec (larger turns faster). AttackInterval is seconds; Damage is HP per hit. WidthScale/DepthScale/HeightScale multiply the body-relative hit envelope without resizing models, colliders or contact Parts. ReachScale multiplies the measured body extent, clamped by MinReach/MaxReach in studs. AttackHeight and VerticalPadding are studs; AttackAngle is degrees. SpeedModifiers apply the preserved equipment-specific angle ratios to each Stage's base angle. Player WalkSpeed is independent.

Initial settings shared by every row: AttackInterval=1, Damage=25, WidthScale=1, DepthScale=0.9, HeightScale=1, ReachScale=0.25, MinReach=8, MaxReach=14, AttackAngle=104, AttackHeight=3.5, VerticalPadding=1. Speed angle multipliers are NONE=1, SPEED_BOOST=160/104, SPEED_PREMIUM=210/104; current resolved angles remain104/160/210. HP/wall HP and Player clocks stay in their existing Configs.

| Stage | W1 Speed | W1 TurnResponse | W2 Speed | W2 TurnResponse |
|---:|---:|---:|---:|---:|
|1|16|4|18|4.5|
|2|16|4|19|4.8|
|3|16|4|20|5.1|
|4|16|4|21|5.4|
|5|16|4|22|5.7|
|6|16|4|23|6.0|
|7|16|4|24|6.3|
|8|16|4|25|6.6|
|9|16|4|26|6.9|
|10|16|4|27|7.2|

Depth0.9 is applied once by inverse mapping the root's Boss-local Z coordinate about the original envelope center. Width uses the equivalent local-X transformation; height scales the original vertical attack interval. All are computed afresh from unmodified geometry, so death/re-registration cannot accumulate scaling. The existing body-size source and equipped-Speed selection remain.

## Four-attack audit

The running shared BossCombatService has MaxAttackCount=nil; Attacks is a counter, and only HP<=0 completes a win. BossAttackService has no hit-count termination and validates life, owner/session, stage and arena each tick. Player MaxHealth100 and25 damage produce normal death after four landed hits; these production values are unchanged. CombatConfig's legacy MaxAttackCount=5 is not read by the active completion path. Legacy Stage01BossClient and MergeToForge.Stage01BossBootstrap are disabled. No active fixed-four limit was found, so no artificial removal or HP rebalance was made.

## Native isolated verification

All persistence/payment/badge/policy/messaging dependencies used temporary memory adapters. Boss damage came from the production Heartbeat and EnemyManager validator, not a fixture health subtraction. Fixture high health was assigned after normal combat startup; production100 HP remains unchanged. Prepared wall clears, anchored character positions and paused fixture chase made range boundaries reproducible. Configuration rows were temporarily mutable only inside isolated Play.

- All20 private native actors resolved their Stage movement/attack row; initial Low/High/Reach/AttackTop/depth and inner/outer predicates matched an inactive pre-change oracle. This is native config/geometry coverage, not a complete fight against every Boss.
- W1 and W2 Stage3 alone were changed; Stage4 retained the original speed/depth and actual25 damage. Temporary row values: W1 speed8/turn2/interval0.35/damage7; W2 speed11/turn1.5/interval0.45/damage9. Both used width1.4/depth0.65/height1.6, reach scale0.4/min6/max18, angle130/height6/padding1.5. All were removed afterward.
- Native chase measured W1 **15.9999→7.9997** and W2 **20.0008→11.0003** studs/sec. Per-frame observed yaw matched the configured exponential turn response, maximum error below9e-8 radians.
- Six consecutive native hits occurred while both participants were alive: W1 seven HP each at0.35s scheduled intervals; W2 nine HP each at0.45s. Baseline samples were25 HP at1s.
- Native HP checks covered front inside/outside,90-degree Boss yaw, width inside/outside (angle temporarily360 to isolate width), height inside/outside, and a120-degree angular boundary at59.9/60.1 degrees.
- Re-fight, actual Humanoid death/respawn and prepared W1→W2→W1 transitions retained the restored0.9 factor. Staying in the arena retained damaged Boss HP; exiting healed Player and unfinished Boss. A real lethal Player attack marked defeat, and heal did not revive it. A new run bound a new actor generation.
- Player-to-Boss success gaps remained W1 **0.5003,0.8163,0.8003,0.8003s** and W2 **0.5005,0.8157,0.8164,0.8009s**. Immediate repeated manual input was refused; another manual hit after0.21s succeeded. Unchanged AutoTapConfig retains0.8 combat,0.5 after manual,0.2 common minimum and0.5 walking. Walking's predicate/cycle Source was preserved, not re-exercised in this phase.

Attempt1 records two fixture errors: its distant chase target was outside the arena and correctly terminated combat. The fixture was constrained to actual arena bounds and now asserts Chasing plus retained session. Only those two failed groups were rerun in StageOverrides.json (150 checks); ArenaAndAngle.json adds30 checks. Accepted all20-stage and death/travel evidence remains in Attempt1.json. No production correction was needed for this fixture error.

No new UI or imagery was introduced; there is no visual/animation acceptance claim. W2 models, animation Sources and opening hooks match the starting Sources. Multi-client runtime separation, physical input, natural full runs and production persistence were not re-tested. Existing unrelated asset warnings remained; no relevant runtime error appeared in completed fixtures.

## Cleanup, Save and delivery

Removed all QA instances, restored42 temporarily modified Sources and the production Config's frozen initial rows. Final audit:490 Sources,484 unchanged original Sources, five changed original Sources and one new Config. Enabled states, HTTP, Edit camera/focus and all unrelated Sources match the baseline. Play stopped; viewport Edit. Six shipping Sources compile and Git whitespace checks pass.

**Unsaved in canonical Studio.** After cleanup, AssetService:SavePlaceAsync was called with the exact canonical PlaceId and SaveWithoutPublish=true. It refused: `Game:SavePlace can only be called from a server script, aborting save function`. No OS/UI automation fallback, Publish, rbxl writeback or Studio close was used. The next Ore phase must preserve these live edits. Normal commit/push targets origin/main; unrelated untracked material is excluded.
