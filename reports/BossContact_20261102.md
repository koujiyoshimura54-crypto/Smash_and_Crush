# Player-to-Boss contact-only hits — 2026-11-02

Target: current unsaved canonical Studio, PlaceId **126576845524886**, UniverseId **10765181857**. Baseline Git `0e05bee`; current EnemyManager matched that export before editing. Applied localized edits directly to the live Source first. No older place or complete Git Source was imported.

## Cause and change

Changed Full Path: **ServerScriptService.World.EnemyManager** only.

The previous `enemyHit` combined collider overlap with an established encounter inside the same arena (`enemyHit or retained`). That retention rule also authorized new Player attacks. The delayed Auto callback checked encounter identity/liveness but did not recheck contact.

- Separate actual contact from `retainBossSession`. Loss of contact in the same arena leaves the encounter, pursuit, remaining HP and Auto setting intact.
- Use the existing `RuntimeCombatTriggers.WallCombatTrigger` referenced by the current character and the personal Boss's `CombatZone`. An oriented-box separating-axis test checks all 15 axes, including height and rotated corners. These existing Parts are non-queryable; no Touched latch or physics query depending on CanQuery is used. The character-root-only fallback no longer authorizes hits.
- Recheck live contact and arena membership immediately before `Boss.Attack`. Capture and validate SpawnGeneration in addition to existing player/character/session/state/actor fences.
- Preserve the existing arena-exit path, paired living-Player/unfinished-Boss recovery and defeated-state exclusion. Contact loss alone never calls Stop/Cancel/heal.
- Keep the existing attack clock: Auto interval 0.8 seconds, Auto impact delay 0.5 seconds, manual impact immediate after acceptance and existing manual cooldown. No attacks are queued while separated; recontact schedules one ordinary attack, not catch-up damage.

Inspected **ServerScriptService.World.BossCombatService**, **BossAttackService**, **BossChaseService** and World2 visual placement. Their Sources are unchanged. Chase still uses the existing collider edge plus player radius plus 0.8-stud gap; CombatZone's existing horizontal margin is 5 studs. Neither collider size nor pursuit settings were changed. Wall collision/damage, Boss-to-Player range/angle/height/cadence, rewards, Trophy, per-Item set effects, Best Equip and SE are untouched.

## Native Play evidence

Used `StudioTestService:ExecuteMultiplayerTestAsync(2,{})` against the current Edit model: **two real native clients**, not two in-memory player records. DataStore and Badge dependencies were temporarily redirected to memory-only adapters. Prepared Strength, owner wall clearance, stage/world and body tier shortened combat setup; normal native Auto monitoring, manual `AutoTapRequest("Tap")`, damage, chase, death/respawn, HP packets and GUI updates ran. No production save, payment or OS input occurred.

| Check | Result |
|---|---|
| W1 / W2 contact, manual and Auto | Actual encounter HP decreased by current BattleDamage. |
| Horizontal separation inside arena | Boss HP stopped decreasing; same encounter and IsFighting remained; damaged Player was not healed; personal Boss continued moving in Chasing state. |
| Vertical non-overlap with Auto ON | No hit; same encounter and Auto setting retained. |
| Recontact | Damage resumed without burst; measured successive Auto hits 0.899s / 0.901s in W1 / W2 (0.8s configured with existing 0.1s monitor scheduling). |
| Leave after Auto starts but before impact | No damage in both Worlds. |
| Damaged Player and Boss leave arena | Player restored to 100, unfinished Boss gauge to MaxHP, active encounter ended. Pending hit did not undo recovery. |
| Reentry | New full-HP encounter. Actual client packet, enabled PersonalGauge HP label and fill agreed: W1 375 / 375, W2 30M / 30M, fill 1. |
| Combat generation replacement | Pending old attack did not damage replacement encounter in either World. |
| Death and respawn | Dead character's pending attack missed; new run had full Boss HP in both Worlds. |
| Native World gate travel | Old W1 pending attack did not apply after real WorldTravelRequest/World2 activation. |
| Defeat then exit | Defeated Stage1 remained defeated, zero gauge, no revived actor. |
| Two-client independence, W1 and W2 | Exiting owner healed; other owner's damaged Boss, Player HP=75 and encounter remained unchanged. |
| Different body sizes/Bosses | Actual body height multipliers 1.1 and 3.55, Stage1 and Stage8 in each World, contact and manual HP reduction passed. Trigger remained 7 × 5.5 × 4. |

W1 and W2 chase stop checks on Stage1/small and Stage8/large all ended with zero measured drift and genuine trigger/CombatZone overlap. No chase or collider adjustment was needed. The focused follow-up passed; all 12 distinct scenario groups have passing evidence (48 distinct assertions).

Validation fixture corrections: first attempt called a nonexistent data setter; the corrected fixture uses the existing CurrentWorld attribute for prepared scenarios, while the dedicated travel case uses the native gate Remote. Another fixture referenced an actor after StartRun destroyed it; it now obtains the replacement. W2 Stage1 prepared wall clearance initially omitted its existing BeginIntro callback, leaving the Boss waiting; the follow-up invokes the same callback as normal final-wall clearance. These failed fixture attempts are not passing gameplay evidence. Production implementation did not change between these attempts.

## Reproduction and limits

Fixtures: `tests/BossContact.server.luau` and `tests/BossContact.client.luau`. Install only temporarily with the memory DataStore/Badge substitutions. The server fixture requires two temporary EnemyManager exports before `contexts[worldId]=M`: `M.__QAContact=bossContact` and `M.__QASession=function(p)return sessions[p]end`. They are verification helpers, not shipped APIs. Default runs all cases; the Only attribute supports focused Remaining / World2Stop retries.

Programmatic native input and measured client GUI properties are verified; physical mouse/touch and screenshot appearance are not. This is representative Stage1/2/8 combat and two-client isolation, not every Boss, all avatar accessories, all framerates or public-server deployment. Production persistence and actual payments were neither needed nor exercised. Existing unrelated asset-load warnings are outside this change.

Final cleanup restored all eight temporary Source substitutions exactly and removed the memory module, server/client fixtures and backup container. All **465 production Sources** and saved Enabled states match the intended post-change baseline; **74 SoundIds** are preserved. The three inspected Boss service Sources are byte-for-byte unchanged. EnemyManager's repository export matches the live final Source; no QA exports/helpers remain.

Canonical Studio is **Edit, focused Edit**, retaining existing and new unsaved edits. No Save/Publish, rbxl writeback, user Studio shutdown, camera/window changes or OS input. No new combat runtime error was found in the final server/client logs; the previously noted fixture failures were corrected rather than counted as passes.
