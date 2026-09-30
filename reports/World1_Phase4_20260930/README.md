# World1 Boss Phase 4 — 2026-09-30

World1 now resolves Boss encounters through real Strength damage. Place 101572058398926 was tested in Play, then stopped in Edit without saving or publishing.

## Changes

- `ServerScriptService.World.BossCombatService.Begin / Attack`: World1 always uses `STRENGTH_DAMAGE`, takes no random draw and sets no Chance/Roll/LossPlanned. Each accepted hit subtracts the existing battle-start Strength × (1 + ItemService.GetGloveBossDamageBonus). No new cap. Five hits do not complete a living encounter.
- `ServerScriptService.World.EnemyManager.updateCombat / applyBossHit`: the legacy Lose result path is explicitly World2-only. Existing Humanoid death handling is unchanged.
- `ServerScriptService.Systems.Debug.StudioDebugService.GetBalanceSnapshot`: reports StrengthRatio / BossDamage / BossDamageRoute instead of obsolete World1 lottery diagnostics.
- Shared ModuleScript contexts remain independent. World2 still uses the old lottery table and five-hit rules. The old config table is retained for that dependency; World1 combat no longer calls it.
- RequiredStrength and MaxHP = RequiredStrength × 5 are unchanged. Encounter snapshots, rebind/cancel/reset and wall carry are preserved.

## Live Play results

Same real Stage01 Boss: RequiredStrength 75, MaxHP 375. Unless stated otherwise, Glove bonus and wall carry were zero. Server runtime sampling was approximately one Heartbeat; the first manual hit is t≈0 (microsecond-negative logging deltas are call-order noise).

| Test | Strength | Damage/hit | Accepted Player hits | Result / duration |
|---|---:|---:|---:|---|
| 100%, manual | 75 | 75 | 5 | WIN, 2.058 s |
| 80%, manual | 60 | 60 | 7 | WIN, 3.092 s |
| 60%, manual, first Boss attack MISS | 45 | 45 | 9 | WIN, 4.128 s |
| 150%, manual | 112.5 | 112.5 | 4 | WIN, 1.553 s |
| 100%, automatic | 75 | 75 | 5 | WIN, 3.967 s |
| 60%, manual, stay close | 45 | 45 | 8 before death | DEATH, Boss fourth attack at 4.010 s |
| 80%, automatic, moved across arena | 60 | 60 | 6 before death | Boss first attack MISS, then death at 5.013 s |
| Actual equipped Common Glove, 100% manual | 75 | 78.75 | 5 | WIN, 2.062 s; bonus 0.05 applied once |

The 80% and 60% manual tests were still active after hit5. The 80% automatic test also continued beyond hit5. No Strength-based terminal rejection occurred.

The 60% successful trial deliberately repositioned the Character within the existing Arena for the first attack, then returned it to the Boss. The unmodified BossAttackService recorded distance 37.220 vs reach 9 at 1.010 s: MISS. Subsequent attacks at 2.011 / 3.010 / 4.010 s hit. This verifies range-based low-Strength victory, not a claim that a human can reproduce the movement effortlessly.

Close-range 60% trial: Boss damage timestamps 1.011 / 2.010 / 3.011 / 4.010 s, HP 100 → 75 → 50 → 25 → 0. No synthetic five-hit defeat. Boss HP reset to 375; IsFighting false; BossAttack stopped; Chase returned home. Following normal respawn: Health100, CurrentStage1, Lobby SpawnLocation, home position error0. A subsequent Glove trial successfully re-entered combat and won.

All eight winning trials delivered the real client events BossResult=WIN, EnemyDefeated and StageCleared(CurrentStage=2). Player HP was 100 and BossAttack inactive after every win.

## Carry

Exercised the real EnemyManager wall contact/manual attack path, not just QueueDamage:

- Strength60: ten wall hits, total walls575, carry25. Gauge before formal combat375; initial combatHP350. Six accepted Boss hits won (without carry, seven).
- Strength1000: one hit cleared all walls575, so mathematical surplus425 exceeded Boss375. Formal combat began atHP0; the next accepted hit emitted WIN. High Strength already exceeds this Boss's full HP without carry. No double Glove or duplicate carry was observed.
- Carry can therefore shorten a fight or exhaust initial HP. This existing behavior was deliberately retained, including result notification on the subsequent accepted attack. No new limit or early-result refactor was introduced.

## Additional checks and limits

- Live service checks for all World1 Stage01–10 at Strength ratios 0 / .5 / .6 / .8 / 1 / 1.5: 60 cases passed. With zero damage, 12 attacks remained Active; other ratios won in 10 / 9 / 7 / 5 / 4 hits. These were service calls, not full arena Play runs for every Stage.
- World2 ratios 0 / .5 / 1 / 1.5 compared against a runtime-only copy of the pre-change module: HP, route, chance and result matched. Random World2 winning paths were not sampled; their logic was retained.
- Final Edit baseline compared 510 Script sources: only the three listed scripts changed. Production source compilation returned zero errors. BossAttackService and BossChaseService were byte-for-byte unchanged.
- CombatConfig.AttackInterval=0.8 and AutoTapConfig.ManualAttackCooldown=0.5 unchanged. Existing approximately0.017 s auto-to-manual consecutive-hit issue intentionally not fixed.
- No Animation, VFX, map, arena, damage range, health service or Chase setting changed.
- Old ServerStorage lottery regression suites encode historical outcomes and were not represented as passing Phase4 tests.

## Test isolation and cleanup

A runtime-only audit runner invoked real server modules (Studio plugin-context require has a separate module state). Strength used the existing StudioStartOverride, which blocks player saves. Glove selection, auto preference and Character position/anchoring were temporary fixtures. Reward persistence and badge calls were temporarily suppressed for the audit, then restored. Normal combat, attack range/timing, Chase, HP damage and progression were not mocked.

Original PlayerData, override flag, Glove, auto setting, reward/badge functions and anchoring were restored before Stop. Runtime-only audit Script/BindableFunction/baseline ModuleScript disappeared with Stop; no test instances remain in Edit.

Console: no error from the changed production combat scripts. Existing unused-model issues remain: TungTungSahur.Script line756 nil Chatted, La_Grande_Combinasion missing Walk child, and old Brainro_pack_3 references including TralaleroWalkController. An initial audit bridge attempted unavailable loadstring and failed; it was replaced with a direct Script runner before measurements. Neither issue was hidden or counted as an error-free Play session.

Raw measured outcomes (no player identifiers or inventory snapshot): [evidence.json](evidence.json).
