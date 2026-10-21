# World2 boss parity and size — 2026-10-21

## Authority and scope

Updated the current C:\Users\kouji\MergeToForge_CurrentCloud.rbxl, starting at SHA-256 189a0007a13fcd649cdc4bc3fc3b8e53175d94d24f1281e82cbc497d37bee3aa / repository 2ee20a4. Read AGENTS.md, current place Sources, related specifications and latest independence/Trophy records. No older place or whole Source set was restored.

Retained 5e3d53f personal actors, c63a393 immediate/idempotent Trophy receipts and 2ee20a4 permanent paired buttons and Game Pass integration. All other Source rows, instance properties, parents, IDs, templates, numeric balances, walls (including transparent walls), gates and map edits are byte-for-byte unchanged in the binary writeback.

The actual place's chase speed/turn response is 16/4. Repository HEAD had 28/12 and an existing dirty local mirror had 20/12. The place retains 16/4; the unrelated local speed edit is neither overwritten nor included in this commit. The writer explicitly preserves the current place values.

## Current World1 contract and implementation

- Boss existence, wall unlock, recognition, owner-only pursuit, encounter retention, exit/heal/reset, stage advancement and reward eligibility use existing EnemyManager contexts.
- BossChaseService and BossAttackService now expose ForWorld contexts. Both Worlds reuse the same movement, rotation, stop-gap, update cadence, attack range rules and cleanup, with separate actors, validators, targets, records and callbacks.
- World2's old five-hit/lottery encounter route is replaced with current World1 real Strength damage: battle-start Strength × (1 + existing glove bonus). No attack-count limit or combat time limit is added. World2BossConfig remains the numeric authority.
- Current World1 has no additional non-animation stage-specific attack pattern or telegraph in these services. Stage3's special animation remains untouched; World2 animations were not authored, purchased, transplanted or required. Existing combat event/timing hooks remain available for future animation work.
- Existing automatic attack interval (0.8 s), automatic hit delay (0.5 s), manual cooldown and immediate accepted manual hits are retained. Boss outgoing hits retain 25 damage, first deadline at 1 s, then 1 s cadence, existing SpeedBossAttackConfig range/angle/height rules and no catch-up burst.
- World2 gauges follow the moving personal actor through the existing overhead renderer. Existing shared hit/defeat presentation events remain connected.
- World2 full visible footprints are kept within the existing floor and beyond Wall4. The rendered bounds helper is separate from the body collider; tails do not enlarge outgoing hit reach. Stage9's body collider is moved forward relative to the long tail.
- Fresh clones are scaled from unchanged templates each time. No scale is applied to a previous live actor. Grounding, home fitting, body volumes and HP offsets apply to the real personal actors.

## Changed Full Paths

1. ReplicatedStorage.Config.World2BossVisualConfig
2. ServerScriptService.World.BossAttackService
3. ServerScriptService.World.BossChaseService
4. ServerScriptService.World.BossCombatService
5. ServerScriptService.World.BossVisualPlacement
6. ServerScriptService.World.EnemyManager
7. StarterPlayer.StarterPlayerScripts.Combat.CombatClient

No Trophy, purchase, progression, balance, animation or template Source was changed.

## Dimensions and visual review

Reference: current World1 Stage5 67Rig, visible dimensions **28.75 × 14.54 × 4.30 studs**, model scale 2.3. Invisible helpers are excluded. These are descriptive visible extents; size choices also used actual rendered body volume and silhouette, rather than matching height alone.

Dimensions below are width × height × depth at neutral facing. The multiplier is relative to each existing template (Stage9 already has template scale 0.5). Minor sub-millistud differences in live world coordinates are floating-point precision. See Dimensions.json for full values and collider ratios/offset.

| Stage | Existing model | Before | Multiplier | After | Actual Play |
|---|---|---|---:|---|---|
| 1 | SCP-096 | 3.40 × 7.00 × 1.26 | 2.25 | 7.65 × 15.75 × 2.84 | Pass |
| 2 | SCP-023 | 1.69 × 3.71 × 5.18 | 3.6 | 6.08 × 13.35 × 18.65 | Pass |
| 3 | SCP-035 | 4.00 × 5.07 × 1.61 | 3 | 11.99 × 15.20 × 4.84 | Pass |
| 4 | SCP-058 | 4.26 × 4.29 × 3.29 | 3 | 12.79 × 12.86 × 9.86 | Pass |
| 5 | SCP-049 | 3.04 × 5.84 × 1.49 | 2.7 | 8.20 × 15.78 × 4.02 | Pass |
| 6 | SCP-173 | 5.60 × 8.80 × 4.46 | 1.75 | 9.80 × 15.40 × 7.81 | Pass |
| 7 | SCP-939 | 8.49 × 4.20 × 9.60 | 2.5 | 21.22 × 10.50 × 23.99 | Pass |
| 8 | SCP-106 | 4.00 × 5.00 × 1.16 | 3 | 12.00 × 15.00 × 3.47 | Pass |
| 9 | SCP-682 | 9.17 × 6.72 × 27.78 | 1.4 | 12.84 × 9.41 × 38.90 | Pass |
| 10 | SCP-323 | 5.08 × 8.81 × 3.21 | 1.8 | 9.14 × 15.85 × 5.78 | Pass |

SCP-023 and SCP-939 receive more body volume for their low quadruped silhouettes. SCP-682 retains a lower 9.41-stud body height and a long tail, rather than being enlarged to 14.54 studs tall. Its existing FileMesh uses intrinsic mesh dimensions (68.2332 × 50 × 206.7453); the tiny carrier Part is not its rendered extent.

Before/after screens for all ten actual spawned actors and the World1 reference were inspected with normal size tier 1 and camera offset (+19,+17,-33), looking at actor pivot + (0,3,0). Additional fight views checked moving HP gauges, normal/max avatars and quadruped side clearance. Screenshots were temporary and were not committed, per AGENTS.md; the one local diagnostic window image was deleted.

## Verification boundaries

Actual local Studio multiplayer Play was used, including independent client processes. No production DataStore or real purchase was used. Unsaved fixtures substituted memory-only PlayerData stores and badge calls, prepared stages/wall unlocks/Strength/body tiers, and optionally restored positive health after logging real 25-damage hits. Fixtures did not implement the boss AI, hit processing, stage result, reward amount or return.

Mouse/keyboard/navigation tools performed attacks, retreat/re-entry and pad contact on real clients. Isolated ownership and checkout success/cancel were deliberately mocked at Marketplace's server-facing interface; the existing GamePassService refresh/confirmed callback and Trophy code then ran normally. These are not real payment confirmations.

## Actual Play results

- **All ten World2 bosses:** actual spawned size/facing/grounding and display inspected; natural pursuit/turning, attack acceptance, 25-damage incoming hits, HP reduction, defeat and next-stage handoff observed. Each nominal five-hit test used current World2 HP / 5 Strength; HP reached 80% after the first hit and defeat after five. Win remained 10,000 until an eligible pad was touched. Verification.json contains the per-stage states.
- **No five-hit cap/lottery:** a lower-Strength Stage1 run remained active after nine accepted hits with 34,999,991 HP, then was defeated by the tenth. An early pre-combat click added 1 Strength through normal training; the recorded battle snapshot reflects that.
- **World1 regression/mixed Worlds:** current Stage5 chased, inflicted 25-damage hits and was defeated through actual client clicks while the other client fought in World2. World1 and World2 actors/HP/targets remained separate. Earlier halted-display attempts are not counted as client-operation passes.
- **Normal/max body:** height scales 1.1 and 3.55 fought Stage7 simultaneously with different HP (45B versus 60B), correct targets and only their own visible Boss (11 visible parts versus 0 for the foreign actor on each client).
- **Exit/retry:** maximum-size Player1 retreated using real keyboard movement, ended only its encounter, then re-entered at full 75B Boss HP and defeated it. Player2 remained at 60B. A natural four-hit death with health assist disabled respawned only Player1; Player2 continued unchanged.
- **Owner reward/return:** Player1's Stage7 left-pad claim with isolated verified ownership added 800,000 (400,000 × 2), returning only Player1; Player2's battle continued. Stage10 right-pad claim with ownership added 3,500,000 × 1 and returned to World2 lobby.
- **Stage10:** current World2 completion flag became true on defeat, no automatic Win and no World3. Existing return/reset semantics remained intact.
- **Mock purchase cancel/success:** entering left Stage1 pad prompted pass 1970515086. Cancel preserved Win/eligibility/location; standing still did not repeat the prompt. Leaving/re-entering then confirming ownership through the server callback credited 6,000 and started return within the next observed 0.2-second sample, without another step.
- **Pending-purchase race:** after a left prompt, walking to the normal pad credited 3,000 and returned. A late successful purchase set ownership true but left Win at 13,000 and did not return again.
- **Exit/rejoin:** one real client left via StudioTestService; its actor disappeared and the remaining World2 Stage7 battle stayed at 60B. A replacement client joined and initialized its own full-HP Stage7 actor. No other player's run was reset.
- **Regeneration:** two five-reset samples left zero old parented actors and one actor per active owner. A generation-13 Stage1 actor still had scale 2.25 and dimensions 7.65 × 15.75 × 2.84; no cumulative growth. No enabled imported scripts or server-colliding parts remained in the personal actor folders.
- **Large quadruped boundary:** Stage9 at maximum player size followed and rotated near the side wall; measured full visual bounds remained within the floor, recovery count 0. Moving beyond the arena's existing inset ended combat. Re-entering and five actual clicks defeated it. No body sinking or persistent wall stall was observed.
- **Console:** no scoped game runtime error, warning or infinite yield from the changed services. Existing asset-permission failures for several shared audio assets and Studio/CorePackages UI warnings remained; audio audibility was not certified.

A long-running verification session lost rendering when Windows entered display power saving. A transient display wake restored RenderStepped and client operations. Fresh isolated clients were also used; no game code was changed for that environmental issue. The navigation tool sometimes reported Path Blocked for the tall avatar; real keyboard movement verified the same retreat/re-entry successfully.

## Static / preserved / not exercised

- Static comparison and lossless binary checks preserve both existing buttons per Stage, shared receipt locks, immediate notification before save/return retries, existing triple-Win correction, purchase callback ownership checks and stale-claim guards.
- Existing personal session identity checks still protect delayed hits; finalization unregisters actors and stops their attack sessions. Repeated runtime regeneration and owner departure were checked; this was not a long-duration memory profiler.
- Real checkout, real receipts/payment failures, production saves, cross-place live server travel and permitted-audio playback were not exercised. Real payment remains intentionally untested.
- No mass regression of unrelated Speed, Inventory, pets, other shops or all World1 stages was performed.
- World2 animation production/visual animation quality is excluded by request; existing World1 animation Sources and IDs are unchanged.

## Persistence and cleanup

The same CurrentCloud file was patched without another rbxl/Backup/Copy/Migration. All seven Sources compile with Luau; tested Studio Sources matched the writeback inputs. Re-read checks validate Source equality and every untouched binary column/row, including templates, map geometry and Trophy settings. The scale/collider settings are persisted in World2BossVisualConfig and applied to fresh runtime personal clones.

Play was stopped; all unsaved memory-store, badge, purchase and preparation fixtures were removed/restored before closing the verification Studio. No Studio Save or Publish was used. Only Studio/client processes launched for this task are closed without saving. See Writeback.json and final cleanup verification for hashes and process/lock checks.
